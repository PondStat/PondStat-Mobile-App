import 'package:flutter/material.dart';

class ParameterItem {
  final String label;
  final IconData icon;
  final Color color;
  final String unit;
  final TextInputType keyboardType;
  final double? minVal;
  final double? maxVal;
  final String hint;

  const ParameterItem({
    required this.label,
    required this.icon,
    required this.color,
    required this.unit,
    required this.keyboardType,
    this.minVal,
    this.maxVal,
    this.hint = '',
  });
}

class MonitoringParameters {
  static const Color physicalColor = Colors.blue;
  static const Color chemicalColor = Colors.deepOrange;
  static const Color biologicalColor = Colors.green;

  static const List<ParameterItem> daily = [
    ParameterItem(
      label: 'Water Temp',
      icon: Icons.thermostat_outlined,
      color: physicalColor,
      unit: '°C',
      keyboardType: TextInputType.numberWithOptions(decimal: true),
      minVal: 15,
      maxVal: 40,
      hint: 'e.g., 28.5',
    ),
    ParameterItem(
      label: 'Air Temp',
      icon: Icons.air_outlined,
      color: physicalColor,
      unit: '°C',
      keyboardType: TextInputType.numberWithOptions(decimal: true),
      minVal: 10,
      maxVal: 50,
      hint: 'e.g., 30.0',
    ),
    ParameterItem(
      label: 'pH Level',
      icon: Icons.science_outlined,
      color: chemicalColor,
      unit: '',
      keyboardType: TextInputType.numberWithOptions(decimal: true),
      minVal: 0,
      maxVal: 14,
      hint: 'e.g., 7.5',
    ),
    ParameterItem(
      label: 'Salinity',
      icon: Icons.waves_outlined,
      color: physicalColor,
      unit: 'ppt',
      keyboardType: TextInputType.numberWithOptions(decimal: true),
      minVal: 0,
      maxVal: 50,
      hint: 'e.g., 15',
    ),
    ParameterItem(
      label: 'Feeding Time',
      icon: Icons.local_dining_outlined,
      color: biologicalColor,
      unit: 'kg',
      keyboardType: TextInputType.numberWithOptions(decimal: true),
      minVal: 0,
      hint: 'Total feed given',
    ),
  ];

  static const List<ParameterItem> weekly = [
    ParameterItem(
      label: 'Microbe Count',
      icon: Icons.coronavirus_outlined,
      color: biologicalColor,
      unit: 'cells/ml',
      keyboardType: TextInputType.number,
      minVal: 0,
      hint: 'e.g., 10000',
    ),
    ParameterItem(
      label: 'Phytoplankton',
      icon: Icons.eco_outlined,
      color: biologicalColor,
      unit: 'cells/ml',
      keyboardType: TextInputType.number,
      minVal: 0,
    ),
    ParameterItem(
      label: 'Zooplankton',
      icon: Icons.bug_report_outlined,
      color: biologicalColor,
      unit: 'ind/L',
      keyboardType: TextInputType.number,
      minVal: 0,
    ),
    ParameterItem(
      label: 'Avg Body Weight',
      icon: Icons.scale_outlined,
      color: biologicalColor,
      unit: 'g',
      keyboardType: TextInputType.numberWithOptions(decimal: true),
      minVal: 0,
      maxVal: 2000,
      hint: 'e.g., 15.2',
    ),
  ];

  static const List<ParameterItem> biweekly = [
    ParameterItem(
      label: 'Dissolved O2',
      icon: Icons.bubble_chart_outlined,
      color: chemicalColor,
      unit: 'mg/L',
      keyboardType: TextInputType.numberWithOptions(decimal: true),
      minVal: 0,
      maxVal: 20,
      hint: 'e.g., 5.5',
    ),
    ParameterItem(
      label: 'Ammonia',
      icon: Icons.warning_amber_outlined,
      color: chemicalColor,
      unit: 'ppm',
      keyboardType: TextInputType.numberWithOptions(decimal: true),
      minVal: 0,
      maxVal: 10,
      hint: 'e.g., 0.2',
    ),
    ParameterItem(
      label: 'Nitrate',
      icon: Icons.water_drop_outlined,
      color: chemicalColor,
      unit: 'ppm',
      keyboardType: TextInputType.numberWithOptions(decimal: true),
      minVal: 0,
      maxVal: 100,
    ),
    ParameterItem(
      label: 'Nitrite',
      icon: Icons.opacity_outlined,
      color: chemicalColor,
      unit: 'ppm',
      keyboardType: TextInputType.numberWithOptions(decimal: true),
      minVal: 0,
      maxVal: 20,
    ),
    ParameterItem(
      label: 'Alkalinity',
      icon: Icons.balance_outlined,
      color: chemicalColor,
      unit: 'ppm',
      keyboardType: TextInputType.numberWithOptions(decimal: true),
      minVal: 0,
      maxVal: 500,
    ),
    ParameterItem(
      label: 'Phosphate',
      icon: Icons.data_usage_outlined,
      color: chemicalColor,
      unit: 'ppm',
      keyboardType: TextInputType.numberWithOptions(decimal: true),
      minVal: 0,
      maxVal: 10,
    ),
    ParameterItem(
      label: 'Ca-Mg Ratio',
      icon: Icons.join_inner_outlined,
      color: chemicalColor,
      unit: 'ratio',
      keyboardType: TextInputType.text,
      hint: 'e.g., 1:3',
    ),
  ];

  static List<ParameterItem> getParametersByIndex(int index) {
    switch (index) {
      case 0:
        return daily;
      case 1:
        return weekly;
      case 2:
        return biweekly;
      default:
        return [];
    }
  }

  static String getTabTitle(int index) {
    switch (index) {
      case 0:
        return "Daily Monitoring";
      case 1:
        return "Weekly Analysis";
      case 2:
        return "Biweekly Report";
      default:
        return "";
    }
  }
}