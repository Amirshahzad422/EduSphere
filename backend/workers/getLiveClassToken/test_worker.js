import worker from "./index.js";

async function runTests() {
  console.log("🧪 Testing getLiveClassToken Worker...");

  const mockEnv = {
    FIREBASE_PROJECT_ID: "edusphere-ae8ed",
    JAAS_APP_ID: "vpaas-magic-cookie-5c5675ce628e421aafac215917f37316",
    JAAS_API_KEY_ID: "vpaas-magic-cookie-5c5675ce628e421aafac215917f37316/key1",
  };

  // Test 1: OPTIONS CORS Preflight
  const corsReq = new Request("http://localhost/token", { method: "OPTIONS" });
  const corsRes = await worker.fetch(corsReq, mockEnv);
  console.assert(corsRes.status === 200, "CORS status should be 200");
  console.log("✅ CORS preflight passed");

  // Test 2: POST generate token
  const postReq = new Request("http://localhost/token", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      classId: "class_ml_101",
      courseId: "course_flutter_master",
      roomName: "live_flutter_master_session",
      userId: "user_sarah_123",
      userName: "Dr. Sarah Chen",
      userEmail: "sarah@edusphere.io",
      isInstructor: true,
    }),
  });

  const postRes = await worker.fetch(postReq, mockEnv);
  const data = await postRes.json();
  console.log("Response data:", data);
  console.assert(postRes.status === 200, "POST status should be 200");
  console.assert(data.success === true, "data.success should be true");
  console.assert(data.room === "live_flutter_master_session", "room name should match");
  console.assert(data.appId === "vpaas-magic-cookie-5c5675ce628e421aafac215917f37316", "appId should match");
  console.assert(data.isModerator === true, "isModerator should be true");

  console.log("🎉 All getLiveClassToken worker tests passed!");
}

runTests().catch((err) => {
  console.error("❌ Test failed:", err);
  process.exit(1);
});
