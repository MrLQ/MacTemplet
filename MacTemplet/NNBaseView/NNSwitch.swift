//
// NSSwitch.swift
//

import Cocoa

protocol NSSwitchDelegate {
    func switchChanged(switch: NNSwitch)
}

@IBDesignable
/// A UISWitch clone for macOS.
public class NNSwitch: NSControl {
    var delegate: NSSwitchDelegate?
    /// Reflects the current state of the `NSSwitch`.
    private (set) public var on = false
    
    /// Set the `on` property, optionally animate the change.
    ///
    /// - Parameter on: The state to set the switch.
    /// - Parameter animated: Specify whether the state change should be animated.
    public func setOn(on: Bool, animated: Bool) {
        if animated {
            animate(on: on)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            let bgColor = on ? self.onColor : self.offColor
            self.backgroundView.layer?.backgroundColor = bgColor.cgColor
        }

        self.on = on
        delegate?.switchChanged(switch: self)
    }
    
    /// The CAMediaTimingFunction for the switch animation.
    public var mediaTimingFunction = CAMediaTimingFunctionName.easeIn
    
    /// The duration of the switch animation.
    /// default value is 0.20.
    public var thumbAnimationDuration = 0.20
    
    /// The `NSColor` value of the `backgroundView` when the property `on` is set to true.
    @IBInspectable public var onColor: NSColor = NSColor(red: 40/255.0, green: 150/255.0, blue: 245/255.0, alpha: 1.0)
    
    /// The `NSColor` value of the `backgroundView` when the property `on` is set to false.
    @IBInspectable public var offColor: NSColor = NSColor(red: 114/255.0, green: 114/255.0, blue: 114/255.0, alpha: 1.0) {
        didSet { backgroundView.layer?.backgroundColor = offColor.cgColor }
    }
    
    /// The `NSColor` value of the `thumbView`.
    @IBInspectable public var thumbColor: NSColor = NSColor.white {
        didSet { thumbView.layer?.backgroundColor = thumbColor.cgColor }
    }
    
    /// The background `NSView` of the `NSSwitch`.
    public var backgroundView: NSView!
    
    /// An instance of `NSSwitchThumbView` for the thumb knob component.
    public var thumbView: NNSwitchThumbView!
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    public override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }
    
    private var dragVelocityGain: CGFloat = 0.3
    
    private var radius: CGFloat {
        return self.bounds.size.height / 2
    }

    private func setup() {
        drawBGView()
        drawThumbKnobView()
        let clickRecognizer = NSClickGestureRecognizer(target: self, action: #selector(NNSwitch.clicked(click:)))
        let panRecognizer = NSPanGestureRecognizer(target: self, action: #selector(NNSwitch.panned(pan:)))
        thumbView.addGestureRecognizer(panRecognizer)
        backgroundView.addGestureRecognizer(clickRecognizer)
        backgroundView.addSubview(thumbView)
        self.addSubview(backgroundView)
    }
    
    private func drawThumbKnobView() {
        let thumbOrigin = CGPoint(x: backgroundView.bounds.origin.x,
                                  y: backgroundView.bounds.origin.y)
        
        let diameter = backgroundView.bounds.size.height
        let thumbSize = CGSize(width: diameter, height: diameter)
        let thumbFrame = CGRect(origin: thumbOrigin, size: thumbSize)
        thumbView = NNSwitchThumbView(frame: thumbFrame)
        thumbView.wantsLayer = true
        
        if let layer = thumbView.layer {
            layer.backgroundColor = thumbColor.cgColor
            layer.cornerRadius = radius
        }
    }
    
    private func drawBGView() {
        // Draw the backgroundView
        backgroundView = NSView(frame: self.bounds)
        backgroundView.wantsLayer = true
        
        if let layer = backgroundView.layer {
            layer.backgroundColor = offColor.cgColor
            layer.cornerRadius = radius
        }
    }
    
    // MARK: - NSGesture handlers.
    
    @objc private func clicked(click: NSClickGestureRecognizer) {
        setOn(on: !on, animated: true)
        sendAction(self.action, to: self.target)
    }
    
    @objc private func panned(pan: NSPanGestureRecognizer) {
        switch pan.state {
        case .changed:
            changed(pan: pan)
            break
        case .ended:
            sendAction(self.action, to: self.target)
            moveToNearestSwitchPosition()
            break
        default:
            break
        }
    }
    
    private func changed(pan: NSPanGestureRecognizer) {
        updatePosition(pan: pan)
        let x = thumbView.frame.origin.x
        let thumbViewWidth = thumbView.bounds.size.width
        let backgroundViewWidth = backgroundView.bounds.size.width
        if x + thumbViewWidth / 2 >= backgroundViewWidth / 2 {
            setOn(on: true, animated: false)
        } else {
            setOn(on: false, animated: false)
        }
    }
    
    private func animate(on: Bool) {
        CATransaction.begin()
        CATransaction.setAnimationDuration(thumbAnimationDuration)
        CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: mediaTimingFunction))
        
        if on {
            let x = backgroundView.bounds.size.width - thumbView.frame.size.width
            let destinationOrigin = CGPoint(x: x, y: 0)
            thumbView.animator().setFrameOrigin(destinationOrigin)
        }
        else {
            let destinationOrigin = CGPoint(x: 0, y: 0)
            thumbView.animator().setFrameOrigin(destinationOrigin)
        }
        
        CATransaction.commit()
    }
    
    private func updatePosition(pan: NSPanGestureRecognizer) {
        let thumbWidth = thumbView.bounds.size.width
        let leadingSpace = thumbView.frame.origin.x
        let trailingSpace = backgroundView.bounds.size.width - (leadingSpace + thumbWidth)
        let xTranslation = pan.translation(in: backgroundView).x
        
        if xTranslation >= 0 {
            let delta = trailingSpace >= xTranslation ? xTranslation : trailingSpace
            thumbView.frame.origin.x += delta * dragVelocityGain
        } else {
            if leadingSpace >= -xTranslation {
                thumbView.frame.origin.x += xTranslation * dragVelocityGain
            } else {
                thumbView.frame.origin.x += -leadingSpace * dragVelocityGain
            }
        }
    }
    
    private func moveToNearestSwitchPosition() {
        setOn(on: on, animated: true)
    }
}
