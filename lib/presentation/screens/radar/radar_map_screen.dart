import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../providers/weather_provider.dart';

/// Radar Map Screen — Live rain/wind overlay
class RadarMapScreen extends ConsumerStatefulWidget {
  const RadarMapScreen({super.key});

  @override
  ConsumerState<RadarMapScreen> createState() => _RadarMapScreenState();
}

class _RadarMapScreenState extends ConsumerState<RadarMapScreen> {
  final MapController _mapController = MapController();
  bool _showRadar = true;
  bool _showWind = false;
  double _radarOpacity = 0.6;

  @override
  Widget build(BuildContext context) {
    final locationAsync = ref.watch(currentLocationProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1117),
        elevation: 0,
        title: const Text(
          'Radar Map',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showRadar ? Icons.layers : Icons.layers_outlined,
              color: _showRadar ? const Color(0xFF4A90D9) : Colors.white54,
            ),
            onPressed: () => setState(() => _showRadar = !_showRadar),
          ),
        ],
      ),
      body: locationAsync.when(
        data: (location) {
          if (location == null) {
            return const Center(
              child: Text('Location unavailable', style: TextStyle(color: Colors.white54)),
            );
          }

          return Stack(
            children: [
              // Map
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: LatLng(location.lat, location.lon),
                  initialZoom: 8.0,
                  minZoom: 3.0,
                  maxZoom: 14.0,
                ),
                children: [
                  // Base map tiles (dark style)
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.aqistat.app',
                    tileBuilder: _darkMapTileBuilder,
                  ),
                  // Radar overlay (RainViewer)
                  if (_showRadar)
                    Opacity(
                      opacity: _radarOpacity,
                      child: TileLayer(
                        urlTemplate:
                            'https://tilecache.rainviewer.com/v2/radar/nowcast/{z}/{x}/{y}/256/6.png',
                        userAgentPackageName: 'com.aqistat.app',
                      ),
                    ),
                  // Location marker
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(location.lat, location.lon),
                        width: 20,
                        height: 20,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF4A90D9),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF4A90D9).withOpacity(0.4),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Controls overlay
              Positioned(
                bottom: 24,
                left: 16,
                right: 16,
                child: _MapControls(
                  showRadar: _showRadar,
                  showWind: _showWind,
                  opacity: _radarOpacity,
                  onRadarToggle: () => setState(() => _showRadar = !_showRadar),
                  onWindToggle: () => setState(() => _showWind = !_showWind),
                  onOpacityChanged: (v) => setState(() => _radarOpacity = v),
                ),
              ),

              // Legend
              Positioned(
                top: 16,
                right: 16,
                child: _RadarLegend(),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.white54)),
        error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.white54))),
      ),
    );
  }

  /// Apply dark mode styling to map tiles
  Widget _darkMapTileBuilder(BuildContext context, Widget tileWidget, TileImage tile) {
    return ColorFiltered(
      colorFilter: const ColorFilter.matrix([
        -0.2, -0.2, -0.2, 0, 40, // Red
        -0.2, -0.2, -0.2, 0, 40, // Green
        -0.2, -0.2, -0.2, 0, 40, // Blue
        0, 0, 0, 1, 0, // Alpha
      ]),
      child: tileWidget,
    );
  }
}

/// Map overlay controls
class _MapControls extends StatelessWidget {
  final bool showRadar;
  final bool showWind;
  final double opacity;
  final VoidCallback onRadarToggle;
  final VoidCallback onWindToggle;
  final ValueChanged<double> onOpacityChanged;

  const _MapControls({
    required this.showRadar,
    required this.showWind,
    required this.opacity,
    required this.onRadarToggle,
    required this.onWindToggle,
    required this.onOpacityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22).withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Layer toggles
          Row(
            children: [
              _LayerChip(
                label: 'Rain',
                icon: Icons.water_drop,
                active: showRadar,
                onTap: onRadarToggle,
              ),
              const SizedBox(width: 8),
              _LayerChip(
                label: 'Wind',
                icon: Icons.air,
                active: showWind,
                onTap: onWindToggle,
              ),
            ],
          ),
          if (showRadar) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  'Opacity',
                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                ),
                Expanded(
                  child: Slider(
                    value: opacity,
                    min: 0.2,
                    max: 1.0,
                    activeColor: const Color(0xFF4A90D9),
                    inactiveColor: Colors.white12,
                    onChanged: onOpacityChanged,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _LayerChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _LayerChip({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF4A90D9).withOpacity(0.2) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? const Color(0xFF4A90D9) : Colors.white.withOpacity(0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: active ? const Color(0xFF4A90D9) : Colors.white54),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: active ? const Color(0xFF4A90D9) : Colors.white54,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Radar color legend
class _RadarLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22).withOpacity(0.9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Rain Intensity',
            style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.5)),
          ),
          const SizedBox(height: 6),
          _LegendItem(color: const Color(0xFF00FF00), label: 'Light'),
          _LegendItem(color: const Color(0xFFFFFF00), label: 'Moderate'),
          _LegendItem(color: const Color(0xFFFF8C00), label: 'Heavy'),
          _LegendItem(color: const Color(0xFFFF0000), label: 'Extreme'),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 10, height: 10, color: color),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
        ],
      ),
    );
  }
}
