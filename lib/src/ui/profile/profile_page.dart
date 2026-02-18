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
  RiderProfile? _rider;
  late bool _isAvailable;
  bool _isTogglingAvailability = false;
  bool _isLoading = true;
  final _apiService = RiderApiService();

  @override
  void initState() {
    super.initState();
    _isAvailable = widget.rider.status == 0;
    _loadProfile();
  }

  @override
  void didUpdateWidget(covariant ProfilePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rider.id != widget.rider.id) {
      _loadProfile();
    }
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final saved = await PreferencesHelper.getSavedRider();
      if (saved == null || (saved.mobile ?? '').isEmpty) {
        if (mounted)
          setState(() {
            _rider = widget.rider;
            _isLoading = false;
          });
        return;
      }
      final fresh = await _apiService.fetchRiderProfile(mobile: saved.mobile!);
      if (!mounted) return;
      final r = fresh.copyWith(
        name: fresh.name.isNotEmpty ? fresh.name : widget.rider.name,
      );
      setState(() {
        _rider = r;
        _isAvailable = r.status == 0;
        _isLoading = false;
      });
      widget.onRiderUpdated(r);
    } catch (_) {
      if (mounted)
        setState(() {
          _rider = widget.rider;
          _isLoading = false;
        });
    }
  }

  Future<void> _toggleAvailability() async {
    if (_rider == null || _isTogglingAvailability) return;
    final newStatus = _isAvailable
        ? 1
        : 0; // toggle: 0=available, 1=unavailable
    setState(() => _isTogglingAvailability = true);
    try {
      await _apiService.updateRiderAvailability(
        rider: _rider!,
        status: newStatus,
      );
      if (!mounted) return;
      final updated = _rider!.copyWith(status: newStatus);
      setState(() {
        _rider = updated;
        _isAvailable = !_isAvailable;
        _isTogglingAvailability = false;
      });
      widget.onRiderUpdated(updated);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isTogglingAvailability = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update availability')));
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Logout',
          style: TextStyle(fontFamily: AssetsFont.textBold, fontSize: 18),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: TextStyle(fontFamily: AssetsFont.textRegular, fontSize: 14),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontFamily: AssetsFont.textMedium,
                color: Colors.grey,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Logout',
              style: TextStyle(
                fontFamily: AssetsFont.textMedium,
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    await PreferencesHelper.clearSession();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)?.translate('profile') ?? 'Profile',
          style: const TextStyle(fontFamily: AssetsFont.textBold, fontSize: 20),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _isLoading ? _buildSkeleton() : _buildContent(),
    );
  }

  Widget _buildSkeleton() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Avatar skeleton
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(height: 16),
          // Name skeleton
          Container(
            width: 150,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 8),
          // Email skeleton
          Container(
            width: 200,
            height: 14,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 30),
          // Info card skeleton
          Container(
            width: double.infinity,
            height: 160,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          const SizedBox(height: 20),
          // Toggle skeleton
          Container(
            width: double.infinity,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          const SizedBox(height: 20),
          // Logout skeleton
          Container(
            width: double.infinity,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final rider = _rider ?? widget.rider;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Avatar
          CircleAvatar(
            radius: 45,
            backgroundColor: AppColors.mainAppColor.withValues(alpha: 0.1),
            backgroundImage: rider.imageUrl.isNotEmpty
                ? NetworkImage(rider.imageUrl)
                : null,
            child: rider.imageUrl.isEmpty
                ? Icon(Icons.person, size: 45, color: AppColors.mainAppColor)
                : null,
          ),
          const SizedBox(height: 16),
          // Name
          Text(
            rider.name.isNotEmpty ? rider.name : 'Rider',
            style: const TextStyle(
              fontFamily: AssetsFont.textBold,
              fontSize: 22,
              color: AppColors.textColorBold,
            ),
          ),
          if (rider.email.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              rider.email,
              style: TextStyle(
                fontFamily: AssetsFont.textRegular,
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
          const SizedBox(height: 8),
          // Rating
          if (rider.averageRatings > 0)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                const SizedBox(width: 4),
                Text(
                  rider.averageRatings.toStringAsFixed(1),
                  style: const TextStyle(
                    fontFamily: AssetsFont.textMedium,
                    fontSize: 14,
                    color: AppColors.textColorBold,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 30),
          // Info card
          _buildInfoCard(rider),
          const SizedBox(height: 20),
          // Availability toggle
          _buildAvailabilityToggle(),
          const SizedBox(height: 20),
          // Logout button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout_rounded, color: Colors.red),
              label: Text(
                AppLocalizations.of(context)?.translate('logout') ?? 'Logout',
                style: const TextStyle(
                  fontFamily: AssetsFont.textMedium,
                  fontSize: 16,
                  color: Colors.red,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.red.shade200),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildInfoCard(RiderProfile rider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _infoRow(Icons.phone_outlined, 'Phone', rider.contact),
          Divider(height: 24, color: Colors.grey.shade100),
          _infoRow(
            Icons.email_outlined,
            'Email',
            rider.email.isNotEmpty ? rider.email : '-',
          ),
          Divider(height: 24, color: Colors.grey.shade100),
          _infoRow(
            Icons.circle,
            'Status',
            _isAvailable ? 'Available' : 'Unavailable',
            valueColor: _isAvailable ? Colors.green : Colors.red,
            iconSize: 10,
          ),
        ],
      ),
    );
  }

  Widget _infoRow(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
    double iconSize = 20,
  }) {
    return Row(
      children: [
        Icon(icon, size: iconSize, color: AppColors.mainAppColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: AssetsFont.textRegular,
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontFamily: AssetsFont.textMedium,
                  fontSize: 15,
                  color: valueColor ?? AppColors.textColorBold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAvailabilityToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            _isAvailable ? Icons.check_circle_outline : Icons.cancel_outlined,
            color: _isAvailable ? Colors.green : Colors.red,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _isAvailable ? 'Available for orders' : 'Unavailable',
              style: const TextStyle(
                fontFamily: AssetsFont.textMedium,
                fontSize: 15,
                color: AppColors.textColorBold,
              ),
            ),
          ),
          _isTogglingAvailability
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Switch(
                  value: _isAvailable,
                  onChanged: (_) => _toggleAvailability(),
                  activeColor: AppColors.mainAppColor,
                ),
        ],
      ),
    );
  }
}
