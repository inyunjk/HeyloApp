import UIKit

class LoadingAnimationView: UIView {

    // MARK: - Properties
    private let circleView = UIView()
    private let pulseView = UIView()
    private let logoLabel = UILabel()

    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    // MARK: - Setup
    private func setupView() {
        backgroundColor = .clear

        // Setup circle view
        circleView.backgroundColor = .clear
        circleView.layer.borderColor = UIColor.white.cgColor
        circleView.layer.borderWidth = 3
        circleView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(circleView)

        // Setup pulse view
        pulseView.backgroundColor = .clear
        pulseView.layer.borderColor = UIColor.white.withAlphaComponent(0.3).cgColor
        pulseView.layer.borderWidth = 3
        pulseView.translatesAutoresizingMaskIntoConstraints = false
        insertSubview(pulseView, belowSubview: circleView)

        // Setup logo label
        logoLabel.text = "H"
        logoLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        logoLabel.textColor = .white
        logoLabel.textAlignment = .center
        logoLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(logoLabel)

        // Setup constraints
        NSLayoutConstraint.activate([
            // Logo label
            logoLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            logoLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            logoLabel.widthAnchor.constraint(equalToConstant: 40),
            logoLabel.heightAnchor.constraint(equalToConstant: 40),

            // Circle view
            circleView.centerXAnchor.constraint(equalTo: centerXAnchor),
            circleView.centerYAnchor.constraint(equalTo: centerYAnchor),
            circleView.widthAnchor.constraint(equalToConstant: 120),
            circleView.heightAnchor.constraint(equalToConstant: 120),

            // Pulse view
            pulseView.centerXAnchor.constraint(equalTo: centerXAnchor),
            pulseView.centerYAnchor.constraint(equalTo: centerYAnchor),
            pulseView.widthAnchor.constraint(equalToConstant: 120),
            pulseView.heightAnchor.constraint(equalToConstant: 120)
        ])
    }

    // MARK: - Layout
    override func layoutSubviews() {
        super.layoutSubviews()

        // Make the circle and pulse views round
        circleView.layer.cornerRadius = circleView.bounds.width / 2
        pulseView.layer.cornerRadius = pulseView.bounds.width / 2
    }

    // MARK: - Animation
    func startAnimating() {
        // Remove any existing animations
        stopAnimating()

        // Rotate animation for circle
        UIView.animate(withDuration: 0.01) { [weak self] in
            self?.circleView.transform = .identity
        } completion: { [weak self] _ in
            UIView.animate(withDuration: 3.0, delay: 0, options: [.repeat, .curveLinear]) {
                self?.circleView.transform = CGAffineTransform(rotationAngle: .pi * 2)
            }
        }

        // Pulse animation
        UIView.animate(withDuration: 0.01) { [weak self] in
            self?.pulseView.transform = .identity
        } completion: { [weak self] _ in
            UIView.animate(withDuration: 1.5, delay: 0, options: [.repeat, .autoreverse]) {
                self?.pulseView.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
            }
        }

        // Fade animation for logo
        UIView.animate(withDuration: 0.01) { [weak self] in
            self?.logoLabel.alpha = 1.0
        } completion: { [weak self] _ in
            UIView.animate(withDuration: 1.5, delay: 0, options: [.repeat, .autoreverse]) {
                self?.logoLabel.alpha = 0.5
            }
        }
    }

    func stopAnimating() {
        // Stop all animations
        circleView.layer.removeAllAnimations()
        pulseView.layer.removeAllAnimations()
        logoLabel.layer.removeAllAnimations()

        // Reset transforms
        circleView.transform = .identity
        pulseView.transform = .identity
        logoLabel.alpha = 1.0
    }
}
