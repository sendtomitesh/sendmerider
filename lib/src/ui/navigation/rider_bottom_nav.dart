import 'package:sendme_rider/flutter_imports.dart';
import 'package:sendme_rider/flutter_project_imports.dart';

class RiderBottomNav extends StatefulWidget {
  final String riderName;
  const RiderBottomNav({super.key, required this.riderName});

  @override
  State<RiderBottomNav> createState() => _RiderBottomNavState();
}

class _RiderBottomNavState extends State<RiderBottomNav> {
  RiderProfile? _rider;
  bool _isLoading = true;
  String? _error;
  int _currentIndex = 0;
  final _apiService = RiderApiService();

  @override
  void initState() {
    super.initState();
    _loadRider();
  }

  Future<void> _loadRider() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final saved = await PreferencesHelper.getSavedRider();
      if (saved == null || (saved.mobile ?? '').isEmpty) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _error = 'No saved rider data found. Please log in again.';
        });
        return;
      }

      final riderProfile = await _apiService.fetchRiderProfile(
        mobile: saved.mobile!,
      );

      if (!mounted) return;
      setState(() {
        _rider = riderProfile.copyWith(
          name: riderProfile.name.isNotEmpty
              ? riderProfile.name
              : (saved.name ?? widget.riderName),
        );
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Failed to load rider profile';
      });
    }
  }

  void _onRiderUpdated(RiderProfile updated) {
    setState(() => _rider = updated);
  }

  List<Widget> _buildPages() {
    return [
      OrdersPage(riderName: _rider!.name, riderProfile: _rider),
      ReportPage(riderId: _rider!.id),
      ReviewPage(riderId: _rider!.id),
      ProfilePage(rider: _rider!, onRiderUpdated: _onRiderUpdated),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null || _rider == null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                const SizedBox(height: 16),
                Text(
                  _error ?? 'Something went wrong',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AssetsFont.textMedium,
                    fontSize: 16,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _loadRider,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.mainAppColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final pages = _buildPages();

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: List.generate(4, (index) {
              return Expanded(
                child: Center(
                  child: Container(
                    height: 3,
                    width: 30,
                    decoration: BoxDecoration(
                      color: _currentIndex == index
                          ? AppColors.mainAppColor
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              );
            }),
          ),
          BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            type: BottomNavigationBarType.fixed,
            selectedItemColor: AppColors.mainAppColor,
            unselectedItemColor: Colors.grey,
            selectedLabelStyle: const TextStyle(
              fontFamily: AssetsFont.textBold,
              fontSize: 12,
            ),
            unselectedLabelStyle: const TextStyle(
              fontFamily: AssetsFont.textRegular,
              fontSize: 12,
            ),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.list_alt_rounded),
                label: 'Orders',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.bar_chart_rounded),
                label: 'Report',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.star_outline_rounded),
                label: 'Review',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline_rounded),
                label: 'Profile',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
