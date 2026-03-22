import 'package:flutter/material.dart';

import '../../../shared/models/app_settings.dart';
import '../../../shared/theme/app_theme.dart';

class TimerSelectionSheet extends StatefulWidget {
  const TimerSelectionSheet({
    super.key,
    required this.initial,
    required this.hasPremiumAccess,
  });

  final AppTimerOption initial;
  final bool hasPremiumAccess;

  static Future<AppTimerOption?> show(
    BuildContext context,
    AppTimerOption initial, {
    required bool hasPremiumAccess,
  }) {
    return showModalBottomSheet<AppTimerOption>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TimerSelectionSheet(initial: initial, hasPremiumAccess: hasPremiumAccess),
    );
  }

  @override
  State<TimerSelectionSheet> createState() => _TimerSelectionSheetState();
}

class _TimerSelectionSheetState extends State<TimerSelectionSheet> {
  late AppTimerOption selected = widget.initial;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
        decoration: const BoxDecoration(
          color: Color(0xE6131313),
          borderRadius: BorderRadius.vertical(top: Radius.circular(42)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 52, height: 4, decoration: BoxDecoration(color: AppTheme.surfaceHighest, borderRadius: BorderRadius.circular(999))),
            const SizedBox(height: 22),
            Container(
              width: double.infinity,
              height: 188,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF3A3A3A), Color(0xFF131313)]),
              ),
              child: const Stack(
                children: [
                  Positioned(
                    bottom: 20,
                    left: 18,
                    child: Row(
                      children: [
                        Icon(Icons.verified_user_rounded, size: 16, color: AppTheme.primary),
                        SizedBox(width: 6),
                        Text('Encrypted Preview', style: TextStyle(fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('Set Self-Destruct Timer', style: TextStyle(fontFamily: 'Manrope', fontSize: 24, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              widget.hasPremiumAccess ? 'Choose when this capture evaporates from the vault.' : '7 day timers are available with Premium.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 2.25,
              physics: const NeverScrollableScrollPhysics(),
              children: AppTimerOption.captureOptions.map((option) {
                final isLocked = option.requiresPremium && !widget.hasPremiumAccess;
                final isSelected = option == selected;
                return InkWell(
                  onTap: () {
                    if (isLocked) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Unlock Premium to use the 7 day timer.')),
                      );
                      return;
                    }
                    setState(() => selected = option);
                  },
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.secondary : AppTheme.surfaceHigh,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: isSelected ? const [BoxShadow(color: Color(0x44E9C349), blurRadius: 16)] : const [],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            option.label,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                              color: isSelected ? const Color(0xFF3C2F00) : isLocked ? AppTheme.onSurfaceVariant : AppTheme.onSurface,
                            ),
                          ),
                        ),
                        if (isLocked) ...[
                          const SizedBox(width: 6),
                          Icon(Icons.lock_rounded, size: 16, color: isSelected ? const Color(0xFF3C2F00) : AppTheme.onSurfaceVariant),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: const Color(0xFF003061),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                onPressed: () => Navigator.of(context).pop(selected),
                child: const Text('Apply Timer', style: TextStyle(fontFamily: 'Manrope', fontWeight: FontWeight.w800, letterSpacing: 1)),
              ),
            ),
            const SizedBox(height: 12),
            const Text('Defaults to 24 hours if skipped.', style: TextStyle(fontSize: 10, letterSpacing: 2, color: AppTheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
