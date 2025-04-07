import UIKit

class HeyloButton: UIButton {

    enum ButtonStyle {
        case primary
        case secondary
        case text
    }

    // MARK: - Properties
    private var style: ButtonStyle = .primary

    // MARK: - Initialization
    init(style: ButtonStyle, title: String) {
        super.init(frame: .zero)
        self.style = style
        setTitle(title, for: .normal)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    // MARK: - Setup
    private func setupView() {
        translatesAutoresizingMaskIntoConstraints = false
        titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)

        switch style {
        case .primary:
            backgroundColor = .black
            layer.borderWidth = 1
            layer.borderColor = UIColor.white.cgColor
            setTitleColor(.white, for: .normal)
            layer.cornerRadius = 8
            contentEdgeInsets = UIEdgeInsets(top: 12, left: 24, bottom: 12, right: 24)

        case .secondary:
            backgroundColor = .clear
            layer.borderWidth = 1
            layer.borderColor = UIColor.white.cgColor
            setTitleColor(.white, for: .normal)
            layer.cornerRadius = 8
            contentEdgeInsets = UIEdgeInsets(top: 12, left: 24, bottom: 12, right: 24)

        case .text:
            backgroundColor = .clear
            setTitleColor(.white, for: .normal)
            contentEdgeInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        }

        // Add shadow for primary and secondary buttons
        if style != .text {
            layer.shadowColor = UIColor.black.cgColor
            layer.shadowOffset = CGSize(width: 0, height: 2)
            layer.shadowRadius = 4
            layer.shadowOpacity = 0.2
        }

        // Add touch animations
        addTarget(self, action: #selector(touchDown), for: [.touchDown, .touchDragEnter])
        addTarget(self, action: #selector(touchUp), for: [.touchUpInside, .touchDragExit, .touchCancel])
    }

    // MARK: - Touch Animations
    @objc private func touchDown() {
        UIView.animate(withDuration: 0.1) {
            self.transform = CGAffineTransform(scaleX: 0.97, y: 0.97)
            self.alpha = 0.9
        }
    }

    @objc private func touchUp() {
        UIView.animate(withDuration: 0.1) {
            self.transform = .identity
            self.alpha = 1.0
        }
    }
}
