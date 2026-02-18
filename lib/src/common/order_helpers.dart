import 'package:flutter/material.dart';
import 'package:sendme_rider/src/common/colors.dart';
import 'package:sendme_rider/src/common/global_constants.dart';

/// Returns (label, color) for a given order status.
({String label, Color color}) getStatusBadge(
  int status, {
  bool isPickUpAndDrop = false,
}) => switch (status) {
  GlobalConstants.orderPending => (
    label: 'Pending',
    color: AppColors.pendingStatusColor,
  ),
  GlobalConstants.userCancelled => (label: 'User Cancelled', color: Colors.red),
  GlobalConstants.hotelCancelled => (
    label: isPickUpAndDrop ? 'Admin Cancelled' : 'Outlet Cancelled',
    color: Colors.red,
  ),
  GlobalConstants.sendmeCancelled => (
    label: 'App Cancelled',
    color: Colors.red,
  ),
  GlobalConstants.hotelAccepted || GlobalConstants.sendmeAccepted => (
    label: 'Accepted',
    color: AppColors.doneStatusColor,
  ),
  GlobalConstants.orderPicked => (label: 'Picked', color: Colors.grey),
  GlobalConstants.orderDelivered => (
    label: 'Delivered',
    color: AppColors.mainAppColor,
  ),
  GlobalConstants.riderGoing => (label: 'Going', color: Colors.blue),
  GlobalConstants.orderPrepared => (
    label: 'Prepared',
    color: AppColors.doneStatusColor,
  ),
  GlobalConstants.riderNotAssign => (
    label: 'Not Assigned',
    color: Colors.orange,
  ),
  _ => (label: 'Unknown', color: Colors.grey),
};

/// Returns the next status in the rider flow, or null if no action available.
/// For pickup-and-drop orders, the rider can also transition from ORDER_PENDING.
int? getNextRiderStatus(
  int currentStatus, {
  int isRiderGoing = 0,
  bool isPickUpAndDrop = false,
}) {
  const acceptedOrPrepared = {
    GlobalConstants.hotelAccepted,
    GlobalConstants.sendmeAccepted,
    GlobalConstants.orderPrepared,
  };

  // Statuses that allow "I Am Going" transition
  // Original app allows pending → going for ALL order types
  final goingStatuses = {...acceptedOrPrepared, GlobalConstants.orderPending};

  if (isRiderGoing == 0 && goingStatuses.contains(currentStatus)) {
    return GlobalConstants.riderGoing;
  }
  if (isRiderGoing == 1 &&
      (acceptedOrPrepared.contains(currentStatus) ||
          currentStatus == GlobalConstants.riderGoing)) {
    return GlobalConstants.orderPicked;
  }
  if (currentStatus == GlobalConstants.orderPicked) {
    return GlobalConstants.orderDelivered;
  }
  // Pickup-and-drop: if none of the above matched but order is picked, deliver
  if (isPickUpAndDrop &&
      currentStatus != GlobalConstants.orderDelivered &&
      isRiderGoing == 1 &&
      currentStatus == GlobalConstants.orderPicked) {
    return GlobalConstants.orderDelivered;
  }
  return null;
}

/// Returns the label for the next status action button, or null if no action available.
String? getNextStatusLabel(
  int currentStatus, {
  int isRiderGoing = 0,
  bool isPickUpAndDrop = false,
}) {
  final next = getNextRiderStatus(
    currentStatus,
    isRiderGoing: isRiderGoing,
    isPickUpAndDrop: isPickUpAndDrop,
  );
  if (next == null) return null;
  if (next == GlobalConstants.riderGoing) return 'I Am Going';
  if (next == GlobalConstants.orderPicked) return 'Picked';
  if (next == GlobalConstants.orderDelivered) return 'Delivered';
  return null;
}

/// Returns a human-readable label for the payment mode.
String getPaymentLabel(int paymentMode) => switch (paymentMode) {
  GlobalConstants.cash => 'Cash',
  GlobalConstants.onlinePayment => 'Online',
  GlobalConstants.directTransfer => 'Direct Transfer',
  _ => 'Unknown',
};
