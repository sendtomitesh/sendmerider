import 'package:sendme_rider/flutter_imports.dart';
import 'package:sendme_rider/flutter_project_imports.dart';
import 'package:sendme_rider/src/service/location_service.dart';
import 'package:sendme_rider/src/ui/common/no_internet_screen.dart';
import 'package:animations/animations.dart';

class OrdersPage extends StatefulWidget {
  final String riderName;
  final RiderProfile? riderProfile;
  const OrdersPage({super.key, required this.riderName, this.riderProfile});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  RiderProfile? _rider;
  int _tabIndex = 0; // 0=today, 1=all
  List<RiderOrder> _orders = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isTogglingAvailability = false;
  int _pageIndex = 0;
  Map<String, dynamic>? _paginationCursor;
  bool _hasMore = true;
  final _scrollController = ScrollController();
  final _apiService = RiderApiService();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScrollEnd);
    _loadRider();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScrollEnd);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadRider() async {
    if (widget.riderProfile != null) {
      setState(() {
        _rider = widget.riderProfile;
      });
      _fetchOrders(refresh: true);
      return;
    }

    final saved = await PreferencesHelper.getSavedRider();
    debugPrint(
      'OrdersPage._loadRider: saved=$saved, userId=${saved?.userId}, mobile=${saved?.mobile}',
    );
    if (saved != null && mounted) {
      try {
        final mobile = saved.mobile ?? '';
        if (mobile.isEmpty) {
          debugPrint(
            'OrdersPage._loadRider: mobile is empty, cannot fetch rider profile',
          );
          return;
        }
        debugPrint(
          'OrdersPage._loadRider: calling fetchRiderProfile with mobile=$mobile',
        );
        final riderProfile = await _apiService.fetchRiderProfile(
          mobile: mobile,
        );
        debugPrint(
          'OrdersPage._loadRider: got rider id=${riderProfile.id}, name=${riderProfile.name}, status=${riderProfile.status}',
        );
        if (!mounted) return;
        setState(() {
          _rider = riderProfile.copyWith(
            name: riderProfile.name.isNotEmpty
                ? riderProfile.name
                : (saved.name ?? widget.riderName),
          );
        });
        _fetchOrders(refresh: true);
      } on ApiException catch (e) {
        debugPrint('OrdersPage._loadRider: ApiException: ${e.message}');
        if (!mounted) return;
        if (e.message == 'No internet connection') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NoInternetScreen()),
          );
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(e.message)));
        }
      }
    }
  }

  Future<void> _fetchOrders({bool refresh = false}) async {
    if (_rider == null) return;

    if (refresh) {
      setState(() {
        _pageIndex = 0;
        _paginationCursor = null;
        _hasMore = true;
        _orders = [];
        _isLoading = true;
      });
    } else {
      setState(() => _isLoadingMore = true);
    }

    try {
      final result = await _apiService.getRiderOrders(
        riderId: _rider!.id,
        dateType: _tabIndex,
        pageIndex: _pageIndex,
        pagination: _paginationCursor,
      );
      if (!mounted) return;
      setState(() {
        if (refresh) {
          _orders = result.orders;
        } else {
          _orders.addAll(result.orders);
        }
        _paginationCursor = result.pagination;
        _hasMore =
            result.orders.isNotEmpty && _pageIndex < result.totalPages - 1;
        _pageIndex++;
        _isLoading = false;
        _isLoadingMore = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
      if (e.message == 'No internet connection') {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NoInternetScreen()),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  void _onTabChanged(int index) {
    if (_tabIndex == index) return;
    setState(() => _tabIndex = index);
    _fetchOrders(refresh: true);
  }

  Future<void> _toggleAvailability() async {
    if (_rider == null) return;
    final newStatus = _rider!.status == 0 ? 1 : 0;
    setState(() => _isTogglingAvailability = true);
    try {
      await _apiService.updateRiderAvailability(
        rider: _rider!,
        status: newStatus,
      );
      if (!mounted) return;
      setState(() {
        _rider = _rider!.copyWith(status: newStatus);
        _isTogglingAvailability = false;
      });
      if (newStatus == 0) {
        LocationService.instance.startTracking(
          riderId: _rider!.id,
          cityId: _rider!.cityId,
        );
      } else {
        LocationService.instance.stopTracking();
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isTogglingAvailability = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  void _onScrollEnd() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _hasMore) {
        _fetchOrders();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Column(
          children: [
            if (_rider != null)
              RiderProfileHeader(
                riderName: _rider!.name.isNotEmpty
                    ? _rider!.name
                    : widget.riderName,
                isAvailable: _rider!.status == 0,
                isToggling: _isTogglingAvailability,
                onToggle: _toggleAvailability,
                imageUrl: _rider!.imageUrl,
              ),
            _buildTabBar(),
            Expanded(child: _buildOrderList()),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTab(
              AppLocalizations.of(context)?.translate('todayOrders') ??
                  'Today Orders',
              0,
            ),
          ),
          Expanded(
            child: _buildTab(
              AppLocalizations.of(context)?.translate('allOrders') ??
                  'All Orders',
              1,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => _fetchOrders(refresh: true),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.refresh,
                size: 20,
                color: AppColors.mainAppColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String label, int index) {
    final isSelected = _tabIndex == index;
    return GestureDetector(
      onTap: () => _onTabChanged(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: isSelected
                  ? AssetsFont.textBold
                  : AssetsFont.textMedium,
              fontSize: 14,
              color: isSelected ? AppColors.mainAppColor : Colors.grey.shade500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderList() {
    if (_isLoading) return const OrderShimmer();
    if (_orders.isEmpty) return _buildEmptyState();
    return RefreshIndicator(
      color: AppColors.mainAppColor,
      onRefresh: () => _fetchOrders(refresh: true),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.only(top: 4, bottom: 16),
        itemCount: _orders.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _orders.length) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.mainAppColor,
                  ),
                ),
              ),
            );
          }
          return _AnimatedOrderCard(
            index: index,
            order: _orders[index],
            riderId: _rider!.id,
            tappable: _tabIndex == 0,
            onResult: (result) {
              if (!mounted) return;
              if (result != null && result is int) {
                final idx = _orders.indexWhere(
                  (o) => o.orderId == _orders[index].orderId,
                );
                if (idx != -1) {
                  setState(() {
                    _orders[idx] = _orders[idx].copyWith(orderStatus: result);
                  });
                }
              } else {
                _fetchOrders(refresh: true);
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(AssetsImage.noData, width: 120, height: 120),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)?.translate('noOrdersFound') ??
                'No orders found',
            style: TextStyle(
              fontFamily: AssetsFont.textMedium,
              fontSize: 16,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () => _fetchOrders(refresh: true),
            icon: Icon(Icons.refresh, size: 18, color: AppColors.mainAppColor),
            label: Text(
              'Refresh',
              style: TextStyle(
                fontFamily: AssetsFont.textMedium,
                fontSize: 14,
                color: AppColors.mainAppColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Animated order card with staggered fade-in and OpenContainer transition.
class _AnimatedOrderCard extends StatefulWidget {
  final int index;
  final RiderOrder order;
  final int riderId;
  final bool tappable;
  final ValueChanged<dynamic> onResult;

  const _AnimatedOrderCard({
    required this.index,
    required this.order,
    required this.riderId,
    this.tappable = true,
    required this.onResult,
  });

  @override
  State<_AnimatedOrderCard> createState() => _AnimatedOrderCardState();
}

class _AnimatedOrderCardState extends State<_AnimatedOrderCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    final delay = Duration(milliseconds: (widget.index.clamp(0, 8)) * 60);
    Future.delayed(delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: widget.tappable
            ? OpenContainer<int?>(
                transitionDuration: const Duration(milliseconds: 500),
                openBuilder: (context, _) => OrderDetailPage(
                  orderId: widget.order.orderId,
                  riderId: widget.riderId,
                  outletId: widget.order.hotelId,
                ),
                closedElevation: 0,
                closedColor: Colors.transparent,
                openColor: Colors.white,
                closedBuilder: (context, openContainer) =>
                    OrderCard(order: widget.order, onTap: openContainer),
                onClosed: (result) => widget.onResult(result),
              )
            : OrderCard(order: widget.order, onTap: null),
      ),
    );
  }
}
