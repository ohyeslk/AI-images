//
//  AboutText.swift
//  AI • Scry
//
//  Created by Sam Kronick on 2/12/16.
//  Copyright © 2016 Disk Cactus. All rights reserved.
//

import Foundation

let aboutDiagramURL = NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("diagram", ofType: "png")!)

let aboutStyle = "<!doctype html><head>" +
                 //"<meta name='viewport' content='width=300, user-scalable=no, initial-scale=1.0' />" +
                 "<style>* { color: white; font-family: HelveticaNeue-Light; font-size: 15pt; }" +
                 "body, html { overflow-x: hidden; } " +
                 ".tagline { font-style: italic; text-align: center; } " +
                 "a { background-color: blue; padding: 0.25em; padding-right: 0.25em; text-decoration: none; font-style: italic; }" +
                 "img { width: 98%; border: 1px dotted white; }" +
                 ".section { text-align: left;  font-style: italic; margin-bottom: 0em; } " +
                 ".howitworks { font-size: 11pt; }" +
                 ".howitworks a { font-size: 11pt; }" +
                 ".define, .define a { font-size: 11pt; font-style: italic; } " +
                 "</style></head><body>"
let aboutPageA = aboutStyle +
                 //"<br><a href='aiscry://howitworks'>👉 How does it work?</a><p>" +
                 "<p>Adjust the \"Attention Aperature\" slider below to control the range of results.</p>"
