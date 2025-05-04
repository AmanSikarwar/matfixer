import 'package:cloud_firestore/cloud_firestore.dart';

class FeedbackModel {
  final String id;
  final String userId;
  final String message;
  final DateTime timestamp;
  final String? errorCode;
  final String? solution;

  FeedbackModel({
    required this.id,
    required this.userId,
    required this.message,
    required this.timestamp,
    this.errorCode,
    this.solution,
  });

  // Create from Firestore document
  factory FeedbackModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FeedbackModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      message: data['message'] ?? '',
      timestamp:
          (data['timestamp'] is Timestamp)
              ? (data['timestamp'] as Timestamp).toDate()
              : DateTime.parse(data['timestamp']), // Handle both cases
      errorCode: data['errorCode'],
      solution: data['solution'],
    );
  }

  // Convert to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp),
      'errorCode': errorCode,
      'solution': solution,
    };
  }
}
