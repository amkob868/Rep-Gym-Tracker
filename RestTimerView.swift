import SwiftUI

struct RestTimerView: View {
    let exerciseName: String
    let onDone: () -> Void

    @State private var secondsLeft = 60
    @State private var totalSeconds = 60
    @State private var timer: Timer? = nil

    var progress: Double { Double(secondsLeft) / Double(totalSeconds) }
    let circumference: Double = 628

    var body: some View {
        ZStack {
            ForgeTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Next up label
                VStack(spacing: 6) {
                    Text("REST UP · NEXT SET")
                        .font(ForgeTheme.nunito(12, weight: .heavy))
                        .tracking(3)
                        .foregroundColor(ForgeTheme.textMuted)
                    Text("Still on: \(exerciseName)")
                        .font(ForgeTheme.bebas(28))
                        .foregroundColor(.white.opacity(0.4))
                }

                Spacer()

                // Ring timer
                ZStack {
                    Circle()
                        .stroke(ForgeTheme.surface2, lineWidth: 8)
                        .frame(width: 220, height: 220)

                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(ForgeTheme.accentBulk, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: 220, height: 220)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1), value: secondsLeft)

                    VStack(spacing: 4) {
                        Text("\(secondsLeft)")
                            .font(ForgeTheme.bebas(64))
                            .foregroundColor(ForgeTheme.accentBulk)
                        Text("SECONDS")
                            .font(ForgeTheme.nunito(12, weight: .heavy))
                            .tracking(2)
                            .foregroundColor(ForgeTheme.textMuted)
                    }
                }

                Spacer()

                // Actions
                VStack(spacing: 10) {
                    Button {
                        timer?.invalidate()
                        onDone()
                    } label: {
                        Text("SKIP REST →")
                            .font(ForgeTheme.bebas(22))
                            .tracking(2)
                            .foregroundColor(ForgeTheme.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(RoundedRectangle(cornerRadius: 20).fill(ForgeTheme.surface).overlay(RoundedRectangle(cornerRadius: 20).stroke(ForgeTheme.border, lineWidth: 1.5)))
                    }

                    Button {
                        secondsLeft += 30
                        totalSeconds = max(totalSeconds, secondsLeft)
                    } label: {
                        Text("+ 30 seconds")
                            .font(ForgeTheme.nunito(14, weight: .bold))
                            .foregroundColor(ForgeTheme.textMuted)
                            .padding(.vertical, 8)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
        }
        .onAppear {
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                if secondsLeft > 0 {
                    secondsLeft -= 1
                } else {
                    timer?.invalidate()
                    onDone()
                }
            }
        }
        .onDisappear { timer?.invalidate() }
    }
}
#Preview {
    RestTimerView(exerciseName: "Bench Press", onDone: {})
}

