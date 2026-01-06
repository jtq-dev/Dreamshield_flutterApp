import 'package:shared_preferences/shared_preferences.dart';

class OnboardingService {
  static const _key = 'onboarding_seen_v1';

  Future<bool> hasSeen() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_key) ?? false;
  }

  Future<void> setSeen() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_key, true);
  }
}
