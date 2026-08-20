/**
 * Script: setup_production_firestore.js
 * 
 * 1. Creates 3 fresh Firebase Auth accounts (1 Instructor, 2 Students) using Firebase Auth REST API.
 * 2. Purges all legacy/mock course documents and user documents from Firestore.
 * 3. Writes 3 authentic user profiles to Firestore `users` collection.
 * 4. Creates exactly 5 high-quality production course documents owned by the real instructor in Firestore.
 */

const https = require('https');

const FIREBASE_API_KEY = 'AIzaSyBt9iDoO1PrxrDYON61pv8FX5B0E79ZSBs';
const PROJECT_ID = 'edusphere-ae8ed';
const FIRESTORE_BASE = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents`;

function makeRequest(url, method = 'GET', data = null) {
  return new Promise((resolve, reject) => {
    const parsed = new URL(url);
    const options = {
      hostname: parsed.hostname,
      path: parsed.pathname + parsed.search,
      method: method,
      headers: {
        'Content-Type': 'application/json',
      },
    };

    const req = https.request(options, (res) => {
      let body = '';
      res.on('data', (chunk) => body += chunk);
      res.on('end', () => {
        try {
          const json = body ? JSON.parse(body) : {};
          if (res.statusCode >= 200 && res.statusCode < 300) {
            resolve(json);
          } else {
            resolve({ error: json.error || body, status: res.statusCode });
          }
        } catch (e) {
          resolve({ error: body, status: res.statusCode });
        }
      });
    });

    req.on('error', reject);
    if (data) {
      req.write(JSON.stringify(data));
    }
    req.end();
  });
}

// 1. Firebase Auth helper: register or login
async function getOrCreateFirebaseAuthUser(email, password, displayName) {
  const signUpUrl = `https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=${FIREBASE_API_KEY}`;
  const res = await makeRequest(signUpUrl, 'POST', {
    email,
    password,
    returnSecureToken: true,
  });

  if (res.localId) {
    console.log(`✅ Created fresh Firebase Auth user: ${email} (UID: ${res.localId})`);
    return { uid: res.localId, email, idToken: res.idToken };
  }

  // If EMAIL_EXISTS, sign in to get UID
  if (res.error?.message === 'EMAIL_EXISTS') {
    const signInUrl = `https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${FIREBASE_API_KEY}`;
    const loginRes = await makeRequest(signInUrl, 'POST', {
      email,
      password,
      returnSecureToken: true,
    });
    if (loginRes.localId) {
      console.log(`✅ Logged in existing Firebase Auth user: ${email} (UID: ${loginRes.localId})`);
      return { uid: loginRes.localId, email, idToken: loginRes.idToken };
    }
  }

  throw new Error(`Failed to create/login auth user ${email}: ${JSON.stringify(res.error)}`);
}

// 2. Firestore Document helper
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
  return { fields };
}

async function setFirestoreDoc(collection, docId, data) {
  const url = `${FIRESTORE_BASE}/${collection}/${docId}`;
  const firestorePayload = objectToFirestoreFields(data);
  const res = await makeRequest(url, 'PATCH', firestorePayload);
  if (res.error) {
    console.error(`❌ Error writing ${collection}/${docId}:`, res.error);
  } else {
    console.log(`✅ Wrote doc ${collection}/${docId}`);
  }
  return res;
}

async function deleteFirestoreDoc(collection, docId) {
  const url = `${FIRESTORE_BASE}/${collection}/${docId}`;
  return await makeRequest(url, 'DELETE');
}

async function listCollectionDocs(collection) {
  const url = `${FIRESTORE_BASE}/${collection}`;
  const res = await makeRequest(url, 'GET');
  return res.documents || [];
}

async function main() {
  console.log('====================================================');
  console.log('🚀 1. Creating 3 Fresh Firebase Auth Accounts');
  console.log('====================================================');

  const instructorAuth = await getOrCreateFirebaseAuthUser(
    'instructor@edusphere.io',
    'EduSphere2026!',
    'Dr. Alexandre Rivera'
  );

  const student1Auth = await getOrCreateFirebaseAuthUser(
    'student.alex@edusphere.io',
    'EduSphere2026!',
    'Alex Morgan'
  );

  const student2Auth = await getOrCreateFirebaseAuthUser(
    'student.sarah@edusphere.io',
    'EduSphere2026!',
    'Sarah Connor'
  );

  console.log('\n====================================================');
  console.log('🧹 2. Purging Old/Mock Courses & Old Test Accounts');
  console.log('====================================================');

  const oldCourses = await listCollectionDocs('courses');
  console.log(`Found ${oldCourses.length} existing course documents to purge...`);
  for (const doc of oldCourses) {
    const docId = doc.name.split('/').pop();
    await deleteFirestoreDoc('courses', docId);
    console.log(`🗑️ Deleted course: ${docId}`);
  }

  const oldUsers = await listCollectionDocs('users');
  console.log(`Found ${oldUsers.length} existing user documents to purge...`);
  for (const doc of oldUsers) {
    const docId = doc.name.split('/').pop();
    await deleteFirestoreDoc('users', docId);
    console.log(`🗑️ Deleted user profile: ${docId}`);
  }

  console.log('\n====================================================');
  console.log('👤 3. Writing 3 Fresh User Documents to Firestore');
  console.log('====================================================');

  // Instructor User Doc
  const instructorDoc = {
    id: instructorAuth.uid,
    name: 'Dr. Alexandre Rivera',
    email: instructorAuth.email,
    role: 'instructor',
    bio: 'Lead Architect & Senior Faculty Director at EduSphere. Specializing in high-performance cloud engineering, mobile platforms, and distributed systems.',
    photoUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400',
    xp: 15400,
    streak: 28,
    badges: ['Lead Faculty', 'Verified Master Instructor', 'Top Rated 2026', 'Distinguished Scholar'],
    createdAt: new Date().toISOString(),
  };
  await setFirestoreDoc('users', instructorAuth.uid, instructorDoc);

  // Student 1 User Doc
  const student1Doc = {
    id: student1Auth.uid,
    name: 'Alex Morgan',
    email: student1Auth.email,
    role: 'student',
    bio: 'Software engineer passionate about Flutter, scalable cloud backends, and elegant user interfaces.',
    photoUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=400',
    xp: 2850,
    streak: 7,
    badges: ['New Joiner', 'Mastery Graduate', 'Full Stack Master'],
    createdAt: new Date().toISOString(),
  };
  await setFirestoreDoc('users', student1Auth.uid, student1Doc);

  // Student 2 User Doc
  const student2Doc = {
    id: student2Auth.uid,
    name: 'Sarah Connor',
    email: student2Auth.email,
    role: 'student',
    bio: 'Cybersecurity specialist and systems engineer exploring zero-trust architectures and threat prevention.',
    photoUrl: 'https://images.unsplash.com/photo-1580489944761-15a19d654956?w=400',
    xp: 1450,
    streak: 4,
    badges: ['New Joiner', 'Security Pioneer'],
    createdAt: new Date().toISOString(),
  };
  await setFirestoreDoc('users', student2Auth.uid, student2Doc);

  console.log('\n====================================================');
  console.log('📚 4. Writing Exactly 5 Real Courses Owned by Instructor');
  console.log('====================================================');

  const realCourses = [
    {
      id: 'course_flutter_arch',
      title: 'Complete Flutter & Dart Architecture Masterclass',
      category: 'Mobile Development',
      instructorId: instructorAuth.uid,
      instructor: {
        id: instructorAuth.uid,
        name: 'Dr. Alexandre Rivera',
        avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400',
        title: 'Senior Faculty Director',
        rating: 4.95,
        studentsCount: 1420,
      },
      price: 89.99,
      discount: 69.99,
      level: 'Intermediate',
      language: 'English',
      duration: '14.5 hrs',
      rating: 4.9,
      enrolmentCount: 342,
      thumbnailUrl: 'https://images.unsplash.com/photo-1551650975-87deedd944c3?w=800',
      description: 'Master production-grade Flutter engineering, Clean Architecture, Riverpod 2.0 state management, offline caching, and responsive UI systems built for enterprise scale.',
      whatYouWillLearn: [
        'Build layered Clean Architecture applications with Flutter and Riverpod',
        'Implement resilient offline-first caching and synchronisation',
        'Stream signed media securely using Cloudflare serverless workers',
        'Design responsive layouts matching Figma design system tokens',
      ],
      requirements: [
        'Basic knowledge of Dart and object-oriented programming',
        'Flutter SDK installed on Windows, macOS, or Linux',
      ],
      syllabus: [
        {
          id: 'sec_fl_01',
          title: 'Section 1: Architecture & State Fundamentals',
          lessons: [
            {
              id: 'les_fl_01',
              title: 'Clean Architecture Principles & Folder Structure',
              duration: '12:45',
              isPreview: true,
              cloudinaryPublicId: 'courses/course_flutter_arch/les_fl_01',
              videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
              order: 1,
            },
            {
              id: 'les_fl_02',
              title: 'Riverpod 2.0 AsyncNotifiers & Immutable State',
              duration: '18:20',
              isPreview: false,
              cloudinaryPublicId: 'courses/course_flutter_arch/les_fl_02',
              videoUrl: '',
              order: 2,
            },
          ],
        },
      ],
      ratingSum: 24.5,
      ratingCount: 5,
      averageRating: 4.9,
      createdAt: new Date().toISOString(),
    },
    {
      id: 'course_cloud_serverless',
      title: 'Full-Stack Cloud & Serverless Systems with Docker',
      category: 'Cloud Engineering',
      instructorId: instructorAuth.uid,
      instructor: {
        id: instructorAuth.uid,
        name: 'Dr. Alexandre Rivera',
        avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400',
        title: 'Senior Faculty Director',
        rating: 4.95,
        studentsCount: 1420,
      },
      price: 94.99,
      discount: 74.99,
      level: 'Advanced',
      language: 'English',
      duration: '18.0 hrs',
      rating: 4.95,
      enrolmentCount: 289,
      thumbnailUrl: 'https://images.unsplash.com/photo-1451187580459-43490279c0fa?w=800',
      description: 'Architect zero-cost serverless microservices with Cloudflare Workers, secure edge pipelines, Docker container orchestration, and Cloud Firestore integration.',
      whatYouWillLearn: [
        'Deploy serverless Edge workers with sub-millisecond execution',
        'Implement zero-card storage and media distribution pipelines',
        'Configure cryptographic authentication and API access tokens',
        'Monitor, trace, and scale cloud workloads globally',
      ],
      requirements: [
        'Familiarity with JavaScript / Node.js and basic HTTP protocols',
        'A free Cloudflare and Firebase developer account',
      ],
      syllabus: [
        {
          id: 'sec_cs_01',
          title: 'Section 1: Edge Computing & Serverless Foundations',
          lessons: [
            {
              id: 'les_cs_01',
              title: 'Serverless Edge Architecture & Cloudflare Worker Core',
              duration: '15:10',
              isPreview: true,
              cloudinaryPublicId: 'courses/course_cloud_serverless/les_cs_01',
              videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
              order: 1,
            },
            {
              id: 'les_cs_02',
              title: 'Securing Edge Endpoints with Firebase Auth REST',
              duration: '22:35',
              isPreview: false,
              cloudinaryPublicId: 'courses/course_cloud_serverless/les_cs_02',
              videoUrl: '',
              order: 2,
            },
          ],
        },
      ],
      ratingSum: 19.8,
      ratingCount: 4,
      averageRating: 4.95,
      createdAt: new Date().toISOString(),
    },
    {
      id: 'course_uiux_design',
      title: 'Modern UI/UX Design Systems & Micro-Interactions',
      category: 'UI/UX Design',
      instructorId: instructorAuth.uid,
      instructor: {
        id: instructorAuth.uid,
        name: 'Dr. Alexandre Rivera',
        avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400',
        title: 'Senior Faculty Director',
        rating: 4.95,
        studentsCount: 1420,
      },
      price: 79.99,
      discount: 59.99,
      level: 'Beginner',
      language: 'English',
      duration: '11.5 hrs',
      rating: 4.85,
      enrolmentCount: 412,
      thumbnailUrl: 'https://images.unsplash.com/photo-1507238691740-187a5b1d37b8?w=800',
      description: 'Design world-class mobile and web user experiences with Figma, comprehensive design tokens, glassmorphism aesthetics, accessible color palettes, and fluid motion design.',
      whatYouWillLearn: [
        'Construct scalable design token systems in Figma and Flutter',
        'Create micro-animations that elevate user engagement and delight',
        'Apply color theory, typographical scale, and spatial grids',
        'Conduct usability testing and UX audit evaluations',
      ],
      requirements: [
        'No prior design experience needed — beginners welcome',
        'Free Figma account for web or desktop',
      ],
      syllabus: [
        {
          id: 'sec_ux_01',
          title: 'Section 1: Design Systems & Token Architecture',
          lessons: [
            {
              id: 'les_ux_01',
              title: 'Design Tokens, Color Harmonies & Spatial Rhythm',
              duration: '14:05',
              isPreview: true,
              cloudinaryPublicId: 'courses/course_uiux_design/les_ux_01',
              videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
              order: 1,
            },
            {
              id: 'les_ux_02',
              title: 'Interactive Prototyping & Micro-Animation Physics',
              duration: '19:40',
              isPreview: false,
              cloudinaryPublicId: 'courses/course_uiux_design/les_ux_02',
              videoUrl: '',
              order: 2,
            },
          ],
        },
      ],
      ratingSum: 29.1,
      ratingCount: 6,
      averageRating: 4.85,
      createdAt: new Date().toISOString(),
    },
    {
      id: 'course_cybersecurity',
      title: 'Zero-Trust Cybersecurity & Threat Hunting',
      category: 'Cybersecurity',
      instructorId: instructorAuth.uid,
      instructor: {
        id: instructorAuth.uid,
        name: 'Dr. Alexandre Rivera',
        avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400',
        title: 'Senior Faculty Director',
        rating: 4.95,
        studentsCount: 1420,
      },
      price: 99.99,
      discount: 79.99,
      level: 'Advanced',
      language: 'English',
      duration: '16.5 hrs',
      rating: 4.92,
      enrolmentCount: 198,
      thumbnailUrl: 'https://images.unsplash.com/photo-1563986768609-322da13575f3?w=800',
      description: 'Protect enterprise infrastructure with modern zero-trust architecture, cryptographic identity validation, packet inspection, network defense, and incident response strategies.',
      whatYouWillLearn: [
        'Implement least-privilege Zero-Trust network perimeters',
        'Analyze network packets, handshake ciphers, and threat vectors',
        'Configure defensive firewall rules and security auditing',
        'Perform ethical penetration assessments and vulnerability reports',
      ],
      requirements: [
        'Understanding of TCP/IP networking and basic command-line navigation',
      ],
      syllabus: [
        {
          id: 'sec_sec_01',
          title: 'Section 1: Zero-Trust Principles & Access Control',
          lessons: [
            {
              id: 'les_sec_01',
              title: 'Zero-Trust Architecture & Continuous Verification',
              duration: '16:50',
              isPreview: true,
              cloudinaryPublicId: 'courses/course_cybersecurity/les_sec_01',
              videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4',
              order: 1,
            },
            {
              id: 'les_sec_02',
              title: 'Packet Analysis & Intrusion Detection Systems',
              duration: '21:15',
              isPreview: false,
              cloudinaryPublicId: 'courses/course_cybersecurity/les_sec_02',
              videoUrl: '',
              order: 2,
            },
          ],
        },
      ],
      ratingSum: 24.6,
      ratingCount: 5,
      averageRating: 4.92,
      createdAt: new Date().toISOString(),
    },
    {
      id: 'course_databases_web3',
      title: 'High-Performance Distributed Databases & Web3',
      category: 'Software Engineering',
      instructorId: instructorAuth.uid,
      instructor: {
        id: instructorAuth.uid,
        name: 'Dr. Alexandre Rivera',
        avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400',
        title: 'Senior Faculty Director',
        rating: 4.95,
        studentsCount: 1420,
      },
      price: 109.99,
      discount: 84.99,
      level: 'Intermediate',
      language: 'English',
      duration: '15.0 hrs',
      rating: 4.88,
      enrolmentCount: 235,
      thumbnailUrl: 'https://images.unsplash.com/photo-1639762681485-074b7f938ba0?w=800',
      description: 'Master distributed document stores, immutable cryptographic ledgers, query indexing, ACID transactions, and smart contract state machines.',
      whatYouWillLearn: [
        'Design distributed NoSQL schemas and partition keys',
        'Optimize multi-document atomic transactions and indexing',
        'Integrate cryptographic verifiable credentials and QR verification',
        'Build resilient decentralised ledger records',
      ],
      requirements: [
        'Basic database concepts and JSON data structures',
      ],
      syllabus: [
        {
          id: 'sec_db_01',
          title: 'Section 1: Distributed Data & Ledger State',
          lessons: [
            {
              id: 'les_db_01',
              title: 'Distributed Consistency, Raft Consensus & ACID Guarantees',
              duration: '13:30',
              isPreview: true,
              cloudinaryPublicId: 'courses/course_databases_web3/les_db_01',
              videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4',
              order: 1,
            },
            {
              id: 'les_db_02',
              title: 'Immutable Ledger Verification & Cryptographic Hashes',
              duration: '20:10',
              isPreview: false,
              cloudinaryPublicId: 'courses/course_databases_web3/les_db_02',
              videoUrl: '',
              order: 2,
            },
          ],
        },
      ],
      ratingSum: 19.5,
      ratingCount: 4,
      averageRating: 4.88,
      createdAt: new Date().toISOString(),
    },
  ];

  for (const course of realCourses) {
    await setFirestoreDoc('courses', course.id, course);
  }

  console.log('\n====================================================');
  console.log('🎉 Verification & Raw Firestore Output');
  console.log('====================================================');

  const finalUsers = await listCollectionDocs('users');
  console.log(`\n--- USERS COLLECTION (${finalUsers.length} total) ---`);
  finalUsers.forEach((u) => console.log(JSON.stringify(u, null, 2)));

  const finalCourses = await listCollectionDocs('courses');
  console.log(`\n--- COURSES COLLECTION (${finalCourses.length} total) ---`);
  finalCourses.forEach((c) => console.log(JSON.stringify(c, null, 2)));

  console.log('\n✅ Setup script complete.');
}

main().catch(console.error);
