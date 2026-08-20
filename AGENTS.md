# EduSphere Project Rules — for Antigravity Agent

This file is the source of truth for this project. Read it before starting any task. Do not deviate from the stack decisions or folder structure without asking first.

## What this app is
A full-stack, multi-role Flutter e-learning app (students + instructors) — courses, video lessons, live classes, quizzes, certificates, gamification. Single codebase for Android/iOS/Web.

## ⚠️ Hard constraint: NO CARD, EVER
No product in this stack may require a linked billing card, even one with
a free/no-cost quota. This RULES OUT: Firebase Storage (requires Blaze
plan since Feb 2026) and Firebase Cloud Functions (also requires Blaze
plan). Firestore, Firebase Auth, and Firebase Cloud Messaging remain free
on the Spark plan with no card and are unaffected. Do not suggest or
silently fall back to either Firebase Storage or Cloud Functions for any
reason — use the replacements below instead.

## Stack decisions (LOCKED)
- **Frontend:** Flutter, single codebase, responsive across phone/tablet/web
- **State management:** Riverpod
- **Backend:** Firebase — Firestore (database) + Firebase Auth ONLY. No Firebase Storage, no Firebase Cloud Functions.
- **File storage (video, PDFs, images, certificates):** Cloudinary, all under one free-tier account (25GB storage + 25GB bandwidth/month, no card required):
  - Lecture videos → `resource_type: video`, `type: authenticated` for non-preview lessons
  - PDF/resource files → `resource_type: raw`
  - Profile photos → `resource_type: image`, `type: upload` (public)
  - Certificates → `resource_type: raw` (or `image` if rendered as an image), `type: upload` (must be public so QR codes/verification links work outside the app)
- **Server-side logic requiring a secret (signed video URLs, certificate generation, Stripe webhook):** Cloudflare Workers — free tier (100,000 requests/day), no card required to sign up. This replaces Firebase Cloud Functions everywhere in this project.
- **Live classes:** Jitsi Meet embed (no paid API key needed)
- **Real-time chat (live class + forums):** Firebase Firestore realtime listeners (skip separate Socket.io server)
- **Push notifications:** Firebase Cloud Messaging (FCM) — free on Spark, no card
- **Payments:** Stripe, test mode
- **Certificates:** PDF generated in a Cloudflare Worker with unique ID + QR code, uploaded to Cloudinary (public, `resource_type: raw`)
- **Routing:** go_router

## Video upload & playback flow (instructor → student)
1. Instructor, in CourseBuilder, picks "Add Lesson" and selects a video file.
2. App uploads the file directly to Cloudinary (unsigned upload preset for
   simplicity, since no server-side upload signing is required for the
   upload step itself) and receives back a `public_id`.
3. Only the `public_id` (never a plain playable URL) is saved on the
   lesson's Firestore doc for non-preview lessons.
4. Student opens the Lesson screen → app calls a Cloudflare Worker
   endpoint with the lesson's `public_id` and the student's auth token →
   Worker verifies enrolment in Firestore → if enrolled, Worker uses the
   Cloudinary API secret (stored as a Worker secret, never in the app) to
   generate a short-lived signed delivery URL and returns it → app streams
   that URL in the VideoPlayer widget.
5. If not enrolled, the Worker returns 403 and no URL is ever sent to the
   client.

## Folder structure — must match exactly

```
lib/
  assets/                  images, icons, static media, mock JSON seed data
  components/
    AppBar.dart            responsive top nav
    BottomNav.dart
    CourseCard.dart        thumbnail, title, category, instructor, price, discount badge, rating, enrolments, duration, level, wishlist icon, view-details button
    LessonList.dart
    VideoPlayer.dart       playback speed, subtitles, resume position
    QuizWidget.dart         MCQ / true-false / short answer, timer
    ProgressBar.dart
    LiveClassRoom.dart     Jitsi embed, participant list, chat, raise-hand
    ChatBubble.dart
    CertificateCard.dart
    SearchBar.dart
    Filters.dart           category, level, price range, duration, rating, language
    Button.dart
    Modal.dart
    Loader.dart             spinner + skeletons
    Testimonials.dart
  screens/
    Splash.dart, Onboarding.dart, Login.dart, Register.dart
    Home.dart               hero, categories, featured, continue-learning, trending instructors, CTA, footer
    Courses.dart            grid/list toggle, pagination, filters, sort
    CourseDetails.dart      preview video, syllabus, instructor bio, requirements, reviews, similar courses
    Lesson.dart
    LiveClass.dart
    Quiz.dart
    MyLearning.dart
    Certificates.dart
    Cart.dart / Checkout.dart
    Wishlist.dart
    Profile.dart            badges, streaks, XP
    InstructorDashboard.dart
    CourseBuilder.dart
    Earnings.dart
    About.dart / Contact.dart / NotFound.dart
  layouts/                 shared layout wrapping every screen (AppBar + BottomNav)
  services/                one file per domain: auth, courses, lessons, quizzes, payments, certificates
  providers/               session, enrolment, progress, quiz, cart state (Riverpod)
  models/                  User, Course, Lesson, Quiz, Enrolment, Certificate
  utils/
  styles/                  theme, colors, typography
  main.dart

backend/  (as Cloudflare Workers, not Firebase Cloud Functions and not a separate Express server)
  workers/
    getVideoStreamUrl/     verifies enrolment in Firestore, returns signed Cloudinary URL
    generateCertificate/   builds PDF + QR code on course completion, uploads to Cloudinary
    verifyCertificate/     public endpoint: looks up a certificate by verification ID
    stripeWebhook/         handles Stripe payment confirmation, writes enrolment to Firestore
```

## Data models (Firestore collections)
- `users` — id, name, email, role (student/instructor), photoUrl, bio, xp, streak, badges[]
- `courses` — id, title, category, instructorId, price, discount, level, language, duration, rating, enrolmentCount, thumbnailUrl, syllabus[], requirements[], whatYouWillLearn[]
- `lessons` — id, courseId, title, videoUrl, resources[], order
- `enrolments` — id, userId, courseId, progress, completedLessons[], paymentId, enrolledAt
- `quizzes` — id, courseId/lessonId, questions[]
- `quizAttempts` — id, userId, quizId, score, answers[], completedAt
- `certificates` — id, userId, courseId, verificationId, cloudinaryPublicId, issuedAt
- `liveClasses` — id, courseId, scheduledAt, jitsiRoomId

## UI design source — READ BEFORE BUILDING ANY SCREEN
Pixel-accurate UI designs already exist, exported from Stitch, in the `/stitch/` folder at project root — one subfolder or image per screen (e.g. `/stitch/Home/`, `/stitch/CourseDetails/`, `/stitch/Login/`).

**Rule: never invent your own layout for a screen that has a Stitch export.** Before building any screen, look inside `/stitch/<ScreenName>/` and match spacing, colors, typography, and component placement as closely as Flutter allows. If a screen has no Stitch export yet, build a clean layout consistent with the styles already established in `lib/styles/` from the screens that do have one, and flag it to me as "no Stitch reference found — used consistent styling" so I know to check it.
**RULE**: generateCloudinarySignedUrl() must NEVER silently fall back to a public /upload/ URL for authenticated assets. If SDK signing fails, throw — don't swallow the error. A broken public URL is worse than a clear 500 error.
## Seed data requirement
Minimum 10 mock courses with full details (title, category, instructor, price, syllabus, thumbnail, sample video, at least one quiz each) and 3–4 mock instructors. Put the seed JSON in `lib/assets/mock/course_seed.json` and write a one-time local Dart/Node script (run manually from your machine, not deployed) to push it into Firestore.

## Working rules for the agent
1. Work one phase at a time (see phase list below). **After finishing a phase, STOP. Do not start the next phase automatically — summarize what you built, list the Definition of Done items with how each was tested, and wait for my explicit approval before continuing.**
2. Match `/stitch/` designs exactly for any screen that has one (see UI design source section above).
3. After building a screen or feature, run the app in the preview/emulator and visually confirm it renders with no errors before reporting done.
4. Use mock data only for what genuinely isn't built yet, and mark it with `// TODO: replace mock`.
5. Never restructure folders or rename files outside the spec above without asking first.
6. After each phase, write a short entry to `CHANGELOG.md` summarizing what was built and what was tested.
7. If a build breaks something in an earlier, already-completed phase, fix it before continuing — do not leave regressions, even if it's not part of the current phase.

## Phase order (do not skip ahead)
1. Setup & Foundations — project scaffold, Firebase connected, routing + shared layout for all screens, seed data loaded
2. Auth & Roles — register/login, Google sign-in, role-based routing, role guards, profile persistence
3. Component Library & Discovery — all reusable widgets, Home screen, Courses grid/list, filters, sort
4. Course Details, Cart & Payment — CourseDetails, wishlist, free instant-enroll, Stripe checkout, enrolment persisted
5. Lessons, Live Classes & Quizzes — video player + progress persistence, My Learning, Jitsi live class + chat, quiz + auto-grading
6. Certificates, Instructor Mode & Polish — PDF certs + verification, gamification, InstructorDashboard, CourseBuilder, Earnings, remaining supporting screens, animations, full responsiveness pass

## Definition of Done (final) — from the 20-item checklist
Only mark a feature complete when it can be demonstrated live, not just present in code:
responsive layout · auth + social login · role-based routing · landing screen · course grid · course card fields · filters/sort · course details · cart/checkout · payment→enrolment · video lesson + persisted progress · live class join+chat · quiz auto-grading · verifiable certificate · gamification display · instructor dashboard · course builder · push notifications · full responsiveness+animation · reusable/redeployable structure.
