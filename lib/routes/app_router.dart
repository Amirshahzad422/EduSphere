import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../styles/colors.dart';
import '../layouts/MainLayout.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../screens/Splash.dart';
import '../screens/Onboarding.dart';
import '../screens/Login.dart';
import '../screens/Register.dart';
import '../screens/Home.dart';
import '../screens/Courses.dart';
import '../screens/CourseDetails.dart';
import '../screens/Lesson.dart';
import '../screens/LiveClass.dart';
import '../screens/Quiz.dart';
import '../screens/MyLearning.dart';
import '../screens/Certificates.dart';
import '../screens/Cart.dart';
import '../screens/Checkout.dart';
import '../screens/Wishlist.dart';
import '../screens/Profile.dart';
import '../screens/InstructorDashboard.dart';
import '../screens/CourseBuilder.dart';
import '../screens/LiveClassManagement.dart';
import '../screens/Earnings.dart';
import '../screens/About.dart';
import '../screens/Contact.dart';
import '../screens/NotFound.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

/// List of routes that require instructor role
const _instructorOnlyRoutes = ['/instructor', '/builder', '/earnings', '/instructor/live-classes'];

/// List of routes that require user authentication
const _authenticatedOnlyRoutes = [
  '/my-learning',
  '/checkout',
  '/profile',
  '/certificates',
  '/instructor',
  '/builder',
  '/earnings',
  '/instructor/live-classes',
];

class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(Ref ref) {
    ref.listen<UserModel?>(authProvider, (_, __) {
      notifyListeners();
    });
  }
}

/// Instant, zero-ghosting tab transition for root shell tabs
Page<void> _buildTabTransitionPage({
  required LocalKey key,
  required Widget child,
}) {
  return NoTransitionPage<void>(
    key: key,
    child: child,
  );
}

/// Fast, smooth, solid slide transition for detail screens & actions without double-screen transparency artifacts
CustomTransitionPage<void> _buildSmoothSlidePage({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: key,
    child: Material(
      color: AppColors.background,
      child: child,
    ),
    transitionDuration: const Duration(milliseconds: 200),
    reverseTransitionDuration: const Duration(milliseconds: 180),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.fastEaseInToSlowEaseOut,
        reverseCurve: Curves.easeInQuad,
      );
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.12, 0),
          end: Offset.zero,
        ).animate(curvedAnimation),
        child: child,
      );
    },
  );
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _RouterRefreshNotifier(ref);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: refreshNotifier,
    errorBuilder: (context, state) => const NotFoundScreen(),
    redirect: (context, state) {
      final authUser = ref.read(authProvider);
      final loc = state.matchedLocation;
      final isAuth = authUser != null;
      final isStudent = authUser?.role == UserRole.student;
      final isInstructor = authUser?.role == UserRole.instructor;

      // 1. Auth guard: Redirect unauthenticated guests trying to access protected screens
      if (!isAuth && _authenticatedOnlyRoutes.contains(loc)) {
        return '/login?redirect=$loc';
      }

      // 2. Instructor session routing: If authenticated as Instructor and lands on splash/home/marketplace, route to /instructor
      if (isAuth && isInstructor && (loc == '/' || loc == '/splash' || loc == '/home' || loc == '/courses' || loc == '/cart')) {
        return '/instructor';
      }

      // 3. Role guard: Prevent Students from opening Instructor pages
      if (isAuth && isStudent && _instructorOnlyRoutes.contains(loc)) {
        debugPrint('[Router Guard] Blocked student access to instructor route $loc. Redirecting to /home');
        return '/home';
      }

      return null;
    },
    routes: [
      // Standalone Screens
      GoRoute(
        path: '/splash',
        pageBuilder: (context, state) => _buildSmoothSlidePage(key: state.pageKey, child: const SplashScreen()),
      ),
      GoRoute(
        path: '/onboarding',
        pageBuilder: (context, state) => _buildSmoothSlidePage(key: state.pageKey, child: const OnboardingScreen()),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => _buildSmoothSlidePage(key: state.pageKey, child: const LoginScreen()),
      ),
      GoRoute(
        path: '/register',
        pageBuilder: (context, state) => _buildSmoothSlidePage(key: state.pageKey, child: const RegisterScreen()),
      ),

      // App Shell Route wrapped in MainLayout (AppBar + BottomNav)
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return MainLayout(child: child);
        },
        routes: [
          // Primary Tabs (Instant, clean, zero ghosting)
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) => _buildTabTransitionPage(key: state.pageKey, child: const HomeScreen()),
          ),
          GoRoute(
            path: '/courses',
            pageBuilder: (context, state) => _buildTabTransitionPage(key: state.pageKey, child: const CoursesScreen()),
          ),
          GoRoute(
            path: '/my-learning',
            pageBuilder: (context, state) => _buildTabTransitionPage(key: state.pageKey, child: const MyLearningScreen()),
          ),
          GoRoute(
            path: '/wishlist',
            pageBuilder: (context, state) => _buildTabTransitionPage(key: state.pageKey, child: const WishlistScreen()),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) => _buildTabTransitionPage(key: state.pageKey, child: const ProfileScreen()),
          ),
          GoRoute(
            path: '/instructor',
            pageBuilder: (context, state) => _buildTabTransitionPage(key: state.pageKey, child: const InstructorDashboardScreen()),
          ),

          // Detail & Action Screens (Fast, smooth, solid slide)
          GoRoute(
            path: '/course/:id',
            pageBuilder: (context, state) {
              final id = state.pathParameters['id'] ?? 'course_1';
              return _buildSmoothSlidePage(key: state.pageKey, child: CourseDetailsScreen(courseId: id));
            },
          ),
          GoRoute(
            path: '/lesson/:courseId/:lessonId',
            pageBuilder: (context, state) {
              final courseId = state.pathParameters['courseId'] ?? 'course_1';
              final lessonId = state.pathParameters['lessonId'] ?? 'les_1_1_1';
              return _buildSmoothSlidePage(key: state.pageKey, child: LessonScreen(courseId: courseId, lessonId: lessonId));
            },
          ),
          GoRoute(
            path: '/live-class/:id',
            pageBuilder: (context, state) {
              final id = state.pathParameters['id'] ?? 'live_1';
              return _buildSmoothSlidePage(key: state.pageKey, child: LiveClassScreen(classId: id));
            },
          ),
          GoRoute(
            path: '/quiz/:id',
            pageBuilder: (context, state) {
              final id = state.pathParameters['id'] ?? 'quiz_c1';
              return _buildSmoothSlidePage(key: state.pageKey, child: QuizScreen(quizId: id));
            },
          ),
          GoRoute(
            path: '/certificates',
            pageBuilder: (context, state) {
              final queryId = state.uri.queryParameters['verify'];
              return _buildSmoothSlidePage(key: state.pageKey, child: CertificatesScreen(initialVerificationId: queryId));
            },
          ),
          GoRoute(
            path: '/verify/:id',
            pageBuilder: (context, state) {
              final verId = state.pathParameters['id'];
              return _buildSmoothSlidePage(key: state.pageKey, child: CertificatesScreen(initialVerificationId: verId));
            },
          ),
          GoRoute(
            path: '/cart',
            pageBuilder: (context, state) => _buildSmoothSlidePage(key: state.pageKey, child: const CartScreen()),
          ),
          GoRoute(
            path: '/checkout',
            pageBuilder: (context, state) => _buildSmoothSlidePage(key: state.pageKey, child: const CheckoutScreen()),
          ),
          GoRoute(
            path: '/builder',
            pageBuilder: (context, state) {
              final courseId = state.uri.queryParameters['courseId'] ?? state.extra as String?;
              return _buildSmoothSlidePage(key: state.pageKey, child: CourseBuilderScreen(courseId: courseId));
            },
          ),
          GoRoute(
            path: '/instructor/live-classes',
            pageBuilder: (context, state) => _buildSmoothSlidePage(key: state.pageKey, child: const LiveClassManagementScreen()),
          ),
          GoRoute(
            path: '/earnings',
            pageBuilder: (context, state) => _buildSmoothSlidePage(key: state.pageKey, child: const EarningsScreen()),
          ),
          GoRoute(
            path: '/about',
            pageBuilder: (context, state) => _buildSmoothSlidePage(key: state.pageKey, child: const AboutScreen()),
          ),
          GoRoute(
            path: '/contact',
            pageBuilder: (context, state) => _buildSmoothSlidePage(key: state.pageKey, child: const ContactScreen()),
          ),
        ],
      ),
    ],
  );
});

// Backward compatibility static router
final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/splash',
  errorBuilder: (context, state) => const NotFoundScreen(),
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => MainLayout(child: child),
      routes: [
        GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
        GoRoute(path: '/courses', builder: (context, state) => const CoursesScreen()),
        GoRoute(
          path: '/course/:id',
          builder: (context, state) => CourseDetailsScreen(courseId: state.pathParameters['id'] ?? 'course_1'),
        ),
        GoRoute(
          path: '/lesson/:courseId/:lessonId',
          builder: (context, state) => LessonScreen(
            courseId: state.pathParameters['courseId'] ?? 'course_1',
            lessonId: state.pathParameters['lessonId'] ?? 'les_1_1_1',
          ),
        ),
        GoRoute(
          path: '/live-class/:id',
          builder: (context, state) => LiveClassScreen(classId: state.pathParameters['id'] ?? 'live_1'),
        ),
        GoRoute(
          path: '/quiz/:id',
          builder: (context, state) => QuizScreen(quizId: state.pathParameters['id'] ?? 'quiz_c1'),
        ),
        GoRoute(path: '/my-learning', builder: (context, state) => const MyLearningScreen()),
        GoRoute(path: '/certificates', builder: (context, state) => const CertificatesScreen()),
        GoRoute(path: '/cart', builder: (context, state) => const CartScreen()),
        GoRoute(path: '/checkout', builder: (context, state) => const CheckoutScreen()),
        GoRoute(path: '/wishlist', builder: (context, state) => const WishlistScreen()),
        GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
        GoRoute(path: '/instructor', builder: (context, state) => const InstructorDashboardScreen()),
        GoRoute(
          path: '/builder',
          builder: (context, state) {
            final courseId = state.uri.queryParameters['courseId'] ?? state.extra as String?;
            return CourseBuilderScreen(courseId: courseId);
          },
        ),
        GoRoute(path: '/earnings', builder: (context, state) => const EarningsScreen()),
        GoRoute(path: '/about', builder: (context, state) => const AboutScreen()),
        GoRoute(path: '/contact', builder: (context, state) => const ContactScreen()),
      ],
    ),
  ],
);
