import SwiftUI

struct OnboardingStepView: View {
    let content: OnboardingStepContent

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: content.iconName)
                .font(.system(size: 40))
                .foregroundStyle(.tint)
                .frame(width: 64, height: 64)
                .background(Color.accentColor.opacity(0.12), in: Circle())

            Text(content.title)
                .font(.title2)
                .fontWeight(.bold)

            Text(content.description)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview("Welcome") {
    OnboardingStepView(content: OnboardingStepContent.allSteps[0])
        .frame(width: 520, height: 300)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20))
}

#Preview("Feature") {
    OnboardingStepView(content: OnboardingStepContent.allSteps[1])
        .frame(width: 520, height: 300)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20))
}

#Preview("Complete") {
    OnboardingStepView(content: OnboardingStepContent.allSteps[5])
        .frame(width: 520, height: 300)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20))
}
