import '../models/sleep_session.dart';
import 'dart:math';

class Insights {
  final double avg;
  final double median;
  final double std;
  final double goal;
  final SleepSession? best;
  final SleepSession? worst;
  final double deficit; // negative means under goal
  final int nights;

  Insights({
    required this.avg,
    required this.median,
    required this.std,
    required this.goal,
    required this.best,
    required this.worst,
    required this.deficit,
    required this.nights,
  });

  List<String> advice() {
    final tips = <String>[];
    if (nights < 3) {
      tips.add('Log a few more nights for stronger insights.');
      return tips;
    }
    if (deficit < -0.5) {
      tips.add('You average ${(goal - avg).toStringAsFixed(1)}h below goal — try a 30-min earlier wind-down.');
    } else {
      tips.add('You’re meeting your goal — keep the routine consistent.');
    }
    if (std > 1.2) tips.add('Sleep varies a lot (σ=${std.toStringAsFixed(1)}h). Aim to keep bedtime within ±30 min.');
    if (best != null && worst != null && (best!.durationHours - worst!.durationHours) > 2) {
      tips.add('Big gap between best and worst nights — review what helped on your best night.');
    }
    return tips;
  }
}

class InsightsService {
  Insights compute(List<SleepSession> sessions, {double goal = 7.5, int days=7}) {
    if (sessions.isEmpty) {
      return Insights(avg: 0, median: 0, std: 0, goal: goal, best: null, worst: null, deficit: -goal, nights: 0);
    }
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final recent = sessions.where((s) => s.end.isAfter(cutoff)).toList();
    if (recent.isEmpty) {
      return Insights(avg: 0, median: 0, std: 0, goal: goal, best: null, worst: null, deficit: -goal, nights: 0);
    }
    recent.sort((a,b)=>a.durationHours.compareTo(b.durationHours));
    final vals = recent.map((s)=>s.durationHours).toList();
    final avg = vals.reduce((a,b)=>a+b)/vals.length;
    final median = vals.length.isOdd ? vals[vals.length~/2] : (vals[vals.length~/2-1]+vals[vals.length~/2])/2;
    final mu = avg;
    final variance = vals.map((v)=>pow(v-mu,2)).reduce((a,b)=>a+b)/vals.length;
    final std = sqrt(variance);
    final best = recent.last;
    final worst = recent.first;
    final deficit = avg - goal;
    return Insights(avg: avg, median: median, std: std, goal: goal, best: best, worst: worst, deficit: deficit, nights: recent.length);
  }
}
