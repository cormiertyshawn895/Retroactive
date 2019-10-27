import Cocoa

/**
Convenience function for initializing an object and modifying its properties.

```
let label = with(NSTextField()) {
	$0.stringValue = "Foo"
	$0.textColor = .systemBlue
	view.addSubview($0)
}
```
*/
@discardableResult
func with<T>(_ item: T, update: (inout T) throws -> Void) rethrows -> T {
	var this = item
	try update(&this)
	return this
}

extension NSColor {
	/// macOS 10.14 polyfill
	static let controlAccentColorPolyfill: NSColor = {
		if #available(macOS 10.14, *) {
			return NSColor.controlAccentColor
		} else {
			// swiftlint:disable:next object_literal
			return NSColor(red: 0.10, green: 0.47, blue: 0.98, alpha: 1)
		}
	}()

	func withAlpha(_ alpha: Double) -> NSColor {
		withAlphaComponent(CGFloat(alpha))
	}

	typealias HSBAColor = (hue: Double, saturation: Double, brightness: Double, alpha: Double)
	var hsba: HSBAColor {
		var hue: CGFloat = 0
		var saturation: CGFloat = 0
		var brightness: CGFloat = 0
		var alpha: CGFloat = 0
		let color = usingColorSpace(.deviceRGB) ?? self
		color.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
		return HSBAColor(Double(hue), Double(saturation), Double(brightness), Double(alpha))
	}

	/// Adjust color components by ratio.
	func adjusting(
		hue: Double = 0,
		saturation: Double = 0,
		brightness: Double = 0,
		alpha: Double = 0
	) -> NSColor {
		let color = hsba
		return NSColor(
			hue: CGFloat(color.hue * (hue + 1)),
			saturation: CGFloat(color.saturation * (saturation + 1)),
			brightness: CGFloat(color.brightness * (brightness + 1)),
			alpha: CGFloat(color.alpha * (alpha + 1))
		)
	}
}


extension Comparable {
	/**
	```
	20.5.clamped(to: 10.3...15)
	//=> 15
	```
	*/
	func clamped(to range: ClosedRange<Self>) -> Self {
		min(max(self, range.lowerBound), range.upperBound)
	}
}


extension CGRect {
	var center: CGPoint {
		get { CGPoint(x: midX, y: midY) }
		set {
			origin = CGPoint(
				x: newValue.x - (size.width / 2),
				y: newValue.y - (size.height / 2)
			)
		}
	}
}


extension DispatchQueue {
	/**
	```
	DispatchQueue.main.asyncAfter(duration: 100.milliseconds) {
		print("100 ms later")
	}
	```
	*/
	func asyncAfter(duration: TimeInterval, execute: @escaping () -> Void) {
		asyncAfter(deadline: .now() + duration, execute: execute)
	}
}


extension CAMediaTimingFunction {
	static let `default` = CAMediaTimingFunction(name: .default)
	static let linear = CAMediaTimingFunction(name: .linear)
	static let easeIn = CAMediaTimingFunction(name: .easeIn)
	static let easeOut = CAMediaTimingFunction(name: .easeOut)
	static let easeInOut = CAMediaTimingFunction(name: .easeInEaseOut)
}


extension CALayer {
	static func animate(
		duration: TimeInterval = 1,
		delay: TimeInterval = 0,
		timingFunction: CAMediaTimingFunction = .default,
		animations: @escaping (() -> Void),
		completion: (() -> Void)? = nil
	) {
		DispatchQueue.main.asyncAfter(duration: delay) {
			CATransaction.begin()
			CATransaction.setAnimationDuration(duration)
			CATransaction.setAnimationTimingFunction(timingFunction)

			if let completion = completion {
				CATransaction.setCompletionBlock(completion)
			}

			animations()
			CATransaction.commit()
		}
	}
}


extension CALayer {
	/**
	Set CALayer properties without the implicit animation

	```
	CALayer.withoutImplicitAnimations {
		view.layer?.opacity = 0.4
	}
	```
	*/
	static func withoutImplicitAnimations(closure: () -> Void) {
		CATransaction.begin()
		CATransaction.setDisableActions(true)
		closure()
		CATransaction.commit()
	}

	/**
	Toggle the implicit CALayer animation
	Can be useful for text layers
	*/
	var implicitAnimations: Bool {
		get { actions == nil }
		set {
			if newValue {
				actions = nil
			} else {
				actions = ["contents": NSNull()]
			}
		}
	}
}


extension CALayer {
	/// This is required for CALayers that are created independently of a view
	func setAutomaticContentsScale() {
		contentsScale = NSScreen.main?.backingScaleFactor ?? 2
	}
}


extension NSFont {
	static let helveticaNeueLight = NSFont(name: "HelveticaNeue-Light", size: 0)
}


extension NSBezierPath {
	static func circle(
		radius: Double,
		center: CGPoint,
		startAngle: Double = 0,
		endAngle: Double = 360
	) -> Self {
		let path = self.init()
		path.appendArc(
			withCenter: center,
			radius: CGFloat(radius),
			startAngle: CGFloat(startAngle),
			endAngle: CGFloat(endAngle)
		)
		return path
	}

	/// For making a circle progress indicator
	static func progressCircle(radius: Double, center: CGPoint) -> Self {
		let startAngle: CGFloat = 90
		let path = self.init()
		path.appendArc(
			withCenter: center,
			radius: CGFloat(radius),
			startAngle: startAngle,
			endAngle: startAngle - 360,
			clockwise: true
		)
		return path
	}
}


extension CAShapeLayer {
	static func circle(radius: Double, center: CGPoint) -> Self {
		let layer = self.init()
		layer.path = NSBezierPath.circle(radius: radius, center: center).cgPath
		return layer
	}

	convenience init(path: NSBezierPath) {
		self.init()
		self.path = path.cgPath
	}
}


extension CATextLayer {
	/// Initializer with better defaults.
	convenience init(text: String, fontSize: Double? = nil, color: NSColor? = nil) {
		self.init()
		string = text
		if let fontSize = fontSize {
			self.fontSize = CGFloat(fontSize)
		}
		self.color = color
		implicitAnimations = false
		setAutomaticContentsScale()
	}

	var color: NSColor? {
		get {
			guard let color = foregroundColor else {
				return nil
			}
			return NSColor(cgColor: color)
		}
		set {
			foregroundColor = newValue?.cgColor
		}
	}
}


final class ProgressCircleShapeLayer: CAShapeLayer {
	convenience init(radius: Double, center: CGPoint) {
		self.init()
		fillColor = nil
		lineCap = .round
		path = NSBezierPath.progressCircle(radius: radius, center: center).cgPath
		strokeEnd = 0
	}

	var progress: Double {
		get { Double(strokeEnd) }
		set {
			strokeEnd = CGFloat(newValue)
		}
	}

	func resetProgress() {
		CALayer.withoutImplicitAnimations {
			strokeEnd = 0
		}
	}
}

/**
Shows the indeterminate state, when it's activated.

It draws part of a circle that gets animated into a looping motion around its core.
*/
final class IndeterminateProgressCircleShapeLayer: CAShapeLayer {
	convenience init(radius: Double, center: CGPoint) {
		self.init()
		fillColor = nil
		path = NSBezierPath.circle(radius: radius, center: bounds.center, startAngle: 270).cgPath
		anchorPoint = CGPoint(x: 0.5, y: 0.5)
		position = center
	}
}


extension NSBezierPath {
	/// UIKit polyfill.
	var cgPath: CGPath {
		let path = CGMutablePath()
		var points = [CGPoint](repeating: .zero, count: 3)

		for index in 0..<elementCount {
			let type = element(at: index, associatedPoints: &points)
			switch type {
			case .moveTo:
				path.move(to: points[0])
			case .lineTo:
				path.addLine(to: points[0])
			case .curveTo:
				path.addCurve(to: points[2], control1: points[0], control2: points[1])
			case .closePath:
				path.closeSubpath()
			@unknown default:
				assertionFailure("NSBezierPath received a new enum case. Please handle it.")
			}
		}

		return path
	}

	/// UIKit polyfill.
	convenience init(roundedRect rect: CGRect, cornerRadius: CGFloat) {
		self.init(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius)
	}
}

final class AssociatedObject<T: Any> {
	subscript(index: Any) -> T? {
		get {
			objc_getAssociatedObject(index, Unmanaged.passUnretained(self).toOpaque()) as! T?
		} set {
			objc_setAssociatedObject(index, Unmanaged.passUnretained(self).toOpaque(), newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
		}
	}
}

extension NSControl {
	typealias ActionClosure = ((NSControl) -> Void)

	private struct AssociatedKeys {
		static let onActionClosure = AssociatedObject<ActionClosure>()
	}

	@objc
	private func callClosure(_ sender: NSControl) {
		onAction?(sender)
	}

	/**
	Closure version of `.action`.

	```
	let button = NSButton(title: "Unicorn", target: nil, action: nil)

	button.onAction = { sender in
		print("Button action: \(sender)")
	}
	```
	*/
	var onAction: ActionClosure? {
		get { AssociatedKeys.onActionClosure[self] }
		set {
			AssociatedKeys.onActionClosure[self] = newValue
			action = #selector(callClosure)
			target = self
		}
	}
}

extension NSView {
	static func animate(
		duration: TimeInterval = 1,
		delay: TimeInterval = 0,
		timingFunction: CAMediaTimingFunction = .default,
		animations: @escaping (() -> Void),
		completion: (() -> Void)? = nil
	) {
		DispatchQueue.main.asyncAfter(duration: delay) {
			NSAnimationContext.runAnimationGroup({ context in
				context.allowsImplicitAnimation = true
				context.duration = duration
				context.timingFunction = timingFunction
				animations()
			}, completionHandler: completion)
		}
	}

	func fadeIn(
		duration: TimeInterval = 1,
		delay: TimeInterval = 0,
		completion: (() -> Void)? = nil
	) {
		isHidden = true

		NSView.animate(
			duration: duration,
			delay: delay,
			animations: {
				self.isHidden = false
			},
			completion: completion
		)
	}
}

extension CABasicAnimation {
	/// Rotates the element around its center point infinitely.
	static var rotate: CABasicAnimation {
		let animation = CABasicAnimation(keyPath: #keyPath(CAShapeLayer.transform))
		animation.valueFunction = CAValueFunction(name: .rotateZ)
		animation.fromValue = 0
		animation.toValue = -(Double.pi * 2)
		animation.duration = 1
		animation.repeatCount = .infinity
		animation.timingFunction = CAMediaTimingFunction(name: .linear)
		return animation
	}
}

extension NSWindow {
	/// Whether the window or its owning app is showing a modal or sheet.
	/// This can be useful to disable any unintended interaction underneath it,
	/// for example, drag and drop or mouse hover.
	var isShowingModalOrSheet: Bool {
		NSApp.modalWindow != nil ||
		attachedSheet != nil
	}
}

func assertMainThread(
	function: StaticString = #function,
	file: String = #file,
	line: UInt = #line
) {
	assert(Thread.isMainThread, "\(function) in \((file as NSString).lastPathComponent):\(line) must run on the main thread!")
}
