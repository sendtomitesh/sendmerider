import 'package:sendme_rider/flutter_imports.dart';
import 'package:sendme_rider/flutter_project_imports.dart';
import 'package:url_launcher/url_launcher.dart';

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
  final _apiService = RiderApiService();

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _updateStatus(int newStatus) async {
    if (_order == null) return;
    setState(() => _isUpdating = true);
    try {
      await _apiService.updateOrderStatus(
        orderId: _order!.orderId,
        newStatus: newStatus,
        riderId: widget.riderId,
      );
      if (!mounted) return;
      // Re-fetch to get updated isRiderGoing and deliveredAt
      await _fetchDetail();
      setState(() => _isUpdating = false);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isUpdating = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _callCustomer() async {
    if (_order == null) return;
    final phone = _order!.contactNo.isNotEmpty
        ? _order!.contactNo
        : _order!.mobile;
    if (phone.isEmpty) return;
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _navigateTo(double lat, double lng) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Order #${widget.orderId}',
          style: const TextStyle(fontFamily: AssetsFont.textBold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _order == null
          ? const Center(child: Text('Order not found'))
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    final order = _order!;
    final badge = getStatusBadge(order.orderStatus);
    final nextStatus = getNextRiderStatus(
      order.orderStatus,
      isRiderGoing: order.isRiderGoing,
    );
    final nextLabel = getNextStatusLabel(
      order.orderStatus,
      isRiderGoing: order.isRiderGoing,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status badge
          _buildStatusBadge(badge),
          const SizedBox(height: 20),
          // Outlet info
          _buildSection(
            'Outlet',
            Icons.store_rounded,
            [
              _infoRow('Name', order.hotelName),
              _infoRow('Address', order.hotelAddress),
            ],
            trailingAction: order.outletLatitude != 0.0
                ? IconButton(
                    icon: const Icon(Icons.directions, color: Colors.blue),
                    onPressed: () => _navigateTo(
                      order.outletLatitude,
                      order.outletLongitude,
                    ),
                    tooltip: 'Navigate to outlet',
                  )
                : null,
          ),
          const SizedBox(height: 12),
          // Customer info
          _buildSection(
            'Customer',
            Icons.person_rounded,
            [
              _infoRow('Name', order.userName),
              _infoRow('Area', order.userArea),
              _infoRow(
                'Contact',
                order.contactNo.isNotEmpty ? order.contactNo : order.mobile,
              ),
            ],
            trailingAction: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (order.contactNo.isNotEmpty || order.mobile.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.phone, color: Colors.green),
                    onPressed: _callCustomer,
                    tooltip: 'Call customer',
                  ),
                if (order.userLatitude != 0.0)
                  IconButton(
                    icon: const Icon(Icons.directions, color: Colors.blue),
                    onPressed: () =>
                        _navigateTo(order.userLatitude, order.userLongitude),
                    tooltip: 'Navigate to customer',
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Order metadata
          _buildSection('Order Details', Icons.receipt_long_rounded, [
            _infoRow('Order ID', '#${order.orderId}'),
            _infoRow(
              'Payment',
              '${order.paymentType} (${getPaymentLabel(order.paymentMode)})',
            ),
            if (order.orderOn.isNotEmpty) _infoRow('Ordered', order.orderOn),
            if (order.deliveryOn.isNotEmpty)
              _infoRow('Delivery', order.deliveryOn),
            if (order.deliveredAt.isNotEmpty)
              _infoRow('Delivered', order.deliveredAt),
            _infoRow(
              'Total',
              '${order.currency} ${order.totalBill.toStringAsFixed(2)}',
            ),
            if (order.deliveryCharge > 0)
              _infoRow(
                'Delivery Charge',
                '${order.currency} ${order.deliveryCharge.toStringAsFixed(2)}',
              ),
            if (order.slot.isNotEmpty) _infoRow('Slot', order.slot),
            if (order.remarks.isNotEmpty) _infoRow('Remarks', order.remarks),
          ]),
          const SizedBox(height: 24),
          // Delivered message
          if (order.orderStatus == GlobalConstants.orderDelivered)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: const Text(
                'This order is processed',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AssetsFont.textBold,
                  fontSize: 15,
                  color: Colors.green,
                ),
              ),
            )
          // Cancelled message
          else if (order.orderStatus == GlobalConstants.userCancelled ||
              order.orderStatus == GlobalConstants.hotelCancelled ||
              order.orderStatus == GlobalConstants.sendmeCancelled)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: const Text(
                'This order is cancelled',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AssetsFont.textBold,
                  fontSize: 15,
                  color: Colors.red,
                ),
              ),
            )
          // Action button (not for pending)
          else if (nextStatus != null && nextLabel != null)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isUpdating ? null : () => _updateStatus(nextStatus),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.mainAppColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontFamily: AssetsFont.textBold,
                    fontSize: 16,
                  ),
                ),
                child: _isUpdating
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(nextLabel),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(({String label, Color color}) badge) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: badge.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: badge.color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: badge.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            badge.label,
            style: TextStyle(
              fontFamily: AssetsFont.textBold,
              fontSize: 16,
              color: badge.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    String title,
    IconData icon,
    List<Widget> children, {
    Widget? trailingAction,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.mainAppColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: AssetsFont.textBold,
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              ?trailingAction,
            ],
          ),
          const Divider(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                fontFamily: AssetsFont.textMedium,
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: AssetsFont.textRegular,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
