import 'package:sendme_rider/flutter_imports.dart';
import 'package:sendme_rider/flutter_project_imports.dart';
import 'package:cached_network_image/cached_network_image.dart';

class RiderProfileHeader extends StatelessWidget {
  final String riderName;
  final bool isAvailable;
  final bool isToggling;
  final VoidCallback onToggle;
  final String imageUrl;

  const RiderProfileHeader({
    super.key,
    required this.riderName,
    required this.isAvailable,
    this.isToggling = false,
    required this.onToggle,
    this.imageUrl = '',
  });

  Color get _statusColor =>
      isAvailable ? AppColors.doneStatusColor : Colors.red.shade400;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Profile image with availability border
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _statusColor, width: 2.5),
            ),
            child: CircleAvatar(
              radius: 24,
              backgroundColor: Colors.grey.shade100,
              child: imageUrl.isNotEmpty
                  ? ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: imageUrl,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        placeholder: (_, _) => _defaultAvatar(),
                        errorWidget: (_, _, _) => _defaultAvatar(),
                      ),
                    )
                  : _defaultAvatar(),
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
                    fontSize: 18,
                    color: AppColors.textColorBold,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isAvailable
                          ? (AppLocalizations.of(
                                  context,
                                )?.translate('available') ??
                                'Available')
                          : (AppLocalizations.of(
                                  context,
                                )?.translate('unavailable') ??
                                'Unavailable'),
                      style: TextStyle(
                        fontFamily: AssetsFont.textMedium,
                        fontSize: 13,
                        color: _statusColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: isToggling ? null : onToggle,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: isToggling
                  ? Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _statusColor,
                        ),
                      ),
                    )
                  : Icon(
                      Icons.power_settings_new,
                      color: _statusColor,
                      size: 22,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _defaultAvatar() {
    return Icon(Icons.person, size: 28, color: Colors.grey.shade400);
  }
}
