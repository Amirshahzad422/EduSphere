import worker from "./index.js";

const FIREBASE_API_KEY = "AIzaSyBt9iDoO1PrxrDYON61pv8FX5B0E79ZSBs";
const PROJECT_ID = "edusphere-ae8ed";

async function getOrRegisterFirebaseUser(email, password) {
  console.log(`\n[Firebase Auth] Authenticating user: ${email}...`);
  const signInUrl = `https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${FIREBASE_API_KEY}`;
  
  let res = await fetch(signInUrl, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      email,
      password,
      returnSecureToken: true,
    }),
  });

  let data = await res.json();
  if (res.ok) {
    console.log(`[Firebase Auth] ✅ Signed in: ${email} (UID: ${data.localId})`);
    return { uid: data.localId, idToken: data.idToken };
  }

  // If user does not exist, sign up
  console.log(`[Firebase Auth] Account not found, creating new account: ${email}...`);
  const signUpUrl = `https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=${FIREBASE_API_KEY}`;
  res = await fetch(signUpUrl, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      email,
      password,
      returnSecureToken: true,
    }),
  });

  const parts = data.idToken.split(".");
  const header = JSON.parse(Buffer.from(parts[0], "base64").toString("utf-8"));
  const payload = JSON.parse(Buffer.from(parts[1], "base64").toString("utf-8"));
  console.log(`[Firebase Auth] Decoded JWT Header:`, header);
  console.log(`[Firebase Auth] Decoded JWT Payload: iss=${payload.iss}, aud=${payload.aud}, sub=${payload.sub}, exp=${payload.exp}`);
}

async function createFirestoreEnrolment(idToken, userId, courseId) {
  console.log(`\n[Firestore] Creating real enrolment doc for userId: ${userId} in course: ${courseId}...`);
  const docId = `enr_live_test_${userId}_${courseId}`;
  const firestoreUrl = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents/enrolments/${docId}`;

  const payload = {
    fields: {
      userId: { stringValue: userId },
      courseId: { stringValue: courseId },
      enrolledAt: { timestampValue: new Date().toISOString() },
      progress: { integerValue: 0 },
      completedLessons: { arrayValue: { values: [] } },
    },
  };

  const res = await fetch(firestoreUrl, {
    method: "PATCH",
    headers: {
      "Content-Type": "application/json",
      "Authorization": `Bearer ${idToken}`,
    },
    body: JSON.stringify(payload),
  });

  const data = await res.json();
  if (res.ok) {
    console.log(`[Firestore] ✅ Created enrolment document: ${docId}`);
  } else {
    console.warn(`[Firestore] Enrolment create status ${res.status}:`, data);
  }
}

async function runLiveVerification() {
  console.log("=================================================================");
  console.log(" REAL END-TO-END VERIFICATION: Firebase Auth + Firestore + Worker");
  console.log("=================================================================");

  const password = "TestPassword2026!";
  const enrolledEmail = "test.enrolled@edusphere.dev";
  const unenrolledEmail = "test.unenrolled@edusphere.dev";
  const courseId = "course_1";

  // Step 1 & 2: Real Firebase Auth Sign In / Registration
  const enrolledUser = await getOrRegisterFirebaseUser(enrolledEmail, password);
  const unenrolledUser = await getOrRegisterFirebaseUser(unenrolledEmail, password);

  // Step 3: Real Firestore Enrolment Creation
  await createFirestoreEnrolment(enrolledUser.idToken, enrolledUser.uid, courseId);

  const env = {
    CLOUDINARY_CLOUD_NAME: "edusphere_uploads",
    CLOUDINARY_API_KEY: "test_key_123",
    CLOUDINARY_API_SECRET: "test_secret_abc456",
    FIREBASE_PROJECT_ID: PROJECT_ID,
  };

  // Step 4: Run Worker verification for both real tokens
  console.log("\n=================================================================");
  console.log(" 4. WORKER RESPONSES FOR REAL ID TOKENS");
  console.log("=================================================================");

  // (A) Enrolled User Request
  console.log("\n--- TEST (A): Enrolled User Token Request ---");
  const reqEnrolled = new Request("http://127.0.0.1:8787", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "Authorization": `Bearer ${enrolledUser.idToken}`,
    },
    body: JSON.stringify({
      courseId: courseId,
      lessonId: "les_1_1_2",
      cloudinaryPublicId: "edusphere/courses/c1_riverpod_mastery",
      isPreview: false,
    }),
  });
  const resEnrolled = await worker.fetch(reqEnrolled, env);
  const bodyEnrolled = await resEnrolled.json();
  console.log(`HTTP Status: ${resEnrolled.status}`);
  console.log("Response Body:", JSON.stringify(bodyEnrolled, null, 2));

  // (B) Unenrolled User Request
  console.log("\n--- TEST (B): Unenrolled User Token Request ---");
  const reqUnenrolled = new Request("http://127.0.0.1:8787", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "Authorization": `Bearer ${unenrolledUser.idToken}`,
    },
    body: JSON.stringify({
      courseId: courseId,
      lessonId: "les_1_1_2",
      cloudinaryPublicId: "edusphere/courses/c1_riverpod_mastery",
      isPreview: false,
    }),
  });
  const resUnenrolled = await worker.fetch(reqUnenrolled, env);
  const bodyUnenrolled = await resUnenrolled.json();
  console.log(`HTTP Status: ${resUnenrolled.status}`);
  console.log("Response Body:", JSON.stringify(bodyUnenrolled, null, 2));

  // (C) Missing Token Request
  console.log("\n--- TEST (C): Missing Authorization Header ---");
  const reqNoToken = new Request("http://127.0.0.1:8787", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      courseId: courseId,
      lessonId: "les_1_1_2",
      cloudinaryPublicId: "edusphere/courses/c1_riverpod_mastery",
      isPreview: false,
    }),
  });
  const resNoToken = await worker.fetch(reqNoToken, env);
  const bodyNoToken = await resNoToken.json();
  console.log(`HTTP Status: ${resNoToken.status}`);
  console.log("Response Body:", JSON.stringify(bodyNoToken, null, 2));
}

runLiveVerification().catch((err) => {
  console.error("Live Verification Error:", err);
});
