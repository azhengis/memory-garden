import SwiftUI

struct WelcomeView: View {
    let onContinue: () -> Void

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.78, green: 0.70, blue: 0.92),
                    Color(red: 0.98, green: 0.78, blue: 0.88),
                    Color(red: 0.74, green: 0.88, blue: 0.98)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 18) {
                Spacer()

                // “Logo” bubble
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.35))
                        .frame(width: 120, height: 120)
                        .overlay(
                            Circle().stroke(.white.opacity(0.35), lineWidth: 1)
                        )

                    Image(systemName: "sparkles")
                        .font(.system(size: 44, weight: .semibold))
                        .foregroundStyle(.white)
                }

                VStack(spacing: 8) {
                    Text("Memory Garden")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text("Save moments. Plant them. Build your world.")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)
                }

                // 3 feature chips
                VStack(spacing: 10) {
                    FeatureRow(icon: "mic.fill", title: "Voice memories", subtitle: "Record quick moments")
                    FeatureRow(icon: "leaf.fill", title: "Choose plants", subtitle: "Attach a plant to each memory")
                    FeatureRow(icon: "arkit", title: "AR garden", subtitle: "Place memories in your space")
                }
                .padding(.top, 10)

                Spacer()

                Button(action: onContinue) {
                    Text("Get Started")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(.white.opacity(0.35))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(.white.opacity(0.35), lineWidth: 1)
                        )
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 18)
            }
        }
    }
}

private struct FeatureRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(.white.opacity(0.22))
                    .frame(width: 46, height: 46)
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))
            }

            Spacer()
        }
        .padding(.horizontal, 20)
    }
}
