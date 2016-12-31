//
//  random.swift
//  
//
//  Created by Kai Lu on 7/7/16.
//
//
import Foundation
import CoreGraphics

public extension CGFloat{
	
	public static func random() -> CGFloat{
		return CGFloat(Float(arc4random()) / 0xFFFFFFFF)
	}
	
	public static func random(min : CGFloat, max : CGFloat) -> CGFloat{
		return CGFloat.random() * (max - min) + min
	}
}
