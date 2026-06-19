import SwiftUI

struct LyricsSkeleton: View {
    var body: some View {
        VStack(spacing: 6) {
            SkeletonLine(height: 10, widthRatio: 0.5).opacity(0.55)
            SkeletonLine(height: 16, widthRatio: 0.82)
            SkeletonLine(height: 10, widthRatio: 0.42).opacity(0.55)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct SkeletonLine: View {
    let height: CGFloat
    let widthRatio: Double
    @State private var phase: CGFloat = -1.2

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width * widthRatio
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: height / 2, style: .continuous)
                    .fill(Color.primary.opacity(0.10))
                    .frame(width: w, height: height)

                LinearGradient(
                    colors: [.clear, Color.primary.opacity(0.18), .clear],
                    startPoint: .leading, endPoint: .trailing
                )
                .frame(width: w * 0.45, height: height)
                .offset(x: phase * w)
                .mask(
                    RoundedRectangle(cornerRadius: height / 2, style: .continuous)
                        .frame(width: w, height: height)
                )
            }
            .frame(width: geo.size.width, alignment: .leading)
        }
        .frame(height: height)
        .onAppear {
            withAnimation(.linear(duration: 1.4).repeatForever(autoreverses: false)) {
                phase = 1.4
            }
        }
    }
}
