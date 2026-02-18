import 'package:sendme_rider/flutter_imports.dart';
import 'package:sendme_rider/flutter_project_imports.dart';
import 'package:intl/intl.dart';

class OrderCard extends StatelessWidget {
  final RiderOrder order;
  final VoidCallback? onTap;

  const OrderCard({super.key, required this.order, this.onTap});

  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return '';
    try {
      final parsed = DateFormat('MM/dd/yyyy h:mm:s a').parse(dateStr);
      return DateFormat('dd-MM-yyyy h:mm a').format(parsed);
    } catch (_) {
      return dateStr;
    }
  }

  String get _totalBillDisplay {
    final isCashOrDirect =
        order.paymentMode == GlobalConstants.cash ||
        order.paymentMode == GlobalConstants.directTransfer;

    if (order.isPickUpAndDropOrder == 1) {
      return '${order.currency} ${order.deliveryCharge}';
    }
    if (isCashOrDirect) {
      return '${order.currency} ${order.totalBill}';
    }
    return '${order.currency} 0';
  }

  @override
  Widget build(BuildContext context) {
    final badge = getStatusBadge(
      order.orderStatus,
      isPickUpAndDrop: order.isPickUpAndDropOrder == 1,
    );

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: hotelName + rider going icon
              Row(
                children: [
                  Expanded(
                    child: Text(
                      order.hotelName,
                      style: const TextStyle(
                        fontFamily: AssetsFont.textBold,
                        fontSize: 16,
                        color: AppColors.textColorBold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.mainAppColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Image.asset(
                      AssetsImage.riderGoing,
                      width: 22,
                      height: 22,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Order ID + payment type
              Row(
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 14,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '#${order.orderId}',
                    style: TextStyle(
                      fontFamily: AssetsFont.textMedium,
                      fontSize: 13,
                      color: AppColors.mainAppColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      order.paymentType,
                      style: TextStyle(
                        fontFamily: AssetsFont.textRegular,
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                  if (order.isPickUpAndDropOrder == 1) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.mainAppColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Pickup & Drop',
                        style: TextStyle(
                          fontFamily: AssetsFont.textMedium,
                          fontSize: 10,
                          color: AppColors.mainAppColor,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Divider(height: 1, color: Colors.grey.shade100),
              ),
              // userName + userArea
              Row(
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 16,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      order.userName,
                      style: const TextStyle(
                        fontFamily: AssetsFont.textMedium,
                        fontSize: 14,
                        color: AppColors.textColorBold,
                      ),
                    ),
                  ),
                  if (order.userArea.isNotEmpty) ...[
                    Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: AppColors.mainAppColor,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      order.userArea,
                      style: TextStyle(
                        fontFamily: AssetsFont.textMedium,
                        fontSize: 12,
                        color: AppColors.mainAppColor,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              // Order At
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Order At: ${_formatDate(order.orderOn)}',
                    style: TextStyle(
                      fontFamily: AssetsFont.textRegular,
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
              // Delivery On
              if (order.deliveryOn.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 14,
                      color: AppColors.doneStatusColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Delivery On: ${_formatDate(order.deliveryOn)}',
                      style: const TextStyle(
                        fontFamily: AssetsFont.textRegular,
                        fontSize: 12,
                        color: AppColors.doneStatusColor,
                      ),
                    ),
                  ],
                ),
              ],
              // Delivered At
              if (order.deliveredAt.isNotEmpty &&
                  order.orderStatus == GlobalConstants.orderDelivered) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      size: 14,
                      color: AppColors.doneStatusColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Delivered At: ${order.deliveredAt}',
                      style: const TextStyle(
                        fontFamily: AssetsFont.textRegular,
                        fontSize: 12,
                        color: AppColors.doneStatusColor,
                      ),
                    ),
                  ],
                ),
              ],
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Divider(height: 1, color: Colors.grey.shade100),
              ),
              // Bottom row: status badge + total bill
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: badge.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      badge.label,
                      style: TextStyle(
                        fontFamily: AssetsFont.textMedium,
                        fontSize: 12,
                        color: badge.color,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _totalBillDisplay,
                    style: const TextStyle(
                      fontFamily: AssetsFont.textBold,
                      fontSize: 16,
                      color: AppColors.textColorBold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
