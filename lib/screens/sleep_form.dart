import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/sleep_session.dart';
import '../services/location_service.dart';

class SleepFormScreen extends StatefulWidget {
  const SleepFormScreen({super.key});

  @override
  State<SleepFormScreen> createState() => _SleepFormScreenState();
}

class _SleepFormScreenState extends State<SleepFormScreen> {
  DateTime start = DateTime.now().subtract(const Duration(hours: 8));
  DateTime end = DateTime.now();
  int comfort = 4;
  int noise = 2;
  String notes = '';
  bool tagLocation = true;

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('yyyy-MM-dd HH:mm');
    return Scaffold(
      appBar: AppBar(title: const Text('Log Sleep')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            title: const Text('Start'),
            subtitle: Text(df.format(start)),
            trailing: const Icon(Icons.edit_calendar),
            onTap: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: start,
                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                lastDate: DateTime.now(),
              );
              if (d == null) return;
              final t = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.fromDateTime(start),
              );
              if (t == null) return;
              setState(() =>
              start = DateTime(d.year, d.month, d.day, t.hour, t.minute));
            },
          ),
          ListTile(
            title: const Text('End'),
            subtitle: Text(df.format(end)),
            trailing: const Icon(Icons.edit_calendar),
            onTap: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: end,
                firstDate: start,
                lastDate: DateTime.now().add(const Duration(days: 1)),
              );
              if (d == null) return;
              final t = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.fromDateTime(end),
              );
              if (t == null) return;
              setState(() =>
              end = DateTime(d.year, d.month, d.day, t.hour, t.minute));
            },
          ),
          const SizedBox(height: 8),
          Text('Comfort: $comfort'),
          Slider(
            min: 1, max: 5, divisions: 4,
            value: comfort.toDouble(),
            onChanged: (v) => setState(() => comfort = v.round()),
          ),
          Text('Noise: $noise'),
          Slider(
            min: 1, max: 5, divisions: 4,
            value: noise.toDouble(),
            onChanged: (v) => setState(() => noise = v.round()),
          ),
          SwitchListTile(
            value: tagLocation,
            onChanged: (v) => setState(() => tagLocation = v),
            title: const Text('Tag location'),
            subtitle: const Text('Capture approximate GPS when saving'),
          ),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Notes',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            onChanged: (v) => notes = v,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              double? lat;
              double? lng;
              if (tagLocation) {
                final loc = await LocationService().getCoarseLatLng();
                lat = loc.lat;
                lng = loc.lng;
              }
              final s = SleepSession(
                id: 'ss_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(999)}',
                start: start,
                end: end,
                comfortRating: comfort,
                noiseLevel: noise,
                notes: notes,
                lat: lat, lng: lng,
              );
              if (!mounted) return;
              Navigator.pop(context, s);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
