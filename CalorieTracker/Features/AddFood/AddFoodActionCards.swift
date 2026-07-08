import SwiftUI

/// "New product" + "Scan" action cards row of the Add food sheet.
struct AddFoodActionCards: View {
    let onNewProduct: () -> Void
    let onScan: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Button(action: onNewProduct) {
                newProductCard
            }
            .buttonStyle(.plain)
            Button(action: onScan) {
                scanCard
            }
            .buttonStyle(.plain)
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    private var newProductCard: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Theme.accentSoftAlt)
                    .frame(width: 34, height: 34)
                Image(systemName: "plus")
                    .font(.title2.weight(.light))
                    .foregroundStyle(Theme.accentIcon)
                    .offset(y: -1)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("New product")
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)
                Text("Create a food with your own values")
                    .font(.footnote)
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 15)
        .padding(.horizontal, 16)
        .glassCard(cornerRadius: 14)
    }

    private var scanCard: some View {
        VStack(spacing: 6) {
            BarcodeViewfinderGlyph()
                .frame(width: 26, height: 22)
            Text("Scan")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.accentDeep)
        }
        .frame(width: 84)
        .frame(maxHeight: .infinity)
        .glassCard(cornerRadius: 14)
    }
}

/// Prototype barcode icon: four 2pt rounded viewfinder corners + a center line.
private struct BarcodeViewfinderGlyph: View {
    var body: some View {
        ZStack {
            ViewfinderCornersShape(corner: 8, radius: 3)
                .stroke(Theme.accentIcon, style: StrokeStyle(lineWidth: 2, lineCap: .round))
            RoundedRectangle(cornerRadius: 1)
                .fill(Theme.accentLabel)
                .frame(height: 2)
                .padding(.horizontal, 2)
        }
    }
}

private struct ViewfinderCornersShape: Shape {
    let corner: CGFloat
    let radius: CGFloat

    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY + corner))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.minY + radius))
        p.addQuadCurve(to: CGPoint(x: rect.minX + radius, y: rect.minY),
                       control: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.minX + corner, y: rect.minY))
        p.move(to: CGPoint(x: rect.maxX - corner, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))
        p.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY + radius),
                       control: CGPoint(x: rect.maxX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + corner))
        p.move(to: CGPoint(x: rect.maxX, y: rect.maxY - corner))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - radius))
        p.addQuadCurve(to: CGPoint(x: rect.maxX - radius, y: rect.maxY),
                       control: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.maxX - corner, y: rect.maxY))
        p.move(to: CGPoint(x: rect.minX + corner, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX + radius, y: rect.maxY))
        p.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.maxY - radius),
                       control: CGPoint(x: rect.minX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - corner))
        return p
    }
}

#Preview {
    ZStack {
        AppBackground()
        AddFoodActionCards(onNewProduct: {}, onScan: {})
            .padding(20)
    }
}
