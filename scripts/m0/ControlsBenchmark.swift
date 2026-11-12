import AppKit
import SwiftUI

@MainActor
final class HistorySource: NSObject, NSTableViewDataSource, NSTableViewDelegate {
    let rows: [String]

    init(rows: [String]) {
        self.rows = rows
    }

    func numberOfRows(in tableView: NSTableView) -> Int { rows.count }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let identifier = NSUserInterfaceItemIdentifier("commit")
        let label = tableView.makeView(withIdentifier: identifier, owner: nil) as? NSTextField
            ?? NSTextField(labelWithString: "")
        label.identifier = identifier
        label.stringValue = rows[row]
        label.setAccessibilityLabel("Commit \(rows[row])")
        return label
    }
}

struct SwiftRows: View {
    let rows: [String]

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(rows.indices, id: \.self) { index in
                    Text(rows[index]).font(.system(.body, design: .monospaced))
                }
            }
        }
    }
}

@main
struct ControlsBenchmark {
    @MainActor
    static func main() throws {
        _ = NSApplication.shared
        NSApp.setActivationPolicy(.prohibited)
        let history = (0..<100_000).map { "\($0) a1b2c3d Commit \($0)" }
        let fixtures: [(String, [String])] = [
            ("large-diff", (0..<20_000).map { "+ line \($0) changed source" }),
            ("unicode-diff", (0..<20_000).map { "- \($0) café 日本語 👩🏽‍💻 e\u{301}" }),
            ("renamed-diff", ["diff --git a/old.swift b/new.swift", "similarity index 98%", "rename from old.swift", "rename to new.swift", "@@ -1 +1 @@", "-old", "+new"]),
            ("binary-diff", ["Binary files a/image.png and b/image.png differ"]),
        ]
        var results: [[String: Any]] = []

        func measure(_ name: String, makeView: () -> NSView) {
            if CommandLine.arguments.count > 1 && name != CommandLine.arguments[1] { return }
            var samples: [Double] = []
            for _ in 0..<20 {
                autoreleasepool {
                    let start = ProcessInfo.processInfo.systemUptime
                    let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 1000, height: 700),
                                          styleMask: [.borderless], backing: .buffered, defer: false)
                    window.isReleasedWhenClosed = false
                    let view = makeView()
                    window.contentView = view
                    view.frame = NSRect(x: 0, y: 0, width: 1000, height: 700)
                    view.layoutSubtreeIfNeeded()
                    guard let image = view.bitmapImageRepForCachingDisplay(in: view.bounds) else {
                        fatalError("Could not render the viewport")
                    }
                    view.cacheDisplay(in: view.bounds, to: image)
                    samples.append((ProcessInfo.processInfo.systemUptime - start) * 1000)
                    window.close()
                }
                RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.01))
            }
            let sorted = samples.sorted()
            results.append(["case": name, "trials": samples.count, "first_ms": samples[0],
                            "p50_ms": sorted[9], "p95_ms": sorted[18], "max_ms": sorted[19]])
        }

        for (name, lines) in fixtures {
            measure("AppKit NSTextView / \(name)") {
                NSHostingView(rootView: NativeDiffView(text: lines.joined(separator: "\n")))
            }
            measure("SwiftUI LazyVStack / \(name)") {
                NSHostingView(rootView: SwiftRows(rows: lines))
            }
            if lines.count > 200 {
                measure("AppKit NSTextView / \(name) / 200-line page") {
                    NSHostingView(rootView: NativeDiffView(text: lines.prefix(200).joined(separator: "\n")))
                }
            }
        }
        let source = HistorySource(rows: history)
        measure("AppKit NSTableView / 100000 commits") {
            let table = NSTableView()
            let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("commit"))
            column.width = 980
            table.addTableColumn(column)
            table.rowHeight = 22
            table.dataSource = source
            table.delegate = source
            table.setAccessibilityLabel("Commit history")
            let scroll = NSScrollView()
            scroll.hasVerticalScroller = true
            scroll.documentView = table
            table.reloadData()
            return scroll
        }
        measure("SwiftUI LazyVStack / 100000 commits") {
            NSHostingView(rootView: SwiftRows(rows: history))
        }
        let report: [String: Any] = [
            "experiment": "DISC-04 offscreen first viewport",
            "os": ProcessInfo.processInfo.operatingSystemVersionString,
            "physical_memory_bytes": ProcessInfo.processInfo.physicalMemory,
            "results": results,
            "limitations": ["offscreen layout and bitmap drawing", "synthetic history rows",
                            "excludes Git retrieval", "excludes interaction and VoiceOver",
                            "same-process warm trials", "whole-process memory measured externally"],
        ]
        let data = try JSONSerialization.data(withJSONObject: report, options: [.prettyPrinted, .sortedKeys])
        print(String(decoding: data, as: UTF8.self))
    }
}
