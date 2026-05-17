import 'dart:convert';

import 'package:flutter/material.dart';

import '../main.dart';

class CardFormScreen extends StatefulWidget {
  final int? cardId;

  const CardFormScreen({super.key, this.cardId});

  @override
  State<CardFormScreen> createState() => _CardFormScreenState();
}

class _CardFormScreenState extends State<CardFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _languageController = TextEditingController();
  final _sourceFieldNameController = TextEditingController();
  final _sourceValueController = TextEditingController();
  final _targetFieldNameController = TextEditingController();
  final _targetValueController = TextEditingController();
  bool _sourceSpeakable = true;
  bool _targetSpeakable = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    if (widget.cardId != null) {
      _isEditing = true;
      _loadCard();
    }
  }

  Future<void> _loadCard() async {
    final card = await cardRepository.getCard(widget.cardId!);
    if (card == null || !mounted) return;

    final fields = Map<String, String>.from(
        jsonDecode(card.fields) as Map<String, dynamic>);
    final speakable = Map<String, bool>.from(
        jsonDecode(card.fieldSpeakable) as Map<String, dynamic>);
    final keys = fields.keys.toList();

    setState(() {
      _languageController.text = card.language;
      if (keys.isNotEmpty) {
        _sourceFieldNameController.text = keys[0];
        _sourceValueController.text = fields[keys[0]]!;
        _sourceSpeakable = speakable[keys[0]] ?? false;
      }
      if (keys.length > 1) {
        _targetFieldNameController.text = keys[1];
        _targetValueController.text = fields[keys[1]]!;
        _targetSpeakable = speakable[keys[1]] ?? false;
      }
    });
  }

  @override
  void dispose() {
    _languageController.dispose();
    _sourceFieldNameController.dispose();
    _sourceValueController.dispose();
    _targetFieldNameController.dispose();
    _targetValueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Card' : 'New Card'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteCard,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _languageController,
              decoration: const InputDecoration(
                labelText: 'Language',
                hintText: 'e.g. Ukrainian',
              ),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Language is required' : null,
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _sourceFieldNameController,
              decoration: const InputDecoration(
                labelText: 'Source field name',
                hintText: 'e.g. Ukrainian',
              ),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Field name is required' : null,
            ),
            TextFormField(
              controller: _sourceValueController,
              decoration: const InputDecoration(
                labelText: 'Source value',
                hintText: 'e.g. привіт',
              ),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Value is required' : null,
            ),
            SwitchListTile(
              title: const Text('Speakable'),
              value: _sourceSpeakable,
              onChanged: (v) => setState(() => _sourceSpeakable = v),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _targetFieldNameController,
              decoration: const InputDecoration(
                labelText: 'Target field name',
                hintText: 'e.g. English',
              ),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Field name is required' : null,
            ),
            TextFormField(
              controller: _targetValueController,
              decoration: const InputDecoration(
                labelText: 'Target value',
                hintText: 'e.g. hello',
              ),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Value is required' : null,
            ),
            SwitchListTile(
              title: const Text('Speakable'),
              value: _targetSpeakable,
              onChanged: (v) => setState(() => _targetSpeakable = v),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _save,
              child: Text(_isEditing ? 'Save Changes' : 'Create Card'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final fields = {
      _sourceFieldNameController.text: _sourceValueController.text,
      _targetFieldNameController.text: _targetValueController.text,
    };
    final speakable = {
      _sourceFieldNameController.text: _sourceSpeakable,
      _targetFieldNameController.text: _targetSpeakable,
    };

    if (_isEditing) {
      await cardRepository.updateCard(
        widget.cardId!,
        language: _languageController.text,
        fields: fields,
        fieldSpeakable: speakable,
      );
    } else {
      await cardRepository.createCard(
        language: _languageController.text,
        fields: fields,
        fieldSpeakable: speakable,
      );
    }

    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _deleteCard() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Card'),
        content: const Text('Are you sure you want to delete this card?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await cardRepository.softDeleteCard(widget.cardId!);
      if (mounted) Navigator.of(context).pop();
    }
  }
}
