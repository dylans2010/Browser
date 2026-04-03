import Foundation
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

struct CopyURLTool {
    static func execute(urlString: String) {
        guard !urlString.isEmpty else { return }
#if os(iOS)
        UIPasteboard.general.string = urlString
#elseif os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(urlString, forType: .string)
#endif
    }
}
