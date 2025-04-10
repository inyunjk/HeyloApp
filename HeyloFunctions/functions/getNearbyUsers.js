/**
 * Get Nearby Users Function
 *
 * This function implements a clean two-step process for finding nearby users:
 * 1. Query Realtime Database for nearby user IDs based on geohash
 * 2. Fetch complete user profiles from Firestore using those IDs
 *
 * This approach properly separates location data (Realtime DB) from user data (Firestore)
 */

const functions = require('firebase-functions/v2/https');
const logger = require('firebase-functions/logger');
const admin = require('firebase-admin');
const geofire = require('geofire-common');

// Export the function
exports.getNearbyUsers = functions.onCall(async (data, context) => {
  try {
    // Log the received data for debugging (safely)
    logger.info(`Received data keys: ${Object.keys(data).join(', ')}`);

    // Log data object structure
    if (data.data) {
      logger.info(`Data object keys: ${Object.keys(data.data).join(', ')}`);

      // Check if userId is in data.data
      if (data.data.userId) {
        logger.info(`Found userId in data.data: ${data.data.userId}`);
      }
    }

    logger.info(`Auth context: ${context.auth ? 'authenticated' : 'not authenticated'}`);
    if (context.auth) {
      logger.info(`Auth UID: ${context.auth.uid}`);
    }

    // Get user ID from auth context or request data (checking both data and data.data)
    let userId = context.auth?.uid || data.userId || (data.data && data.data.userId);
    logger.info(`Using userId: ${userId}`);

    // Only allow calls with a userId
    if (!userId) {
      throw new functions.HttpsError(
        'invalid-argument',
        'User ID must be provided when not authenticated.'
      );
    }

    // Get parameters from request (checking both data and data.data)
    const latitude = data.latitude || (data.data && data.data.latitude);
    const longitude = data.longitude || (data.data && data.data.longitude);
    const radiusKm = data.radiusKm || (data.data && data.data.radiusKm) || 5.0;

    logger.info(`Latitude: ${latitude}, Longitude: ${longitude}, RadiusKm: ${radiusKm}`);

    // Validate parameters
    if (!latitude || !longitude) {
      throw new functions.HttpsError(
        'invalid-argument',
        'The function must be called with latitude and longitude.'
      );
    }

    // Validate radius (between 0.1 and 50 km)
    const validRadius = Math.min(Math.max(radiusKm, 0.1), 50.0);

    logger.info(`Finding users near [${latitude}, ${longitude}] within ${validRadius}km for user ${userId}`);

    // STEP 1: Query Realtime Database for nearby user IDs

    // Calculate the geohash for the query center
    const center = [latitude, longitude];
    const centerGeohash = geofire.geohashForLocation(center);

    // Calculate geohash precision based on radius
    // For a 5km radius, precision 5 is appropriate (each cell is ~5km×5km)
    // For smaller radius, we might use precision 6 (~1.2km×0.6km)
    const precision = validRadius <= 1.0 ? 6 : 5;
    const geohashPrefix = centerGeohash.substring(0, precision);

    logger.info(`Using geohash prefix: ${geohashPrefix} with precision ${precision}`);

    // Calculate the bounding box for the query
    const radiusInM = validRadius * 1000;
    const bounds = geofire.geohashQueryBounds(center, radiusInM);

    // Query Realtime Database for users within the bounding box
    const realtimeDb = admin.database();
    const locationsRef = realtimeDb.ref('locations');

    // Array to hold all promises for the queries
    const nearbyUserPromises = [];

    // For each geohash range, query the Realtime Database
    for (const bound of bounds) {
      const query = locationsRef
        .orderByChild('geohash')
        .startAt(bound[0])
        .endAt(bound[1]);

      nearbyUserPromises.push(query.once('value'));
    }

    // Wait for all queries to complete
    const snapshots = await Promise.all(nearbyUserPromises);

    // Process the results
    const nearbyUserIds = [];
    const nearbyUserLocations = {};

    // Combine results from all queries
    snapshots.forEach(snapshot => {
      snapshot.forEach(childSnapshot => {
        const locationData = childSnapshot.val();
        const userIdFromLocation = childSnapshot.key;

        // Skip the current user
        if (userIdFromLocation === userId) {
          return;
        }

        // Skip users without proper location data
        if (!locationData || !locationData.lat || !locationData.lng) {
          return;
        }

        // Add to the list without distance calculation
        // Avoid duplicates (same user might appear in multiple geohash ranges)
        if (!nearbyUserLocations[userIdFromLocation]) {
          nearbyUserIds.push(userIdFromLocation);
          nearbyUserLocations[userIdFromLocation] = {
            lastUpdated: locationData.timestamp || Date.now() / 1000
          };
        }
      });
    });

    logger.info(`Found ${nearbyUserIds.length} nearby users in Realtime Database`);

    // If no nearby users found, return empty array
    if (nearbyUserIds.length === 0) {
      return {
        success: true,
        users: []
      };
    }

    // STEP 2: Fetch user profiles from Firestore

    // Firestore has a limit of 10 items for 'in' queries, so we need to batch
    const batchSize = 10;
    const userProfilePromises = [];

    // Split the user IDs into batches
    for (let i = 0; i < nearbyUserIds.length; i += batchSize) {
      const batch = nearbyUserIds.slice(i, i + batchSize);

      // Query Firestore for user profiles
      const usersQuery = admin.firestore()
        .collection('users')
        .where(admin.firestore.FieldPath.documentId(), 'in', batch);

      userProfilePromises.push(usersQuery.get());
    }

    // Wait for all Firestore queries to complete
    const userProfileSnapshots = await Promise.all(userProfilePromises);

    // Process the results
    const nearbyUsers = [];

    // Combine results from all batches
    userProfileSnapshots.forEach(querySnapshot => {
      querySnapshot.forEach(doc => {
        const userData = doc.data();
        const userId = doc.id;

        // Combine user profile with location data
        if (nearbyUserLocations[userId]) {
          nearbyUsers.push({
            id: userId,
            userId: userId,
            displayName: userData.displayName || 'Unknown User',
            profileImageUrl: userData.photoURL || userData.profileImageUrl || '',
            moodTemperature: userData.moodTemperature || 'Neutral',
            lastUpdated: nearbyUserLocations[userId].lastUpdated,
            // Add any other user profile fields needed
          });
        }
      });
    });

    // Sort by lastUpdated (most recent first)
    nearbyUsers.sort((a, b) => b.lastUpdated - a.lastUpdated);

    logger.info(`Returning ${nearbyUsers.length} nearby users with profiles`);

    return {
      success: true,
      users: nearbyUsers
    };

  } catch (error) {
    logger.error('Error getting nearby users:', error);

    throw new functions.HttpsError(
      'internal',
      `Error getting nearby users: ${error.message}`
    );
  }
});
