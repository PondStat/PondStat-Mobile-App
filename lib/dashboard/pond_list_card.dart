import 'package:flutter/material.dart';
import '../monitoring/data_monitoring.dart';

class PondListCard extends StatelessWidget {
  final String pondId;
  final String pondName;
  final String species;
  final String userRole;

  const PondListCard({
    super.key,
    required this.pondId,
    required this.pondName,
    required this.species,
    required this.userRole,
  });

  void _navigateToMonitoring(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MonitoringPage(
          pondId: pondId,
          pondName: pondName,
          userRole: userRole,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200, width: 1.5),
      ),
      child: InkWell(
        onTap: () => _navigateToMonitoring(context),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                height: 52,
                width: 52,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.water_drop,
                  color: Colors.blue,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pondName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Species: $species',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildRoleBadge(),
                  const SizedBox(height: 8),
                  Icon(
                    Icons.chevron_right,
                    color: Colors.grey.shade400,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleBadge() {
    final isOwner = userRole.toLowerCase() == 'owner';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isOwner ? Colors.green.shade50 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isOwner ? Colors.green.shade200 : Colors.grey.shade300,
        ),
      ),
      child: Text(
        userRole.toUpperCase(),
        style: TextStyle(
          color: isOwner ? Colors.green.shade700 : Colors.grey.shade700,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}