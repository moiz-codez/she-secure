import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/location_service.dart';
import '../theme/app_colors.dart';

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

/// Raw OpenStreetMap raster tiles, no key/commercial provider — a locked-in
/// decision (dev/light-use only; see CLAUDE.md's map caveat).
final _osmStyle = jsonEncode({
  'version': 8,
  'sources': {
    'osm': {
      'type': 'raster',
      'tiles': ['https://tile.openstreetmap.org/{z}/{x}/{y}.png'],
      'tileSize': 256,
      'attribution': '© OpenStreetMap contributors',
    },
  },
  'layers': [
    {'id': 'osm-layer', 'type': 'raster', 'source': 'osm'},
  ],
});

Future<void> _callNumber(String num) => launchUrl(Uri(scheme: 'tel', path: num));

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  MapLibreMapController? _map;
  double? _lat;
  double? _lng;
  double? _accuracy;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final position = await LocationService.getCurrentPosition();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _lat = position?.latitude;
      _lng = position?.longitude;
      _accuracy = position?.accuracy;
    });
    if (position != null) {
      _map?.animateCamera(CameraUpdate.newLatLng(LatLng(position.latitude, position.longitude)));
    }
  }

  /// Same Google Maps link format the SOS SMS already uses — a snapshot of
  /// where the fix was when shared/copied, not a hosted continuously
  /// updating page (this app has no such backend).
  String? get _mapsLink => _lat == null ? null : 'https://maps.google.com/?q=$_lat,$_lng';

  Future<void> _copyLink(BuildContext context) async {
    final link = _mapsLink;
    if (link == null) return;
    await Clipboard.setData(ClipboardData(text: link));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Link copied.')));
  }

  Future<void> _shareLink(BuildContext context) async {
    final link = _mapsLink;
    if (link == null) return;
    await SharePlus.instance.share(ShareParams(text: link, subject: 'My location'));
  }

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
                            MapLibreMap(
                              styleString: _osmStyle,
                              initialCameraPosition: CameraPosition(
                                target: LatLng(_lat ?? 24.8607, _lng ?? 67.0011), // Karachi fallback
                                zoom: 15,
                              ),
                              onMapCreated: (c) => _map = c,
                              myLocationEnabled: false,
                              compassEnabled: false,
                              rotateGesturesEnabled: false,
                            ),
                            if (!_loading)
                              const _PulsingMarker()
                            else
                              const CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent),
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
                              Text(
                                _lat == null ? 'Location unavailable' : '${_lat!.toStringAsFixed(5)}, ${_lng!.toStringAsFixed(5)}',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                              ),
                              Text(
                                _accuracy == null
                                    ? 'Turn on location permission to share where you are'
                                    : 'accurate to ${_accuracy!.round()} m · updated just now',
                                style: TextStyle(fontSize: 11.5, color: AppColors.textMuted(0.45)),
                              ),
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
                            onPressed: () => _shareLink(context),
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
                        _SquareOutlineButton(icon: Icons.copy_rounded, onTap: () => _copyLink(context)),
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
                            onTap: () => _callNumber(h.num),
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

/// Sits fixed at the map's center — since the camera is always recentred on
/// the live fix, this is equivalent to a marker pinned to that coordinate.
class _PulsingMarker extends StatefulWidget {
  const _PulsingMarker();

  @override
  State<_PulsingMarker> createState() => _PulsingMarkerState();
}

class _PulsingMarkerState extends State<_PulsingMarker> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          return Stack(
            alignment: Alignment.center,
            children: [
              Opacity(
                opacity: (1 - t).clamp(0, 1),
                child: Container(
                  width: 24 + 72 * t,
                  height: 24 + 72 * t,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.accentTint(0.28)),
                ),
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
            ],
          );
        },
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
