//
//  Particle.swift
//  AI Image
//
//  Created by Kai Lu on 2/12/16.
//  Copyright © 2016 Kai Lu. All rights reserved.
//

import UIKit

class Particle {
    let characters = "👌👯💕🚶👗😢💁👯🚶⚡️😨😘🙏🚶⚡️🗻🙏🏄😂✋👌🌵😎😢🎈👗💾🌵💊😎😢💕👗👌👯💁😂🚶🗻👌🌍🏄😀💾🌵️🐳💰😻🐣🌺🍆💰🐣💾🍺😈🍕😻😂😘😀🙌😂🗻🌍👌🙌🏄😀😂👶👌🌍😀🏄🙌😂🗻😀🏄🙌😂👌🌺🍆😻️🐳💰😈👌😎👌😆👐😜🆗😆👐😍😱🏃 🆗👐🔥😍💎💸🆗😆👐😜😍😱🔥🆗🐝🍌🌐🌋💸🔮👵🍌🌐💽🍌🍻👿👿👿👿👿👿💽🐝💸💽🐝🔥🍌😱😉👋🔥😆😜👕👐💽🐘🆗😹😜🆗😆👐👋😜😱🆗🐝👋💸🐝🍌💖💉💸🆗🐘🍔😹🐘👐🎯🆗😆😜😹🙅🌞🆗🏃🎯🌞☔️💾🌵💾🌵💾🌵🌊🌊🌽💱🌊👺👺🐖👽👺🐓🍷🌽💱🍷🙀👻🚽🐔🙀🍸👻👻👻🚽💜👂🐒🚂🎱🌌🏂🙋🚽💜💄⛄️💊🐝🐘🐘🐘🐘🐘😹🆗👐🌹🐘😉👅🔥👋😱🏃👭🙅🌋🏃🔮👵🆗🌹🌹🐧🐱🌟🐒😲😠💋🐒😲💋🐒😲✏️💋🐒💋😲✏️🚂🚂💰🍕😈😎🚽✊😝💣🙀😴💣🐍💳💄🍴🍉💳🍴😌💪👫🙋😅🗼👫🍸🙋🍉🍴🍸🌸🐬🙋🍉💳🙋💳🍴🙋"
    var view = UITextView()
    var origin = CGPoint()
    init(parent: UIView, origin: CGPoint, energy: Float) {
        self.view.text = String(characters[characters.characters.index(characters.startIndex, offsetBy: Int.random(0, characters.characters.count - 1))])
        self.view.center = origin
        self.view.alpha = 0
        self.view.isOpaque = false
        self.view.backgroundColor = UIColor.clear
        self.view.sizeToFit()
        self.view.font = UIFont(name: "Apple Color Emoji", size: 36)
        self.view.layer.anchorPoint = CGPoint(x: self.view.layer.anchorPoint.x + CGFloat.random(-0.3, 0.3), y: self.view.layer.anchorPoint.y + CGFloat.random(-0.3, 0.3))
        parent.addSubview(self.view)
        
        UIView.animate(withDuration: Double.random(0.3, 0.6), delay: 0, options: .curveEaseOut, animations: {
            self.view.center = CGPoint(x: CGFloat.random(-100, 100) + self.view.center.x, y: CGFloat.random(-50 , -200) * CGFloat(energy) + self.view.center.y)
            self.view.transform = CGAffineTransform(rotationAngle: CGFloat.random(-10, 10))
            }, completion: { (b) -> Void in
            self.view.removeFromSuperview()
        })

        // Fade in and out
        UIView.animate(withDuration: Double.random(0.06, 0.15), delay: 0, options: [], animations: {
            self.view.alpha = 1
            }, completion: { (b) -> Void in
                UIView.animate(withDuration: Double.random(0.15, 0.3), delay: Double.random(0.06, 0.1), options: [], animations: {
                    self.view.alpha = 0
                    }, completion: nil)
        })
        
    }
}
