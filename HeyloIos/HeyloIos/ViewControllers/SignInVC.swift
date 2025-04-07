import UIKit
import FirebaseAuth

class SignInVC: UIViewController {

    // MARK: - UI Elements
    private let heyloTitleLabel: GradientTextLabel = {
        let label = GradientTextLabel()
        label.text = "Heylo"
        label.font = UIFont.systemFont(ofSize: 72, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let subtitleLabel: GradientTextInlineLabel = {
        let label = GradientTextInlineLabel()
        let text = "Discover real connections near you"
        let range = (text as NSString).range(of: "real connections")
        label.setGradientText(text, highlightRange: range)
        label.textColor = .lightGray
        label.font = UIFont.systemFont(ofSize: 16)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()



    private let emailTextField: AnimatedPlaceholderTextField = {
        let textField = AnimatedPlaceholderTextField()
        textField.placeholderText = "Email"
        textField.keyboardType = .emailAddress
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()

    private let passwordTextField: AnimatedPlaceholderTextField = {
        let textField = AnimatedPlaceholderTextField()
        textField.placeholderText = "Password"
        textField.isSecureTextEntry = true
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()

    private lazy var signInButton: HeyloButton = {
        let button = HeyloButton(style: .primary, title: "Sign In")
        button.addTarget(self, action: #selector(signInButtonTapped), for: .touchUpInside)
        return button
    }()

    private lazy var signUpButton: HeyloButton = {
        let button = HeyloButton(style: .text, title: "Don't have an account? Sign Up")
        button.addTarget(self, action: #selector(signUpButtonTapped), for: .touchUpInside)
        return button
    }()

    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
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
        setupKeyboardHandling()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        removeKeyboardHandling()
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
        view.addSubview(subtitleLabel)
        view.addSubview(emailTextField)
        view.addSubview(passwordTextField)
        view.addSubview(signInButton)
        view.addSubview(signUpButton)
        view.addSubview(activityIndicator)

        // Setup text field delegates
        emailTextField.delegate = self
        passwordTextField.delegate = self

        // Setup return key types
        emailTextField.returnKeyType = .next
        passwordTextField.returnKeyType = .done
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Heylo Title
            heyloTitleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 80),
            heyloTitleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            heyloTitleLabel.heightAnchor.constraint(equalToConstant: 100),

            // Subtitle
            subtitleLabel.topAnchor.constraint(equalTo: heyloTitleLabel.bottomAnchor, constant: 20),
            subtitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            subtitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            // Email TextField
            emailTextField.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 60),
            emailTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            emailTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            emailTextField.heightAnchor.constraint(equalToConstant: 50),

            // Password TextField
            passwordTextField.topAnchor.constraint(equalTo: emailTextField.bottomAnchor, constant: 20),
            passwordTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            passwordTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            passwordTextField.heightAnchor.constraint(equalToConstant: 50),

            // Sign In Button
            signInButton.topAnchor.constraint(equalTo: passwordTextField.bottomAnchor, constant: 40),
            signInButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            signInButton.widthAnchor.constraint(equalToConstant: 250),

            // Sign Up Button
            signUpButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            signUpButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            // Activity Indicator
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }



    // MARK: - Actions
    // Flag to prevent multiple rapid taps
    private var isSigningIn = false

    @objc private func signInButtonTapped() {
        // Prevent multiple rapid taps
        guard !isSigningIn else { return }
        isSigningIn = true

        // Add a slight delay to ensure UI updates properly
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.performSignIn()
        }
    }

    private func performSignIn() {
        guard let email = emailTextField.text, !email.isEmpty,
              let password = passwordTextField.text, !password.isEmpty else {
            showAlert(title: "Error", message: "Please enter both email and password")
            return
        }

        // Show loading indicator
        activityIndicator.startAnimating()
        signInButton.isEnabled = false

        // Attempt to sign in using the secure backend function
        AuthService.shared.signIn(email: email, password: password) { [weak self] result in
            guard let self = self else { return }

            // Hide loading indicator
            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()
                self.signInButton.isEnabled = true
                self.isSigningIn = false

                switch result {
                case .success(let user):
                    // Check if email is verified
                    if user.isEmailVerified {
                        // Show PreHomeVC
                        self.showPreHomeVC()
                    } else {
                        // Show email verification screen
                        self.showPendingEmailVerificationVC()
                    }

                case .failure(let error):
                    // Check if it's a rate limiting error
                    if error.localizedDescription.contains("Too many sign-in attempts") {
                        #if DEBUG
                        // In debug mode, offer to reset rate limiters
                        let alert = UIAlertController(title: "Rate Limit Exceeded", message: "\(error.localizedDescription)\n\nWould you like to reset rate limiters for development?", preferredStyle: .alert)

                        alert.addAction(UIAlertAction(title: "Reset", style: .default) { [weak self] _ in
                            self?.resetRateLimiters()
                        })

                        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

                        self.present(alert, animated: true)
                        #else
                        // In production, just show the error
                        self.showAlert(title: "Sign In Failed", message: error.localizedDescription)
                        #endif
                    } else {
                        // For other errors, show the standard error message
                        self.showAlert(title: "Sign In Failed", message: error.localizedDescription)
                    }
                }
            }
        }
    }

    @objc private func signUpButtonTapped() {
        let signUpVC = SignUpVC()
        navigationController?.pushViewController(signUpVC, animated: true)
    }



    // MARK: - Navigation
    private func showPreHomeVC() {
        let preHomeVC = PreHomeVC()
        preHomeVC.modalPresentationStyle = .fullScreen
        present(preHomeVC, animated: true)
    }

    private func showPendingEmailVerificationVC() {
        let pendingVC = PendingEmailVerificationVC()
        navigationController?.pushViewController(pendingVC, animated: true)
    }

    // MARK: - Helper Methods
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    #if DEBUG
    private func resetRateLimiters() {
        // Show loading indicator
        activityIndicator.startAnimating()
        signInButton.isEnabled = false

        AuthService.shared.resetRateLimiters { [weak self] result in
            guard let self = self else { return }

            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()
                self.signInButton.isEnabled = true

                switch result {
                case .success:
                    self.showAlert(title: "Rate Limiters Reset", message: "Rate limiters have been reset. You can now try signing in again.")
                case .failure(let error):
                    self.showAlert(title: "Reset Failed", message: "Failed to reset rate limiters: \(error.localizedDescription)")
                }
            }
        }
    }
    #endif
}

// MARK: - UITextFieldDelegate
extension SignInVC: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case emailTextField:
            passwordTextField.becomeFirstResponder()
        case passwordTextField:
            textField.resignFirstResponder()
            signInButtonTapped()
        default:
            textField.resignFirstResponder()
        }
        return true
    }
}
