import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/status_pill.dart';

class _Helpline {
  const _Helpline({required this.icon, required this.label, required this.sub, required this.num});

  final IconData icon;
  final String label;
  final String sub;
  final String num;
}

const _helplines = [
  _Helpline(icon: Icons.shield_moon_outlined, label: 'Police', sub: 'Sindh emergency', num: '15'),
  _Helpline(icon: Icons.medical_services_outlined, label: 'Rescue 1122', sub: 'Fire and accident', num: '1122'),
  _Helpline(icon: Icons.emergency_outlined, label: 'Edhi Ambulance', sub: 'Nationwide', num: '115'),
  _Helpline(icon: Icons.emergency_outlined, label: 'Chhipa Ambulance', sub: 'Karachi and Sindh', num: '1020'),
  _Helpline(icon: Icons.volunteer_activism_outlined, label: 'Women and Child Helpline', sub: 'Government of Sindh', num: '1043'),
  _Helpline(icon: Icons.support_agent_rounded, label: 'Madadgar National', sub: 'Legal and counselling', num: '1098'),
];

class LocationScreen extends StatelessWidget {
  const LocationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 14, 12, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_rounded, size: 21, color: AppColors.text),
                  ),
                  const Text('Location', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, letterSpacing: -0.16)),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 26),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 16, 22, 0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        height: 250,
                        decoration: BoxDecoration(
                          color: const Color(0xFF20222F),
                          border: Border.all(color: AppColors.textMuted(0.09)),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CustomPaint(size: Size.infinite, painter: _GridPainter()),
                            Container(
                              width: 96,
                              height: 96,
                              decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.accentTint(0.14)),
                            ),
                            Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.accent,
                                border: Border.all(color: Colors.white, width: 3),
                                boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 3))],
                              ),
                            ),
                            Positioned(
                              left: 12,
                              bottom: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                                decoration: BoxDecoration(
                                  color: const Color(0xB3161826),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'MAP PLACEHOLDER',
                                  style: TextStyle(fontSize: 10, letterSpacing: 1, color: AppColors.textMuted(0.3)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Icon(Icons.location_on_outlined, size: 17, color: AppColors.accentLight),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Block 5, Gulshan-e-Iqbal', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                              Text('Karachi · accurate to 8 m · updated just now', style: TextStyle(fontSize: 11.5, color: AppColors.textMuted(0.45))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 18, 22, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => showNotBuiltSnack(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.accent,
                              side: const BorderSide(color: AppColors.accent),
                              minimumSize: const Size.fromHeight(48),
                            ),
                            icon: const Icon(Icons.share_rounded, size: 17),
                            label: const Text('Share live link', style: TextStyle(fontWeight: FontWeight.w500)),
                          ),
                        ),
                        const SizedBox(width: 9),
                        _SquareOutlineButton(icon: Icons.copy_rounded, onTap: () => showNotBuiltSnack(context)),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 6),
                    child: Text('HELPLINES · SINDH', style: TextStyle(fontSize: 9.5, letterSpacing: 1.1, color: AppColors.textMuted(0.35))),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    child: Column(
                      children: [
                        for (final h in _helplines)
                          InkWell(
                            onTap: () => showNotBuiltSnack(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 2),
                              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.textMuted(0.07)))),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(color: AppColors.textMuted(0.05), borderRadius: BorderRadius.circular(9)),
                                    child: Icon(h.icon, size: 17, color: AppColors.accentLight),
                                  ),
                                  const SizedBox(width: 13),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(h.label, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500)),
                                        Text(h.sub, style: TextStyle(fontSize: 11.5, color: AppColors.textMuted(0.45))),
                                      ],
                                    ),
                                  ),
                                  Text(h.num, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500, color: AppColors.accentLight)),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SquareOutlineButton extends StatelessWidget {
  const _SquareOutlineButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.textMuted(0.16))),
      child: IconButton(onPressed: onTap, icon: Icon(icon, size: 18, color: AppColors.text)),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF252735)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
