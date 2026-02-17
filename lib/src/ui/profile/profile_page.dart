import 'package:sendme_rider/flutter_imports.dart';
import 'package:sendme_rider/flutter_project_imports.dart';

class ProfilePage extends StatefulWidget {
  final RiderProfile rider;
  final ValueChanged<RiderProfile> onRiderUpdated;

  const ProfilePage({
    super.key,
    required this.rider,
    required this.onRiderUpdated,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late bool _isAvailable;
  bool _isTogglingAvailability = false;
  final _apiService = RiderApiService();

  @override
  void initState() {
    super.initState();
    _isAvailable = widget.rider.status == 0;
  }

  @override
  void didUpdateWidget(covariant ProfilePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rider.status != widget.rider.status) {
      _isAvailable = widget.rider.status == 0;
    }
  }

  Future<void> _toggleAvailability(bool value) async {
    final previousValue = _isAvailable;
    final newStatus = value ? 0 : 1;

    setState(() {
      _isAvailable = value;
      _isTogglingAvailability = true;
    });

    try {
      await _apiService.updateRiderAvailability(
        rider: widget.rider,
        status: newStatus,
      );
      final updatedRider = widget.rider.copyWith(status: newStatus);
      widget.onRiderUpdated(updatedRider);
    } catch (e) {
      if (mounted) {
        setState(() => _isAvailable = previousValue);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update availability: $e'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isTogglingAvailability = false);
      }
    }
  }

  Future<void> _logout() async {
    try {
      await PreferencesHelper.clearSession();
    } catch (_) {
      // Best effort — still navigate to login
    }
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final rider = widget.rider;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: AppColors.mainAppColor,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          children: [
            // Profile image
            CircleAvatar(
              radius: 50,
              backgroundColor: AppColors.mainAppColor.withValues(alpha: 0.1),
              backgroundImage: rider.imageUrl.isNotEmpty
                  ? NetworkImage(rider.imageUrl)
                  : null,
              child: rider.imageUrl.isEmpty
                  ? Icon(Icons.person, size: 50, color: AppColors.mainAppColor)
                  : null,
            ),
            const SizedBox(height: 16),

            // Name
            Text(
              rider.name,
              style: const TextStyle(
                fontFamily: AssetsFont.textBold,
                fontSize: 22,
              ),
            ),
            const SizedBox(height: 4),

            // Email
            Text(
              rider.email,
              style: TextStyle(
                fontFamily: AssetsFont.textRegular,
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),

            // Info card
            _buildInfoCard(rider),
            const SizedBox(height: 16),

            // Availability toggle
            _buildAvailabilityToggle(),
            const SizedBox(height: 32),

            // Logout button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text(
                  'Logout',
                  style: TextStyle(
                    fontFamily: AssetsFont.textMedium,
                    fontSize: 16,
                    color: Colors.red,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(RiderProfile rider) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _infoRow(Icons.phone, 'Contact', rider.contact),
            const Divider(height: 24),
            _infoRow(Icons.email_outlined, 'Email', rider.email),
            const Divider(height: 24),
            _infoRow(
              Icons.star,
              'Rating',
              rider.averageRatings.toStringAsFixed(1),
              iconColor: Colors.amber,
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(
    IconData icon,
    String label,
    String value, {
    Color? iconColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: iconColor ?? AppColors.mainAppColor),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            fontFamily: AssetsFont.textMedium,
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(
              fontFamily: AssetsFont.textMedium,
              fontSize: 14,
            ),
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildAvailabilityToggle() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              _isAvailable ? Icons.check_circle : Icons.cancel,
              color: _isAvailable ? Colors.green : Colors.red,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _isAvailable ? 'Available' : 'Unavailable',
                style: const TextStyle(
                  fontFamily: AssetsFont.textMedium,
                  fontSize: 15,
                ),
              ),
            ),
            if (_isTogglingAvailability)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Switch(
                value: _isAvailable,
                onChanged: _toggleAvailability,
                activeTrackColor: AppColors.mainAppColor.withValues(alpha: 0.5),
                activeThumbColor: AppColors.mainAppColor,
              ),
          ],
        ),
      ),
    );
  }
}
