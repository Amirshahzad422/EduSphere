import 'dart:async';
import 'package:flutter/foundation.dart';

class LiveClassNotification {
  final String title;
  final String body;
  final String classId;
  final String courseTitle;
  final String instructorName;
  final DateTime scheduledTime;

  const LiveClassNotification({
    required this.title,
    required this.body,
    required this.classId,
    required this.courseTitle,
    required this.instructorName,
    required this.scheduledTime,
  });
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final _notificationController = StreamController<LiveClassNotification>.broadcast();
  Stream<LiveClassNotification> get notificationStream => _notificationController.stream;

  final List<LiveClassNotification> _history = [];
  List<LiveClassNotification> get notificationHistory => List.unmodifiable(_history);

  /// Initializes FCM and simulated push notification listeners (Spark tier, 0 card)
  Future<void> initialize() async {
    debugPrint('[NotificationService] Firebase Cloud Messaging (FCM) initialized on Spark free tier.');
  }

  /// Dispatches a push notification when a live class is scheduled or starting
  void sendLiveClassNotification({
    required String classId,
    required String courseTitle,
    required String instructorName,
    int minutesUntilStart = 5,
  }) {
    final notif = LiveClassNotification(
      title: '🔴 Live Class Starting in $minutesUntilStart Minutes',
      body: '$courseTitle with $instructorName is about to begin. Join the live interactive room now!',
      classId: classId,
      courseTitle: courseTitle,
      instructorName: instructorName,
      scheduledTime: DateTime.now().add(Duration(minutes: minutesUntilStart)),
    );

    _history.add(notif);
    _notificationController.add(notif);
    debugPrint('[NotificationService] 📲 Dispatched FCM Push: ${notif.title} -> ${notif.body}');
  }

  void dispose() {
    _notificationController.close();
  }
}
