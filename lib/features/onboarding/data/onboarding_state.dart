import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _seenOnboardingKey = 'docscan.seenOnboarding';

/// Reads/writes the "user has finished the first-run onboarding" flag.
class OnboardingState {
  const OnboardingState(this._prefs);

  final SharedPreferences _prefs;

  bool get seen => _prefs.getBool(_seenOnboardingKey) ?? false;

  Future<void> markSeen() => _prefs.setBool(_seenOnboardingKey, true);
}

final onboardingStateProvider = FutureProvider<OnboardingState>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return OnboardingState(prefs);
});
