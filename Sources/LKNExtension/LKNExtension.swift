//
//  LKNExtension.swift
//  Swift Package
//
//  Created by Arnold Lee on 2019/10/24.
//  Copyright © 2019 Arnold Lee. All rights reserved.
//

import Foundation
import UIKit
import ImageIO

//  MARK: - UIColor
extension UIColor{
    /** An easy way to get the color by providing the hexstring */
    public convenience init(hexString: String) {
        let hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int = UInt32()
        Scanner(string: hex).scanHexInt32(&int)
        let a, r, g, b: UInt32
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
    }
    /** Return UIColor lighter */
    public func lighter(by percentage: CGFloat = 50.0) -> UIColor? {
        return self.adjust(by: abs(percentage) )
    }
    /** Return UIColor darker */
    public func darker(by percentage: CGFloat = 50.0) -> UIColor? {
        return self.adjust(by: -1 * abs(percentage) )
    }
    
    public func adjust(by percentage: CGFloat = 50.0) -> UIColor? {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        if self.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
            return UIColor(red: min(red + percentage/100, 1.0),
                           green: min(green + percentage/100, 1.0),
                           blue: min(blue + percentage/100, 1.0),
                           alpha: alpha)
        } else {
            return nil
        }
    }
    
    /** Return contrast UIColor */
    public func contrast() -> UIColor? {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        if self.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
            return UIColor(red: 1 - red, green: 1 - green, blue: 1 - blue, alpha: alpha)
        }
        else {
            return nil
        }
    }
}

//  MARK: - Numeric Collection
extension Collection where Element: Numeric {
    /** Get the sum of an array */
    public func sum() -> Element { return reduce(0, +) }
    
    /** Change an integer array to a double array */
    public func intToDouble() -> [Double] {
        var array = [Double]()
        for i in self{
            array.append(Double((i as? Int)!))
        }
        return array
    }
    
    /** Change an integer array to percent array */
    public func percent() -> [Int]{
        var array = [Int]()
        for i in self{
            array.append(lround((Double((i as! Int)*100) / Double(self.sum() as! Int))))
        }
        return array
    }
}

//  MARK: - NSLayoutConstraint Collection
extension Collection where Element: NSLayoutConstraint{
    /** Get the specific constraint by providing it's identifier */
    public func constraint(withIdentifier: String) -> NSLayoutConstraint {
        
        return self.filter { $0.identifier == withIdentifier }.first ?? NSLayoutConstraint.init()
    }
}

extension UIImageView{
    /** Move the UIImageView horizontally infinity */
    public func imageViewTranslationX(value: CGFloat){
        let animation = CABasicAnimation(keyPath: "transform.translation.x")
        animation.toValue = value
        animation.duration = 2
        animation.repeatCount = .infinity
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        layer.add(animation, forKey: nil)
    }
    /** Play the gif provided */
    public func loadGif(name: String) {
        DispatchQueue.global().async {
            let image = UIImage.gif(name: name)
            DispatchQueue.main.async {
                self.image = image
            }
        }
    }
    
    @available(iOS 9.0, *)
    public func loadGif(asset: String) {
        DispatchQueue.global().async {
            let image = UIImage.gif(asset: asset)
            DispatchQueue.main.async {
                self.image = image
            }
        }
    }
}

//  MARK: - UIImage
extension UIImage {
    
    public class func gif(data: Data) -> UIImage? {
        // Create source from data
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            print("SwiftGif: Source for the image does not exist")
            return nil
        }
        
        return UIImage.animatedImageWithSource(source)
    }
    
    public class func gif(url: String) -> UIImage? {
        // Validate URL
        guard let bundleURL = URL(string: url) else {
            print("SwiftGif: This image named \"\(url)\" does not exist")
            return nil
        }
        
        // Validate data
        guard let imageData = try? Data(contentsOf: bundleURL) else {
            print("SwiftGif: Cannot turn image named \"\(url)\" into NSData")
            return nil
        }
        
        return gif(data: imageData)
    }
    
    public class func gif(name: String) -> UIImage? {
        // Check for existance of gif
        guard let bundleURL = Bundle.main
            .url(forResource: name, withExtension: "gif") else {
                print("SwiftGif: This image named \"\(name)\" does not exist")
                return nil
        }
        
        // Validate data
        guard let imageData = try? Data(contentsOf: bundleURL) else {
            print("SwiftGif: Cannot turn image named \"\(name)\" into NSData")
            return nil
        }
        
        return gif(data: imageData)
    }
    
    @available(iOS 9.0, *)
    public class func gif(asset: String) -> UIImage? {
        // Create source from assets catalog
        guard let dataAsset = NSDataAsset(name: asset) else {
            print("SwiftGif: Cannot turn image named \"\(asset)\" into NSDataAsset")
            return nil
        }
        
        return gif(data: dataAsset.data)
    }
    
    internal class func delayForImageAtIndex(_ index: Int, source: CGImageSource!) -> Double {
        var delay = 0.1
        
        // Get dictionaries
        let cfProperties = CGImageSourceCopyPropertiesAtIndex(source, index, nil)
        let gifPropertiesPointer = UnsafeMutablePointer<UnsafeRawPointer?>.allocate(capacity: 0)
        if CFDictionaryGetValueIfPresent(cfProperties, Unmanaged.passUnretained(kCGImagePropertyGIFDictionary).toOpaque(), gifPropertiesPointer) == false {
            return delay
        }
        
        let gifProperties:CFDictionary = unsafeBitCast(gifPropertiesPointer.pointee, to: CFDictionary.self)
        
        // Get delay time
        var delayObject: AnyObject = unsafeBitCast(
            CFDictionaryGetValue(gifProperties,
                                 Unmanaged.passUnretained(kCGImagePropertyGIFUnclampedDelayTime).toOpaque()),
            to: AnyObject.self)
        if delayObject.doubleValue == 0 {
            delayObject = unsafeBitCast(CFDictionaryGetValue(gifProperties,
                                                             Unmanaged.passUnretained(kCGImagePropertyGIFDelayTime).toOpaque()), to: AnyObject.self)
        }
        
        delay = delayObject as? Double ?? 0
        
        if delay < 0.1 {
            delay = 0.1 // Make sure they're not too fast
        }
        
        return delay
    }
    
    internal class func gcdForPair(_ a: Int?, _ b: Int?) -> Int {
        var a = a
        var b = b
        // Check if one of them is nil
        if b == nil || a == nil {
            if b != nil {
                return b!
            } else if a != nil {
                return a!
            } else {
                return 0
            }
        }
        
        // Swap for modulo
        if a! < b! {
            let c = a
            a = b
            b = c
        }
        
        // Get greatest common divisor
        var rest: Int
        while true {
            rest = a! % b!
            
            if rest == 0 {
                return b! // Found it
            } else {
                a = b
                b = rest
            }
        }
    }
    
    internal class func gcdForArray(_ array: Array<Int>) -> Int {
        if array.isEmpty {
            return 1
        }
        
        var gcd = array[0]
        
        for val in array {
            gcd = UIImage.gcdForPair(val, gcd)
        }
        
        return gcd
    }
    
    internal class func animatedImageWithSource(_ source: CGImageSource) -> UIImage? {
        let count = CGImageSourceGetCount(source)
        var images = [CGImage]()
        var delays = [Int]()
        
        // Fill arrays
        for i in 0..<count {
            // Add image
            if let image = CGImageSourceCreateImageAtIndex(source, i, nil) {
                images.append(image)
            }
            
            // At it's delay in cs
            let delaySeconds = UIImage.delayForImageAtIndex(Int(i),
                                                            source: source)
            delays.append(Int(delaySeconds * 1000.0)) // Seconds to ms
        }
        
        // Calculate full duration
        let duration: Int = {
            var sum = 0
            
            for val: Int in delays {
                sum += val
            }
            
            return sum
        }()
        
        // Get frames
        let gcd = gcdForArray(delays)
        var frames = [UIImage]()
        
        var frame: UIImage
        var frameCount: Int
        for i in 0..<count {
            frame = UIImage(cgImage: images[Int(i)])
            frameCount = Int(delays[Int(i)] / gcd)
            
            for _ in 0..<frameCount {
                frames.append(frame)
            }
        }
        
        let animation = UIImage.animatedImage(with: frames,
                                              duration: Double(duration) / 1000.0)
        
        return animation
    }
    
    func isEqualToImage(image: UIImage) -> Bool {
        let data1: NSData = self.pngData()! as NSData
        let data2: NSData = image.pngData()! as NSData
        return data1.isEqual(data2)
    }
    
}

fileprivate var customActivityIndicatorBaseView = UIView()

//  MARK: - UIViewController
extension UIViewController{
    /** Custom UIAlertController */
    public func customAlert(title: String, message: String, titleFont: String, titleFontSize: CGFloat = 18, titleColor: UIColor, messageFont: String, messageFontSize: CGFloat = 14, messageColor: UIColor, actionButtonText: String) {
        let controller = UIAlertController(title: title, message: message, preferredStyle: .alert)
        func customAlertMessage(setValueKey: String, message: String, controller: UIAlertController, fontType: String,color: UIColor, fontSize: CGFloat){
            let presentString = message
            var messageMutableString = NSMutableAttributedString()
            messageMutableString = NSMutableAttributedString(string: presentString, attributes: [NSAttributedString.Key.font: UIFont(name: fontType, size: fontSize)!])
            messageMutableString.addAttribute(NSAttributedString.Key.foregroundColor, value: color, range: NSRange(location: 0,length: presentString.count))
            controller.setValue(messageMutableString, forKey: setValueKey)
        }
        customAlertMessage(setValueKey: "attributedTitle", message: title, controller: controller, fontType: titleFont, color: titleColor, fontSize: titleFontSize)
        customAlertMessage(setValueKey: "attributedMessage", message: message, controller: controller, fontType: messageFont, color: messageColor, fontSize: messageFontSize)
        let action = UIAlertAction(title: actionButtonText, style: .cancel, handler: nil)
        controller.addAction(action)
        
        self.present(controller, animated: true, completion: nil)
    }
    
    public func popMessage(text: String){
        let messageLabel = UILabel()
        messageLabel.frame = CGRect(origin: view.frame.origin, size: CGSize(width: view.frame.width * 0.8, height: 80))
        messageLabel.layer.cornerRadius = 8
        messageLabel.layer.masksToBounds = true
        messageLabel.center = view.center
        messageLabel.backgroundColor = UIColor(hexString: "#F0F0F0")
        messageLabel.text = text
        messageLabel.textAlignment = .center
        messageLabel.font = UIFont(name: messageLabel.font.fontName, size: 50)
        messageLabel.adjustsFontSizeToFitWidth = true
        messageLabel.minimumScaleFactor = 10
        messageLabel.textColor = UIColor(hexString: "#2C3E50")
        messageLabel.alpha = 0
        messageLabel.font = UIFont(name: messageLabel.font.fontName, size: messageLabel.font.pointSize * 0.9)
        let window = UIApplication.shared.keyWindow!
        window.addSubview(messageLabel)
        UIView.animate(withDuration: 0.2, animations: {
            messageLabel.alpha = 1
        }) { (success) in
            UIView.animate(withDuration: 1, animations: {
                messageLabel.alpha = 0
            }, completion: { (successPartTwo) in
                messageLabel.removeFromSuperview()
            })
        }
    }
    
    public var isDarkModeEnabled : Bool {
        get {
            if #available(iOS 12.0, *) {
                return traitCollection.userInterfaceStyle == .dark
            } else {
                return false
            }
        }
    }
    

    @available(iOS 10.0, *)
    public func customActivityIndicator(withView: UIView, withViewBaseSize: CGSize = .zero, textBelowYourView: String = "", textColor: UIColor = .white, font: UIFont = UIFont.systemFont(ofSize: 13), textLocation: CGFloat = 50, backgroundColor: UIColor = .gray) {
        customActivityIndicatorBaseView = UIView()
        customActivityIndicatorBaseView.frame = view.frame
        customActivityIndicatorBaseView.backgroundColor = backgroundColor.withAlphaComponent(0.5)
        let withViewBaseGrayView = UIView()
        customActivityIndicatorBaseView.addSubview(withViewBaseGrayView)
        withViewBaseGrayView.frame.size = withViewBaseSize
        withViewBaseGrayView.center = customActivityIndicatorBaseView.center
        withViewBaseGrayView.clipsToBounds = true
        withViewBaseGrayView.layer.cornerRadius = 8
        withViewBaseGrayView.backgroundColor = UIColor.darkGray.withAlphaComponent(0.5)
        
        customActivityIndicatorBaseView.addSubview(withView)
        withView.center = customActivityIndicatorBaseView.center
        if textBelowYourView != "" {
            let label = UILabel()
            label.textColor = textColor
            label.text = textBelowYourView
            label.font = font
            label.numberOfLines = 0
            label.textAlignment = .center
            Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { (timer) in
                if label.text == textBelowYourView {
                    label.text = textBelowYourView + " ."
                }
                else if label.text == textBelowYourView + " ." {
                    label.text = textBelowYourView + " .."
                }
                else if label.text == textBelowYourView + " .." {
                    label.text = textBelowYourView + " ..."
                }
                else {
                    label.text = textBelowYourView
                }
            }
            customActivityIndicatorBaseView.addSubview(label)
            label.frame = customActivityIndicatorBaseView.frame
            label.frame = CGRect(x: label.frame.minX, y: label.frame.minY + textLocation, width: label.frame.width, height: label.frame.height)
        }
        view.addSubview(customActivityIndicatorBaseView)
        print("LKNExtension: customActivityIndicator: addsubview")
    }
    
    public func removeCustomActivityIndicator() {
        guard self.view.subviews.contains(customActivityIndicatorBaseView) else {
            print("LKNExtension: removeCustomActivityIndicator: CustomActivityIndicator don't exist")
            return
        }
        customActivityIndicatorBaseView.removeFromSuperview()
    }
}

//  MARK: - UIAlertController
extension UIAlertController{
    public convenience init(title: String, message: String, preferredStyle: UIAlertController.Style, titleFont: String, titleFontSize: CGFloat = 18, titleColor: UIColor, messageFont: String, messageFontSize: CGFloat = 15, messageColor: UIColor){
        self.init(title: title, message: message, preferredStyle: preferredStyle)
        func customAlertMessage(setValueKey: String, message: String, controller: UIAlertController, fontType: String,color: UIColor, fontSize: CGFloat){
            let presentString = message
            var messageMutableString = NSMutableAttributedString()
            messageMutableString = NSMutableAttributedString(string: presentString, attributes: [NSAttributedString.Key.font: UIFont(name: fontType, size: fontSize)!])
            messageMutableString.addAttribute(NSAttributedString.Key.foregroundColor, value: color, range: NSRange(location: 0,length: presentString.count))
            controller.setValue(messageMutableString, forKey: setValueKey)
        }
 
        customAlertMessage(setValueKey: "attributedTitle", message: title, controller: self, fontType: titleFont, color: titleColor, fontSize: titleFontSize)
        customAlertMessage(setValueKey: "attributedMessage", message: message, controller: self, fontType: messageFont, color: messageColor, fontSize: messageFontSize)
    }
}

extension UIAlertAction {
    public var titleTextColor: UIColor? {
        get {
            return self.value(forKey: "titleTextColor") as? UIColor
        } set {
            self.setValue(newValue, forKey: "titleTextColor")
        }
    }
}

public enum animationType{
    case shrink
    case enlarge
    case segmentDown
    case segmentUp
}

//  MARK: - UIButton
extension UIButton{
    /** UIButton's animation */
    public func buttonAnimation(animationType: animationType, duration: CGFloat = 0.05, infinity: Bool = false){
        switch animationType{
        case .shrink:
            let animation = CABasicAnimation(keyPath: "transform.scale")
            animation.fromValue = 1
            animation.autoreverses = true
            animation.toValue = 0.8
            animation.duration = CFTimeInterval(duration)
            if infinity{
                animation.repeatCount = .infinity
            }
            animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
            layer.add(animation, forKey: nil)
        case .enlarge:
            let animation = CABasicAnimation(keyPath: "transform.scale")
            animation.fromValue = 1
            animation.autoreverses = true
            animation.toValue = 1.5
            animation.duration = CFTimeInterval(duration)
            if infinity{
                animation.repeatCount = .infinity
            }
            animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
            layer.add(animation, forKey: nil)
        case .segmentDown:
            let animation = CAKeyframeAnimation(keyPath: "transform.scale")
            animation.values = [1,0.5,0.8]
            animation.duration = 0.3
            if infinity{
                animation.repeatCount = .infinity
            }
            animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
            animation.fillMode = CAMediaTimingFillMode.forwards
            animation.isRemovedOnCompletion = false
            layer.add(animation, forKey: nil)
        case .segmentUp:
            let animation = CAKeyframeAnimation(keyPath: "transform.scale")
            animation.values = [0.8,0.5,1]
            animation.duration = 0.3
            if infinity{
                animation.repeatCount = .infinity
            }
            animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
            animation.fillMode = CAMediaTimingFillMode.forwards
            animation.isRemovedOnCompletion = false
            layer.add(animation, forKey: nil)
        }
    }
    /** UIButton's rotation */
    public func buttonRotate(semicircleAsUnit: CGFloat, duration: Double){
        let animation = CABasicAnimation(keyPath: "transform.rotation.z")
        animation.fromValue = 0
        animation.toValue = CGFloat.pi * semicircleAsUnit
        animation.duration = duration
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
        layer.add(animation, forKey: nil)
    }
}

//  MARK: - UIView
extension UIView{
    public func viewAnimation(animationType: animationType){
        switch animationType{
        case .shrink:
            let animation = CABasicAnimation(keyPath: "transform.scale")
            animation.fromValue = 1
            animation.autoreverses = true
            animation.toValue = 0.8
            animation.duration = 0.05
            animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
            layer.add(animation, forKey: nil)
        case .enlarge:
            let animation = CABasicAnimation(keyPath: "transform.scale")
            animation.fromValue = 1
            animation.autoreverses = true
            animation.toValue = 1.5
            animation.duration = 0.05
            animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
            layer.add(animation, forKey: nil)
        case .segmentDown:
            let animation = CAKeyframeAnimation(keyPath: "transform.scale")
            animation.values = [1,0.5,0.8]
            animation.duration = 0.3
            animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
            animation.fillMode = CAMediaTimingFillMode.forwards
            animation.isRemovedOnCompletion = false
            layer.add(animation, forKey: nil)
        case .segmentUp:
            let animation = CAKeyframeAnimation(keyPath: "transform.scale")
            animation.values = [0.8,0.5,1]
            animation.duration = 0.3
            animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
            animation.fillMode = CAMediaTimingFillMode.forwards
            animation.isRemovedOnCompletion = false
            layer.add(animation, forKey: nil)
        }
    }
    public func viewShrink(){
        let animation = CABasicAnimation(keyPath: "transform.scale")
        animation.fromValue = 1
        animation.autoreverses = true
        animation.toValue = 0.8
        animation.duration = 0.1
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        layer.add(animation, forKey: nil)
    }
    public func decrease(){
        let animation = CABasicAnimation(keyPath: "transform.scale")
        animation.fromValue = 1
        animation.toValue = 0.95
        animation.duration = 0.5
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        layer.add(animation, forKey: nil)
    }
    public func viewRotate(semicircleAsUnit: CGFloat, duration: Double){
        let animation = CABasicAnimation(keyPath: "transform.rotation.z")
        animation.fromValue = 0
        animation.toValue = CGFloat.pi * semicircleAsUnit // semicircleAsUnit = 2 A circle
        animation.duration = duration
        //animation.repeatCount = .infinity
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
        layer.add(animation, forKey: nil)
    }
    public func viewTranslationX(value: CGFloat,duration: Double){
        let animation = CABasicAnimation(keyPath: "transform.translation.x")
        animation.toValue = value
        animation.duration = duration
        animation.autoreverses = true
        animation.repeatCount = .infinity
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
        layer.add(animation, forKey: nil)
    }
    /** Perform a horizontal shift and a squezze effect */
    public func viewSqueezeX(xValue: CGFloat,duration: Double){
        let animation = CABasicAnimation(keyPath: "transform.translation.x")
        animation.toValue = xValue
        animation.duration = duration
        animation.autoreverses = true
        animation.repeatCount = .infinity
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
        layer.add(animation, forKey: nil)
        let animation1 = CABasicAnimation(keyPath: "transform.scale.x")
        animation1.fromValue = 1
        animation1.toValue = 0.8
        animation1.duration = duration
        animation1.autoreverses = true
        animation1.repeatCount = .infinity
        animation1.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeIn)
        layer.add(animation1, forKey: nil)
        let animation2 = CABasicAnimation(keyPath: "transform.scale.y")
        animation2.fromValue = 1
        animation2.toValue = 1.5
        animation2.duration = duration
        animation2.autoreverses = true
        animation2.repeatCount = .infinity
        animation2.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeIn)
        layer.add(animation2, forKey: nil)
    }
    /** Perform a vertical shift and asqueeze effect */
    public func viewSqueezeY(yValue: CGFloat,duration: Double){
        let animation = CABasicAnimation(keyPath: "transform.translation.y")
        animation.toValue = yValue
        animation.duration = duration
        animation.autoreverses = true
        animation.repeatCount = .infinity
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
        layer.add(animation, forKey: nil)
        let animation1 = CABasicAnimation(keyPath: "transform.scale.x")
        animation1.fromValue = 1
        animation1.toValue = 1.1
        animation1.duration = duration
        animation1.autoreverses = true
        animation1.repeatCount = .infinity
        animation1.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeIn)
        layer.add(animation1, forKey: nil)
        let animation2 = CABasicAnimation(keyPath: "transform.scale.y")
        animation2.fromValue = 1
        animation2.toValue = 0.8
        animation2.duration = duration
        animation2.autoreverses = true
        animation2.repeatCount = .infinity
        animation2.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeIn)
        layer.add(animation2, forKey: nil)
    }
    @available(iOS 10.0, *)
    /** Set a blur background */
    public func setBlurBackground(style: UIBlurEffect.Style) {
        let blurEffect = UIBlurEffect(style: style)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blurEffectView.clipsToBounds = true
        blurEffectView.frame = self.frame
        self.superview?.insertSubview(blurEffectView, belowSubview: self)
    }
    /** Add shadow to UIView when corner radius is set */
    public func addRoundShadowView(withShadowColor: UIColor = .black, offSet: CGSize, opacity: Float, radius: CGFloat = 3) {
        let shadowLayer = CAShapeLayer()
        shadowLayer.path = UIBezierPath(roundedRect: bounds, cornerRadius: layer.cornerRadius).cgPath
        shadowLayer.fillColor = backgroundColor?.cgColor
        shadowLayer.shadowColor = withShadowColor.cgColor
        shadowLayer.shadowPath = shadowLayer.path
        shadowLayer.shadowOffset = offSet
        shadowLayer.shadowOpacity = opacity
        shadowLayer.shadowRadius = radius
        layer.insertSublayer(shadowLayer, at: 0)
    }
}

//  MARK: - Bundle
extension Bundle{
    /** Return app's current icon */
    public var icon: UIImage? {
        if let icons = infoDictionary?["CFBundleIcons"] as? [String: Any],
            let primaryIcon = icons["CFBundlePrimaryIcon"] as? [String: Any],
            let iconFiles = primaryIcon["CFBundleIconFiles"] as? [String],
            let lastIcon = iconFiles.last {
            return UIImage(named: lastIcon)
        }
        return nil
    }
}

//  MARK: - String
extension String{
    /** Drop the number of character off the string */
    public func dropChracter(numberDrop: Int) -> String{
        if numberDrop < 0{
            let b = self.index(self.endIndex, offsetBy: numberDrop)
            return String(self[..<b])
        }
        else{
            let b = self.index(self.startIndex, offsetBy: numberDrop)
            return String(self[b...])
        }
    }
}

extension UIDevice {
    public static let modelName: String = {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        func mapToDevice(identifier: String) -> String {
            #if os(iOS)
            switch identifier {
            case "iPod5,1":                                 return "iPod touch (5th generation)"
            case "iPod7,1":                                 return "iPod touch (6th generation)"
            case "iPod9,1":                                 return "iPod touch (7th generation)"
            case "iPhone3,1", "iPhone3,2", "iPhone3,3":     return "iPhone 4"
            case "iPhone4,1":                               return "iPhone 4s"
            case "iPhone5,1", "iPhone5,2":                  return "iPhone 5"
            case "iPhone5,3", "iPhone5,4":                  return "iPhone 5c"
            case "iPhone6,1", "iPhone6,2":                  return "iPhone 5s"
            case "iPhone7,2":                               return "iPhone 6"
            case "iPhone7,1":                               return "iPhone 6 Plus"
            case "iPhone8,1":                               return "iPhone 6s"
            case "iPhone8,2":                               return "iPhone 6s Plus"
            case "iPhone8,4":                               return "iPhone SE"
            case "iPhone9,1", "iPhone9,3":                  return "iPhone 7"
            case "iPhone9,2", "iPhone9,4":                  return "iPhone 7 Plus"
            case "iPhone10,1", "iPhone10,4":                return "iPhone 8"
            case "iPhone10,2", "iPhone10,5":                return "iPhone 8 Plus"
            case "iPhone10,3", "iPhone10,6":                return "iPhone X"
            case "iPhone11,2":                              return "iPhone XS"
            case "iPhone11,4", "iPhone11,6":                return "iPhone XS Max"
            case "iPhone11,8":                              return "iPhone XR"
            case "iPhone12,1":                              return "iPhone 11"
            case "iPhone12,3":                              return "iPhone 11 Pro"
            case "iPhone12,5":                              return "iPhone 11 Pro Max"
            case "iPhone12,8":                              return "iPhone SE (2nd generation)"
            case "iPad2,1", "iPad2,2", "iPad2,3", "iPad2,4":return "iPad 2"
            case "iPad3,1", "iPad3,2", "iPad3,3":           return "iPad (3rd generation)"
            case "iPad3,4", "iPad3,5", "iPad3,6":           return "iPad (4th generation)"
            case "iPad6,11", "iPad6,12":                    return "iPad (5th generation)"
            case "iPad7,5", "iPad7,6":                      return "iPad (6th generation)"
            case "iPad7,11", "iPad7,12":                    return "iPad (7th generation)"
            case "iPad4,1", "iPad4,2", "iPad4,3":           return "iPad Air"
            case "iPad5,3", "iPad5,4":                      return "iPad Air 2"
            case "iPad11,4", "iPad11,5":                    return "iPad Air (3rd generation)"
            case "iPad2,5", "iPad2,6", "iPad2,7":           return "iPad mini"
            case "iPad4,4", "iPad4,5", "iPad4,6":           return "iPad mini 2"
            case "iPad4,7", "iPad4,8", "iPad4,9":           return "iPad mini 3"
            case "iPad5,1", "iPad5,2":                      return "iPad mini 4"
            case "iPad11,1", "iPad11,2":                    return "iPad mini (5th generation)"
            case "iPad6,3", "iPad6,4":                      return "iPad Pro (9.7-inch)"
            case "iPad7,3", "iPad7,4":                      return "iPad Pro (10.5-inch)"
            case "iPad8,1", "iPad8,2", "iPad8,3", "iPad8,4":return "iPad Pro (11-inch) (1st generation)"
            case "iPad8,9", "iPad8,10":                     return "iPad Pro (11-inch) (2nd generation)"
            case "iPad6,7", "iPad6,8":                      return "iPad Pro (12.9-inch) (1st generation)"
            case "iPad7,1", "iPad7,2":                      return "iPad Pro (12.9-inch) (2nd generation)"
            case "iPad8,5", "iPad8,6", "iPad8,7", "iPad8,8":return "iPad Pro (12.9-inch) (3rd generation)"
            case "iPad8,11", "iPad8,12":                    return "iPad Pro (12.9-inch) (4th generation)"
            case "AppleTV5,3":                              return "Apple TV"
            case "AppleTV6,2":                              return "Apple TV 4K"
            case "AudioAccessory1,1":                       return "HomePod"
            case "i386", "x86_64":                          return "Simulator \(mapToDevice(identifier: ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] ?? "iOS"))"
            default:                                        return identifier
            }
            #elseif os(tvOS)
            switch identifier {
            case "AppleTV5,3": return "Apple TV 4"
            case "AppleTV6,2": return "Apple TV 4K"
            case "i386", "x86_64": return "Simulator \(mapToDevice(identifier: ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] ?? "tvOS"))"
            default: return identifier
            }
            #endif
        }
        return mapToDevice(identifier: identifier)
    }()
}

public protocol Declarative: AnyObject {
    init()
}

public extension Declarative {
    init(configureHandler: (Self) -> Void) {
        self.init()
        configureHandler(self)
    }
}

extension NSObject: Declarative { }

public func debugFunctionPrint(functionName: String, errorStatement: String) {
    print("Error function: \(functionName):  \(errorStatement)")
}
