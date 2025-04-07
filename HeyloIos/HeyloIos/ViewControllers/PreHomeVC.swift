import UIKit
import FirebaseAuth

class PreHomeVC: UIViewController {

    // MARK: - Properties
    private var authStateDidChangeListener: AuthStateDidChangeListenerHandle?
    private var emailVerificationTimer: Timer?
    private var checkCount = 0
    private let maxCheckCount = 10 // Maximum number of checks before giving up

    // MARK: - UI Elements
    private let heyloTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Heylo"
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 48, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let loadingAnimationView: LoadingAnimationView = {
        let view = LoadingAnimationView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let statusLabel: UILabel = {
        let label = UILabel()
        label.text = "Loading..."
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 18)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupConstraints()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startLoading()
        addAuthStateListener()
        startEmailVerificationCheck()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopLoading()
        removeAuthStateListener()
        stopEmailVerificationCheck()
    }

    // MARK: - Setup
    private func setupView() {
        view.backgroundColor = .black

        // Add subviews
        view.addSubview(heyloTitleLabel)
        view.addSubview(loadingAnimationView)
        view.addSubview(statusLabel)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Heylo Title
            heyloTitleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            heyloTitleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            heyloTitleLabel.widthAnchor.constraint(equalToConstant: 200),
            heyloTitleLabel.heightAnchor.constraint(equalToConstant: 60),

            // Loading Animation View
            loadingAnimationView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingAnimationView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            loadingAnimationView.widthAnchor.constraint(equalToConstant: 150),
            loadingAnimationView.heightAnchor.constraint(equalToConstant: 150),

            // Status Label
            statusLabel.topAnchor.constraint(equalTo: loadingAnimationView.bottomAnchor, constant: 20),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }

    // MARK: - Loading
    private func startLoading() {
        loadingAnimationView.startAnimating()
    }

    private func stopLoading() {
        loadingAnimationView.stopAnimating()
    }

    // MARK: - Auth State
    private func addAuthStateListener() {
        authStateDidChangeListener = Auth.auth().addStateDidChangeListener { [weak self] (auth, user) in
            guard let self = self else { return }

            if let user = user {
                // User is signed in
                if user.isEmailVerified {
                    // Email is verified, proceed to home screen
                    self.proceedToHomeScreen()
                } else {
                    // Email is not verified, start checking
                    self.statusLabel.text = "Waiting for email verification..."
                }
            } else {
                // No user is signed in, go back to sign in screen
                self.dismissToSignIn()
            }
        }
    }

    private func removeAuthStateListener() {
        if let listener = authStateDidChangeListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
    }

    // MARK: - Email Verification Check
    private func startEmailVerificationCheck() {
        // Stop any existing timer
        stopEmailVerificationCheck()

        // Reset check count
        checkCount = 0

        // Start a new timer to check email verification status
        emailVerificationTimer = Timer.scheduledTimer(timeInterval: 3.0, target: self, selector: #selector(checkEmailVerification), userInfo: nil, repeats: true)
    }

    private func stopEmailVerificationCheck() {
        emailVerificationTimer?.invalidate()
        emailVerificationTimer = nil
    }

    @objc private func checkEmailVerification() {
        guard let user = Auth.auth().currentUser else {
            stopEmailVerificationCheck()
            return
        }

        // Increment check count
        checkCount += 1

        // Update status label with check count
        statusLabel.text = "Checking email verification... (\(checkCount)/\(maxCheckCount))"

        // First, reload the user to get the latest status
        user.reload { [weak self] error in
            guard let self = self else { return }

            if let error = error {
                print("Error reloading user: \(error.localizedDescription)")
            }

            // Check if email is already verified locally
            if user.isEmailVerified {
                // Email is verified, proceed to home screen
                self.stopEmailVerificationCheck()
                self.proceedToHomeScreen()
                return
            }

            // If not verified locally, check with the backend
            AuthService.shared.checkEmailVerification { [weak self] result in
                guard let self = self else { return }

                switch result {
                case .success(let isVerified):
                    if isVerified {
                        // Email is verified, proceed to home screen
                        self.stopEmailVerificationCheck()
                        self.proceedToHomeScreen()
                    } else if self.checkCount >= self.maxCheckCount {
                        // Max check count reached, stop checking
                        self.stopEmailVerificationCheck()
                        self.showEmailVerificationTimeout()
                    }

                case .failure(let error):
                    print("Error checking email verification: \(error.localizedDescription)")
                    if self.checkCount >= self.maxCheckCount {
                        // Max check count reached, stop checking
                        self.stopEmailVerificationCheck()
                        self.showEmailVerificationTimeout()
                    }
                }
            }
        }
    }

    // MARK: - Navigation
    private func proceedToHomeScreen() {
        DispatchQueue.main.async {
            self.statusLabel.text = "Email verified! Proceeding to home screen..."

            // Delay to show the success message
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                let homeVC = HomeVC()
                homeVC.modalPresentationStyle = .fullScreen

                // Replace the current view controller with HomeVC
                if let sceneDelegate = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate,
                   let window = sceneDelegate.window {

                    // Create a new navigation controller with HomeVC as root
                    let navController = UINavigationController(rootViewController: homeVC)
                    navController.isNavigationBarHidden = true

                    // Set as root view controller
                    window.rootViewController = navController
                    window.makeKeyAndVisible()

                    // Add a smooth transition
                    UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: nil, completion: nil)
                } else {
                    // Fallback if we can't access the window
                    self.present(homeVC, animated: true)
                }
            }
        }
    }

    private func dismissToSignIn() {
        DispatchQueue.main.async {
            self.dismiss(animated: true)
        }
    }

    private func showEmailVerificationTimeout() {
        DispatchQueue.main.async {
            self.statusLabel.text = "Email verification timeout. Please try again later."

            // Show alert
            let alert = UIAlertController(
                title: "Verification Timeout",
                message: "We couldn't verify your email. Please check your inbox and try again later.",
                preferredStyle: .alert
            )

            alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
                self?.dismissToSignIn()
            })

            self.present(alert, animated: true)
        }
    }
}
