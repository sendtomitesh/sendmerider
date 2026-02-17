import 'package:sendme_rider/flutter_imports.dart';
import 'package:sendme_rider/flutter_project_imports.dart';
import 'package:intl/intl.dart';

class OrderCard extends StatelessWidget {
  final RiderOrder order;
  final VoidCallback onTap;

  const OrderCard({super.key, required this.order, required this.onTap});

  Color get _cardBackground {
    if (order.isPickUpAndDropOrder == 1) return Colors.yellow[100]!;
    if (order.orderStatus == GlobalConstants.orderPending) {
      return const Color(0xFFfadef0);
    }
    return Colors.white;
  }

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
    final badge = getStatusBadge(order.orderStatus);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: _cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
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
                        fontSize: 18,
                        color: AppColors.textColorBold,
                      ),
                    ),
                  ),
                  Image.asset(AssetsImage.riderGoing, width: 30, height: 30),
                ],
              ),
              const SizedBox(height: 4),
              // Order ID + payment type
              Text(
                '#${order.orderId}(${order.paymentType})',
                style: const TextStyle(
                  fontFamily: AssetsFont.textRegular,
                  fontSize: 13,
                  color: AppColors.textColorLight,
                ),
              ),
              const Divider(height: 16),
              // userName + userArea
              Row(
                children: [
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
                  Text(
                    order.userArea,
                    style: TextStyle(
                      fontFamily: AssetsFont.textMedium,
                      fontSize: 13,
                      color: AppColors.mainAppColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Order At
              Text(
                'Order At: ${_formatDate(order.orderOn)}',
                style: const TextStyle(
                  fontFamily: AssetsFont.textRegular,
                  fontSize: 12,
                  color: AppColors.textColorLight,
                ),
              ),
              // Delivery On (conditional)
              if (order.deliveryOn.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'Delivery On: ${_formatDate(order.deliveryOn)}',
                  style: const TextStyle(
                    fontFamily: AssetsFont.textRegular,
                    fontSize: 12,
                    color: AppColors.doneStatusColor,
                  ),
                ),
              ],
              // Delivered At (conditional)
              if (order.deliveredAt.isNotEmpty &&
                  order.orderStatus == GlobalConstants.orderDelivered) ...[
                const SizedBox(height: 4),
                Text(
                  'Delivered At: ${order.deliveredAt}',
                  style: const TextStyle(
                    fontFamily: AssetsFont.textRegular,
                    fontSize: 12,
                    color: AppColors.doneStatusColor,
                  ),
                ),
              ],
              const Divider(height: 16),
              // Bottom row: status badge + total bill
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: badge.color,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      badge.label,
                      style: const TextStyle(
                        fontFamily: AssetsFont.textMedium,
                        fontSize: 12,
                        color: Colors.white,
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
