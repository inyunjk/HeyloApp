# FireGeo - Custom Geospatial Solution for Firebase

FireGeo is a custom implementation of geospatial queries for Firebase, designed to be used by both iOS and Android apps. It provides a more maintainable alternative to the GeoFire library, using only Firestore for data storage and following the flat structure specified in the data structure document.

## Features

- Store user locations with geohashes in Firestore
- Query nearby users within a radius
- Support for privacy features (ghost mode, privacy zones)
- Efficient querying using geohash prefixes
- User connection management (blocking)

## Architecture

FireGeo uses a Firestore-only approach with a flat structure:
- Stores user location data in the `locations/{userId}` document
- Maintains a geospatial index in the `geo_index/{geohashPrefix}/users/{userId}` collection for efficient queries
- Tracks user privacy settings in `users_private/{userId}`
- Uses Firebase Functions as a backend to handle all geospatial operations

## Firebase Functions

### updateUserLocation

Updates a user's location with geohash in Firestore, following the flat structure specified in the data structure document.

**Parameters:**
- `latitude`: Latitude in decimal degrees (-90 to 90)
- `longitude`: Longitude in decimal degrees (-180 to 180)
- `accuracy`: Accuracy of the location in meters
- `altitude` (optional): Altitude in meters
- `heading` (optional): Heading in degrees
- `speed` (optional): Speed in meters per second
- `batteryLevel` (optional): Device battery level (0-100)
- `locationMethod` (optional): Method used to determine location ("gps", "network", "wifi")
- `movementState` (optional): User's movement state ("stationary", "walking", "running", "biking", "driving", "flying")

**Example (iOS - Swift):**
```swift
import FirebaseFunctions

func updateUserLocation(latitude: Double, longitude: Double, accuracy: Double) {
    let functions = Functions.functions()

    let data: [String: Any] = [
        "latitude": latitude,
        "longitude": longitude,
        "accuracy": accuracy,
        "movementState": "walking",
        "batteryLevel": 85,
        "locationMethod": "gps"
    ]

    functions.httpsCallable("updateUserLocation").call(data) { result, error in
        if let error = error {
            print("Error updating location: \(error)")
            return
        }

        if let data = result?.data as? [String: Any],
           let success = data["success"] as? Bool, success {
            print("Location updated successfully")

            // Check if user is in a privacy zone
            if let inPrivacyZone = data["inPrivacyZone"] as? Bool, inPrivacyZone {
                print("User is in a privacy zone")
            }
        }
    }
}
```

**Example (Android - Kotlin):**
```kotlin
import com.google.firebase.functions.FirebaseFunctions

fun updateUserLocation(latitude: Double, longitude: Double, accuracy: Float) {
    val functions = FirebaseFunctions.getInstance()

    val data = hashMapOf(
        "latitude" to latitude,
        "longitude" to longitude,
        "accuracy" to accuracy,
        "movementState" to "walking",
        "batteryLevel" to 85,
        "locationMethod" to "gps"
    )

    functions.getHttpsCallable("updateUserLocation")
        .call(data)
        .addOnSuccessListener { result ->
            val data = result.data as Map<String, Any>
            val success = data["success"] as Boolean
            if (success) {
                println("Location updated successfully")

                // Check if user is in a privacy zone
                val inPrivacyZone = data["inPrivacyZone"] as? Boolean ?: false
                if (inPrivacyZone) {
                    println("User is in a privacy zone")
                }
            }
        }
        .addOnFailureListener { exception ->
            println("Error updating location: $exception")
        }
}
```

### queryNearbyUsers

Queries nearby users within a specified radius of a center point.

**Parameters:**
- `latitude`: Center latitude in decimal degrees
- `longitude`: Center longitude in decimal degrees
- `radiusKm`: Radius in kilometers (max 50km)
- `limit` (optional): Maximum number of results to return (default: 50)

**Example (iOS - Swift):**
```swift
import FirebaseFunctions

func queryNearbyUsers(latitude: Double, longitude: Double, radiusKm: Double) {
    let functions = Functions.functions()

    let data: [String: Any] = [
        "latitude": latitude,
        "longitude": longitude,
        "radiusKm": radiusKm,
        "limit": 20
    ]

    functions.httpsCallable("queryNearbyUsers").call(data) { result, error in
        if let error = error {
            print("Error querying nearby users: \(error)")
            return
        }

        if let data = result?.data as? [String: Any],
           let success = data["success"] as? Bool, success,
           let users = data["users"] as? [[String: Any]] {
            print("Found \(users.count) nearby users")

            for user in users {
                let userId = user["userId"] as? String ?? ""
                let displayName = user["displayName"] as? String ?? ""
                let distance = user["distance"] as? Double ?? 0.0

                print("User: \(displayName), Distance: \(distance) km")
            }
        }
    }
}
```

**Example (Android - Kotlin):**
```kotlin
import com.google.firebase.functions.FirebaseFunctions

fun queryNearbyUsers(latitude: Double, longitude: Double, radiusKm: Double) {
    val functions = FirebaseFunctions.getInstance()

    val data = hashMapOf(
        "latitude" to latitude,
        "longitude" to longitude,
        "radiusKm" to radiusKm,
        "limit" to 20
    )

    functions.getHttpsCallable("queryNearbyUsers")
        .call(data)
        .addOnSuccessListener { result ->
            val data = result.data as Map<String, Any>
            val success = data["success"] as Boolean

            if (success) {
                val users = data["users"] as List<Map<String, Any>>
                println("Found ${users.size} nearby users")

                users.forEach { user ->
                    val userId = user["userId"] as String
                    val displayName = user["displayName"] as String
                    val distance = user["distance"] as Double

                    println("User: $displayName, Distance: $distance km")
                }
            }
        }
        .addOnFailureListener { exception ->
            println("Error querying nearby users: $exception")
        }
}
```

### userSignOut

Removes a user from the geo index when they sign out.

**Parameters:**
No additional parameters required - uses the authenticated user's ID.

**Example (iOS - Swift):**
```swift
import FirebaseFunctions

func signOutUser() {
    let functions = Functions.functions()

    functions.httpsCallable("userSignOut").call() { result, error in
        if let error = error {
            print("Error signing out: \(error)")
            return
        }

        // Now sign out from Firebase Auth
        try? Auth.auth().signOut()
    }
}
```

### updatePrivacySettings

Updates a user's privacy settings, including ghost mode and privacy zones.

**Parameters:**
- `ghostMode` (optional): Boolean indicating whether ghost mode is enabled
- `privacyZones` (optional): Array of privacy zone objects, each containing:
  - `zoneId`: Unique identifier for the zone
  - `name`: Display name for the zone
  - `center`: Object with `latitude` and `longitude`
  - `radiusMeters`: Radius of the privacy zone in meters

## Implementation Details

FireGeo uses geohashing to efficiently query nearby users:

1. User locations are stored in the `locations/{userId}` document with their full data
2. Geohash indexes are stored in the `geo_index/{geohashPrefix}/users/{userId}` collection for efficient querying
3. When querying, FireGeo:
   - Uses a fixed geohash precision of 5 for nearby user queries
   - Queries the `geo_index` collection for users with matching geohash prefixes
   - Filters results by calculating the actual distance
   - Retrieves full location data from the `locations` collection for the filtered results
   - Applies privacy filters (ghost mode, blocked users)

### Privacy Features

1. **Ghost Mode**: When enabled, the user is not added to the geo index and cannot be found by other users
2. **Privacy Zones**: Defined areas where a user's location is marked as private
3. **User Blocking**: Users can block others, preventing them from seeing each other

### Optimizations

1. **Denormalization**: Key user data is stored directly in the geo index for faster queries
2. **Backend Geohash Calculation**: All geohash calculations are performed on the backend for consistency
3. **Batch Operations**: Updates to multiple collections are performed in batches for consistency

This Firestore-only approach provides:
- Efficient queries (using the geohash index)
- Rich data storage (using Firestore collections)
- Secure access control (using Firebase Authentication)
- Privacy controls (ghost mode, privacy zones)
- Simplified architecture (no need for Realtime Database)

## Deployment

To deploy the FireGeo functions:

```bash
firebase deploy --only functions
```

## Troubleshooting

If you encounter issues with the Firebase deployment, ensure that:

1. All required APIs are enabled in the Google Cloud Console:
   - Cloud Functions API
   - Cloud Build API
   - Artifact Registry API

2. Your Firebase project has billing enabled (required for Cloud Functions)

3. You have the correct permissions to deploy functions
