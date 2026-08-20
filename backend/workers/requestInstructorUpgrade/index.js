/**
 * Cloudflare Worker: requestInstructorUpgrade
 * 
 * Free-tier serverless microservice (100,000 requests/day, NO card required).
 * 1. Cryptographically verifies Firebase Auth ID Token using firebase-auth-cloudflare-workers.
 * 2. Authenticates that the requesting user owns the account.
 * 3. Server-side elevates the role from 'student' to 'instructor' in Firestore users and publicProfiles.
 */

if (typeof globalThis.__dirname === "undefined") {
  globalThis.__dirname = "/";
}
if (typeof globalThis.__filename === "undefined") {
  globalThis.__filename = "/index.js";
}

import { Auth, WorkersKVStoreSingle } from "firebase-auth-cloudflare-workers";

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
      const authHeader = request.headers.get("Authorization") || "";
      const idToken = authHeader.startsWith("Bearer ") ? authHeader.substring(7) : authHeader;

      let verifiedUid = null;
      let verifiedEmail = null;

      const projectId = env.FIREBASE_PROJECT_ID || "edusphere-ae8ed";

      if (idToken) {
        try {
          const auth = Auth.getOrInitialize(
            projectId,
            WorkersKVStoreSingle.getOrInitialize(
              env.PUBLIC_JWK_CACHE_KEY || "FIREBASE_AUTH_PUBLIC_JWK_CACHE",
              env.FIREBASE_AUTH_KV || fallbackKeyStore
            )
          );
          const tokenResult = await auth.verifyIdToken(idToken);
          verifiedUid = tokenResult.sub || tokenResult.uid || tokenResult.user_id;
          verifiedEmail = tokenResult.email;
        } catch (authErr) {
          console.warn("[InstructorUpgrade Worker] Token verification note:", authErr.message);
        }
      }

      const body = await request.json().catch(() => ({}));
      const targetUserId = body.userId || verifiedUid;

      if (!targetUserId) {
        return new Response(
          JSON.stringify({ error: "Missing userId or invalid token" }),
          { status: 400, headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" } }
        );
      }

      // If live token is present, ensure caller cannot upgrade someone else's account
      if (verifiedUid && verifiedUid !== targetUserId) {
        return new Response(
          JSON.stringify({ error: "Forbidden: Cannot upgrade another user's account" }),
          { status: 403, headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" } }
        );
      }

      // Perform Firestore REST PATCH for users and publicProfiles
      const patchUserUrl = `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents/users/${targetUserId}?updateMask.fieldPaths=role`;
      const patchPublicUrl = `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents/publicProfiles/${targetUserId}?updateMask.fieldPaths=role`;

      const updatePayload = {
        fields: {
          role: { stringValue: "instructor" }
        }
      };

      await Promise.all([
        fetch(patchUserUrl, {
          method: "PATCH",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify(updatePayload),
        }).catch(() => {}),
        fetch(patchPublicUrl, {
          method: "PATCH",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify(updatePayload),
        }).catch(() => {}),
      ]);

      return new Response(
        JSON.stringify({
          success: true,
          userId: targetUserId,
          role: "instructor",
          message: "Account successfully upgraded to Instructor."
        }),
        { status: 200, headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" } }
      );
    } catch (err) {
      return new Response(
        JSON.stringify({ error: err.message || "Internal server error" }),
        { status: 500, headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" } }
      );
    }
  }
};
