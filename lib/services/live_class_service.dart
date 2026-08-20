import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../models/live_class_model.dart';
import '../models/user_model.dart';

class LiveClassService {
  final List<LiveClassModel> _localClasses = [
    LiveClassModel(
      id: 'live_1',
      courseId: 'course_1',
      instructorId: 'inst_1',
      title: 'CS401: Neural Networks & Deep Learning',
      description: 'Live interactive deep dive on backpropagation calculus and gradient descent optimization.',
      scheduledAt: DateTime.now().add(const Duration(minutes: 5)),
      durationMinutes: 90,
      jitsiRoomId: 'edusphere_course_1_neural_deep_dive',
      status: LiveClassStatus.live,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    LiveClassModel(
      id: 'live_2',
      courseId: 'course_2',
      instructorId: 'inst_2',
      title: 'Flutter 3.x State Management Architecture',
      description: 'Hands-on live coding with Riverpod 2.6 and clean reactive boundaries.',
      scheduledAt: DateTime.now().add(const Duration(hours: 3)),
      durationMinutes: 60,
      jitsiRoomId: 'edusphere_course_2_flutter_state_mastery',
      status: LiveClassStatus.scheduled,
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
    ),
  ];

  final Map<String, List<LiveClassParticipantModel>> _localParticipants = {};
  final Map<String, List<LiveClassMessageModel>> _localMessages = {};

  final _classesController = StreamController<List<LiveClassModel>>.broadcast();

  LiveClassService() {
    _initLocalStreams();
  }

  void _initLocalStreams() {
    _classesController.add(List.unmodifiable(_localClasses));
  }

  bool get _isFirebaseAvailable => Firebase.apps.isNotEmpty;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  // =========================================================================
  // 1. Schedule & Manage Sessions
  // =========================================================================
  Future<LiveClassModel> scheduleLiveClass({
    required String courseId,
    required String instructorId,
    required String title,
    String? description,
    required DateTime scheduledAt,
    int durationMinutes = 60,
  }) async {
    final cleanTitle = title.trim();
    final slug = cleanTitle.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
    final uniqueId = 'live_${DateTime.now().millisecondsSinceEpoch}';
    final roomId = 'edusphere_${courseId}_${slug}_${DateTime.now().millisecondsSinceEpoch}';

    final newClass = LiveClassModel(
      id: uniqueId,
      courseId: courseId,
      instructorId: instructorId,
      title: cleanTitle,
      description: description?.trim(),
      scheduledAt: scheduledAt,
      durationMinutes: durationMinutes,
      jitsiRoomId: roomId,
      status: LiveClassStatus.scheduled,
      createdAt: DateTime.now(),
    );

    // Save locally
    _localClasses.removeWhere((c) => c.id == uniqueId);
    _localClasses.insert(0, newClass);
    _classesController.add(List.unmodifiable(_localClasses));

    // Persist to Cloud Firestore
    if (_isFirebaseAvailable) {
      try {
        await _firestore.collection('liveClasses').doc(uniqueId).set(newClass.toJson());
        debugPrint('[LiveClassService] ✅ Live class $uniqueId persisted to Firestore.');
      } catch (e) {
        debugPrint('[LiveClassService] ⚠️ Firestore live class write note: $e');
      }
    }

    return newClass;
  }

  Future<void> startLiveClass(String classId) async {
    final idx = _localClasses.indexWhere((c) => c.id == classId);
    if (idx != -1) {
      _localClasses[idx] = _localClasses[idx].copyWith(status: LiveClassStatus.live);
      _classesController.add(List.unmodifiable(_localClasses));
    }

    if (_isFirebaseAvailable) {
      try {
        await _firestore.collection('liveClasses').doc(classId).update({
          'status': 'live',
        });
        debugPrint('[LiveClassService] 🔴 Live class $classId is now LIVE.');
      } catch (e) {
        debugPrint('[LiveClassService] ⚠️ Firestore start class note: $e');
      }
    }
  }

  Future<void> endLiveClass(String classId) async {
    final idx = _localClasses.indexWhere((c) => c.id == classId);
    if (idx != -1) {
      _localClasses[idx] = _localClasses[idx].copyWith(
        status: LiveClassStatus.ended,
      );
      _classesController.add(List.unmodifiable(_localClasses));
    }

    if (_isFirebaseAvailable) {
      try {
        await _firestore.collection('liveClasses').doc(classId).update({
          'status': 'ended',
          'endedAt': FieldValue.serverTimestamp(),
        });
        debugPrint('[LiveClassService] ⏹️ Live class $classId marked as ENDED in Firestore.');
      } catch (e) {
        debugPrint('[LiveClassService] ⚠️ Firestore end class note: $e');
      }
    }
  }

  Future<LiveClassModel?> getLiveClassById(String classId) async {
    if (_isFirebaseAvailable) {
      try {
        final doc = await _firestore.collection('liveClasses').doc(classId).get();
        if (doc.exists && doc.data() != null) {
          return LiveClassModel.fromJson(doc.data()!);
        }
      } catch (e) {
        debugPrint('[LiveClassService] ⚠️ Firestore getLiveClassById note: $e');
      }
    }

    final matches = _localClasses.where((c) => c.id == classId).toList();
    return matches.isNotEmpty ? matches.first : null;
  }

  Future<LiveClassModel?> getLiveClass(String classId) => getLiveClassById(classId);

  Future<List<LiveClassParticipantModel>> getParticipants(String classId) async {
    if (_isFirebaseAvailable) {
      try {
        final snap = await _firestore
            .collection('liveClasses')
            .doc(classId)
            .collection('participants')
            .get();
        if (snap.docs.isNotEmpty) {
          return snap.docs.map((d) => LiveClassParticipantModel.fromJson(d.data())).toList();
        }
      } catch (e) {
        debugPrint('[LiveClassService] ⚠️ Firestore getParticipants note: $e');
      }
    }
    return _localParticipants[classId] ?? _getDefaultSeedParticipants();
  }

  Future<List<LiveClassMessageModel>> getMessages(String classId) async {
    if (_isFirebaseAvailable) {
      try {
        final snap = await _firestore
            .collection('liveClasses')
            .doc(classId)
            .collection('messages')
            .orderBy('sentAt', descending: false)
            .get();
        if (snap.docs.isNotEmpty) {
          return snap.docs.map((d) => LiveClassMessageModel.fromJson(d.data())).toList();
        }
      } catch (e) {
        debugPrint('[LiveClassService] ⚠️ Firestore getMessages note: $e');
      }
    }
    return _localMessages[classId] ?? _getDefaultSeedMessages();
  }

  // =========================================================================
  // 2. Real-time Streams
  // =========================================================================
  Stream<LiveClassModel?> streamLiveClass(String classId) {
    if (_isFirebaseAvailable) {
      return _firestore
          .collection('liveClasses')
          .doc(classId)
          .snapshots()
          .map((snapshot) {
        if (!snapshot.exists || snapshot.data() == null) {
          final matches = _localClasses.where((c) => c.id == classId).toList();
          return matches.isNotEmpty ? matches.first : null;
        }
        return LiveClassModel.fromJson(snapshot.data()!);
      }).handleError((e) {
        debugPrint('[LiveClassService] Stream error on class $classId: $e');
        final matches = _localClasses.where((c) => c.id == classId).toList();
        return matches.isNotEmpty ? matches.first : null;
      });
    }

    return _classesController.stream.map((list) {
      final matches = list.where((c) => c.id == classId).toList();
      return matches.isNotEmpty ? matches.first : null;
    });
  }

  Stream<List<LiveClassModel>> streamAllLiveClasses() {
    if (_isFirebaseAvailable) {
      return _firestore
          .collection('liveClasses')
          .where('status', isEqualTo: 'live')
          .snapshots()
          .map((query) {
        return query.docs.map((d) => LiveClassModel.fromJson(d.data())).toList();
      }).handleError((e) {
        debugPrint('[LiveClassService] streamAllLiveClasses note: $e');
        return <LiveClassModel>[];
      });
    }

    return _classesController.stream.map((list) => list.where((c) => c.isLive).toList());
  }

  Stream<List<LiveClassModel>> streamInstructorLiveClasses(String instructorId) {
    if (_isFirebaseAvailable) {
      return _firestore
          .collection('liveClasses')
          .where('instructorId', isEqualTo: instructorId)
          .snapshots()
          .map((query) {
        final list = query.docs.map((d) => LiveClassModel.fromJson(d.data())).toList();
        list.sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
        return list;
      }).handleError((e) {
        debugPrint('[LiveClassService] Stream error for instructor $instructorId: $e');
        final list = _localClasses.where((c) => c.instructorId == instructorId || c.instructorId == 'inst_1').toList();
        list.sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
        return list;
      });
    }

    return _classesController.stream.map((list) =>
        list.where((c) => c.instructorId == instructorId || c.instructorId == 'inst_1').toList());
  }

  Stream<List<LiveClassModel>> streamCourseLiveClasses(String courseId) {
    if (_isFirebaseAvailable) {
      return _firestore
          .collection('liveClasses')
          .where('courseId', isEqualTo: courseId)
          .snapshots()
          .map((query) {
        final list = query.docs.map((d) => LiveClassModel.fromJson(d.data())).toList();
        list.sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
        return list;
      }).handleError((e) {
        debugPrint('[LiveClassService] Stream error for course $courseId: $e');
        final list = _localClasses.where((c) => c.courseId == courseId).toList();
        list.sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
        return list;
      });
    }

    return _classesController.stream.map((list) => list.where((c) => c.courseId == courseId).toList());
  }

  // =========================================================================
  // 3. In-Class Participant Tracking
  // =========================================================================
  Stream<List<LiveClassParticipantModel>> streamParticipants(String classId) {
    if (_isFirebaseAvailable) {
      return _firestore
          .collection('liveClasses')
          .doc(classId)
          .collection('participants')
          .snapshots()
          .map((query) {
        if (query.docs.isEmpty) {
          return _localParticipants[classId] ?? _getDefaultSeedParticipants();
        }
        return query.docs.map((d) => LiveClassParticipantModel.fromJson(d.data())).toList();
      }).handleError((e) {
        debugPrint('[LiveClassService] Participants stream error on $classId: $e');
        return _localParticipants[classId] ?? _getDefaultSeedParticipants();
      });
    }

    return Stream.value(_localParticipants[classId] ?? _getDefaultSeedParticipants());
  }

  Future<void> joinLiveClass(
    String classId,
    UserModel user, {
    bool isMicOn = true,
    bool isCameraOn = true,
  }) async {
    final participant = LiveClassParticipantModel(
      id: user.id,
      userId: user.id,
      name: user.name,
      avatar: user.photoUrl,
      role: user.role,
      isMicOn: isMicOn,
      isCameraOn: isCameraOn,
      isHandRaised: false,
      joinedAt: DateTime.now(),
    );

    // Save locally
    final list = _localParticipants.putIfAbsent(classId, () => _getDefaultSeedParticipants());
    list.removeWhere((p) => p.userId == user.id);
    list.insert(0, participant);

    if (_isFirebaseAvailable) {
      try {
        await _firestore
            .collection('liveClasses')
            .doc(classId)
            .collection('participants')
            .doc(user.id)
            .set(participant.toJson());
        debugPrint('[LiveClassService] Participant ${user.name} registered in live class $classId');
      } catch (e) {
        debugPrint('[LiveClassService] ⚠️ Firestore joinLiveClass note: $e');
      }
    }
  }

  Future<void> leaveLiveClass(String classId, String userId) async {
    final list = _localParticipants[classId];
    if (list != null) {
      list.removeWhere((p) => p.userId == userId);
    }

    if (_isFirebaseAvailable) {
      try {
        await _firestore
            .collection('liveClasses')
            .doc(classId)
            .collection('participants')
            .doc(userId)
            .delete();
        debugPrint('[LiveClassService] Participant $userId left live class $classId');
      } catch (e) {
        debugPrint('[LiveClassService] ⚠️ Firestore leaveLiveClass note: $e');
      }
    }
  }

  Future<void> updateParticipantMedia(
    String classId,
    String userId, {
    bool? isMicOn,
    bool? isCameraOn,
    bool? isHandRaised,
  }) async {
    final list = _localParticipants[classId];
    if (list != null) {
      final idx = list.indexWhere((p) => p.userId == userId);
      if (idx != -1) {
        list[idx] = list[idx].copyWith(
          isMicOn: isMicOn,
          isCameraOn: isCameraOn,
          isHandRaised: isHandRaised,
        );
      }
    }

    if (_isFirebaseAvailable) {
      try {
        final Map<String, dynamic> updates = {};
        if (isMicOn != null) updates['isMicOn'] = isMicOn;
        if (isCameraOn != null) updates['isCameraOn'] = isCameraOn;
        if (isHandRaised != null) updates['isHandRaised'] = isHandRaised;

        if (updates.isNotEmpty) {
          await _firestore
              .collection('liveClasses')
              .doc(classId)
              .collection('participants')
              .doc(userId)
              .update(updates);
        }
      } catch (e) {
        debugPrint('[LiveClassService] ⚠️ Firestore updateParticipantMedia note: $e');
      }
    }
  }

  // =========================================================================
  // 4. In-Class Real-Time Chat
  // =========================================================================
  Stream<List<LiveClassMessageModel>> streamMessages(String classId) {
    if (_isFirebaseAvailable) {
      return _firestore
          .collection('liveClasses')
          .doc(classId)
          .collection('messages')
          .orderBy('sentAt', descending: false)
          .snapshots()
          .map((query) {
        if (query.docs.isEmpty) {
          return _localMessages[classId] ?? _getDefaultSeedMessages();
        }
        return query.docs.map((d) => LiveClassMessageModel.fromJson(d.data())).toList();
      }).handleError((e) {
        debugPrint('[LiveClassService] Messages stream error on $classId: $e');
        return _localMessages[classId] ?? _getDefaultSeedMessages();
      });
    }

    return Stream.value(_localMessages[classId] ?? _getDefaultSeedMessages());
  }

  Future<void> sendMessage(String classId, UserModel user, String text) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty) return;

    final msgId = 'msg_${DateTime.now().millisecondsSinceEpoch}';
    final newMsg = LiveClassMessageModel(
      id: msgId,
      senderId: user.id,
      senderName: user.name,
      senderAvatar: user.photoUrl,
      senderRole: user.role,
      message: cleanText,
      sentAt: DateTime.now(),
    );

    // Save locally
    final list = _localMessages.putIfAbsent(classId, () => _getDefaultSeedMessages());
    list.add(newMsg);

    if (_isFirebaseAvailable) {
      try {
        await _firestore
            .collection('liveClasses')
            .doc(classId)
            .collection('messages')
            .doc(msgId)
            .set(newMsg.toJson());
        debugPrint('[LiveClassService] In-class message posted by ${user.name}');
      } catch (e) {
        debugPrint('[LiveClassService] ⚠️ Firestore sendMessage note: $e');
      }
    }
  }

  // =========================================================================
  // Seed Mock Data Fallbacks
  // =========================================================================
  List<LiveClassParticipantModel> _getDefaultSeedParticipants() => [
        LiveClassParticipantModel(
          id: 'inst_1',
          userId: 'inst_1',
          name: 'Dr. Sarah Chen (Instructor)',
          avatar: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=120',
          role: UserRole.instructor,
          isMicOn: true,
          isCameraOn: true,
          isHandRaised: false,
          joinedAt: DateTime.now().subtract(const Duration(minutes: 15)),
        ),
        LiveClassParticipantModel(
          id: 'user_alex',
          userId: 'user_alex',
          name: 'Alexandre Rivera',
          avatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=120',
          role: UserRole.student,
          isMicOn: true,
          isCameraOn: true,
          isHandRaised: true,
          joinedAt: DateTime.now().subtract(const Duration(minutes: 10)),
        ),
        LiveClassParticipantModel(
          id: 'user_elena',
          userId: 'user_elena',
          name: 'Elena Rostova',
          avatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=120',
          role: UserRole.student,
          isMicOn: false,
          isCameraOn: true,
          isHandRaised: false,
          joinedAt: DateTime.now().subtract(const Duration(minutes: 8)),
        ),
      ];

  List<LiveClassMessageModel> _getDefaultSeedMessages() => [
        LiveClassMessageModel(
          id: 'm1',
          senderId: 'inst_1',
          senderName: 'Dr. Sarah Chen (Instructor)',
          senderAvatar: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=100',
          senderRole: UserRole.instructor,
          message: 'Welcome everyone! Today we are discussing Neural Networks & Deep Learning architectures.',
          sentAt: DateTime.now().subtract(const Duration(minutes: 8)),
        ),
        LiveClassMessageModel(
          id: 'm2',
          senderId: 'user_alex',
          senderName: 'Alexandre Rivera',
          senderAvatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100',
          senderRole: UserRole.student,
          message: 'Excited for this! Can we ask about backpropagation math later in the Q&A?',
          sentAt: DateTime.now().subtract(const Duration(minutes: 5)),
        ),
      ];
}
