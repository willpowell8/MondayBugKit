//
//  ImageUtils.swift
//  RemoteLogTest
//


import Foundation
import UIKit
import ImageIO
import MobileCoreServices

class ImageUtils {
    static func resizeImage(image: UIImage, maxDimension: CGFloat) -> UIImage? {
        if image.size.width < maxDimension, image.size.height < maxDimension {
            // return image if less than max size
            return image
        }
        let scaleX = maxDimension / image.size.width
        let scaleY = maxDimension / image.size.height
        let scale = scaleY < scaleX ? scaleY : scaleX
        let newWidth = image.size.width * scale
        let newHeight = image.size.height * scale
        UIGraphicsBeginImageContext(CGSize(width: newWidth, height: newHeight))
        image.draw(in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    static func generateGif(photos: [UIImage], filename: String) -> String? {
        let documentsDirectoryPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let path = documentsDirectoryPath.appending("/\(filename)")
        let fileProperties = [kCGImagePropertyGIFDictionary as String: [kCGImagePropertyGIFLoopCount as String: 0]]
        let gifProperties = [kCGImagePropertyGIFDictionary as String: [kCGImagePropertyGIFDelayTime as String: 1.0]]
        let cfURL = URL(fileURLWithPath: path) as CFURL
        if let destination = CGImageDestinationCreateWithURL(cfURL, kUTTypeGIF, photos.count, nil) {
            CGImageDestinationSetProperties(destination, fileProperties as CFDictionary?)
            for photo in photos {
                CGImageDestinationAddImage(destination, photo.cgImage!, gifProperties as CFDictionary?)
            }
            if CGImageDestinationFinalize(destination) {
                return path
            }
        }
        return nil
    }
}
