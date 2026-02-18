import 'package:sendme_rider/flutter_imports.dart';
import 'package:sendme_rider/flutter_project_imports.dart';
import 'package:sendme_rider/src/ui/common/no_internet_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:photo_view/photo_view.dart';

class OrderDetailPage extends StatefulWidget {
  final int orderId;
  final int riderId;
  final int outletId;
  const OrderDetailPage({
    super.key,
    required this.orderId,
    required this.riderId,
    this.outletId = 0,
  });

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  RiderOrder? _order;
  bool _isLoading = true;
  bool _isUpdating = false;
  int? _lastUpdatedStatus;
  final _apiService = RiderApiService();
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  // ─── API ───

  Future<void> _fetchDetail() async {
    setState(() => _isLoading = true);
    try {
      final order = await _apiService.getRiderOrderDetail(
        orderId: widget.orderId,
        outletId: widget.outletId,
        riderId: widget.riderId,
      );
      if (!mounted) return;
      setState(() {
        _order = order;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (e.message == 'No internet connection') {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NoInternetScreen()),
        ).then((_) => _fetchDetail());
      } else {
        _snack(e.message);
      }
    }
  }

  Future<void> _updateStatus() async {
    if (_order == null) return;
    final next = getNextRiderStatus(
      _order!.orderStatus,
      isRiderGoing: _order!.isRiderGoing,
      isPickUpAndDrop: _order!.isPickUpAndDropOrder == 1,
    );
    if (next == null) return;
    setState(() => _isUpdating = true);
    try {
      await _apiService.updateOrderStatus(
        orderId: _order!.orderId,
        newStatus: next,
        riderId: widget.riderId,
      );
      if (!mounted) return;
      _lastUpdatedStatus = next;
      await _fetchDetail();
      setState(() => _isUpdating = false);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isUpdating = false);
      if (e.message == 'No internet connection') {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NoInternetScreen()),
        );
      } else {
        _snack(e.message);
      }
    }
  }

  Future<void> _callPhone(String phone) async {
    if (phone.isEmpty) return;
    final uri = Uri.parse('tel://$phone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _openMap(double lat, double lng) async {
    if (lat == 0.0 && lng == 0.0) return;
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _navigateToOutlet() async {
    if (_order == null) return;
    double lat = _order!.outletLatitude;
    double lng = _order!.outletLongitude;
    if (_order!.isPickUpAndDropOrder == 1 && _order!.pickUpAddress != null) {
      lat = _order!.pickUpAddress!.latitude;
      lng = _order!.pickUpAddress!.longitude;
    }
    _openMap(lat, lng);
  }

  Future<void> _navigateToCustomer() async {
    if (_order == null) return;
    double lat = _order!.userLatitude;
    double lng = _order!.userLongitude;
    if (_order!.isPickUpAndDropOrder == 1 && _order!.dropAddress != null) {
      lat = _order!.dropAddress!.latitude;
      lng = _order!.dropAddress!.longitude;
    }
    _openMap(lat, lng);
  }

  Future<void> _uploadBill() async {
    try {
      final pic = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 20,
      );
      if (pic == null) return;
      final msg = await _apiService.uploadBill(
        orderId: _order!.orderId,
        imageFile: pic,
      );
      if (!mounted) return;
      _snack(msg);
    } catch (e) {
      if (!mounted) return;
      _snack('Failed to upload bill');
    }
  }

  Future<void> _uploadQRProof() async {
    try {
      final pic = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 20,
      );
      if (pic == null) return;
      final msg = await _apiService.uploadQRPayment(
        orderId: _order!.orderId,
        imageFile: pic,
      );
      if (!mounted) return;
      _snack(msg);
    } catch (e) {
      if (!mounted) return;
      _snack('Failed to upload proof');
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ─── HELPERS ───

  String _fmtDate(String s) {
    if (s.isEmpty) return '';
    try {
      final d = DateFormat('MM/dd/yyyy h:mm:s a', 'en').parse(s);
      return DateFormat('dd MMM yyyy, h:mm a').format(d);
    } catch (_) {
      return s;
    }
  }

  String _fmtCur(double v) => v.toStringAsFixed(2);

  bool _isCancelled(int s) =>
      s == GlobalConstants.userCancelled ||
      s == GlobalConstants.hotelCancelled ||
      s == GlobalConstants.sendmeCancelled ||
      s == GlobalConstants.adminCancelled;

  String _collectFromCustomer() {
    if (_order!.paymentMode == GlobalConstants.cash ||
        _order!.paymentMode == GlobalConstants.directTransfer) {
      return '${_order!.currency} ${_fmtCur(_order!.totalBill)}';
    }
    return '${_order!.currency} 0';
  }

  String _amountForHotel() {
    if (_order!.paymentMode == GlobalConstants.cash ||
        _order!.paymentMode == GlobalConstants.directTransfer) {
      return '${_order!.currency} ${_fmtCur(_order!.totalAmountForHotel)}';
    }
    return '${_order!.currency} 0';
  }

  // ─── BUILD ───

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Navigator.of(context).pop(_lastUpdatedStatus);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        appBar: AppBar(
          title: Text(
            'Order #${widget.orderId}',
            style: const TextStyle(
              fontFamily: AssetsFont.textBold,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          surfaceTintColor: Colors.white,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _order == null
            ? _emptyState()
            : _order!.isPickUpAndDropOrder == 1
            ? _pickupDropBody()
            : _normalBody(),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          const Text(
            'Order not found',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
              fontFamily: AssetsFont.textMedium,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // NORMAL ORDER
  // ═══════════════════════════════════════════════════════════

  Widget _normalBody() {
    final o = _order!;
    return Column(
      children: [
        _statusBanner(o),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _fetchDetail,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                // Action button
                _actionButton(o),
                const SizedBox(height: 16),
                // Outlet card
                _outletCard(o),
                const SizedBox(height: 12),
                // Customer card
                _customerCard(o),
                const SizedBox(height: 12),
                // Prescription
                if (o.groceryItems == null &&
                    o.orderDetail == null &&
                    o.prescriptionImage.isNotEmpty)
                  _prescriptionSection(o),
                // Grocery items
                if (o.groceryItems != null && o.orderDetail == null)
                  _grocerySection(o),
                // Order items
                if (o.groceryItems == null && o.orderDetail != null)
                  _orderItemsSection(o),
                const SizedBox(height: 12),
                // Summary
                _summaryCard(o),
                const SizedBox(height: 12),
                // Bottom actions
                _bottomActions(o),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // PICKUP & DROP ORDER
  // ═══════════════════════════════════════════════════════════

  Widget _pickupDropBody() {
    final o = _order!;
    return Column(
      children: [
        _statusBanner(o),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _fetchDetail,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                _actionButton(o),
                const SizedBox(height: 16),
                _pickupDropTimeline(o),
                const SizedBox(height: 12),
                _pickupDropQuickActions(o),
                if (o.packageContent != null &&
                    o.packageContent!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _packageCard(o),
                ],
                const SizedBox(height: 12),
                _pickupDropPayment(o),
                const SizedBox(height: 12),
                if (o.paymentMode != GlobalConstants.onlinePayment)
                  _bottomActions(o),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // STATUS BANNER
  // ═══════════════════════════════════════════════════════════

  Widget _statusBanner(RiderOrder o) {
    Color bg;
    IconData icon;
    String text;

    if (o.orderStatus == GlobalConstants.orderDelivered) {
      bg = const Color(0xFF00B894);
      icon = Icons.check_circle_rounded;
      text = 'Delivered Successfully';
    } else if (_isCancelled(o.orderStatus)) {
      bg = const Color(0xFFD63031);
      icon = Icons.cancel_rounded;
      text = 'Order Cancelled';
    } else {
      final badge = getStatusBadge(
        o.orderStatus,
        isPickUpAndDrop: o.isPickUpAndDropOrder == 1,
      );
      bg = AppColors.mainAppColor;
      icon = Icons.delivery_dining_rounded;
      text = badge.label;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [bg, bg.withValues(alpha: 0.85)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontFamily: AssetsFont.textMedium,
              ),
            ),
          ),
          if (o.orderOn.isNotEmpty)
            Text(
              _fmtDate(o.orderOn),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 11,
                fontFamily: AssetsFont.textRegular,
              ),
            ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // ACTION BUTTON
  // ═══════════════════════════════════════════════════════════

  Widget _actionButton(RiderOrder o) {
    if (o.orderStatus == GlobalConstants.orderDelivered ||
        _isCancelled(o.orderStatus)) {
      return const SizedBox.shrink();
    }

    final label = getNextStatusLabel(
      o.orderStatus,
      isRiderGoing: o.isRiderGoing,
      isPickUpAndDrop: o.isPickUpAndDropOrder == 1,
    );
    if (label == null) return const SizedBox.shrink();

    if (_isUpdating) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    IconData icon;
    switch (label) {
      case 'I Am Going':
        icon = Icons.directions_bike_rounded;
        break;
      case 'Picked':
        icon = Icons.shopping_bag_rounded;
        break;
      case 'Delivered':
        icon = Icons.check_circle_rounded;
        break;
      default:
        icon = Icons.arrow_forward_rounded;
    }

    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            AppColors.mainAppColor,
            AppColors.mainAppColor.withValues(alpha: 0.8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.mainAppColor.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _updateStatus,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 22),
              const SizedBox(width: 10),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontFamily: AssetsFont.textBold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // OUTLET CARD
  // ═══════════════════════════════════════════════════════════

  Widget _outletCard(RiderOrder o) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.mainAppColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.store_rounded,
                  color: AppColors.mainAppColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      o.hotelName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontFamily: AssetsFont.textBold,
                        color: Colors.black87,
                      ),
                    ),
                    if (o.contactNo.isNotEmpty)
                      Text(
                        o.contactNo,
                        style: const TextStyle(
                          fontSize: 13,
                          fontFamily: AssetsFont.textRegular,
                          color: Colors.grey,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (o.outletAddress2.isNotEmpty || o.outletCity.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 18,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      [
                        o.outletAddress2,
                        o.outletCity,
                      ].where((s) => s.isNotEmpty).join(', '),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                        fontFamily: AssetsFont.textRegular,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _chipButton(
                  Icons.phone_rounded,
                  'Call',
                  () => _callPhone(o.contactNo),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _chipButton(
                  Icons.directions_rounded,
                  'Navigate',
                  _navigateToOutlet,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // CUSTOMER CARD
  // ═══════════════════════════════════════════════════════════

  Widget _customerCard(RiderOrder o) {
    final phone = o.mobile.isNotEmpty ? o.mobile : o.contactNo;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: Colors.blue,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      o.userName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontFamily: AssetsFont.textBold,
                        color: Colors.black87,
                      ),
                    ),
                    if (phone.isNotEmpty)
                      Text(
                        phone,
                        style: const TextStyle(
                          fontSize: 13,
                          fontFamily: AssetsFont.textRegular,
                          color: Colors.grey,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (o.address != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 18,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          o.address!.floor != null
                              ? '${o.address!.address}, Floor ${o.address!.floor}'
                              : o.address!.address,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                            fontFamily: AssetsFont.textRegular,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (o.address!.landMark.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            o.address!.landMark,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                              fontFamily: AssetsFont.textRegular,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _chipButton(
                  Icons.phone_rounded,
                  'Call',
                  () => _callPhone(phone),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _chipButton(
                  Icons.directions_rounded,
                  'Navigate',
                  _navigateToCustomer,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // PRESCRIPTION
  // ═══════════════════════════════════════════════════════════

  Widget _prescriptionSection(RiderOrder o) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Prescription',
              style: TextStyle(
                fontSize: 15,
                fontFamily: AssetsFont.textBold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => Scaffold(
                      appBar: AppBar(title: const Text('Prescription')),
                      body: PhotoView(
                        imageProvider: NetworkImage(o.prescriptionImage),
                        backgroundDecoration: const BoxDecoration(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                child: SizedBox(
                  height: 200,
                  width: double.infinity,
                  child: Image.network(
                    o.prescriptionImage,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey.shade100,
                      child: const Center(
                        child: Icon(
                          Icons.broken_image,
                          size: 40,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // GROCERY ITEMS
  // ═══════════════════════════════════════════════════════════

  Widget _grocerySection(RiderOrder o) {
    final items = o.groceryItems!;
    final showPrice = items.isNotEmpty && items[0].price != 0.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.shopping_basket_rounded,
                  color: AppColors.mainAppColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Grocery Items (${items.length})',
                  style: const TextStyle(
                    fontSize: 15,
                    fontFamily: AssetsFont.textBold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.mainAppColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Expanded(
                    flex: 3,
                    child: Text(
                      'Item',
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: AssetsFont.textMedium,
                      ),
                    ),
                  ),
                  const Expanded(
                    flex: 1,
                    child: Text(
                      'Qty',
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: AssetsFont.textMedium,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const Expanded(
                    flex: 1,
                    child: Text(
                      'Unit',
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: AssetsFont.textMedium,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  if (showPrice)
                    const Expanded(
                      flex: 2,
                      child: Text(
                        'Price',
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: AssetsFont.textMedium,
                        ),
                        textAlign: TextAlign.end,
                      ),
                    ),
                ],
              ),
            ),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        item.itemName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontFamily: AssetsFont.textRegular,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        item.qty,
                        style: const TextStyle(
                          fontSize: 13,
                          fontFamily: AssetsFont.textRegular,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        item.unit,
                        style: const TextStyle(
                          fontSize: 13,
                          fontFamily: AssetsFont.textRegular,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    if (showPrice)
                      Expanded(
                        flex: 2,
                        child: Text(
                          '${o.currency} ${item.price}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontFamily: AssetsFont.textMedium,
                          ),
                          textAlign: TextAlign.end,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // ORDER ITEMS
  // ═══════════════════════════════════════════════════════════

  Widget _orderItemsSection(RiderOrder o) {
    final items = o.orderDetail!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.receipt_long_rounded,
                  color: AppColors.mainAppColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Order Items (${items.length})',
                  style: const TextStyle(
                    fontSize: 15,
                    fontFamily: AssetsFont.textBold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...items.map((item) {
              final name = item.subItemName.isNotEmpty
                  ? '${item.name} (${item.subItemName})'
                  : item.name;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.mainAppColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontFamily: AssetsFont.textMedium,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${o.currency} ${_fmtCur(item.price)} × ${item.qty}',
                            style: TextStyle(
                              fontSize: 12,
                              fontFamily: AssetsFont.textRegular,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${o.currency} ${_fmtCur(item.totalAmount)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontFamily: AssetsFont.textMedium,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // ORDER SUMMARY
  // ═══════════════════════════════════════════════════════════

  Widget _summaryCard(RiderOrder o) {
    double billTotal = 0;
    if (o.orderDetail != null) {
      for (final item in o.orderDetail!) billTotal += item.totalAmount;
    } else if (o.groceryItems != null) {
      for (final item in o.groceryItems!) billTotal += item.price;
    }

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.summarize_rounded,
                color: AppColors.mainAppColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Order Summary',
                style: TextStyle(
                  fontSize: 15,
                  fontFamily: AssetsFont.textBold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Payment mode chip
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.mainAppColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              o.paymentType.isNotEmpty
                  ? o.paymentType
                  : getPaymentLabel(o.paymentMode),
              style: TextStyle(
                fontSize: 12,
                fontFamily: AssetsFont.textMedium,
                color: AppColors.mainAppColor,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.grey.shade200, height: 1),
          const SizedBox(height: 8),
          if (billTotal != 0)
            _summaryRow('Bill Total', '${o.currency} ${_fmtCur(billTotal)}'),
          if (o.additionalCharges != 0)
            _summaryRow(
              'Additional Charge',
              '${o.currency} ${_fmtCur(o.additionalCharges)}',
              valueColor: const Color(0xFFD63031),
            ),
          // Offers
          if (o.offers != null)
            ...o.offers!.map(
              (offer) => _summaryRow(
                offer.title,
                offer.itemFree.isNotEmpty
                    ? offer.itemFree
                    : '${o.currency} ${_fmtCur(offer.mainDiscountAmount)}',
                valueColor: const Color(0xFF00B894),
              ),
            ),
          // Taxes
          if (o.sGST != 0 && o.cGST != 0) ...[
            const SizedBox(height: 4),
            Divider(color: Colors.grey.shade200, height: 1),
            const SizedBox(height: 4),
            _summaryRow(
              'Sub Total',
              '${o.currency} ${_fmtCur(o.netBill)}',
              bold: true,
            ),
            _summaryRow('CGST', '${o.currency} ${_fmtCur(o.cGST)}'),
            _summaryRow('SGST', '${o.currency} ${_fmtCur(o.sGST)}'),
          ],
          _summaryRow(
            'Amount For Hotel',
            _amountForHotel(),
            bold: true,
            labelColor: AppColors.mainAppColor,
          ),
          _summaryRow(
            'Delivery Charge',
            '${o.currency} ${_fmtCur(o.deliveryCharge)}',
          ),
          // Delivery charge offers
          if (o.offers != null)
            ...o.offers!
                .where((x) => x.offerType == 5 && x.mainDiscountAmount != 0)
                .map(
                  (x) => _summaryRow(
                    x.title,
                    '${o.currency} ${_fmtCur(x.mainDiscountAmount)}',
                    valueColor: const Color(0xFF00B894),
                  ),
                ),
          const SizedBox(height: 4),
          Divider(color: Colors.grey.shade200, height: 1),
          const SizedBox(height: 4),
          _summaryRow(
            'Collect From Customer',
            _collectFromCustomer(),
            bold: true,
            labelColor: const Color(0xFF00B894),
            valueColor: const Color(0xFF00B894),
          ),
          if (o.changeForCash.isNotEmpty && o.changeForCash != '0') ...[
            const SizedBox(height: 4),
            _summaryRow(
              'Change For Cash',
              '${o.currency} ${o.changeForCash}',
              bold: true,
              labelColor: const Color(0xFFD63031),
              valueColor: const Color(0xFFD63031),
            ),
          ],
          if (o.remarks.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3CD),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: Color(0xFF856404),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      o.remarks,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF856404),
                        fontFamily: AssetsFont.textRegular,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // BOTTOM ACTIONS (Bill + QR)
  // ═══════════════════════════════════════════════════════════

  Widget _bottomActions(RiderOrder o) {
    return Column(
      children: [
        // Attach bill
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _uploadBill,
            icon: const Icon(Icons.camera_alt_rounded, size: 20),
            label: const Text(
              'Attach Bill',
              style: TextStyle(fontSize: 15, fontFamily: AssetsFont.textBold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.mainAppColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
          ),
        ),
        if (o.paymentMode != GlobalConstants.onlinePayment) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => _QRViewPage(
                          qrImage: o.qrImage,
                          orderId: o.orderId,
                          riderId: widget.riderId,
                          apiService: _apiService,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.qr_code_rounded, size: 20),
                    label: const Text(
                      'Pay QR',
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: AssetsFont.textBold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.mainAppColor,
                      side: BorderSide(color: AppColors.mainAppColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: _uploadQRProof,
                    icon: const Icon(Icons.upload_file_rounded, size: 20),
                    label: const Text(
                      'Upload Proof',
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: AssetsFont.textBold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.mainAppColor,
                      side: BorderSide(color: AppColors.mainAppColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // PICKUP & DROP — TIMELINE
  // ═══════════════════════════════════════════════════════════

  Widget _pickupDropTimeline(RiderOrder o) {
    final picked =
        o.orderStatus == GlobalConstants.orderPicked ||
        o.orderStatus == GlobalConstants.orderDelivered;
    final delivered = o.orderStatus == GlobalConstants.orderDelivered;

    return _card(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline dots + line
          Column(
            children: [
              _timelineDot(picked),
              Container(
                width: 2,
                height: 80,
                margin: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: picked ? AppColors.mainAppColor : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
              _timelineDot(delivered),
            ],
          ),
          const SizedBox(width: 16),
          // Address info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PICKUP',
                  style: TextStyle(
                    fontSize: 11,
                    fontFamily: AssetsFont.textBold,
                    color: picked ? AppColors.mainAppColor : Colors.grey,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                if (o.pickUpAddress != null) _addressInfo(o.pickUpAddress!),
                const SizedBox(height: 24),
                Text(
                  'DROP OFF',
                  style: TextStyle(
                    fontSize: 11,
                    fontFamily: AssetsFont.textBold,
                    color: delivered ? AppColors.mainAppColor : Colors.grey,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                if (o.dropAddress != null) _addressInfo(o.dropAddress!),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _timelineDot(bool active) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? AppColors.mainAppColor : Colors.grey.shade300,
        border: Border.all(
          color: active ? AppColors.mainAppColor : Colors.grey.shade400,
          width: 2,
        ),
      ),
      child: active
          ? const Icon(Icons.check, size: 10, color: Colors.white)
          : null,
    );
  }

  Widget _addressInfo(OrderAddress addr) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          addr.userName,
          style: const TextStyle(
            fontSize: 14,
            fontFamily: AssetsFont.textMedium,
            color: Colors.black87,
          ),
        ),
        if (addr.userContact.isNotEmpty)
          GestureDetector(
            onTap: () => _callPhone(addr.userContact),
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.phone_rounded,
                    size: 14,
                    color: AppColors.mainAppColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    addr.userContact,
                    style: TextStyle(
                      fontSize: 13,
                      fontFamily: AssetsFont.textRegular,
                      color: AppColors.mainAppColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            addr.floor != null
                ? '${addr.address}, Floor ${addr.floor}, ${addr.landMark}'
                : '${addr.address}, ${addr.landMark}',
            style: TextStyle(
              fontSize: 12,
              fontFamily: AssetsFont.textRegular,
              color: Colors.grey.shade600,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // PICKUP & DROP — QUICK ACTIONS
  // ═══════════════════════════════════════════════════════════

  Widget _pickupDropQuickActions(RiderOrder o) {
    final phone = o.mobile.isNotEmpty ? o.mobile : o.contactNo;
    return Row(
      children: [
        Expanded(
          child: _chipButton(
            Icons.phone_rounded,
            'Call Customer',
            () => _callPhone(phone),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _chipButton(
            Icons.near_me_rounded,
            'Pickup',
            _navigateToOutlet,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _chipButton(
            Icons.flag_rounded,
            'Drop Off',
            _navigateToCustomer,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // PICKUP & DROP — PACKAGE CONTENTS
  // ═══════════════════════════════════════════════════════════

  Widget _packageCard(RiderOrder o) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.inventory_2_rounded,
                color: AppColors.mainAppColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Package Contents',
                style: TextStyle(
                  fontSize: 15,
                  fontFamily: AssetsFont.textBold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...o.packageContent!.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.mainAppColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        fontSize: 14,
                        fontFamily: AssetsFont.textRegular,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // PICKUP & DROP — PAYMENT
  // ═══════════════════════════════════════════════════════════

  Widget _pickupDropPayment(RiderOrder o) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.payment_rounded,
                color: AppColors.mainAppColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Payment Info',
                style: TextStyle(
                  fontSize: 15,
                  fontFamily: AssetsFont.textBold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.mainAppColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              o.paymentType,
              style: TextStyle(
                fontSize: 12,
                fontFamily: AssetsFont.textMedium,
                color: AppColors.mainAppColor,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.grey.shade200, height: 1),
          const SizedBox(height: 8),
          _summaryRow(
            'Delivery Charge',
            '${o.currency} ${_fmtCur(o.deliveryCharge)}',
          ),
          _summaryRow('Ordered On', _fmtDate(o.orderOn)),
          if (o.changeForCash.isNotEmpty && o.changeForCash != '0') ...[
            const SizedBox(height: 4),
            _summaryRow(
              'Change For Cash',
              '${o.currency} ${o.changeForCash}',
              bold: true,
              labelColor: const Color(0xFFD63031),
              valueColor: const Color(0xFFD63031),
            ),
          ],
          if (o.remarks.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3CD),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: Color(0xFF856404),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      o.remarks,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF856404),
                        fontFamily: AssetsFont.textRegular,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // SHARED WIDGETS
  // ═══════════════════════════════════════════════════════════

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
      child: child,
    );
  }

  Widget _chipButton(IconData icon, String label, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: AppColors.mainAppColor),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontFamily: AssetsFont.textMedium,
                    color: AppColors.mainAppColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryRow(
    String label,
    String value, {
    Color? labelColor,
    Color? valueColor,
    bool bold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontFamily: bold
                    ? AssetsFont.textMedium
                    : AssetsFont.textRegular,
                color: labelColor ?? Colors.grey.shade700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontFamily: bold ? AssetsFont.textBold : AssetsFont.textMedium,
              color: valueColor ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// QR VIEW PAGE
// ═══════════════════════════════════════════════════════════

class _QRViewPage extends StatelessWidget {
  final String qrImage;
  final int orderId;
  final int riderId;
  final RiderApiService apiService;

  const _QRViewPage({
    required this.qrImage,
    required this.orderId,
    required this.riderId,
    required this.apiService,
  });

  @override
  Widget build(BuildContext context) {
    final picker = ImagePicker();
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text(
          'Pay Through QR',
          style: TextStyle(fontFamily: AssetsFont.textBold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        surfaceTintColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
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
                child: qrImage.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: PhotoView(
                          imageProvider: NetworkImage(qrImage),
                          backgroundDecoration: const BoxDecoration(
                            color: Colors.white,
                          ),
                          minScale: PhotoViewComputedScale.contained * 0.8,
                          maxScale: PhotoViewComputedScale.covered * 0.8,
                        ),
                      )
                    : const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.qr_code_rounded,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'No QR code available',
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey,
                                fontFamily: AssetsFont.textMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: () async {
                  try {
                    final pic = await picker.pickImage(
                      source: ImageSource.camera,
                      imageQuality: 20,
                    );
                    if (pic == null) return;
                    final msg = await apiService.uploadQRPayment(
                      orderId: orderId,
                      imageFile: pic,
                    );
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(msg)));
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Upload failed: $e')),
                    );
                  }
                },
                icon: const Icon(Icons.upload_file_rounded, size: 20),
                label: const Text(
                  'Upload Payment Proof',
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: AssetsFont.textBold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.mainAppColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
