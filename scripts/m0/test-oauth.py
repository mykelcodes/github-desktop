#!/usr/bin/env python3
"""Verify callback validation and credential cleanup with synthetic OAuth fixtures."""

import contextlib
import importlib.util
import io
from pathlib import Path
import unittest
from unittest.mock import patch
from urllib.parse import parse_qs, urlencode, urlsplit

specification = importlib.util.spec_from_file_location("m0oauth", Path(__file__).with_name("oauth.py"))
oauth = importlib.util.module_from_spec(specification)
specification.loader.exec_module(oauth)


class OAuthTests(unittest.TestCase):
    def test_refresh_and_failed_refresh_revoke_credentials_without_printing_them(self):
        for refresh_fails in [False, True]:
            with self.subTest(refresh_fails=refresh_fails):
                revoked = []

                def request(url, payload=None, token=None, method=None, client_credentials=None):
                    if method == "DELETE":
                        revoked.append(payload["access_token"])
                        return 204, {}
                    if url.endswith("/login/oauth/access_token"):
                        if payload.get("grant_type") == "refresh_token":
                            return (400, {}) if refresh_fails else (200, {
                                "access_token": "fake_access_new", "refresh_token": "fake_refresh_new"})
                        return 200, {"access_token": "fake_access_old", "refresh_token": "fake_refresh_old",
                                     "scope": "read:user notifications"}
                    if token in revoked:
                        return 401, {}
                    return (200, {"id": 7}) if url.endswith("/user") else (200, [])

                output = io.StringIO()
                with patch.object(oauth.sys.stdin, "isatty", return_value=True), \
                     patch.object(oauth.getpass, "getpass", return_value="fake_client_secret"), \
                     patch.object(oauth, "authorize", return_value=("fake_code", "fake_verifier")), \
                     patch.object(oauth, "request_json", side_effect=request), \
                     contextlib.redirect_stdout(output):
                    if refresh_fails:
                        with self.assertRaises(RuntimeError):
                            oauth.run("public_client", "read:user notifications offline_access")
                    else:
                        oauth.run("public_client", "read:user notifications offline_access")
                for secret in ["fake_access", "fake_refresh", "fake_client_secret", "fake_code", "fake_verifier"]:
                    self.assertNotIn(secret, output.getvalue())
                self.assertEqual(revoked, ["fake_access_old"] if refresh_fails else ["fake_access_new"])

    def test_callback_rejects_invalid_state_path_host_duplicate_state_and_replay(self):
        state = {}
        responses = []

        class Connection:
            def __init__(self, request):
                self.request = request

            def makefile(self, *arguments):
                return io.BytesIO(self.request)

            def sendall(self, data):
                responses.append(data)

        class Server:
            def __init__(self, address, handler):
                self.handler = handler
                self.step = 0
                state["server"] = self

            def __enter__(self):
                return self

            def __exit__(self, *arguments):
                pass

            def handle_request(self):
                token = state["token"]
                cases = [
                    ("/oauth/callback", {"state": "wrong", "code": "fake"}, "127.0.0.1:49152"),
                    ("/oauth/callback", {"state": [token, token], "code": "fake"}, "127.0.0.1:49152"),
                    ("/wrong", {"state": token, "code": "fake"}, "127.0.0.1:49152"),
                    ("/oauth/callback", {"state": token, "code": "fake"}, "evil.invalid"),
                    ("/oauth/callback", {"state": token, "code": "fake"}, "127.0.0.1:49152"),
                ]
                path, query, host = cases[min(self.step, 4)]
                self.step += 1
                request = f"GET {path}?{urlencode(query, doseq=True)} HTTP/1.0\r\nHost: {host}\r\n\r\n"
                self.handler(Connection(request.encode()), ("127.0.0.1", 22222), self)

        def browser(url):
            query = parse_qs(urlsplit(url).query)
            state["token"] = query["state"][0]
            self.assertEqual(query["code_challenge_method"], ["S256"])
            self.assertEqual(len(query["code_challenge"][0]), 43)
            return True

        with patch.object(oauth, "HTTPServer", Server), \
             patch.object(oauth.webbrowser, "open", side_effect=browser), \
             contextlib.redirect_stdout(io.StringIO()):
            code, verifier = oauth.authorize("public_client", "read:user")
            state["server"].handle_request()
        self.assertEqual(code, "fake")
        self.assertGreaterEqual(len(verifier), 43)
        statuses = [data.split(b"\r\n")[0] for data in responses if data.startswith(b"HTTP/")]
        self.assertEqual(statuses, [b"HTTP/1.0 400 Invalid callback"] * 4 +
                         [b"HTTP/1.0 200 OK", b"HTTP/1.0 400 Invalid callback"])


if __name__ == "__main__":
    unittest.main()
