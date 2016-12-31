//
//  SpeechDelegate.swift
//  AI Image
//
//  Created by Kai Lu on 2/6/16.
//  Copyright © 2016 Kai Lu. All rights reserved.
//

import Foundation
import AVFoundation


class SpeechDelegate : NSObject, AVSpeechSynthesizerDelegate {
    var isSpeaking = false
    
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        self.isSpeaking = false
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        self.isSpeaking = true
    }
}
