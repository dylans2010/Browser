import Foundation
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

struct CopyPageTitleTool {
    static func execute(title: String) {
        guard !title.isEmpty else { return }
#if os(iOS)
        UIPasteboard.general.string = title
#elseif os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(title, forType: .string)
#endif
    }
}
