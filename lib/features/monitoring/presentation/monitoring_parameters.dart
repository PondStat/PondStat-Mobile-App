import 'package:flutter/material.dart';

enum ParameterCategory {
  physical,
  chemical,
  biological,
  growth,
  custom,
}

extension ParameterCategoryExtension on ParameterCategory {
  Color resolveColor(BuildContext context) {

    switch (this) {
      case ParameterCategory.physical:
        return Colors.orange;
      case ParameterCategory.chemical:
        return Colors.blue;
      case ParameterCategory.biological:
        return Colors.green;
      case ParameterCategory.growth:
        return Colors.lightGreen;
      case ParameterCategory.custom:
        return Colors.blueGrey;
    }
  }

  Color get fallbackColor {
    switch (this) {
      case ParameterCategory.physical:
        return Colors.orange;
      case ParameterCategory.chemical:
        return Colors.blue;
      case ParameterCategory.biological:
        return Colors.green;
      case ParameterCategory.growth:
        return Colors.lightGreen;
      case ParameterCategory.custom:
        return Colors.blueGrey;
    }
  }
}

class ParameterItem {
  final String label;
  final String unit;
  final IconData icon;
  final ParameterCategory category;
  final TextInputType keyboardType;
  final double? absoluteMin;
  final double? absoluteMax;
  final double? optimalMin;
  final double? optimalMax;
  final String hint;
  final bool isSinglePoint;
  final String? createdBy;
  final String? warningMessage;

  const ParameterItem({
    required this.label,
    required this.unit,
    required this.icon,
    required this.category,
    this.keyboardType = const TextInputType.numberWithOptions(decimal: true),
    this.absoluteMin,
    this.absoluteMax,
    this.optimalMin,
    this.optimalMax,
    this.hint = '',
    this.isSinglePoint = false,
    this.createdBy,
    this.warningMessage,
  });

  Color getColor(BuildContext context) => category.resolveColor(context);
}

class MonitoringParameters {
  static List<ParameterItem> getDailyParameters(String species) {
    double? phOptMin, phOptMax, tempOptMin, tempOptMax, salOptMin, salOptMax, transOptMin, transOptMax;

    switch (species.toLowerCase()) {
      case 'shrimp':
        phOptMin = 7.5; phOptMax = 8.5;
        tempOptMin = 28.0; tempOptMax = 32.0;
        salOptMin = 10.0; salOptMax = 25.0;
        transOptMin = 30.0; transOptMax = 40.0;
        break;
      case 'tilapia':
      default:
        phOptMin = 6.5; phOptMax = 9.0;
        tempOptMin = 26.0; tempOptMax = 32.0;
        salOptMin = 5.0; salOptMax = 15.0; 
        transOptMin = 20.0; transOptMax = 40.0;
        break;
    }

    return [
      ParameterItem(
        label: 'pH Level',
        unit: '',
        icon: Icons.water_drop_rounded,
        category: ParameterCategory.chemical,
        absoluteMin: 0.0,
        absoluteMax: 14.0,
        optimalMin: phOptMin,
        optimalMax: phOptMax,
        hint: 'e.g., 7.2',
        warningMessage: 'pH levels outside the optimal range can stress the $species.',
      ),
      ParameterItem(
        label: 'Temperature',
        unit: '°C',
        icon: Icons.thermostat_rounded,
        category: ParameterCategory.physical,
        absoluteMin: 10.0,
        absoluteMax: 45.0,
        optimalMin: tempOptMin,
        optimalMax: tempOptMax,
        hint: 'e.g., 28.5',
        warningMessage: 'Temperature extremes can lead to disease or mortality.',
      ),
      ParameterItem(
        label: 'Salinity',
        unit: 'ppt',
        icon: Icons.grain_rounded,
        category: ParameterCategory.chemical,
        absoluteMin: 0.0,
        absoluteMax: 100.0,
        optimalMin: salOptMin,
        optimalMax: salOptMax,
        hint: 'e.g., 15',
        warningMessage: 'Salinity must be maintained for osmotic balance.',
      ),
      ParameterItem(
        label: 'Transparency',
        unit: 'cm',
        icon: Icons.visibility_rounded,
        category: ParameterCategory.physical,
        absoluteMin: 0.0,
        absoluteMax: 200.0,
        optimalMin: transOptMin,
        optimalMax: transOptMax,
        hint: 'e.g., 30',
        warningMessage: 'Low transparency indicates heavy blooms, high indicates poor primary productivity.',
      ),
    ];
  }

  static final List<ParameterItem> samplingParameters = [
    const ParameterItem(
      label: 'ABW',
      unit: 'g',
      icon: Icons.scale_rounded,
      category: ParameterCategory.growth,
      hint: 'Auto-calculated',
      isSinglePoint: true,
      absoluteMin: 0.0,
    ),
    const ParameterItem(
      label: 'ADG',
      unit: 'g/day',
      icon: Icons.trending_up_rounded,
      category: ParameterCategory.growth,
      hint: 'e.g., 0.5',
      isSinglePoint: true,
    ),
    const ParameterItem(
      label: 'DFR',
      unit: 'kg/day',
      icon: Icons.set_meal_rounded,
      category: ParameterCategory.growth,
      hint: 'e.g., 10',
      isSinglePoint: true,
      absoluteMin: 0.0,
    ),
    const ParameterItem(
      label: 'FCR',
      unit: '',
      icon: Icons.speed_rounded,
      category: ParameterCategory.growth,
      hint: 'e.g., 1.2',
      isSinglePoint: true,
      absoluteMin: 0.0,
    ),
  ];

  static final List<ParameterItem> weeklyParameters = [
    const ParameterItem(
      label: 'Phytoplankton',
      unit: 'cells/mL',
      icon: Icons.biotech_rounded,
      category: ParameterCategory.biological,
      hint: 'e.g., 10000',
      absoluteMin: 0.0,
    ),
    const ParameterItem(
      label: 'Bacterial Analysis',
      unit: 'Mixed',
      icon: Icons.biotech_rounded,
      category: ParameterCategory.biological,
      hint: 'Tabbed analysis',
      isSinglePoint: true,
    ),
  ];

  static final List<ParameterItem> biweeklyParameters = [
    const ParameterItem(
      label: 'Dissolved Oxygen',
      unit: 'mg/L',
      icon: Icons.air_rounded,
      category: ParameterCategory.chemical,
      absoluteMin: 0.0,
      absoluteMax: 20.0,
      optimalMin: 5.0,
      hint: 'e.g., 6.0',
      warningMessage: 'Low DO is highly lethal.',
    ),
    const ParameterItem(
      label: 'Ammonia',
      unit: 'mg/L',
      icon: Icons.science_rounded,
      category: ParameterCategory.chemical,
      absoluteMin: 0.0,
      optimalMax: 0.05,
      hint: 'e.g., 0.02',
      warningMessage: 'High ammonia levels are toxic.',
    ),
    const ParameterItem(
      label: 'Nitrite',
      unit: 'mg/L',
      icon: Icons.science_outlined,
      category: ParameterCategory.chemical,
      absoluteMin: 0.0,
      optimalMax: 0.1,
      hint: 'e.g., 0.05',
      warningMessage: 'Nitrite toxicity affects oxygen transport.',
    ),
    const ParameterItem(
      label: 'Nitrate',
      unit: 'mg/L',
      icon: Icons.biotech_rounded,
      category: ParameterCategory.chemical,
      absoluteMin: 0.0,
      hint: 'e.g., 10',
    ),
    const ParameterItem(
      label: 'Calcium',
      unit: 'mg/L',
      icon: Icons.apps_rounded,
      category: ParameterCategory.chemical,
      absoluteMin: 0.0,
      hint: 'e.g., 40',
    ),
    const ParameterItem(
      label: 'Magnesium',
      unit: 'mg/L',
      icon: Icons.apps_outage_rounded,
      category: ParameterCategory.chemical,
      absoluteMin: 0.0,
      hint: 'e.g., 120',
    ),
    const ParameterItem(
      label: 'Total Alkalinity',
      unit: 'mg/L',
      icon: Icons.waves_rounded,
      category: ParameterCategory.chemical,
      absoluteMin: 0.0,
      optimalMin: 100.0,
      hint: 'e.g., 120',
      warningMessage: 'Low alkalinity causes pH swings.',
    ),
    const ParameterItem(
      label: 'Carbon dioxide',
      unit: 'mg/L',
      icon: Icons.co2_rounded,
      category: ParameterCategory.chemical,
      absoluteMin: 0.0,
      hint: 'e.g., 15',
    ),
  ];

  static List<ParameterItem> getParametersByIndex(int index, String species) {
    switch (index) {
      case 0:
        return getDailyParameters(species);
      case 1:
        return weeklyParameters;
      case 2:
        return biweeklyParameters;
      default:
        return getDailyParameters(species);
    }
  }

  static ParameterItem? getParameterByLabel(String label, String species) {
    final allParams = [
      ...getDailyParameters(species),
      ...weeklyParameters,
      ...biweeklyParameters,
      ...samplingParameters,
    ];
    try {
      return allParams.firstWhere((p) => p.label == label);
    } catch (_) {
      return null;
    }
  }
}
