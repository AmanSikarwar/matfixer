import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ai_toolkit/flutter_ai_toolkit.dart';
import 'package:matfixer/chat_page.dart' show Conversation;

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID, or generate an anonymous ID if not authenticated
  String get _userId {
    final user = _auth.currentUser;
    return user?.uid ?? 'anonymous_user';
  }

  // Reference to the user's conversations collection
  CollectionReference get _conversationsRef =>
      _firestore.collection('users').doc(_userId).collection('conversations');

  // Get reference to messages subcollection for a specific conversation
  CollectionReference _messagesRef(String conversationId) =>
      _conversationsRef.doc(conversationId).collection('messages');

  // Save a list of conversations to Firestore
  Future<void> saveConversations(List<Conversation> conversations) async {
    try {
      // Create a defensive copy of the conversations list
      final conversationsCopy = List<Conversation>.from(conversations);

      // Add or update current conversations
      for (final conversation in conversationsCopy) {
        // Add the current timestamp to ensure proper ordering
        final conversationData = {
          'name': conversation.name,
          'updatedAt': FieldValue.serverTimestamp(),
          'messageCount': conversation.history.length,
          'lastUpdated':
              DateTime.now()
                  .millisecondsSinceEpoch, // Add timestamp for sorting
        };

        await _conversationsRef.doc(conversation.id).set(conversationData);

        // Save messages to subcollection only if they're not empty
        if (conversation.history.isNotEmpty) {
          await _saveMessagesForConversation(
            conversation.id,
            conversation.history,
          );
        }
      }
    } catch (e, stackTrace) {
      log('Error saving conversations: $e');
      log('Error stack trace: $stackTrace');
    }
  }

  // Save messages for a specific conversation to its subcollection
  Future<void> _saveMessagesForConversation(
    String conversationId,
    Iterable<ChatMessage> messages,
  ) async {
    try {
      // Skip if there are no messages to save
      if (messages.isEmpty) {
        log('No messages to save for conversation $conversationId');
        return;
      }

      log(
        'Saving ${messages.length} messages for conversation $conversationId',
      );

      // Create a defensive copy of the history to prevent concurrent modification
      final historyList = List<ChatMessage>.from(messages);

      try {
        // First check if we need to delete existing messages
        final existingMessages = await _messagesRef(conversationId).get();

        // If existing count differs from new count, we need to recreate
        if (existingMessages.docs.length != historyList.length) {
          // Delete existing messages first
          if (existingMessages.docs.isNotEmpty) {
            log('Deleting ${existingMessages.docs.length} existing messages');
            final batch = _firestore.batch();
            for (final doc in existingMessages.docs) {
              batch.delete(doc.reference);
            }
            await batch.commit();
          }

          // Now add all messages with timestamps to maintain order
          final batch = _firestore.batch();
          int index = 0;

          for (final msg in historyList) {
            try {
              final messageData = {
                'text': msg.text,
                'isUser': msg.origin.isUser,
                'timestamp': Timestamp.now(),
                'order': index++, // Use index to maintain order
              };

              // Create document with auto-generated ID
              final docRef = _messagesRef(conversationId).doc();
              batch.set(docRef, messageData);
            } catch (e) {
              log('Error processing message: $e');
              continue;
            }
          }

          await batch.commit();
          log('Successfully saved ${historyList.length} messages');
        } else {
          // If counts match, assume we don't need to update
          log('Message count matches existing messages, skipping update');
        }
      } catch (e) {
        log('Error managing messages: $e');

        // Fallback approach: just save all messages
        try {
          final batch = _firestore.batch();
          int index = 0;

          // Delete all existing messages first
          final existingMessages = await _messagesRef(conversationId).get();
          for (final doc in existingMessages.docs) {
            batch.delete(doc.reference);
          }

          // Add all new messages
          for (final msg in historyList) {
            final messageData = {
              'text': msg.text,
              'isUser': msg.origin.isUser,
              'timestamp': Timestamp.now(),
              'order': index++,
            };
            batch.set(_messagesRef(conversationId).doc(), messageData);
          }

          await batch.commit();
          log('Used fallback approach to save ${historyList.length} messages');
        } catch (e) {
          log('Fallback save also failed: $e');
        }
      }
    } catch (e) {
      log('Error in _saveMessagesForConversation: $e');
    }
  }

  // Load all conversations for the current user
  Future<List<Conversation>> loadConversations() async {
    try {
      final snapshot =
          await _conversationsRef
              .orderBy(
                'lastUpdated',
                descending: true,
              ) // Use numeric timestamp for sorting
              .get();

      // Create list to store fully loaded conversations
      final List<Conversation> result = [];

      // Load each conversation with its messages
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final String conversationId = doc.id;

        // Load messages for this conversation
        final messages = await _loadMessagesForConversation(conversationId);

        // Create conversation object with loaded messages
        final conversation = Conversation(
          id: conversationId,
          name: data['name'] ?? 'Unnamed Conversation',
          history: messages,
        );

        result.add(conversation);
      }

      return result;
    } catch (e, stackTrace) {
      debugPrint('Error loading conversations: $e');
      log('Error stack trace: $stackTrace');
      return [];
    }
  }

  // Load messages for a specific conversation
  Future<List<ChatMessage>> _loadMessagesForConversation(
    String conversationId,
  ) async {
    try {
      final snapshot =
          await _messagesRef(conversationId)
              .orderBy('order') // Order by the index field
              .get();

      final messages =
          snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return ChatMessage(
              text: data['text'] ?? '',
              origin: data['isUser'] ? MessageOrigin.user : MessageOrigin.llm,
              attachments: const [],
            );
          }).toList();

      log(
        'Loaded ${messages.length} messages for conversation $conversationId',
      );
      return messages;
    } catch (e) {
      log('Error loading messages for conversation $conversationId: $e');
      return [];
    }
  }

  // Stream of conversations for real-time updates
  Stream<List<Conversation>> streamConversations() {
    return _conversationsRef
        .orderBy(
          'lastUpdated',
          descending: true,
        ) // Use numeric timestamp for sorting
        .snapshots()
        .asyncMap((snapshot) async {
          final List<Conversation> result = [];

          // For each conversation, load its messages
          for (final doc in snapshot.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final String conversationId = doc.id;

            // Load messages for this conversation
            final messages = await _loadMessagesForConversation(conversationId);

            // Create conversation object with loaded messages
            final conversation = Conversation(
              id: conversationId,
              name: data['name'] ?? 'Unnamed Conversation',
              history: messages,
            );

            result.add(conversation);
          }

          return result;
        });
  }

  // Save a single conversation
  Future<void> saveConversation(Conversation conversation) async {
    try {
      // Add timestamp to ensure proper ordering
      final conversationData = {
        'name': conversation.name,
        'updatedAt': FieldValue.serverTimestamp(),
        'messageCount': conversation.history.length,
        'lastUpdated':
            DateTime.now().millisecondsSinceEpoch, // Add timestamp for sorting
      };

      await _conversationsRef.doc(conversation.id).set(conversationData);

      // Save all messages
      await _saveMessagesForConversation(conversation.id, conversation.history);

      log(
        'Successfully saved conversation: ${conversation.name} with ${conversation.history.length} messages',
      );
    } catch (e, stackTrace) {
      debugPrint('Error saving conversation: $e');
      log('Error stack trace: $stackTrace');
    }
  }

  // Delete a conversation
  Future<void> deleteConversation(String conversationId) async {
    try {
      // Delete all messages in the subcollection first
      final messagesSnapshot = await _messagesRef(conversationId).get();
      final batch = _firestore.batch();
      for (final doc in messagesSnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      // Then delete the conversation document
      await _conversationsRef.doc(conversationId).delete();
    } catch (e, stackTrace) {
      debugPrint('Error deleting conversation: $e');
      log('Error stack trace: $stackTrace');
    }
  }

  // Add a method to save feedback to Firestore
  Future<void> addFeedback(Map<String, dynamic> feedback) async {
    try {
      // Create a new document with an auto-generated ID
      await FirebaseFirestore.instance.collection('/feedbacks').add(feedback);
    } catch (e) {
      debugPrint('Error adding feedback: $e');
      throw Exception('Failed to add feedback: $e');
    }
  }
}
