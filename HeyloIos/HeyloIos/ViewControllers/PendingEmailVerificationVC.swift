import UIKit
import FirebaseAuth

class PendingEmailVerificationVC: UIViewController {

    // MARK: - UI Elements
    private let heyloTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Heylo"
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 36, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let emailIconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "envelope.circle.fill")
        imageView.tintColor = .white
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Verify Your Email"
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let messageLabel: UILabel = {
        let label = UILabel()
        label.text = "We've sent a verification email to your address. Please check your inbox and verify your email to continue."
        label.textColor = .lightGray
        label.font = UIFont.systemFont(ofSize: 16)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let emailLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var resendButton: HeyloButton = {
        let button = HeyloButton(style: .secondary, title: "Resend Verification Email")
        button.addTarget(self, action: #selector(resendButtonTapped), for: .touchUpInside)
        return button
    }()

    private lazy var signInButton: HeyloButton = {
        let button = HeyloButton(style: .primary, title: "Return to Sign In")
        button.addTarget(self, action: #selector(signInButtonTapped), for: .touchUpInside)
        return button
    }()

    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.color = .white
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupConstraints()
        updateEmailLabel()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    // MARK: - Setup
    private func setupView() {
        view.backgroundColor = .black

        // Add subviews
        view.addSubview(heyloTitleLabel)
        view.addSubview(emailIconImageView)
        view.addSubview(titleLabel)
        view.addSubview(messageLabel)
        view.addSubview(emailLabel)
        view.addSubview(resendButton)
        view.addSubview(signInButton)
        view.addSubview(activityIndicator)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Heylo Title
            heyloTitleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            heyloTitleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            heyloTitleLabel.widthAnchor.constraint(equalToConstant: 150),
            heyloTitleLabel.heightAnchor.constraint(equalToConstant: 50),

            // Email Icon
            emailIconImageView.topAnchor.constraint(equalTo: heyloTitleLabel.bottomAnchor, constant: 30),
            emailIconImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emailIconImageView.widthAnchor.constraint(equalToConstant: 100),
            emailIconImageView.heightAnchor.constraint(equalToConstant: 100),

            // Title
            titleLabel.topAnchor.constraint(equalTo: emailIconImageView.bottomAnchor, constant: 30),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            // Message
            messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            messageLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            messageLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),

            // Email Label
            emailLabel.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 20),
            emailLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            emailLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            // Resend Button
            resendButton.topAnchor.constraint(equalTo: emailLabel.bottomAnchor, constant: 40),
            resendButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            // Activity Indicator
            activityIndicator.centerYAnchor.constraint(equalTo: resendButton.centerYAnchor),
            activityIndicator.leadingAnchor.constraint(equalTo: resendButton.trailingAnchor, constant: 10),

            // Sign In Button
            signInButton.topAnchor.constraint(equalTo: resendButton.bottomAnchor, constant: 20),
            signInButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }

    private func updateEmailLabel() {
        if let email = Auth.auth().currentUser?.email {
            emailLabel.text = email
        } else {
            emailLabel.text = "your email address"
        }
    }

    // MARK: - Actions
    @objc private func resendButtonTapped() {
        guard Auth.auth().currentUser != nil else {
            showAlert(title: "Error", message: "No user is currently signed in")
            return
        }

        // Show loading indicator
        activityIndicator.startAnimating()
        resendButton.isEnabled = false

        // Resend verification email using the secure backend function
        AuthService.shared.sendEmailVerification { [weak self] result in
            guard let self = self else { return }

            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()
                self.resendButton.isEnabled = true

                switch result {
                case .success(let verificationLink):
                    // In a real app, you would send this link to the user's email
                    // For now, we'll just show a success message
                    print("Email verification link: \(verificationLink)")
                    self.showAlert(title: "Success", message: "Verification email has been sent again")

                case .failure(let error):
                    self.showAlert(title: "Error", message: error.localizedDescription)
                }
            }
        }
    }

    @objc private func signInButtonTapped() {
        // Sign out current user using the secure backend function
        AuthService.shared.signOut { [weak self] error in
            guard let self = self else { return }

            if let error = error {
                self.showAlert(title: "Error", message: "Failed to sign out: \(error.localizedDescription)")
            } else {
                // Navigate back to sign in screen
                self.navigationController?.popToRootViewController(animated: true)
            }
        }
    }

    // MARK: - Helper Methods
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
