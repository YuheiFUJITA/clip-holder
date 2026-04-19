import Foundation
import AppKit
import SwiftUI

// キーウィンドウになれるNSPanelサブクラス
private class KeyablePanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

protocol PanelWindowManaging {
    var isVisible: Bool { get }
    func showPanel()
    func hidePanel()
    func togglePanel()
    func resizePanel(showPreview: Bool)
}

@MainActor
final class PanelWindowService: PanelWindowManaging {
    private var panel: NSPanel?
    private var eventMonitor: Any?
    private let caretPositionService: CaretPositionProviding
    static let panelHeight: CGFloat = 480
    static let listWidth: CGFloat = 360
    static let previewWidth: CGFloat = 400
    static let dividerWidth: CGFloat = 1

    static func panelWidth(showPreview: Bool) -> CGFloat {
        showPreview ? listWidth + dividerWidth + previewWidth : listWidth
    }

    private var currentShowPreview: Bool = true

    private var panelSize: NSSize {
        NSSize(width: Self.panelWidth(showPreview: currentShowPreview), height: Self.panelHeight)
    }

    private(set) var isVisible: Bool = false

    var contentView: (() -> AnyView)?

    init(caretPositionService: CaretPositionProviding? = nil) {
        self.caretPositionService = caretPositionService ?? CaretPositionService()
    }

    func showPanel() {
        guard !isVisible else { return }

        let panel = createOrReusePanel()
        let position = calculatePosition()
        panel.setFrameOrigin(position)
        NSApp.activate()
        panel.makeKeyAndOrderFront(nil)
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

    func resizePanel(showPreview: Bool) {
        currentShowPreview = showPreview
        guard let panel else { return }
        let newSize = panelSize
        var frame = panel.frame
        let topY = frame.origin.y + frame.size.height
        frame.size = newSize
        frame.origin.y = topY - newSize.height
        if let screen = panel.screen ?? NSScreen.main {
            let visible = screen.visibleFrame
            if frame.origin.x + frame.size.width > visible.maxX {
                frame.origin.x = visible.maxX - frame.size.width
            }
            if frame.origin.x < visible.minX {
                frame.origin.x = visible.minX
            }
        }
        panel.setFrame(frame, display: true, animate: false)
    }

    // MARK: - Private

    private func createOrReusePanel() -> NSPanel {
        if let existing = panel {
            return existing
        }

        let newPanel = KeyablePanel(
            contentRect: NSRect(origin: .zero, size: panelSize),
            styleMask: [.nonactivatingPanel, .fullSizeContentView, .titled],
            backing: .buffered,
            defer: false
        )
        newPanel.level = .floating
        newPanel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        newPanel.isOpaque = false
        newPanel.backgroundColor = .clear
        newPanel.hasShadow = true
        newPanel.hidesOnDeactivate = false
        newPanel.isMovableByWindowBackground = true
        newPanel.titleVisibility = .hidden
        newPanel.titlebarAppearsTransparent = true

        if let contentView = contentView {
            let hostingView = NSHostingView(rootView: contentView())
            hostingView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
            hostingView.setContentHuggingPriority(.defaultHigh, for: .vertical)
            newPanel.contentView = hostingView
        }

        panel = newPanel
        return newPanel
    }

    private func calculatePosition() -> NSPoint {
        let active = activeScreen()

        // キャレット位置を取得
        if let caretPoint = caretPositionService.getCaretPosition() {
            let screenPoint = convertToScreenCoordinates(caretPoint)
            // キャレットがある画面を優先、なければアクティブな画面
            let targetScreen = screenContaining(screenPoint) ?? active
            return adjustForScreenBounds(screenPoint, in: targetScreen)
        }

        // フォールバック: アクティブな画面の中央
        return centerOfScreen(active)
    }

    // NSScreen.main は管理画面など別ディスプレイの key window がある画面を返してしまうため、
    // マウスカーソルがある画面を「現在アクティブな画面」とみなす
    private func activeScreen() -> NSScreen {
        let mouseLocation = NSEvent.mouseLocation
        if let screen = NSScreen.screens.first(where: { $0.frame.contains(mouseLocation) }) {
            return screen
        }
        return NSScreen.main ?? NSScreen.screens[0]
    }

    private func screenContaining(_ point: NSPoint) -> NSScreen? {
        NSScreen.screens.first(where: { $0.frame.contains(point) })
    }

    private func convertToScreenCoordinates(_ point: CGPoint) -> NSPoint {
        // AXUIElement の座標系（プライマリ画面の左上原点）を NSWindow の座標系（同画面の左下原点）に変換
        let primaryScreen = NSScreen.screens.first(where: { $0.frame.origin == .zero }) ?? NSScreen.screens.first
        guard let primaryScreen else {
            return NSPoint(x: point.x, y: point.y)
        }
        return NSPoint(x: point.x, y: primaryScreen.frame.height - point.y)
    }

    private func adjustForScreenBounds(_ origin: NSPoint, in screen: NSScreen) -> NSPoint {
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

    private func centerOfScreen(_ screen: NSScreen) -> NSPoint {
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
