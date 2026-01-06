// lib/services/backup_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;

// NOTE: You're running on web (Chrome), so this is fine.
// If you later target mobile, we can switch to conditional imports.
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import '../models/sleep_session.dart';

class BackupService {
  // ---------- Serialize / Deserialize ----------
  String toJsonString(List<SleepSession> sessions) {
    final list = sessions.map((s) => {
      'id': s.id,
      'start': s.start.toIso8601String(),
      'end': s.end.toIso8601String(),
      'comfort': s.comfortRating,
      'noise': s.noiseLevel,
      'lat': s.lat,
      'lng': s.lng,
      'notes': s.notes,
      'preset': s.preset,
    }).toList();
    return const JsonEncoder.withIndent('  ').convert(list);
  }

  List<SleepSession> fromJsonString(String jsonStr) {
    final list = (json.decode(jsonStr) as List).cast<Map<String, dynamic>>();
    return list
        .map((m) => SleepSession(
      id: m['id'] as String,
      start: DateTime.parse(m['start'] as String),
      end: DateTime.parse(m['end'] as String),
      comfortRating: (m['comfort'] as num?)?.toInt() ?? 3,
      noiseLevel: (m['noise'] as num?)?.toInt() ?? 3,
      lat: (m['lat'] as num?)?.toDouble(),
      lng: (m['lng'] as num?)?.toDouble(),
      notes: (m['notes'] as String?) ?? '',
      preset: m['preset'],
    ))
        .toList();
  }

  // ---------- Web download (save JSON file) ----------
  void downloadJsonWeb(String filename, String json) {
    if (!kIsWeb) return; // no-op on non-web
    final bytes = utf8.encode(json);
    final blob = html.Blob([bytes], 'application/json');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  // ---------- Web picker (load JSON file) ----------
  Future<String?> pickJsonWeb() async {
    if (!kIsWeb) return null;
    final input = html.FileUploadInputElement()..accept = '.json,application/json';
    final comp = Completer<String?>();
    input.onChange.listen((_) async {
      if (input.files == null || input.files!.isEmpty) {
        comp.complete(null);
        return;
      }
      final file = input.files!.first;
      final reader = html.FileReader()..readAsText(file);
      reader.onLoadEnd.listen((_) => comp.complete(reader.result as String));
    });
    input.click();
    return comp.future;
  }
}
