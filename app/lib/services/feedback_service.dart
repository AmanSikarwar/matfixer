import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:matfixer/models/feedback_model.dart';

class FeedbackService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection reference
  CollectionReference get _feedbackCollection =>
      _firestore.collection('feedbacks'); // Corrected path

  // Submit new feedback
  Future<void> submitFeedback({
    required String userId,
    required String message,
    String? errorCode,
    String? solution,
  }) async {
    await _feedbackCollection.add({
      'userId': userId,
      'message': message,
      'timestamp': Timestamp.now(),
      'errorCode': errorCode,
      'solution': solution,
    });
  }

  // Get all feedback (for admin)
  Stream<List<FeedbackModel>> getAllFeedback() {
    return _feedbackCollection
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => FeedbackModel.fromFirestore(doc))
                  .toList(),
        );
  }

  // Get feedback for a specific user
  Stream<List<FeedbackModel>> getUserFeedback(String userId) {
    return _feedbackCollection
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => FeedbackModel.fromFirestore(doc))
                  .toList(),
        );
  }
}
