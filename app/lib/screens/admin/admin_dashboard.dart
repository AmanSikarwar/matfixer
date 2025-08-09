import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:matfixer/models/feedback_model.dart';
import 'package:matfixer/services/auth_service.dart';
import 'package:matfixer/services/feedback_service.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final FeedbackService _feedbackService = FeedbackService();
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  void _checkAdminStatus() {
    if (!_authService.isAdmin()) {
      Future.microtask(
        () => Navigator.of(context).pushReplacementNamed('/welcome'),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _authService.signOut();
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed('/welcome');
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<List<FeedbackModel>>(
        stream: _feedbackService.getAllFeedback(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final feedbackList = snapshot.data ?? [];

          if (feedbackList.isEmpty) {
            return const Center(child: Text('No feedback submitted yet.'));
          }

          return ListView.builder(
            itemCount: feedbackList.length,
            itemBuilder: (context, index) {
              final feedback = feedbackList[index];
              return FeedbackCard(feedback: feedback);
            },
          );
        },
      ),
    );
  }
}

class FeedbackCard extends StatelessWidget {
  final FeedbackModel feedback;

  const FeedbackCard({super.key, required this.feedback});

  @override
  Widget build(BuildContext context) {
    final DateFormat formatter = DateFormat('MMM d, yyyy HH:mm');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'User ID: ${feedback.userId.length > 8 ? feedback.userId.substring(0, 8) + '...' : feedback.userId}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  formatter.format(feedback.timestamp),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
            const Divider(),
            if (feedback.errorCode != null) ...[
              Text(
                'Error Code: ${feedback.errorCode}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
            ],
            Text('Feedback: ${feedback.message}'),
            if (feedback.solution != null) ...[
              const SizedBox(height: 8),
              Text(
                'Solution: ${feedback.solution}',
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
