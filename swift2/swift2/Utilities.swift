//
//  Utilities.swift
//  AI Image
//
//  Created by Kai Lu on 1/26/16.
//  Copyright © 2016 Kai Lu. All rights reserved.
//

import Foundation
import UIKit


public extension Int {
    /// SwiftRandom extension
    public static func random(_ lower: Int = 0, _ upper: Int = 100) -> Int {
        return lower + Int(arc4random_uniform(UInt32(upper - lower + 1)))
    }
}

public extension Double {
    /// SwiftRandom extension
    public static func random(_ lower: Double = 0, _ upper: Double = 100) -> Double {
        return (Double(arc4random()) / 0xFFFFFFFF) * (upper - lower) + lower
    }
}

public extension Float {
    /// SwiftRandom extension
    public static func random(_ lower: Float = 0, _ upper: Float = 100) -> Float {
        return (Float(arc4random()) / 0xFFFFFFFF) * (upper - lower) + lower
    }
}

public extension CGFloat {
    /// SwiftRandom extension
    public static func random(_ lower: CGFloat = 0, _ upper: CGFloat = 1) -> CGFloat {
        return CGFloat(Float(arc4random()) / Float(UINT32_MAX)) * (upper - lower) + lower
    }
}

extension CGImage {
    //func resize(scale:CGFloat)-> CGImage {
    func scale(_ scale:CGFloat)-> CGImage {
        let image = UIImage(cgImage: self)
        let imageView = UIImageView(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: image.size.width*scale, height: image.size.height*scale)))
        imageView.contentMode = UIViewContentMode.scaleAspectFit
        imageView.image = image
        UIGraphicsBeginImageContext(imageView.bounds.size)
        imageView.layer.render(in: UIGraphicsGetCurrentContext()!)
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result!.cgImage!
    }
    
    func resize(_ size:CGSize)-> CGImage {
        let image = UIImage(cgImage: self)
        let imageView = UIImageView(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: size))
        imageView.contentMode = UIViewContentMode.scaleAspectFill
        imageView.image = image
        UIGraphicsBeginImageContext(imageView.bounds.size)
        imageView.layer.render(in: UIGraphicsGetCurrentContext()!)
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return result!.cgImage!
    }
}

func delay(_ delay:Double, closure:@escaping ()->()) {
    DispatchQueue.main.asyncAfter(
        deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: closure)
}
