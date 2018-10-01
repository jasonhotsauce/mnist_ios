//
//  PixelBuffPipline.swift
//  MNIST
//
//  Created by Wenbin Zhang on 9/27/18.
//  Copyright © 2018 Wenbin Zhang. All rights reserved.
//

import UIKit

typealias PixelBuffSize = CGSize
typealias LayerContent = (CALayer, PixelBuffSize) -> CGContext?
typealias ViewPixelConverter = (CGContext) -> CVPixelBuffer?
typealias Pipline = (CALayer, PixelBuffSize) -> CVPixelBuffer?

func content() -> LayerContent {
    return { layer, size in
        let colorSpace = CGColorSpaceCreateDeviceGray()
        let bitmapInfo = CGImageAlphaInfo.none.rawValue
        guard let context = CGContext(data: nil,
                                      width: Int(size.width),
                                      height: Int(size.height),
                                      bitsPerComponent: 8,
                                      bytesPerRow: Int(size.width) * 8,
                                      space: colorSpace,
                                      bitmapInfo: bitmapInfo) else {
                                        return nil
        }
        context.translateBy(x: 0, y: size.height)
        context.scaleBy(x: size.width/layer.bounds.width, y: (-1 * size.height)/layer.bounds.height)
        layer.render(in: context)
        return context
    }
}

func pixelBuff() -> ViewPixelConverter {
    return { context in
        let attr = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
                    kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        var pixelBuffOrNil: CVPixelBuffer?
        CVPixelBufferCreate(kCFAllocatorDefault,
                            context.width,
                            context.height,
                            kCVPixelFormatType_OneComponent8,
                            attr,
                            &pixelBuffOrNil)
        guard let pixelBuff = pixelBuffOrNil else { return nil }
        guard let cgImage = context.makeImage() else { return nil }
        let ciImage = CIImage(cgImage: cgImage)
        let ciContext = CIContext()
        ciContext.render(ciImage, to: pixelBuff)
        return pixelBuff
    }
}

func layerContentToPixelBuffPipline(first content: @escaping LayerContent, then converter: @escaping ViewPixelConverter) -> Pipline {
    return { layer, size in
        guard let context = content(layer, size) else {
            return nil
        }
        return converter(context)
    }
}
