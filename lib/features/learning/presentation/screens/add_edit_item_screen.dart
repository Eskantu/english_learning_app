import 'package:flutter/material.dart';

import '../../domain/entities/learning_item.dart';

class AddEditItemScreen extends StatefulWidget {
  const AddEditItemScreen({super.key, this.initialItem});

  final LearningItem? initialItem;

  @override
  State<AddEditItemScreen> createState() => _AddEditItemScreenState();
}

class _AddEditItemScreenState extends State<AddEditItemScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _textController;
  late final TextEditingController _meaningController;
  late final TextEditingController _examplesController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.initialItem?.text ?? '');
    _meaningController =
        TextEditingController(text: widget.initialItem?.meaning ?? '');
    _examplesController = TextEditingController(
      text: widget.initialItem?.examples.join('\n') ?? '',
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _meaningController.dispose();
    _examplesController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final DateTime now = DateTime.now();
    final List<String> examples = _examplesController.text
        .split('\n')
        .map((String e) => e.trim())
        .where((String e) => e.isNotEmpty)
        .toList(growable: false);

    final LearningItem item = LearningItem(
      id: widget.initialItem?.id ?? now.microsecondsSinceEpoch.toString(),
      text: _textController.text.trim(),
      meaning: _meaningController.text.trim(),
      examples: examples,
      repetitionLevel: widget.initialItem?.repetitionLevel ?? 0,
      nextReviewDate: widget.initialItem?.nextReviewDate ?? now,
      createdAt: widget.initialItem?.createdAt ?? now,
    );

    Navigator.of(context).pop(item);
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditing = widget.initialItem != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar frase' : 'Agregar frase'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              TextFormField(
                controller: _textController,
                decoration: const InputDecoration(labelText: 'Texto en ingles'),
                validator: (String? value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa el texto en ingles.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _meaningController,
                decoration: const InputDecoration(labelText: 'Significado en espanol'),
                validator: (String? value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa el significado.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _examplesController,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Ejemplos (uno por linea)',
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _submit,
                child: const Text('Guardar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
