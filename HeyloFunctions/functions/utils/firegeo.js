/**
 * FireGeo - Custom geospatial query implementation for Firebase
 * 
 * This utility provides functions for:
 * 1. Converting lat/lng to geohashes
 * 2. Storing location data with geohashes
 * 3. Querying locations within a radius
 */

const BASE32_CHARS = '0123456789bcdefghjkmnpqrstuvwxyz';
const EARTH_RADIUS_KM = 6371; // Earth's radius in kilometers

/**
 * Converts a latitude and longitude to a geohash
 * @param {number} lat - Latitude in decimal degrees
 * @param {number} lng - Longitude in decimal degrees
 * @param {number} precision - Length of the geohash string (default: 9)
 * @returns {string} The geohash string
 */
function encodeGeohash(lat, lng, precision = 9) {
  let isEven = true;
  let latMin = -90;
  let latMax = 90;
  let lngMin = -180;
  let lngMax = 180;
  let bit = 0;
  let ch = 0;
  let geohash = '';

  while (geohash.length < precision) {
    if (isEven) {
      const mid = (lngMin + lngMax) / 2;
      if (lng >= mid) {
        ch |= 1 << (4 - bit);
        lngMin = mid;
      } else {
        lngMax = mid;
      }
    } else {
      const mid = (latMin + latMax) / 2;
      if (lat >= mid) {
        ch |= 1 << (4 - bit);
        latMin = mid;
      } else {
        latMax = mid;
      }
    }

    isEven = !isEven;
    
    if (bit < 4) {
      bit++;
    } else {
      geohash += BASE32_CHARS.charAt(ch);
      bit = 0;
      ch = 0;
    }
  }
  
  return geohash;
}

/**
 * Calculates the distance between two points on Earth
 * @param {number} lat1 - Latitude of point 1 in decimal degrees
 * @param {number} lng1 - Longitude of point 1 in decimal degrees
 * @param {number} lat2 - Latitude of point 2 in decimal degrees
 * @param {number} lng2 - Longitude of point 2 in decimal degrees
 * @returns {number} Distance in kilometers
 */
function calculateDistance(lat1, lng1, lat2, lng2) {
  // Convert latitude and longitude from degrees to radians
  const latRad1 = toRadians(lat1);
  const lngRad1 = toRadians(lng1);
  const latRad2 = toRadians(lat2);
  const lngRad2 = toRadians(lng2);

  // Haversine formula
  const dLat = latRad2 - latRad1;
  const dLng = lngRad2 - lngRad1;
  const a = 
    Math.sin(dLat/2) * Math.sin(dLat/2) +
    Math.cos(latRad1) * Math.cos(latRad2) * 
    Math.sin(dLng/2) * Math.sin(dLng/2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
  const distance = EARTH_RADIUS_KM * c;
  
  return distance;
}

/**
 * Converts degrees to radians
 * @param {number} degrees - Angle in degrees
 * @returns {number} Angle in radians
 */
function toRadians(degrees) {
  return degrees * (Math.PI / 180);
}

/**
 * Calculates the geohash precision needed for a given radius
 * @param {number} radiusKm - Radius in kilometers
 * @returns {number} Recommended geohash precision
 */
function getPrecisionForRadius(radiusKm) {
  // These are approximate values for geohash precision at the equator
  const precisionMap = [
    { precision: 1, widthKm: 5000 },   // Geohash length 1: ~5000km
    { precision: 2, widthKm: 1250 },   // Geohash length 2: ~1250km
    { precision: 3, widthKm: 156 },    // Geohash length 3: ~156km
    { precision: 4, widthKm: 39 },     // Geohash length 4: ~39km
    { precision: 5, widthKm: 4.9 },    // Geohash length 5: ~4.9km
    { precision: 6, widthKm: 1.2 },    // Geohash length 6: ~1.2km
    { precision: 7, widthKm: 0.152 },  // Geohash length 7: ~152m
    { precision: 8, widthKm: 0.038 },  // Geohash length 8: ~38m
    { precision: 9, widthKm: 0.005 }   // Geohash length 9: ~5m
  ];
  
  // Find the appropriate precision for the given radius
  for (let i = 0; i < precisionMap.length; i++) {
    if (radiusKm > precisionMap[i].widthKm) {
      return Math.max(1, precisionMap[i].precision);
    }
  }
  
  return 9; // Default to highest precision
}

/**
 * Calculates the neighboring geohashes for a given geohash
 * This is useful for querying locations that might be close to the edge of a geohash
 * @param {string} geohash - The center geohash
 * @returns {string[]} Array of neighboring geohashes
 */
function getGeohashNeighbors(geohash) {
  const neighbors = [];
  const precision = geohash.length;
  
  // Decode the geohash to get its bounding box
  const { latitude, longitude, latitudeError, longitudeError } = decodeGeohash(geohash);
  
  // Calculate the neighboring geohashes in all 8 directions
  const latDelta = latitudeError * 2;
  const lngDelta = longitudeError * 2;
  
  const neighborCoords = [
    { lat: latitude + latDelta, lng: longitude }, // north
    { lat: latitude + latDelta, lng: longitude + lngDelta }, // northeast
    { lat: latitude, lng: longitude + lngDelta }, // east
    { lat: latitude - latDelta, lng: longitude + lngDelta }, // southeast
    { lat: latitude - latDelta, lng: longitude }, // south
    { lat: latitude - latDelta, lng: longitude - lngDelta }, // southwest
    { lat: latitude, lng: longitude - lngDelta }, // west
    { lat: latitude + latDelta, lng: longitude - lngDelta } // northwest
  ];
  
  // Encode each neighboring coordinate to a geohash
  for (const coord of neighborCoords) {
    if (coord.lat >= -90 && coord.lat <= 90 && coord.lng >= -180 && coord.lng <= 180) {
      neighbors.push(encodeGeohash(coord.lat, coord.lng, precision));
    }
  }
  
  return neighbors;
}

/**
 * Decodes a geohash to its latitude/longitude bounds
 * @param {string} geohash - The geohash to decode
 * @returns {Object} Object containing latitude, longitude, and error margins
 */
function decodeGeohash(geohash) {
  let isEven = true;
  let latMin = -90;
  let latMax = 90;
  let lngMin = -180;
  let lngMax = 180;
  
  for (let i = 0; i < geohash.length; i++) {
    const c = geohash[i];
    const cd = BASE32_CHARS.indexOf(c);
    
    for (let j = 4; j >= 0; j--) {
      const mask = 1 << j;
      
      if (isEven) {
        if (cd & mask) {
          lngMin = (lngMin + lngMax) / 2;
        } else {
          lngMax = (lngMin + lngMax) / 2;
        }
      } else {
        if (cd & mask) {
          latMin = (latMin + latMax) / 2;
        } else {
          latMax = (latMin + latMax) / 2;
        }
      }
      
      isEven = !isEven;
    }
  }
  
  const latitude = (latMin + latMax) / 2;
  const longitude = (lngMin + lngMax) / 2;
  const latitudeError = (latMax - latMin) / 2;
  const longitudeError = (lngMax - lngMin) / 2;
  
  return {
    latitude,
    longitude,
    latitudeError,
    longitudeError
  };
}

module.exports = {
  encodeGeohash,
  calculateDistance,
  getPrecisionForRadius,
  getGeohashNeighbors,
  decodeGeohash
};
