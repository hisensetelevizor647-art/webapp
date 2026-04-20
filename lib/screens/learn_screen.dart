import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/ai_service.dart';

/// NotebookLM-style "Learn" mode: user supplies source text, app produces a
/// summary + follow-up Q&A handled by the regular chat pipeline.
class LearnScreen extends StatefulWidget {
  const LearnScreen({super.key});

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  final TextEditingController _source = TextEditingController();
  final TextEditingController _question = TextEditingController();

  @override
  void dispose() {
    _source.dispose();
    _question.dispose();
    super.dispose();
  }

  Future<void> _summarize() async {
    final String src = _source.text.trim();
    if (src.isEmpty) return;
    final AiService ai = context.read<AiService>();
    await ai.sendUserMessage(
      'Summarize the following source material with bullet points and a short conclusion:\n\n$src',
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Summary request sent to chat.')),
      );
    }
  }

  Future<void> _ask() async {
    final String src = _source.text.trim();
    final String q = _question.text.trim();
    if (q.isEmpty) return;
    final AiService ai = context.read<AiService>();
    final String prompt = src.isEmpty
        ? q
        : 'Using the following sources, answer: $q\n\nSources:\n$src';
    await ai.sendUserMessage(prompt);
    _question.clear();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const _SectionTitle(title: 'Source material'),
          const SizedBox(height: 8),
          TextField(
            controller: _source,
            maxLines: 8,
            decoration: const InputDecoration(
              hintText: 'Paste an article, notes, or any text…',
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _summarize,
            icon: const Icon(Icons.auto_stories_outlined, size: 18),
            label: const Text('Summarize'),
          ),
          const SizedBox(height: 24),
          const _SectionTitle(title: 'Ask about this source'),
          const SizedBox(height: 8),
          TextField(
            controller: _question,
            onSubmitted: (_) => _ask(),
            decoration: const InputDecoration(
              hintText: 'What do you want to know?',
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _ask,
            icon: const Icon(Icons.question_answer_outlined, size: 18),
            label: const Text('Ask'),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
    );
  }
}
