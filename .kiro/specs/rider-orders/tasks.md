# Implementation Plan: Rider Orders

## Overview

Build the full rider orders feature for sendme_rider: data models, API service, orders list page with tabs/pagination, and order detail page with status updates and external actions. All API calls use direct http.Client. The implementation follows the existing white-label architecture and coding conventions.

## Tasks

- [x] 1. Add intl package and create data models
  - [x] 1.1 Add `intl` package to `sendme_rider/pubspec.yaml`
    - Add `intl: ^0.19.0` under dependencies
    - _Requirements: 7.3_

  - [x] 1.2 Create `RiderOrder` model at `sendme_rider/lib/src/models/rider_order.dart`
    - Define all fields: orderId, orderStatus, paymentMode, paymentType, hotelName, hotelId, hotelAddress, userName, userArea, contactNo, mobile, orderOn, deliveryOn, deliveredAt, totalBill, deliveryCharge, currency, riderId, riderName, isPickUpAndDropOrder, deliveryType, outletLatitude, outletLongitude, userLatitude, userLongitude, slot, remarks
    - Implement `fromJson` with null-safe `_parseInt`/`_parseDouble` helpers (same pattern as UserModel)
    - Implement `toJson` for serialization
    - Implement `copyWith` for immutable status updates
    - _Requirements: 1.1, 1.2, 1.3_

  - [x] 1.3 Create `RiderProfile` model at `sendme_rider/lib/src/models/rider_profile.dart`
    - Define fields: id, name, email, contact, status, latitude, longitude, imageUrl, averageRatings
    - Implement `fromJson`/`toJson` with null-safe parsing helpers
    - Implement `copyWith` for immutable availability toggle
    - _Requirements: 1.4, 1.5, 1.6_

  - [ ]\* 1.4 Write property test for RiderOrder round-trip serialization
    - **Property 1: RiderOrder round-trip serialization**
    - Generate 100 random RiderOrder JSON maps with mixed types, verify fromJson → toJson → fromJson equivalence
    - Create test file at `sendme_rider/test/models/rider_order_test.dart`
    - **Validates: Requirements 1.2, 1.3**

  - [ ]\* 1.5 Write property test for RiderProfile round-trip serialization
    - **Property 2: RiderProfile round-trip serialization**
    - Generate 100 random RiderProfile JSON maps with mixed types, verify fromJson → toJson → fromJson equivalence
    - Create test file at `sendme_rider/test/models/rider_profile_test.dart`
    - **Validates: Requirements 1.5, 1.6**

- [x] 2. Create API service and order helpers
  - [x] 2.1 Create `ApiException` class and `RiderApiService` at `sendme_rider/lib/src/api/rider_api_service.dart`
    - Implement `_post` helper with http.Client, JSON encoding, Status check, error handling
    - Implement `getRiderOrders` with all required params (pageIndex, pagination, dateType, fromDate, toDate, outletId, riderId, isAdmin, userType, isRider, deviceId, deviceType, version)
    - Implement `getRiderOrderDetail` with orderId param
    - Implement `updateOrderStatus` with orderId and newStatus params
    - Implement `updateRiderAvailability` with rider profile fields and status
    - Accept http.Client via constructor for testability
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.7, 2.8_

  - [x] 2.2 Create order status helpers at `sendme_rider/lib/src/common/order_helpers.dart`
    - Implement `getStatusBadge(int status)` returning `({String label, Color color})`
    - Implement `getNextRiderStatus(int currentStatus)` returning `int?`
    - Implement `getNextStatusLabel(int currentStatus)` returning `String?`
    - Implement `getPaymentLabel(int paymentMode)` returning String
    - _Requirements: 5.7, 6.6, 6.7, 6.8, 6.9_

  - [ ]\* 2.3 Write property tests for order helpers
    - **Property 5: Status badge mapping correctness**
    - **Property 6: Next rider status mapping correctness**
    - Test all defined status codes for correct badge (label, color) and next status mapping
    - Test random integers outside defined set return sensible defaults
    - Create test file at `sendme_rider/test/common/order_helpers_test.dart`
    - **Validates: Requirements 5.7, 6.6, 6.7, 6.8, 6.9**

  - [ ]\* 2.4 Write unit tests for RiderApiService
    - **Property 3: API success response parsing**
    - **Property 4: API error response propagation**
    - Mock http.Client to test success parsing (100 random Data arrays), error propagation, network error handling
    - Test correct URL and params for each endpoint
    - Create test file at `sendme_rider/test/api/rider_api_service_test.dart`
    - **Validates: Requirements 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.7, 2.8**

- [x] 3. Checkpoint - Models and API service
  - Ensure all tests pass, ask the user if questions arise.

- [x] 4. Build Orders page UI
  - [x] 4.1 Create `RiderProfileHeader` widget at `sendme_rider/lib/src/ui/orders/widgets/rider_profile_header.dart`
    - Display rider name, avatar placeholder (first letter in colored circle), availability status label
    - Availability toggle button (power icon) that calls onToggle callback
    - Use AppColors, AssetsFont for styling
    - _Requirements: 3.1, 3.2_

  - [x] 4.2 Create `OrderCard` widget at `sendme_rider/lib/src/ui/orders/widgets/order_card.dart`
    - Display hotelName, #orderId(paymentType), userName, userArea, formatted orderOn, deliveryOn, deliveredAt, status badge, totalBill+currency
    - Use `getStatusBadge` for color-coded status
    - Use `intl` DateFormat for date formatting
    - onTap callback for navigation
    - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 5.6, 5.7, 5.8, 5.9_

  - [x] 4.3 Create `OrderShimmer` widget at `sendme_rider/lib/src/ui/orders/widgets/order_shimmer.dart`
    - Skeleton loading placeholder matching OrderCard layout
    - _Requirements: 4.7_

  - [x] 4.4 Rewrite `OrdersPage` at `sendme_rider/lib/src/ui/orders/orders_page.dart`
    - Replace placeholder with full implementation
    - Load rider from PreferencesHelper on init
    - RiderProfileHeader at top with availability toggle (calls RiderApiService.updateRiderAvailability)
    - TabBar with "Today Orders" / "All Orders" tabs
    - RefreshIndicator wrapping order list for pull-to-refresh
    - ScrollController for infinite scroll pagination
    - Loading state → shimmer, empty state → illustration + message, error state → snackbar
    - Tab switch resets pagination and fetches fresh
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 4.1, 4.2, 4.3, 4.4, 4.5, 4.6, 4.7, 4.8_

  - [ ]\* 4.5 Write widget test for OrderCard field display
    - **Property 7: OrderCard displays all required fields**
    - Generate random RiderOrder instances, pump OrderCard, verify all expected text in widget tree
    - Create test file at `sendme_rider/test/ui/order_card_test.dart`
    - **Validates: Requirements 5.1, 5.2, 5.3, 5.4, 5.8**

- [x] 5. Build Order Detail page
  - [x] 5.1 Create `OrderDetailPage` at `sendme_rider/lib/src/ui/orders/order_detail_page.dart`
    - Accept orderId, fetch full detail from RiderApiService.getRiderOrderDetail on init
    - Display outlet info section (name, address, coordinates)
    - Display customer info section (name, area, contact)
    - Display order metadata section (orderId, paymentType, orderOn, deliveryOn, totalBill, deliveryCharge, remarks)
    - Prominent status badge using getStatusBadge
    - Status update action button using getNextRiderStatus/getNextStatusLabel (hidden for terminal statuses)
    - Call customer button → launch tel: URI
    - Navigate to outlet button → launch Google Maps URL with outlet coordinates
    - Navigate to customer button → launch Google Maps URL with customer coordinates
    - Loading state, error snackbar on status update failure
    - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5, 6.6, 6.7, 6.8, 6.9, 6.10, 6.11, 6.12, 6.13, 6.14_

- [x] 6. Wire everything together and update barrel file
  - [x] 6.1 Update `sendme_rider/lib/flutter_project_imports.dart`
    - Add exports for: rider_order.dart, rider_profile.dart, rider_api_service.dart, order_helpers.dart, order_detail_page.dart, rider_profile_header.dart, order_card.dart, order_shimmer.dart
    - _Requirements: 7.1, 7.2_

  - [x] 6.2 Update `OrdersPage` constructor to work with `RiderBottomNav`
    - Ensure OrdersPage still accepts riderName from RiderBottomNav
    - Verify navigation from OrderCard to OrderDetailPage works
    - Verify back navigation from OrderDetailPage refreshes order list if status changed
    - _Requirements: 5.9, 6.1_

- [x] 7. Final checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- All API calls use direct http.Client (NOT GlobalConstants.apiCall)
- Use modern Dart 3 patterns: const, final, non-nullable, switch expressions, pattern matching
- Use `Color.withValues()` not deprecated `withOpacity()`
- Follow existing import pattern: `flutter_imports.dart` + `flutter_project_imports.dart`
- Property tests use custom random generators with 100+ iterations each
