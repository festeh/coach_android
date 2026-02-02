import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/app_rule.dart';

class RuleEditorDialog extends StatefulWidget {
  final AppRule? existingRule;

  const RuleEditorDialog({super.key, this.existingRule});

  @override
  State<RuleEditorDialog> createState() => _RuleEditorDialogState();
}

class _RuleEditorDialogState extends State<RuleEditorDialog> {
  late final TextEditingController _everyNController;
  late final TextEditingController _maxTriggersController;
  late String _challengeType;

  static const _challengeTypes = [
    ('none', 'None'),
    ('longPress', 'Long Press'),
    ('typing', 'Typing'),
  ];

  @override
  void initState() {
    super.initState();
    _everyNController = TextEditingController(
      text: (widget.existingRule?.everyN ?? 3).toString(),
    );
    _maxTriggersController = TextEditingController(
      text: (widget.existingRule?.maxTriggers ?? 5).toString(),
    );
    _challengeType = widget.existingRule?.challengeType ?? 'none';
  }

  @override
  void dispose() {
    _everyNController.dispose();
    _maxTriggersController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingRule != null;

    return AlertDialog(
      title: Text(isEditing ? 'Edit Rule' : 'Add Rule'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _everyNController,
            decoration: const InputDecoration(
              labelText: 'Every N-th open',
              hintText: '3',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _maxTriggersController,
            decoration: const InputDecoration(
              labelText: 'Max triggers per day',
              hintText: '5',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _challengeType,
            decoration: const InputDecoration(
              labelText: 'Challenge',
              border: OutlineInputBorder(),
            ),
            items: _challengeTypes.map((entry) {
              return DropdownMenuItem(
                value: entry.$1,
                child: Text(entry.$2),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _challengeType = value);
              }
            },
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
            final everyN = int.tryParse(_everyNController.text);
            final maxTriggers = int.tryParse(_maxTriggersController.text);

            if (everyN == null || everyN < 1 || maxTriggers == null || maxTriggers < 1) {
              return;
            }

            Navigator.of(context).pop(RuleEditorResult(
              everyN: everyN,
              maxTriggers: maxTriggers,
              challengeType: _challengeType,
            ));
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class RuleEditorResult {
  final int everyN;
  final int maxTriggers;
  final String challengeType;

  RuleEditorResult({
    required this.everyN,
    required this.maxTriggers,
    this.challengeType = 'none',
  });
}
