import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/sleep_tip.dart';

class TipService {
  final String endpoint;
  TipService({this.endpoint = 'https://jsonplaceholder.typicode.com/posts?_limit=5'});

  Future<List<SleepTip>> fetchTips() async {
    try {
      final res = await http.get(Uri.parse(endpoint));
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        return data.map((e) => SleepTip(title: e['title'], body: e['body'])).toList();
      }
    } catch (_) {}
    // Fallback local tips (works offline)
    return [
      SleepTip(title: 'Consistent Bedtime', body: 'Aim to go to bed at the same time daily.'),
      SleepTip(title: 'Wind-down Routine', body: 'Reduce screens and bright light 30 minutes before bed.'),
      SleepTip(title: 'Ambient Noise', body: 'Try pink/brown noise to mask sudden sounds.'),
    ];
  }
}
