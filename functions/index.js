const functions = require("firebase-functions");
const admin = require("firebase-admin");
const geohash = require("ngeohash");

admin.initializeApp();
const db = admin.firestore();

/**
 * 1. Push Notifications: Triggered when new food listing is posted.
 * Sends FCM push notification to receivers registered within a 5 km radius.
 */
exports.onFoodListingCreated = functions.firestore
  .document("food_listings/{listingId}")
  .onCreate(async (snap, context) => {
    const listing = snap.data();
    if (!listing || listing.status !== "available") return null;

    const { title, quantity, category, location, providerName } = listing;
    if (!location || !location.geohash) return null;

    // 5 km radius geohash precision ~ 5-6 characters
    // Using a 5-char geohash prefix (~4.9km x ~4.9km bounding box)
    const geoPrefix = location.geohash.substring(0, 5);
    const neighbors = geohash.neighbors(geoPrefix);
    const searchHashes = [geoPrefix, ...neighbors];

    try {
      // Find receivers whose geohash starts within these neighbor blocks
      // Note: In production, store tokens in user document or a fcm_tokens collection
      const userTokens = [];
      const userDocs = await db.collection("users")
        .where("role", "==", "receiver")
        .where("notificationsEnabled", "==", true)
        .get();

      userDocs.forEach((doc) => {
        const u = doc.data();
        if (u.fcmToken && u.location && u.location.geohash) {
          const userPrefix = u.location.geohash.substring(0, 5);
          if (searchHashes.includes(userPrefix)) {
            userTokens.push(u.fcmToken);
          }
        }
      });

      if (userTokens.length === 0) {
        console.log("No recipient devices found in 5 km radius.");
        return null;
      }

      const payload = {
        notification: {
          title: "Surplus Food Alert Nearby! 🍲",
          body: `${providerName} just listed ${quantity.value} ${quantity.unit} of ${title} (${category.toUpperCase()}). Claim now before it expires!`,
        },
        data: {
          listingId: context.params.listingId,
          click_action: "FLUTTER_NOTIFICATION_CLICK",
          category: category,
          lat: String(location.lat),
          lng: String(location.lng),
        },
      };

      // Send to registered device tokens in batches
      const response = await admin.messaging().sendEachForMulticast({
        tokens: userTokens,
        notification: payload.notification,
        data: payload.data,
      });

      console.log(`Dispatched ${response.successCount} notifications for listing: ${context.params.listingId}`);
      return response;
    } catch (error) {
      console.error("Error sending 5km proximity push notifications:", error);
      return null;
    }
  });

/**
 * 2. Auto-Expiry Logic: Scheduled cron to automatically mark food expired.
 * Runs every 5 minutes to sweep stale food so unsafe food is never visible.
 */
exports.scheduledAutoExpiry = functions.pubsub
  .schedule("every 5 minutes")
  .onRun(async (context) => {
    const now = admin.firestore.Timestamp.now();

    try {
      const snapshot = await db.collection("food_listings")
        .where("status", "==", "available")
        .where("bestBefore", "<=", now)
        .get();

      if (snapshot.empty) {
        return null;
      }

      const batch = db.batch();
      snapshot.forEach((doc) => {
        batch.update(doc.ref, {
          status: "expired",
          expiredAt: now,
          updatedAt: now,
        });
      });

      await batch.commit();
      console.log(`Auto-expired ${snapshot.size} listings past bestBefore timestamp.`);
      return null;
    } catch (error) {
      console.error("Error running auto-expiry task:", error);
      return null;
    }
  });

/**
 * 3. Lock Release Daemon: Reclaims abandoned reservations after 30-min window.
 * If a receiver claims food but does not complete pickup within 30 minutes,
 * this function automatically resets the quantity back to available.
 */
exports.scheduledClaimLockTimeout = functions.pubsub
  .schedule("every 5 minutes")
  .onRun(async (context) => {
    const now = admin.firestore.Timestamp.now();

    try {
      const expiredLocks = await db.collection("claims")
        .where("status", "==", "locked")
        .where("lockedUntil", "<=", now)
        .get();

      if (expiredLocks.empty) return null;

      for (const claimDoc of expiredLocks.docs) {
        const claim = claimDoc.data();
        const listingRef = db.collection("food_listings").doc(claim.listingId);

        await db.runTransaction(async (transaction) => {
          const listingSnap = await transaction.get(listingRef);
          if (!listingSnap.exists) return;

          const listing = listingSnap.data();
          const restoredQty = (listing.remainingQuantity?.value || 0) + (claim.claimedQuantity?.value || 0);

          // Update listing to restore quantity
          transaction.update(listingRef, {
            "remainingQuantity.value": restoredQty,
            status: restoredQty > 0 ? "available" : listing.status,
            updatedAt: now,
          });

          // Mark claim expired
          transaction.update(claimDoc.ref, {
            status: "expired",
            updatedAt: now,
            expirationReason: "30-minute pickup window elapsed",
          });
        });
      }

      console.log(`Processed ${expiredLocks.size} timed-out claim reservations.`);
      return null;
    } catch (error) {
      console.error("Error checking claim lock timeouts:", error);
      return null;
    }
  });
