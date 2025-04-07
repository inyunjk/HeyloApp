/**
 * Redis Rate Limiter for Firebase Functions
 * Uses rate-limiter-flexible package to implement rate limiting
 */

const { RateLimiterRedis, RateLimiterMemory } = require('rate-limiter-flexible');
const logger = require("firebase-functions/logger");

// Always use memory-based rate limiting
const isDevelopment = true;

// Redis client setup (only used in production)
let redisClient;
let Redis;

// Initialize Redis client (only in production)
const initRedisClient = () => {
  // In development, we'll use memory instead of Redis
  if (isDevelopment) {
    logger.info('Using memory rate limiter for development');
    return null;
  }

  if (redisClient) return redisClient;

  // Lazy load ioredis only in production
  if (!Redis) {
    Redis = require('ioredis');
  }

  // Use environment variables for Redis connection
  // For production, set these in Firebase Functions config
  const redisHost = process.env.REDIS_HOST || 'localhost';
  const redisPort = process.env.REDIS_PORT || 6379;
  const redisPassword = process.env.REDIS_PASSWORD || '';
  const redisTls = process.env.REDIS_TLS === 'true';

  const options = {
    host: redisHost,
    port: redisPort,
    enableOfflineQueue: false,
    maxRetriesPerRequest: 3,
  };

  if (redisPassword) {
    options.password = redisPassword;
  }

  if (redisTls) {
    options.tls = {};
  }

  try {
    redisClient = new Redis(options);

    redisClient.on('error', (err) => {
      logger.error('Redis error:', err);
    });

    redisClient.on('connect', () => {
      logger.info('Connected to Redis');
    });

    return redisClient;
  } catch (err) {
    logger.error('Redis connection error:', err);
    // Fall back to memory rate limiter
    logger.info('Falling back to memory rate limiter');
    return null;
  }
};

/**
 * Create a rate limiter for a specific endpoint or action
 *
 * @param {Object} options - Rate limiter options
 * @param {string} options.keyPrefix - Prefix for Redis keys
 * @param {number} options.points - Maximum number of points (requests)
 * @param {number} options.duration - Duration in seconds
 * @param {number} options.blockDuration - Block duration in seconds (optional)
 * @returns {RateLimiterRedis} - Rate limiter instance
 */
const createRateLimiter = (options) => {
  // Get Redis client (will be null in development)
  const client = initRedisClient();

  // Common options for both Redis and Memory rate limiters
  const commonOptions = {
    keyPrefix: options.keyPrefix,
    points: options.points,
    duration: options.duration,
    blockDuration: options.blockDuration || 0, // Block for blockDuration seconds if consumed more than points
  };

  // Use memory rate limiter in development or if Redis client initialization failed
  if (!client || isDevelopment) {
    return new RateLimiterMemory(commonOptions);
  }

  // Use Redis rate limiter in production
  const redisOptions = {
    ...commonOptions,
    storeClient: client,
    inmemoryBlockOnConsumed: options.points * 2, // Block key in memory for better performance
    inmemoryBlockDuration: options.duration,
  };

  return new RateLimiterRedis(redisOptions);
};

/**
 * Middleware for Express-based Firebase Functions
 *
 * @param {RateLimiterRedis} rateLimiter - Rate limiter instance
 * @param {Function} getKey - Function to extract key from request (default: IP address)
 * @param {number} pointsToConsume - Points to consume per request (default: 1)
 * @returns {Function} - Express middleware
 */
const rateLimiterMiddleware = (rateLimiter, getKey = (req) => req.ip, pointsToConsume = 1) => {
  return (req, res, next) => {
    const key = getKey(req);

    rateLimiter.consume(key, pointsToConsume)
      .then((rateLimiterRes) => {
        // Add rate limit headers
        res.set('X-RateLimit-Limit', rateLimiter.points);
        res.set('X-RateLimit-Remaining', rateLimiterRes.remainingPoints);
        res.set('X-RateLimit-Reset', Math.ceil((Date.now() + rateLimiterRes.msBeforeNext) / 1000));
        next();
      })
      .catch((rateLimiterRes) => {
        // Too many requests
        res.set('Retry-After', Math.ceil(rateLimiterRes.msBeforeNext / 1000));
        res.set('X-RateLimit-Limit', rateLimiter.points);
        res.set('X-RateLimit-Remaining', 0);
        res.set('X-RateLimit-Reset', Math.ceil((Date.now() + rateLimiterRes.msBeforeNext) / 1000));
        res.status(429).json({
          success: false,
          error: 'Too many requests',
          message: 'Please try again later',
          retryAfter: Math.ceil(rateLimiterRes.msBeforeNext / 1000)
        });
      });
  };
};

/**
 * Rate limiter for Firebase Functions (non-Express)
 *
 * @param {RateLimiterRedis} rateLimiter - Rate limiter instance
 * @param {string|Function} key - Key or function to extract key
 * @param {number} pointsToConsume - Points to consume (default: 1)
 * @returns {Promise<boolean>} - True if request is allowed, false if rate limited
 */
const rateLimitRequest = async (rateLimiter, key, pointsToConsume = 1) => {
  try {
    await rateLimiter.consume(key, pointsToConsume);
    return true;
  } catch (error) {
    return false;
  }
};

/**
 * Predefined rate limiters for common scenarios
 */
const rateLimiters = {
  // Authentication rate limiters
  auth: {
    // Limit sign-in attempts to 15 per 15 minutes per IP
    signIn: () => createRateLimiter({
      keyPrefix: 'rl:auth:signin',
      points: 15,
      duration: 60 * 15, // 15 minutes
      blockDuration: 60 * 30 // Block for 30 minutes after too many attempts
    }),

    // Set very high limits for sign-up to effectively disable rate limiting
    signUp: () => createRateLimiter({
      keyPrefix: 'rl:auth:signup',
      points: 1000, // Allow 1000 attempts
      duration: 60, // Per minute
      blockDuration: 0 // Don't block
    }),

    // Limit email verification requests to 5 per hour per user
    emailVerification: () => createRateLimiter({
      keyPrefix: 'rl:auth:emailverify',
      points: 5,
      duration: 60 * 60, // 1 hour
      blockDuration: 60 * 30 // Block for 30 minutes after too many attempts
    })
  },

  // API rate limiters
  api: {
    // General API rate limiter: 60 requests per minute per IP
    general: () => createRateLimiter({
      keyPrefix: 'rl:api:general',
      points: 60,
      duration: 60
    }),

    // Sensitive operations: 10 requests per minute per user
    sensitive: () => createRateLimiter({
      keyPrefix: 'rl:api:sensitive',
      points: 10,
      duration: 60,
      blockDuration: 60 * 2 // Block for 2 minutes after too many attempts
    })
  }
};

/**
 * Clear rate limiting for a specific key (useful for development and testing)
 *
 * @param {Object} rateLimiter - Rate limiter instance
 * @param {string} key - Key to clear
 * @returns {Promise<boolean>} - True if successful, false otherwise
 */
const clearRateLimit = async (rateLimiter, key) => {
  try {
    await rateLimiter.delete(key);
    return true;
  } catch (error) {
    logger.error('Error clearing rate limit:', error);
    return false;
  }
};

/**
 * Reset all rate limiters (for development and testing only)
 * WARNING: This should never be exposed in production
 */
const resetAllRateLimiters = async () => {
  // Always allow resetting rate limiters
  logger.info('Resetting all rate limiters');

  try {
    // Initialize all rate limiters
    const signInLimiter = rateLimiters.auth.signIn();
    const signUpLimiter = rateLimiters.auth.signUp();
    const emailVerificationLimiter = rateLimiters.auth.emailVerification();
    const generalApiLimiter = rateLimiters.api.general();
    const sensitiveApiLimiter = rateLimiters.api.sensitive();

    // Delete all keys (this only works for memory rate limiters)
    if (signInLimiter.deleteAll) await signInLimiter.deleteAll();
    if (signUpLimiter.deleteAll) await signUpLimiter.deleteAll();
    if (emailVerificationLimiter.deleteAll) await emailVerificationLimiter.deleteAll();
    if (generalApiLimiter.deleteAll) await generalApiLimiter.deleteAll();
    if (sensitiveApiLimiter.deleteAll) await sensitiveApiLimiter.deleteAll();

    return true;
  } catch (error) {
    logger.error('Error resetting rate limiters:', error);
    return false;
  }
};

module.exports = {
  initRedisClient,
  createRateLimiter,
  rateLimiterMiddleware,
  rateLimitRequest,
  rateLimiters,
  clearRateLimit,
  resetAllRateLimiters
};
