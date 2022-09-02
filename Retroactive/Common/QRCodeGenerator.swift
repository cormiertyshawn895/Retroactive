//
//  QRCodeGenerator.swift
//  Retroactive
//

import AppKit

final class QRCodeGenerator {
    static func generate(string: String, size: CGSize) -> NSImage? {
        guard let data = string.data(using: .utf8) else {
            return nil
        }
        
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else {
            return nil
        }
        
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("Q", forKey: "inputCorrectionLevel")
        
        
        guard let ciImage = filter.outputImage else {
            return nil
        }
        
        guard let colorInvertFilter = CIFilter(name: "CIColorInvert") else { return nil }
        colorInvertFilter.setValue(ciImage, forKey: "inputImage")
        guard let outputInvertedImage = colorInvertFilter.outputImage else { return nil }
        
        guard let maskToAlphaFilter = CIFilter(name: "CIMaskToAlpha") else { return nil }
        maskToAlphaFilter.setValue(outputInvertedImage, forKey: "inputImage")
        guard let outputCIImage = maskToAlphaFilter.outputImage else { return nil }
        
        let rep = NSCIImageRep(ciImage: outputCIImage)
        let image = NSImage(size: rep.size)
        image.addRepresentation(rep)
        
        let finalImage = NSImage(size: size)
        finalImage.lockFocus()
        NSGraphicsContext.current?.imageInterpolation = .none
        image.draw(in: NSRect(origin: .zero, size: size))
        finalImage.unlockFocus()
        
        return finalImage
    }
}
