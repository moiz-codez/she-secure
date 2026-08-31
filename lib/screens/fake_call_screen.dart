import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/fake_call_provider.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';

class FakeCallScreen extends StatelessWidget {
  const FakeCallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final fc = context.watch<FakeCallProvider>();
    return Scaffold(
      body: switch (fc.phase) {
        FakeCallPhase.setup => const _SetupBody(),
        FakeCallPhase.waiting => const _WaitingBody(),
        FakeCallPhase.ringing => const _RingingBody(),
        FakeCallPhase.inCall => const _InCallBody(),
      },
    );
  }
}

class _SetupBody extends StatelessWidget {
  const _SetupBody();

  @override
  Widget build(BuildContext context) {
    final fc = context.watch<FakeCallProvider>();
    return SafeArea(
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
                const Text('Fake call', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, letterSpacing: -0.16)),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 26),
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(24, 18, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('A reason to walk away', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w500, letterSpacing: -0.46)),
                      SizedBox(height: 8),
                      Text(
                        'It rings and looks like any other call. Answer it out loud and leave.',
                        style: TextStyle(fontSize: 13.5, height: 1.6, color: Color.fromRGBO(233, 233, 237, 0.55)),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 26, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('CALLER NAME', style: TextStyle(fontSize: 9.5, letterSpacing: 1.1, color: AppColors.textMuted(0.35))),
                      const SizedBox(height: 11),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final name in FakeCallProvider.names)
                            _Chip(label: name, active: fc.callerName == name, onTap: () => fc.setCallerName(name)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const TextField(decoration: InputDecoration(hintText: 'Or type a name')),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 26, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('RING AFTER', style: TextStyle(fontSize: 9.5, letterSpacing: 1.1, color: AppColors.textMuted(0.35))),
                      const SizedBox(height: 11),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final d in FakeCallProvider.delaysSeconds)
                            _Chip(
                              label: d < 60 ? '$d s' : '1 min',
                              active: fc.delaySeconds == d,
                              onTap: () => fc.setDelay(d),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 34, 22, 0),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: fc.ringNow,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.accent,
                            side: const BorderSide(color: AppColors.accent),
                            minimumSize: const Size.fromHeight(50),
                          ),
                          child: const Text('Ring now', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: fc.scheduleCall,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.text,
                            side: BorderSide(color: AppColors.textMuted(0.16)),
                            minimumSize: const Size.fromHeight(50),
                          ),
                          child: const Text('Schedule the call', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
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
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.active, required this.onTap});

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(100),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: active ? AppColors.accent : AppColors.textMuted(0.14)),
          color: active ? AppColors.accentTint(0.12) : Colors.transparent,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: active ? FontWeight.w500 : FontWeight.w400,
            color: active ? AppColors.accentPale : AppColors.textMuted(0.7),
          ),
        ),
      ),
    );
  }
}

class _WaitingBody extends StatelessWidget {
  const _WaitingBody();

  @override
  Widget build(BuildContext context) {
    final fc = context.watch<FakeCallProvider>();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 34),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${fc.callerName.toUpperCase()} WILL CALL IN',
              style: TextStyle(fontSize: 11, letterSpacing: 1.5, color: AppColors.textMuted(0.4)),
            ),
            Text(
              '${fc.secondsLeft}',
              style: const TextStyle(fontSize: 108, height: 1, fontWeight: FontWeight.w500, letterSpacing: -5.4),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Put the phone away. It rings on its own.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13.5, color: AppColors.textMuted(0.5)),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: fc.endCall,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.text,
                  backgroundColor: AppColors.textMuted(0.07),
                  side: BorderSide(color: AppColors.textMuted(0.16)),
                  minimumSize: const Size.fromHeight(50),
                ),
                child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RingingBody extends StatelessWidget {
  const _RingingBody();

  @override
  Widget build(BuildContext context) {
    final fc = context.watch<FakeCallProvider>();
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF1F2129), Color(0xFF121319)]),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(26, 20, 26, 42),
          child: Column(
            children: [
              Text('Incoming call', style: TextStyle(fontSize: 13, color: AppColors.textMuted(0.55))),
              const SizedBox(height: 34),
              Container(
                width: 104,
                height: 104,
                decoration: BoxDecoration(
                  color: const Color(0xFF33364A),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.textMuted(0.1)),
                ),
                child: Icon(Icons.person_outline_rounded, size: 44, color: AppColors.textMuted(0.4)),
              ),
              const SizedBox(height: 22),
              Text(fc.callerName, style: const TextStyle(fontSize: 30, letterSpacing: -0.3)),
              const SizedBox(height: 7),
              Text('Mobile · Pakistan', style: TextStyle(fontSize: 14, color: AppColors.textMuted(0.5))),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _CallAction(icon: Icons.call_end_rounded, color: AppColors.danger, label: 'Decline', onTap: fc.endCall),
                  _CallAction(icon: Icons.call_rounded, color: AppColors.callAccept, label: 'Answer', onTap: fc.answer),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CallAction extends StatelessWidget {
  const _CallAction({required this.icon, required this.color, required this.label, required this.onTap});

  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 24, offset: const Offset(0, 8))],
            ),
            child: Icon(icon, color: Colors.white, size: 27),
          ),
        ),
        const SizedBox(height: 10),
        Text(label, style: TextStyle(fontSize: 12, color: AppColors.textMuted(0.5))),
      ],
    );
  }
}

class _InCallBody extends StatelessWidget {
  const _InCallBody();

  @override
  Widget build(BuildContext context) {
    final fc = context.watch<FakeCallProvider>();
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF1F2129), Color(0xFF121319)]),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(26, 20, 26, 42),
          child: Column(
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: const Color(0xFF33364A),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.textMuted(0.1)),
                ),
                child: Icon(Icons.person_outline_rounded, size: 38, color: AppColors.textMuted(0.4)),
              ),
              const SizedBox(height: 20),
              Text(fc.callerName, style: const TextStyle(fontSize: 27, letterSpacing: -0.27)),
              const SizedBox(height: 7),
              Text(formatMmSs(fc.callSeconds), style: TextStyle(fontSize: 14, color: AppColors.textMuted(0.5))),
              const SizedBox(height: 44),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _InCallIcon(icon: Icons.mic_off_rounded, label: 'Mute'),
                  _InCallIcon(icon: Icons.grid_view_rounded, label: 'Keypad'),
                  _InCallIcon(icon: Icons.volume_up_rounded, label: 'Speaker'),
                ],
              ),
              const Spacer(),
              InkWell(
                customBorder: const CircleBorder(),
                onTap: fc.endCall,
                child: Container(
                  width: 66,
                  height: 66,
                  decoration: BoxDecoration(
                    color: AppColors.danger,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: AppColors.danger.withValues(alpha: 0.35), blurRadius: 24, offset: const Offset(0, 8))],
                  ),
                  child: const Icon(Icons.call_end_rounded, color: Colors.white, size: 27),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InCallIcon extends StatelessWidget {
  const _InCallIcon({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(color: AppColors.textMuted(0.08), shape: BoxShape.circle),
          child: Icon(icon, size: 22, color: AppColors.textMuted(0.75)),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(fontSize: 11, color: AppColors.textMuted(0.45))),
      ],
    );
  }
}
