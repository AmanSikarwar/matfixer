import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_ai_toolkit/flutter_ai_toolkit.dart';
import 'package:matfixer/main.dart';
import 'package:matfixer/matlab_chat_theme.dart';
import 'package:matfixer/providers/llm_providers.dart';
import 'package:uuid/uuid.dart';
import 'package:matfixer/services/firestore_service.dart';

/// Model class to represent a conversation
class Conversation {
  final String id;
  String name;
  Iterable<ChatMessage> history;

  Conversation({
    required this.id,
    required this.name,
    Iterable<ChatMessage>? history,
  }) : history = history ?? [];
}

class ChatPage extends StatefulWidget {
  const ChatPage({
    required this.geminiApiKey,
    required this.onResetApiKey,
    super.key,
  });

  final String geminiApiKey;
  final VoidCallback onResetApiKey;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with WidgetsBindingObserver {
  // List of conversations
  final List<Conversation> _conversations = [];

  // Current conversation index
  int _currentConversationIndex = -1;

  // Text controller for new conversation name
  final TextEditingController _newConversationController =
      TextEditingController();

  // Add text controller for feedback
  final TextEditingController _feedbackController = TextEditingController();

  // Sidebar state
  bool _isSidebarExpanded = true;

  // Timer for periodic saving
  Timer? _saveTimer;

  // Debounce timer to prevent too frequent saves
  Timer? _debounceTimer;

  // Flag to track app lifecycle state for better resource management
  bool _isInForeground = true;

  // Current LLM provider type
  LlmProviderType _currentProviderType = LlmProviderType.agent1;

  late LlmProvider _provider;

  // Add Firestore service
  final FirestoreService _firestoreService = FirestoreService();

  // Stream subscription for real-time updates
  StreamSubscription<List<Conversation>>? _conversationsSubscription;

  // Flag to prevent saving during stream updates
  bool _updatingFromStream = false;

  // Add loading state
  bool _isLoading = true;

  // Add a lock to prevent concurrent saving operations
  bool _isSaving = false;

  // Add hover tracking state
  int? _hoveredConversationIndex;

  // Initialize provider
  void _initializeProvider() {
    _provider = LlmProviderFactory.createProvider(
      _currentProviderType,
      history:
          _conversations.isNotEmpty && _currentConversationIndex >= 0
              ? _conversations[_currentConversationIndex].history
              : [],
      apiKey: widget.geminiApiKey,
    );

    // Listen for changes to the provider's history
    _provider.addListener(_onProviderHistoryChanged);
  }

  // Change the current LLM provider
  void _changeProvider(LlmProviderType newProviderType) {
    if (newProviderType == _currentProviderType) return;

    // Save current history
    final currentHistory = List<ChatMessage>.from(_provider.history);

    // Remove listener from old provider
    _provider.removeListener(_onProviderHistoryChanged);

    setState(() {
      _currentProviderType = newProviderType;

      // Create new provider with same history
      _provider = LlmProviderFactory.createProvider(
        newProviderType,
        history: currentHistory,
        apiKey: widget.geminiApiKey,
      );

      // Update the current conversation's history with the most recent history
      if (_currentConversationIndex >= 0 &&
          _currentConversationIndex < _conversations.length) {
        _conversations[_currentConversationIndex].history = currentHistory;
      }
    });

    // Add listener to new provider
    _provider.addListener(_onProviderHistoryChanged);

    // Save the updated conversation
    _debouncedSave();
  }

  // Debounced save function to prevent excessive Firestore operations
  void _debouncedSave() {
    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer?.cancel();
    }

    _debounceTimer = Timer(const Duration(seconds: 2), () {
      _saveConversations();
    });
  }

  // Save conversations to Firestore
  Future<void> _saveConversations() async {
    // Don't save if we're updating from stream or already saving or app is in background
    if (_updatingFromStream || _isSaving || !_isInForeground) return;

    try {
      _isSaving = true;

      if (_currentConversationIndex >= 0 &&
          _currentConversationIndex < _conversations.length) {
        // Make a copy of the provider history to avoid concurrent modification
        final currentHistory = List<ChatMessage>.from(_provider.history);

        if (currentHistory.isNotEmpty ||
            _conversations[_currentConversationIndex].history.isEmpty) {
          _conversations[_currentConversationIndex].history = currentHistory;
        }
      }

      // Create a defensive copy of the conversations list
      final conversationsCopy = List<Conversation>.from(_conversations);

      // Only save if we have conversations to save
      if (conversationsCopy.isNotEmpty) {
        await _firestoreService.saveConversations(conversationsCopy);
      }
    } catch (e) {
      debugPrint('Error in _saveConversations: $e');
    } finally {
      _isSaving = false;
    }
  }

  // Load conversations from Firestore
  Future<void> _loadConversations() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final loadedConversations = await _firestoreService.loadConversations();

      setState(() {
        _conversations.clear();
        _conversations.addAll(loadedConversations);

        // Set current conversation to the first one if available
        if (_conversations.isNotEmpty) {
          _currentConversationIndex = 0;

          // Initialize provider with the loaded history
          _initializeProvider();
        } else {
          // Create a default conversation if none exists
          _createNewConversationWithoutSaving(name: 'New Chat');
        }

        _isLoading = false;
      });

      // Subscribe to real-time updates
      _subscribeToConversations();
    } catch (e) {
      debugPrint('Error loading conversations: $e');

      setState(() {
        // Create a default conversation if loading fails
        _createNewConversationWithoutSaving(name: 'New Chat');
        _isLoading = false;
      });
    }
  }

  // Create a new conversation without saving (for initial setup)
  void _createNewConversationWithoutSaving({String? name}) {
    final conversationName =
        name?.isNotEmpty == true
            ? name!
            : 'Conversation ${_conversations.length + 1}';

    final newConversation = Conversation(
      id: const Uuid().v4(),
      name: conversationName,
      history: [],
    );

    setState(() {
      _conversations.add(newConversation);
      _currentConversationIndex = _conversations.length - 1;
      _initializeProvider();
    });
  }

  // Create a new conversation
  void _createNewConversation({String? name}) {
    final conversationName =
        name?.isNotEmpty == true
            ? name!
            : 'Conversation ${_conversations.length + 1}';

    final newConversation = Conversation(
      id: const Uuid().v4(),
      name: conversationName,
      history: [],
    );

    // Add the new conversation to the list
    setState(() {
      _conversations.add(newConversation);
      _switchToConversation(_conversations.length - 1);
    });

    // Save the new conversation to Firestore
    _firestoreService.saveConversation(newConversation);
  }

  // Switch to a specific conversation with optimized saving
  void _switchToConversation(int index) {
    if (index >= 0 && index < _conversations.length) {
      // First save the current conversation if we have one
      if (_currentConversationIndex >= 0 &&
          _currentConversationIndex < _conversations.length) {
        // Create a defensive copy of current history
        final currentHistory = List<ChatMessage>.from(_provider.history);

        // Only save if we have messages to save and they've changed
        if (currentHistory.isNotEmpty) {
          _conversations[_currentConversationIndex].history = currentHistory;

          // Create a defensive copy with a fresh history list for saving
          final conversationToSave = Conversation(
            id: _conversations[_currentConversationIndex].id,
            name: _conversations[_currentConversationIndex].name,
            history: currentHistory,
          );

          // Save in background
          _firestoreService.saveConversation(conversationToSave);
        }
      }

      // Now perform the switch
      _performConversationSwitch(index);
    }
  }

  // Actually perform the switch after saving
  void _performConversationSwitch(int index) {
    // Safety check - make sure the index is still valid
    if (index < 0 || index >= _conversations.length) {
      return;
    }

    setState(() {
      _currentConversationIndex = index;

      // Double check the index is still valid
      if (index < _conversations.length) {
        // IMPORTANT: Make a fresh copy of the history to avoid reference issues
        final historyList = List<ChatMessage>.from(
          _conversations[index].history,
        );
        _provider.history = historyList;
      } else {
        // If conversation disappeared, reset to empty history
        _provider.history = [];
      }
    });
  }

  // Subscribe to real-time conversation updates with error handling and retries
  void _subscribeToConversations() {
    _conversationsSubscription?.cancel();

    _conversationsSubscription = _firestoreService.streamConversations().listen(
      (updatedConversations) {
        if (_updatingFromStream) return; // Avoid nested updates

        // Only update if there's a real change
        if (!_listsEqual(updatedConversations, _conversations)) {
          _updatingFromStream = true;

          // Save current conversation state before updating
          final currentHistory =
              (_currentConversationIndex >= 0 &&
                      _currentConversationIndex < _conversations.length)
                  ? _provider.history
                  : null;
          final currentConvId =
              (_currentConversationIndex >= 0 &&
                      _currentConversationIndex < _conversations.length)
                  ? _conversations[_currentConversationIndex].id
                  : null;

          // Sort conversations by updatedAt timestamp
          final sortedConversations =
              updatedConversations.toList()..sort(
                (a, b) => _getConversationTimeValue(
                  a,
                ).compareTo(_getConversationTimeValue(b)),
              );

          setState(() {
            _conversations.clear();
            _conversations.addAll(sortedConversations.cast<Conversation>());

            // Restore current conversation position if possible
            if (currentConvId != null && _conversations.isNotEmpty) {
              final index = _conversations.indexWhere(
                (c) => c.id == currentConvId,
              );
              if (index >= 0) {
                _currentConversationIndex = index;
                if (currentHistory != null && currentHistory.isNotEmpty) {
                  // Keep the current history if it exists
                  _provider.history = currentHistory;
                } else {
                  // Otherwise use the history from Firestore
                  _provider.history = List<ChatMessage>.from(
                    _conversations[index].history,
                  );
                }
              } else {
                // If we couldn't find the previous conversation, select the first one
                _currentConversationIndex = 0;
                _provider.history = List<ChatMessage>.from(
                  _conversations[0].history,
                );
              }
            } else if (_conversations.isNotEmpty) {
              // Select first conversation if previous selection is gone
              _currentConversationIndex = 0;
              _provider.history = List<ChatMessage>.from(
                _conversations[0].history,
              );
            } else {
              // No conversations available
              _currentConversationIndex = -1;
              _provider.history = [];
            }
          });

          _updatingFromStream = false;
        }
      },
      onError: (error) {
        debugPrint('Error streaming conversations: $error');
        // Reconnect after a delay
        Future.delayed(const Duration(seconds: 5), _subscribeToConversations);
      },
      onDone: () {
        debugPrint('Conversation stream closed. Reconnecting...');
        // Reconnect after a delay
        Future.delayed(const Duration(seconds: 5), _subscribeToConversations);
      },
    );
  }

  // Helper to compare conversation lists
  bool _listsEqual(List<Conversation> list1, List<Conversation> list2) {
    if (list1.length != list2.length) return false;

    // Check if any conversation has changed by comparing IDs and names
    for (int i = 0; i < list1.length; i++) {
      bool found = false;
      for (int j = 0; j < list2.length; j++) {
        if (list1[i].id == list2[j].id) {
          if (list1[i].name != list2[j].name) {
            return false; // Name changed
          }
          // If message counts differ, consider lists not equal
          if ((list1[i].history as List).length !=
              (list2[j].history as List).length) {
            return false;
          }
          found = true;
          break;
        }
      }
      if (!found) return false; // Conversation not found in other list
    }

    return true;
  }

  // Helper function to get a comparable timestamp value from conversation
  int _getConversationTimeValue(Conversation conversation) {
    // Assume each conversation has a last updated time or creation time
    // For now we'll use the index in the list as a fallback
    final index = _conversations.indexWhere((c) => c.id == conversation.id);
    return index >= 0 ? index : 0;
  }

  // Toggle sidebar
  void _toggleSidebar() {
    setState(() {
      _isSidebarExpanded = !_isSidebarExpanded;
    });
  }

  void _onError(BuildContext context, LlmException error) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Error: ${error.message}')));
  }

  void _onCancel(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Chat cancelled')));
  }

  void _clearHistory() {
    if (_currentConversationIndex >= 0) {
      setState(() {
        _conversations[_currentConversationIndex].history = [];
        _provider.history = [];
      });

      // Directly update in Firestore
      if (_currentConversationIndex < _conversations.length) {
        _firestoreService.saveConversation(
          _conversations[_currentConversationIndex],
        );
      }
    }
  }

  // Rename the current conversation
  void _renameConversation(int index, String newName) {
    if (index >= 0 && index < _conversations.length && newName.isNotEmpty) {
      setState(() {
        _conversations[index].name = newName;
      });

      // Save directly instead of using periodic save
      _firestoreService.saveConversation(_conversations[index]);
    }
  }

  // Delete a conversation
  void _deleteConversation(int index) {
    if (index >= 0 && index < _conversations.length) {
      final conversationId = _conversations[index].id;

      setState(() {
        _conversations.removeAt(index);

        // Update current conversation index
        if (_conversations.isEmpty) {
          _currentConversationIndex = -1;
          _provider.history = [];
        } else if (_currentConversationIndex >= _conversations.length) {
          _currentConversationIndex = _conversations.length - 1;
          _provider.history = _conversations[_currentConversationIndex].history;
        } else if (_currentConversationIndex == index) {
          _provider.history = _conversations[_currentConversationIndex].history;
        }
      });

      // Delete from Firestore directly
      _firestoreService.deleteConversation(conversationId);
    }
  }

  // Show dialog to create a new conversation
  Future<void> _showNewConversationDialog() async {
    _newConversationController.clear();
    return showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('New Conversation'),
            content: TextField(
              controller: _newConversationController,
              decoration: const InputDecoration(hintText: 'Conversation Name'),
              autofocus: true,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  _createNewConversation(name: _newConversationController.text);
                  Navigator.of(context).pop();
                },
                child: const Text('Create'),
              ),
            ],
          ),
    );
  }

  // Show dialog to rename a conversation
  Future<void> _showRenameConversationDialog(int index) async {
    _newConversationController.text = _conversations[index].name;
    return showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Rename Conversation'),
            content: TextField(
              controller: _newConversationController,
              decoration: const InputDecoration(hintText: 'New Name'),
              autofocus: true,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  _renameConversation(index, _newConversationController.text);
                  Navigator.of(context).pop();
                },
                child: const Text('Rename'),
              ),
            ],
          ),
    );
  }

  // Show dialog to collect feedback
  Future<void> _showFeedbackDialog() async {
    _feedbackController.clear();
    bool isProblemResolved = false;

    return showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: const Text('Provide Feedback'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Problem resolution checkbox
                      Row(
                        children: [
                          Checkbox(
                            value: isProblemResolved,
                            onChanged: (value) {
                              setState(() {
                                isProblemResolved = value ?? false;
                              });
                            },
                          ),
                          const Text('Did you get your problem resolved?'),
                        ],
                      ),

                      const SizedBox(height: 12),

                      const Text(
                        'Please share your feedback about the current conversation:',
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _feedbackController,
                        decoration: const InputDecoration(
                          hintText: 'Your feedback here',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 4,
                        autofocus: true,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Note: Your feedback will include the entire conversation history.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        _sendFeedback(
                          _feedbackController.text,
                          isProblemResolved,
                        );
                        Navigator.of(context).pop();
                      },
                      child: const Text('Submit'),
                    ),
                  ],
                ),
          ),
    );
  }

  // Send feedback to Firestore
  Future<void> _sendFeedback(String comment, bool isProblemResolved) async {
    if (_currentConversationIndex >= 0 &&
        _currentConversationIndex < _conversations.length) {
      try {
        // Get current conversation details
        final conversation = _conversations[_currentConversationIndex];

        // Create feedback data
        final feedback = {
          'conversationId': conversation.id,
          'conversationName': conversation.name,
          'timestamp': DateTime.now().toIso8601String(),
          'comment': comment,
          'isProblemResolved': isProblemResolved,
          'history':
              conversation.history
                  .map(
                    (msg) => {
                      'role': msg.origin.isUser ? 'user' : 'llm',
                      'content': msg.text,
                    },
                  )
                  .toList(),
        };

        // Save feedback to Firestore
        await _firestoreService.addFeedback(feedback);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thank you for your feedback!')),
        );
      } catch (e) {
        debugPrint('Error sending feedback: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send feedback. Please try again.'),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No active conversation to provide feedback on.'),
        ),
      );
    }
  }

  // Handle app lifecycle changes
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      // App came to foreground
      _isInForeground = true;

      // Reset stream subscription to ensure we get fresh data
      _subscribeToConversations();
    } else if (state == AppLifecycleState.paused) {
      // App went to background
      _isInForeground = false;

      // Save current state before going to background
      if (!_isSaving) {
        _saveConversations();
      }
    }
  }

  @override
  void initState() {
    super.initState();

    // Register for lifecycle events
    WidgetsBinding.instance.addObserver(this);

    // Initialize provider
    _initializeProvider();

    // Load saved conversations from Firestore
    _loadConversations();

    // Set up periodic saving every 30 seconds
    _saveTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _saveConversations();
    });

    // Listen for changes to the provider's history
    _provider.addListener(_onProviderHistoryChanged);
  }

  void _onProviderHistoryChanged() {
    // When the provider history changes, schedule a save operation
    _debouncedSave();
  }

  @override
  void dispose() {
    // Unregister from lifecycle events
    WidgetsBinding.instance.removeObserver(this);

    // Remove provider listener
    _provider.removeListener(_onProviderHistoryChanged);

    // Cancel subscriptions and timers
    _conversationsSubscription?.cancel();
    _saveTimer?.cancel();
    _debounceTimer?.cancel();

    // Dispose of controllers
    _newConversationController.dispose();
    _feedbackController.dispose();

    // Try-catch the final save to prevent errors during disposal
    try {
      if (!_isSaving &&
          _currentConversationIndex >= 0 &&
          _currentConversationIndex < _conversations.length) {
        // Only save if we have messages
        final currentHistory = List<ChatMessage>.from(_provider.history);
        if (currentHistory.isNotEmpty) {
          _conversations[_currentConversationIndex].history = currentHistory;

          // Create a defensive copy before saving
          final conversationCopy = Conversation(
            id: _conversations[_currentConversationIndex].id,
            name: _conversations[_currentConversationIndex].name,
            history: currentHistory,
          );

          // Save directly just the current conversation
          _firestoreService.saveConversation(conversationCopy);
        }
      }
    } catch (e) {
      debugPrint('Error saving during dispose: $e');
    }

    super.dispose();
  }

  // Widget to build the sidebar content
  Widget _buildSidebar(BuildContext context) {
    // Using LayoutBuilder to constrain sidebar properly
    return LayoutBuilder(
      builder: (context, constraints) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: _isSidebarExpanded ? 280 : 0,
          curve: Curves.easeInOut,
          color: Theme.of(context).colorScheme.surface,
          // Use clipped container to avoid layout issues during animation
          child:
              _isSidebarExpanded
                  ? ClipRect(
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header container
                        Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 12,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Your Conversations',
                                style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 6),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _showNewConversationDialog,
                                  icon: const Icon(Icons.add, size: 16),
                                  label: const Text(
                                    'New Chat',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const Divider(height: 1, thickness: 0.5),

                        // Conversation list - in Expanded to avoid overflow
                        Expanded(
                          child:
                              _conversations.isEmpty
                                  ? const Center(
                                    child: Text('No conversations yet'),
                                  )
                                  : ListView.builder(
                                    shrinkWrap: false,
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    padding: EdgeInsets.zero,
                                    itemCount: _conversations.length,
                                    itemBuilder: (context, index) {
                                      final conversation =
                                          _conversations[index];
                                      final isHovered =
                                          _hoveredConversationIndex == index;

                                      // Wrap with MouseRegion to detect hover
                                      return MouseRegion(
                                        onEnter:
                                            (_) => setState(() {
                                              _hoveredConversationIndex = index;
                                            }),
                                        onExit:
                                            (_) => setState(() {
                                              if (_hoveredConversationIndex ==
                                                  index) {
                                                _hoveredConversationIndex =
                                                    null;
                                              }
                                            }),
                                        child: InkWell(
                                          onTap:
                                              () =>
                                                  _switchToConversation(index),
                                          child: Container(
                                            color:
                                                index ==
                                                        _currentConversationIndex
                                                    ? Theme.of(
                                                      context,
                                                    ).highlightColor
                                                    : Colors.transparent,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 6,
                                            ),
                                            child: Row(
                                              children: [
                                                // Chat icon
                                                const Padding(
                                                  padding: EdgeInsets.only(
                                                    right: 8.0,
                                                  ),
                                                  child: Icon(
                                                    Icons.chat,
                                                    size: 18,
                                                  ),
                                                ),

                                                // Chat name - expanded to take available space
                                                Expanded(
                                                  child: Text(
                                                    conversation.name,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      fontWeight:
                                                          index ==
                                                                  _currentConversationIndex
                                                              ? FontWeight.bold
                                                              : FontWeight
                                                                  .normal,
                                                    ),
                                                  ),
                                                ),

                                                // Only show action buttons when hovered
                                                if (isHovered) ...[
                                                  // Edit button - compact
                                                  InkWell(
                                                    onTap:
                                                        () =>
                                                            _showRenameConversationDialog(
                                                              index,
                                                            ),
                                                    child: const Padding(
                                                      padding: EdgeInsets.all(
                                                        6.0,
                                                      ),
                                                      child: Icon(
                                                        Icons.edit,
                                                        size: 16,
                                                      ),
                                                    ),
                                                  ),

                                                  // Small gap between buttons
                                                  const SizedBox(width: 2),

                                                  // Delete button - compact
                                                  InkWell(
                                                    onTap:
                                                        () =>
                                                            _deleteConversation(
                                                              index,
                                                            ),
                                                    child: const Padding(
                                                      padding: EdgeInsets.all(
                                                        6.0,
                                                      ),
                                                      child: Icon(
                                                        Icons.delete,
                                                        size: 16,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                        ),

                        const Divider(height: 1, thickness: 0.5),

                        // LLM Provider dropdown selection
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 12,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Active Agent',
                                style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              DropdownButton<LlmProviderType>(
                                value: _currentProviderType,
                                onChanged: (LlmProviderType? newValue) {
                                  if (newValue != null) {
                                    _changeProvider(newValue);
                                  }
                                },
                                items:
                                    LlmProviderType.values.map<
                                      DropdownMenuItem<LlmProviderType>
                                    >((LlmProviderType value) {
                                      return DropdownMenuItem<LlmProviderType>(
                                        value: value,
                                        child: Text(value.displayName),
                                      );
                                    }).toList(),
                                isExpanded:
                                    true, // Make dropdown take full width
                                icon: const Icon(Icons.swap_horiz),
                              ),
                            ],
                          ),
                        ),

                        // Feedback button at the bottom
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 12,
                          ),
                          child: ElevatedButton.icon(
                            onPressed:
                                _currentConversationIndex >= 0
                                    ? _showFeedbackDialog
                                    : null,
                            icon: const Icon(Icons.feedback, size: 16),
                            label: const Text('Provide Feedback'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 8,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                  : null,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leadingWidth: 84,
      leading: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          IconButton(
            icon: Icon(_isSidebarExpanded ? Icons.menu_open : Icons.menu),
            tooltip: _isSidebarExpanded ? 'Collapse Sidebar' : 'Expand Sidebar',
            onPressed: _toggleSidebar,
          ),
        ],
      ),
      title: Text(
        _isLoading
            ? 'Loading...'
            : ((_currentConversationIndex >= 0 &&
                    _currentConversationIndex < _conversations.length)
                ? _conversations[_currentConversationIndex].name
                : App.title),
        overflow: TextOverflow.ellipsis, // Handle possible overflow in title
      ),
      actions: [
        // Removed dropdown for LLM provider selection (moved to sidebar)
        IconButton(
          onPressed: _showNewConversationDialog,
          tooltip: 'New Conversation',
          icon: const Icon(Icons.add),
        ),
        IconButton(
          onPressed: _clearHistory,
          tooltip: 'Clear History',
          icon: const Icon(Icons.clear_all),
        ),
        IconButton(
          onPressed:
              () =>
                  App.themeMode.value =
                      App.themeMode.value == ThemeMode.light
                          ? ThemeMode.dark
                          : ThemeMode.light,
          tooltip:
              App.themeMode.value == ThemeMode.light
                  ? 'Dark Mode'
                  : 'Light Mode',
          icon: const Icon(Icons.brightness_4_outlined),
        ),
      ],
    ),
    body:
        _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SafeArea(
              // Added SafeArea to ensure proper insets
              child: LayoutBuilder(
                // Added LayoutBuilder to get available size
                builder: (context, constraints) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sidebar
                      _buildSidebar(context),

                      // Divider when sidebar is expanded
                      if (_isSidebarExpanded)
                        const VerticalDivider(width: 1, thickness: 1),

                      // Main content - Now properly constrained with Expanded
                      Expanded(
                        child:
                            (_currentConversationIndex < 0 ||
                                    _conversations.isEmpty)
                                ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text('No active conversations'),
                                      const SizedBox(height: 16),
                                      ElevatedButton.icon(
                                        onPressed: _showNewConversationDialog,
                                        icon: const Icon(Icons.add),
                                        label: const Text(
                                          'Create New Conversation',
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                                : LlmChatView(
                                  onCancelCallback: _onCancel,
                                  cancelMessage: 'Request cancelled',
                                  onErrorCallback: _onError,
                                  errorMessage: 'An error occurred',
                                  welcomeMessage:
                                      'Hello and welcome to the MatFixer!',
                                  style:
                                      App.themeMode.value == ThemeMode.light
                                          ? MatlabChatTheme.matlabStyle()
                                          : MatlabChatTheme.matlabDarkStyle(),
                                  provider: _provider,
                                ),
                      ),
                    ],
                  );
                },
              ),
            ),
  );
}
