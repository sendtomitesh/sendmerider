# Requirements Document

## Introduction

The rider-orders feature replaces the current placeholder Orders page in the sendme_rider app with a fully functional order management system. Riders can view their assigned orders (today or all), see order details, update order status through the delivery flow (Going → Picked → Delivered), toggle their availability, and contact customers or navigate to locations. The feature uses direct HTTP calls (not the legacy GlobalConstants.apiCall pattern) and follows the existing white-label architecture.

## Glossary

- **Rider_App**: The sendme_rider Flutter application used by delivery riders
- **Orders_Page**: The main screen showing the rider's order list with profile header and tab bar
- **Order_Card**: A list item widget displaying summary information for a single order
- **Order_Detail_Page**: The full-detail screen for a single order with status update actions
- **Rider_API_Service**: The HTTP service class responsible for all rider-related API calls
- **RiderOrder_Model**: The data model representing a single order with rider-relevant fields
- **RiderProfile_Model**: The data model representing the rider's profile and availability status
- **Order_Status**: An integer code representing the current state of an order (Pending=1, Cancelled=2/3/4, Accepted=5/6, Picked=7, Delivered=8, Going=9, NotAssigned=10, Prepared=11)
- **Availability_Status**: The rider's current availability (0=available, 1=unavailable)
- **Pagination_Cursor**: A server-provided opaque object used for cursor-based pagination of order lists
- **Status_Badge**: A color-coded label on an order card indicating the current order status

## Requirements

### Requirement 1: Rider Order Data Model

**User Story:** As a developer, I want a clean RiderOrder model with only rider-relevant fields, so that the app handles order data efficiently without the bloated 90+ field model from the customer app.

#### Acceptance Criteria

1. THE RiderOrder_Model SHALL contain fields: orderId, orderStatus, paymentMode, paymentType, hotelName, hotelId, hotelAddress, userName, userArea, contactNo, mobile, orderOn, deliveryOn, deliveredAt, totalBill, deliveryCharge, currency, riderId, riderName, isPickUpAndDropOrder, deliveryType, outletLatitude, outletLongitude, userLatitude, userLongitude, slot, and remarks
2. WHEN the RiderOrder_Model is constructed from a JSON map, THE RiderOrder_Model SHALL parse all fields using null-safe accessors and type coercion for int and double values
3. WHEN the RiderOrder_Model is serialized to a JSON map, THE RiderOrder_Model SHALL produce a map that, when parsed back, yields an equivalent RiderOrder_Model instance (round-trip consistency)
4. THE RiderProfile_Model SHALL contain fields: id, name, email, contact, status, latitude, longitude, imageUrl, and averageRatings
5. WHEN the RiderProfile_Model is constructed from a JSON map, THE RiderProfile_Model SHALL parse all fields using null-safe accessors and type coercion for int and double values
6. WHEN the RiderProfile_Model is serialized to a JSON map, THE RiderProfile_Model SHALL produce a map that, when parsed back, yields an equivalent RiderProfile_Model instance (round-trip consistency)

### Requirement 2: Rider API Service

**User Story:** As a developer, I want a clean HTTP service class for rider API calls, so that the app uses direct http.Client calls instead of the legacy GlobalConstants.apiCall pattern.

#### Acceptance Criteria

1. THE Rider_API_Service SHALL use http.Client for all network requests with Content-Type application/json headers
2. WHEN fetching rider orders, THE Rider_API_Service SHALL POST to ApiPath.getRiderOrders with parameters: pageIndex, pagination, dateType (0=today, 1=all), fromDate, toDate, outletId, riderId, isAdmin, userType, isRider, deviceId, deviceType, and version
3. WHEN the API returns a response with Status=1, THE Rider_API_Service SHALL parse the Data array into a list of RiderOrder_Model instances and return the TotalPage count and pagination cursor
4. IF the API returns a response with Status other than 1, THEN THE Rider_API_Service SHALL return an error result containing the server Message
5. IF a network error occurs during an API call, THEN THE Rider_API_Service SHALL catch the exception and return an error result with a descriptive message
6. WHEN fetching order detail, THE Rider_API_Service SHALL POST to ApiPath.getRiderOrderDetail with the orderId and return a RiderOrder_Model
7. WHEN updating order status, THE Rider_API_Service SHALL POST to ApiPath.updateOrderStatus with orderId and the new status value and return a success or error result
8. WHEN updating rider availability, THE Rider_API_Service SHALL POST to ApiPath.updateRider with rider profile fields and the new status value (0=available, 1=unavailable)

### Requirement 3: Orders Page — Rider Profile Header

**User Story:** As a rider, I want to see my profile summary and toggle my availability at the top of the orders page, so that I can quickly manage my status.

#### Acceptance Criteria

1. WHEN the Orders_Page loads, THE Orders_Page SHALL display a header showing the rider's name and an avatar placeholder (first letter of name in a colored circle)
2. WHEN the Orders_Page loads, THE Orders_Page SHALL display the rider's current availability status as a text label ("Available" or "Unavailable")
3. WHEN the rider taps the availability toggle, THE Orders_Page SHALL call the Rider_API_Service to update the rider's availability status
4. WHEN the availability update API call succeeds, THE Orders_Page SHALL update the displayed availability status to reflect the new value
5. IF the availability update API call fails, THEN THE Orders_Page SHALL display a snackbar with the error message and revert the toggle to its previous state

### Requirement 4: Orders Page — Tab Bar and Order List

**User Story:** As a rider, I want to switch between today's orders and all orders with a tab bar, so that I can focus on current deliveries or review past ones.

#### Acceptance Criteria

1. WHEN the Orders_Page loads, THE Orders_Page SHALL display a tab bar with two tabs: "Today Orders" and "All Orders"
2. WHEN the "Today Orders" tab is selected, THE Orders_Page SHALL fetch orders with dateType=0 and display only today's orders
3. WHEN the "All Orders" tab is selected, THE Orders_Page SHALL fetch orders with dateType=1 and display all orders
4. WHEN the rider switches tabs, THE Orders_Page SHALL reset pagination and fetch a fresh list for the selected tab
5. WHEN the rider pulls down on the order list, THE Orders_Page SHALL refresh the current tab's order list from the API
6. WHEN the rider scrolls to the bottom of the order list and more pages are available, THE Orders_Page SHALL fetch the next page and append the results to the list
7. WHILE orders are being fetched for the first time, THE Orders_Page SHALL display a shimmer/skeleton loading placeholder
8. WHEN the API returns an empty order list, THE Orders_Page SHALL display an empty state with an illustration and a descriptive message

### Requirement 5: Order Card Display

**User Story:** As a rider, I want each order card to show key delivery information at a glance, so that I can quickly assess my assignments.

#### Acceptance Criteria

1. THE Order_Card SHALL display the outlet name (hotelName) as the primary title
2. THE Order_Card SHALL display the order ID prefixed with "#" and the payment type in parentheses
3. THE Order_Card SHALL display the customer name (userName) and delivery area (userArea)
4. THE Order_Card SHALL display the order date (orderOn) formatted as a readable date-time string
5. WHEN the order has a deliveryOn value, THE Order_Card SHALL display the scheduled delivery date
6. WHEN the order has a deliveredAt value, THE Order_Card SHALL display the actual delivery timestamp
7. THE Order_Card SHALL display a Status_Badge with color coding: Pending(1)=amber, Cancelled(2,3,4)=red, Accepted(5,6)=green, Picked(7)=grey, Delivered(8)=brand color, Going(9)=blue, Prepared(11)=green
8. THE Order_Card SHALL display the total bill amount with the currency symbol
9. WHEN the rider taps an Order_Card, THE Rider_App SHALL navigate to the Order_Detail_Page for that order

### Requirement 6: Order Detail Page

**User Story:** As a rider, I want to see full order details and take actions like updating status, calling the customer, or navigating to locations, so that I can complete deliveries efficiently.

#### Acceptance Criteria

1. WHEN the Order_Detail_Page loads, THE Order_Detail_Page SHALL fetch and display the full order detail from the API
2. THE Order_Detail_Page SHALL display outlet information: name, address, and location coordinates
3. THE Order_Detail_Page SHALL display customer information: name, area, and contact number
4. THE Order_Detail_Page SHALL display order metadata: order ID, payment type, order date, delivery date, total bill, delivery charge, and remarks
5. THE Order_Detail_Page SHALL display the current order status as a prominent Status_Badge
6. WHEN the order status is Accepted (5 or 6), THE Order_Detail_Page SHALL display a "Going" action button to update status to riderGoing (9)
7. WHEN the order status is riderGoing (9), THE Order_Detail_Page SHALL display a "Picked" action button to update status to orderPicked (7)
8. WHEN the order status is orderPicked (7), THE Order_Detail_Page SHALL display a "Delivered" action button to update status to orderDelivered (8)
9. WHEN the order status is orderDelivered (8) or any cancelled status (2, 3, 4), THE Order_Detail_Page SHALL hide the status update action buttons
10. WHEN the rider taps a status update button, THE Order_Detail_Page SHALL call the Rider_API_Service to update the order status and refresh the displayed status on success
11. IF a status update API call fails, THEN THE Order_Detail_Page SHALL display a snackbar with the error message and retain the current status
12. WHEN the rider taps the call customer button, THE Order_Detail_Page SHALL launch the phone dialer with the customer's contact number
13. WHEN the rider taps the navigate-to-outlet button, THE Order_Detail_Page SHALL open Google Maps with directions to the outlet coordinates
14. WHEN the rider taps the navigate-to-customer button, THE Order_Detail_Page SHALL open Google Maps with directions to the customer coordinates

### Requirement 7: Barrel File and Package Updates

**User Story:** As a developer, I want all new files exported through the barrel file and the intl package added, so that the project stays consistent and date formatting works.

#### Acceptance Criteria

1. WHEN new model or service files are created, THE Rider_App SHALL export them from flutter_project_imports.dart
2. WHEN new UI files are created, THE Rider_App SHALL export them from flutter_project_imports.dart
3. THE Rider_App SHALL include the intl package in pubspec.yaml for date formatting
