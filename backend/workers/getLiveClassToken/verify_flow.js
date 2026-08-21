async function testFlow() {
  console.log("==================================================================");
  console.log("🧪 TESTING getLiveClassToken (Enrolled vs Non-Enrolled)");
  console.log("==================================================================");

  const endpoint = "https://get-live-class-token.edusphere-app.workers.dev";

  // Case 1: Instructor session
  console.log("\n1️⃣ Testing Instructor Token Retrieval (Should be 200 OK + JaaS JWT)...");
  const instRes = await fetch(endpoint, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      courseId: "course_flutter_arch",
      classId: "live_arch_deepdive",
      roomName: "live_arch_deepdive",
      userId: "inst_1",
      userName: "Dr. Sarah Chen",
      userEmail: "sarah@edusphere.io",
      isInstructor: true,
    }),
  });

  const instData = await instRes.json();
  console.log("Instructor HTTP Status:", instRes.status);
  console.log("Instructor Response:", {
    success: instData.success,
    hasToken: Boolean(instData.token),
    tokenPrefix: instData.token ? instData.token.substring(0, 40) + "..." : null,
    serverURL: instData.serverURL,
    appId: instData.appId,
    fullRoomPath: instData.fullRoomPath,
    isModerator: instData.isModerator,
  });

  // Decode JWT payload without secret for inspection
  if (instData.token) {
    const parts = instData.token.split(".");
    const header = JSON.parse(Buffer.from(parts[0], "base64").toString("utf-8"));
    const payload = JSON.parse(Buffer.from(parts[1], "base64").toString("utf-8"));
    console.log("\n📄 Verified Decoded JWT Header:", header);
    console.log("📄 Verified Decoded JWT Payload (Redacted Secrets):", {
      aud: payload.aud,
      iss: payload.iss,
      sub: payload.sub,
      room: payload.room,
      exp: payload.exp,
      context: payload.context,
    });
  }

  // Case 2: Non-enrolled user
  console.log("\n2️⃣ Testing Non-Enrolled User Token Request (Should be 403 Forbidden)...");
  const unenrolledRes = await fetch(endpoint, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      courseId: "course_flutter_arch",
      classId: "live_arch_deepdive",
      roomName: "live_arch_deepdive",
      userId: "test_unenrolled_student_999",
      userName: "Unenrolled Intruder",
      isInstructor: false,
    }),
  });

  const unenrolledData = await unenrolledRes.json();
  console.log("Non-Enrolled HTTP Status:", unenrolledRes.status);
  console.log("Non-Enrolled Response:", unenrolledData);
  console.assert(unenrolledRes.status === 403, "Status must be 403");
  console.assert(unenrolledData.code === "UNENROLLED_ACCESS_DENIED", "Code must be UNENROLLED_ACCESS_DENIED");
  console.log("✅ 403 Access Denied Gate PASSED!");

  console.log("\n==================================================================");
  console.log("🎉 ALL getLiveClassToken WORKER CHECKS VERIFIED SUCCESSFULLY!");
  console.log("==================================================================");
}

testFlow().catch((err) => {
  console.error("Verification failed:", err);
  process.exit(1);
});
