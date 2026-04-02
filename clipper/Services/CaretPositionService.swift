import Foundation
import AppKit
import ApplicationServices

protocol CaretPositionProviding {
    func getCaretPosition() -> CGPoint?
}

final class CaretPositionService: CaretPositionProviding {
    func getCaretPosition() -> CGPoint? {
        let systemWide = AXUIElementCreateSystemWide()

        // フォーカス中の UI 要素を取得
        var focusedElement: AnyObject?
        let focusResult = AXUIElementCopyAttributeValue(systemWide, kAXFocusedUIElementAttribute as CFString, &focusedElement)
        guard focusResult == .success, let element = focusedElement else {
            return nil
        }

        let axElement = element as! AXUIElement

        // テキスト選択範囲を取得
        var selectedRangeValue: AnyObject?
        let rangeResult = AXUIElementCopyAttributeValue(axElement, kAXSelectedTextRangeAttribute as CFString, &selectedRangeValue)
        guard rangeResult == .success, let rangeValue = selectedRangeValue else {
            return nil
        }

        // 選択範囲のスクリーン座標を取得
        var boundsValue: AnyObject?
        let boundsResult = AXUIElementCopyParameterizedAttributeValue(
            axElement,
            kAXBoundsForRangeParameterizedAttribute as CFString,
            rangeValue,
            &boundsValue
        )
        guard boundsResult == .success, let bounds = boundsValue else {
            return nil
        }

        var rect = CGRect.zero
        guard AXValueGetValue(bounds as! AXValue, .cgRect, &rect) else {
            return nil
        }

        // キャレット位置（矩形の左下）を返す
        // macOS の座標系は左下が原点のため、SwiftUI/NSWindow 座標に変換
        return CGPoint(x: rect.origin.x, y: rect.origin.y + rect.size.height)
    }
}
