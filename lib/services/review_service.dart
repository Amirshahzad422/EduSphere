import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/review_model.dart';
import 'firebase_service.dart';

class ReviewService {
  final FirebaseFirestore? _firestore;

  ReviewService([FirebaseFirestore? firestore])
      : _firestore = firestore ?? (FirebaseService.isInitialized ? FirebaseFirestore.instance : null);

  static final Map<String, List<ReviewModel>> _memoryReviews = {};

  /// Submits or updates a student review atomically via Firestore transaction
  Future<ReviewModel> submitOrUpdateReview({
    required String userId,
    required String userName,
    String userPhotoUrl = '',
    required String courseId,
    required double rating,
    required String reviewText,
  }) async {
    final deterministicId = '${userId}_$courseId';
    final now = DateTime.now();

    final newReview = ReviewModel(
      id: deterministicId,
      userId: userId,
      userName: userName,
      userPhotoUrl: userPhotoUrl,
      courseId: courseId,
      rating: rating,
      reviewText: reviewText,
      createdAt: now,
      updatedAt: now,
    );

    // In-memory cache update
    final list = _memoryReviews.putIfAbsent(courseId, () => []);
    list.removeWhere((r) => r.id == deterministicId);
    list.insert(0, newReview);

    if (_firestore != null && Firebase.apps.isNotEmpty) {
      try {
        final reviewRef = _firestore.collection('reviews').doc(deterministicId);
        final courseRef = _firestore.collection('courses').doc(courseId);

        await _firestore.runTransaction((transaction) async {
          final reviewSnap = await transaction.get(reviewRef);
          final courseSnap = await transaction.get(courseRef);

          double prevRating = 0.0;
          bool isNewReview = true;

          if (reviewSnap.exists && reviewSnap.data() != null) {
            isNewReview = false;
            final data = reviewSnap.data()!;
            prevRating = (data['rating'] as num?)?.toDouble() ?? 0.0;
          }

          double currentSum = 0.0;
          int currentCount = 0;

          if (courseSnap.exists && courseSnap.data() != null) {
            final cData = courseSnap.data()!;
            currentSum = (cData['ratingSum'] as num?)?.toDouble() ??
                ((cData['rating'] as num?)?.toDouble() ?? 4.8) *
                    ((cData['ratingCount'] ?? cData['reviewCount'] ?? 1) as num).toDouble();
            currentCount = ((cData['ratingCount'] ?? cData['reviewCount'] ?? 0) as num).toInt();
          }

          double newSum;
          int newCount;

          if (isNewReview) {
            newSum = currentSum + rating;
            newCount = currentCount + 1;
          } else {
            newSum = currentSum - prevRating + rating;
            newCount = currentCount > 0 ? currentCount : 1;
          }

          final double newAvg = newCount > 0
              ? double.parse((newSum / newCount).toStringAsFixed(2))
              : rating;

          // 1. Write review doc
          transaction.set(reviewRef, newReview.toJson(), SetOptions(merge: true));

          // 2. Atomically update denormalized rating aggregates on course doc
          transaction.update(courseRef, {
            'ratingSum': newSum,
            'ratingCount': newCount,
            'reviewCount': newCount,
            'averageRating': newAvg,
            'rating': newAvg,
          });
        });

        debugPrint('[ReviewService] ✅ Review submitted atomically for course $courseId (New rating: $rating)');
      } catch (e) {
        debugPrint('[ReviewService] ⚠️ Transaction warning (running in mock/offline mode): $e');
      }
    }

    return newReview;
  }

  /// Streams all reviews for a course in real time
  Stream<List<ReviewModel>> getCourseReviewsStream(String courseId) {
    if (_firestore == null || Firebase.apps.isEmpty) {
      return Stream.value(_memoryReviews[courseId] ?? []);
    }

    return _firestore
        .collection('reviews')
        .where('courseId', isEqualTo: courseId)
        .snapshots()
        .map((snap) {
      final reviews = snap.docs.map((d) => ReviewModel.fromJson(d.data())).toList();
      reviews.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return reviews;
    });
  }

  /// Streams all reviews for an instructor across all their courses
  Stream<List<ReviewModel>> getInstructorReviewsStream(List<String> courseIds) {
    if (_firestore == null || Firebase.apps.isEmpty || courseIds.isEmpty) {
      final all = <ReviewModel>[];
      for (final cid in courseIds) {
        all.addAll(_memoryReviews[cid] ?? []);
      }
      all.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return Stream.value(all);
    }

    // Firestore `whereIn` supports up to 30 course IDs
    final chunk = courseIds.take(30).toList();
    return _firestore
        .collection('reviews')
        .where('courseId', whereIn: chunk)
        .snapshots()
        .map((snap) {
      final reviews = snap.docs.map((d) => ReviewModel.fromJson(d.data())).toList();
      reviews.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return reviews;
    });
  }

  /// Fetches the user's specific review for a course
  Future<ReviewModel?> getUserReview(String userId, String courseId) async {
    final deterministicId = '${userId}_$courseId';
    if (_firestore != null && Firebase.apps.isNotEmpty) {
      try {
        final doc = await _firestore.collection('reviews').doc(deterministicId).get();
        if (doc.exists && doc.data() != null) {
          return ReviewModel.fromJson(doc.data()!);
        }
      } catch (e) {
        debugPrint('[ReviewService] Note on getUserReview: $e');
      }
    }
    return _memoryReviews[courseId]?.firstWhere((r) => r.id == deterministicId, orElse: () => null as dynamic);
  }
}
