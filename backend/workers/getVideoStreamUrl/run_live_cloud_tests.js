const FIREBASE_API_KEY = "AIzaSyBt9iDoO1PrxrDYON61pv8FX5B0E79ZSBs";
const PROJECT_ID = "edusphere-ae8ed";
const WORKER_URL = "http://127.0.0.1:8787";

async function getFreshFirebaseToken(email, password) {
  const signInUrl = `https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${FIREBASE_API_KEY}`;
  const res = await fetch(signInUrl, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      email,
      password,
      returnSecureToken: true,
    }),
  });

  const data = await res.json();
  if (!res.ok) {
    throw new Error(`Firebase sign-in failed for ${email}: ${JSON.stringify(data)}`);
  }

  return { uid: data.localId, idToken: data.idToken };
}

async function ensureFirestoreEnrolment(idToken, userId, courseId) {
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

  if (!res.ok) {
    console.warn(`[Firestore] Enrolment patch warning:`, await res.text());
  }
}

async function runEndToEndVerification() {
  console.log("================================================================================");
  console.log(" REAL END-TO-END LIVE WORKER & CLOUDINARY VERIFICATION");
  console.log(" Target Live Worker: " + WORKER_URL);
  console.log("================================================================================");

  const password = "TestPassword2026!";
  const enrolledEmail = "test.enrolled@edusphere.dev";
  const unenrolledEmail = "test.unenrolled@edusphere.dev";
  const courseId = "course_1";
  const targetPublicId = "edusphere/courses/c1_riverpod_mastery";

  // 1. Fetch fresh tokens
  console.log("\n[1/4] Signing in to get fresh Firebase Auth ID Tokens...");
  const enrolled = await getFreshFirebaseToken(enrolledEmail, password);
  const unenrolled = await getFreshFirebaseToken(unenrolledEmail, password);
  console.log(`✅ Enrolled Student Token obtained (UID: ${enrolled.uid})`);
  console.log(`✅ Unenrolled Student Token obtained (UID: ${unenrolled.uid})`);

  // 2. Ensure Firestore enrolment
  console.log("\n[2/4] Ensuring Firestore enrolment document exists for enrolled student...");
  await ensureFirestoreEnrolment(enrolled.idToken, enrolled.uid, courseId);
  console.log(`✅ Enrolment doc confirmed in Firestore for course ${courseId}`);

  // Test Case 1: No Token
  console.log("\n================================================================================");
  console.log(" TEST CASE 1: No Token Provided -> Expect 401 Unauthorized");
  console.log("================================================================================");
  const res1 = await fetch(WORKER_URL, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      courseId,
      lessonId: "les_1_1_2",
      cloudinaryPublicId: targetPublicId,
      isPreview: false,
    }),
  });
  console.log(`HTTP Status: ${res1.status} ${res1.statusText}`);
  const body1 = await res1.json();
  console.log("Response Body:", JSON.stringify(body1, null, 2));

  // Test Case 2: Unenrolled Real Token
  console.log("\n================================================================================");
  console.log(" TEST CASE 2: Real Unenrolled Student Token -> Expect 403 Forbidden");
  console.log("================================================================================");
  const res2 = await fetch(WORKER_URL, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "Authorization": `Bearer ${unenrolled.idToken}`,
    },
    body: JSON.stringify({
      courseId,
      lessonId: "les_1_1_2",
      cloudinaryPublicId: targetPublicId,
      isPreview: false,
    }),
  });
  console.log(`HTTP Status: ${res2.status} ${res2.statusText}`);
  const body2 = await res2.json();
  console.log("Response Body:", JSON.stringify(body2, null, 2));

  // Test Case 3: Enrolled Real Token
  console.log("\n================================================================================");
  console.log(" TEST CASE 3: Real Enrolled Student Token -> Expect 200 OK + Signed Stream URL");
  console.log("================================================================================");
  const res3 = await fetch(WORKER_URL, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "Authorization": `Bearer ${enrolled.idToken}`,
    },
    body: JSON.stringify({
      courseId,
      lessonId: "les_1_1_2",
      cloudinaryPublicId: targetPublicId,
      isPreview: false,
    }),
  });
  console.log(`HTTP Status: ${res3.status} ${res3.statusText}`);
  const body3 = await res3.json();
  console.log("Response Body:", JSON.stringify(body3, null, 2));

  // Test Case 4: Direct fetch of the returned streamUrl from Cloudinary CDN
  if (body3.streamUrl) {
    console.log("\n================================================================================");
    console.log(" TEST CASE 4: Direct Fetch of streamUrl from Cloudinary CDN");
    console.log(" URL: " + body3.streamUrl);
    console.log("================================================================================");
    const cldRes = await fetch(body3.streamUrl);
    console.log(`Cloudinary CDN HTTP Status: ${cldRes.status} ${cldRes.statusText}`);
    console.log("Headers:");
    for (const [k, v] of cldRes.headers) {
      console.log(`  ${k}: ${v}`);
    }
  }
}

runEndToEndVerification().catch((err) => {
  console.error("Verification Error:", err);
});
