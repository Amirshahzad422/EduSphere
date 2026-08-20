/**
 * Cloudflare Worker: getVideoStreamUrl & getResourceUrl
 * 
 * Free-tier serverless microservice (100,000 requests/day, NO card required).
 * 1. Cryptographically verifies Firebase Auth ID Token using firebase-auth-cloudflare-workers.
 * 2. Authenticates and queries Cloud Firestore runQuery for (userId == verifiedUid && courseId == courseId), failing CLOSED.
 * 3. Generates Cloudinary delivery URLs via native Web Crypto API (0 Node fs dependencies, 100% Worker native).
 */

if (typeof globalThis.__dirname === "undefined") {
  globalThis.__dirname = "/";
}
if (typeof globalThis.__filename === "undefined") {
  globalThis.__filename = "/index.js";
}

import { Auth, WorkersKVStoreSingle } from "firebase-auth-cloudflare-workers";
import { v2 as cloudinary } from "cloudinary";

// In-memory fallback key store when KV namespace is not bound
class InMemoryKeyStore {
  constructor() {
    this.cache = null;
    this.expiry = 0;
  }
  async get() {
    if (this.cache && Date.now() < this.expiry) {
      return this.cache;
    }
    return null;
  }
  async put(value, expirationTtl) {
    this.cache = typeof value === "string" ? JSON.parse(value) : value;
    this.expiry = Date.now() + (expirationTtl || 3600) * 1000;
  }
}

const fallbackKeyStore = new InMemoryKeyStore();

export default {
  async fetch(request, env) {
    // 1. Handle CORS preflight
    if (request.method === "OPTIONS") {
      return new Response(null, {
        headers: {
          "Access-Control-Allow-Origin": "*",
          "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
          "Access-Control-Allow-Headers": "Content-Type, Authorization",
        },
      });
    }

    if (request.method !== "POST") {
      return new Response(JSON.stringify({ error: "Method not allowed" }), {
        status: 405,
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*",
        },
      });
    }

    try {
      const body = await request.json();
      const { courseId, lessonId, cloudinaryPublicId, isPreview, resourceType = "video" } = body;

      if (!cloudinaryPublicId && !lessonId) {
        return new Response(JSON.stringify({ error: "Missing resource or lesson identifier" }), {
          status: 400,
          headers: {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
          },
        });
      }

      const targetPublicId = cloudinaryPublicId || `courses/${courseId}/${lessonId}`;

      // 2. Free Preview handling (public type: upload asset URL without worker access checks)
      if (isPreview === true) {
        const previewUrl = await generateCloudinarySignedUrl(env, targetPublicId, resourceType, true);

        return new Response(
          JSON.stringify({
            streamUrl: previewUrl,
            isPreview: true,
            resourceType,
          }),
          {
            status: 200,
            headers: {
              "Content-Type": "application/json",
              "Access-Control-Allow-Origin": "*",
            },
          }
        );
      }

      // 3. Extract and Verify Firebase Auth ID Token from Authorization header
      const authHeader = request.headers.get("Authorization") || "";
      const idToken = authHeader.replace(/^Bearer\s+/i, "").trim();

      if (!idToken) {
        return new Response(
          JSON.stringify({
            error: "Unauthorized: Missing Firebase Auth ID token in Authorization header.",
            code: "MISSING_AUTH_TOKEN",
          }),
          {
            status: 401,
            headers: {
              "Content-Type": "application/json",
              "Access-Control-Allow-Origin": "*",
            },
          }
        );
      }

      const keyStore = env.PUBLIC_JWK_CACHE_KV
        ? WorkersKVStoreSingle.getOrInitialize(env.PUBLIC_JWK_CACHE_KEY || "firebase_jwks", env.PUBLIC_JWK_CACHE_KV)
        : fallbackKeyStore;

      const auth = Auth.getOrInitialize(
        env.FIREBASE_PROJECT_ID || "edusphere-ae8ed",
        keyStore
      );

      let decodedToken;
      try {
        decodedToken = await auth.verifyIdToken(idToken, false, env);
      } catch (err) {
        return new Response(
          JSON.stringify({
            error: "Unauthorized: Invalid or expired Firebase Auth ID token.",
            code: "INVALID_AUTH_TOKEN",
          }),
          {
            status: 401,
            headers: {
              "Content-Type": "application/json",
              "Access-Control-Allow-Origin": "*",
            },
          }
        );
      }

      const verifiedUid = decodedToken.uid || decodedToken.sub;
      if (!verifiedUid) {
        return new Response(
          JSON.stringify({
            error: "Unauthorized: Verified token contains no valid UID.",
            code: "INVALID_UID",
          }),
          {
            status: 401,
            headers: {
              "Content-Type": "application/json",
              "Access-Control-Allow-Origin": "*",
            },
          }
        );
      }

      // 4. Authenticated Firestore Enrolment Verification (Strict FAIL CLOSED)
      const isEnrolled = await verifyFirestoreEnrolment(
        env.FIREBASE_PROJECT_ID || "edusphere-ae8ed",
        courseId,
        verifiedUid,
        idToken
      );

      if (!isEnrolled) {
        return new Response(
          JSON.stringify({
            error: "Access Denied: You are not enrolled in this course.",
            code: "UNENROLLED_ACCESS_DENIED",
          }),
          {
            status: 403,
            headers: {
              "Content-Type": "application/json",
              "Access-Control-Allow-Origin": "*",
            },
          }
        );
      }

      // 5. Generate delivery URL
      const signedDeliveryUrl = await generateCloudinarySignedUrl(
        env,
        targetPublicId,
        resourceType,
        false
      );

      return new Response(
        JSON.stringify({
          streamUrl: signedDeliveryUrl,
          publicId: targetPublicId,
          resourceType,
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
        JSON.stringify({ error: err.message || "Internal server error" }),
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

/**
 * Authenticated Firestore Enrolment Verification
 * Queries Firestore REST API: runQuery for (userId == verifiedUid && courseId == courseId)
 * FAILS CLOSED: Returns false on any error, non-200 status, or empty query result.
 */
async function verifyFirestoreEnrolment(projectId, courseId, verifiedUid, idToken) {
  if (!verifiedUid || !courseId || !idToken) {
    return false; // FAIL CLOSED
  }

  try {
    const firestoreUrl = `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents:runQuery`;
    const queryPayload = {
      structuredQuery: {
        from: [{ collectionId: "enrolments" }],
        where: {
          compositeFilter: {
            op: "AND",
            filters: [
              {
                fieldFilter: {
                  field: { fieldPath: "userId" },
                  op: "EQUAL",
                  value: { stringValue: verifiedUid },
                },
              },
              {
                fieldFilter: {
                  field: { fieldPath: "courseId" },
                  op: "EQUAL",
                  value: { stringValue: courseId },
                },
              },
            ],
          },
        },
        limit: 1,
      },
    };

    const response = await fetch(firestoreUrl, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${idToken}`,
      },
      body: JSON.stringify(queryPayload),
    });

    if (!response.ok) {
      return false; // FAIL CLOSED on any non-200 HTTP response
    }

    const data = await response.json();
    if (!Array.isArray(data) || data.length === 0) {
      return false; // FAIL CLOSED if no response documents found
    }

    // The query returns an array of results; a matching document contains the 'document' field
    const hasMatchingDoc = Boolean(data[0] && data[0].document);
    return hasMatchingDoc;
  } catch (_) {
    return false; // FAIL CLOSED on any exception or network failure
  }
}

/**
 * Native Cloudflare Worker HMAC-SHA1 / SHA256 signer for Cloudinary
 * 0 external Node filesystem dependencies, 100% native Web Crypto API.
 */
async function generateCloudinarySignedUrl(env, publicId, resourceType = "video", isPreview = false) {
  const cloudName = env.CLOUDINARY_CLOUD_NAME || "kl8rl0al";
  const ext = resourceType === "raw" ? (publicId.endsWith(".pdf") ? "" : ".pdf") : (publicId.endsWith(".mp4") ? "" : ".mp4");

  if (isPreview) {
    return `https://res.cloudinary.com/${cloudName}/${resourceType}/upload/v1/${publicId}${ext}`;
  }

  // Authenticated assets MUST use signed delivery — NEVER fall back to /upload/
  if (!env.CLOUDINARY_API_SECRET) {
    throw new Error("Missing CLOUDINARY_API_SECRET on worker environment. Worker secrets must be configured via wrangler secret put.");
  }

  try {
    const cleanPublicId = publicId.replace(/\.(mp4|pdf)$/, "");
    const format = resourceType === "raw" ? "pdf" : "mp4";

    console.log("[generateCloudinarySignedUrl] Config check:", {
      hasApiSecret: Boolean(env.CLOUDINARY_API_SECRET),
      apiSecretLength: env.CLOUDINARY_API_SECRET.length,
      cleanPublicId,
      resourceType,
      format,
    });

    // Cloudinary Canonical SHA-1 signing via WebCrypto API
    const toSignStr = `${cleanPublicId}.${format}${env.CLOUDINARY_API_SECRET}`;
    const encoder = new TextEncoder();
    const hashBuffer = await crypto.subtle.digest("SHA-1", encoder.encode(toSignStr));
    const hashArray = Array.from(new Uint8Array(hashBuffer));
    const base64Sig = btoa(String.fromCharCode(...hashArray))
      .substring(0, 8)
      .replace(/\+/g, "-")
      .replace(/\//g, "_");

    const signedUrl = `https://res.cloudinary.com/${cloudName}/${resourceType}/authenticated/s--${base64Sig}--/v1/${cleanPublicId}.${format}`;
    return signedUrl;
  } catch (err) {
    throw new Error("Cloudinary signing failed: " + err.message);
  }
}
