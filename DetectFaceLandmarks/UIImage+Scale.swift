//
//  UIImage+Scale.swift
//  AICamera
//
//  Created by mathieu on 08/06/2017.
//  Copyright © 2017 mathieu. All rights reserved.
//

import UIKit
import CoreMedia

extension UIImage {

    convenience init?(sampleBuffer: CMSampleBuffer) {

        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }
        CVPixelBufferLockBaseAddress(imageBuffer, CVPixelBufferLockFlags.readOnly)

        let baseAddress = CVPixelBufferGetBaseAddress(imageBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer)
        let width = CVPixelBufferGetWidth(imageBuffer)
        let height = CVPixelBufferGetHeight(imageBuffer)
        let colorSpace = CGColorSpaceCreateDeviceRGB()

        let bitmapInfo: UInt32 = CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue & CGBitmapInfo.alphaInfoMask.rawValue
        guard let context = CGContext(data: baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo) else { return nil }
        let quartzImage = context.makeImage()
        CVPixelBufferUnlockBaseAddress(imageBuffer, CVPixelBufferLockFlags.readOnly)

        if let quartz = quartzImage {
            self.init(cgImage: quartz, scale: 1.0, orientation: .right)
            //self.init(cgImage: quartz)
        } else {
            return nil
        }
    }

    func hasAlpha() -> Bool {
        if let cgImage = self.cgImage {
            let alpha = cgImage.alphaInfo
            return alpha == .first || alpha == .last || alpha == .premultipliedFirst || alpha == .premultipliedLast
        }
        return false
    }

    func flipped() -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(self.size, !self.hasAlpha(), self.scale)
        let context = UIGraphicsGetCurrentContext()!
        context.translateBy(x: self.size.width, y: 0.0)
        context.scaleBy(x: -1.0, y: 1.0)
        let rect = CGRect(origin: .zero, size: self.size)
        self.draw(in: rect)
        let retVal = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return retVal
    }

    func imageWithAspectFit(size:CGSize) -> UIImage? {
        let aspectFitSize = self.getAspectFitSize(destination: size)
        let resizedImage = self.resize(size: aspectFitSize)
        return resizedImage
    }

    private func getAspectFitSize(destination dst:CGSize) -> CGSize {
        var result = CGSize.zero
        var scaleRatio = CGPoint()

        if (dst.width != 0) {scaleRatio.x = self.size.width / dst.width}
        if (dst.height != 0) {scaleRatio.y = self.size.height / dst.height}
        let scaleFactor = max(scaleRatio.x, scaleRatio.y)

        result.width  = scaleRatio.x * dst.width / scaleFactor
        result.height = scaleRatio.y * dst.height / scaleFactor
        return result
    }

    func resize(size:CGSize) -> UIImage? {
        let imageRect = CGRect(origin: .zero, size: size);

        UIGraphicsBeginImageContextWithOptions(size, false, 1.0);
        self.draw(in: imageRect)
        let scaled = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return scaled
    }
}
