// LoopFollow
// TrendStrip.swift

import SwiftUI

/// A no-detail trend strip for the Snoozer: recent readings as a filled area,
/// with dashed markers at the low and high limits. No axes, labels or values —
/// the shape is the whole point.
///
/// The vertical scale auto-fits the readings rather than using a fixed glucose
/// window, so an ordinary night's movement fills the strip instead of being
/// flattened into a near-straight line.
///
/// A limit marker is only pulled into frame once the readings come within
/// `limitProximity` of it. Auto-fitting to in-range data normally leaves 70 and
/// 180 outside the visible span entirely, where they cannot be drawn honestly;
/// this keeps the full vertical range on a quiet night and brings the reference
/// line in exactly when a drift starts to matter.
struct TrendStrip: View {
    /// Readings in mg/dL, oldest first.
    let values: [Double]
    /// Line and limit markers — follows the screen's text color, so night mode
    /// turns the whole strip red along with everything else.
    let strokeColor: Color
    /// Fill and endpoint — follows the BG range color.
    let accentColor: Color

    /// How close (mg/dL) the readings must come to a limit before it is drawn.
    private let limitProximity: Double = 35

    var body: some View {
        Canvas { context, size in
            guard values.count >= 2, size.width > 0, size.height > 0 else { return }

            let bounds = verticalBounds
            let span = bounds.upper - bounds.lower

            func y(_ value: Double) -> CGFloat {
                let clamped = min(bounds.upper, max(bounds.lower, value))
                return size.height - CGFloat((clamped - bounds.lower) / span) * size.height
            }

            // Limits first, so the filled area reads as passing over them.
            let thresholds = UnitSettingsStore.shared.effectiveThresholds()
            for limit in [thresholds.low, thresholds.high]
                where limit >= bounds.lower && limit <= bounds.upper
            {
                var marker = Path()
                marker.move(to: CGPoint(x: 0, y: y(limit)))
                marker.addLine(to: CGPoint(x: size.width, y: y(limit)))
                context.stroke(
                    marker,
                    with: .color(strokeColor.opacity(0.30)),
                    style: StrokeStyle(lineWidth: 1.5, dash: [5, 4])
                )
            }

            let step = size.width / CGFloat(values.count - 1)
            let points = values.enumerated().map { index, value in
                CGPoint(x: CGFloat(index) * step, y: y(value))
            }

            var line = Path()
            line.addLines(points)

            var area = line
            area.addLine(to: CGPoint(x: size.width, y: size.height))
            area.addLine(to: CGPoint(x: 0, y: size.height))
            area.closeSubpath()

            context.fill(
                area,
                with: .linearGradient(
                    Gradient(colors: [accentColor.opacity(0.42), accentColor.opacity(0.02)]),
                    startPoint: .zero,
                    endPoint: CGPoint(x: 0, y: size.height)
                )
            )

            context.stroke(
                line,
                with: .color(strokeColor.opacity(0.8)),
                style: StrokeStyle(lineWidth: 2.4, lineCap: .round, lineJoin: .round)
            )

            // The endpoint marks which end is "now" — without it the shape alone
            // does not say which way it is read.
            if let last = points.last {
                let radius: CGFloat = 4.2
                let dot = CGRect(
                    x: last.x - radius,
                    y: last.y - radius,
                    width: radius * 2,
                    height: radius * 2
                )
                context.fill(Path(ellipseIn: dot), with: .color(accentColor))
            }
        }
    }

    /// Visible glucose span: the readings, widened to a limit when they approach
    /// one, plus headroom so the stroke never clips against the frame edge.
    private var verticalBounds: (lower: Double, upper: Double) {
        guard let dataMin = values.min(), let dataMax = values.max() else {
            return (70, 180)
        }

        let thresholds = UnitSettingsStore.shared.effectiveThresholds()
        var lower = dataMin
        var upper = dataMax

        if dataMin - thresholds.low <= limitProximity {
            lower = min(lower, thresholds.low)
        }
        if thresholds.high - dataMax <= limitProximity {
            upper = max(upper, thresholds.high)
        }

        // The floor also keeps a dead-flat stretch from collapsing the span.
        let padding = max((upper - lower) * 0.12, 3)
        return (lower - padding, upper + padding)
    }
}
