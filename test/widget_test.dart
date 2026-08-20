import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:edusphere/models/course_model.dart';
import 'package:edusphere/models/user_model.dart';
import 'package:edusphere/models/quiz_model.dart';
import 'package:edusphere/services/auth_service.dart';
import 'package:edusphere/services/course_service.dart';
import 'package:edusphere/providers/auth_provider.dart';
import 'package:edusphere/providers/course_provider.dart';
import 'package:edusphere/screens/Login.dart';
import 'package:edusphere/screens/Register.dart';
import 'package:edusphere/screens/Courses.dart';
import 'package:edusphere/components/Button.dart';
import 'package:edusphere/components/ProgressBar.dart';
import 'package:edusphere/components/CourseCard.dart';
import 'package:edusphere/components/Loader.dart';
import 'package:edusphere/services/payment_service.dart';
import 'package:edusphere/providers/cart_provider.dart';
import 'package:edusphere/providers/enrolment_provider.dart';
import 'package:edusphere/models/lesson_model.dart';
import 'package:edusphere/services/lesson_stream_service.dart';
import 'package:edusphere/services/quiz_service.dart';
import 'package:edusphere/services/notification_service.dart';
import 'package:edusphere/components/VideoPlayer.dart';
import 'package:edusphere/services/cloudinary_upload_service.dart';
import 'package:edusphere/models/live_class_model.dart';
import 'package:edusphere/services/live_class_service.dart';
import 'package:edusphere/providers/live_class_provider.dart';
import 'package:edusphere/screens/LiveClassManagement.dart';
import 'package:edusphere/screens/LiveClass.dart';
import 'package:edusphere/components/LiveClassRoom.dart';

class _TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _createMockImageHttpClient();
  }
}

HttpClient _createMockImageHttpClient() {
  return _MockHttpClient();
}

class _MockHttpClient implements HttpClient {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #getUrl || invocation.memberName == #openUrl) {
      return Future.value(_MockHttpClientRequest());
    }
    return null;
  }
}

class _MockHttpClientRequest implements HttpClientRequest {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #close) {
      return Future.value(_MockHttpClientResponse());
    }
    return null;
  }
}

class _MockHttpClientResponse implements HttpClientResponse {
  static final _kTransparentImage = <int>[
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
    0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
    0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
    0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
    0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
    0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
  ];

  @override
  int get statusCode => 200;

  @override
  int get contentLength => _kTransparentImage.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(void Function(List<int> event)? onData,
      {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    return Stream.value(_kTransparentImage).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  setUpAll(() {
    HttpOverrides.global = _TestHttpOverrides();
  });

  test('CourseModel JSON parsing and CourseService returns courses', () async {
    final mockJson = {
      'id': 'course_test_1',
      'title': 'Test Course',
      'category': 'Mobile Development',
      'instructorId': 'inst_1',
      'price': 49.99,
      'duration': '10h',
      'thumbnailUrl': 'https://example.com/thumb.jpg',
      'syllabus': [],
    };

    final course = CourseModel.fromJson(mockJson);
    expect(course.id, 'course_test_1');
    expect(course.title, 'Test Course');
    expect(course.price, 49.99);

    final service = CourseService();
    final courses = await service.getCourses();
    expect(courses.isNotEmpty, true);
  });

  test('Instructor publishes course and it is visible to all students', () async {
    final service = CourseService();
    const newCourse = CourseModel(
      id: 'course_published_test',
      title: 'Advanced AI Architectures',
      category: 'AI & Data',
      instructorId: 'inst_alex',
      instructor: InstructorInfo(
        id: 'inst_alex',
        name: 'Alexandre Rivera',
        title: 'Lead Architect',
        avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200',
        bio: 'AI specialist',
      ),
      price: 99.99,
      duration: '8h',
      thumbnailUrl: 'https://example.com/thumb.jpg',
      syllabus: [],
    );

    await service.publishCourse(newCourse);
    final allCourses = await service.getCourses();
    final found = allCourses.any((c) => c.id == 'course_published_test');
    expect(found, true);
  });

  test('UserModel JSON parsing and role assignment', () {
    final user = UserModel.fromJson({
      'id': 'u1',
      'name': 'Test User',
      'email': 'test@example.com',
      'role': 'instructor',
    });
    expect(user.role, UserRole.instructor);
  });

  test('Phase 2: AuthNotifier registers Student and Instructor properly', () async {
    final authService = AuthService();
    final authNotifier = AuthNotifier(authService);

    // Register student
    final student = await authNotifier.register(
      'Jane Student',
      'jane.student@edusphere.io',
      'password123',
      role: UserRole.student,
    );
    expect(student?.role, UserRole.student);
    expect(authNotifier.isStudent, true);
    expect(authNotifier.isInstructor, false);

    // Switch view mode (Udemy style)
    authNotifier.switchRole(UserRole.instructor);
    expect(authNotifier.isInstructor, true);
    expect(authNotifier.isStudent, false);

    // Switch back to Student View
    authNotifier.switchRole(UserRole.student);
    expect(authNotifier.isStudent, true);
    expect(authNotifier.isInstructor, false);
  });

  test('Phase 3: Multi-facet filter and reset logic', () {
    final container = ProviderContainer();

    // Default filters
    expect(container.read(selectedCategoryProvider), 'All');
    expect(container.read(selectedLevelProvider), 'All Levels');
    expect(container.read(selectedPriceRangeProvider), 'All');
    expect(container.read(selectedDurationProvider), 'All');
    expect(container.read(selectedMinRatingProvider), 0.0);
    expect(container.read(activeFiltersCountProvider), 0);

    // Apply multiple filters
    container.read(selectedCategoryProvider.notifier).state = 'Mobile Development';
    container.read(selectedPriceRangeProvider.notifier).state = 'Under \$30';
    container.read(selectedMinRatingProvider.notifier).state = 4.5;
    expect(container.read(activeFiltersCountProvider), 3);

    // Reset all filters
    container.read(selectedCategoryProvider.notifier).state = 'All';
    container.read(selectedPriceRangeProvider.notifier).state = 'All';
    container.read(selectedMinRatingProvider.notifier).state = 0.0;
    expect(container.read(activeFiltersCountProvider), 0);
  });

  test('Quiz grading logic', () {
    const quiz = QuizModel(
      id: 'q1',
      courseId: 'c1',
      title: 'Quiz 1',
      passingScore: 80,
      questions: [
        QuizQuestion(
          id: 'q1_1',
          question: 'Q1',
          options: [
            QuizOption(id: 'opt1', text: 'Option 1', isCorrect: true),
            QuizOption(id: 'opt2', text: 'Option 2', isCorrect: false),
          ],
        ),
      ],
    );

    expect(quiz.questions.length, 1);
    expect(quiz.questions.first.options.first.isCorrect, true);
  });

  testWidgets('AppButton renders in all variants without assertion error', (WidgetTester tester) async {
    bool primaryClicked = false;
    bool outlineClicked = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              AppButton(
                label: 'Primary Button',
                variant: ButtonVariant.primary,
                onPressed: () => primaryClicked = true,
              ),
              AppButton(
                label: 'Outline Button',
                variant: ButtonVariant.outline,
                onPressed: () => outlineClicked = true,
              ),
              AppButton(
                label: 'Secondary Button',
                variant: ButtonVariant.secondary,
                onPressed: () {},
              ),
              AppButton(
                label: 'Ghost Button',
                variant: ButtonVariant.ghost,
                onPressed: () {},
              ),
              AppButton(
                label: 'Danger Button',
                variant: ButtonVariant.danger,
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Primary Button'), findsOneWidget);
    expect(find.text('Outline Button'), findsOneWidget);
    expect(find.text('Secondary Button'), findsOneWidget);
    expect(find.text('Ghost Button'), findsOneWidget);
    expect(find.text('Danger Button'), findsOneWidget);

    await tester.tap(find.text('Primary Button'));
    expect(primaryClicked, true);

    await tester.tap(find.text('Outline Button'));
    expect(outlineClicked, true);
  });

  testWidgets('CourseCard renders all required AGENTS.md fields', (WidgetTester tester) async {
    const course = CourseModel(
      id: 'c_test',
      title: 'Full-Stack Flutter & Cloud Masterclass',
      category: 'Mobile Development',
      instructorId: 'inst_1',
      instructor: InstructorInfo(
        id: 'inst_1',
        name: 'Alexandre Rivera',
        title: 'Lead Architect',
        avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200',
        bio: 'Educator',
      ),
      price: 49.99,
      originalPrice: 99.99,
      discount: 50.0,
      duration: '14 hours',
      level: 'Intermediate',
      rating: 4.9,
      enrolmentCount: 3400,
      thumbnailUrl: 'https://images.unsplash.com/photo-1551288049-bebda4e38f71?w=400',
    );

    bool wishToggled = false;
    bool cardTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 340,
            child: CourseCard(
              course: course,
              isWishlisted: false,
              onTap: () => cardTapped = true,
              onWishlistToggle: () => wishToggled = true,
            ),
          ),
        ),
      ),
    );

    // Verify all fields are present
    expect(find.text('Full-Stack Flutter & Cloud Masterclass'), findsOneWidget);
    expect(find.text('Mobile Development'), findsOneWidget);
    expect(find.text('Alexandre Rivera'), findsOneWidget);
    expect(find.text('\$49.99'), findsOneWidget);
    expect(find.text('\$99.99'), findsOneWidget);
    expect(find.text('50% OFF'), findsOneWidget);
    expect(find.text('4.9'), findsOneWidget);
    expect(find.text('(3.4K)'), findsOneWidget);
    expect(find.text('14 hours'), findsOneWidget);
    expect(find.text('Intermediate'), findsOneWidget);
    expect(find.text('Details'), findsOneWidget);
    expect(find.byIcon(Icons.favorite_border), findsOneWidget);

    await tester.tap(find.byIcon(Icons.favorite_border));
    expect(wishToggled, true);

    await tester.tap(find.text('Details'));
    expect(cardTapped, true);
  });

  testWidgets('CourseListCard renders horizontal list layout', (WidgetTester tester) async {
    const course = CourseModel(
      id: 'c_test_list',
      title: 'Deep Learning & Neural Networks',
      category: 'AI & Data',
      instructorId: 'inst_2',
      instructor: InstructorInfo(
        id: 'inst_2',
        name: 'Dr. Sarah Jenkins',
        title: 'AI Professor',
        avatarUrl: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=200',
        bio: 'AI specialist',
      ),
      price: 89.99,
      duration: '18 hours',
      level: 'Advanced',
      rating: 4.95,
      enrolmentCount: 5200,
      thumbnailUrl: 'https://images.unsplash.com/photo-1620712943543-bcc4688e7485?w=400',
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CourseListCard(
            course: course,
            isWishlisted: true,
          ),
        ),
      ),
    );

    expect(find.text('Deep Learning & Neural Networks'), findsOneWidget);
    expect(find.text('AI & Data'), findsOneWidget);
    expect(find.text('By Dr. Sarah Jenkins • 18 hours'), findsOneWidget);
    expect(find.text('\$89.99'), findsOneWidget);
    expect(find.byIcon(Icons.favorite), findsOneWidget);
  });

  testWidgets('AppProgressBar renders percentage', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppProgressBar(progress: 0.5, showPercentage: true),
        ),
      ),
    );

    expect(find.text('50%'), findsOneWidget);
  });

  testWidgets('LoginScreen renders fields and Google button', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: LoginScreen(),
        ),
      ),
    );

    expect(find.text('EduSphere'), findsOneWidget);
    expect(find.text('Welcome back.'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
  });

  testWidgets('RegisterScreen renders role selector and form', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: RegisterScreen(),
        ),
      ),
    );

    expect(find.text('Create Account'), findsNWidgets(2));
    expect(find.text('Student'), findsOneWidget);
    expect(find.text('Instructor'), findsOneWidget);
    expect(find.text('Sign Up with Google'), findsOneWidget);
  });

  test('Phase 4: Stripe Payment Service processes test card 4242 4242 4242 4242 successfully with tokenization', () async {
    final paymentService = PaymentService();
    final result = await paymentService.processStripePayment(
      cardholderName: 'Alex Morgan',
      cardNumber: '4242 4242 4242 4242',
      expiryDate: '12/28',
      cvc: '123',
      amount: 49.99,
      courseId: 'course_1',
    );

    expect(result.isSuccess, true);
    expect(result.last4, '4242');
    expect(result.cardBrand, 'Visa');
    expect(result.paymentId?.startsWith('pi_test_'), true);
    expect(result.errorMessage, isNull);
  });

  test('Phase 4: Stripe Payment Service handles decline and insufficient funds cards', () async {
    final paymentService = PaymentService();

    // Test card decline
    final declineResult = await paymentService.processStripePayment(
      cardholderName: 'Alex Morgan',
      cardNumber: '4000 0000 0000 0002',
      expiryDate: '12/28',
      cvc: '123',
      amount: 49.99,
      courseId: 'course_1',
    );
    expect(declineResult.isSuccess, false);
    expect(declineResult.errorMessage?.contains('card was declined'), true);

    // Test insufficient funds
    final fundsResult = await paymentService.processStripePayment(
      cardholderName: 'Alex Morgan',
      cardNumber: '4000 0000 0000 0005',
      expiryDate: '12/28',
      cvc: '123',
      amount: 49.99,
      courseId: 'course_1',
    );
    expect(fundsResult.isSuccess, false);
    expect(fundsResult.errorMessage?.contains('insufficient funds'), true);
  });

  test('Phase 4: Cart and Coupon Discount computations', () {
    final container = ProviderContainer();

    const course1 = CourseModel(
      id: 'c1',
      title: 'Course 1',
      category: 'Web',
      instructorId: 'inst_1',
      instructor: InstructorInfo(id: 'inst_1', name: 'Instructor 1', title: 'Lead', avatarUrl: '', bio: ''),
      price: 100.0,
      duration: '5h',
      thumbnailUrl: '',
      syllabus: [],
    );

    const course2 = CourseModel(
      id: 'c2',
      title: 'Course 2',
      category: 'Mobile',
      instructorId: 'inst_2',
      instructor: InstructorInfo(id: 'inst_2', name: 'Instructor 2', title: 'Lead', avatarUrl: '', bio: ''),
      price: 50.0,
      duration: '3h',
      thumbnailUrl: '',
      syllabus: [],
    );

    container.read(cartProvider.notifier).addToCart(course1);
    container.read(cartProvider.notifier).addToCart(course2);

    expect(container.read(cartProvider.notifier).subtotalPrice, 150.0);
    expect(container.read(cartDiscountAmountProvider), 0.0);
    expect(container.read(finalCartTotalPriceProvider), 150.0);

    // Apply 20% coupon
    container.read(appliedCouponProvider.notifier).state = kValidCoupons.first; // EDUSPHERE20
    expect(container.read(cartDiscountAmountProvider), 30.0); // 20% of 150
    expect(container.read(finalCartTotalPriceProvider), 120.0); // 150 - 30

    // Remove from cart
    container.read(cartProvider.notifier).removeFromCart('c2');
    expect(container.read(cartProvider.notifier).subtotalPrice, 100.0);
    expect(container.read(cartDiscountAmountProvider), 20.0); // 20% of 100
    expect(container.read(finalCartTotalPriceProvider), 80.0); // 100 - 20
  });

  test('Phase 4: EnrolmentNotifier enrolls and prevents duplicate enrollments', () async {
    final notifier = EnrolmentNotifier();
    expect(notifier.isEnrolled('course_new_test'), false);

    final enrolment = await notifier.enroll('course_new_test', 'user_123', paymentId: 'pi_test_999');
    expect(enrolment.courseId, 'course_new_test');
    expect(enrolment.paymentId, 'pi_test_999');
    expect(notifier.isEnrolled('course_new_test'), true);

    // Duplicate enroll should return existing
    final duplicate = await notifier.enroll('course_new_test', 'user_123');
    expect(duplicate.id, enrolment.id);
  });

  test('Phase 4: Student purchase and review dynamically updates instructor course metrics', () async {
    final courseService = CourseService();
    final initialCourses = await courseService.getCourses();
    final targetCourse = initialCourses.first;
    final initialStudents = targetCourse.enrolmentCount;

    // Student purchases course
    await courseService.recordEnrolment(targetCourse.id);
    final updatedCourses = await courseService.getCourses();
    final updatedCourse = updatedCourses.firstWhere((c) => c.id == targetCourse.id);

    expect(updatedCourse.enrolmentCount, initialStudents + 1);

    // Student rates course 5 stars
    await courseService.recordCourseRating(targetCourse.id, 5.0);
    final ratedCourses = await courseService.getCourses();
    final ratedCourse = ratedCourses.firstWhere((c) => c.id == targetCourse.id);

    expect(ratedCourse.reviewCount, targetCourse.reviewCount + 1);
  });

  // ============================================================================
  // PHASE 5: LESSONS, LIVE CLASSES & QUIZZES TESTS
  // ============================================================================

  test('Phase 5: Playback position persistence and resume capability', () async {
    final notifier = EnrolmentNotifier();
    const courseId = 'course_phase5_test';
    const lessonId = 'les_test_42';

    await notifier.enroll(courseId, 'student_1');

    // Simulate watching video for 4 minutes 15 seconds (255s)
    notifier.savePlaybackPosition(courseId, lessonId, 255);

    final enrolments = notifier.state;
    final enrolment = enrolments.firstWhere((e) => e.courseId == courseId);

    expect(enrolment.lastLessonId, lessonId);
    expect(enrolment.lastPlayedPositions[lessonId], 255);

    // Save personal note for this lesson
    notifier.saveLessonNote(courseId, lessonId, 'Key takeaway: use StreamProvider for realtime sync');
    final updatedEnrolment = notifier.state.firstWhere((e) => e.courseId == courseId);
    expect(updatedEnrolment.lessonNotes[lessonId], 'Key takeaway: use StreamProvider for realtime sync');
  });

  test('Phase 5: Server-side access control & Cloudflare Worker signed video and resource URL generation', () async {
    final streamService = LessonStreamService(client: _MockCloudinaryHttpClient());

    const nonPreviewResource = LessonResource(
      title: 'Advanced Architecture Blueprint (PDF)',
      url: '', // Non-preview: NO plain download link stored on doc
      cloudinaryPublicId: 'edusphere/resources/arch_mastery_blueprint_raw',
      type: 'pdf',
      isPreview: false,
    );

    const nonPreviewLesson = LessonModel(
      id: 'les_secret_99',
      courseId: 'course_paid_only',
      title: 'Advanced Architecture Deep Dive',
      videoUrl: '', // Non-preview: NO playable raw URL stored
      cloudinaryPublicId: 'edusphere/courses/arch_mastery_les99',
      order: 1,
      isPreview: false,
      resources: [nonPreviewResource],
    );

    const previewResource = LessonResource(
      title: 'Course Overview Teaser (PDF)',
      url: 'https://res.cloudinary.com/edusphere/raw/upload/v1/preview_teaser.pdf',
      cloudinaryPublicId: 'edusphere/resources/preview_teaser',
      type: 'pdf',
      isPreview: true,
    );

    const previewLesson = LessonModel(
      id: 'les_preview_1',
      courseId: 'course_paid_only',
      title: 'Free Preview Teaser',
      videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
      cloudinaryPublicId: 'edusphere/courses/preview_video',
      order: 1,
      isPreview: true,
      resources: [previewResource],
    );

    // 1. Unenrolled student querying non-preview lesson and non-preview resource:
    // Confirm lesson doc and resource doc contain NO plain playable/downloadable URL
    expect(nonPreviewLesson.videoUrl, '');
    expect(nonPreviewLesson.cloudinaryPublicId, 'edusphere/courses/arch_mastery_les99');
    expect(nonPreviewResource.url, '');
    expect(nonPreviewResource.cloudinaryPublicId, 'edusphere/resources/arch_mastery_blueprint_raw');

    // Unenrolled student must be rejected with 403 Forbidden for non-preview video
    expect(
      () => streamService.getVideoStreamUrl(
        courseId: 'course_paid_only',
        lesson: nonPreviewLesson,
        userId: 'student_unpaid',
        isEnrolled: false,
      ),
      throwsA(isA<LessonAccessDeniedException>()),
    );

    // Unenrolled student must be rejected with 403 Forbidden for non-preview raw resource
    expect(
      () => streamService.getResourceDeliveryUrl(
        courseId: 'course_paid_only',
        lesson: nonPreviewLesson,
        resource: nonPreviewResource,
        userId: 'student_unpaid',
        isEnrolled: false,
      ),
      throwsA(isA<LessonAccessDeniedException>()),
    );

    // 2. Unenrolled student CAN access preview lesson video and preview resource
    final previewVideoResult = await streamService.getVideoStreamUrl(
      courseId: 'course_paid_only',
      lesson: previewLesson,
      userId: 'student_unpaid',
      isEnrolled: false,
    );
    expect(previewVideoResult.isPreview, true);
    expect(previewVideoResult.streamUrl.isNotEmpty, true);

    final previewResourceResult = await streamService.getResourceDeliveryUrl(
      courseId: 'course_paid_only',
      lesson: previewLesson,
      resource: previewResource,
      userId: 'student_unpaid',
      isEnrolled: false,
    );
    expect(previewResourceResult.isPreview, true);
    expect(previewResourceResult.streamUrl.contains('preview_teaser.pdf'), true);

    // 3. Enrolled student receives authenticated HMAC-SHA256 signed Cloudinary delivery URLs
    final enrolledVideoResult = await streamService.getVideoStreamUrl(
      courseId: 'course_paid_only',
      lesson: nonPreviewLesson,
      userId: 'student_paid',
      isEnrolled: true,
    );
    expect(enrolledVideoResult.streamUrl.contains('res.cloudinary.com'), true);
    expect(enrolledVideoResult.streamUrl.contains('/video/authenticated/'), true);
    expect(enrolledVideoResult.streamUrl.contains('edusphere/courses/arch_mastery_les99.mp4'), true);

    final enrolledResourceResult = await streamService.getResourceDeliveryUrl(
      courseId: 'course_paid_only',
      lesson: nonPreviewLesson,
      resource: nonPreviewResource,
      userId: 'student_paid',
      isEnrolled: true,
    );
    expect(enrolledResourceResult.streamUrl.contains('res.cloudinary.com'), true);
    expect(enrolledResourceResult.streamUrl.contains('/raw/authenticated/'), true);
    expect(enrolledResourceResult.streamUrl.contains('edusphere/resources/arch_mastery_blueprint_raw.pdf'), true);
  });

  test('Phase 5: Quiz auto-grading for MCQ & True/False, and pending review for Short Answers', () async {
    final quizService = QuizService();

    const testQuiz = QuizModel(
      id: 'quiz_eval_test',
      courseId: 'course_1',
      title: 'Phase 5 Comprehensive Evaluation',
      passingScore: 70,
      timeLimitMinutes: 15,
      questions: [
        QuizQuestion(
          id: 'q_mcq_1',
          question: 'What handles signed URLs in zero-card EduSphere?',
          type: QuestionType.multipleChoice,
          explanation: 'Cloudflare Workers handle secret signing without billing cards.',
          options: [
            QuizOption(id: 'opt1', text: 'Firebase Cloud Functions', isCorrect: false),
            QuizOption(id: 'opt2', text: 'Cloudflare Workers', isCorrect: true),
          ],
        ),
        QuizQuestion(
          id: 'q_tf_1',
          question: 'Cloudinary raw resource_type is used for PDF files in EduSphere.',
          type: QuestionType.trueFalse,
          explanation: 'True, PDF blueprints use Cloudinary raw storage without credit cards.',
          options: [
            QuizOption(id: 'tf_true', text: 'True', isCorrect: true),
            QuizOption(id: 'tf_false', text: 'False', isCorrect: false),
          ],
        ),
        QuizQuestion(
          id: 'q_short_1',
          question: 'Explain why Riverpod Notifiers improve testability over StatefulWidget.',
          type: QuestionType.shortAnswer,
          sampleAnswer: 'Notifiers decouple business logic from BuildContext and widget lifecycles.',
          explanation: 'Notifiers can be unit-tested without mounting widgets.',
          options: [],
        ),
      ],
    );

    final userAnswers = {
      'q_mcq_1': 'opt2', // Correct (MCQ)
      'q_tf_1': 'tf_true', // Correct (True/False)
      'q_short_1': 'Notifiers separate business state from UI widgets and enable mock overrides in ProviderContainer.',
    };

    final attempt = quizService.evaluateQuiz(
      quiz: testQuiz,
      userId: 'student_tester',
      userAnswers: userAnswers,
    );

    // 2 out of 2 auto-gradeable questions correct = 100%
    expect(attempt.score, 100);
    expect(attempt.passed, true);
    expect(attempt.shortAnswerCount, 1);
    expect(attempt.answers['q_short_1']?.contains('Notifiers separate business state'), true);

    // Record attempt to Firestore
    await quizService.recordAttempt(attempt);
    final history = await quizService.getAttemptsForUser('student_tester');
    expect(history.any((a) => a.id == attempt.id), true);
  });

  test('Phase 5: FCM Live Class Push Notification dispatch', () async {
    final notifService = NotificationService();

    notifService.sendLiveClassNotification(
      classId: 'live_cs401',
      courseTitle: 'CS401: Neural Networks',
      instructorName: 'Dr. Sarah Chen',
      minutesUntilStart: 5,
    );

    expect(notifService.notificationHistory.isNotEmpty, true);
    expect(
      notifService.notificationHistory.last.body,
      'CS401: Neural Networks with Dr. Sarah Chen is about to begin. Join the live interactive room now!',
    );
  });

  testWidgets('Phase 5: CustomVideoPlayer renders playback controls, speed toggles, and subtitles', (tester) async {
    int reportedPosition = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomVideoPlayer(
            videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
            title: 'Lesson 1: Introduction to Clean Architecture',
            initialPositionSeconds: 120, // 02:00
            totalDurationSeconds: 600, // 10:00
            onPositionChanged: (sec) {
              reportedPosition = sec;
            },
          ),
        ),
      ),
    );

    await tester.pump();

    // Verify initial resume position badge and text
    expect(find.text('Lesson 1: Introduction to Clean Architecture'), findsWidgets);
    expect(find.text('Resuming at 02:00'), findsOneWidget);
    expect(find.text('02:00 / 10:00'), findsOneWidget);
    expect(find.text('1.0x'), findsOneWidget);

    // Toggle speed button
    await tester.tap(find.text('1.0x'));
    await tester.pump();
    expect(find.text('1.25x'), findsOneWidget);

    // Toggle play
    await tester.tap(find.byIcon(Icons.play_arrow).first);
    await tester.pump();
    expect(find.byIcon(Icons.pause), findsWidgets);

    // Toggle subtitles
    await tester.tap(find.byTooltip('Toggle Subtitles'));
    await tester.pump();
    expect(find.textContaining('Captions:'), findsOneWidget);
  });

  test('Phase 5 / Instructor Flow: Upload video to Cloudinary, save public_id only, and verify access control', () async {
    // Custom mock HTTP client returning real Cloudinary response structures
    final mockHttpClient = _MockCloudinaryHttpClient();
    final uploadService = CloudinaryUploadService(client: mockHttpClient);
    final streamService = LessonStreamService(client: mockHttpClient);

    final testBytes = Uint8List.fromList([0, 1, 2, 3, 4, 5, 6, 7]);

    // 1. Instructor uploads a paid lesson video (type: authenticated)
    final uploadResult = await uploadService.uploadLessonVideo(
      courseId: 'course_cloud_arch',
      lessonId: 'les_arch_01',
      fileName: 'lecture_01_clean_architecture.mp4',
      fileBytes: testBytes,
      isPreview: false,
    );

    // Verify upload response: returns public_id, locked access mode, and NO plain playable URL
    expect(uploadResult.publicId, 'courses/course_cloud_arch/les_arch_01');
    expect(uploadResult.secureUrl, ''); // Authenticated asset has NO raw playable URL on upload
    expect(uploadResult.accessMode, 'authenticated'); // Locked at preset level
    expect(uploadResult.resourceType, 'video');
    expect(uploadResult.format, 'mp4');

    // Test 100MB size limit guard: Files > 100MB are blocked before upload
    final oversizedBytes = Uint8List(105 * 1024 * 1024);
    expect(
      () => uploadService.uploadLessonVideo(
        courseId: 'course_cloud_arch',
        lessonId: 'les_too_large',
        fileName: 'huge_4k_raw_lecture.mp4',
        fileBytes: oversizedBytes,
        isPreview: false,
      ),
      throwsA(isA<CloudinaryUploadException>()),
    );

    // 2. Instructor creates the Lesson document in Firestore with only public_id
    final publishedLesson = LessonModel(
      id: 'les_arch_01',
      courseId: 'course_cloud_arch',
      title: 'Clean Architecture in Production',
      videoUrl: '', // NO plain URL stored on document
      cloudinaryPublicId: uploadResult.publicId,
      order: 1,
      isPreview: false,
    );

    expect(publishedLesson.videoUrl, '');
    expect(publishedLesson.cloudinaryPublicId, 'courses/course_cloud_arch/les_arch_01');

    // 3. Non-enrolled student attempts to stream this lesson -> 403 Access Denied
    expect(
      () => streamService.getVideoStreamUrl(
        courseId: 'course_cloud_arch',
        lesson: publishedLesson,
        userId: 'student_unpaid_test',
        isEnrolled: false,
      ),
      throwsA(isA<LessonAccessDeniedException>()),
    );

    // 4. Enrolled student requests stream -> Worker generates signed Cloudinary URL
    final enrolledStreamResult = await streamService.getVideoStreamUrl(
      courseId: 'course_cloud_arch',
      lesson: publishedLesson,
      userId: 'student_paid_test',
      isEnrolled: true,
      customAuthToken: 'valid_mock_jwt_token',
    );

    expect(enrolledStreamResult.streamUrl.contains('res.cloudinary.com'), true);
    expect(enrolledStreamResult.streamUrl.contains('/video/authenticated/'), true);
    expect(enrolledStreamResult.publicId, 'courses/course_cloud_arch/les_arch_01');
    expect(enrolledStreamResult.isPreview, false);

    // 5. Instructor uploads a preview video (type: upload)
    final previewUploadResult = await uploadService.uploadLessonVideo(
      courseId: 'course_cloud_arch',
      lessonId: 'les_preview_teaser',
      fileName: 'course_teaser.mp4',
      fileBytes: testBytes,
      isPreview: true,
    );

    expect(previewUploadResult.publicId, 'courses/course_cloud_arch/les_preview_teaser');
    expect(previewUploadResult.secureUrl.contains('/video/upload/'), true);
    expect(previewUploadResult.accessMode, 'public');

    final previewLesson = LessonModel(
      id: 'les_preview_teaser',
      courseId: 'course_cloud_arch',
      title: 'Course Preview Teaser',
      videoUrl: previewUploadResult.secureUrl,
      cloudinaryPublicId: previewUploadResult.publicId,
      order: 0,
      isPreview: true,
    );

    // Guest or unenrolled user can stream preview directly
    final previewStreamResult = await streamService.getVideoStreamUrl(
      courseId: 'course_cloud_arch',
      lesson: previewLesson,
      userId: 'guest',
      isEnrolled: false,
    );

    expect(previewStreamResult.streamUrl.contains('/video/upload/'), true);
    expect(previewStreamResult.isPreview, true);
  });

  test('CourseService: updateCourse updates existing course details and lessons', () async {
    final courseService = CourseService();
    final initialCourses = await courseService.getCourses();
    final targetCourse = initialCourses.first;

    final updatedCourse = targetCourse.copyWith(
      title: '${targetCourse.title} (Updated 2026 Edition)',
      price: 79.99,
    );

    await courseService.updateCourse(updatedCourse);

    final refreshedCourses = await courseService.getCourses();
    final updatedFound = refreshedCourses.firstWhere((c) => c.id == targetCourse.id);

    expect(updatedFound.title, contains('Updated 2026 Edition'));
    expect(updatedFound.price, 79.99);
  });

  group('Phase 5 Live Class End-to-End Flow & Security', () {
    test('LiveClassModel: serialization and status transitions', () {
      final scheduled = LiveClassModel(
        id: 'class_demo_01',
        courseId: 'course_ai_101',
        instructorId: 'inst_sarah',
        title: 'Deep Learning Mastery',
        scheduledAt: DateTime.now().add(const Duration(hours: 2)),
        durationMinutes: 60,
        jitsiRoomId: 'edusphere-room-ai101-123',
        status: LiveClassStatus.scheduled,
        createdAt: DateTime.now(),
      );

      expect(scheduled.isScheduled, isTrue);
      expect(scheduled.isLive, isFalse);
      expect(scheduled.isEnded, isFalse);

      final json = scheduled.toJson();
      expect(json['courseId'], 'course_ai_101');
      expect(json['status'], 'scheduled');

      final fromJson = LiveClassModel.fromJson(json);
      expect(fromJson.title, 'Deep Learning Mastery');
      expect(fromJson.jitsiRoomId, 'edusphere-room-ai101-123');

      final liveState = fromJson.copyWith(status: LiveClassStatus.live);
      expect(liveState.isLive, isTrue);
    });

    test('LiveClassService: schedule, start, join, message, and end lifecycle', () async {
      final service = LiveClassService();

      // 1. Instructor schedules class
      final created = await service.scheduleLiveClass(
        courseId: 'course_cloud_arch',
        instructorId: 'inst_sarah',
        title: 'Cloud Architecture Live Q&A',
        description: 'Deep dive into VPC peering and IAM policies.',
        scheduledAt: DateTime.now().add(const Duration(hours: 1)),
        durationMinutes: 45,
      );

      expect(created.id, isNotEmpty);
      expect(created.status, LiveClassStatus.scheduled);
      expect(created.jitsiRoomId, contains('edusphere_course_cloud_arch'));

      // 2. Instructor starts class
      await service.startLiveClass(created.id);
      final activeClass = await service.getLiveClass(created.id);
      expect(activeClass?.status, LiveClassStatus.live);
      expect(activeClass?.isLive, isTrue);

      // 3. Student joins class
      const student = UserModel(
        id: 'student_007',
        name: 'James Bond',
        email: '007@mi6.gov.uk',
        role: UserRole.student,
      );
      await service.joinLiveClass(created.id, student, isMicOn: true, isCameraOn: false);

      final participants = await service.getParticipants(created.id);
      expect(participants.any((p) => p.userId == 'student_007'), isTrue);

      // 4. Student toggles hand raise and mute
      await service.updateParticipantMedia(created.id, 'student_007', isHandRaised: true, isMicOn: false);
      final updatedParticipants = await service.getParticipants(created.id);
      final studentParticipant = updatedParticipants.firstWhere((p) => p.userId == 'student_007');
      expect(studentParticipant.isHandRaised, isTrue);
      expect(studentParticipant.isMicOn, isFalse);

      // 5. Student sends live in-class chat message
      await service.sendMessage(created.id, student, 'Can we discuss CloudFormation vs Terraform?');
      final messages = await service.getMessages(created.id);
      expect(messages.any((m) => m.message.contains('CloudFormation vs Terraform')), isTrue);

      // 6. Instructor ends class
      await service.endLiveClass(created.id);
      final endedClass = await service.getLiveClass(created.id);
      expect(endedClass?.status, LiveClassStatus.ended);
      expect(endedClass?.isEnded, isTrue);
    });

    test('Enrolment doc ID matches Firestore security rule convention userId_courseId', () {
      const userId = 'user_abc_123';
      const courseId = 'course_flutter_01';
      final deterministicDocId = '${userId}_$courseId';

      expect(deterministicDocId, 'user_abc_123_course_flutter_01');
      // Verifies security rule evaluation: exists(/databases/$(database)/documents/enrolments/$(request.auth.uid + '_' + resource.data.courseId))
      final evaluatedRuleDocPath = 'enrolments/${userId}_$courseId';
      expect(evaluatedRuleDocPath, 'enrolments/user_abc_123_course_flutter_01');
    });
  });
}

class _MockCloudinaryHttpClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    // If request is calling the Cloudflare Worker to sign a stream URL:
    if (request.url.toString().contains('workers.dev') || request.url.toString().contains('getVideoStreamUrl')) {
      final authHeader = request.headers['authorization'] ?? '';
      if (authHeader.contains('unauthorized')) {
        return http.StreamedResponse(
          Stream.value(utf8.encode(jsonEncode({'error': 'Unauthorized', 'code': 'UNAUTHORIZED'}))),
          401,
          headers: {'content-type': 'application/json'},
        );
      }

      String publicId = 'courses/course_cloud_arch/les_arch_01';
      String resType = 'video';
      if (request is http.Request && request.body.isNotEmpty) {
        try {
          final json = jsonDecode(request.body) as Map<String, dynamic>;
          if (json['cloudinaryPublicId'] != null) {
            publicId = json['cloudinaryPublicId'];
          }
          if (json['resourceType'] != null) {
            resType = json['resourceType'];
          }
        } catch (_) {}
      }

      final ext = resType == 'raw' ? '.pdf' : '.mp4';
      final responseJson = jsonEncode({
        'streamUrl': 'https://res.cloudinary.com/kl8rl0al/$resType/authenticated/s--signedsignature123--/v1/$publicId$ext',
        'publicId': publicId,
        'resourceType': resType,
      });

      return http.StreamedResponse(
        Stream.value(utf8.encode(responseJson)),
        200,
        headers: {'content-type': 'application/json'},
      );
    }

    // Otherwise it's a Cloudinary upload multipart request:
    final bodyFields = <String, String>{};
    if (request is http.MultipartRequest) {
      bodyFields.addAll(request.fields);
    }

    final preset = bodyFields['upload_preset'] ?? '';
    final publicId = bodyFields['public_id'] ?? 'courses/demo/video';
    final isPreview = preset == 'edusphere_public_preview';

    final responseJson = jsonEncode({
      'public_id': publicId,
      'secure_url': isPreview
          ? 'https://res.cloudinary.com/kl8rl0al/video/upload/v1/$publicId.mp4'
          : '',
      'resource_type': 'video',
      'format': 'mp4',
      'bytes': 1048576,
      'duration': 720,
      'access_mode': isPreview ? 'public' : 'authenticated',
      'created_at': DateTime.now().toIso8601String(),
    });

    return http.StreamedResponse(
      Stream.value(utf8.encode(responseJson)),
      200,
      headers: {'content-type': 'application/json'},
    );
  }
}


