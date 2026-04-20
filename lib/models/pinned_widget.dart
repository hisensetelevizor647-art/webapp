/// A single "prompt widget" the user has pinned.
///
/// The same record is surfaced in three places:
///   1. The home screen rail inside the app.
///   2. The Settings screen, where it can be removed or pushed to the
///      Android launcher as a real AppWidget.
///   3. The Android home screen via the `home_widget` package.
class PinnedWidget {
  const PinnedWidget({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.prompt,
    required this.iconCode,
  });

  final String id;
  final String title;
  final String subtitle;
  final String prompt;

  /// Material icon codePoint, stored as int so it survives JSON round-trips.
  final int iconCode;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'title': title,
        'subtitle': subtitle,
        'prompt': prompt,
        'iconCode': iconCode,
      };

  factory PinnedWidget.fromJson(Map<String, dynamic> json) => PinnedWidget(
        id: json['id'] as String,
        title: (json['title'] ?? '') as String,
        subtitle: (json['subtitle'] ?? '') as String,
        prompt: (json['prompt'] ?? '') as String,
        iconCode:
            (json['iconCode'] as num?)?.toInt() ?? 0xe3ae /* widgets */,
      );

  PinnedWidget copyWith({
    String? title,
    String? subtitle,
    String? prompt,
    int? iconCode,
  }) =>
      PinnedWidget(
        id: id,
        title: title ?? this.title,
        subtitle: subtitle ?? this.subtitle,
        prompt: prompt ?? this.prompt,
        iconCode: iconCode ?? this.iconCode,
      );
}
