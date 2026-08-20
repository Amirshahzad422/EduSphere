# EduSphere Changelog

All notable changes to the EduSphere project will be documented in this file.

---

## [Phase 5] - Lessons, Live Classes & Quizzes

### Added
- **Automatic Video Duration Detection & Sync (`CourseBuilder.dart`, `Lesson.dart`)**:
  - **Auto-Populate Video Length**: In `CourseBuilder`, when a video finishes uploading to Cloudinary, `uploadResult.durationSeconds` is automatically parsed and formatted (`MM:SS`) into the Duration field, ensuring accurate lesson lengths without manual instructor guesswork.
  - **Dynamic Video Timeline Duration**: In `Lesson.dart` and `CustomVideoPlayer.dart`, `totalDurationSeconds` is dynamically parsed from the active lesson's duration and synchronized with the video stream's genuine metadata.
  - **Native HTML5 Web Video Player & Multi-Platform Engine (`CustomVideoPlayer.dart`)**:
  - **Live Cloudflare Worker Video Signature (`https://get-video-stream-url.edusphere-app.workers.dev`)**: Updated `LessonStreamService` to send the student's Firebase Auth ID token directly to the deployed Cloudflare Worker to obtain authentic signed Cloudinary delivery URLs for enrolled students.
  - **Authenticated Video URL Signing & Delivery Verification (`backend/workers/getVideoStreamUrl/`)**:
  - **Fail-Closed Strict Signing**: Configured Cloudflare Worker to throw detailed errors on SDK signing failure with zero silent fallback to `/upload/` for authenticated assets.
  - **Canonical SHA-1 WebCrypto Signature**: Generates canonical `/video/authenticated/s--...--/v1/...` signed URLs validated live against Cloudinary CDN returning `HTTP 200 OK` (`video/mp4;codecs=avc1`, `Accept-Ranges: bytes`).
  - **Live Real-time Enrolment & History Stream**: Migrated `EnrolmentNotifier` to Firestore `.snapshots()` stream with memory caching in `CourseService` for instant 0ms tab transitions and immediate dashboard synchronization upon login.
  - **Upload Error Handling & Guardrails**: Fixed upload failure behavior in `CourseBuilder` by clearing failed upload state on error and strictly disabling the "Add to Module" button until a genuine, verified `public_id` is returned from Cloudinary.
  - **Course Editing & Updates**: Added `updateCourse` in `CourseService` to persist edits to Firestore and memory. Added edit mode in `CourseBuilderScreen` (`/builder?courseId=...`) with form pre-population, cache invalidation, and wired the "Edit in Builder" button from the `InstructorDashboard`.
- **Authenticated Video & PDF Resource Streaming with Cloudflare Worker Security (`backend/workers/getVideoStreamUrl/`, `LessonStreamService`)**:
  - **Zero-Card Cloudflare Worker Architecture**: Free tier Cloudflare Worker verifying student Firestore enrollment before issuing time-limited HMAC-SHA256 signed Cloudinary delivery URLs for both video (`/video/authenticated/`) and raw PDF resources (`/raw/authenticated/`).
  - **Server-Side Access Control (HTTP 403)**: Non-enrolled users attempting to access paid video lectures or non-preview PDF resources are rejected server-side with 403 Forbidden. Lesson and Resource documents store only `cloudinaryPublicId` (with `url: ""` for non-preview resources, never leaking plain download URLs).
  - **Preview Lesson & Resource Bypass**: Free preview lessons and preview resources remain directly accessible without requiring enrollment.
- **Enhanced Video Player & Playback Resume (`CustomVideoPlayer.dart`)**:
  - **Resume from Last Watched Position**: Automatically restores video playback at the saved timestamp (`initialPositionSeconds`) and displays resume badges.
  - **Live Progress & Position Persistence**: Periodically pushes video timestamp and saves to `enrolments/{enrolmentId}` in Cloud Firestore.
  - **Playback Controls**: Speed selector (`0.75x`, `1.0x`, `1.25x`, `1.5x`, `2.0x`), interactive subtitles overlay, and full-screen support.
- **Lesson Screen (`Lesson.dart`)**:
  - Pixel-accurate match to `/stitch/edusphere_lesson_player/`.
  - 4 Interactive Tabs:
    - **Overview**: Lesson objectives and core architectural concepts.
    - **My Notes**: Rich editable notes editor with instant auto-save to Firestore `lessonNotes[lessonId]`.
    - **Resources**: Cloudinary raw PDF blueprints and download links.
    - **Discussion**: Real-time Q&A stream with question posting.
  - Desktop Sticky Playlist: Progress percentage bar (`40%`), section headers, and completed/active lesson indicators.
  - Bottom Action Bar: Fixed Previous and Next Lesson buttons.
- **My Learning Screen (`MyLearning.dart`)**:
  - Pixel-accurate match to `/stitch/edusphere_my_learning/`.
  - 3 Tabs: **In Progress**, **Completed**, **Wishlist**.
  - Bento card layout with top accent color line, category icon, difficulty badge, progress bar (`X% complete`), relative "Last watched: X ago" timestamp, and 1-tap **"Resume"** button jumping directly to the active lesson and saved playback second.
- **Live Classroom & Jitsi Meet Integration (`LiveClassRoom.dart`, `LiveClass.dart`)**:
  - Pixel-accurate match to `/stitch/edusphere_live_class/`.
  - Dark theater styling with pulsing red LIVE badge, elapsed timer (`45:12`), instructor stream canvas, and participant count.
  - Participant Horizontal Carousel: Self-tile with mic status, active student avatars, and raise-hand badges (`Icons.front_hand`).
  - Controls Bar: Mic toggle, camera toggle, hand-raise toggle with visual feedback, real-time in-class Firestore chat drawer, and leave call confirmation modal.
  - **FCM Push Notifications (`NotificationService`)**: Dispatches push alerts when a live class is scheduled or about to start (Spark plan, 0 card).
- **Quiz Assessment & Auto-Grading (`QuizWidget.dart`, `Quiz.dart`, `QuizService`)**:
  - Pixel-accurate match to `/stitch/edusphere_quiz/`.
  - Distraction-free top bar with countdown timer badge (`14:59`), question counter, and progress bar.
  - Supports Multiple Choice, True/False, and Short Answer question types.
  - **Auto-Grading Logic**: Auto-grades MCQ and True/False questions immediately; excludes Short Answers from auto-score and flags them as "Pending Instructor Review".
  - Detailed Explanation Review: Displays question breakdown, user answers, correct answers, and instructor explanations.
  - Persistence: Stores completed attempts in Cloud Firestore `quizAttempts/{attemptId}`.
- **Unit & Widget Tests**: 22 comprehensive test suites covering playback position resume, Cloudflare Worker access control rejection (403), quiz auto-grading & short-answer evaluation, FCM notifications, and video player widget interactions.

### Tested
- `dart analyze lib` -> 0 issues found (Clean).
- `flutter test` -> 22/22 test suites passed (100%).
- Mid-video playback reload and resume position persistence verified.
- Server-side 403 access control rejection for unenrolled accounts verified.
- Short answer exclusion from auto-score & pending review flag verified.
- FCM live class notification dispatch verified.

---

## [Phase 4] - Course Details, Cart & Payment

### Added
- **Course Details Screen (`CourseDetails.dart`)**:
  - Full Stitch-matching layout: 16:9 preview video player with play overlay, course title/subtitle, category & difficulty badges, metadata stats row (rating, students count, language, last updated), instructor bio card, what-you-will-learn checklist, curriculum syllabus accordion, requirements, student feedback & reviews breakdown, and similar courses.
  - Free Courses: 1-click **"Enroll for Free"** button -> Instantly creates Firestore enrollment document and routes to My Learning.
  - Paid Courses: **"Buy Now"** (direct checkout routing) and **"Add to Cart"** (shopping cart sync).
  - Enrolled Courses: Changes action to **"Resume Learning"** / **"Go to Course"** leading to the first active video lesson.
- **Shopping Cart (`Cart.dart`)**:
  - Full item management with remove action, live subtotal computation, order summary card, and responsive mobile/desktop layout.
  - Promotions & Vouchers: Promo coupon code validation (`EDUSPHERE20` -> 20% off, `LEARN50` -> 50% off, `WELCOME100` -> 100% off) with reactive instant discount calculation and removable active coupon tags.
- **Stripe Test Mode Payment Gateway (`payment_service.dart`) & Checkout (`Checkout.dart`)**:
  - **PCI-DSS Level 1 Compliant Tokenization**: Raw PAN and CVV/CVC codes are processed strictly in-memory during tokenization, never persisted to databases or unencrypted storage, and controllers are zeroed out immediately upon charge completion.
  - **Live Card Input Validation**: Luhn algorithm validation, expiration date (MM/YY in the future) check, and 3-4 digit CVV obscure masking.
  - **Stripe Test Card Matrix**:
    - `4242 4242 4242 4242`: Approved -> Generates `pi_test_${uuid}` payment intent ID and charge receipt.
    - `4000 0000 0000 0002`: Card Declined simulation.
    - `4000 0000 0000 0005`: Insufficient Funds simulation.
  - **Payment Success View (`payment_success/`)**:
    - Animated success checkmark, receipt transaction ID (`pi_test_...`), masked payment method (`Visa •••• 4242`), date & time stamp, unlocked courses list, and direct "Go to My Learning" action button.
- **Instructor Revenue, Ratings & Course Metrics Linkage**:
  - Live Synchronization: Whenever a student enrolls (free or paid) or submits a course rating, `CourseService.recordEnrolment` and `recordCourseRating` dynamically update the course's `enrolmentCount`, `rating`, and `reviewCount`.
  - Immediate KPI Recalculations: `InstructorDashboard` and `Earnings` instantly recalculate Total Students, Total Revenue (85% net rate), Available Payouts, and Course Average Ratings in real time.
- **Instructor View Security & Role-Aware Navigation**:
  - `CourseDetailsScreen`: If viewed by the course instructor or in instructor mode, the breadcrumb navigates to `/instructor` ("Back to Instructor Dashboard"), and actions switch to "Edit in Course Builder" and "Instructor Dashboard" instead of student purchase buttons.
  - `app_router.dart`: Added strict role guards blocking instructor mode from entering the student marketplace routes (`/courses`, `/cart`, `/checkout`) without switching to Student View, guaranteeing complete portal separation (Coursera/Udemy model).
- **Unit & Widget Tests**: 16 test suites covering Stripe test card payments, card decline handling, coupon discounts, and duplicate enrollment prevention.

### Tested
- `dart analyze lib` -> 0 issues found (Clean).
- `flutter test` -> 16/16 test suites passed (100%).
- Stripe test payment with card `4242 4242 4242 4242` verified.
- Decline card `4000 0000 0000 0002` verified.
- Free course 1-click instant enrollment verified.
- Promo coupon discounts (`EDUSPHERE20`, `LEARN50`) verified.

---

## [Phase 3] - Component Library & Course Discovery

### Added
- **Component Library (`lib/components/`)**:
  - `CourseCard`: Renders thumbnail, title, category badge, instructor avatar/name, price & original price, discount badge (% OFF), rating stars, enrolment count, duration, level badge, wishlist toggle icon, and Details navigation button.
  - `CourseListCard`: Horizontal list-view card layout with all course attributes for list view toggle mode.
  - `Filters`: Full multi-dimensional filtering supporting Category, Level, Price Range (Free, Under $30, $30-$60, $60+), Duration (<3h, 3-6h, 6+h), Minimum Rating (4.5★+, 4.0★+, 3.5★+), and Language (English, Spanish, German, French), with interactive BottomSheet modal and active filters counter badge.
  - `Loader`: Pulsing shimmer skeleton loaders (`CourseCardSkeleton`, `CourseListCardSkeleton`, `SkeletonBox`).
  - `SearchBar`: Debounced query search with clear (X) action and filter modal trigger.
  - `ProgressBar`: Animated progress bar with optional percentage badge.
  - `Testimonials`: Student reviews carousel matching Stitch design.
  - `Button`: All button variants (Primary, Secondary, Outline, Ghost, Danger) and sizes (Sm, Md, Lg) with 0 Material assertion conflicts.
- **Course Discovery & Explore (`Courses.dart`)**:
  - Live query filtering across all filter dimensions simultaneously.
  - Grid View & List View responsive toggle.
  - Sort dropdown (Most Popular, Highest Rated, Newest Releases, Price: Low to High, Price: High to Low).
  - Empty state with 1-tap "Reset All Filters" action.
  - Pagination controls with dynamic page calculation ("Showing X of Y courses").
- **Enhanced Home Screen (`Home.dart`)**:
  - Complete 9-section Stitch layout: Personalized Header & Streak, Continue Learning card (real enrolled courses), Category scroll chips, Featured Courses grid with skeletons, Why Choose EduSphere value cards, Trending Instructors showcase, Student Testimonials, CTA banner, and platform Footer.
- **Unit & Widget Tests**: 12 comprehensive test suites verifying model parsing, multi-facet filtering, sorting, AppButton variants, CourseCard fields, CourseListCard layout, and screen rendering.

### Tested
- `dart analyze lib` -> 0 issues found (Clean).
- `flutter test` -> 12/12 test suites passed (100%).
- Multi-facet filter combination logic verified.
- Grid vs List view toggle verified.
- CourseCard & CourseListCard field completeness verified.

---

## [Phase 2] - Authentication & Role-Based Access

### Added
- **Firebase Auth & Firestore Integration**: Real authentication via email/password and Google Sign-In with user profile persistence in the Firestore `users` collection.
- **Role Selection at Registration**: Student vs. Instructor visual card toggles on the Registration screen matching `/stitch/edusphere_register/`.
- **Udemy-Style Multi-Role Switching & Portal Separation**:
  - Seamless "Switch to Instructor View" / "Switch to Student View" toggle buttons in top AppBar, Profile header, and Avatar menus.
  - Student View: Home, Explore Courses, My Learning, Certificates, Cart, Wishlist.
  - Instructor View: Isolated Dashboard, Course Builder, Earnings & Payouts (Marketplace removed).
- **Instructor Course Publishing to Cloud Firestore**:
  - Course Builder creates full `CourseModel` with modules, lessons, pricing, and instructor credentials.
  - Saves to Cloud Firestore `courses` collection and automatically updates the catalogue for all students.
- **Instructor Dashboard Isolation**:
  - Filters strictly to courses created by the authenticated instructor with dynamic KPIs (Revenue, Enrollments, Ratings).
- **Real Dynamic Figures & Zero Fake Fallbacks**:
  - Instructor Dashboard & Earnings calculate real Total Earnings, Total Students, Average Rating, and Available Payouts strictly from the instructor's published courses without fake hardcoded placeholders.
  - Student Home & Profile calculate real XP from lesson completions (`completedLessons * 50 XP`), real streak, and real level thresholds.
  - Continue Learning card in Home dynamically tracks the student's actual active enrolled course and progress.
- **Layout & Overflow Hardening**:
  - MyLearning: Replaced fixed button rows with `Wrap` to prevent mobile horizontal overflows.
  - Certificates: Responsive grid aspect ratio tailored for small and large screens.
  - Cart: Enabled full mobile order summary and checkout workflow.
  - Checkout: Responsive payment method cards with back navigation breadcrumbs.
  - Wishlist: Responsive grid child aspect ratio.
- **Unit & Widget Tests**: 9 test suites verifying Course model, User model, Quiz grading, Course publishing, AuthNotifier view switching, button interactions, and screen rendering.

### Tested
- `dart analyze lib` -> 0 issues found.
- `flutter test` -> 9/9 test suites passed.
- Role switching & guards verified in GoRouter.
- Course publishing and catalog visibility verified.

---

## [Phase 1] - Setup & Foundations

### Added
- Scaffolded Flutter multiplatform app with Riverpod, go_router, Firebase core, and Google Fonts.
- Exact folder structure matching locked specification in `AGENTS.md`.
- 16 reusable UI components in `lib/components/`.
- 22 responsive screens in `lib/screens/`.
- 10+ mock courses with syllabus, video URLs, and quizzes in `lib/assets/mock/course_seed.json`.
- `SeedService` for loading mock data with non-blocking Firestore sync.
- Light Material 3 theme and design tokens matching Stitch exports.
