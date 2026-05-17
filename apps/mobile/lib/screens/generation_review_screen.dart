import 'package:flutter/material.dart';
import 'package:core/core.dart' as core;

import '../main.dart';

class GenerationReviewScreen extends StatefulWidget {
  final List<core.GeneratedCard> generatedCards;
  final String language;

  const GenerationReviewScreen({
    super.key,
    required this.generatedCards,
    required this.language,
  });

  @override
  State<GenerationReviewScreen> createState() => _GenerationReviewScreenState();
}

class _GenerationReviewScreenState extends State<GenerationReviewScreen> {
  late List<core.GeneratedCard> _cards;
  bool _accepting = false;

  @override
  void initState() {
    super.initState();
    _cards = List.from(widget.generatedCards);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Review (${_cards.length} cards)'),
      ),
      body: _cards.isEmpty
          ? const Center(child: Text('No cards to review'))
          : ListView.builder(
              itemCount: _cards.length,
              itemBuilder: (context, index) {
                final card = _cards[index];
                return Dismissible(
                  key: ValueKey('${card.sourceValue}_${card.targetValue}'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) {
                    setState(() => _cards.removeAt(index));
                  },
                  child: ListTile(
                    title: Text(
                      card.sourceValue,
                      style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                      ),
                    ),
                    subtitle: Text(
                      card.targetValue,
                      style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primaryContainer,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'AI',
                            style: TextStyle(
                              fontSize: 10,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                    onTap: () => _editCard(index),
                    onLongPress: () {
                      setState(() => _cards.removeAt(index));
                    },
                  ),
                );
              },
            ),
      bottomNavigationBar: _cards.isEmpty
          ? null
          : Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton(
                onPressed: _accepting ? null : _acceptAll,
                child: _accepting
                    ? const CircularProgressIndicator()
                    : Text('Accept All (${_cards.length})'),
              ),
            ),
    );
  }

  Future<void> _editCard(int index) async {
    final card = _cards[index];
    final result = await showDialog<core.GeneratedCard>(
      context: context,
      builder: (context) => _EditGeneratedCardDialog(card: card),
    );
    if (result != null && mounted) {
      setState(() => _cards[index] = result);
    }
  }

  Future<void> _acceptAll() async {
    setState(() => _accepting = true);

    for (final card in _cards) {
      await cardRepository.createCard(
        language: widget.language,
        fields: {
          card.sourceFieldName: card.sourceValue,
          card.targetFieldName: card.targetValue,
        },
        fieldSpeakable: {
          card.sourceFieldName: true,
          card.targetFieldName: false,
        },
      );
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_cards.length} cards added to Library')),
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }
}

class _EditGeneratedCardDialog extends StatefulWidget {
  final core.GeneratedCard card;

  const _EditGeneratedCardDialog({required this.card});

  @override
  State<_EditGeneratedCardDialog> createState() =>
      _EditGeneratedCardDialogState();
}

class _EditGeneratedCardDialogState extends State<_EditGeneratedCardDialog> {
  late TextEditingController _sourceController;
  late TextEditingController _targetController;

  @override
  void initState() {
    super.initState();
    _sourceController = TextEditingController(text: widget.card.sourceValue);
    _targetController = TextEditingController(text: widget.card.targetValue);
  }

  @override
  void dispose() {
    _sourceController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Card'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _sourceController,
            decoration: InputDecoration(
              labelText: widget.card.sourceFieldName,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _targetController,
            decoration: InputDecoration(
              labelText: widget.card.targetFieldName,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(
            core.GeneratedCard(
              sourceFieldName: widget.card.sourceFieldName,
              sourceValue: _sourceController.text,
              targetFieldName: widget.card.targetFieldName,
              targetValue: _targetController.text,
            ),
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
