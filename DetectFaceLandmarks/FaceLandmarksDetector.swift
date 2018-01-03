//
//  FaceLandmarksDetector.swift
//  DetectFaceLandmarks
//
//  Created by mathieu on 09/07/2017.
//  Copyright © 2017 mathieu. All rights reserved.
//

import UIKit
import Vision

class FaceLandmarksDetector {

    open func highlightFaces(for source: UIImage, complete: @escaping (UIImage) -> Void) {
        var resultImage = source
        let detectFaceRequest = VNDetectFaceLandmarksRequest { (request, error) in
            if error == nil {
                if let results = request.results as? [VNFaceObservation] {
                    for faceObservation in results {
                        guard let landmarks = faceObservation.landmarks else {
                            continue
                        }
                        let boundingRect = faceObservation.boundingBox

                        resultImage = self.drawOnImage(source: resultImage, boundingRect: boundingRect, faceLandmarks: landmarks)
                    }
                }
            } else {
                print(error!.localizedDescription)
            }
            complete(resultImage)
        }

        let vnImage = VNImageRequestHandler(cgImage: source.cgImage!, options: [:])
        try? vnImage.perform([detectFaceRequest])
    }

    private func drawOnImage(source: UIImage, boundingRect: CGRect, faceLandmarks: VNFaceLandmarks2D) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(source.size, false, 1)
        let context = UIGraphicsGetCurrentContext()!
        context.translateBy(x: 0.0, y: source.size.height)
        context.scaleBy(x: 1.0, y: -1.0)
        //context.setBlendMode(CGBlendMode.colorBurn)
        context.setLineJoin(.round)
        context.setLineCap(.round)
        context.setShouldAntialias(true)
        context.setAllowsAntialiasing(true)

        let rectWidth = source.size.width * boundingRect.size.width
        let rectHeight = source.size.height * boundingRect.size.height

        //draw image
        let rect = CGRect(x: 0, y:0, width: source.size.width, height: source.size.height)
        context.draw(source.cgImage!, in: rect)


        //draw bound rect
        context.setStrokeColor(UIColor.green.cgColor)
        context.addRect(CGRect(x: boundingRect.origin.x * source.size.width, y:boundingRect.origin.y * source.size.height, width: rectWidth, height: rectHeight))
        context.drawPath(using: CGPathDrawingMode.stroke)

        //draw overlay
        context.setLineWidth(1.0)

        func drawFeature(_ feature: VNFaceLandmarkRegion2D, color: CGColor, close: Bool = false) {
            context.setStrokeColor(color)
            context.setFillColor(color)
            for point in feature.normalizedPoints {
                // Draw DEBUG numbers
                let textFontAttributes = [
                    NSAttributedStringKey.font: UIFont.systemFont(ofSize: 16),
                    NSAttributedStringKey.foregroundColor: UIColor.white
                ]
                context.saveGState()
                // rotate to draw numbers
                context.translateBy(x: 0.0, y: source.size.height)
                context.scaleBy(x: 1.0, y: -1.0)
                let mp = CGPoint(x: boundingRect.origin.x * source.size.width + point.x * rectWidth, y: source.size.height - (boundingRect.origin.y * source.size.height + point.y * rectHeight))
                context.fillEllipse(in: CGRect(origin: CGPoint(x: mp.x-2.0, y: mp.y-2), size: CGSize(width: 4.0, height: 4.0)))
                if let index = feature.normalizedPoints.index(of: point) {
                    NSString(format: "%d", index).draw(at: mp, withAttributes: textFontAttributes)
                }
                context.restoreGState()
            }
            let mappedPoints = feature.normalizedPoints.map { CGPoint(x: boundingRect.origin.x * source.size.width + $0.x * rectWidth, y: boundingRect.origin.y * source.size.height + $0.y * rectHeight) }
            context.addLines(between: mappedPoints)
            if close, let first = mappedPoints.first, let lats = mappedPoints.last {
                context.addLines(between: [lats, first])
            }
            context.strokePath()
        }
        
        if let faceContour = faceLandmarks.faceContour {
            drawFeature(faceContour, color: UIColor.magenta.cgColor)
        }

        if let leftEye = faceLandmarks.leftEye {
            drawFeature(leftEye, color: UIColor.cyan.cgColor, close: true)
        }
        if let rightEye = faceLandmarks.rightEye {
            drawFeature(rightEye, color: UIColor.cyan.cgColor, close: true)
        }
        if let leftPupil = faceLandmarks.leftPupil {
            drawFeature(leftPupil, color: UIColor.cyan.cgColor, close: true)
        }
        if let rightPupil = faceLandmarks.rightPupil {
            drawFeature(rightPupil, color: UIColor.cyan.cgColor, close: true)
        }

        if let nose = faceLandmarks.nose {
            drawFeature(nose, color: UIColor.green.cgColor)
        }
        if let noseCrest = faceLandmarks.noseCrest {
            drawFeature(noseCrest, color: UIColor.green.cgColor)
        }

        if let medianLine = faceLandmarks.medianLine {
            drawFeature(medianLine, color: UIColor.gray.cgColor)
        }

        if let outerLips = faceLandmarks.outerLips {
            drawFeature(outerLips, color: UIColor.red.cgColor, close: true)
        }
        if let innerLips = faceLandmarks.innerLips {
            drawFeature(innerLips, color: UIColor.red.cgColor, close: true)
        }

        if let leftEyebrow = faceLandmarks.leftEyebrow {
            drawFeature(leftEyebrow, color: UIColor.blue.cgColor)
        }
        if let rightEyebrow = faceLandmarks.rightEyebrow {
            drawFeature(rightEyebrow, color: UIColor.blue.cgColor)
        }

        let coloredImg : UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return coloredImg
    }

}
