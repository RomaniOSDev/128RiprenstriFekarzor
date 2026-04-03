//
//  OnboardingFlowView.swift
//  128RiprenstriFekarzor
//

import SwiftUI

struct OnboardingFlowView: View {
    @EnvironmentObject private var progress: GameProgressStore
    @State private var page = 0

    var body: some View {
        ZStack {
            AppChromeBackground()
            VStack(spacing: 0) {
                TabView(selection: $page) {
                    OnboardingRhythmPage().tag(0)
                    OnboardingGeometryPage().tag(1)
                    OnboardingSignalPage().tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.35), value: page)

                PrimaryGameButton(title: page < 2 ? "Continue" : "Enter") {
                    if page < 2 {
                        withAnimation(.easeInOut(duration: 0.35)) {
                            page += 1
                        }
                    } else {
                        progress.completeOnboarding()
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
        }
    }
}

private struct OnboardingRhythmPage: View {
    @State private var wave = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Canvas { context, size in
                    let w = size.width
                    let h = size.height * 0.45
                    var path = Path()
                    let steps = 6
                    for i in 0...steps {
                        let x = w * CGFloat(i) / CGFloat(steps)
                        let y = h * 0.5 + sin((Double(i) * 0.9) + (wave ? 0.6 : 0)) * h * 0.22
                        if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                        else { path.addLine(to: CGPoint(x: x, y: y)) }
                    }
                    context.stroke(path, with: .color(Color.appAccent), lineWidth: 4)
                }
                .frame(height: 220)
                .appInsetPanel(cornerRadius: 18)

                Text("Cascade matching keeps a calm, steady tempo.")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Color.appTextPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)

                Text("Slide neighboring tiles until three or more hues line up, then enjoy the gentle collapse.")
                    .font(.body)
                    .foregroundStyle(Color.appTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }
            .padding(.vertical, 32)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                wave.toggle()
            }
        }
    }
}

private struct OnboardingGeometryPage: View {
    @State private var spin = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                ZStack {
                    ForEach(0..<3, id: \.self) { i in
                        let side: CGFloat = 120 - CGFloat(i * 18)
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(AppFill.secondaryFaceGradient)
                            .frame(width: side, height: side)
                            .shadow(color: Color.appBackground.opacity(0.55), radius: 10, x: 0, y: 6)
                            .shadow(color: Color.appAccent.opacity(0.12), radius: 6, x: 0, y: 3)
                            .overlay {
                                DiamondShape()
                                    .stroke(Color.appAccent, lineWidth: 3)
                                    .frame(width: side * 0.55, height: side * 0.55)
                                    .rotationEffect(.degrees(spin ? Double(i * 12) : Double(i * 4)))
                            }
                    }
                }
                .frame(height: 220)
                .appInsetPanel(cornerRadius: 22)

                Text("Shapes ask you to notice angles and order.")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Color.appTextPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)

                Text("Drag each outline into its matching silhouette, tuning rotation when the challenge demands it.")
                    .font(.body)
                    .foregroundStyle(Color.appTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }
            .padding(.vertical, 32)
        }
        .onAppear {
            withAnimation(.spring(response: 1.4, dampingFraction: 0.65).repeatForever(autoreverses: true)) {
                spin.toggle()
            }
        }
    }
}

private struct OnboardingSignalPage: View {
    @State private var pulse = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .stroke(Color.appPrimary.opacity(0.35), lineWidth: 10)
                        .frame(width: pulse ? 190 : 150, height: pulse ? 190 : 150)
                        .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: pulse)

                    GridPatternPreview()
                        .frame(width: 160, height: 160)
                }
                .frame(height: 220)
                .appInsetPanel(cornerRadius: 22)

                Text("Signals appear, then it is your turn.")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Color.appTextPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)

                Text("Observe the short sequence, then replay it on the board with careful taps.")
                    .font(.body)
                    .foregroundStyle(Color.appTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }
            .padding(.vertical, 32)
        }
        .onAppear { pulse = true }
    }
}

private struct GridPatternPreview: View {
    var body: some View {
        Canvas { context, size in
            let cols = 3
            let spacing: CGFloat = 8
            let cell = (size.width - spacing * CGFloat(cols - 1)) / CGFloat(cols)
            for r in 0..<cols {
                for c in 0..<cols {
                    let rect = CGRect(
                        x: CGFloat(c) * (cell + spacing),
                        y: CGFloat(r) * (cell + spacing),
                        width: cell,
                        height: cell
                    )
                    let rr = RoundedRectangle(cornerRadius: 10, style: .continuous)
                    context.fill(rr.path(in: rect), with: .color(Color.appSurface))
                    context.stroke(rr.path(in: rect), with: .color(Color.appAccent.opacity(0.6)), lineWidth: 1.5)
                }
            }
        }
    }
}

private struct DiamondShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        path.closeSubpath()
        return path
    }
}
