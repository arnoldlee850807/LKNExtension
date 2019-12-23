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
    public func customAlert(title: String, message: String, preferredStyle: UIAlertController.Style, titleFont: String, titleFontSize: CGFloat = 18, titleColor: UIColor, messageFont: String, messageFontSize: CGFloat = 14, messageColor: UIColor) -> UIAlertController{
        let controller = UIAlertController(title: title, message: message, preferredStyle: preferredStyle)
        func customAlertMessage(setValueKey: String, message: String, controller: UIAlertController, fontType: String,color: UIColor, fontSize: CGFloat){
            let presentString = message
            var messageMutableString = NSMutableAttributedString()
            messageMutableString = NSMutableAttributedString(string: presentString, attributes: [NSAttributedString.Key.font: UIFont(name: fontType, size: fontSize)!])
            messageMutableString.addAttribute(NSAttributedString.Key.foregroundColor, value: color, range: NSRange(location: 0,length: presentString.count))
            controller.setValue(messageMutableString, forKey: setValueKey)
        }
        customAlertMessage(setValueKey: "attributedTitle", message: title, controller: controller, fontType: titleFont, color: titleColor, fontSize: titleFontSize)
        customAlertMessage(setValueKey: "attributedMessage", message: message, controller: controller, fontType: messageFont, color: messageColor, fontSize: messageFontSize)
        return controller
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
        
        customActivityIndicatorBaseView.frame = view.frame
        customActivityIndicatorBaseView.backgroundColor = backgroundColor.withAlphaComponent(0.5)
        let withViewBaseGrayView = UIView()
        customActivityIndicatorBaseView.addSubview(withViewBaseGrayView)
        withViewBaseGrayView.center = customActivityIndicatorBaseView.center
        withViewBaseGrayView.frame.size = withViewBaseSize
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
