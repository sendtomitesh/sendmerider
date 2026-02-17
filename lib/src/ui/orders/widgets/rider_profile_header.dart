import 'package:sendme_rider/flutter_imports.dart';
import 'package:sendme_rider/flutter_project_imports.dart';

class RiderProfileHeader extends StatelessWidget {
  final String riderName;
  final bool isAvailable;
  final bool isToggling;
  final VoidCallback onToggle;

  const RiderProfileHeader({
    super.key,
    required this.riderName,
    required this.isAvailable,
    this.isToggling = false,
    required this.onToggle,
  });

  Color get _statusColor =>
      isAvailable ? AppColors.doneStatusColor : AppColors.mainAppColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: _statusColor,
            child: Text(
              riderName.isNotEmpty ? riderName[0].toUpperCase() : '?',
              style: const TextStyle(
                fontFamily: AssetsFont.textBold,
                fontSize: 20,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  riderName,
                  style: const TextStyle(
                    fontFamily: AssetsFont.textBold,
                    fontSize: 20,
                    color: AppColors.textColorBold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isAvailable ? 'Available' : 'Unavailable',
                  style: TextStyle(
                    fontFamily: AssetsFont.textMedium,
                    fontSize: 14,
                    color: _statusColor,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: isToggling ? null : onToggle,
            child: CircleAvatar(
              radius: 20,
              backgroundColor: _statusColor,
              child: isToggling
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(
                      Icons.power_settings_new,
                      color: Colors.white,
                      size: 22,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
