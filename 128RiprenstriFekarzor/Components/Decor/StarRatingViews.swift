//
//  StarRatingViews.swift
//  128RiprenstriFekarzor
//

import SwiftUI

struct CompactStarRow: View {
    let filled: Int
    let maxStars: Int

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<maxStars, id: \.self) { i in
                starShape(filled: i < filled)
                    .frame(width: 14, height: 14)
            }
        }
    }

    private func starShape(filled: Bool) -> some View {
        Canvas { context, size in
            let rect = CGRect(origin: .zero, size: size)
            let path = starPath(in: rect)
            if filled {
                context.fill(path, with: .color(Color.appAccent))
            } else {
                context.stroke(path, with: .color(Color.appTextSecondary.opacity(0.5)), lineWidth: 1)
            }
        }
    }

    private func starPath(in rect: CGRect) -> Path {
        var path = Path()
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let r = min(rect.width, rect.height) / 2
        let points = 5
        for i in 0..<(points * 2) {
            let angle = CGFloat(i) * .pi / CGFloat(points) - .pi / 2
            let radius = i.isMultiple(of: 2) ? r : r * 0.45
            let pt = CGPoint(x: c.x + cos(angle) * radius, y: c.y + sin(angle) * radius)
            if i == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
        }
        path.closeSubpath()
        return path
    }
}

struct AnimatedResultStar: View {
    let show: Bool
    let index: Int

    var body: some View {
        ZStack {
            if show {
                Canvas { context, size in
                    let p = starPath(CGRect(origin: .zero, size: size))
                    context.fill(p, with: .color(Color.appPrimary))
                }
                .shadow(color: Color.appAccent.opacity(0.9), radius: 14, y: 0)
                .scaleEffect(show ? 1 : 0.2)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(width: 52, height: 52)
        .animation(
            .spring(response: 0.55, dampingFraction: 0.62),
            value: show
        )
    }

    private func starPath(_ rect: CGRect) -> Path {
        var path = Path()
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let r = min(rect.width, rect.height) / 2 - 2
        let points = 5
        for i in 0..<(points * 2) {
            let angle = CGFloat(i) * .pi / CGFloat(points) - .pi / 2
            let radius = i.isMultiple(of: 2) ? r : r * 0.45
            let pt = CGPoint(x: c.x + cos(angle) * radius, y: c.y + sin(angle) * radius)
            if i == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
        }
        path.closeSubpath()
        return path
    }
}
