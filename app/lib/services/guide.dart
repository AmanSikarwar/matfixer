import 'package:flutter/material.dart';
import 'package:matfixer/data/guide_data.dart';
import 'package:matfixer/matlab_chat_theme.dart';
import 'package:matfixer/services/mywidget.dart'; // Import the model file
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class InstallationGuideScreen extends StatefulWidget {
  const InstallationGuideScreen({super.key});

  @override
  State<InstallationGuideScreen> createState() =>
      _InstallationGuideScreenState();
}

class _InstallationGuideScreenState extends State<InstallationGuideScreen> {
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _itemPositionsListener.itemPositions.addListener(_onScroll);
  }

  void _onScroll() {
    final positions = _itemPositionsListener.itemPositions.value;
    final visible = positions.where((pos) => pos.itemLeadingEdge >= 0).toList();
    if (visible.isNotEmpty) {
      final firstVisible = visible.reduce(
        (a, b) => a.itemLeadingEdge < b.itemLeadingEdge ? a : b,
      );
      if (_currentIndex != firstVisible.index) {
        setState(() {
          _currentIndex = firstVisible.index;
        });
      }
    }
  }

  void _scrollTo(int index) {
    _itemScrollController.scrollTo(
      index: index,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Installation Guide')),
      body: Row(
        children: [
          Container(
            width: 200,
            color: Colors.white,
            child: ListView.builder(
              itemCount: installationSteps.length,
              itemBuilder: (context, index) {
                final isActive = index == _currentIndex;
                return ListTile(
                  title: Text(
                    installationSteps[index].title,
                    style: TextStyle(
                      fontWeight:
                          isActive ? FontWeight.bold : FontWeight.normal,
                      color:
                          isActive
                              ? Theme.of(context).colorScheme.primary
                              : null,
                    ),
                  ),
                  onTap: () => _scrollTo(index),
                );
              },
            ),
          ),
          Expanded(
            child: ScrollablePositionedList.builder(
              itemCount: installationSteps.length,
              itemScrollController: _itemScrollController,
              itemPositionsListener: _itemPositionsListener,
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final step = installationSteps[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Card(
                    color: MatlabColors.lightBlueBackground,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            step.title,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            step.content,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          if (step.code != null && step.language != null) ...[
                            const SizedBox(height: 16),
                            MyWidget(
                              code: step.code!,
                              language: step.language!,
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
        ],
      ),
    );
  }
}
