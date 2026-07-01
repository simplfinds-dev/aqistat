import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/weather_provider.dart';

class _Frame {
  final DateTime time;
  final String url;
  _Frame({required this.time, required this.url});
}

/// Animated precipitation radar using free OpenStreetMap/CARTO tiles and the
/// free RainViewer radar overlay (no API keys required).
class RadarScreen extends ConsumerStatefulWidget {
  const RadarScreen({super.key});
  @override
  ConsumerState<RadarScreen> createState() => _RadarScreenState();
}

class _RadarScreenState extends ConsumerState<RadarScreen> {
  final _mapController = MapController();
  List<_Frame> _frames = [];
  int _index = 0;
  bool _playing = true;
  bool _loading = true;
  String? _error;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadFrames();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }


  Future<void> _loadFrames() async {
    try {
      final res =
          await Dio().get('https://api.rainviewer.com/public/weather-maps.json');
      final data = res.data as Map<String, dynamic>;
      final host = data['host'] as String;
      final radar = data['radar'] as Map<String, dynamic>;
      final past = (radar['past'] as List?) ?? [];
      final nowcast = (radar['nowcast'] as List?) ?? [];
      final frames = [...past, ...nowcast].map((e) {
        final m = e as Map<String, dynamic>;
        return _Frame(
          time: DateTime.fromMillisecondsSinceEpoch((m['time'] as int) * 1000),
          url: '$host${m['path']}/256/{z}/{x}/{y}/2/1_1.png',
        );
      }).toList();
      if (!mounted) return;
      setState(() {
        _frames = frames;
        _index = past.isNotEmpty ? past.length - 1 : 0; // start at "now"
        _loading = false;
      });
      _startAnim();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load radar data. Check your connection and retry.';
      });
    }
  }

  void _startAnim() {
    _timer?.cancel();
    if (!_playing || _frames.isEmpty) return;
    _timer = Timer.periodic(const Duration(milliseconds: 650), (_) {
      if (!mounted) return;
      setState(() => _index = (_index + 1) % _frames.length);
    });
  }

  void _togglePlay() {
    setState(() => _playing = !_playing);
    _startAnim();
  }

  @override
  Widget build(BuildContext context) {
    final w = ref.watch(weatherBundleProvider).valueOrNull?.current;
    final center = (w != null && w.lat != 0)
        ? LatLng(w.lat, w.lon)
        : const LatLng(20.6, 78.9);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgDark,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textWhite),
        title: const Text('Rain Radar',
            style: TextStyle(
                color: AppColors.textWhite,
                fontSize: 18,
                fontWeight: FontWeight.w600)),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.accent))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(_error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.textGrey)),
                  ),
                )
              : Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                          initialCenter: center,
                          initialZoom: 6,
                          minZoom: 3,
                          maxZoom: 12),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.aqistat.app',
                        ),
                        if (_frames.isNotEmpty)
                          TileLayer(
                            key: ValueKey(_frames[_index].url),
                            urlTemplate: _frames[_index].url,
                            userAgentPackageName: 'com.aqistat.app',
                          ),
                        MarkerLayer(markers: [
                          Marker(
                            point: center,
                            width: 30,
                            height: 30,
                            child: const Icon(Icons.location_on,
                                color: AppColors.accent, size: 28),
                          ),
                        ]),
                      ],
                    ),
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 24,
                      child: _controls(),
                    ),
                    const Positioned(
                      right: 8,
                      bottom: 6,
                      child: Text('© OpenStreetMap · CARTO · RainViewer',
                          style: TextStyle(color: Colors.white38, fontSize: 9)),
                    ),
                  ],
                ),
    );
  }


  Widget _controls() {
    final frame = _frames.isNotEmpty ? _frames[_index] : null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardDark.withOpacity(0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _togglePlay,
            child: Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                  color: AppColors.accent, shape: BoxShape.circle),
              child: Icon(_playing ? Icons.pause : Icons.play_arrow,
                  color: Colors.black),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    frame == null
                        ? ''
                        : DateFormat('EEE, h:mm a').format(frame.time),
                    style: const TextStyle(
                        color: AppColors.textWhite,
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
                const SizedBox(height: 4),
                SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 3,
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 7),
                    overlayShape: SliderComponentShape.noOverlay,
                  ),
                  child: Slider(
                    value: _index
                        .toDouble()
                        .clamp(0, (_frames.length - 1).toDouble()),
                    min: 0,
                    max: (_frames.length - 1).clamp(1, 9999).toDouble(),
                    activeColor: AppColors.accent,
                    inactiveColor: AppColors.glassWhite,
                    onChanged: (v) {
                      _timer?.cancel();
                      setState(() {
                        _playing = false;
                        _index = v.round();
                      });
                    },
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
