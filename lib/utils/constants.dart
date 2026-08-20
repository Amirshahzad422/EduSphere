class AppConstants {
  AppConstants._();

  static const String appName = 'EduSphere';
  static const String appTagline = 'Empowering Minds, Shaping Tomorrow';

  // Storage Keys & Firestore Collections
  static const String usersCollection = 'users';
  static const String coursesCollection = 'courses';
  static const String lessonsCollection = 'lessons';
  static const String enrolmentsCollection = 'enrolments';
  static const String quizzesCollection = 'quizzes';
  static const String quizAttemptsCollection = 'quizAttempts';
  static const String certificatesCollection = 'certificates';
  static const String liveClassesCollection = 'liveClasses';

  // Default Categories
  static const List<String> categories = [
    'All',
    'Mobile Development',
    'Design & UI/UX',
    'Artificial Intelligence',
    'Cybersecurity',
    'Cloud Computing',
    'Web Development',
    'Data Science',
    'Business & Management',
    'Game Development',
    'Blockchain',
  ];

  // Levels
  static const List<String> levels = [
    'All Levels',
    'Beginner',
    'Intermediate',
    'Advanced',
  ];
}
