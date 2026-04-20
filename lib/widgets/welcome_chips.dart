import 'package:flutter/material.dart';

class WelcomeChips extends StatelessWidget {
  const WelcomeChips({super.key, required this.onPick});
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final List<_Chip> chips = <_Chip>[
      const _Chip(icon: Icons.auto_awesome, label: 'Surprise me'),
      const _Chip(icon: Icons.edit_outlined, label: 'Write a message'),
      const _Chip(icon: Icons.school_outlined, label: 'Explain a concept'),
      const _Chip(icon: Icons.code_rounded, label: 'Debug some code'),
      const _Chip(icon: Icons.translate_rounded, label: 'Translate'),
    ];

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 10,
      children: chips
          .map((_Chip c) => _ChipButton(
                chip: c,
                onTap: () => onPick(_promptFor(c.label)),
              ))
          .toList(),
    );
  }

  String _promptFor(String label) {
    switch (label) {
      case 'Surprise me':
        return 'Surprise me with an interesting fact.';
      case 'Write a message':
        return 'Help me write a friendly message to congratulate a friend on their new job.';
      case 'Explain a concept':
        return 'Explain quantum entanglement in simple terms.';
      case 'Debug some code':
        return 'Here is some code that is buggy. Please review it: ';
      case 'Translate':
        return 'Translate the following text to Ukrainian: ';
      default:
        return label;
    }
  }
}

class _Chip {
  const _Chip({required this.icon, required this.label});
  final IconData icon;
  final String label;
}

class _ChipButton extends StatelessWidget {
  const _ChipButton({required this.chip, required this.onTap});
  final _Chip chip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(chip.icon, size: 16, color: Colors.black87),
              const SizedBox(width: 8),
              Text(
                chip.label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
