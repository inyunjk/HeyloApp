# HeyLo Data Structure Reference Guide

This document serves as a reference guide for the data structure implementation in both iOS and Android projects.

## Core Collections Overview

```
firestore/
├── users_public/                # Public user information
│   └── {userId}/                # Document per user
├── users_private/               # Private user information
│   └── {userId}/                # Document per user
├── locations/                   # User location tracking (not for queries)
│   └── {userId}/                # Document per user
├── geo_index/                   # Geospatial index for queries
│   └── {geohashPrefix}/         # Documents grouped by geohash prefix
│       └── {userId}/            # User entry in geospatial index
└── businesses/                  # Reserved for future use (empty for now)
```

## Document Structures

### users_public/{userId}
```json
{
  "userId": "string",
  "displayName": "string",
  "username": "string",
  "profileImageUrl": "string",
  "bio": "string",
  "joinDate": "timestamp",
  "lastActive": "timestamp",
  "moodTemperature": "string",    // "cold", "cool", "neutral", "warm", "hot"
  "howToApproach": {
    "text": "string",
    "socialLinks": {
      "instagram": "string?",
      "twitter": "string?",
      "linkedin": "string?",
      "other": "string?"
    },
    "lastUpdated": "timestamp"
  },
  "stats": {
    "shakasSent": "number",
    "shakasReceived": "number"
  }
}
```

### users_private/{userId}
```json
{
  "userId": "string",
  "email": "string",
  "emailVerified": "boolean",
  "phoneNumber": "string?",
  "privacySettings": {
    "ghostMode": "boolean",
    "privacyZones": [
      {
        "zoneId": "string",
        "name": "string",
        "center": {
          "latitude": "number",
          "longitude": "number"
        },
        "radiusMeters": "number"
      }
    ]
  },
  "connections": {
    "blocked": ["userId1", "userId2", ...],
    "blockedBy": ["userId3", "userId4", ...]
  },
  "deviceTokens": ["token1", "token2", ...],
  "notificationSettings": {
    "pushEnabled": "boolean",
    "emailEnabled": "boolean",
    "locationAlerts": "boolean"
  },
  "isOnline": "boolean",          // Tracks if user is signed in
  "currentGeoIndexPath": "string?" // Stores current geo_index document path for efficient updates
}
```

### locations/{userId}
```json
{
  "userId": "string",
  "location": {
    "latitude": "number",
    "longitude": "number",
    "accuracy": "number",
    "altitude": "number?",
    "heading": "number?",
    "speed": "number?",
    "timestamp": "timestamp"
  },
  "geohash": "string",        // Full geohash (calculated on backend)
  "movementState": "string",  // "stationary", "walking", "running", "biking", "driving", "flying"
  "batteryLevel": "number?",
  "locationMethod": "string", // "gps", "network", "wifi"
  "lastUpdated": "timestamp",
  "lastActive": "timestamp",  // For TTL cleanup
  "inPrivacyZone": "boolean", // Whether user is in a privacy zone
  "privacyZoneId": "string?"  // ID of the privacy zone if in one
}
```

### geo_index/{geohashPrefix}/{userId}
```json
{
  "userId": "string",
  "geohash": "string",        // Full geohash
  "lastUpdated": "timestamp",
  
  // Denormalized fields for faster queries
  "displayName": "string",    // From users_public
  "profileImageUrl": "string", // From users_public
  "moodTemperature": "string"  // From users_public
}
```

## Subcollections

### users_private/{userId}/connections
```json
{
  "connectionId": "string",      // Connected user's ID
  "connectionIndex": "number",   // 0-100 scale
  "lastInteraction": "timestamp",
  "interactionHistory": [
    {
      "type": "string",          // "shaka", "message", "view", etc.
      "timestamp": "timestamp",
      "indexChange": "number"    // How much this interaction affected the index
    }
  ],
  "decayRate": "number",         // How quickly connection index decays
  "lastDecayCalculation": "timestamp"
}
```

## Key Optimizations

### 1. Backend Geohash Calculation
- All geohash calculations performed on the backend
- Ensures consistency and security
- Simplifies client-side code

**Implementation Notes:**
- Client sends raw coordinates to backend
- Backend calculates geohash and updates database
- Prevents manipulation of location data

### 2. Denormalization for Nearby Queries
- Store frequently needed user information directly in geo_index
- Reduces number of reads when querying nearby users
- Improves performance for the most common operation

**Implementation Notes:**
- Copy key fields from users_public to geo_index
- Update denormalized data when source data changes
- Balance between read performance and write complexity

### 3. Pagination Support for Nearby Queries
- Load nearby users in smaller batches
- Better performance and user experience
- Reduces initial load time

**Implementation Notes:**
- Implement cursor-based pagination
- Use geohash prefixes for efficient spatial queries
- Sort results by actual distance after retrieval

### 4. Batch Updates for Consistency
- Use batch operations when updating multiple documents
- Ensures data consistency
- All-or-nothing transactions

**Implementation Notes:**
- Group related updates in a single batch
- Handle batch size limits (500 operations per batch)
- Use for critical operations like privacy changes

### 5. TTL (Time-To-Live) for Inactive Users
- Automatically clean up location data for inactive users
- Keeps database efficient
- Reduces storage costs

**Implementation Notes:**
- Implement scheduled cloud function
- Remove data for users inactive for 30+ days
- Update lastActive timestamp on all user actions

## Privacy Flows

### Ghost Mode Toggle
- When enabled: Remove user from geo_index
- When disabled: Add user back to geo_index if not in privacy zone
- Update privacy settings in users_private

### Privacy Zone Entry/Exit
- Entry: Remove from geo_index, update location document
- Exit: Add back to geo_index if not in ghost mode, update location document
- Use batch operations for consistency

### Sign Out / App Close
- Update online status
- Remove from geo_index
- Update last active timestamp

## Implementation Checklist

1. [ ] Set up basic Firestore collections and documents
2. [ ] Implement backend geohash calculation
3. [ ] Create location update flow with privacy checks
4. [ ] Add denormalization to geo_index
5. [ ] Implement pagination for nearby queries
6. [ ] Add batch operations for consistency
7. [ ] Set up TTL cleanup function
8. [ ] Implement privacy flows (ghost mode, privacy zones)
9. [ ] Add connection tracking and management
10. [ ] Set up proper Firestore security rules

## Platform-Specific Notes

### iOS Implementation
- Use Swift's Codable protocol for Firestore document mapping
- Implement location services with CoreLocation
- Handle background location updates appropriately
- Manage privacy permissions according to iOS guidelines

### Android Implementation
- Use Kotlin data classes for Firestore document mapping
- Implement location services with FusedLocationProviderClient
- Handle background location updates with WorkManager
- Manage privacy permissions according to Android guidelines

## Security Considerations

- Implement proper Firestore security rules
- Validate all data on the server side
- Use Firebase Authentication for user identity
- Encrypt sensitive data in transit and at rest
- Implement rate limiting for location updates
- Validate geospatial queries on the server

## Performance Monitoring

- Track read/write operations to optimize costs
- Monitor query performance
- Set up alerts for excessive database usage
- Implement analytics to track user engagement
- Monitor battery usage from location services

---

This reference guide should be used by both iOS and Android development teams to ensure consistent implementation of the data structure across platforms.
