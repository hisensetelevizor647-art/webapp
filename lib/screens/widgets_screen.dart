import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/pinned_widget.dart';
import '../services/ai_service.dart';
import '../services/widget_registry_service.dart';

/// Built-in catalog of prompt widgets. Anything the user pins from here flows
/// into the global [WidgetRegistryService] and automatically shows up on the
/// Chat home rail and in Settings.
const List<PinnedWidget> _catalog = <PinnedWidget>[
  PinnedWidget(
    id: 'translate',
    title: 'Translate',
    subtitle: 'Translate text to any language',
    prompt: 'Translate the following text to English, keeping the tone:\n\n',
    iconCode: 0xe8e2, // translate
  ),
  PinnedWidget(
    id: 'summarize',
    title: 'Summarize',
    subtitle: 'Turn long text into key points',
    prompt: 'Summarize this in 5 concise bullets:\n\n',
    iconCode: 0xe8b6, // subject
  ),
  PinnedWidget(
    id: 'rewrite',
    title: 'Rewrite',
    subtitle: 'Polish tone and grammar',
    prompt: 'Rewrite this for clarity and professional tone:\n\n',
    iconCode: 0xe3c9, // edit
  ),
  PinnedWidget(
    id: 'brainstorm',
    title: 'Brainstorm',
    subtitle: 'Generate 10 ideas about…',
    prompt: 'Give me 10 creative ideas about:\n\n',
    iconCode: 0xe0f0, // lightbulb
  ),
  PinnedWidget(
    id: 'explain',
    title: 'Explain',
    subtitle: 'Explain like I am five',
    prompt: 'Explain this like I am five years old:\n\n',
    iconCode: 0xe887, // help_outline
  ),
  PinnedWidget(
    id: 'email',
    title: 'Email reply',
    subtitle: 'Draft a polite email reply',
    prompt: 'Write a polite, concise email reply to:\n\n',
    iconCode: 0xe0be, // email
  ),
];

class WidgetsScreen extends StatelessWidget {
  const WidgetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AiService ai = context.read<AiService>();
    final WidgetRegistryService reg =
        context.watch<WidgetRegistryService>();

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.95,
      ),
      itemCount: _catalog.length,
      itemBuilder: (BuildContext _, int i) {
        final PinnedWidget w = _catalog[i];
        final bool pinned = reg.contains(w.id);
        return _WidgetCard(
          widget: w,
          pinned: pinned,
          onTap: () => _openPrompt(context, ai, w),
          onTogglePin: () async {
            await reg.toggle(w);
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                duration: const Duration(milliseconds: 1400),
                content: Text(
                  pinned
                      ? 'Removed from home & Settings.'
                      : 'Pinned to home & Settings.',
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openPrompt(
      BuildContext context, AiService ai, PinnedWidget w) async {
    final String? text = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext ctx) => _PromptSheet(widget: w),
    );
    if (text != null && text.trim().isNotEmpty) {
      await ai.sendUserMessage('${w.prompt}${text.trim()}');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sent to chat.')),
        );
      }
    }
  }
}

class _WidgetCard extends StatelessWidget {
  const _WidgetCard({
    required this.widget,
    required this.pinned,
    required this.onTap,
    required this.onTogglePin,
  });
  final PinnedWidget widget;
  final bool pinned;
  final VoidCallback onTap;
  final VoidCallback onTogglePin;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      IconData(widget.iconCode, fontFamily: 'MaterialIcons'),
                      size: 20,
                      color: Colors.black,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                        width: 32, height: 32),
                    onPressed: onTogglePin,
                    tooltip: pinned ? 'Unpin' : 'Pin',
                    icon: Icon(
                      pinned
                          ? Icons.push_pin
                          : Icons.push_pin_outlined,
                      size: 18,
                      color: pinned ? Colors.black : const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                widget.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 12,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PromptSheet extends StatefulWidget {
  const _PromptSheet({required this.widget});
  final PinnedWidget widget;

  @override
  State<_PromptSheet> createState() => _PromptSheetState();
}

class _PromptSheetState extends State<_PromptSheet> {
  final TextEditingController _c = TextEditingController();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Text(
            widget.widget.title,
            style:
                const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            widget.widget.subtitle,
            style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _c,
            maxLines: 6,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Enter your text…'),
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(_c.text),
            child: const Text('Run'),
          ),
        ],
      ),
    );
  }
}
