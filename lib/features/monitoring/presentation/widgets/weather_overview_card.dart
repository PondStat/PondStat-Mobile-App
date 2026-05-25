import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pondstat/features/dashboard/data/pond_repository.dart';
import 'package:pondstat/core/services/weather_service.dart';
import 'package:pondstat/core/utils/snackbar_helper.dart';

class WeatherOverviewCard extends ConsumerStatefulWidget {
  final String pondId;
  final String pondName;
  final double? latitude;
  final double? longitude;
  final bool canEdit;

  const WeatherOverviewCard({
    super.key,
    required this.pondId,
    required this.pondName,
    this.latitude,
    this.longitude,
    required this.canEdit,
  });

  @override
  ConsumerState<WeatherOverviewCard> createState() => _WeatherOverviewCardState();
}

class _WeatherOverviewCardState extends ConsumerState<WeatherOverviewCard> {
  bool _isLoadingWeather = false;
  List<DailyWeatherData> _weatherData = [];
  List<String> _alerts = [];
  String? _errorMessage;

  late final double _activeLat;
  late final double _activeLon;
  late final bool _isDefaultLocation;

  @override
  void initState() {
    super.initState();
    _resolveLocation();
    _loadWeather();
  }

  @override
  void didUpdateWidget(covariant WeatherOverviewCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.latitude != widget.latitude || oldWidget.longitude != widget.longitude) {
      _resolveLocation();
      _loadWeather();
    }
  }

  void _resolveLocation() {
    if (widget.latitude != null && widget.longitude != null) {
      _activeLat = widget.latitude!;
      _activeLon = widget.longitude!;
      _isDefaultLocation = false;
    } else {
      _activeLat = WeatherService.defaultLat;
      _activeLon = WeatherService.defaultLon;
      _isDefaultLocation = true;
    }
  }

  Future<void> _loadWeather() async {
    if (_isLoadingWeather) return;
    if (mounted) {
      setState(() {
        _isLoadingWeather = true;
        _errorMessage = null;
      });
    }

    try {
      final service = ref.read(weatherServiceProvider);
      final forecast = await service.fetchForecast(_activeLat, _activeLon);
      final alertsList = await service.checkWeatherAlerts(
        widget.pondId,
        widget.pondName,
        _activeLat,
        _activeLon,
      );

      if (mounted) {
        setState(() {
          _weatherData = forecast;
          _alerts = alertsList;
          _isLoadingWeather = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().contains('SocketException')
              ? 'No internet connection to load weather data.'
              : 'Failed to fetch weather forecast.';
          _isLoadingWeather = false;
        });
      }
    }
  }

  IconData _getWeatherIcon(int? code) {
    if (code == null) return Icons.wb_cloudy_rounded;
    if (code == 0) return Icons.wb_sunny_rounded;
    if (code >= 1 && code <= 3) return Icons.cloud_queue_rounded;
    if (code == 45 || code == 48) return Icons.cloud_rounded;
    if (code >= 51 && code <= 67) return Icons.grain_rounded;
    if (code >= 80 && code <= 82) return Icons.umbrella_rounded;
    if (code >= 95 && code <= 99) return Icons.thunderstorm_rounded;
    return Icons.cloud_queue_rounded;
  }

  String _getWeatherDescription(int? code) {
    if (code == null) return 'Cloudy';
    if (code == 0) return 'Sunny';
    if (code >= 1 && code <= 3) return 'Partly Cloudy';
    if (code == 45 || code == 48) return 'Foggy';
    if (code >= 51 && code <= 55) return 'Drizzle';
    if (code >= 61 && code <= 67) return 'Rainy';
    if (code >= 80 && code <= 82) return 'Rain Showers';
    if (code >= 95 && code <= 99) return 'Thunderstorm';
    return 'Cloudy';
  }

  void _showConfigureLocationDialog() {
    final latController = TextEditingController(
      text: widget.latitude?.toString() ?? '',
    );
    final lonController = TextEditingController(
      text: widget.longitude?.toString() ?? '',
    );

    final List<Map<String, dynamic>> presets = [
      {'name': 'Miagao, Iloilo (Default)', 'lat': WeatherService.defaultLat, 'lon': WeatherService.defaultLon},
      {'name': 'Manila, Philippines', 'lat': 14.5995, 'lon': 120.9842},
      {'name': 'Jakarta, Indonesia', 'lat': -6.2088, 'lon': 106.8456},
      {'name': 'Bangkok, Thailand', 'lat': 13.7563, 'lon': 100.5018},
    ];

    showDialog(
      context: context,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        final colorScheme = theme.colorScheme;

        return AlertDialog(
          backgroundColor: theme.scaffoldBackgroundColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text(
            'Configure Pond Location',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Select a preset zone or enter manual coordinates to receive customized local weather warnings and overlays.',
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  decoration: InputDecoration(
                    labelText: 'Location Preset',
                    prefixIcon: const Icon(Icons.map_rounded),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: List.generate(presets.length, (index) {
                    return DropdownMenuItem<int>(
                      value: index,
                      child: Text(
                        presets[index]['name'],
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    );
                  }),
                  onChanged: (idx) {
                    if (idx != null) {
                      latController.text = presets[idx]['lat'].toString();
                      lonController.text = presets[idx]['lon'].toString();
                    }
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: latController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                        decoration: InputDecoration(
                          labelText: 'Latitude',
                          prefixIcon: const Icon(Icons.explore_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (v) => v == null || double.tryParse(v) == null ? 'Invalid' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: lonController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                        decoration: InputDecoration(
                          labelText: 'Longitude',
                          prefixIcon: const Icon(Icons.explore_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (v) => v == null || double.tryParse(v) == null ? 'Invalid' : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                final lat = double.tryParse(latController.text.trim());
                final lon = double.tryParse(lonController.text.trim());

                if (lat == null || lon == null) {
                  SnackbarHelper.showError(context, 'Please input valid coordinate numbers.');
                  return;
                }

                Navigator.pop(dialogContext);
                _saveLocation(lat, lon);
              },
              child: const Text('Save Location', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveLocation(double lat, double lon) async {
    try {
      final repo = ref.read(pondRepositoryProvider);
      final pondDoc = await repo.pondsCollection.doc(widget.pondId).get();
      if (pondDoc.exists) {
        final existingPond = pondDoc.data()!;
        final updatedPond = existingPond.copyWith(
          latitude: lat,
          longitude: lon,
        );
        await repo.updatePond(updatedPond);
        if (mounted) {
          SnackbarHelper.showSuccess(context, 'Location coordinates saved successfully!');
        }
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'Failed to save location coordinates: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final locationText = _isDefaultLocation
        ? 'Miagao, Iloilo (Default)'
        : '${_activeLat.toStringAsFixed(4)}, ${_activeLon.toStringAsFixed(4)}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? colorScheme.surfaceContainer : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.1) : colorScheme.outlineVariant,
          ),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Location Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D9488).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.location_on_rounded,
                    color: Color(0xFF0D9488),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pond Location Weather',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        locationText,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.canEdit)
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: _showConfigureLocationDialog,
                    icon: const Icon(Icons.settings_rounded, size: 14, color: Color(0xFF0D9488)),
                    label: const Text(
                      'Configure',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0D9488),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Loading / Error / Content Area
            if (_isLoadingWeather)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else if (_errorMessage != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _errorMessage!,
                    style: TextStyle(color: colorScheme.error, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _loadWeather,
                    icon: const Icon(Icons.refresh_rounded, size: 14),
                    label: const Text('Retry', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              )
            else if (_weatherData.isNotEmpty) ...[
              // Grid metrics of weather
              Builder(
                builder: (context) {
                  final current = _weatherData.first;
                  final uvVal = current.uvIndex ?? 0.0;
                  final rainVal = current.rainfall ?? 0.0;
                  final tempVal = current.temperature ?? 0.0;
                  final weatherCode = current.weatherCode;

                  Widget buildMetric(IconData icon, Color iconColor, String title, String val, String unit) {
                    return Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.02) : colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(icon, color: iconColor, size: 14),
                                const SizedBox(width: 6),
                                Text(
                                  title,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: val,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                  TextSpan(
                                    text: ' $unit',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onSurfaceVariant,
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

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Weather Forecast Summary row
                      Row(
                        children: [
                          Icon(
                            _getWeatherIcon(weatherCode),
                            color: const Color(0xFFF59E0B),
                            size: 26,
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getWeatherDescription(weatherCode),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Daily Forecast for Today',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          buildMetric(
                            Icons.thermostat_rounded,
                            const Color(0xFFEF4444),
                            'Temperature',
                            tempVal.toStringAsFixed(1),
                            '°C',
                          ),
                          const SizedBox(width: 8),
                          buildMetric(
                            Icons.grain_rounded,
                            const Color(0xFF3B82F6),
                            'Rainfall',
                            rainVal.toStringAsFixed(1),
                            'mm',
                          ),
                          const SizedBox(width: 8),
                          buildMetric(
                            Icons.wb_sunny_rounded,
                            const Color(0xFFF59E0B),
                            'UV Index',
                            uvVal.toStringAsFixed(1),
                            '',
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),

              // Weather Warnings Banner if alerts active
              if (_alerts.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Active Weather Warning',
                            style: TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ..._alerts.map((alert) => Padding(
                            padding: const EdgeInsets.only(bottom: 4.0),
                            child: Text(
                              '• $alert',
                              style: TextStyle(
                                color: isDark ? Colors.orange.shade300 : Colors.orange.shade900,
                                fontSize: 11,
                                height: 1.3,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
