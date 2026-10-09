import CoreGraphics

/// Where the floating badge settles after a drag (or at launch): fully inside the screen's margin,
/// and pulled onto the margin line when dropped close to an edge, so it lines up neatly without fiddling.
public enum BadgeSnap {
    public static func origin(for frame: CGRect, in bounds: CGRect, margin: CGFloat, snapDistance: CGFloat = 48) -> CGPoint {
        let inner = bounds.insetBy(dx: margin, dy: margin)
        let maxX = inner.maxX - frame.width
        let maxY = inner.maxY - frame.height
        var x = min(max(frame.minX, inner.minX), maxX)
        var y = min(max(frame.minY, inner.minY), maxY)
        if x - inner.minX < snapDistance { x = inner.minX } else if maxX - x < snapDistance { x = maxX }
        if y - inner.minY < snapDistance { y = inner.minY } else if maxY - y < snapDistance { y = maxY }
        return CGPoint(x: x, y: y)
    }
}
