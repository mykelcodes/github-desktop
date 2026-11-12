import AppKit
import SwiftUI

struct NativeDiffView: NSViewRepresentable {
    let text: String

    func makeNSView(context: Context) -> NSScrollView {
        let scroll = NSScrollView()
        scroll.hasVerticalScroller = true
        scroll.hasHorizontalScroller = true
        scroll.autohidesScrollers = true
        scroll.drawsBackground = true
        scroll.backgroundColor = .textBackgroundColor
        let view = NSTextView()
        view.isEditable = false
        view.isSelectable = true
        view.isRichText = false
        view.isAutomaticLinkDetectionEnabled = false
        view.isAutomaticSpellingCorrectionEnabled = false
        view.textContainerInset = NSSize(width: 16, height: 16)
        view.isHorizontallyResizable = true
        view.isVerticallyResizable = true
        view.autoresizingMask = [.width]
        view.textContainer?.widthTracksTextView = false
        view.textContainer?.containerSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        view.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        view.setAccessibilityLabel("File changes")
        scroll.documentView = view
        return scroll
    }

    func updateNSView(_ scroll: NSScrollView, context: Context) {
        guard let view = scroll.documentView as? NSTextView, view.string != text else { return }
        let attributed = NSMutableAttributedString(string: text, attributes: [
            .font: NSFont.monospacedSystemFont(ofSize: 12, weight: .regular),
            .foregroundColor: NSColor.textColor,
        ])
        var position = 0
        for line in text.components(separatedBy: "\n") {
            let length = line.utf16.count
            let range = NSRange(location: position, length: length)
            if line.hasPrefix("+") && !line.hasPrefix("+++") {
                attributed.addAttributes([
                    .foregroundColor: NSColor.systemGreen,
                    .backgroundColor: NSColor.systemGreen.withAlphaComponent(0.08),
                ], range: range)
            } else if line.hasPrefix("-") && !line.hasPrefix("---") {
                attributed.addAttributes([
                    .foregroundColor: NSColor.systemRed,
                    .backgroundColor: NSColor.systemRed.withAlphaComponent(0.08),
                ], range: range)
            } else if line.hasPrefix("@@") {
                attributed.addAttribute(.foregroundColor, value: NSColor.systemBlue, range: range)
            } else if line.hasPrefix("diff --git") || line.hasPrefix("index ") {
                attributed.addAttribute(.foregroundColor, value: NSColor.secondaryLabelColor, range: range)
            }
            position += length + 1
        }
        view.textStorage?.setAttributedString(attributed)
        view.scrollToBeginningOfDocument(nil)
    }
}
