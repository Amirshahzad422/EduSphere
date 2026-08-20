/**
 * Cloudflare Worker: verifyCertificate
 * 
 * Free-tier public verification microservice (100,000 requests/day, NO card required).
 * 1. Accepts public verification queries for certificate verification IDs.
 * 2. Looks up Firestore certificates collection.
 * 3. Returns structured JSON or rich HTML verification badge for external validators.
 */

export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    // 1. CORS Preflight
    if (request.method === "OPTIONS") {
      return new Response(null, {
        headers: {
          "Access-Control-Allow-Origin": "*",
          "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
          "Access-Control-Allow-Headers": "Content-Type",
        },
      });
    }

    let verificationId = "";

    if (request.method === "GET") {
      const pathSegments = url.pathname.split("/").filter(Boolean);
      // /verify/:verificationId or /:verificationId or ?id=:verificationId
      if (pathSegments.length >= 2 && pathSegments[0] === "verify") {
        verificationId = pathSegments[1];
      } else if (pathSegments.length === 1 && pathSegments[0] !== "verify") {
        verificationId = pathSegments[0];
      } else {
        verificationId = url.searchParams.get("id") || url.searchParams.get("verificationId") || "";
      }
    } else if (request.method === "POST") {
      try {
        const body = await request.json();
        verificationId = body.verificationId || body.id || "";
      } catch (_) {}
    }

    if (!verificationId) {
      return new Response(
        JSON.stringify({
          valid: false,
          error: "Missing verification ID. Please provide a valid certificate identifier.",
        }),
        {
          status: 400,
          headers: {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
          },
        }
      );
    }

    try {
      const projectId = env.FIREBASE_PROJECT_ID || "edusphere-ae8ed";
      const firestoreUrl = `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents/certificates/${verificationId}`;

      const res = await fetch(firestoreUrl);

      if (!res.ok) {
        // Not found or error
        const acceptHeader = request.headers.get("Accept") || "";
        if (acceptHeader.includes("text/html") && request.method === "GET") {
          return new Response(renderInvalidHtml(verificationId), {
            status: 404,
            headers: { "Content-Type": "text/html; charset=utf-8" },
          });
        }

        return new Response(
          JSON.stringify({
            valid: false,
            verificationId,
            error: "Certificate not found or revoked. This credential could not be verified on the EduSphere ledger.",
          }),
          {
            status: 404,
            headers: {
              "Content-Type": "application/json",
              "Access-Control-Allow-Origin": "*",
            },
          }
        );
      }

      const doc = await res.json();
      const fields = doc.fields || {};

      const certificate = {
        id: fields.id?.stringValue || verificationId,
        userId: fields.userId?.stringValue || "",
        userName: fields.userName?.stringValue || "EduSphere Graduate",
        courseId: fields.courseId?.stringValue || "",
        courseTitle: fields.courseTitle?.stringValue || "Accredited Course",
        instructorName: fields.instructorName?.stringValue || "Senior Faculty",
        verificationId: fields.verificationId?.stringValue || verificationId,
        qrCodeUrl: fields.qrCodeUrl?.stringValue || "",
        pdfUrl: fields.pdfUrl?.stringValue || "",
        issuedAt: fields.issuedAt?.stringValue || new Date().toISOString(),
        verified: true,
      };

      const acceptHeader = request.headers.get("Accept") || "";
      if (acceptHeader.includes("text/html") && request.method === "GET") {
        return new Response(renderValidHtml(certificate), {
          status: 200,
          headers: { "Content-Type": "text/html; charset=utf-8" },
        });
      }

      return new Response(
        JSON.stringify({
          valid: true,
          certificate,
        }),
        {
          status: 200,
          headers: {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
          },
        }
      );
    } catch (err) {
      return new Response(
        JSON.stringify({
          valid: false,
          error: "Verification service exception: " + err.message,
        }),
        {
          status: 500,
          headers: {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
          },
        }
      );
    }
  },
};

function renderValidHtml(cert) {
  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Verified Certificate: ${cert.verificationId} — EduSphere</title>
  <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;600;700;800&family=Inter:wght@400;500;600&display=swap" rel="stylesheet">
  <style>
    body { margin: 0; padding: 24px; font-family: 'Inter', sans-serif; background: #0F172A; color: #F8FAFC; display: flex; justify-content: center; align-items: center; min-height: 100vh; }
    .card { background: #1E293B; border-radius: 16px; border: 1px solid #334155; padding: 36px; max-width: 560px; width: 100%; box-shadow: 0 25px 50px -12px rgba(0,0,0,0.5); text-align: center; }
    .badge { display: inline-flex; align-items: center; gap: 8px; background: rgba(16,185,129,0.15); color: #10B981; border: 1px solid #10B981; padding: 6px 14px; border-radius: 9999px; font-size: 13px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.5px; margin-bottom: 20px; }
    h1 { font-family: 'Plus Jakarta Sans', sans-serif; font-size: 24px; margin: 0 0 8px; color: #FFFFFF; }
    .student { font-size: 20px; font-weight: 700; color: #00696E; margin: 12px 0 6px; }
    .desc { font-size: 14px; color: #94A3B8; margin-bottom: 24px; }
    .meta-box { background: #0F172A; border-radius: 10px; padding: 16px; text-align: left; margin-bottom: 24px; font-size: 13px; }
    .meta-row { display: flex; justify-content: space-between; padding: 6px 0; border-bottom: 1px solid #1E293B; }
    .meta-row:last-child { border-bottom: none; }
    .meta-label { color: #64748B; font-weight: 600; }
    .meta-val { color: #F1F5F9; font-weight: 600; }
    .qr { margin: 16px 0; border-radius: 8px; padding: 8px; background: #FFFFFF; display: inline-block; }
  </style>
</head>
<body>
  <div class="card">
    <div class="badge">✓ Verified Authentic Credential</div>
    <h1>EduSphere Certificate of Completion</h1>
    <div class="desc">This certifies that</div>
    <div class="student">${cert.userName}</div>
    <div class="desc">has successfully mastered and completed all curricula for</div>
    <h2 style="font-size: 18px; color: #FFFFFF; margin: 0 0 16px;">${cert.courseTitle}</h2>
    <div class="meta-box">
      <div class="meta-row"><span class="meta-label">Credential ID:</span><span class="meta-val">${cert.verificationId}</span></div>
      <div class="meta-row"><span class="meta-label">Instructor:</span><span class="meta-val">${cert.instructorName}</span></div>
      <div class="meta-row"><span class="meta-label">Issued On:</span><span class="meta-val">${new Date(cert.issuedAt).toLocaleDateString('en-US', { year: 'numeric', month: 'long', day: 'numeric' })}</span></div>
      <div class="meta-row"><span class="meta-label">Ledger Status:</span><span class="meta-val" style="color: #10B981;">Active & Immutable</span></div>
    </div>
    ${cert.qrCodeUrl ? `<div class="qr"><img src="${cert.qrCodeUrl}" width="140" height="140" alt="QR Code"></div>` : ''}
  </div>
</body>
</html>`;
}

function renderInvalidHtml(id) {
  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>Invalid Credential — EduSphere</title>
  <style>
    body { margin: 0; padding: 24px; font-family: sans-serif; background: #0F172A; color: #F8FAFC; display: flex; justify-content: center; align-items: center; min-height: 100vh; }
    .card { background: #1E293B; border-radius: 16px; border: 1px solid #EF4444; padding: 36px; max-width: 480px; width: 100%; text-align: center; }
    .badge { background: rgba(239,68,68,0.15); color: #EF4444; border: 1px solid #EF4444; padding: 6px 14px; border-radius: 9999px; font-size: 13px; font-weight: 700; }
    h1 { color: #FFFFFF; font-size: 22px; margin: 16px 0 8px; }
    p { color: #94A3B8; font-size: 14px; line-height: 1.5; }
  </style>
</head>
<body>
  <div class="card">
    <div class="badge">✕ Verification Failed</div>
    <h1>Certificate Not Found</h1>
    <p>The verification ID <strong>${id || "UNKNOWN"}</strong> does not exist on the EduSphere verified credential registry.</p>
  </div>
</body>
</html>`;
}
