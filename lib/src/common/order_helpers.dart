import 'package:flutter/material.dart';
import 'package:sendme_rider/src/common/colors.dart';
import 'package:sendme_rider/src/common/global_constants.dart';

/// Returns (label, color) for a given order status.
({String label, Color color}) getStatusBadge(int status) => switch (status) {
  GlobalConstants.orderPending => (
    label: 'Pending',
    color: AppColors.pendingStatusColor,
  ),
  GlobalConstants.userCancelled ||
  GlobalConstants.hotelCancelled ||
  GlobalConstants.sendmeCancelled => (label: 'Cancelled', color: Colors.red),
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
int? getNextRiderStatus(int currentStatus, {int isRiderGoing = 0}) {
  const acceptedOrPrepared = {
    GlobalConstants.hotelAccepted,
    GlobalConstants.sendmeAccepted,
    GlobalConstants.orderPrepared,
  };

  if (isRiderGoing == 0 && acceptedOrPrepared.contains(currentStatus)) {
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
  return null;
}

/// Returns the label for the next status action button, or null if no action available.
String? getNextStatusLabel(int currentStatus, {int isRiderGoing = 0}) {
  const acceptedOrPrepared = {
    GlobalConstants.hotelAccepted,
    GlobalConstants.sendmeAccepted,
    GlobalConstants.orderPrepared,
  };

  if (isRiderGoing == 0 && acceptedOrPrepared.contains(currentStatus)) {
    return 'I Am Going';
  }
  if (isRiderGoing == 1 &&
      (acceptedOrPrepared.contains(currentStatus) ||
          currentStatus == GlobalConstants.riderGoing)) {
    return 'Picked';
  }
  if (currentStatus == GlobalConstants.orderPicked) {
    return 'Delivered';
  }
  return null;
}

/// Returns a human-readable label for the payment mode.
String getPaymentLabel(int paymentMode) => switch (paymentMode) {
  GlobalConstants.cash => 'Cash',
  GlobalConstants.onlinePayment => 'Online',
  GlobalConstants.directTransfer => 'Direct Transfer',
  _ => 'Unknown',
};
