import Foundation
import CoreLocation
import FirebaseAuth
import FirebaseFirestore
import FirebaseFunctions
import FirebaseDatabase

class NearbyUsersService {

    // MARK: - Singleton
    static let shared = NearbyUsersService()

    // MARK: - Properties
    private let db = Firestore.firestore()
    private let rtdb = Database.database()
    private var nearbyUsersListener: ListenerRegistration?

    // Configuration
    private let defaultRadius: Double = 1.0 // 1 kilometer
    private let maxResults: Int = 50

    // MARK: - Initialization
    private init() {}

    // MARK: - Public Methods

    /// Get nearby users within a specified radius using the two-step process:
    /// 1. Query Realtime Database for nearby user IDs based on location
    /// 2. Fetch complete user profiles from Firestore using those IDs
    ///
    /// - Parameters:
    ///   - location: The center location to search from
    ///   - radiusKm: The radius in kilometers (default: 1km)
    ///   - completion: Callback with the result containing nearby users or an error
    func getNearbyUsers(location: CLLocation, radiusKm: Double = 1.0, completion: @escaping (Result<[NearbyUser], Error>) -> Void) {
        guard let currentUser = Auth.auth().currentUser else {
            completion(.failure(NSError(domain: "NearbyUsersService", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])))
            return
        }

        // Use the clean two-step approach with the Firebase Function
        let locationData: [String: Any] = [
            "latitude": location.coordinate.latitude,
            "longitude": location.coordinate.longitude,
            "radiusKm": radiusKm
        ]

        // Call the Firebase Function that implements the two-step process
        let functions = Functions.functions()

        // Force a token refresh to ensure we have a valid token
        currentUser.getIDTokenForcingRefresh(true) { token, error in
            if let error = error {
                print("❌ Error refreshing token: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }

            guard let token = token else {
                print("❌ Failed to get token")
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "NearbyUsersService", code: 401, userInfo: [NSLocalizedDescriptionKey: "Failed to get authentication token"])))
                }
                return
            }

            print("✅ Token refreshed successfully: \(token.prefix(10))...\(token.suffix(10)), calling getNearbyUsers function")

            // Add the token and user ID to the request data
            var enhancedLocationData = locationData
            enhancedLocationData["debug_token_prefix"] = String(token.prefix(10))
            enhancedLocationData["debug_token_suffix"] = String(token.suffix(10))
            enhancedLocationData["userId"] = currentUser.uid

            // Add userId at both levels to ensure it's found
            var wrappedData: [String: Any] = [
                "userId": currentUser.uid,
                "latitude": locationData["lat"] as? Double ?? 0.0,
                "longitude": locationData["lng"] as? Double ?? 0.0,
                "radiusKm": radiusKm
            ]

            // Also include the original data
            for (key, value) in enhancedLocationData {
                wrappedData[key] = value
            }

            print("📍 Including userId in request: \(currentUser.uid)")

            // We don't need custom options, just make sure userId is included in the data
            // This matches how updateUserLocationRTDB is called in LocationService
            functions.httpsCallable("getNearbyUsers").call(wrappedData) { result, error in
            // Ensure completion is called on the main thread
            DispatchQueue.main.async {
                if let error = error {
                    print("Error fetching nearby users: \(error.localizedDescription)")

                    // Check if it's a Firebase Functions error and log details
                    if let functionsError = error as NSError? {
                        print("❌ Firebase Functions error code: \(functionsError.code)")
                        print("❌ Firebase Functions error domain: \(functionsError.domain)")
                        if let details = functionsError.userInfo["details"] as? String {
                            print("❌ Error details: \(details)")
                        }
                    }

                    completion(.failure(error))
                    return
                }

                guard let data = result?.data as? [String: Any],
                      let success = data["success"] as? Bool, success,
                      let usersData = data["users"] as? [[String: Any]] else {
                    let errorMessage = (result?.data as? [String: Any])?["error"] as? String ?? "Unknown error"
                    print("Error parsing nearby users response: \(errorMessage)")
                    completion(.failure(NSError(domain: "NearbyUsersService", code: 500, userInfo: [NSLocalizedDescriptionKey: errorMessage])))
                    return
                }

                // Parse the users data
                var nearbyUsers: [NearbyUser] = []

                for userData in usersData {
                    if let userId = userData["userId"] as? String,
                       userId != currentUser.uid { // Skip the current user

                        // Get display name with fallback
                        let displayName = userData["displayName"] as? String ?? "Unknown User"

                        // Get profile image URL with fallback (support both field names)
                        let profileImageUrl = userData["profileImageUrl"] as? String ?? userData["photoURL"] as? String ?? ""

                        // Create a date from timestamp if available, or use current date
                        let lastUpdated: Date
                        if let timestamp = userData["lastUpdated"] as? TimeInterval {
                            // Handle Unix timestamp (seconds since epoch)
                            lastUpdated = Date(timeIntervalSince1970: timestamp)
                        } else if let timestamp = userData["lastUpdated"] as? Double {
                            // Handle Double timestamp
                            lastUpdated = Date(timeIntervalSince1970: timestamp)
                        } else if let timestampObj = userData["lastUpdated"] as? [String: Any],
                                  let seconds = timestampObj["_seconds"] as? Int {
                            // Handle Firestore timestamp object format
                            lastUpdated = Date(timeIntervalSince1970: TimeInterval(seconds))
                        } else {
                            // Default to current time if no valid timestamp
                            print("⚠️ Warning: Using current time as fallback for user \(userId)")
                            lastUpdated = Date()
                        }

                        let moodTemperature = userData["moodTemperature"] as? String ?? "Neutral"

                        let user = NearbyUser(
                            id: userId,
                            userId: userId,
                            displayName: displayName,
                            profileImageUrl: profileImageUrl,
                            moodTemperature: moodTemperature,
                            lastUpdated: lastUpdated
                        )

                        nearbyUsers.append(user)
                    }
                }

                // Sort by lastUpdated (most recent first)
                nearbyUsers.sort { $0.lastUpdated > $1.lastUpdated }

                // Limit the number of results
                if nearbyUsers.count > self.maxResults {
                    nearbyUsers = Array(nearbyUsers.prefix(self.maxResults))
                }

                completion(.success(nearbyUsers))
            }
        }
        }
    }

    /// Start listening for nearby users in real-time using a polling approach
    /// This is a temporary implementation until we implement real-time listeners with the two-step process
    ///
    /// - Parameters:
    ///   - location: The center location to search from
    ///   - radiusKm: The radius in kilometers (default: 1km)
    ///   - listener: Callback that will be called whenever the nearby users list changes
    func startListeningForNearbyUsers(location: CLLocation, radiusKm: Double = 1.0, listener: @escaping ([NearbyUser]) -> Void) {
        // Stop any existing listener
        stopListeningForNearbyUsers()

        // For now, we'll just do a one-time fetch
        // In a real implementation, we would set up a timer to periodically refresh
        // or implement a proper real-time listener using Firebase Realtime Database
        getNearbyUsers(location: location, radiusKm: radiusKm) { result in
            switch result {
            case .success(let users):
                listener(users)
            case .failure(let error):
                print("Error fetching nearby users: \(error.localizedDescription)")
                listener([])
            }
        }
    }

    /// Stop listening for nearby users
    func stopListeningForNearbyUsers() {
        nearbyUsersListener?.remove()
        nearbyUsersListener = nil
    }

    // MARK: - Private Methods

    /// Calculate the distance between two locations
    private func calculateDistance(from: CLLocation, to: CLLocation) -> Double {
        return from.distance(from: to) / 1000.0 // Convert meters to kilometers
    }
}

// MARK: - Models

/// Represents a nearby user
struct NearbyUser: Identifiable {
    let id: String
    let userId: String
    let displayName: String
    let profileImageUrl: String
    let moodTemperature: String
    let lastUpdated: Date
    var hasLiked: Bool = false

    var formattedLastActive: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: lastUpdated, relativeTo: Date())
    }

    // Initialize from Firestore document with robust error handling
    init?(document: QueryDocumentSnapshot) {
        let data = document.data()

        // Extract required fields with fallbacks
        guard let userId = data["userId"] as? String else {
            return nil // User ID is required
        }

        let displayName = data["displayName"] as? String ?? "Unknown User"
        let profileImageUrl = data["profileImageUrl"] as? String ?? ""
        let moodTemperature = data["moodTemperature"] as? String ?? "Neutral"

        // Handle various timestamp formats
        let lastUpdated: Date
        if let timestamp = data["lastUpdated"] as? Timestamp {
            lastUpdated = timestamp.dateValue()
        } else if let timestamp = data["lastUpdated"] as? TimeInterval {
            lastUpdated = Date(timeIntervalSince1970: timestamp)
        } else if let timestamp = data["lastUpdated"] as? Double {
            lastUpdated = Date(timeIntervalSince1970: timestamp)
        } else if let timestampObj = data["lastUpdated"] as? [String: Any],
                  let seconds = timestampObj["_seconds"] as? Int {
            lastUpdated = Date(timeIntervalSince1970: TimeInterval(seconds))
        } else {
            lastUpdated = Date() // Default to current time
        }

        self.id = document.documentID
        self.userId = userId
        self.displayName = displayName
        self.profileImageUrl = profileImageUrl
        self.moodTemperature = moodTemperature
        self.lastUpdated = lastUpdated
        self.hasLiked = data["hasLiked"] as? Bool ?? false
    }

    // Initialize from dictionary with robust error handling
    init?(dictionary: [String: Any], id: String) {
        // Extract required fields with fallbacks
        guard let userId = dictionary["userId"] as? String else {
            return nil // User ID is required
        }

        let displayName = dictionary["displayName"] as? String ?? "Unknown User"
        let profileImageUrl = dictionary["profileImageUrl"] as? String ?? ""
        let moodTemperature = dictionary["moodTemperature"] as? String ?? "Neutral"

        // Handle various timestamp formats
        let lastUpdated: Date
        if let timestamp = dictionary["lastUpdated"] as? Timestamp {
            lastUpdated = timestamp.dateValue()
        } else if let timestamp = dictionary["lastUpdated"] as? TimeInterval {
            lastUpdated = Date(timeIntervalSince1970: timestamp)
        } else if let timestamp = dictionary["lastUpdated"] as? Double {
            lastUpdated = Date(timeIntervalSince1970: timestamp)
        } else if let timestampObj = dictionary["lastUpdated"] as? [String: Any],
                  let seconds = timestampObj["_seconds"] as? Int {
            lastUpdated = Date(timeIntervalSince1970: TimeInterval(seconds))
        } else {
            lastUpdated = Date() // Default to current time
        }

        self.id = id
        self.userId = userId
        self.displayName = displayName
        self.profileImageUrl = profileImageUrl
        self.moodTemperature = moodTemperature
        self.lastUpdated = lastUpdated
        self.hasLiked = dictionary["hasLiked"] as? Bool ?? false
    }

    // Basic initializer for testing or manual creation
    init(id: String, userId: String, displayName: String, profileImageUrl: String, moodTemperature: String, lastUpdated: Date, hasLiked: Bool = false) {
        self.id = id
        self.userId = userId
        self.displayName = displayName
        self.profileImageUrl = profileImageUrl
        self.moodTemperature = moodTemperature
        self.lastUpdated = lastUpdated
        self.hasLiked = hasLiked
    }
}
