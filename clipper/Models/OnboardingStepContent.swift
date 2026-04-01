import Foundation

enum OnboardingStepType: Equatable {
    case welcome
    case feature
    case accessibilityPermission
    case launchAtLogin
    case complete
}

struct OnboardingStepContent {
    let iconName: String
    let title: String
    let description: String
    let stepType: OnboardingStepType
}

extension OnboardingStepContent {
    static let allSteps: [OnboardingStepContent] = [
        OnboardingStepContent(
            iconName: "clipboard",
            title: "Clipper へようこそ",
            description: "macOS のクリップボードを\nもっと便利に、もっと賢く。",
            stepType: .welcome
        ),
        OnboardingStepContent(
            iconName: "clock.arrow.circlepath",
            title: "クリップボード履歴",
            description: "コピーした内容を自動で記録。\nいつでも過去のコピーを呼び出せます。",
            stepType: .feature
        ),
        OnboardingStepContent(
            iconName: "magnifyingglass",
            title: "かんたん検索",
            description: "キーワードで過去のコピーを\nすばやく見つけられます。",
            stepType: .feature
        ),
        OnboardingStepContent(
            iconName: "lock.shield",
            title: "アクセシビリティ権限",
            description: "クリップボードの監視にはアクセシビリティ\n権限が必要です。下のボタンから設定してください。",
            stepType: .accessibilityPermission
        ),
        OnboardingStepContent(
            iconName: "power",
            title: "ログイン時に自動起動",
            description: "Mac を起動するたびに Clipper が\n自動で立ち上がります。",
            stepType: .launchAtLogin
        ),
        OnboardingStepContent(
            iconName: "checkmark.circle",
            title: "準備完了！",
            description: "すべての設定が完了しました。\nClipper を使い始めましょう。",
            stepType: .complete
        ),
    ]
}

enum NavigationDirection: Equatable {
    case forward
    case backward
}
