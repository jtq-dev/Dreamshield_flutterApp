import 'package:flutter/material.dart';
import '../services/onboarding_service.dart';

class OnboardingSheet extends StatefulWidget {
  const OnboardingSheet({super.key});

  @override
  State<OnboardingSheet> createState() => _OnboardingSheetState();
}

class _OnboardingSheetState extends State<OnboardingSheet> {
  final _page = PageController();
  int _i = 0;

  final _slides = const [
    _Slide(
      title: 'Welcome to DreamShield',
      text: 'Log your nights, mix calming soundscapes, and see your progress.',
      icon: Icons.nightlight_round,
    ),
    _Slide(
      title: 'Soundscape Studio',
      text: 'Pink/Brown/White noise mixer with presets. Works in the browser.',
      icon: Icons.graphic_eq,
    ),
    _Slide(
      title: 'Progress & Badges',
      text: 'Charts, streaks, and badges for consistent sleep.',
      icon: Icons.emoji_events,
    ),
  ];

  Future<void> _finish() async {
    await OnboardingService().setSeen();
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: cs.outlineVariant, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 250,
              child: PageView.builder(
                controller: _page,
                itemCount: _slides.length,
                onPageChanged: (v) => setState(() => _i = v),
                itemBuilder: (_, i) => _slides[i],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_slides.length, (j) {
                final active = j == _i;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: active ? 22 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: active ? cs.primary : cs.outlineVariant,
                    borderRadius: BorderRadius.circular(99),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    label: const Text('Skip'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      if (_i < _slides.length - 1) {
                        _page.nextPage(duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
                      } else {
                        _finish();
                      }
                    },
                    icon: Icon(_i < _slides.length - 1 ? Icons.arrow_forward : Icons.check),
                    label: Text(_i < _slides.length - 1 ? 'Next' : 'Let’s go'),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class _Slide extends StatelessWidget {
  final String title;
  final String text;
  final IconData icon;
  const _Slide({required this.title, required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 84, height: 84,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: [cs.primaryContainer, cs.secondaryContainer]),
            boxShadow: [BoxShadow(color: cs.primary.withOpacity(0.2), blurRadius: 20)],
          ),
          child: Icon(icon, size: 42, color: cs.onPrimaryContainer),
        ),
        const SizedBox(height: 16),
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(text, textAlign: TextAlign.center),
        ),
      ],
    );
  }
}
