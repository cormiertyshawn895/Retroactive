//
//  ConfettiView.swift
//  ConfettiView
//
//  Created by Chris Zielinski on 10/19/17.
//  Copyright © 2017 Big Z Labs. All rights reserved.
//

#if canImport(AppKit)
import AppKit
#else
import UIKit
#endif

open class ConfettiView: ConfettiView.View {

    #if canImport(AppKit)
    public typealias View = NSView
    public typealias Color = NSColor
    public typealias Image = NSImage

    let frameworkConstant: CGFloat = 1
    var yOrigin: CGFloat {
        return frame.size.height + heightOffset
    }
    #else
    public typealias View = UIView
    public typealias Color = UIColor
    public typealias Image = UIImage

    let frameworkConstant: CGFloat = -1
    var yOrigin: CGFloat {
        return -heightOffset
    }
    #endif
    
    public enum ConfettiType {
        case confetti
        case triangle
        case star
        case diamond
        case image(Image)
    }

    open var confettiType: ConfettiType = .confetti
    open var isActive: Bool = false
    /// The delay in seconds before the emitter sublayer is removed from the view's layer after stopping.
    open var removalDelay: Int = 6
    @IBInspectable open var intensity: Float = 0.5
    open var colors: [Color] = [#colorLiteral(red:0.95, green:0.40, blue:0.27, alpha:1.0), #colorLiteral(red:1.00, green:0.78, blue:0.36, alpha:1.0), #colorLiteral(red:0.48, green:0.78, blue:0.64, alpha:1.0), #colorLiteral(red:0.30, green:0.76, blue:0.85, alpha:1.0), #colorLiteral(red:0.58, green:0.39, blue:0.55, alpha:1.0)]
    @IBInspectable open var image: Image? {
        didSet {
            if let image = image {
                confettiType = .image(image)
            }
        }
    }

    let heightOffset: CGFloat = 10.0
    var emitterQueue: [CAEmitterLayer] = []
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    /// Convenience initializer that adds and pins (using Auto Layout) the `ConfettiView` to the provided superview.
    ///
    /// - Parameter superview: The superview that the `ConfettiView` should be added to.
    public convenience init(in superview: View) {
        self.init(frame: superview.frame)

        superview.addSubview(self)
        
        self.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            NSLayoutConstraint(item: self, attribute: .leading, relatedBy: .equal, toItem: superview, attribute: .leading, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self, attribute: .top, relatedBy: .equal, toItem: superview, attribute: .top, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self, attribute: .trailing, relatedBy: .equal, toItem: superview, attribute: .trailing, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self, attribute: .bottom, relatedBy: .equal, toItem: superview, attribute: .bottom, multiplier: 1, constant: 0),
        ])
    }

    #if canImport(AppKit)
    @objc public func frameDidChange(notification: Notification) {
        setSizeAndPosition()
    }
    #else
    override open func layoutSubviews() {
        super.layoutSubviews()
        setSizeAndPosition()
    }
    #endif

    private func setSizeAndPosition() {
        emitterQueue.forEach({ setSizeAndPosition(for: $0) })
    }
    
    private func setSizeAndPosition(for emitter: CAEmitterLayer) {
        emitter.emitterPosition = CGPoint(x: frame.size.width / 2.0,
                                          y: yOrigin)
        emitter.emitterSize = CGSize(width: frame.size.width, height: 1)
    }
    
    func setup() {
        #if canImport(AppKit)
        wantsLayer = true
        postsFrameChangedNotifications = true

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(frameDidChange(notification:)),
                                               name: View.frameDidChangeNotification,
                                               object: nil)
        #endif
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    open func startConfetti() {
        isActive = true

        let emitter = CAEmitterLayer()
        emitter.emitterShape = CAEmitterLayerEmitterShape.line
        setSizeAndPosition(for: emitter)
        emitter.emitterCells = confettiCells(for: colors)
        emitterQueue.append(emitter)
        caLayer.addSublayer(emitter)
    }
    
    open func stopConfetti() {
        guard !emitterQueue.isEmpty else {
            isActive = false
            return
        }

        let firstEmitter = emitterQueue.removeFirst()
        firstEmitter.birthRate = 0

        if emitterQueue.isEmpty {
            isActive = false
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(removalDelay)) {
            firstEmitter.removeFromSuperlayer()
        }
    }
    
    func imageForType(_ type: ConfettiType) -> Image? {
        var fileName: String!
        
        switch type {
        case .confetti:
            fileName = "confetti"
        case .triangle:
            fileName = "triangle"
        case .star:
            fileName = "star"
        case .diamond:
            fileName = "diamond"
        case let .image(image):
            return image
        }
        
        let path = Bundle(for: ConfettiView.self).path(forResource: "ConfettiView", ofType: "bundle")
        let bundle = Bundle(path: path!)
        let imagePath = bundle?.path(forResource: fileName, ofType: "png")
        let url = URL(fileURLWithPath: imagePath!)
        let data = try? Data(contentsOf: url)
        if let data = data, let image = Image(data: data) {
            return image
        }
        return nil
    }
    
    func confettiCells(for colors: [Color]) -> [CAEmitterCell] {
        guard let cellImage = imageForType(confettiType)?.cgImage else {
            print("Could get image.")
            return []
        }

        return colors.map { (color: Color) -> CAEmitterCell in
            let confetti = CAEmitterCell()
            confetti.name = "confetti"
            confetti.birthRate = 16.0 * intensity
            confetti.lifetime = 14.0 * intensity
            confetti.color = color.cgColor
            confetti.velocity = CGFloat(350.0 * intensity) * frameworkConstant
            confetti.velocityRange = CGFloat(80.0 * intensity)
            confetti.emissionRange = .pi / 4
            confetti.spin = CGFloat(3.5 * intensity)
            confetti.spinRange = CGFloat(4.0 * intensity)
            confetti.scaleRange = CGFloat(intensity)
            confetti.scaleSpeed = CGFloat(-0.1 * intensity)
            confetti.beginTime = CACurrentMediaTime()
            confetti.contents = cellImage
            return confetti
        }
    }
}

#if canImport(AppKit)
extension ConfettiView.Image {
    var cgImage: CGImage? {
        return self.cgImage(forProposedRect: nil, context: nil, hints: nil)
    }
}
#endif

extension ConfettiView.View {
    var caLayer: CALayer {
        #if canImport(AppKit)
            if !wantsLayer {
                wantsLayer = true
            }
            return self.layer!
        #else
            return self.layer
        #endif
    }
}
