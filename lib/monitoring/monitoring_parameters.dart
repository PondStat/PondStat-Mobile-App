import 'package:flutter/material.dart';

class ParameterItem {
  final String label;
  final String unit;
  final IconData icon;
  final Color color;
  final TextInputType keyboardType;
  final double? minVal;
  final double? maxVal;
  final String hint;
  final bool isSinglePoint;

  const ParameterItem({
    required this.label,
    required this.unit,
    required this.icon,
    required this.color,
    this.keyboardType = const TextInputType.numberWithOptions(decimal: true),
    this.minVal,
    this.maxVal,
    this.hint = '',
    this.isSinglePoint = false,
  });
}

class MonitoringParameters {
  static List<ParameterItem> getDailyParameters(String species) {
    double? phMin = 6.5;
    double? phMax = 8.5;
    double? tempMin = 25.0;
    double? tempMax = 32.0;
    double? salMin;
    double? salMax;
    double? transMin;
    double? transMax;

    if (species.toLowerCase() == 'shrimp') {
      phMin = 7.5;
      phMax = 8.5;
      tempMin = 28.0;
      tempMax = 30.0;
      salMin = 15.0;
      salMax = 30.0;
      transMin = 25.0;
      transMax = 40.0;
    } else if (species.toLowerCase() == 'tilapia') {
      phMin = 6.5;
      phMax = 9.0;
      tempMin = 25.0;
      tempMax = 32.0;
      salMin = 30.0;
      salMax = 35.0;
      transMin = 20.0;
      transMax = 60.0;
    }

    return [
      const ParameterItem(
        label: 'Feeding rate',
        unit: '%',
        icon: Icons.percent_rounded,
        color: Colors.brown,
        hint: 'e.g., 5',
        isSinglePoint: true,
      ),
      const ParameterItem(
        label: 'Total feed consumed',
        unit: 'kg',
        icon: Icons.set_meal_rounded,
        color: Colors.brown,
        hint: 'e.g., 10',
        isSinglePoint: true,
      ),
      const ParameterItem(
        label: 'Total weight gained',
        unit: 'kg',
        icon: Icons.monitor_weight_rounded,
        color: Colors.brown,
        hint: 'e.g., 2',
        isSinglePoint: true,
      ),
      ParameterItem(
        label: 'pH Level',
        unit: '',
        icon: Icons.water_drop_rounded,
        color: Colors.blue,
        minVal: phMin,
        maxVal: phMax,
        hint: 'e.g., 7.2',
      ),
      ParameterItem(
        label: 'Temperature',
        unit: '°C',
        icon: Icons.thermostat_rounded,
        color: Colors.orange,
        minVal: tempMin,
        maxVal: tempMax,
        hint: 'e.g., 28.5',
      ),
      ParameterItem(
        label: 'Salinity',
        unit: 'ppt',
        icon: Icons.grain_rounded,
        color: Colors.cyan,
        minVal: salMin,
        maxVal: salMax,
        hint: 'e.g., 15',
      ),
      ParameterItem(
        label: 'Transparency',
        unit: 'cm',
        icon: Icons.visibility_rounded,
        color: Colors.amber,
        minVal: transMin,
        maxVal: transMax,
        hint: 'e.g., 30',
      ),
    ];
  }

  static final List<ParameterItem> weeklyParameters = [
    const ParameterItem(
      label: 'Total weight of fish sampled',
      unit: 'g',
      icon: Icons.scale_rounded,
      color: Colors.lightGreen,
      hint: 'e.g., 500',
      isSinglePoint: true,
    ),
    const ParameterItem(
      label: 'Number of fish sampled',
      unit: 'pcs',
      icon: Icons.numbers_rounded,
      color: Colors.blueGrey,
      hint: 'e.g., 50',
      isSinglePoint: true,
      keyboardType: TextInputType.number,
    ),
    const ParameterItem(
      label: 'Phytoplankton',
      unit: 'cells/mL',
      icon: Icons.biotech_rounded,
      color: Colors.lightGreen,
      hint: 'e.g., 10000',
    ),
    const ParameterItem(
      label: 'Bacterial (yellow colonies)',
      unit: 'CFU/mL',
      icon: Icons.circle_rounded,
      color: Colors.amber,
      hint: 'e.g., 10^4',
    ),
    const ParameterItem(
      label: 'Bacterial (green colonies)',
      unit: 'CFU/mL',
      icon: Icons.circle_rounded,
      color: Colors.green,
      hint: 'e.g., 10^4',
    ),
  ];

  static final List<ParameterItem> biweeklyParameters = [
    const ParameterItem(
      label: 'Dissolved Oxygen',
      unit: 'mg/L',
      icon: Icons.air_rounded,
      color: Colors.cyan,
      minVal: 5.0,
      hint: 'e.g., 6.0',
    ),
    const ParameterItem(
      label: 'Ammonia',
      unit: 'mg/L',
      icon: Icons.science_rounded,
      color: Colors.purple,
      maxVal: 0.05,
      hint: 'e.g., 0.02',
    ),
    const ParameterItem(
      label: 'Nitrite',
      unit: 'mg/L',
      icon: Icons.science_outlined,
      color: Colors.indigo,
      maxVal: 0.1,
      hint: 'e.g., 0.05',
    ),
    const ParameterItem(
      label: 'Nitrate',
      unit: 'mg/L',
      icon: Icons.biotech_rounded,
      color: Colors.deepPurple,
      hint: 'e.g., 10',
    ),
    const ParameterItem(
      label: 'Calcium',
      unit: 'mg/L',
      icon: Icons.apps_rounded,
      color: Colors.blueGrey,
      hint: 'e.g., 40',
    ),
    const ParameterItem(
      label: 'Magnesium',
      unit: 'mg/L',
      icon: Icons.apps_outage_rounded,
      color: Colors.teal,
      hint: 'e.g., 120',
    ),
    const ParameterItem(
      label: 'Total Alkalinity',
      unit: 'mg/L',
      icon: Icons.waves_rounded,
      color: Colors.lightBlue,
      minVal: 100.0,
      hint: 'e.g., 120',
    ),
    const ParameterItem(
      label: 'Carbon dioxide',
      unit: 'mg/L',
      icon: Icons.co2_rounded,
      color: Colors.grey,
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
    ];
    try {
      return allParams.firstWhere((p) => p.label == label);
    } catch (_) {
      return null;
    }
  }
}
