import UIKit
import FirebaseAuth

class HomeVC: UIViewController {

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

    private let welcomeLabel: UILabel = {
        let label = UILabel()
        label.text = "Welcome!"
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let userInfoLabel: UILabel = {
        let label = UILabel()
        label.textColor = .lightGray
        label.font = UIFont.systemFont(ofSize: 16)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 50
        imageView.layer.masksToBounds = true
        imageView.backgroundColor = .darkGray
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private lazy var signOutButton: HeyloButton = {
        let button = HeyloButton(style: .secondary, title: "Sign Out")
        button.addTarget(self, action: #selector(signOutButtonTapped), for: .touchUpInside)
        return button
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupConstraints()
        updateUserInfo()
    }

    // MARK: - Setup
    private func setupView() {
        view.backgroundColor = .black

        // Add subviews
        view.addSubview(heyloTitleLabel)
        view.addSubview(welcomeLabel)
        view.addSubview(profileImageView)
        view.addSubview(userInfoLabel)
        view.addSubview(signOutButton)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Heylo Title
            heyloTitleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            heyloTitleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            heyloTitleLabel.widthAnchor.constraint(equalToConstant: 200),
            heyloTitleLabel.heightAnchor.constraint(equalToConstant: 60),

            // Welcome Label
            welcomeLabel.topAnchor.constraint(equalTo: heyloTitleLabel.bottomAnchor, constant: 20),
            welcomeLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            welcomeLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            // Profile Image View
            profileImageView.topAnchor.constraint(equalTo: welcomeLabel.bottomAnchor, constant: 40),
            profileImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 100),
            profileImageView.heightAnchor.constraint(equalToConstant: 100),

            // User Info Label
            userInfoLabel.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 20),
            userInfoLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            userInfoLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            // Sign Out Button
            signOutButton.topAnchor.constraint(equalTo: userInfoLabel.bottomAnchor, constant: 40),
            signOutButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }

    private func updateUserInfo() {
        guard let user = Auth.auth().currentUser else {
            return
        }

        // Update user info label
        let displayName = user.displayName ?? "User"
        let email = user.email ?? "No email"
        userInfoLabel.text = "Logged in as: \(displayName)\nEmail: \(email)"

        // Load profile image if available
        if let photoURL = user.photoURL {
            loadProfileImage(from: photoURL)
        } else {
            // Set default profile image
            profileImageView.image = UIImage(systemName: "person.circle.fill")
            profileImageView.tintColor = .white
        }
    }

    private func loadProfileImage(from url: URL) {
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self,
                  let data = data,
                  error == nil,
                  let image = UIImage(data: data) else {
                return
            }

            DispatchQueue.main.async {
                self.profileImageView.image = image
            }
        }.resume()
    }

    // MARK: - Actions
    @objc private func signOutButtonTapped() {
        // Show confirmation alert
        let alert = UIAlertController(title: "Sign Out", message: "Are you sure you want to sign out?", preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Sign Out", style: .destructive) { [weak self] _ in
            self?.signOut()
        })

        present(alert, animated: true)
    }

    private func signOut() {
        // Show loading indicator if needed

        // Sign out using the secure backend function
        AuthService.shared.signOut { [weak self] error in
            guard let self = self else { return }

            if let error = error {
                self.showAlert(title: "Error", message: "Failed to sign out: \(error.localizedDescription)")
            } else {
                // Present the SignInVC
                DispatchQueue.main.async {
                    // Create a new SignInVC
                    let signInVC = SignInVC()
                    signInVC.modalPresentationStyle = .fullScreen

                    // Replace the current view controller with SignInVC
                    if let sceneDelegate = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate,
                       let window = sceneDelegate.window {

                        // Set as root view controller
                        window.rootViewController = signInVC
                        window.makeKeyAndVisible()

                        // Add a smooth transition
                        UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: nil, completion: nil)
                    } else {
                        // Fallback if we can't access the window
                        self.present(signInVC, animated: true)
                    }
                }
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
