import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ai_toolkit/flutter_ai_toolkit.dart';
import 'package:matfixer/chat_page.dart' show Conversation;

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Cache to track last sent message counts to avoid redundant operations
  final Map<String, int> _lastSavedMessageCounts = {};

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

      // Prepare a batch for all operations
      final batch = _firestore.batch();
      final pendingSaves = <Future<void>>[];

      // Add or update current conversations
      for (final conversation in conversationsCopy) {
        // Only save if the conversation has changed
        final lastSavedCount = _lastSavedMessageCounts[conversation.id] ?? 0;
        final currentCount = conversation.history.length;

        if (lastSavedCount != currentCount) {
          // Add the current timestamp to ensure proper ordering
          final conversationData = {
            'name': conversation.name,
            'updatedAt': FieldValue.serverTimestamp(),
            'messageCount': currentCount,
            'lastUpdated': DateTime.now().millisecondsSinceEpoch,
          };

          batch.set(_conversationsRef.doc(conversation.id), conversationData);

          // Save messages to subcollection only if they're not empty
          if (conversation.history.isNotEmpty) {
            pendingSaves.add(
              _saveMessagesForConversation(
                conversation.id,
                conversation.history,
              ),
            );
          }

          // Update the cache
          _lastSavedMessageCounts[conversation.id] = currentCount;
        }
      }

      // Commit batch for conversation documents
      await batch.commit();

      // Wait for all message saves to complete
      if (pendingSaves.isNotEmpty) {
        await Future.wait(pendingSaves);
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

      // Create a defensive copy of the history to prevent concurrent modification
      final historyList = List<ChatMessage>.from(messages);
      final currentCount = historyList.length;
      final lastSavedCount = _lastSavedMessageCounts[conversationId] ?? 0;

      // Only process if the message count has changed
      if (currentCount != lastSavedCount) {
        log(
          'Saving $currentCount messages for conversation $conversationId (previously had $lastSavedCount)',
        );

        try {
          // First check if we need to delete existing messages
          final existingMessages = await _messagesRef(conversationId).get();

          // If existing count differs from new count, we need to recreate
          if (existingMessages.docs.length != historyList.length) {
            final batch = _firestore.batch();

            // Delete existing messages first if any exist
            if (existingMessages.docs.isNotEmpty) {
              for (final doc in existingMessages.docs) {
                batch.delete(doc.reference);
              }
            }

            // Now add all messages in a single batch
            int index = 0;
            for (final msg in historyList) {
              try {
                final messageData = {
                  'text': msg.text,
                  'isUser': msg.origin.isUser,
                  'timestamp': Timestamp.now(),
                  'order': index++,
                };
                batch.set(_messagesRef(conversationId).doc(), messageData);
              } catch (e) {
                log('Error processing message: $e');
                continue;
              }
            }

            await batch.commit();
            _lastSavedMessageCounts[conversationId] = currentCount;
            log('Successfully saved $currentCount messages in batch');
          }
        } catch (e) {
          log('Error in batch message operation: $e');
          throw e; // Rethrow to handle in the calling method
        }
      } else {
        log(
          'Message count unchanged for conversation $conversationId, skipping save',
        );
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
              .orderBy('lastUpdated', descending: true)
              .get();

      final List<Conversation> result = [];
      final List<Future<void>> messageLoadFutures = [];
      final Map<String, List<ChatMessage>> messagesMap = {};

      // First, load all conversation metadata and prepare message loading futures
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final String conversationId = doc.id;

        // Store the messageCount for cache
        final messageCount = data['messageCount'] as int? ?? 0;
        _lastSavedMessageCounts[conversationId] = messageCount;

        // Create a future for loading messages
        messageLoadFutures.add(
          _loadMessagesForConversation(conversationId).then((messages) {
            messagesMap[conversationId] = messages;
          }),
        );
      }

      // Wait for all messages to load in parallel
      await Future.wait(messageLoadFutures);

      // Now create conversation objects with the loaded messages
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final String conversationId = doc.id;

        final conversation = Conversation(
          id: conversationId,
          name: data['name'] ?? 'Unnamed Conversation',
          history: messagesMap[conversationId] ?? [],
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
          await _messagesRef(conversationId).orderBy('order').get();

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
        .orderBy('lastUpdated', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          try {
            final List<Conversation> result = [];
            final List<Future<void>> messageLoadFutures = [];
            final Map<String, List<ChatMessage>> messagesMap = {};

            // Load all conversation metadata first
            for (final doc in snapshot.docs) {
              final data = doc.data() as Map<String, dynamic>;
              final String conversationId = doc.id;

              // Load messages for each conversation in parallel
              messageLoadFutures.add(
                _loadMessagesForConversation(conversationId).then((messages) {
                  messagesMap[conversationId] = messages;
                }),
              );
            }

            // Wait for all messages to load
            await Future.wait(messageLoadFutures);

            // Now build the conversation objects with loaded messages
            for (final doc in snapshot.docs) {
              final data = doc.data() as Map<String, dynamic>;
              final String conversationId = doc.id;

              final conversation = Conversation(
                id: conversationId,
                name: data['name'] ?? 'Unnamed Conversation',
                history: messagesMap[conversationId] ?? [],
              );

              result.add(conversation);
            }

            return result;
          } catch (e) {
            log('Error in streamConversations: $e');
            // Return empty list rather than throwing to keep stream alive
            return [];
          }
        });
  }

  // Save a single conversation
  Future<void> saveConversation(Conversation conversation) async {
    try {
      final currentCount = conversation.history.length;
      final lastSavedCount = _lastSavedMessageCounts[conversation.id] ?? 0;

      // Only save if the message count has changed
      if (currentCount != lastSavedCount) {
        // Add timestamp to ensure proper ordering
        final conversationData = {
          'name': conversation.name,
          'updatedAt': FieldValue.serverTimestamp(),
          'messageCount': currentCount,
          'lastUpdated': DateTime.now().millisecondsSinceEpoch,
        };

        await _conversationsRef.doc(conversation.id).set(conversationData);

        // Save messages
        await _saveMessagesForConversation(
          conversation.id,
          conversation.history,
        );

        // Update cache
        _lastSavedMessageCounts[conversation.id] = currentCount;

        log(
          'Successfully saved conversation: ${conversation.name} with $currentCount messages',
        );
      } else {
        log(
          'Message count unchanged for conversation ${conversation.name}, skipping save',
        );
      }
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

      // Remove from cache
      _lastSavedMessageCounts.remove(conversationId);
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
