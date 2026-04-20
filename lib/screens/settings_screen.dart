import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/pinned_widget.dart';
import '../services/assistant_service.dart';
import '../services/widget_registry_service.dart';

/// User-facing control panel:
///   - Permissions (overlay, notifications).
///   - Default assistant role.
///   - The full list of pinned widgets, synced with the home screen rail and
///     the Android launcher widget.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AssistantService assistant = context.watch<AssistantService>();
    final WidgetRegistryService reg = context.watch<WidgetRegistryService>();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        const _SectionTitle('Assistant'),
        _Tile(
          icon: Icons.layers_outlined,
          title: 'Show prompt overlay',
          subtitle: 'Floating prompt bar over other apps.',
          trailing: FilledButton(
            onPressed: () async {
              final bool ok = await assistant.ensureOverlayPermission();
              if (!ok) return;
              await assistant.showPromptOverlay();
            },
            child: const Text('Open'),
          ),
        ),
        _Tile(
          icon: Icons.assistant_rounded,
          title: 'Set as default assistant',
          subtitle:
              'Pick OleksandrAi under "Digital assistant app" to launch it '
              'with a long-press on the home button.',
          trailing: OutlinedButton(
            onPressed: assistant.openDefaultAssistantSettings,
            child: const Text('Open settings'),
          ),
        ),
        _Tile(
          icon: Icons.picture_in_picture_alt_rounded,
          title: 'Display over other apps',
          subtitle: 'Required for the floating assistant bar.',
          trailing: OutlinedButton(
            onPressed: assistant.ensureOverlayPermission,
            child: const Text('Grant'),
          ),
        ),
        const SizedBox(height: 24),
        const _SectionTitle('Pinned widgets'),
        if (reg.isEmpty)
          const _EmptyCard()
        else
          ...reg.items.map(
            (PinnedWidget w) => _WidgetRow(
              widget: w,
              onRemove: () => reg.remove(w.id),
            ),
          ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: reg.isEmpty
                ? null
                : () async {
                    final bool ok = await reg.requestPinToHomeScreen();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          ok
                              ? 'Widget added to Android home screen.'
                              : 'Your launcher does not support pinning.',
                        ),
                      ),
                    );
                  },
            icon: const Icon(Icons.add_to_home_screen_rounded, size: 18),
            label: const Text('Add widget to Android home screen'),
          ),
        ),
        const SizedBox(height: 24),
        const _SectionTitle('About'),
        const _Tile(
          icon: Icons.info_outline_rounded,
          title: 'Version',
          subtitle: '1.0.0',
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);
  final String label;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 10),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          letterSpacing: 0.8,
          fontWeight: FontWeight.w700,
          color: Color(0xFF6B7280),
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: Colors.black87),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...<Widget>[
            const SizedBox(width: 8),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class _WidgetRow extends StatelessWidget {
  const _WidgetRow({required this.widget, required this.onRemove});
  final PinnedWidget widget;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
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
              size: 18,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                if (widget.subtitle.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      widget.subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            tooltip: 'Remove',
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: const Row(
        children: <Widget>[
          Icon(Icons.widgets_outlined, color: Colors.black54),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'No widgets pinned yet. Open the Widgets tab and tap the '
              'pin icon on any card.',
              style: TextStyle(fontSize: 13, color: Color(0xFF374151)),
            ),
          ),
        ],
      ),
    );
  }
}
