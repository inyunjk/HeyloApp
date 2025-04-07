import UIKit
import CoreMotion

class GradientTextInlineLabel: UILabel {
    // MARK: - Properties
    private let gradientLayer = CAGradientLayer()
    private let metallicLayer = CAGradientLayer()
    private let containerLayer = CALayer()
    private let motionManager = CMMotionManager()
    private var displayLink: CADisplayLink?
    
    // Text range to apply gradient
    private var gradientRange: NSRange?
    
    // Gradient colors - vibrant rainbow version
    private let gradientColors: [UIColor] = [
        UIColor(red: 255/255, green: 105/255, blue: 180/255, alpha: 1.0),  // Hot Pink
        UIColor(red: 255/255, green: 165/255, blue: 0/255, alpha: 1.0),    // Orange
        UIColor(red: 255/255, green: 215/255, blue: 0/255, alpha: 1.0),    // Gold
        UIColor(red: 50/255, green: 205/255, blue: 50/255, alpha: 1.0),    // Lime Green
        UIColor(red: 0/255, green: 191/255, blue: 255/255, alpha: 1.0),    // Deep Sky Blue
        UIColor(red: 147/255, green: 112/255, blue: 219/255, alpha: 1.0),  // Medium Purple
        UIColor(red: 255/255, green: 69/255, blue: 0/255, alpha: 1.0)      // Red-Orange
    ]
    
    // Metallic overlay colors
    private let metallicColors: [UIColor] = [
        UIColor(white: 1.0, alpha: 0.8),   // Bright highlight
        UIColor(white: 1.0, alpha: 0.4),   // Medium highlight
        UIColor(white: 1.0, alpha: 0.1),   // Subtle highlight
        UIColor(white: 0.0, alpha: 0.1),   // Subtle shadow
        UIColor(white: 0.0, alpha: 0.4),   // Medium shadow
        UIColor(white: 0.0, alpha: 0.8)    // Dark shadow
    ]
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupGradient()
        setupMetallicEffect()
        setupMotion()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupGradient()
        setupMetallicEffect()
        setupMotion()
    }
    
    // MARK: - Public Methods
    func setGradientText(_ text: String, highlightRange: NSRange) {
        self.text = text
        self.gradientRange = highlightRange
        setNeedsDisplay()
    }
    
    // MARK: - Setup
    private func setupGradient() {
        // Configure gradient layer
        gradientLayer.colors = gradientColors.map { $0.cgColor }
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)  // Start from top-left
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)    // End at bottom-right
        gradientLayer.locations = [0.0, 0.15, 0.3, 0.45, 0.6, 0.75, 0.9, 1.0]  // Adjusted for more colors
        
        // Add gradient layer to container
        containerLayer.addSublayer(gradientLayer)
    }
    
    private func setupMetallicEffect() {
        // Configure metallic overlay layer
        metallicLayer.colors = metallicColors.map { $0.cgColor }
        metallicLayer.startPoint = CGPoint(x: 0, y: 0)
        metallicLayer.endPoint = CGPoint(x: 1, y: 1)
        metallicLayer.locations = [0.0, 0.2, 0.4, 0.6, 0.8, 1.0]
        
        // Add metallic layer to container
        containerLayer.addSublayer(metallicLayer)
        
        // Add a subtle shadow for depth
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 1)
        layer.shadowOpacity = 0.3
        layer.shadowRadius = 2
    }
    
    private func setupMotion() {
        // Configure motion manager
        motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
        motionManager.startDeviceMotionUpdates()
        
        // Setup display link for smooth updates
        displayLink = CADisplayLink(target: self, selector: #selector(updateGradientPosition))
        displayLink?.add(to: .main, forMode: .common)
    }
    
    @objc private func updateGradientPosition() {
        guard let motion = motionManager.deviceMotion else { return }
        
        // Get device motion data
        let roll = motion.attitude.roll
        let pitch = motion.attitude.pitch
        
        // Calculate offsets for gradient movement
        let xOffset = CGFloat(roll) * 0.4
        let yOffset = CGFloat(pitch) * 0.4
        
        // Shift gradient locations based on motion
        let baseLocations: [NSNumber] = [0.0, 0.15, 0.3, 0.45, 0.6, 0.75, 0.9, 1.0]
        let shiftedLocations = baseLocations.map { NSNumber(value: ($0.doubleValue + xOffset).truncatingRemainder(dividingBy: 1.0)) }
        gradientLayer.locations = shiftedLocations
        
        // Shift metallic layer locations for sheen effect
        let metallicBaseLocations: [NSNumber] = [0.0, 0.2, 0.4, 0.6, 0.8, 1.0]
        let metallicShiftedLocations = metallicBaseLocations.map { NSNumber(value: ($0.doubleValue + yOffset).truncatingRemainder(dividingBy: 1.0)) }
        metallicLayer.locations = metallicShiftedLocations
        
        // Update gradient start and end points
        gradientLayer.startPoint = CGPoint(x: xOffset, y: yOffset)
        gradientLayer.endPoint = CGPoint(x: 1 + xOffset, y: 1 + yOffset)
        
        // Update metallic layer start and end points with different offset
        metallicLayer.startPoint = CGPoint(x: xOffset * 0.5, y: yOffset * 0.5)
        metallicLayer.endPoint = CGPoint(x: 1 + xOffset * 0.5, y: 1 + yOffset * 0.5)
    }
    
    // MARK: - Layout
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Create a mask from the text
        if let text = text, let gradientRange = gradientRange {
            // Create attributed string with the full text
            let fullAttributedString = NSMutableAttributedString(string: text)
            fullAttributedString.addAttribute(.foregroundColor, value: textColor ?? UIColor.white, range: NSRange(location: 0, length: text.count))
            
            // Create a separate attributed string for the gradient part
            if gradientRange.location + gradientRange.length <= text.count {
                let gradientText = (text as NSString).substring(with: gradientRange)
                
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: font as Any,
                    .foregroundColor: UIColor.white
                ]
                
                let gradientAttributedString = NSAttributedString(string: gradientText, attributes: attributes)
                let size = gradientAttributedString.size()
                
                UIGraphicsBeginImageContextWithOptions(size, false, 0)
                gradientAttributedString.draw(at: .zero)
                
                if let image = UIGraphicsGetImageFromCurrentImageContext() {
                    UIGraphicsEndImageContext()
                    
                    // Create a mask from the image
                    let maskLayer = CALayer()
                    maskLayer.contents = image.cgImage
                    
                    // Calculate the position of the gradient text within the full text
                    let fullTextAttributes = [NSAttributedString.Key.font: font as Any]
                    let fullTextSize = (text as NSString).size(withAttributes: fullTextAttributes)
                    
                    // Calculate the starting position of the gradient text
                    let startOfGradientText = (text as NSString).substring(to: gradientRange.location)
                    let startAttributes = [NSAttributedString.Key.font: font as Any]
                    let startSize = (startOfGradientText as NSString).size(withAttributes: startAttributes)
                    
                    // Make container larger than bounds to allow full movement
                    let padding: CGFloat = 50  // Add padding around the text
                    containerLayer.frame = CGRect(x: -padding, y: -padding, 
                                               width: size.width + padding * 2, 
                                               height: size.height + padding * 2)
                    
                    // Position the mask layer at the correct location
                    maskLayer.frame = CGRect(x: padding, y: padding, 
                                           width: size.width, height: size.height)
                    
                    // Apply the mask to the container layer
                    containerLayer.mask = maskLayer
                    
                    // Set gradient layers to match container bounds
                    gradientLayer.frame = containerLayer.bounds
                    metallicLayer.frame = containerLayer.bounds
                    
                    // Ensure the layers are always visible
                    gradientLayer.opacity = 1.0
                    metallicLayer.opacity = 0.8
                    
                    // Calculate the position for the container layer
                    let textRect = self.textRect(forBounds: bounds, limitedToNumberOfLines: numberOfLines)
                    let xPosition = textRect.origin.x + startSize.width
                    let yPosition = textRect.origin.y
                    
                    // Position the container layer
                    containerLayer.position = CGPoint(x: xPosition + size.width/2, y: yPosition + size.height/2)
                    
                    // Add container layer to main layer if not already added
                    if containerLayer.superlayer == nil {
                        layer.addSublayer(containerLayer)
                    }
                }
            }
        }
    }
    
    // MARK: - Cleanup
    deinit {
        motionManager.stopDeviceMotionUpdates()
        displayLink?.invalidate()
    }
}
