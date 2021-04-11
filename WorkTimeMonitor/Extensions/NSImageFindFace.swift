import Cocoa

extension NSImage {
    var ciImage: CIImage? {
        guard let data = tiffRepresentation else { return nil }
        return CIImage(data: data)
    }
    var faces: [NSImage] {
        guard let ciImage = ciImage else { return [] }
        return (CIDetector(ofType: CIDetectorTypeFace, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])?
            .features(in: ciImage) as? [CIFaceFeature])?
            .map {
                let ciimage = ciImage.cropped(to: $0.bounds)  // Swift 3 use cropping(to:)
                let imageRep = NSCIImageRep(ciImage: ciimage)
                let nsImage = NSImage(size: imageRep.size)
                nsImage.addRepresentation(imageRep)
                return nsImage
            }  ?? []
    }
}
