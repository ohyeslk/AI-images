//
//  ViewController.swift
//  AI Image
//
//  Created by Kai Lu on 1/25/16.
//  Copyright © 2016 Kai Lu. All rights reserved.
//

import UIKit
import AVFoundation


class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate, AVAudioPlayerDelegate, UIWebViewDelegate {

    @IBOutlet weak var 🔮button: UIButton!
    @IBOutlet weak var spinnerImage: UIImageView!
    
    @IBOutlet weak var CaptionsView: UIView!
    @IBOutlet weak var TemperatureSlider: UISlider!
    @IBOutlet weak var SliderView: UIView!
    @IBOutlet weak var SliderMaskView: UIView!
    
    @IBOutlet weak var AboutView: UIView!
    @IBOutlet weak var AccessErrorText: UITextView!
    
    @IBOutlet weak var AboutWebViewText: UIWebView!
    var gradientLayer: CAGradientLayer!
    
    let update_frequency = 5.0 as Double
    let request_n_captions = 5 as Int
    
    let captureSession = AVCaptureSession()
    var captureDevice : AVCaptureDevice?
    var previewLayer : AVCaptureVideoPreviewLayer?
    var stillImageOutput = AVCaptureStillImageOutput()
    
    var videoDataOutput = AVCaptureVideoDataOutput()
    var videoDataOutputQueue:DispatchQueue = DispatchQueue(label: "VideoDataOutputQueue", attributes: []);
    
    var waitingForCaptions = false
    var captionsCued = false
    var currentTemperature = 0.5 as Float
    
    var captions = [Caption]()
    var captionSlot = 0
    
    var audioPlayers = [AVAudioPlayer]()
    let instrumentNames = ["pluck", "short", "plinky", "zero", "bell", "tri"]
    
    var processingVideoFrame = false
    var needsNewFrame = false
    
    var recentJPEG: Data?
    var recentVideoFrame: UIImage?
    
    let synthesizer = AVSpeechSynthesizer()
    let speechDelegate = SpeechDelegate()
	
	var soundURL: URL?

	
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Check to see if we need to request camera access
        switch AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo) {
            case .authorized:
                print("Camera access OK")
                self.AccessErrorText.isHidden = true
                beginSession()
            case .denied, .restricted:
                print("Camera access DENIED")
                self.AccessErrorText.isHidden = false
            case .notDetermined:
                print("Requesting camera access...")
                AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeVideo, completionHandler: { (granted) -> Void in
                    if(granted) {
                        print("Camera access granted")
                        DispatchQueue.main.async(execute: {
                            self.AccessErrorText.isHidden = true
                            self.showAboutView(self)
                            self.beginSession()
                        })
                    }
                    else {
                        print("Camera access denied!")
                        DispatchQueue.main.async(execute: {
                            self.AccessErrorText.isHidden = false
                        })
                    }
                })
        }
        
        
        // Add perspective effects to CaptionsView layers
        var perspectiveTransform = CATransform3DIdentity;
        perspectiveTransform.m34 = 1.0 / -350;
        CaptionsView.layer.sublayerTransform = perspectiveTransform;
        
        spinnerImage.alpha = 0
        rotate🌀(true)
        
        // Automagically get captions every 5 seconds
        self.captureAndSendFrame(nil)
        Timer.scheduledTimer(timeInterval: self.update_frequency, target: self, selector: #selector(ViewController.captureAndSendFrame(_:)), userInfo: nil, repeats: true)
        
        
        // Load sound effects
//        for instrument in self.instrumentNames {
//            for n in 1...6 {
//                let soundPath = NSBundle.mainBundle().pathForResource(instrument + "-" + String(n), ofType: "aiff")
//				
//                soundURL = NSURL(fileURLWithPath: soundPath!)
//				if let url = soundURL {
//					do {
//						let soundPlayer = try AVAudioPlayer(contentsOfURL: url)
//						soundPlayer.delegate = self
//						soundPlayer.volume = 1.0
//						soundPlayer.prepareToPlay()
//						self.audioPlayers.append(soundPlayer)
//					}
//					catch {
//						print("Couldn't open sound: " + soundPath!)
//					}
//					
//				}
//            }
//        }
		
        synthesizer.delegate = speechDelegate;
        
        
        AboutView.isHidden = true
        AboutWebViewText.delegate = self
        AboutWebViewText.loadHTMLString(aboutPageA, baseURL: nil)
        //AboutWebViewText.scrollView.scrollEnabled = false

        
    }
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        webView.scrollView.contentSize = CGSize(width: webView.frame.size.width, height: webView.scrollView.contentSize.height)
    }
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        if navigationType == UIWebViewNavigationType.linkClicked {
            UIApplication.shared.openURL(request.url!)
            return false
        }
        return true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        // View bounds are set at this point so we can set up subviews
        
        super.viewWillAppear(animated)
        
        // Add in a gradient background to the slider mask view
        if self.gradientLayer == nil{
            self.gradientLayer = CAGradientLayer()
            self.gradientLayer.startPoint = CGPoint(x: 0, y:0)
            self.gradientLayer.endPoint = CGPoint(x: 1, y: 0)    // Make a horizontal gradient
            // Frame is relative to parent view, so origin needs to be 0,0
            self.gradientLayer.frame = CGRect(x: 0, y: 0, width: self.SliderView.frame.width, height: self.SliderView.frame.height)
            self.gradientLayer.colors = [
                UIColor(red: 0.0,  green: 1.0,  blue: 0.0,  alpha: 1.0).cgColor,
                UIColor(red: 0.0,  green: 0.75, blue: 1.0,  alpha: 1.0).cgColor,
                UIColor(red: 1.0,  green: 0.0,  blue: 1.0,  alpha: 1.0).cgColor,
                UIColor(red: 1.0,  green: 0.19, blue: 0.19, alpha: 1.0).cgColor,
                UIColor(red: 1.0,  green: 1.0,  blue: 0.0,  alpha: 1.0).cgColor
            ]
            self.SliderMaskView.layer.insertSublayer(self.gradientLayer, at: 0)
            self.SliderMaskView.clipsToBounds = true
            self.gradientLayer.opacity = 0.75
        }
        
        // Update the temperature slider at the start
        self.temperatureChanged(self.TemperatureSlider)
        
        UIView.animate(withDuration: 3, animations: {
            self.TemperatureSlider.setValue(0.5, animated: true)
            self.setTemperatureBGForValue(0.5)
        })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func willAnimateRotation(to toInterfaceOrientation: UIInterfaceOrientation,
         duration: TimeInterval) {
        if toInterfaceOrientation == .landscapeLeft {
            self.previewLayer?.transform = CATransform3DMakeRotation(CGFloat(M_PI / 2.0), 0, 0, 1.0)
        }
        else if toInterfaceOrientation == .landscapeRight {
            self.previewLayer?.transform = CATransform3DMakeRotation(CGFloat(-M_PI / 2.0), 0, 0, 1.0)
        }
        else {
            self.previewLayer?.transform = CATransform3DMakeRotation(0, 0, 0, 1.0)
        }
        
        self.previewLayer?.frame = self.view.frame
        
        // Update the temperature slider
        self.temperatureChanged(self.TemperatureSlider)
        
        // Update the temperature slider gradient's frame
        self.gradientLayer.frame = CGRect(x: 0, y: 0, width: self.SliderView.frame.width, height: self.SliderView.frame.height)
          
        // Resize webview content
        self.webViewDidFinishLoad(AboutWebViewText)
            
        // Re-center captions
            for c in self.captions {
                c.view.frame.origin = CGPoint(x: -c.padding - c.view.frame.width / 2 + c.parentView!.frame.width / 2, y: c.view.frame.origin.y)
            }
}

    func beginSession() {
        captureSession.sessionPreset = AVCaptureSessionPresetHigh
        let devices = AVCaptureDevice.devices()
        for device in devices! {
            if((device as AnyObject).hasMediaType(AVMediaTypeVideo)) {
                if((device as AnyObject).position == AVCaptureDevicePosition.back) {
                    captureDevice = device as? AVCaptureDevice
                }
            }
        }
        
        if(captureDevice == nil) { return }
        
        do {
            try captureSession.addInput(AVCaptureDeviceInput(device: captureDevice))
        } catch {
            print("Couldn't open camera.")
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        self.view.layer.insertSublayer(previewLayer!, below: CaptionsView.layer)
        previewLayer?.frame = self.view.layer.frame
        captureSession.startRunning()
        
        videoDataOutput.alwaysDiscardsLateVideoFrames=true;
        videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as AnyHashable:Int(kCVPixelFormatType_32BGRA)]
        videoDataOutput.setSampleBufferDelegate(self, queue:self.videoDataOutputQueue)

        if captureSession.canAddOutput(videoDataOutput){
            captureSession.addOutput(videoDataOutput)
        }
    }
    
    // this gets called periodically with an image
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        if(processingVideoFrame || !needsNewFrame) { return }
        processingVideoFrame = true
        
        var orientation = UIImageOrientation.right
        if self.interfaceOrientation == .landscapeLeft {
            orientation = UIImageOrientation.down
        }
        else if self.interfaceOrientation == .landscapeRight {
            orientation = UIImageOrientation.up
        }
        
        let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
        CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue)
        let cgImageRef = context?.makeImage()
        
        CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))

        self.recentVideoFrame = UIImage(cgImage: cgImageRef!, scale: 1.0, orientation: orientation)
        
        // Resize to 256x256px
        // TODO: Make this a center crop
        let scaledContext = CGContext(data: nil, width: 256, height: 256, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue)
        scaledContext!.interpolationQuality = .high
        
        if width > height {
            let _w = CGFloat(Double(width) * 256.0/Double(height))
            let origin = CGPoint(x: -(_w - 256) / 2, y: 0)
            scaledContext?.draw(cgImageRef!, in: CGRect(origin: origin, size: CGSize(width: _w, height: CGFloat(256))))
        }
        else {
            let _h = CGFloat(Double(height) * 256.0/Double(width))
            let origin = CGPoint(x: 0, y: -(_h - 256) / 2)
            scaledContext?.draw(cgImageRef!, in: CGRect(origin: origin, size: CGSize(width: CGFloat(256), height: _h)))
        }
        

        
        let scaledImage = scaledContext?.makeImage()
    
        
        let image = UIImage(cgImage: scaledImage!, scale: 1.0, orientation: orientation)
        
        self.recentJPEG = UIImageJPEGRepresentation(image, 0.5)
        
        self.needsNewFrame = false
        self.processingVideoFrame = false
    }
    
    @IBAction func temperatureChanged(_ sender: UISlider) {
        self.currentTemperature = sender.value
        print(sender.value)
        self.setTemperatureBGForValue(sender.value)
    }
    
    func setTemperatureBGForValue(_ value: Float) {
        let percent = CGFloat((value - TemperatureSlider.minimumValue) / (TemperatureSlider.maximumValue - TemperatureSlider.minimumValue))
        var sliderX = TemperatureSlider.frame.height / 2 + (self.view.bounds.width - TemperatureSlider.frame.height) * percent
        self.SliderMaskView.frame = CGRect(x: self.SliderMaskView.frame.origin.x, y: self.SliderMaskView.frame.origin.y, width: sliderX, height: self.SliderMaskView.bounds.height)
        
        sliderX -= TemperatureSlider.frame.height / 2
        let _ = Particle(parent: self.view, origin: CGPoint(x: sliderX, y: self.TemperatureSlider.frame.origin.y), energy: value)
    }
    
    func emitParticleAtSlider(_ value: Float) {
        let percent = CGFloat((value - TemperatureSlider.minimumValue) / (TemperatureSlider.maximumValue - TemperatureSlider.minimumValue))
        var sliderX = TemperatureSlider.frame.height / 2 + (self.view.bounds.width - TemperatureSlider.frame.height) * percent
        sliderX -= TemperatureSlider.frame.height / 2
        let _ = Particle(parent: self.view, origin: CGPoint(x: sliderX, y: self.TemperatureSlider.frame.origin.y), energy: value)
    }
    
    @IBAction func captureAndSendFrame(_ sender: UIButton?) {
        // Check to see if a request is currently pending. Wait for a second if so
        if waitingForCaptions {
            if !captionsCued {
                captionsCued = true
                Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(ViewController.captureAndSendFrame(_:)), userInfo: nil, repeats: false)
            }
            
            return
        }
        self.needsNewFrame = true
        self.waitingForCaptions = true
        self.captionsCued = false
        self.sendImageToServer()

    }
    
    func sendImageToServer() -> Bool {
        let image = self.recentJPEG
        if(self.needsNewFrame || image == nil) {
            delay(0.1) {
                self.sendImageToServer()
            }

            return false;
            
        }
        
        let request = NSMutableURLRequest(url: URL(string: "http://u1f52e.net/captionsForImage")!)
        let session = URLSession.shared
        request.httpMethod = "POST"
        
        let encodedImage = image!.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
        //print(encodedImage)
        let params = [
            "image": encodedImage,
            "temperature": "\(self.currentTemperature)",
            "n": String(self.request_n_captions),
            "uuid": UIDevice.current.identifierForVendor!.uuidString
            ] as Dictionary<String, String>
        //let params = ["image": "None", "temperature": "0.5", "n": "10"] as Dictionary<String, String>
        
        do {
            print("Sending request with image as Base64-encoded jpeg...")
            self.show🌀()
            try request.httpBody = JSONSerialization.data(withJSONObject: params, options: JSONSerialization.WritingOptions(rawValue: 0))
            //print(NSString(data: request.HTTPBody!, encoding: NSUTF8StringEncoding))
            request.addValue("application/json", forHTTPHeaderField:  "Content-Type")
            request.addValue("application/json", forHTTPHeaderField:  "Accept")
            
            let temperatureWhenRequestWasSent = self.currentTemperature
            
            let task = session.dataTask(with: request as URLRequest, completionHandler: {(data, response, error) -> Void in
                //let stringData = NSString(data: data!, encoding: NSUTF8StringEncoding)
                //print("Response: \(response)")
                //print("Body: \(stringData)")
                //print("Response received")
                do {
                    let json = try JSONSerialization.jsonObject(with: data!, options: .mutableLeaves) as? NSDictionary
                    let newCaptions = (json!["captions"] as AnyObject).components(separatedBy: "\n")
                    
                    DispatchQueue.main.sync(execute: {
                        // Clear out any old, dead captions
                        var survivingCaptions = [Caption]()
                        for c in self.captions {
                            if(c.alive) {
                                survivingCaptions.append(c)
                            }
                        }
                        self.captions = survivingCaptions
                    })
                    
                    
                    var i = 0
                    for c in newCaptions {
                        if c == "" { continue }
                        DispatchQueue.main.sync(execute: {
                            let newCaption = Caption(text: c, parent: self.CaptionsView!, slot: self.captionSlot % Caption.n_slots)
                            self.captionSlot += Int.random(5,10)
                            self.captions.append(newCaption)
                            delay(Double(i+1) * 1) {
                                newCaption.enter()
                                
//                                let instrument = (temperatureWhenRequestWasSent - 0.1) / 1.91 * Float(self.instrumentNames.count)
//                                self.audioPlayers[Int(instrument) * 6 + Int.random(0,5)].play()
								
                                // iOS speech synthesis is flakey between 8 and 9, so set default utterance rate based on iOS version
                                var minRate = 0.15 as Float
                                var maxRate = 0.5 as Float
                                if (UIDevice.current.systemVersion as NSString).floatValue > 9 {
                                    minRate = 0.45
                                    maxRate = 0.6
                                }



                                let allVoices = AVSpeechSynthesisVoice.speechVoices()
                                var englishVoices = [AVSpeechSynthesisVoice]()
                                for v in allVoices {
                                    if v.language.hasPrefix("en") {
                                        englishVoices.append(v)
                                    }
                                }
                                
                                let utterance = AVSpeechUtterance(string: c)

                                utterance.rate = Float.random(minRate,maxRate) * 0.6
                                utterance.pitchMultiplier = Float.random(0.5,2)
                            
                                if Int.random(0,10) < 4 {
                                    utterance.voice = allVoices[Int.random(0, allVoices.count-1)]
                                }
                                else {
                                    utterance.voice = englishVoices[Int.random(0, englishVoices.count-1)]
                                }
                                
                                if !self.speechDelegate.isSpeaking {
                                    self.synthesizer.speak(utterance)
                                }
                            }
                        })
                    }

                    
                    
                } catch {
                    print(error)
                }
                
                DispatchQueue.main.sync(execute: {
                    self.hide🌀()
                    self.waitingForCaptions = false
                })
                
            })
            
            task.resume()
            return true
        } catch {
            print("Could not send request.")
            return false
        }
        
    }

    
    func rotate🌀(_ b: Bool) {
        func complete(_ b: Bool) {
            UIView.animate(withDuration: 0.5, delay: 0, options: .curveLinear, animations: {
                self.spinnerImage.transform = CGAffineTransform(rotationAngle: CGFloat(M_PI * 2))
                }, completion: rotate🌀)
        }
        UIView.animate(withDuration: 0.5, delay: 0, options: .curveLinear, animations: {
            self.spinnerImage.transform = CGAffineTransform(rotationAngle: CGFloat(M_PI))
            }, completion: complete)
    }
    
    func show🌀() {
        UIView.animate(withDuration: 1, animations: {
            self.spinnerImage.alpha = 1
        })
        
        UIView.animate(withDuration: 0.2, animations: {
            self.🔮button.transform = CGAffineTransform(scaleX: 1.1, y: 1.1).rotated(by: CGFloat.random(-0.2, 0.2))
            }, completion: { (b) -> Void in
                UIView.animate(withDuration: 0.2, animations: {
                    self.🔮button.transform = CGAffineTransform.identity
                }, completion: nil)
        })
    }
    func hide🌀() {
        UIView.animate(withDuration: 1, animations: {
            self.spinnerImage.alpha = 0
        })
    }
    
    @IBAction func showAboutView(_ sender: AnyObject) {
        self.AboutView.alpha = 0
        self.AboutView.isHidden = false
        UIView.animate(withDuration: 0.5, animations: {

            self.AboutView.alpha = 1
        }, completion: nil)
        
        
        UIView.animate(withDuration: 0.5, delay: 1, options: [.curveEaseOut, .beginFromCurrentState],  animations: {
            self.TemperatureSlider.setValue(1.75, animated: true)
            self.setTemperatureBGForValue(1.75)
            }, completion: {(b) -> Void in
                delay(0.1) {
                    for i in 0...20 {
                        delay(Double(i) * 0.01) {
                            self.emitParticleAtSlider(1.75)
                        }
                    }
                }
                
                UIView.animate(withDuration: 0.8, delay: 1, options: [.curveEaseOut, .beginFromCurrentState],  animations: {
                    self.TemperatureSlider.setValue(0.5, animated: true)
                    self.setTemperatureBGForValue(0.5)
                    }, completion: {(b) -> Void in
                        delay(0.1) {
                            for i in 0...10 {
                                delay(Double(i) * 0.01) {
                                    self.emitParticleAtSlider(0.5)
                                }
                            }
                        }
                    }
                )
            }
        )
        
        

    }
    
    @IBAction func hideAboutView(_ sender: AnyObject) {
        UIView.animate(withDuration: 0.5, animations: {
            self.AboutView.alpha = 0
        }, completion: {(b) -> Void in self.AboutView.isHidden = true; })
        
        UIView.animate(withDuration: 0.3, delay: 0, options: [.beginFromCurrentState, .curveEaseOut],  animations: {
            self.TemperatureSlider.setValue(0.5, animated: true)
            self.setTemperatureBGForValue(0.5)
            }, completion: {(b) -> Void in

            }
        )
        
    }
    @IBAction func screenShotMethod(_ sender: UIButton) {
        return;
        //Create the UIImage
        UIGraphicsBeginImageContext(view.frame.size)
        recentVideoFrame?.draw(in: view.frame)
        self.view.layer.render(in: UIGraphicsGetCurrentContext()!)
        //view.layer.renderInContext(UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        //Save it to the camera roll
        UIImageWriteToSavedPhotosAlbum(image!, nil, nil, nil)
    }
    
    
    
}



