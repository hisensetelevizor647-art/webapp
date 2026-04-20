import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import '../models/pinned_widget.dart';
import 'storage_service.dart';

/// Single source of truth for "user-pinned widgets".
///
/// Everything that needs to show the pinned widgets (home rail, Settings
/// screen, Android launcher widget) listens to this service. Pinning or
/// unpinning anywhere updates all surfaces automatically.
class WidgetRegistryService extends ChangeNotifier {
  WidgetRegistryService({required StorageService storage})
      : _storage = storage {
    _items = _storage.loadPinnedWidgets();
    // Fire-and-forget mirror on first run so the launcher widget is not empty.
    _mirrorToHomeScreen();
  }

  static const String _widgetProvider = 'AiWidgetProvider';
  static const String _androidPackage = 'com.oleksandrai.app';

  final StorageService _storage;
  List<PinnedWidget> _items = <PinnedWidget>[];

  List<PinnedWidget> get items => List<PinnedWidget>.unmodifiable(_items);
  bool get isEmpty => _items.isEmpty;
  int get length => _items.length;

  Future<void> add(PinnedWidget w) async {
    if (_items.any((PinnedWidget e) => e.id == w.id)) return;
    _items = <PinnedWidget>[..._items, w];
    await _persist();
  }

  Future<void> remove(String id) async {
    _items = _items.where((PinnedWidget w) => w.id != id).toList();
    await _persist();
  }

  Future<void> toggle(PinnedWidget w) async {
    final bool exists = _items.any((PinnedWidget e) => e.id == w.id);
    if (exists) {
      await remove(w.id);
    } else {
      await add(w);
    }
  }

  bool contains(String id) => _items.any((PinnedWidget w) => w.id == id);

  /// Ask the launcher to place the AppWidget on the Android home screen.
  /// No-op on launchers that don't support programmatic pinning.
  Future<bool> requestPinToHomeScreen() async {
    try {
      await HomeWidget.requestPinWidget(
        name: _widgetProvider,
        androidName: _widgetProvider,
        qualifiedAndroidName: '$_androidPackage.$_widgetProvider',
      );
      return true;
    } catch (e) {
      debugPrint('[WidgetRegistry] pin request failed: $e');
      return false;
    }
  }

  Future<void> _persist() async {
    await _storage.savePinnedWidgets(_items);
    await _mirrorToHomeScreen();
    notifyListeners();
  }

  /// Push the current list into the platform's HomeWidget store so the
  /// AppWidgetProvider can render them.
  Future<void> _mirrorToHomeScreen() async {
    try {
      final List<Map<String, dynamic>> payload =
          _items.map((PinnedWidget w) => w.toJson()).toList();
      await HomeWidget.saveWidgetData<String>(
        'oa_pinned_count',
        _items.length.toString(),
      );
      await HomeWidget.saveWidgetData<String>(
        'oa_pinned_titles',
        payload
            .map((Map<String, dynamic> m) => (m['title'] as String? ?? '').trim())
            .where((String t) => t.isNotEmpty)
            .take(4)
            .join(' • '),
      );
      await HomeWidget.updateWidget(
        name: _widgetProvider,
        androidName: _widgetProvider,
        qualifiedAndroidName: '$_androidPackage.$_widgetProvider',
      );
    } catch (e) {
      debugPrint('[WidgetRegistry] mirror failed: $e');
    }
  }
}
