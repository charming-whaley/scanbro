import SwiftUI

extension CGSize {
    public func adjustSize(to: CGSize) -> CGSize {
        let aspectRatio = min(to.width / self.width, to.height / self.height)
        return .init(width: aspectRatio * width, height: aspectRatio * height)
    }
}
