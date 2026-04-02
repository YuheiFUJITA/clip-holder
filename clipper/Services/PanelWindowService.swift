import Foundation
import AppKit
import SwiftUI

protocol PanelWindowManaging {
    var isVisible: Bool { get }
    func showPanel()
    func hidePanel()
    func togglePanel()
}

@MainActor
final class PanelWindowService: PanelWindowManaging {
    private var panel: NSPanel?
    private var eventMonitor: Any?
    private let caretPositionService: CaretPositionProviding
    private let panelSize = NSSize(width: 360, height: 400)

    private(set) var isVisible: Bool = false

    var contentView: (() -> AnyView)?

    init(caretPositionService: CaretPositionProviding = CaretPositionService()) {
        self.caretPositionService = caretPositionService
    }

    func showPanel() {
        guard !isVisible else { return }

        let panel = createOrReusePanel()
        let position = calculatePosition()
        panel.setFrameOrigin(position)
        panel.orderFrontRegardless()
        isVisible = true

        startEventMonitor()
    }

    func hidePanel() {
        guard isVisible else { return }
        panel?.orderOut(nil)
        isVisible = false
        stopEventMonitor()
    }

    func togglePanel() {
        if isVisible {
            hidePanel()
        } else {
            showPanel()
        }
    }

    // MARK: - Private

    private func createOrReusePanel() -> NSPanel {
        if let existing = panel {
            return existing
        }

        let newPanel = NSPanel(
            contentRect: NSRect(origin: .zero, size: panelSize),
            styleMask: [.nonactivatingPanel, .borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        newPanel.level = .floating
        newPanel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        newPanel.isOpaque = false
        newPanel.backgroundColor = .clear
        newPanel.hasShadow = true
        newPanel.hidesOnDeactivate = false
        newPanel.isMovableByWindowBackground = false

        if let contentView = contentView {
            let hostingView = NSHostingView(rootView: contentView())
            newPanel.contentView = hostingView
        }

        panel = newPanel
        return newPanel
    }

    private func calculatePosition() -> NSPoint {
        // キャレット位置を取得
        if let caretPoint = caretPositionService.getCaretPosition() {
            let screenPoint = convertToScreenCoordinates(caretPoint)
            return adjustForScreenBounds(screenPoint)
        }

        // フォールバック: 画面中央
        return centerOfScreen()
    }

    private func convertToScreenCoordinates(_ point: CGPoint) -> NSPoint {
        // AXUIElement の座標系（左上原点）を NSWindow の座標系（左下原点）に変換
        guard let screen = NSScreen.main else {
            return NSPoint(x: point.x, y: point.y)
        }
        let screenHeight = screen.frame.height
        return NSPoint(x: point.x, y: screenHeight - point.y)
    }

    private func adjustForScreenBounds(_ origin: NSPoint) -> NSPoint {
        guard let screen = NSScreen.main else { return origin }
        let visibleFrame = screen.visibleFrame
        var adjusted = origin

        // 右端からはみ出す場合
        if adjusted.x + panelSize.width > visibleFrame.maxX {
            adjusted.x = visibleFrame.maxX - panelSize.width
        }
        // 左端からはみ出す場合
        if adjusted.x < visibleFrame.minX {
            adjusted.x = visibleFrame.minX
        }
        // 下端からはみ出す場合（パネルを上に表示）
        if adjusted.y - panelSize.height < visibleFrame.minY {
            adjusted.y = adjusted.y + panelSize.height
        } else {
            // 通常はカーソルの下に表示
            adjusted.y = adjusted.y - panelSize.height
        }
        // 上端からはみ出す場合
        if adjusted.y + panelSize.height > visibleFrame.maxY {
            adjusted.y = visibleFrame.maxY - panelSize.height
        }

        return adjusted
    }

    private func centerOfScreen() -> NSPoint {
        guard let screen = NSScreen.main else { return .zero }
        let visibleFrame = screen.visibleFrame
        return NSPoint(
            x: visibleFrame.midX - panelSize.width / 2,
            y: visibleFrame.midY - panelSize.height / 2
        )
    }

    private func startEventMonitor() {
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDown) { [weak self] event in
            Task { @MainActor in
                guard let self, self.isVisible, let panel = self.panel else { return }
                let mouseLocation = NSEvent.mouseLocation
                if !panel.frame.contains(mouseLocation) {
                    self.hidePanel()
                }
            }
        }
    }

    private func stopEventMonitor() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }
}
