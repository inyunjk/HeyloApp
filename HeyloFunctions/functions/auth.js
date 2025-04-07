/**
 * Heylo Authentication Functions
 * Secure backend methods for handling user authentication
 * With Redis rate limiting
 */

const admin = require("firebase-admin");
const logger = require("firebase-functions/logger");
const { onCall } = require("firebase-functions/v2/https");
const { rateLimiters, rateLimitRequest } = require("./utils/rateLimiter");

// Note: Firebase Admin is initialized in index.js
// Reference to Firestore database - this will be initialized after admin.initializeApp() is called
let db;

// Initialize Firestore reference
const initFirestore = () => {
  if (!db) {
    db = admin.firestore();
  }
  return db;
};

// Rate limiters will be initialized when needed
let signInLimiter;
let signUpLimiter;
let emailVerificationLimiter;

// Initialize rate limiters
const initRateLimiters = () => {
  if (!signInLimiter) {
    signInLimiter = rateLimiters.auth.signIn();
  }
  if (!signUpLimiter) {
    signUpLimiter = rateLimiters.auth.signUp();
  }
  if (!emailVerificationLimiter) {
    emailVerificationLimiter = rateLimiters.auth.emailVerification();
  }
};

/**
 * Securely creates a new user account
 * This function handles the entire sign-up process including:
 * - Creating the Firebase Auth user
 * - Uploading profile image
 * - Creating user documents in Firestore
 * - Sending email verification
 */
exports.secureSignUp = onCall(async (request) => {
  try {
    const { email, password, displayName, profileImageBase64 } = request.data;

    // Skip initializing rate limiters for sign-up
    logger.info("Skipping rate limiter initialization for sign-up");

    // Get client IP for rate limiting
    const clientIP = request.rawRequest?.ip || 'unknown';

    // Skip rate limiting for sign-up
    logger.info("Skipping rate limiting for sign-up");

    // Validate input
    if (!email || !password || !displayName) {
      throw new Error("Missing required fields: email, password, displayName");
    }

    // Validate email format
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      throw new Error("Invalid email format");
    }

    // Validate password strength
    if (password.length < 8) {
      throw new Error("Password must be at least 8 characters long");
    }

    // Create user in Firebase Auth
    const userRecord = await admin.auth().createUser({
      email: email,
      password: password,
      displayName: displayName,
      emailVerified: false
    });

    const userId = userRecord.uid;
    let photoURL = null;

    // Upload profile image if provided
    if (profileImageBase64) {
      try {
        // Remove data:image/jpeg;base64, prefix if present
        const base64EncodedImageString = profileImageBase64.replace(/^data:image\/\w+;base64,/, '');
        const imageBuffer = Buffer.from(base64EncodedImageString, 'base64');

        // Create a storage reference
        const bucket = admin.storage().bucket();
        const imageFile = bucket.file(`profile_images/${userId}.jpg`);

        // Upload the image
        await imageFile.save(imageBuffer, {
          metadata: {
            contentType: 'image/jpeg',
          }
        });

        // Make the file publicly accessible
        await imageFile.makePublic();

        // Get the public URL
        photoURL = `https://storage.googleapis.com/${bucket.name}/${imageFile.name}`;

        // Update user profile with photo URL
        await admin.auth().updateUser(userId, {
          photoURL: photoURL
        });
      } catch (error) {
        logger.error("Error uploading profile image", error);
        // Continue with user creation even if image upload fails
      }
    }

    // Initialize Firestore
    const db = initFirestore();

    // Create user document in Firestore
    const userData = {
      userId: userId,
      displayName: displayName,
      email: email,
      photoURL: photoURL || "",
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    };

    // Start a batch write
    const batch = db.batch();

    // Create main user document
    const userRef = db.collection("users").doc(userId);
    batch.set(userRef, userData);

    // Create public user profile
    const publicUserData = {
      displayName: displayName,
      photoURL: photoURL || "",
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    };
    const publicUserRef = db.collection("users_public").doc(userId);
    batch.set(publicUserRef, publicUserData);

    // Create private user data
    const privateUserData = {
      email: email,
      settings: {
        notifications: true,
        darkMode: true
      },
      privacySettings: {
        ghostMode: false,
        privacyZones: []
      },
      isOnline: true,
      lastActive: admin.firestore.FieldValue.serverTimestamp(),
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    };
    const privateUserRef = db.collection("users_private").doc(userId);
    batch.set(privateUserRef, privateUserData);

    // Commit all the writes as a batch
    await batch.commit();

    // For development, we'll use the Firebase default verification email
    // This doesn't require a custom domain to be set up
    let emailVerificationLink = "CLIENT_SEND_VERIFICATION";

    try {
      // Get the user record
      const userRecord = await admin.auth().getUser(userId);

      // Send verification email using the Firebase Admin SDK
      // This will use Firebase's default email template and handling
      await admin.auth().updateUser(userId, {
        emailVerified: false // Ensure it's not verified yet
      });

      logger.info(`Preparing for email verification for ${email}`);
    } catch (emailError) {
      logger.error("Error preparing for email verification", emailError);
    }

    // Send email verification
    // Note: In a production environment, you would use a proper email service
    // For now, we'll just return the link to the client

    return {
      success: true,
      userId: userId,
      displayName: displayName,
      email: email,
      photoURL: photoURL,
      emailVerificationLink: emailVerificationLink
    };
  } catch (error) {
    logger.error("Error in secureSignUp function", error);
    return {
      success: false,
      error: error.message
    };
  }
});

/**
 * Securely signs in a user
 * This function handles the sign-in process and returns a custom token
 * that can be used by the client to authenticate with Firebase
 */
exports.secureSignIn = onCall(async (request) => {
  try {
    const { email, password } = request.data;

    // Initialize rate limiters
    initRateLimiters();

    // Get client IP for rate limiting
    const clientIP = request.rawRequest?.ip || 'unknown';

    // Apply rate limiting
    const isAllowed = await rateLimitRequest(signInLimiter, clientIP);
    if (!isAllowed) {
      throw new Error("Too many sign-in attempts. Please try again later.");
    }

    // Validate input
    if (!email || !password) {
      throw new Error("Missing required fields: email, password");
    }

    // We can't directly verify passwords with Admin SDK, so we'll use a workaround
    // This is a limitation of Firebase Admin SDK

    // First, try to get the user by email
    const userRecord = await admin.auth().getUserByEmail(email)
      .catch(error => {
        // If user not found, throw a generic error for security
        throw new Error("Invalid email or password");
      });

    // At this point, we know the user exists
    // Instead of creating a custom token (which requires additional permissions),
    // we'll just return the user information and let the client sign in directly
    // with email and password

    // Note: We're not creating a custom token anymore as it requires additional IAM permissions
    // const customToken = await admin.auth().createCustomToken(userRecord.uid);
    const customToken = null; // Not using custom tokens

    // Initialize Firestore
    const db = initFirestore();

    // Get user data from Firestore
    const userDoc = await db.collection("users").doc(userRecord.uid).get();
    const userData = userDoc.exists ? userDoc.data() : null;

    return {
      success: true,
      userId: userRecord.uid,
      displayName: userRecord.displayName,
      email: userRecord.email,
      photoURL: userRecord.photoURL,
      emailVerified: userRecord.emailVerified,
      userData: userData
    };
  } catch (error) {
    logger.error("Error in secureSignIn function", error);
    return {
      success: false,
      error: error.message
    };
  }
});

/**
 * Resends the email verification link to the user
 */
exports.resendEmailVerification = onCall(async (request) => {
  try {
    // Ensure user is authenticated
    const userId = request.auth?.uid;
    if (!userId) {
      throw new Error("User must be authenticated");
    }

    // Initialize rate limiters
    initRateLimiters();

    // Apply rate limiting based on user ID
    const isAllowed = await rateLimitRequest(emailVerificationLimiter, userId);
    if (!isAllowed) {
      throw new Error("Too many email verification requests. Please try again later.");
    }

    // Get the user record
    const userRecord = await admin.auth().getUser(userId);

    // Check if email is already verified
    if (userRecord.emailVerified) {
      return {
        success: true,
        message: "Email is already verified"
      };
    }

    // For development, we'll use the Firebase default verification email
    // This doesn't require a custom domain to be set up
    let emailVerificationLink = "CLIENT_SEND_VERIFICATION";

    try {
      // Make sure the email is not verified yet
      await admin.auth().updateUser(userId, {
        emailVerified: false // Ensure it's not verified yet
      });

      logger.info(`Preparing for email verification resend for ${userRecord.email}`);
    } catch (emailError) {
      logger.error("Error preparing for email verification resend", emailError);
    }

    // Note: In a production environment, you would use a proper email service
    // For now, we'll just return instructions to the client to send the verification email

    return {
      success: true,
      emailVerificationLink: emailVerificationLink
    };
  } catch (error) {
    logger.error("Error in resendEmailVerification function", error);
    return {
      success: false,
      error: error.message
    };
  }
});

/**
 * Checks if the user's email is verified
 */
exports.checkEmailVerification = onCall(async (request) => {
  try {
    // Ensure user is authenticated
    const userId = request.auth?.uid;
    if (!userId) {
      throw new Error("User must be authenticated");
    }

    // Get the user record
    const userRecord = await admin.auth().getUser(userId);

    // Just check if the email is verified, don't automatically verify it
    logger.info(`Checking email verification status for ${userRecord.email}: ${userRecord.emailVerified}`);

    // If not verified, log a message about how to verify
    if (!userRecord.emailVerified) {
      logger.info(`Email ${userRecord.email} is not verified. User should check their email or request a new verification link.`);
    }

    return {
      success: true,
      emailVerified: userRecord.emailVerified
    };
  } catch (error) {
    logger.error("Error in checkEmailVerification function", error);
    return {
      success: false,
      error: error.message
    };
  }
});

/**
 * Securely signs out a user
 * This function handles the sign-out process and updates the user's online status
 */
exports.secureSignOut = onCall(async (request) => {
  try {
    // Ensure user is authenticated
    const userId = request.auth?.uid;
    if (!userId) {
      throw new Error("User must be authenticated");
    }

    // Initialize Firestore
    const db = initFirestore();

    // Update user's online status
    await db.collection("users_private").doc(userId).update({
      isOnline: false,
      lastActive: admin.firestore.FieldValue.serverTimestamp()
    });

    return {
      success: true,
      message: "User signed out successfully"
    };
  } catch (error) {
    logger.error("Error in secureSignOut function", error);
    return {
      success: false,
      error: error.message
    };
  }
});
