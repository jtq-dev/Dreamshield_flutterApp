class SleepTip {
  final String title;
  final String body;

  SleepTip({required this.title, required this.body});

  factory SleepTip.fromJson(Map<String, dynamic> j) =>
      SleepTip(title: j['title'] ?? 'Tip', body: j['body'] ?? '');
}
