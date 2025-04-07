import UIKit
import AVFoundation

class SignUpVC: UIViewController {

    // MARK: - Properties
    private var profileImage: UIImage?

    // MARK: - UI Elements
    private let heyloTitleLabel: GradientTextLabel = {
        let label = GradientTextLabel()
        label.text = "Heylo"
        label.font = UIFont.systemFont(ofSize: 48, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let createAccountLabel: UILabel = {
        let label = UILabel()
        label.text = "Create Account"
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let profileImageButton: UIButton = {
        let button = UIButton()
        let config = UIImage.SymbolConfiguration(pointSize: 120, weight: .regular)
        button.setImage(UIImage(systemName: "person.circle.fill", withConfiguration: config), for: .normal)
        button.tintColor = .white
        button.contentMode = .scaleAspectFill
        button.layer.cornerRadius = 75
        button.layer.masksToBounds = true
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let cameraIconView: UIImageView = {
        let imageView = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .regular)
        imageView.image = UIImage(systemName: "camera.fill", withConfiguration: config)
        imageView.tintColor = .white
        imageView.backgroundColor = .black
        imageView.layer.cornerRadius = 18
        imageView.layer.masksToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let displayNameTextField: AnimatedPlaceholderTextField = {
        let textField = AnimatedPlaceholderTextField()
        textField.placeholderText = "Display Name"
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
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

    private let confirmPasswordTextField: AnimatedPlaceholderTextField = {
        let textField = AnimatedPlaceholderTextField()
        textField.placeholderText = "Confirm Password"
        textField.isSecureTextEntry = true
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()

    private lazy var signUpButton: HeyloButton = {
        let button = HeyloButton(style: .primary, title: "Sign Up")
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
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    // MARK: - Setup
    private func setupView() {
        view.backgroundColor = .black

        // Setup navigation bar
        navigationController?.navigationBar.tintColor = .white
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(backButtonTapped)
        )

        // Add subviews
        view.addSubview(heyloTitleLabel)
        view.addSubview(createAccountLabel)
        view.addSubview(profileImageButton)
        view.addSubview(cameraIconView)
        view.addSubview(displayNameTextField)
        view.addSubview(emailTextField)
        view.addSubview(passwordTextField)
        view.addSubview(confirmPasswordTextField)
        view.addSubview(signUpButton)
        view.addSubview(activityIndicator)

        // Setup profile image button
        profileImageButton.addTarget(self, action: #selector(profileImageButtonTapped), for: .touchUpInside)

        // Setup text field delegates
        displayNameTextField.delegate = self
        emailTextField.delegate = self
        passwordTextField.delegate = self
        confirmPasswordTextField.delegate = self

        // Setup return key types
        displayNameTextField.returnKeyType = .next
        emailTextField.returnKeyType = .next
        passwordTextField.returnKeyType = .next
        confirmPasswordTextField.returnKeyType = .done
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Heylo Title
            heyloTitleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            heyloTitleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            heyloTitleLabel.heightAnchor.constraint(equalToConstant: 60),

            // Create Account Label
            createAccountLabel.topAnchor.constraint(equalTo: heyloTitleLabel.bottomAnchor, constant: 10),
            createAccountLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            createAccountLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            // Profile Image Button
            profileImageButton.topAnchor.constraint(equalTo: createAccountLabel.bottomAnchor, constant: 30),
            profileImageButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            profileImageButton.widthAnchor.constraint(equalToConstant: 150),
            profileImageButton.heightAnchor.constraint(equalToConstant: 150),

            // Camera Icon
            cameraIconView.trailingAnchor.constraint(equalTo: profileImageButton.trailingAnchor, constant: 5),
            cameraIconView.bottomAnchor.constraint(equalTo: profileImageButton.bottomAnchor, constant: 5),
            cameraIconView.widthAnchor.constraint(equalToConstant: 36),
            cameraIconView.heightAnchor.constraint(equalToConstant: 36),

            // Display Name TextField
            displayNameTextField.topAnchor.constraint(equalTo: profileImageButton.bottomAnchor, constant: 30),
            displayNameTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            displayNameTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            displayNameTextField.heightAnchor.constraint(equalToConstant: 50),

            // Email TextField
            emailTextField.topAnchor.constraint(equalTo: displayNameTextField.bottomAnchor, constant: 20),
            emailTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            emailTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            emailTextField.heightAnchor.constraint(equalToConstant: 50),

            // Password TextField
            passwordTextField.topAnchor.constraint(equalTo: emailTextField.bottomAnchor, constant: 20),
            passwordTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            passwordTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            passwordTextField.heightAnchor.constraint(equalToConstant: 50),

            // Confirm Password TextField
            confirmPasswordTextField.topAnchor.constraint(equalTo: passwordTextField.bottomAnchor, constant: 20),
            confirmPasswordTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            confirmPasswordTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            confirmPasswordTextField.heightAnchor.constraint(equalToConstant: 50),

            // Sign Up Button
            signUpButton.topAnchor.constraint(equalTo: confirmPasswordTextField.bottomAnchor, constant: 40),
            signUpButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            signUpButton.widthAnchor.constraint(equalToConstant: 200),

            // Activity Indicator
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }



    // MARK: - Actions
    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func profileImageButtonTapped() {
        // Check camera permission
        checkCameraPermission()
    }

    // Flag to prevent multiple rapid taps
    private var isSigningUp = false

    @objc private func signUpButtonTapped() {
        // Prevent multiple rapid taps
        guard !isSigningUp else { return }
        isSigningUp = true

        // Add a slight delay to ensure UI updates properly
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.performSignUp()
        }
    }

    private func performSignUp() {
        // Validate inputs
        guard let displayName = displayNameTextField.text, !displayName.isEmpty else {
            showAlert(title: "Error", message: "Please enter a display name")
            return
        }

        guard let email = emailTextField.text, !email.isEmpty else {
            showAlert(title: "Error", message: "Please enter an email")
            return
        }

        guard let password = passwordTextField.text, !password.isEmpty else {
            showAlert(title: "Error", message: "Please enter a password")
            return
        }

        guard let confirmPassword = confirmPasswordTextField.text, !confirmPassword.isEmpty else {
            showAlert(title: "Error", message: "Please confirm your password")
            return
        }

        guard password == confirmPassword else {
            showAlert(title: "Error", message: "Passwords do not match")
            return
        }

        // Show loading indicator
        activityIndicator.startAnimating()
        signUpButton.isEnabled = false

        // Attempt to sign up using the secure backend function
        AuthService.shared.signUp(email: email, password: password, displayName: displayName, profileImage: profileImage) { [weak self] result in
            guard let self = self else { return }

            // Hide loading indicator
            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()
                self.signUpButton.isEnabled = true
                self.isSigningUp = false

                switch result {
                case .success:
                    // Show email verification screen
                    self.showPendingEmailVerificationVC()

                case .failure(let error):
                    // Check if it's a rate limiting error
                    if error.localizedDescription.contains("Too many sign-up attempts") {
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
                        self.showAlert(title: "Sign Up Failed", message: error.localizedDescription)
                        #endif
                    } else {
                        // For other errors, show the standard error message
                        self.showAlert(title: "Sign Up Failed", message: error.localizedDescription)
                    }
                }
            }
        }
    }



    // MARK: - Camera Handling
    private func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            presentCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted {
                    DispatchQueue.main.async {
                        self?.presentCamera()
                    }
                }
            }
        case .denied, .restricted:
            showAlert(title: "Camera Access", message: "Please allow camera access in Settings to take a profile picture")
        @unknown default:
            break
        }
    }

    private func presentCamera() {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .camera
        imagePicker.allowsEditing = true
        imagePicker.delegate = self
        present(imagePicker, animated: true)
    }

    // MARK: - Navigation
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
        signUpButton.isEnabled = false

        AuthService.shared.resetRateLimiters { [weak self] result in
            guard let self = self else { return }

            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()
                self.signUpButton.isEnabled = true

                switch result {
                case .success:
                    self.showAlert(title: "Rate Limiters Reset", message: "Rate limiters have been reset. You can now try signing up again.")
                case .failure(let error):
                    self.showAlert(title: "Reset Failed", message: "Failed to reset rate limiters: \(error.localizedDescription)")
                }
            }
        }
    }
    #endif
}

// MARK: - UITextFieldDelegate
extension SignUpVC: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case displayNameTextField:
            emailTextField.becomeFirstResponder()
        case emailTextField:
            passwordTextField.becomeFirstResponder()
        case passwordTextField:
            confirmPasswordTextField.becomeFirstResponder()
        case confirmPasswordTextField:
            textField.resignFirstResponder()
            signUpButtonTapped()
        default:
            textField.resignFirstResponder()
        }
        return true
    }
}

// MARK: - UIImagePickerControllerDelegate
extension SignUpVC: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[.editedImage] as? UIImage {
            profileImage = image
            profileImageButton.setImage(image, for: .normal)
            profileImageButton.layer.borderWidth = 2
            profileImageButton.layer.borderColor = UIColor.white.cgColor
        }

        picker.dismiss(animated: true)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}
