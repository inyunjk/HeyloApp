# Heylo Firebase Functions

This directory contains the Firebase Functions for the Heylo app, providing a shared backend for both iOS and Android clients.

## Rate Limiting with Redis

The backend implements Redis-based rate limiting to protect against DDoS attacks, brute force attempts, and to ensure fair usage of resources.

### Setup

1. **Redis Instance**:
   - For production, set up a Redis instance (e.g., using Google Cloud Memorystore for Redis)
   - For local development, you can use Docker:
     ```bash
     docker run --name heylo-redis -p 6379:6379 -d redis
     ```

2. **Environment Variables**:
   - Set the following environment variables for the Firebase Functions:
     ```bash
     firebase functions:config:set redis.host="YOUR_REDIS_HOST" redis.port="6379" redis.password="YOUR_REDIS_PASSWORD" redis.tls="true"
     ```
   - For local development, you can use `.runtimeconfig.json` or set environment variables directly

### Rate Limiting Configuration

The rate limiting is configured for different endpoints and actions:

1. **Authentication**:
   - Sign In: 5 attempts per minute per IP
   - Sign Up: 3 attempts per hour per IP
   - Email Verification: 3 attempts per hour per user

2. **API**:
   - General API: 60 requests per minute per IP
   - Sensitive Operations: 10 requests per minute per user

### Implementation Details

The rate limiting is implemented using the `rate-limiter-flexible` package, which provides:

- Atomic increments to avoid race conditions
- In-memory blocking for better performance
- Configurable points, duration, and block duration
- Failover options with insurance limiters

### Usage in Code

```javascript
// Import the rate limiter utilities
const { rateLimiters, rateLimitRequest } = require("./utils/rateLimiter");

// Initialize a rate limiter
const signInLimiter = rateLimiters.auth.signIn();

// Apply rate limiting in a function
const isAllowed = await rateLimitRequest(signInLimiter, clientIP);
if (!isAllowed) {
  throw new Error("Too many sign-in attempts. Please try again later.");
}
```

### Error Responses

When rate limits are exceeded, the functions return appropriate error messages with HTTP status code 429 (Too Many Requests) and the following headers:

- `Retry-After`: Seconds to wait before retrying
- `X-RateLimit-Limit`: Maximum number of requests allowed
- `X-RateLimit-Remaining`: Number of requests remaining
- `X-RateLimit-Reset`: Timestamp when the rate limit resets

## Functions

The backend provides the following functions:

1. **Authentication**:
   - `secureSignUp`: Handles user registration with rate limiting
   - `secureSignIn`: Handles user authentication with rate limiting
   - `resendEmailVerification`: Resends verification emails with rate limiting
   - `checkEmailVerification`: Checks if a user's email is verified

2. **Geolocation**:
   - `updateUserLocation`: Updates a user's location with geohash
   - `queryNearbyUsers`: Finds users within a specified radius

3. **User Management**:
   - `getUserProfile`: Gets a user's profile data
   - `userSignOut`: Handles user sign-out and removes from geo index
   - `updatePrivacySettings`: Updates a user's privacy settings

## Development

To run the functions locally:

```bash
cd functions
npm install
firebase emulators:start
```

To deploy the functions:

```bash
firebase deploy --only functions
```
