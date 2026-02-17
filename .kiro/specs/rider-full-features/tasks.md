# Implementation Plan: Rider Full Features

## Overview

Port complete rider functionality from the sendme customer app to the sendme_rider standalone app. Implementation follows an incremental approach: API/model layer first, then shared state, then each page, then order detail enhancements.

## Tasks

- [x] 1. Add Review model and update RiderOrder model
  - [x] 1.1 Create Review model at `sendme_rider/lib/src/models/review.dart`
    - Define `Review` class with fields: id (int), userId (int), hotelId (int), rating (double), userName (String), comment (String), reply (String), dateTime (String)
    - Add `fromJson` factory with safe parsing (matching RiderOrder pattern: `_parseInt`, `_parseDouble`, `_parseString`)
    - Add `toJson` method
    - Add `const` constructor with defaults
    - _Requirements: 5.1, 5.4_
  - [x] 1.2 Add `isRiderGoing` field to RiderOrder model
    - Add `final int isRiderGoing` field with default 0
    - Parse from JSON key `isRiderGoing` in `fromJson`
    - Include in `toJson` and `copyWith`
    - _Requirements: 7.1_
  - [ ]\* 1.3 Write property test for Review model JSON round-trip
    - **Property 2: Review model JSON round-trip with safe parsing**
    - **Validates: Requirements 5.1, 5.4**
  - [ ]\* 1.4 Write property test for RiderOrder isRiderGoing round-trip
    - **Property 3: RiderOrder isRiderGoing round-trip**
    - **Validates: Requirements 7.1**

- [x] 2. Add API endpoint and service methods
  - [x] 2.1 Add `getReports` endpoint to `sendme_rider/lib/src/api/api_path.dart`
    - Add: `static final String getReports = '${slsServerPath}GetReports?';`
    - _Requirements: 3.1_
  - [x] 2.2 Add `getRiderReportSummary` method to `sendme_rider/lib/src/api/rider_api_service.dart`
    - GET request to `ApiPath.getTotalBillAmountForReports` (already exists in api_path.dart as `getTotalBillAmountForReports` — need to add this endpoint if missing, otherwise use existing `getRiderEarnings` path — verify and use the correct one)
    - Note: The endpoint is `GetTotalBillAmountForReport` — check if it exists in api_path.dart, if not add it
    - Parameters: paymentMode, fromDate, toDate, outletId=0, riderId, deliveryType=0, deliveryManageByType=0, pageIndex=0, userType=rider, isAdmin=1
    - Return `List<Map<String, dynamic>>` from `data['Data']`
    - _Requirements: 3.2, 3.4_
  - [x] 2.3 Add `getRiderReport` method to `sendme_rider/lib/src/api/rider_api_service.dart`
    - GET request to `ApiPath.getReports`
    - Parameters: paymentMode, fromDate, toDate, outletId=0, riderId, deliveryType=0, deliveryManageByType=0, pageIndex, userType=rider, isAdmin=1
    - Return `({List<Map<String, dynamic>> entries, int totalPages})`
    - _Requirements: 3.3, 3.5_
  - [x] 2.4 Add `getRiderReviews` method to `sendme_rider/lib/src/api/rider_api_service.dart`
    - POST request to `ApiPath.getRatingsAndReviewsForRider`
    - Parameters: riderId, pagination (JSON string, default '{}'), userType=rider, deviceId, deviceType, version
    - Return `({List<Review> reviews, Map<String, dynamic>? pagination, double averageRating})`
    - Parse `data['Data']` as list of Review, `data['pagination']` as cursor, `data['averageRating']` as double
    - _Requirements: 5.2, 5.3_

- [x] 3. Update order_helpers.dart for isRiderGoing status flow
  - [x] 3.1 Update `getNextRiderStatus` to accept `isRiderGoing` parameter
    - Add `{int isRiderGoing = 0}` named parameter
    - Logic: if isRiderGoing==0 and status is accepted/going/prepared → return riderGoing (9)
    - If isRiderGoing==1 and status is accepted/going/prepared → return orderPicked (7)
    - If status is orderPicked → return orderDelivered (8)
    - If status is delivered/cancelled/pending → return null
    - _Requirements: 7.9, 7.2, 7.3, 7.4, 7.5, 7.6, 7.7_
  - [x] 3.2 Update `getNextStatusLabel` to accept `isRiderGoing` parameter
    - Add `{int isRiderGoing = 0}` named parameter
    - Logic mirrors getNextRiderStatus: "I Am Going", "Picked", "Delivered", or null
    - _Requirements: 7.10_
  - [ ]\* 3.3 Write property test for status flow correctness
    - **Property 4: Status flow correctness**
    - **Validates: Requirements 7.2, 7.3, 7.4, 7.5, 7.6, 7.7, 7.9, 7.10**

- [x] 4. Checkpoint - Ensure models, API methods, and helpers compile
  - Ensure all tests pass, ask the user if questions arise.

- [x] 5. Lift shared rider state to RiderBottomNav
  - [x] 5.1 Modify `sendme_rider/lib/src/ui/navigation/rider_bottom_nav.dart`
    - Add `RiderProfile? _rider`, `bool _isLoading = true`, `String? _error` state
    - In `initState`, call `_loadRider()` which fetches RiderProfile via `RiderApiService.fetchRiderProfile()` using saved mobile from PreferencesHelper
    - While loading, show centered CircularProgressIndicator
    - On error, show error message with retry button
    - On success, build pages passing riderId and RiderProfile
    - Add `_onRiderUpdated(RiderProfile)` callback for ProfilePage to propagate changes
    - Pass `riderId: _rider!.id` to ReportPage and ReviewPage
    - Pass `rider: _rider!, onRiderUpdated: _onRiderUpdated` to ProfilePage
    - Pass `riderName: _rider!.name, riderProfile: _rider` to OrdersPage (OrdersPage can skip its own \_loadRider if profile is provided)
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5_
  - [x] 5.2 Update OrdersPage to accept optional RiderProfile parameter
    - Add `final RiderProfile? riderProfile` parameter
    - If riderProfile is provided, skip `_loadRider()` and use it directly
    - This avoids the duplicate SwitchUser API call
    - _Requirements: 1.2_

- [x] 6. Implement Report page
  - [x] 6.1 Implement full ReportPage at `sendme_rider/lib/src/ui/report/report_page.dart`
    - Accept `final int riderId` constructor parameter
    - State: selectedStartDate (1st of month), selectedEndDate (today), selectedPaymentMode (0), summaryList, reportList, pageIndex, totalPages, isLoadingSummary, isLoadingList, isLoadingMore
    - Date pickers using `showDatePicker` (Flutter built-in) for start and end dates
    - Payment mode dropdown with Both/Cash/Online Payment options
    - On filter change: call `getRiderReportSummary` and `getRiderReport` with reset pageIndex
    - Summary section: ListView.builder over summaryList showing TotalBillAmount, DeliveryChargeAmount, GSTOnDeliveryCharge, GSTOnBillAmount per currency
    - Table header row: Order ID, Date, Delivery Charge, Bill, GST
    - Table body: ListView.builder with scroll listener for pagination
    - Format dates from `MM/dd/yyyy HH:mm:ss` to `dd-MM-yyyy`
    - Loading indicators for summary and list
    - Empty state "No orders" message
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.7, 2.8, 2.9_

- [x] 7. Implement Review page
  - [x] 7.1 Implement full ReviewPage at `sendme_rider/lib/src/ui/review/review_page.dart`
    - Accept `final int riderId` constructor parameter
    - State: reviewList, averageRating, paginationCursor, isLoading, isLoadingMore, scrollController
    - On init: call `getRiderReviews` with empty pagination
    - Average rating display: star icon + numeric value in a rounded container at top
    - Review list: ListView.builder showing userName, star rating (use Row of Icon widgets), decoded comment, formatted date
    - Base64 decode comments: `utf8.decode(base64.decode(comment.replaceAll('\n', '')))` with try-catch fallback to empty string
    - Date formatting: parse `yyyy-MM-dd` format, display as `dd MMM yyyy`
    - Scroll listener for pagination: when at bottom and cursor is not empty, fetch next page
    - Shimmer loading state for initial load (reuse OrderShimmer or simple shimmer containers)
    - Empty state "No reviews" message
    - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 4.6, 4.7_
  - [ ]\* 7.2 Write property test for base64 comment round-trip
    - **Property 1: Review comment base64 round-trip**
    - **Validates: Requirements 4.4**

- [x] 8. Implement Profile page
  - [x] 8.1 Implement full ProfilePage at `sendme_rider/lib/src/ui/profile/profile_page.dart`
    - Accept `final RiderProfile rider` and `final ValueChanged<RiderProfile> onRiderUpdated` constructor parameters
    - Profile image: CircleAvatar with NetworkImage from rider.imageUrl, fallback to person icon
    - Display: rider name, email, contact, average rating with star
    - Availability toggle: Switch widget, available (status=0) / unavailable (status=1)
    - On toggle: call `RiderApiService.updateRiderAvailability`, on success call `onRiderUpdated` with updated profile, on failure revert and show snackbar
    - Logout button: clear PreferencesHelper, navigate to LoginPage with `pushAndRemoveUntil`
    - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5, 6.6_

- [x] 9. Enhance OrderDetailPage with isRiderGoing logic
  - [x] 9.1 Update `sendme_rider/lib/src/ui/orders/order_detail_page.dart`
    - Use updated `getNextRiderStatus(order.orderStatus, isRiderGoing: order.isRiderGoing)` and `getNextStatusLabel(order.orderStatus, isRiderGoing: order.isRiderGoing)`
    - Add delivered message: when orderStatus == orderDelivered, show green "This order is processed" container instead of action button
    - Add cancelled message: when orderStatus is any cancelled status, show red "This order is cancelled" container instead of action button
    - Hide action button for pending orders (orderStatus == orderPending)
    - After successful status update, re-fetch order detail to get updated isRiderGoing and deliveredAt from API response
    - _Requirements: 7.2, 7.3, 7.4, 7.5, 7.6, 7.7, 7.8_

- [x] 10. Update barrel file exports
  - [x] 10.1 Add Review model export to `sendme_rider/lib/flutter_project_imports.dart`
    - Add: `export 'package:sendme_rider/src/models/review.dart';`
    - _Requirements: 8.1_

- [x] 11. Final checkpoint - Ensure all code compiles and integrates
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- The implementation uses Dart/Flutter with the existing RiderApiService pattern (http.Client, \_get/\_post)
- All new pages follow existing conventions: AppColors.mainAppColor, AssetsFont font families, modern Dart 3 syntax
- Report page uses Flutter's built-in showDatePicker instead of the customer app's flutter_datetime_picker_plus dependency
- Property tests validate the pure logic (models, helpers) rather than UI behavior
