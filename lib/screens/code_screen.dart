import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../services/ai_service.dart';

class CodeScreen extends StatefulWidget {
  const CodeScreen({super.key});

  @override
  State<CodeScreen> createState() => _CodeScreenState();
}

class _CodeScreenState extends State<CodeScreen> {
  final TextEditingController _input = TextEditingController();
  String _language = 'Dart';

  static const List<String> _languages = <String>[
    'Dart',
    'TypeScript',
    'JavaScript',
    'Python',
    'Kotlin',
    'Java',
    'Go',
    'Rust',
    'C++',
    'SQL',
  ];

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _run(String action) async {
    final String code = _input.text.trim();
    if (code.isEmpty) return;
    final AiService ai = context.read<AiService>();
    final String prompt = switch (action) {
      'explain' =>
        'Explain the following $_language code, line by line, concisely:\n\n$code',
      'refactor' =>
        'Refactor this $_language code for clarity and performance. Output only the final code.\n\n$code',
      _ => 'Review this $_language code and list issues:\n\n$code',
    };
    await ai.sendUserMessage(prompt);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sent to chat.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Text(
                'Language',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 12),
              DropdownButton<String>(
                value: _language,
                underline: const SizedBox.shrink(),
                items: _languages
                    .map((String l) => DropdownMenuItem<String>(
                          value: l,
                          child: Text(l),
                        ))
                    .toList(),
                onChanged: (String? v) {
                  if (v != null) setState(() => _language = v);
                },
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Copy',
                icon: const Icon(Icons.copy_rounded, size: 18),
                onPressed: () async {
                  await Clipboard.setData(
                    ClipboardData(text: _input.text),
                  );
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Copied')),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0B0B0D),
                borderRadius: BorderRadius.circular(14),
              ),
              child: TextField(
                controller: _input,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                keyboardType: TextInputType.multiline,
                style: const TextStyle(
                  color: Color(0xFFE5E7EB),
                  fontFamily: 'monospace',
                  fontSize: 13,
                  height: 1.45,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  hintText: '// paste or write code here',
                  hintStyle: TextStyle(color: Color(0xFF6B7280)),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              ElevatedButton(
                onPressed: () => _run('explain'),
                child: const Text('Explain'),
              ),
              OutlinedButton(
                onPressed: () => _run('refactor'),
                child: const Text('Refactor'),
              ),
              OutlinedButton(
                onPressed: () => _run('review'),
                child: const Text('Review'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
