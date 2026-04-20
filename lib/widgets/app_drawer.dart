import 'package:flutter/material.dart';

import '../models/chat_session.dart';
import '../screens/home_shell.dart';
import '../services/auth_service.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({
    super.key,
    required this.currentTab,
    required this.onSelectTab,
    required this.user,
    required this.sessions,
    required this.activeSessionId,
    required this.onSelectSession,
    required this.onNewSession,
    required this.onDeleteSession,
    required this.onTogglePin,
    required this.onSignOut,
  });

  final AppTab currentTab;
  final ValueChanged<AppTab> onSelectTab;
  final AppUser? user;
  final List<ChatSession> sessions;
  final String activeSessionId;
  final ValueChanged<String> onSelectSession;
  final VoidCallback onNewSession;
  final ValueChanged<String> onDeleteSession;
  final ValueChanged<String> onTogglePin;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(),
      child: SafeArea(
        child: Column(
          children: <Widget>[
            _UserHeader(user: user),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onNewSession,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('New chat'),
                ),
              ),
            ),
            _NavItem(
              icon: Icons.chat_bubble_outline_rounded,
              label: 'Chat',
              active: currentTab == AppTab.chat,
              onTap: () => onSelectTab(AppTab.chat),
            ),
            _NavItem(
              icon: Icons.image_outlined,
              label: 'Image',
              active: currentTab == AppTab.image,
              onTap: () => onSelectTab(AppTab.image),
            ),
            _NavItem(
              icon: Icons.menu_book_outlined,
              label: 'Learn',
              active: currentTab == AppTab.learn,
              onTap: () => onSelectTab(AppTab.learn),
            ),
            _NavItem(
              icon: Icons.graphic_eq_rounded,
              label: 'Voice',
              active: currentTab == AppTab.voice,
              onTap: () => onSelectTab(AppTab.voice),
            ),
            _NavItem(
              icon: Icons.code_rounded,
              label: 'Code',
              active: currentTab == AppTab.code,
              onTap: () => onSelectTab(AppTab.code),
            ),
            _NavItem(
              icon: Icons.widgets_outlined,
              label: 'Widgets',
              active: currentTab == AppTab.widgets,
              onTap: () => onSelectTab(AppTab.widgets),
            ),
            _NavItem(
              icon: Icons.settings_outlined,
              label: 'Settings',
              active: currentTab == AppTab.settings,
              onTap: () => onSelectTab(AppTab.settings),
            ),
            const Divider(height: 20),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 6),
              child: Row(
                children: const <Widget>[
                  Text(
                    'HISTORY',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: sessions.isEmpty
                  ? const _EmptyHistory()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      itemCount: sessions.length,
                      itemBuilder: (BuildContext _, int i) {
                        final ChatSession s = sessions[i];
                        return _HistoryTile(
                          session: s,
                          active: s.id == activeSessionId,
                          onTap: () => onSelectSession(s.id),
                          onDelete: () => onDeleteSession(s.id),
                          onTogglePin: () => onTogglePin(s.id),
                        );
                      },
                    ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.logout_rounded, size: 20),
              title: const Text(
                'Sign out',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              onTap: onSignOut,
            ),
          ],
        ),
      ),
    );
  }
}

class _UserHeader extends StatelessWidget {
  const _UserHeader({required this.user});
  final AppUser? user;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Row(
        children: <Widget>[
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFFE5E7EB),
            backgroundImage:
                (user?.photoUrl != null && user!.photoUrl!.isNotEmpty)
                    ? NetworkImage(user!.photoUrl!)
                    : null,
            child: (user?.photoUrl == null || user!.photoUrl!.isEmpty)
                ? const Icon(Icons.person, color: Colors.black54)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  user?.displayName ?? 'Guest',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user?.email ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: active ? Colors.black : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: <Widget>[
                Icon(
                  icon,
                  size: 20,
                  color: active ? Colors.white : Colors.black87,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: active ? Colors.white : Colors.black87,
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

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'No conversations yet.',
          style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
        ),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({
    required this.session,
    required this.active,
    required this.onTap,
    required this.onDelete,
    required this.onTogglePin,
  });
  final ChatSession session;
  final bool active;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onTogglePin;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: active ? const Color(0xFFF3F4F6) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: <Widget>[
                Icon(
                  session.pinned
                      ? Icons.push_pin
                      : Icons.chat_bubble_outline_rounded,
                  size: 16,
                  color: Colors.black87,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        session.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      if (session.preview.isNotEmpty)
                        Text(
                          session.preview,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'More',
                  icon: const Icon(Icons.more_vert, size: 16),
                  onSelected: (String v) {
                    if (v == 'pin') onTogglePin();
                    if (v == 'delete') onDelete();
                  },
                  itemBuilder: (BuildContext _) => <PopupMenuEntry<String>>[
                    PopupMenuItem<String>(
                      value: 'pin',
                      child:
                          Text(session.pinned ? 'Unpin' : 'Pin'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: Text('Delete'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
