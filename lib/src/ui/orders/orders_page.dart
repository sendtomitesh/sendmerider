import 'package:sendme_rider/flutter_imports.dart';
import 'package:sendme_rider/flutter_project_imports.dart';

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
    // If a RiderProfile was passed from RiderBottomNav, use it directly
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
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

  Future<void> _navigateToDetail(RiderOrder order) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderDetailPage(
          orderId: order.orderId,
          riderId: _rider!.id,
          outletId: order.hotelId,
        ),
      ),
    );
    // Refresh on return in case status was updated
    _fetchOrders(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Profile header
            if (_rider != null)
              RiderProfileHeader(
                riderName: _rider!.name.isNotEmpty
                    ? _rider!.name
                    : widget.riderName,
                isAvailable: _rider!.status == 0,
                isToggling: _isTogglingAvailability,
                onToggle: _toggleAvailability,
              ),
            // Tab bar
            _buildTabBar(),
            // Order list
            Expanded(child: _buildOrderList()),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildTab('Today Orders', 0),
          const SizedBox(width: 20),
          _buildTab('All Orders', 1),
          const Spacer(),
          IconButton(
            icon: Icon(Icons.refresh, color: AppColors.mainAppColor),
            onPressed: () => _fetchOrders(refresh: true),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String label, int index) {
    final isSelected = _tabIndex == index;
    return GestureDetector(
      onTap: () => _onTabChanged(index),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: isSelected
                  ? AssetsFont.textBold
                  : AssetsFont.textMedium,
              fontSize: 17,
              color: isSelected ? AppColors.mainAppColor : Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 30,
            height: 3,
            color: isSelected ? AppColors.mainAppColor : Colors.transparent,
          ),
        ],
      ),
    );
  }

  Widget _buildOrderList() {
    if (_isLoading) return const OrderShimmer();
    if (_orders.isEmpty) return _buildEmptyState();
    return RefreshIndicator(
      onRefresh: () => _fetchOrders(refresh: true),
      child: ListView.builder(
        controller: _scrollController,
        itemCount: _orders.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _orders.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }
          return OrderCard(
            order: _orders[index],
            onTap: () => _navigateToDetail(_orders[index]),
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
            'No orders found',
            style: TextStyle(
              fontFamily: AssetsFont.textMedium,
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
