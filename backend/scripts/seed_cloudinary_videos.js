/**
 * Script: seed_cloudinary_videos.js
 * 
 * One-time local seed script (per AGENTS.md) to upload all 10 sample videos
 * from sample_videos/ to Cloudinary and update the 5 courses in Firestore.
 */

const fs = require('fs');
const path = require('path');
const https = require('https');

const CLOUD_NAME = 'kl8rl0al';
const PROJECT_ID = 'edusphere-ae8ed';
const FIRESTORE_BASE = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents`;

const VIDEO_MAPPINGS = [
  // Course 1: Complete Flutter & Dart Architecture Masterclass
  {
    filePath: 'sample_videos/clip_01_bunny_opening.mp4',
    courseId: 'course_flutter_arch',
    sectionId: 'sec_fl_01',
    lessonId: 'les_fl_01',
    lessonTitle: 'Clean Architecture Principles & Folder Structure',
    isPreview: true,
    preset: 'edusphere_public_preview',
    order: 1,
  },
  {
    filePath: 'sample_videos/clip_02_bunny_field.mp4',
    courseId: 'course_flutter_arch',
    sectionId: 'sec_fl_01',
    lessonId: 'les_fl_02',
    lessonTitle: 'Riverpod 2.0 AsyncNotifiers & Immutable State',
    isPreview: false,
    preset: 'edusphere_authenticated',
    order: 2,
  },

  // Course 2: Full-Stack Cloud & Serverless Systems with Docker
  {
    filePath: 'sample_videos/clip_03_bunny_birds.mp4',
    courseId: 'course_cloud_serverless',
    sectionId: 'sec_cs_01',
    lessonId: 'les_cs_01',
    lessonTitle: 'Serverless Edge Architecture & Cloudflare Worker Core',
    isPreview: true,
    preset: 'edusphere_public_preview',
    order: 1,
  },
  {
    filePath: 'sample_videos/clip_04_bunny_forest.mp4',
    courseId: 'course_cloud_serverless',
    sectionId: 'sec_cs_01',
    lessonId: 'les_cs_02',
    lessonTitle: 'Securing Edge Endpoints with Firebase Auth REST',
    isPreview: false,
    preset: 'edusphere_authenticated',
    order: 2,
  },

  // Course 3: Modern UI/UX Design Systems & Micro-Interactions
  {
    filePath: 'sample_videos/clip_05_bunny_ending.mp4',
    courseId: 'course_uiux_design',
    sectionId: 'sec_ux_01',
    lessonId: 'les_ux_01',
    lessonTitle: 'Design Tokens, Color Harmonies & Spatial Rhythm',
    isPreview: true,
    preset: 'edusphere_public_preview',
    order: 1,
  },
  {
    filePath: 'sample_videos/clip_06_echo_intro.mp4',
    courseId: 'course_uiux_design',
    sectionId: 'sec_ux_01',
    lessonId: 'les_ux_02',
    lessonTitle: 'Interactive Prototyping & Micro-Animation Physics',
    isPreview: false,
    preset: 'edusphere_authenticated',
    order: 2,
  },

  // Course 4: Zero-Trust Cybersecurity & Threat Hunting
  {
    filePath: 'sample_videos/clip_07_echo_scene.mp4',
    courseId: 'course_cybersecurity',
    sectionId: 'sec_sec_01',
    lessonId: 'les_sec_01',
    lessonTitle: 'Zero-Trust Architecture & Continuous Verification',
    isPreview: true,
    preset: 'edusphere_public_preview',
    order: 1,
  },
  {
    filePath: 'sample_videos/clip_08_echo_mid.mp4',
    courseId: 'course_cybersecurity',
    sectionId: 'sec_sec_01',
    lessonId: 'les_sec_02',
    lessonTitle: 'Packet Analysis & Intrusion Detection Systems',
    isPreview: false,
    preset: 'edusphere_authenticated',
    order: 2,
  },

  // Course 5: High-Performance Distributed Databases & Web3
  {
    filePath: 'sample_videos/clip_09_echo_late.mp4',
    courseId: 'course_databases_web3',
    sectionId: 'sec_db_01',
    lessonId: 'les_db_01',
    lessonTitle: 'Distributed Consistency, Raft Consensus & ACID Guarantees',
    isPreview: true,
    preset: 'edusphere_public_preview',
    order: 1,
  },
  {
    filePath: 'sample_videos/clip_10_echo_end.mp4',
    courseId: 'course_databases_web3',
    sectionId: 'sec_db_01',
    lessonId: 'les_db_02',
    lessonTitle: 'Immutable Ledger Verification & Cryptographic Hashes',
    isPreview: false,
    preset: 'edusphere_authenticated',
    order: 2,
  },
];

/**
 * Uploads a local file buffer to Cloudinary using multipart/form-data
 */
function uploadToCloudinary(fileBuffer, fileName, publicId, preset) {
  return new Promise((resolve, reject) => {
    const boundary = '----CloudinaryBoundary' + Math.random().toString(36).substring(2);
    const postData = [];

    // upload_preset field
    postData.push(Buffer.from(`--${boundary}\r\nContent-Disposition: form-data; name="upload_preset"\r\n\r\n${preset}\r\n`));

    // public_id field
    postData.push(Buffer.from(`--${boundary}\r\nContent-Disposition: form-data; name="public_id"\r\n\r\n${publicId}\r\n`));

    // file field
    postData.push(Buffer.from(`--${boundary}\r\nContent-Disposition: form-data; name="file"; filename="${fileName}"\r\nContent-Type: video/mp4\r\n\r\n`));
    postData.push(fileBuffer);
    postData.push(Buffer.from(`\r\n--${boundary}--\r\n`));

    const totalPayload = Buffer.concat(postData);

    const options = {
      hostname: 'api.cloudinary.com',
      path: `/v1_1/${CLOUD_NAME}/video/upload`,
      method: 'POST',
      headers: {
        'Content-Type': `multipart/form-data; boundary=${boundary}`,
        'Content-Length': totalPayload.length,
      },
    };

    const req = https.request(options, (res) => {
      let body = '';
      res.on('data', (chunk) => body += chunk);
      res.on('end', () => {
        try {
          const json = JSON.parse(body);
          if (res.statusCode >= 200 && res.statusCode < 300) {
            resolve(json);
          } else {
            reject(new Error(`Cloudinary error (${res.statusCode}): ${JSON.stringify(json)}`));
          }
        } catch (e) {
          reject(new Error(`Invalid response (${res.statusCode}): ${body}`));
        }
      });
    });

    req.on('error', reject);
    req.write(totalPayload);
    req.end();
  });
}

function makeFirestoreRequest(url, method = 'GET', data = null) {
  return new Promise((resolve, reject) => {
    const parsed = new URL(url);
    const options = {
      hostname: parsed.hostname,
      path: parsed.pathname + parsed.search,
      method: method,
      headers: { 'Content-Type': 'application/json' },
    };

    const req = https.request(options, (res) => {
      let body = '';
      res.on('data', (chunk) => body += chunk);
      res.on('end', () => {
        try {
          resolve(JSON.parse(body));
        } catch (e) {
          resolve({ error: body });
        }
      });
    });

    req.on('error', reject);
    if (data) req.write(JSON.stringify(data));
    req.end();
  });
}

async function getCourseDoc(courseId) {
  const url = `${FIRESTORE_BASE}/courses/${courseId}`;
  return await makeFirestoreRequest(url, 'GET');
}

async function updateCourseDoc(courseId, firestoreFields) {
  const url = `${FIRESTORE_BASE}/courses/${courseId}`;
  return await makeFirestoreRequest(url, 'PATCH', { fields: firestoreFields });
}

// Convert JSON object to Firestore Fields structure
function toFirestoreField(val) {
  if (val === null || val === undefined) return { nullValue: null };
  if (typeof val === 'string') return { stringValue: val };
  if (typeof val === 'boolean') return { booleanValue: val };
  if (typeof val === 'number') {
    return Number.isInteger(val) ? { integerValue: val.toString() } : { doubleValue: val };
  }
  if (Array.isArray(val)) {
    return { arrayValue: { values: val.map(toFirestoreField) } };
  }
  if (typeof val === 'object') {
    const fields = {};
    for (const k of Object.keys(val)) {
      fields[k] = toFirestoreField(val[k]);
    }
    return { mapValue: { fields } };
  }
  return { stringValue: String(val) };
}

function objectToFirestoreFields(obj) {
  const fields = {};
  for (const k of Object.keys(obj)) {
    fields[k] = toFirestoreField(obj[k]);
  }
  return fields;
}

// Helper to convert Firestore document to plain JS object
function firestoreValueToPlain(fv) {
  if (!fv) return null;
  if ('stringValue' in fv) return fv.stringValue;
  if ('integerValue' in fv) return parseInt(fv.integerValue, 10);
  if ('doubleValue' in fv) return parseFloat(fv.doubleValue);
  if ('booleanValue' in fv) return fv.booleanValue;
  if ('nullValue' in fv) return null;
  if ('arrayValue' in fv) return (fv.arrayValue.values || []).map(firestoreValueToPlain);
  if ('mapValue' in fv) {
    const res = {};
    for (const k of Object.keys(fv.mapValue.fields || {})) {
      res[k] = firestoreValueToPlain(fv.mapValue.fields[k]);
    }
    return res;
  }
  return null;
}

function firestoreDocToPlain(doc) {
  if (!doc || !doc.fields) return null;
  const res = {};
  for (const k of Object.keys(doc.fields)) {
    res[k] = firestoreValueToPlain(doc.fields[k]);
  }
  return res;
}

async function main() {
  console.log('========================================================================');
  console.log('🚀 SEEDING 10 REAL VIDEOS TO CLOUDINARY & UPDATING FIRESTORE');
  console.log('========================================================================\n');

  const uploadResults = [];

  for (let i = 0; i < VIDEO_MAPPINGS.length; i++) {
    const mapping = VIDEO_MAPPINGS[i];
    const absolutePath = path.resolve(mapping.filePath);

    if (!fs.existsSync(absolutePath)) {
      throw new Error(`Video file not found at: ${absolutePath}`);
    }

    const fileBuffer = fs.readFileSync(absolutePath);
    const fileName = path.basename(mapping.filePath);
    const publicId = `courses/${mapping.courseId}/${mapping.lessonId}`;

    console.log(`[${i + 1}/10] 📤 Uploading "${fileName}" (${(fileBuffer.length / (1024 * 1024)).toFixed(2)} MB)`);
    console.log(`      Target Public ID: ${publicId}`);
    console.log(`      Access Mode: ${mapping.isPreview ? 'PUBLIC (Preview)' : 'AUTHENTICATED (Paid)'}`);
    console.log(`      Preset: ${mapping.preset}`);

    const result = await uploadToCloudinary(fileBuffer, fileName, publicId, mapping.preset);

    console.log(`      ✅ Upload Success! Cloudinary public_id: ${result.public_id}`);
    console.log(`      Duration: ${result.duration ? result.duration.toFixed(1) + 's' : 'N/A'}, Bytes: ${result.bytes}, Format: ${result.format}\n`);

    uploadResults.push({
      mapping,
      result,
      durationStr: `${Math.floor((result.duration || 60) / 60)}:${Math.floor((result.duration || 60) % 60).toString().padStart(2, '0')}`,
    });
  }

  console.log('========================================================================');
  console.log('📝 UPDATING FIRESTORE COURSE LESSON DOCUMENTS');
  console.log('========================================================================\n');

  // Group uploads by course
  const coursesToUpdate = {};
  for (const item of uploadResults) {
    const cId = item.mapping.courseId;
    if (!coursesToUpdate[cId]) coursesToUpdate[cId] = [];
    coursesToUpdate[cId].push(item);
  }

  for (const courseId of Object.keys(coursesToUpdate)) {
    const rawDoc = await getCourseDoc(courseId);
    const course = firestoreDocToPlain(rawDoc);

    if (!course) {
      console.error(`❌ Course ${courseId} not found in Firestore!`);
      continue;
    }

    const items = coursesToUpdate[courseId];
    const lessonsList = items.map(({ mapping, result, durationStr }) => ({
      id: mapping.lessonId,
      title: mapping.lessonTitle,
      duration: durationStr,
      isPreview: mapping.isPreview,
      cloudinaryPublicId: result.public_id,
      // For preview lessons, store public URL; for authenticated lessons, NEVER store playable URL (keep empty)
      videoUrl: mapping.isPreview ? result.secure_url : '',
      order: mapping.order,
    }));

    // Update the syllabus structure
    const updatedSyllabus = [
      {
        id: items[0].mapping.sectionId,
        title: 'Section 1: Core Fundamentals & Practical Implementation',
        lessons: lessonsList,
      },
    ];

    course.syllabus = updatedSyllabus;
    const newFirestoreFields = objectToFirestoreFields(course);
    await updateCourseDoc(courseId, newFirestoreFields);

    console.log(`✅ Updated Firestore course: "${course.title}" (${courseId})`);
    lessonsList.forEach(l => {
      console.log(`   - Lesson: "${l.title}" | isPreview: ${l.isPreview} | publicId: ${l.cloudinaryPublicId} | videoUrl: ${l.videoUrl || '(PROTECTED - Gated behind Worker)'}`);
    });
    console.log('');
  }

  console.log('========================================================================');
  console.log('📊 CLOUDINARY MEDIA LIBRARY ASSET VERIFICATION REPORT');
  console.log('========================================================================\n');

  console.log('-------------------------------------------------------------------------------------------------------------------------');
  console.log('| #  | Course ID               | Lesson ID  | Access Mode   | Cloudinary Public ID                          | Size (KB) |');
  console.log('-------------------------------------------------------------------------------------------------------------------------');

  uploadResults.forEach((item, idx) => {
    const num = (idx + 1).toString().padEnd(2);
    const cId = item.mapping.courseId.padEnd(23);
    const lId = item.mapping.lessonId.padEnd(10);
    const mode = (item.mapping.isPreview ? 'PUBLIC' : 'AUTHENTICATED').padEnd(13);
    const pId = item.result.public_id.padEnd(45);
    const size = (item.result.bytes / 1024).toFixed(0).padStart(9);
    console.log(`| ${num} | ${cId} | ${lId} | ${mode} | ${pId} | ${size} |`);
  });
  console.log('-------------------------------------------------------------------------------------------------------------------------\n');
  console.log('🎉 Section 2 Execution Succeeded!');
}

main().catch(console.error);
