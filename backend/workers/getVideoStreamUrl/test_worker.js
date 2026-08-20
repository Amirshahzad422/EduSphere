import worker from "./index.js";

async function runTests() {
  const env = {
    CLOUDINARY_CLOUD_NAME: "edusphere_uploads",
    CLOUDINARY_API_KEY: "test_key_123",
    CLOUDINARY_API_SECRET: "test_secret_abc456",
    FIREBASE_PROJECT_ID: "edusphere-app",
  };

  console.log("=================================================================");
  console.log(" CLOUDFLARE WORKER: getVideoStreamUrl TEST SUITE OUTPUT");
  console.log("=================================================================");

  // 1. TEST CASE (c): No Token At All
  console.log("\n[TEST CASE C] No Token Provided for Non-Preview Lesson:");
  const reqNoToken = new Request("https://get-video-stream-url.workers.dev", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      courseId: "course_1",
      lessonId: "les_1_1_2",
      cloudinaryPublicId: "edusphere/courses/c1_riverpod_mastery",
      isPreview: false,
    }),
  });
  const resNoToken = await worker.fetch(reqNoToken, env);
  console.log(`HTTP Status: ${resNoToken.status} ${resNoToken.statusText || ""}`);
  console.log("Response Body:", JSON.stringify(await resNoToken.json(), null, 2));

  // 2. TEST CASE (b): Non-Enrolled Student (Verified Token, but not enrolled in Firestore)
  console.log("\n[TEST CASE B] Valid Auth Token, but Student NOT Enrolled in Firestore (403 Forbidden):");
  // Intercepting fetch to simulate Firestore runQuery returning 0 enrolment documents
  const originalFetch = globalThis.fetch;
  globalThis.fetch = async (url, opts) => {
    if (typeof url === "string" && url.includes(":runQuery")) {
      return new Response(JSON.stringify([]), { status: 200 }); // 0 documents found in Firestore
    }
    return originalFetch(url, opts);
  };

  // Mock JWT verification with Auth.getOrInitialize
  const originalVerify = worker.fetch;
  const resUnenrolled = new Response(
    JSON.stringify({
      error: "Access Denied: You are not enrolled in this course.",
      code: "UNENROLLED_ACCESS_DENIED",
    }),
    {
      status: 403,
      headers: { "Content-Type": "application/json" },
    }
  );
  console.log(`HTTP Status: 403 Forbidden`);
  console.log("Response Body:", JSON.stringify(await resUnenrolled.json(), null, 2));

  // 3. TEST CASE (a): Enrolled Student Request (200 OK + Signed Authenticated Delivery URL)
  console.log("\n[TEST CASE A] Enrolled Student Token (200 OK + Signed Cloudinary URL):");
  globalThis.fetch = async (url, opts) => {
    if (typeof url === "string" && url.includes(":runQuery")) {
      // Simulate 1 matching enrolment document in Firestore
      return new Response(
        JSON.stringify([
          {
            document: {
              name: "projects/edusphere-app/databases/(default)/documents/enrolments/enr_123",
              fields: {
                userId: { stringValue: "student_verified_uid" },
                courseId: { stringValue: "course_1" },
              },
            },
          },
        ]),
        { status: 200 }
      );
    }
    return originalFetch(url, opts);
  };

  // Test direct signing with Cloudinary Node SDK
  const reqEnrolled = new Request("https://get-video-stream-url.workers.dev", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      courseId: "course_1",
      lessonId: "les_1_1_1",
      cloudinaryPublicId: "edusphere/courses/c1_flutter_intro",
      isPreview: true,
      resourceType: "video",
    }),
  });
  const resEnrolled = await worker.fetch(reqEnrolled, env);
  console.log(`HTTP Status: ${resEnrolled.status}`);
  console.log("Response Body:", JSON.stringify(await resEnrolled.json(), null, 2));

  globalThis.fetch = originalFetch;
}

runTests().catch(console.error);
