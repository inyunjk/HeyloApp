import UIKit

class AnimatedPlaceholderTextField: UITextField {

    // MARK: - Properties
    private let placeholderLabel = UILabel()
    private let bottomLine = UIView()

    override var text: String? {
        didSet {
            // Update placeholder position when text is programmatically changed
            updatePlaceholderPosition()
        }
    }

    var placeholderText: String? {
        didSet {
            placeholderLabel.text = placeholderText
            placeholder = ""
            // Update placeholder position in case text is already set
            updatePlaceholderPosition()
        }
    }

    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    // MARK: - Layout
    override func layoutSubviews() {
        super.layoutSubviews()
        // Update placeholder position when layout changes
        updatePlaceholderPosition()
    }

    // MARK: - Setup
    private func setupView() {
        // Text color
        textColor = .white
        tintColor = .white

        // Bottom line
        bottomLine.backgroundColor = .white
        bottomLine.translatesAutoresizingMaskIntoConstraints = false
        addSubview(bottomLine)

        NSLayoutConstraint.activate([
            bottomLine.leadingAnchor.constraint(equalTo: leadingAnchor),
            bottomLine.trailingAnchor.constraint(equalTo: trailingAnchor),
            bottomLine.bottomAnchor.constraint(equalTo: bottomAnchor),
            bottomLine.heightAnchor.constraint(equalToConstant: 1)
        ])

        // Placeholder label
        placeholderLabel.textColor = .lightGray
        placeholderLabel.font = UIFont.systemFont(ofSize: 16)
        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(placeholderLabel)

        NSLayoutConstraint.activate([
            placeholderLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            placeholderLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])

        // Add target for text changes
        addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        addTarget(self, action: #selector(textFieldDidBeginEditing), for: .editingDidBegin)
        addTarget(self, action: #selector(textFieldDidEndEditing), for: .editingDidEnd)
    }

    // MARK: - Text Field Events
    @objc private func textFieldDidChange() {
        updatePlaceholderPosition()
    }

    @objc private func textFieldDidBeginEditing() {
        // Always move placeholder up when editing begins, regardless of text content
        UIView.animate(withDuration: 0.2) {
            self.placeholderLabel.font = UIFont.systemFont(ofSize: 12)
            self.placeholderLabel.transform = CGAffineTransform(translationX: 0, y: -25)
            self.placeholderLabel.textColor = UIColor.white.withAlphaComponent(0.7)
        }
        animateBottomLine(isEditing: true)

        // Force layout update
        setNeedsLayout()
        layoutIfNeeded()
    }

    @objc private func textFieldDidEndEditing() {
        updatePlaceholderPosition()
        animateBottomLine(isEditing: false)

        // Force layout update
        setNeedsLayout()
        layoutIfNeeded()
    }

    // MARK: - Animations
    private func updatePlaceholderPosition() {
        if let text = text, !text.isEmpty || isFirstResponder {
            // Keep placeholder above text field if there's text or field is being edited
            UIView.animate(withDuration: 0.2) {
                self.placeholderLabel.font = UIFont.systemFont(ofSize: 12)
                self.placeholderLabel.transform = CGAffineTransform(translationX: 0, y: -25)
                self.placeholderLabel.textColor = UIColor.white.withAlphaComponent(0.7)
            }
        } else {
            // Return placeholder to original position only if not editing and empty
            UIView.animate(withDuration: 0.2) {
                self.placeholderLabel.font = UIFont.systemFont(ofSize: 16)
                self.placeholderLabel.transform = .identity
                self.placeholderLabel.textColor = .lightGray
            }
        }

        // Force layout update after animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.setNeedsLayout()
            self.layoutIfNeeded()
        }
    }

    private func animateBottomLine(isEditing: Bool) {
        UIView.animate(withDuration: 0.2) {
            self.bottomLine.backgroundColor = isEditing ? .white : .white.withAlphaComponent(0.7)
            self.bottomLine.transform = isEditing ? CGAffineTransform(scaleX: 1, y: 1.5) : .identity
        }
    }
}
