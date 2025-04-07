import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import FirebaseFunctions
import UIKit

class AuthService {

    static let shared = AuthService()

    private init() {}

    // MARK: - Sign In
    func signIn(email: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        // Call the secure backend function with retry mechanism
        signInWithRetry(email: email, password: password, retryCount: 0, maxRetries: 2, completion: completion)
    }

    private func signInWithRetry(email: String, password: String, retryCount: Int, maxRetries: Int, completion: @escaping (Result<User, Error>) -> Void) {
        // First, call the secure backend function
        let functions = Functions.functions()

        // No custom options available in this version of Firebase

        let data: [String: Any] = [
            "email": email,
            "password": password
        ]

        functions.httpsCallable("secureSignIn").call(data) { [weak self] result, error in
            guard let self = self else { return }

            // Check for network errors that might benefit from a retry
            if let error = error {
                let nsError = error as NSError
                let isNetworkError = nsError.domain == NSURLErrorDomain ||
                                    error.localizedDescription.contains("network") ||
                                    error.localizedDescription.contains("timeout")

                if isNetworkError && retryCount < maxRetries {
                    // Wait a bit before retrying (exponential backoff)
                    let delay = TimeInterval(pow(2.0, Double(retryCount))) // 1s, 2s, 4s, etc.
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                        self.signInWithRetry(email: email, password: password,
                                            retryCount: retryCount + 1,
                                            maxRetries: maxRetries, completion: completion)
                    }
                    return
                }

                completion(.failure(error))
                return
            }

            guard let resultData = result?.data as? [String: Any],
                  let success = resultData["success"] as? Bool,
                  success == true else {

                let errorMessage = (result?.data as? [String: Any])?["error"] as? String ?? "Unknown error"
                completion(.failure(NSError(domain: "AuthService", code: 0, userInfo: [NSLocalizedDescriptionKey: errorMessage])))
                return
            }

            // Sign in directly with email and password
            Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }

                guard let user = authResult?.user else {
                    completion(.failure(NSError(domain: "AuthService", code: 0, userInfo: [NSLocalizedDescriptionKey: "User not found"])))
                    return
                }

                // Check if the backend wants us to send a verification email
                if let verificationInstruction = resultData["emailVerificationLink"] as? String,
                   verificationInstruction == "CLIENT_SEND_VERIFICATION" {

                    // Send verification email directly from the client
                    user.sendEmailVerification { verificationError in
                        if let verificationError = verificationError {
                            print("Error sending verification email: \(verificationError.localizedDescription)")
                            // Continue anyway, don't fail the sign-in
                        } else {
                            print("Verification email sent successfully")
                        }

                        // Complete the sign-in process
                        completion(.success(user))
                    }
                } else {
                    // No verification email needed, complete the sign-in
                    completion(.success(user))
                }
            }
        }
    }

    // MARK: - Sign Up
    func signUp(email: String, password: String, displayName: String, profileImage: UIImage?, completion: @escaping (Result<User, Error>) -> Void) {
        // Call the secure backend function with retry mechanism
        signUpWithRetry(email: email, password: password, displayName: displayName, profileImage: profileImage, retryCount: 0, maxRetries: 2, completion: completion)
    }

    private func signUpWithRetry(email: String, password: String, displayName: String, profileImage: UIImage?, retryCount: Int, maxRetries: Int, completion: @escaping (Result<User, Error>) -> Void) {
        // Call the secure backend function
        let functions = Functions.functions()

        // No custom options available in this version of Firebase

        var data: [String: Any] = [
            "email": email,
            "password": password,
            "displayName": displayName
        ]

        // If profile image is provided, convert it to base64
        if let profileImage = profileImage,
           let imageData = profileImage.jpegData(compressionQuality: 0.7) {
            let base64String = imageData.base64EncodedString()
            data["profileImageBase64"] = "data:image/jpeg;base64," + base64String
        }

        functions.httpsCallable("secureSignUp").call(data) { [weak self] result, error in
            guard let self = self else { return }

            // Check for network errors that might benefit from a retry
            if let error = error {
                let nsError = error as NSError
                let isNetworkError = nsError.domain == NSURLErrorDomain ||
                                    error.localizedDescription.contains("network") ||
                                    error.localizedDescription.contains("timeout")

                if isNetworkError && retryCount < maxRetries {
                    // Wait a bit before retrying (exponential backoff)
                    let delay = TimeInterval(pow(2.0, Double(retryCount))) // 1s, 2s, 4s, etc.
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                        self.signUpWithRetry(email: email, password: password, displayName: displayName,
                                             profileImage: profileImage, retryCount: retryCount + 1,
                                             maxRetries: maxRetries, completion: completion)
                    }
                    return
                }

                completion(.failure(error))
                return
            }

            guard let resultData = result?.data as? [String: Any],
                  let success = resultData["success"] as? Bool,
                  success == true,
                  let userId = resultData["userId"] as? String else {

                let errorMessage = (result?.data as? [String: Any])?["error"] as? String ?? "Unknown error"
                completion(.failure(NSError(domain: "AuthService", code: 0, userInfo: [NSLocalizedDescriptionKey: errorMessage])))
                return
            }

            // Get the email verification link
            let emailVerificationLink = (resultData["emailVerificationLink"] as? String) ?? ""

            // Sign in with email and password to get the user object
            Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
                guard let self = self else { return }

                if let error = error {
                    completion(.failure(error))
                    return
                }

                guard let user = authResult?.user else {
                    completion(.failure(NSError(domain: "AuthService", code: 0, userInfo: [NSLocalizedDescriptionKey: "User not found"])))
                    return
                }

                // Check if the backend wants us to send a verification email
                if emailVerificationLink == "CLIENT_SEND_VERIFICATION" {
                    // Send verification email directly from the client
                    user.sendEmailVerification { verificationError in
                        if let verificationError = verificationError {
                            print("Error sending verification email: \(verificationError.localizedDescription)")
                            // Continue anyway, don't fail the sign-up
                        } else {
                            print("Verification email sent successfully")
                        }

                        // Complete the sign-up process
                        completion(.success(user))
                    }
                } else if !emailVerificationLink.isEmpty {
                    // In a real app, you would send this link to the user's email
                    // For now, we'll just print it to the console
                    print("Email verification link: \(emailVerificationLink)")
                    completion(.success(user))
                } else {
                    // No verification email needed, complete the sign-up
                    completion(.success(user))
                }
            }
        }
    }

    // MARK: - Sign Out
    func signOut(completion: @escaping (Error?) -> Void) {
        // First sign out locally to ensure the user is signed out even if the backend call fails
        do {
            try Auth.auth().signOut()

            // Then call the backend function (but don't wait for it)
            let functions = Functions.functions()
            functions.httpsCallable("secureSignOut").call() { _, _ in
                // Ignore any errors from the backend
            }

            // Complete successfully
            completion(nil)
        } catch let signOutError {
            completion(signOutError)
        }
    }

    // MARK: - Email Verification
    func sendEmailVerification(completion: @escaping (Result<String, Error>) -> Void) {
        // First check if we have a current user
        guard let user = Auth.auth().currentUser else {
            completion(.failure(NSError(domain: "AuthService", code: 0, userInfo: [NSLocalizedDescriptionKey: "No user is signed in"])))
            return
        }

        // Call the secure backend function first to prepare
        let functions = Functions.functions()

        functions.httpsCallable("resendEmailVerification").call() { [weak self] result, error in
            guard let self = self else { return }

            // Check for backend errors
            if let error = error {
                // If backend fails, try to send directly from client
                self.sendVerificationEmailDirectly(user: user, completion: completion)
                return
            }

            guard let resultData = result?.data as? [String: Any],
                  let success = resultData["success"] as? Bool,
                  success == true else {

                let errorMessage = (result?.data as? [String: Any])?["error"] as? String ?? "Unknown error"
                completion(.failure(NSError(domain: "AuthService", code: 0, userInfo: [NSLocalizedDescriptionKey: errorMessage])))
                return
            }

            // Check if the backend wants us to send the verification email
            if let verificationInstruction = resultData["emailVerificationLink"] as? String,
               verificationInstruction == "CLIENT_SEND_VERIFICATION" {

                // Send verification email directly from the client
                self.sendVerificationEmailDirectly(user: user, completion: completion)
            } else {
                // Get the email verification link from the backend
                let emailVerificationLink = (resultData["emailVerificationLink"] as? String) ?? ""
                completion(.success(emailVerificationLink))
            }
        }
    }

    private func sendVerificationEmailDirectly(user: User, completion: @escaping (Result<String, Error>) -> Void) {
        user.sendEmailVerification { error in
            if let error = error {
                completion(.failure(error))
            } else {
                print("Verification email sent directly from client")
                completion(.success("Verification email sent. Please check your inbox."))
            }
        }
    }

    // MARK: - Check Email Verification
    func checkEmailVerification(completion: @escaping (Result<Bool, Error>) -> Void) {
        // Call the secure backend function
        let functions = Functions.functions()

        functions.httpsCallable("checkEmailVerification").call() { result, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let resultData = result?.data as? [String: Any],
                  let success = resultData["success"] as? Bool,
                  success == true,
                  let emailVerified = resultData["emailVerified"] as? Bool else {

                let errorMessage = (result?.data as? [String: Any])?["error"] as? String ?? "Unknown error"
                completion(.failure(NSError(domain: "AuthService", code: 0, userInfo: [NSLocalizedDescriptionKey: errorMessage])))
                return
            }

            completion(.success(emailVerified))
        }
    }

    // This is a synchronous check that uses the local cache
    // For a more accurate check, use the checkEmailVerification method
    func isEmailVerified() -> Bool {
        return Auth.auth().currentUser?.isEmailVerified ?? false
    }

    // MARK: - Current User
    func getCurrentUser() -> User? {
        return Auth.auth().currentUser
    }

    // MARK: - Helper Methods
    // These methods have been replaced by secure backend functions

    // MARK: - Development Helpers
    #if DEBUG
    func resetRateLimiters(completion: @escaping (Result<Void, Error>) -> Void) {
        // Use the HTTP endpoint instead of the callable function
        resetRateLimitersWithRetry(retryCount: 0, maxRetries: 2, completion: completion)
    }

    private func resetRateLimitersWithRetry(retryCount: Int, maxRetries: Int, completion: @escaping (Result<Void, Error>) -> Void) {
        let urlString = "https://devresetratelimitershttp-6yxxa6khrq-uc.a.run.app"
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "AuthService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 30 // 30 seconds timeout

        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }

            // Check for network errors that might benefit from a retry
            if let error = error {
                let nsError = error as NSError
                let isNetworkError = nsError.domain == NSURLErrorDomain ||
                                    error.localizedDescription.contains("network") ||
                                    error.localizedDescription.contains("timeout")

                if isNetworkError && retryCount < maxRetries {
                    // Wait a bit before retrying (exponential backoff)
                    let delay = TimeInterval(pow(2.0, Double(retryCount))) // 1s, 2s, 4s, etc.
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                        self.resetRateLimitersWithRetry(retryCount: retryCount + 1,
                                                      maxRetries: maxRetries,
                                                      completion: completion)
                    }
                    return
                }

                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(NSError(domain: "AuthService", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let success = json["success"] as? Bool {
                    if success {
                        completion(.success(()))
                    } else {
                        let errorMessage = json["error"] as? String ?? "Unknown error"
                        completion(.failure(NSError(domain: "AuthService", code: 0, userInfo: [NSLocalizedDescriptionKey: errorMessage])))
                    }
                } else {
                    completion(.failure(NSError(domain: "AuthService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response format"])))
                }
            } catch {
                completion(.failure(error))
            }
        }

        task.resume()
    }
    #endif
}
