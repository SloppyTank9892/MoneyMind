const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();

// Helper function to calculate financial stress index for a user
async function calculateStressIndex(uid) {
  const userDoc = await db.collection("users").doc(uid).get();
  const userData = userDoc.data();
  
  // Only process students
  if (!userData || userData.role !== "student") return null;

  // 1. Fetch Profile
  const profileSnap = await db.collection("users").doc(uid).collection("private").doc("profile").get();
  const profile = profileSnap.data() || {};
  
  // 2. Fetch recent moods (last 7 days for better accuracy)
  const sevenDaysAgo = admin.firestore.Timestamp.fromMillis(Date.now() - 7 * 86400000);
  const moodSnap = await db.collection("users").doc(uid).collection("private").doc("moods")
    .collection("entries")
    .where("time", ">", sevenDaysAgo)
    .get();

  // 3. Fetch recent spending (last 7 days)
  const spendingSnap = await db.collection("users").doc(uid).collection("private").doc("spending")
    .collection("entries")
    .where("time", ">", sevenDaysAgo)
    .get();

  // === CORE LOGIC: FINANCIAL STRESS INDEX ===
  let stressScore = 30; // Base baseline

  // Factor 1: Moods (weighted by recency - more recent = higher weight)
  let moodCount = 0;
  moodSnap.forEach(doc => {
    const data = doc.data();
    const daysAgo = (Date.now() - data.time.toMillis()) / (1000 * 60 * 60 * 24);
    const recencyWeight = Math.max(0.5, 1 - (daysAgo / 7)); // More recent = higher weight
    
    if (data.mood === "Stressed" || data.mood === "Anxious") stressScore += 10 * recencyWeight;
    if (data.money === "Worried" || data.money === "Guilty") stressScore += 15 * recencyWeight;
    if (data.moneyCausedStress) stressScore += 20 * recencyWeight;
    moodCount++;
  });

  // Factor 2: Spending Behavior
  let unplannedSpend = 0;
  let totalUnplannedCount = 0;
  spendingSnap.forEach(doc => {
    const data = doc.data();
    // Check both field names for compatibility
    const isUnplanned = data.isPlanned === false || data.planned === false;
    if (isUnplanned) {
      const daysAgo = (Date.now() - data.time.toMillis()) / (1000 * 60 * 60 * 24);
      const recencyWeight = Math.max(0.5, 1 - (daysAgo / 7));
      stressScore += 5 * recencyWeight; // Impulse spending increases stress index
      unplannedSpend += (data.amount || 0);
      totalUnplannedCount++;
    }
  });

  // Factor 3: Triggers
  const triggers = profile.stressTriggers || [];
  if (triggers.includes("Exams")) {
    stressScore += 10; 
  }
  if (triggers.includes("Financial Insecurity")) {
    stressScore += 15;
  }

  // Factor 4: Spending frequency (more frequent unplanned spending = higher stress)
  if (totalUnplannedCount > 5) stressScore += 10;
  if (totalUnplannedCount > 10) stressScore += 10;

  // Cap at 100
  if (stressScore > 100) stressScore = 100;
  if (stressScore < 0) stressScore = 0;

  // Determine Risk Level
  let riskLevel = "Low";
  if (stressScore > 75) riskLevel = "High";
  else if (stressScore > 40) riskLevel = "Medium";

  // Money Personality (Simple logic)
  let personality = "Balanced";
  if (unplannedSpend > 1000 && stressScore > 60) personality = "Stress Spender";
  else if (stressScore > 80 && unplannedSpend < 500) personality = "Anxious Saver";
  else if (unplannedSpend > 2000) personality = "Impulsive";
  else if (moodCount === 0 && spendingSnap.empty) personality = "New User";

  // Predict Risk Window (Simple logic: next 3 days if high stress)
  let predictedWindow = null;
  if (riskLevel === "High" || riskLevel === "Medium") {
    predictedWindow = "Next 3 Days";
  }

  const summaryData = {
    financialStressIndex: stressScore,
    riskLevel: riskLevel,
    moneyPersonality: personality,
    triggerTypes: triggers,
    predictedRiskWindow: predictedWindow,
    lastUpdated: admin.firestore.FieldValue.serverTimestamp()
  };

  // Update Student's View
  await db.collection("users").doc(uid).collection("features").doc("summary").set(summaryData, { merge: true });

  // Update University Admin's View (Copy)
  if (userData.university_id) {
    await db.collection("universities").doc(userData.university_id)
      .collection("students").doc(uid)
      .collection("features").doc("summary")
      .set(summaryData, { merge: true });
      
    // Also ensure the student exists in the uni list
    await db.collection("universities").doc(userData.university_id)
      .collection("students").doc(uid)
      .set({
         uid: uid,
         lastUpdated: admin.firestore.FieldValue.serverTimestamp()
      }, { merge: true });
  }

  return summaryData;
}

// Scheduled function that runs daily
exports.dailyStressEngine = functions.pubsub.schedule("every 24 hours").onRun(async (context) => {
  const usersSnapshot = await db.collection("users").get();
  const promises = usersSnapshot.docs.map(async (userDoc) => {
    await calculateStressIndex(userDoc.id);
  });
  await Promise.all(promises);
});

// Callable function for real-time recalculation
exports.recalculateStressIndex = functions.https.onCall(async (data, context) => {
  // Verify user is authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const uid = context.auth.uid;
  const result = await calculateStressIndex(uid);
  
  if (!result) {
    throw new functions.https.HttpsError('not-found', 'User not found or not a student');
  }

  return { success: true, financialStressIndex: result.financialStressIndex };
});
