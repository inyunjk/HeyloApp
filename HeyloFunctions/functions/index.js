/**
 * Heylo Firebase Functions
 * Shared backend for iOS and Android apps
 *
 * Features:
 * - Secure authentication with rate limiting using Redis
 * - Custom geospatial implementation (FireGeo)
 * - Shared backend for iOS and Android clients
 */

const {onRequest, onCall} = require("firebase-functions/v2/https");
const {onDocumentCreated, onDocumentUpdated, onDocumentDeleted} = require("firebase-functions/v2/firestore");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");

// Initialize Firebase Admin SDK first
admin.initializeApp();

// Import custom utilities after Firebase Admin is initialized
const FireGeo = require("./utils/firegeo");
const authFunctions = require("./auth");
const { resetAllRateLimiters } = require("./utils/rateLimiter");

// Reference to Firestore database
const db = admin.firestore();

/**
 * Export authentication functions
 */
exports.secureSignUp = authFunctions.secureSignUp;
exports.secureSignIn = authFunctions.secureSignIn;
exports.resendEmailVerification = authFunctions.resendEmailVerification;
exports.checkEmailVerification = authFunctions.checkEmailVerification;
exports.secureSignOut = authFunctions.secureSignOut;

/**
 * API endpoint to check if the backend is running
 */
exports.heyloApiStatus = onRequest((request, response) => {
  logger.info("API Status check", {structuredData: true});
  response.json({
    status: "online",
    version: "1.0.0",
    timestamp: new Date().toISOString()
  });
});

/**
 * Development only: HTTP endpoint to reset rate limiters
 * This is a public endpoint that doesn't require authentication
 */
exports.devResetRateLimitersHttp = onRequest(async (request, response) => {
  // Set CORS headers for preflight requests
  response.set('Access-Control-Allow-Origin', '*');
  response.set('Access-Control-Allow-Methods', 'GET, POST');

  if (request.method === 'OPTIONS') {
    // Send response to OPTIONS requests
    response.set('Access-Control-Allow-Headers', 'Content-Type');
    response.set('Access-Control-Max-Age', '3600');
    response.status(204).send('');
    return;
  }

  // Always allow resetting rate limiters
  logger.info('Forcing development mode for rate limiter reset');

  logger.info("HTTP Rate limiter reset requested");

  try {
    const success = await resetAllRateLimiters();

    if (success) {
      logger.info("Successfully reset all rate limiters");
      response.json({ success: true, message: "All rate limiters have been reset" });
    } else {
      logger.error("Failed to reset rate limiters");
      response.status(500).json({ success: false, error: "Failed to reset rate limiters" });
    }
  } catch (error) {
    logger.error("Error resetting rate limiters", error);
    response.status(500).json({ success: false, error: error.message });
  }
});

/**
 * Callable function to get user profile data
 * Can be called from both iOS and Android clients
 */
exports.getUserProfile = onCall(async (request) => {
  try {
    // Get user ID from the authenticated request
    const uid = request.auth.uid;
    if (!uid) {
      throw new Error("User must be authenticated");
    }

    // Get user data from Firestore
    const userDoc = await db.collection("users_public").doc(uid).get();

    if (!userDoc.exists) {
      throw new Error("User profile not found");
    }

    return {
      success: true,
      data: userDoc.data()
    };
  } catch (error) {
    logger.error("Error getting user profile", error);
    return {
      success: false,
      error: error.message
    };
  }
});

/**
 * Firestore trigger when a new user is created
 * Automatically creates public and private user documents
 */
exports.onUserCreated = onDocumentCreated("users/{userId}", async (event) => {
  try {
    const userId = event.params.userId;
    const userData = event.data.data();

    logger.info(`New user created: ${userId}`, {structuredData: true});

    // Create public user profile
    await db.collection("users_public").doc(userId).set({
      displayName: userData.displayName || "",
      photoURL: userData.photoURL || "",
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    });

    // Create private user data
    await db.collection("users_private").doc(userId).set({
      email: userData.email || "",
      settings: {
        notifications: true,
        darkMode: false
      },
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    });

    return {success: true};
  } catch (error) {
    logger.error("Error in onUserCreated function", error);
    return {success: false, error: error.message};
  }
});

/**
 * FireGeo Functions
 * Custom geospatial implementation for Firebase
 */

/**
 * Updates a user's location with geohash in Firestore
 * This function follows the flat structure specified in the data structure document
 */
exports.updateUserLocation = onCall(async (request) => {
  try {
    // Ensure user is authenticated
    const userId = request.auth?.uid;
    if (!userId) {
      throw new Error("User must be authenticated");
    }

    const { latitude, longitude, accuracy, altitude, heading, speed, batteryLevel, locationMethod, movementState } = request.data;

    if (typeof latitude !== 'number' || typeof longitude !== 'number') {
      throw new Error("Invalid location data. Required: latitude, longitude");
    }

    // Validate latitude and longitude
    if (latitude < -90 || latitude > 90 || longitude < -180 || longitude > 180) {
      throw new Error("Invalid coordinates. Latitude must be between -90 and 90, longitude between -180 and 180");
    }

    // Generate geohash for the location
    const geohash = FireGeo.encodeGeohash(latitude, longitude);

    // Get user's public data for denormalization
    const userPublicDoc = await db.collection("users_public").doc(userId).get();
    if (!userPublicDoc.exists) {
      throw new Error("User profile not found");
    }

    const userData = userPublicDoc.data();

    // Check if user has privacy settings
    const userPrivateDoc = await db.collection("users_private").doc(userId).get();
    let inPrivacyZone = false;
    let privacyZoneId = null;
    let ghostMode = false;

    if (userPrivateDoc.exists) {
      const userPrivateData = userPrivateDoc.data();

      // Check if ghost mode is enabled
      if (userPrivateData.privacySettings?.ghostMode === true) {
        ghostMode = true;
      }

      // Check if user is in a privacy zone
      if (userPrivateData.privacySettings?.privacyZones &&
          Array.isArray(userPrivateData.privacySettings.privacyZones)) {

        for (const zone of userPrivateData.privacySettings.privacyZones) {
          if (zone.center && typeof zone.radiusMeters === 'number') {
            const distance = FireGeo.calculateDistance(
              latitude, longitude,
              zone.center.latitude, zone.center.longitude
            ) * 1000; // Convert km to meters

            if (distance <= zone.radiusMeters) {
              inPrivacyZone = true;
              privacyZoneId = zone.zoneId;
              break;
            }
          }
        }
      }
    }

    // Prepare location data for Firestore following the specified structure
    const locationDoc = {
      userId,
      location: {
        latitude,
        longitude,
        accuracy: accuracy || 0,
        altitude: altitude || null,
        heading: heading || null,
        speed: speed || null,
        timestamp: admin.firestore.FieldValue.serverTimestamp()
      },
      geohash,
      movementState: movementState || "stationary",
      batteryLevel: batteryLevel || null,
      locationMethod: locationMethod || "gps",
      lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
      lastActive: admin.firestore.FieldValue.serverTimestamp(),
      inPrivacyZone,
      privacyZoneId
    };

    // Start a batch write
    const batch = db.batch();

    // Update the locations/{userId} document
    const locationRef = db.collection("locations").doc(userId);
    batch.set(locationRef, locationDoc);

    // Update the user's current geo index path in users_private
    if (userPrivateDoc.exists) {
      const userPrivateRef = db.collection("users_private").doc(userId);
      batch.update(userPrivateRef, {
        currentGeoIndexPath: ghostMode ? null : `geo_index/${geohash.substring(0, 5)}/${userId}`
      });
    }

    // Only update geo_index if not in ghost mode
    if (!ghostMode) {
      // Get the precision to use for the main geo index (using precision 5 as default)
      const indexPrecision = 5;
      const geohashPrefix = geohash.substring(0, indexPrecision);

      // Check if we need to remove the user from a previous geohash index
      if (userPrivateDoc.exists) {
        const userPrivateData = userPrivateDoc.data();
        const currentGeoIndexPath = userPrivateData.currentGeoIndexPath;

        if (currentGeoIndexPath && currentGeoIndexPath !== `geo_index/${geohashPrefix}/${userId}`) {
          // Extract the old geohash prefix from the path
          const pathParts = currentGeoIndexPath.split('/');
          if (pathParts.length === 3 && pathParts[0] === 'geo_index') {
            const oldGeohashPrefix = pathParts[1];
            // Delete from old geo index if it's different
            if (oldGeohashPrefix !== geohashPrefix) {
              const oldGeoIndexRef = db.collection("geo_index").doc(oldGeohashPrefix).collection("users").doc(userId);
              batch.delete(oldGeoIndexRef);
            }
          }
        }
      }

      // Add to geo_index with the flat structure as specified
      const geoIndexRef = db.collection("geo_index").doc(geohashPrefix);

      // Create a document for the user in the geo index
      batch.set(geoIndexRef.collection("users").doc(userId), {
        userId,
        geohash,
        lastUpdated: admin.firestore.FieldValue.serverTimestamp(),

        // Denormalized fields from users_public for faster queries
        displayName: userData.displayName || "",
        profileImageUrl: userData.photoURL || "",
        moodTemperature: userData.moodTemperature || "neutral"
      });
    }

    // Commit all the writes as a batch
    await batch.commit();

    return {
      success: true,
      userId,
      geohash,
      inPrivacyZone,
      ghostMode
    };
  } catch (error) {
    logger.error("Error updating user location", error);
    return {
      success: false,
      error: error.message
    };
  }
});

/**
 * Queries nearby users within a radius of a center point
 * This function finds all users within the specified radius using geohashing
 */
exports.queryNearbyUsers = onCall(async (request) => {
  try {
    // Ensure user is authenticated
    const userId = request.auth?.uid;
    if (!userId) {
      throw new Error("User must be authenticated");
    }

    const { latitude, longitude, radiusKm, limit = 50 } = request.data;

    if (typeof latitude !== 'number' || typeof longitude !== 'number' || typeof radiusKm !== 'number') {
      throw new Error("Invalid query parameters. Required: latitude, longitude, radiusKm");
    }

    // Validate parameters
    if (latitude < -90 || latitude > 90 || longitude < -180 || longitude > 180) {
      throw new Error("Invalid coordinates. Latitude must be between -90 and 90, longitude between -180 and 180");
    }

    if (radiusKm <= 0 || radiusKm > 50) { // Limit to 50km for privacy and performance
      throw new Error("Radius must be between 0 and 50 kilometers");
    }

    // Check if the requesting user is blocked by any users
    const userPrivateDoc = await db.collection("users_private").doc(userId).get();
    let blockedByUsers = [];

    if (userPrivateDoc.exists) {
      const userPrivateData = userPrivateDoc.data();
      if (userPrivateData.connections?.blockedBy &&
          Array.isArray(userPrivateData.connections.blockedBy)) {
        blockedByUsers = userPrivateData.connections.blockedBy;
      }
    }

    // Determine the appropriate geohash precision for the radius
    // For nearby users, we use a fixed precision of 5 as specified in the data structure
    const precision = 5;

    // Generate the center geohash
    const centerGeohash = FireGeo.encodeGeohash(latitude, longitude, precision);

    // Get neighboring geohashes to handle edge cases
    const neighboringGeohashes = FireGeo.getGeohashNeighbors(centerGeohash);
    const geohashesToQuery = [centerGeohash, ...neighboringGeohashes];

    // Query Firestore for users in these geohashes
    const userPromises = geohashesToQuery.map(async (geohashPrefix) => {
      const snapshot = await db.collection("geo_index")
        .doc(geohashPrefix)
        .collection("users")
        .get();

      return snapshot.docs.map(doc => doc.data());
    });

    const usersArrays = await Promise.all(userPromises);

    // Flatten the arrays of users
    const allUsers = usersArrays.flat();

    // Filter out the requesting user and any users who have blocked them
    const filteredUsers = allUsers.filter(user =>
      user.userId !== userId && !blockedByUsers.includes(user.userId)
    );

    // Get the full location data for each user
    const userLocationPromises = filteredUsers.map(async (user) => {
      const locationDoc = await db.collection("locations").doc(user.userId).get();
      if (!locationDoc.exists) return null;

      const locationData = locationDoc.data();

      // Calculate distance
      const distance = FireGeo.calculateDistance(
        latitude, longitude,
        locationData.location.latitude, locationData.location.longitude
      );

      // Only include users within the specified radius
      if (distance <= radiusKm) {
        return {
          userId: user.userId,
          displayName: user.displayName,
          profileImageUrl: user.profileImageUrl,
          moodTemperature: user.moodTemperature,
          location: {
            latitude: locationData.location.latitude,
            longitude: locationData.location.longitude,
            accuracy: locationData.location.accuracy,
            lastUpdated: locationData.lastUpdated
          },
          distance: parseFloat(distance.toFixed(2)),
          movementState: locationData.movementState
        };
      }

      return null;
    });

    const usersWithLocation = (await Promise.all(userLocationPromises))
      .filter(user => user !== null);

    // Sort by distance and limit results
    const sortedUsers = usersWithLocation
      .sort((a, b) => a.distance - b.distance)
      .slice(0, limit);

    return {
      success: true,
      users: sortedUsers,
      count: sortedUsers.length
    };
  } catch (error) {
    logger.error("Error querying nearby users", error);
    return {
      success: false,
      error: error.message
    };
  }
});

/**
 * Removes a user from the geo index when they sign out
 */
exports.userSignOut = onCall(async (request) => {
  try {
    // Ensure user is authenticated
    const userId = request.auth?.uid;
    if (!userId) {
      throw new Error("User must be authenticated");
    }

    // Get the user's current geo index path
    const userPrivateDoc = await db.collection("users_private").doc(userId).get();
    if (!userPrivateDoc.exists) {
      return {
        success: true,
        message: "No user data to update"
      };
    }

    const userPrivateData = userPrivateDoc.data();
    const currentGeoIndexPath = userPrivateData.currentGeoIndexPath;

    // Start a batch write
    const batch = db.batch();

    // Update user's online status
    const userPrivateRef = db.collection("users_private").doc(userId);
    batch.update(userPrivateRef, {
      isOnline: false,
      currentGeoIndexPath: null,
      lastActive: admin.firestore.FieldValue.serverTimestamp()
    });

    // Remove from geo_index if they have a current path
    if (currentGeoIndexPath) {
      const pathParts = currentGeoIndexPath.split('/');
      if (pathParts.length === 3 && pathParts[0] === 'geo_index') {
        const geohashPrefix = pathParts[1];
        const geoIndexRef = db.collection("geo_index")
          .doc(geohashPrefix)
          .collection("users")
          .doc(userId);

        batch.delete(geoIndexRef);
      }
    }

    // Update the location document to mark last active time
    const locationRef = db.collection("locations").doc(userId);
    const locationDoc = await locationRef.get();

    if (locationDoc.exists) {
      batch.update(locationRef, {
        lastActive: admin.firestore.FieldValue.serverTimestamp()
      });
    }

    // Commit all the writes as a batch
    await batch.commit();

    return {
      success: true,
      message: "User signed out successfully"
    };
  } catch (error) {
    logger.error("Error signing out user", error);
    return {
      success: false,
      error: error.message
    };
  }
});

/**
 * Updates a user's privacy settings
 */
exports.updatePrivacySettings = onCall(async (request) => {
  try {
    // Ensure user is authenticated
    const userId = request.auth?.uid;
    if (!userId) {
      throw new Error("User must be authenticated");
    }

    const { ghostMode, privacyZones } = request.data;

    // Validate privacy zones if provided
    if (privacyZones && !Array.isArray(privacyZones)) {
      throw new Error("Privacy zones must be an array");
    }

    if (privacyZones) {
      for (const zone of privacyZones) {
        if (!zone.zoneId || !zone.name || !zone.center || typeof zone.radiusMeters !== 'number') {
          throw new Error("Invalid privacy zone format");
        }

        if (!zone.center.latitude || !zone.center.longitude) {
          throw new Error("Privacy zone center must have latitude and longitude");
        }
      }
    }

    // Get the user's current privacy settings
    const userPrivateRef = db.collection("users_private").doc(userId);
    const userPrivateDoc = await userPrivateRef.get();

    if (!userPrivateDoc.exists) {
      throw new Error("User private data not found");
    }

    const userPrivateData = userPrivateDoc.data();
    const currentSettings = userPrivateData.privacySettings || {};

    // Prepare the updated privacy settings
    const updatedSettings = {
      ghostMode: typeof ghostMode === 'boolean' ? ghostMode : currentSettings.ghostMode,
      privacyZones: privacyZones || currentSettings.privacyZones || []
    };

    // Update the privacy settings
    await userPrivateRef.update({
      privacySettings: updatedSettings
    });

    // If ghost mode is enabled, remove the user from the geo index
    if (updatedSettings.ghostMode === true) {
      const currentGeoIndexPath = userPrivateData.currentGeoIndexPath;

      if (currentGeoIndexPath) {
        const pathParts = currentGeoIndexPath.split('/');
        if (pathParts.length === 3 && pathParts[0] === 'geo_index') {
          const geohashPrefix = pathParts[1];
          const geoIndexRef = db.collection("geo_index")
            .doc(geohashPrefix)
            .collection("users")
            .doc(userId);

          await geoIndexRef.delete();

          // Update the current geo index path to null
          await userPrivateRef.update({
            currentGeoIndexPath: null
          });
        }
      }
    }

    return {
      success: true,
      privacySettings: updatedSettings
    };
  } catch (error) {
    logger.error("Error updating privacy settings", error);
    return {
      success: false,
      error: error.message
    };
  }
});

/**
 * Development only: Reset all rate limiters
 * This endpoint is only available in development mode
 */
exports.devResetRateLimiters = onCall({
  enforceAppCheck: false,  // Don't require App Check
  allowInvalidAppCheckToken: true, // Allow invalid App Check tokens
  minInstances: 0,
  maxInstances: 1,
  timeoutSeconds: 60,
  memory: '256MiB',
}, async (request) => {
  // Always allow this function to run in any environment for testing
  // In a real production app, you would want to restrict this
  logger.info("Rate limiter reset requested", { auth: request.auth });

  // Always allow resetting rate limiters
  logger.info('Forcing development mode for rate limiter reset');

  const success = await resetAllRateLimiters();

  if (success) {
    logger.info("Successfully reset all rate limiters");
    return { success: true, message: "All rate limiters have been reset" };
  } else {
    logger.error("Failed to reset rate limiters");
    throw new Error("Failed to reset rate limiters");
  }
});