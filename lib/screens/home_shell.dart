import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/pinned_widget.dart';
import '../services/ai_service.dart';
import '../services/assistant_service.dart';
import '../services/auth_service.dart';
import '../services/widget_registry_service.dart';
import '../widgets/app_drawer.dart';
import 'chat_screen.dart';
import 'code_screen.dart';
import 'image_screen.dart';
import 'learn_screen.dart';
import 'settings_screen.dart';
import 'voice_screen.dart';
import 'widgets_screen.dart';

/// Tab identifiers mirroring the web app's primary modes.
enum AppTab { chat, image, learn, voice, code, widgets, settings }

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  AppTab _tab = AppTab.chat;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _selectTab(AppTab t) {
    setState(() => _tab = t);
    Navigator.of(context).maybePop(); // closes drawer
  }

  Widget _bodyFor(AppTab t) {
    switch (t) {
      case AppTab.chat:
        return const _ChatHome();
      case AppTab.image:
        return const ImageScreen();
      case AppTab.learn:
        return const LearnScreen();
      case AppTab.voice:
        return const VoiceScreen();
      case AppTab.code:
        return const CodeScreen();
      case AppTab.widgets:
        return const WidgetsScreen();
      case AppTab.settings:
        return const SettingsScreen();
    }
  }

  String _titleFor(AppTab t) {
    switch (t) {
      case AppTab.chat:
        return 'OleksandrAi';
      case AppTab.image:
        return 'Image Studio';
      case AppTab.learn:
        return 'Learn';
      case AppTab.voice:
        return 'Voice';
      case AppTab.code:
        return 'Code Studio';
      case AppTab.widgets:
        return 'Widgets';
      case AppTab.settings:
        return 'Settings';
    }
  }

  @override
  Widget build(BuildContext context) {
    final AuthService auth = context.watch<AuthService>();
    final AiService ai = context.watch<AiService>();

    return Scaffold(
      key: _scaffoldKey,
      drawer: AppDrawer(
        currentTab: _tab,
        onSelectTab: _selectTab,
        user: auth.user,
        sessions: ai.sessions,
        activeSessionId: ai.activeSession.id,
        onSelectSession: (String id) {
          ai.selectSession(id);
          setState(() => _tab = AppTab.chat);
          Navigator.of(context).maybePop();
        },
        onNewSession: () {
          ai.newSession();
          setState(() => _tab = AppTab.chat);
          Navigator.of(context).maybePop();
        },
        onDeleteSession: ai.deleteSession,
        onTogglePin: ai.togglePin,
        onSignOut: () async {
          await auth.signOut();
        },
      ),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: Text(_titleFor(_tab)),
        actions: <Widget>[
          if (_tab == AppTab.chat)
            IconButton(
              icon: const Icon(Icons.layers_outlined),
              tooltip: 'Show assistant overlay',
              onPressed: () async {
                final AssistantService a = context.read<AssistantService>();
                await a.showPromptOverlay();
              },
            ),
          if (_tab == AppTab.chat)
            IconButton(
              icon: const Icon(Icons.add_rounded),
              tooltip: 'New chat',
              onPressed: ai.newSession,
            ),
          IconButton(
            icon: _Avatar(auth.user?.photoUrl),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(child: _bodyFor(_tab)),
    );
  }
}

/// Chat home: the pinned widgets rail on top, then the chat UI.
class _ChatHome extends StatelessWidget {
  const _ChatHome();

  @override
  Widget build(BuildContext context) {
    final WidgetRegistryService reg =
        context.watch<WidgetRegistryService>();

    return Column(
      children: <Widget>[
        if (reg.isEmpty) const SizedBox.shrink() else _PinnedRail(reg: reg),
        const Expanded(child: ChatScreen()),
      ],
    );
  }
}

class _PinnedRail extends StatelessWidget {
  const _PinnedRail({required this.reg});
  final WidgetRegistryService reg;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 92,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFF1F5F9)),
        ),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: reg.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (BuildContext _, int i) {
          final PinnedWidget w = reg.items[i];
          return _RailChip(widget: w);
        },
      ),
    );
  }
}

class _RailChip extends StatelessWidget {
  const _RailChip({required this.widget});
  final PinnedWidget widget;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () async {
            final AiService ai = context.read<AiService>();
            await ai.sendUserMessage(widget.prompt);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Ran "${widget.title}".')),
              );
            }
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(
                  IconData(widget.iconCode, fontFamily: 'MaterialIcons'),
                  size: 22,
                  color: Colors.black,
                ),
                const SizedBox(height: 6),
                Text(
                  widget.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar(this.url);
  final String? url;

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return const CircleAvatar(
        radius: 14,
        backgroundColor: Color(0xFFE5E7EB),
        child: Icon(Icons.person, size: 18, color: Colors.black54),
      );
    }
    return CircleAvatar(
      radius: 14,
      backgroundImage: NetworkImage(url!),
      backgroundColor: const Color(0xFFE5E7EB),
    );
  }
}
