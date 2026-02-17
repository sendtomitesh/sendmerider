# Requirements Document

## Introduction

Port the complete rider functionality from the sendme customer app's rider section to the sendme_rider standalone app. The rider app already has basic orders, order detail, and bottom navigation working. This spec covers implementing the three placeholder pages (Report, Review, Profile), enhancing the order detail page with the `isRiderGoing` status flow, lifting shared rider state to the navigation level, and adding the necessary API methods and models.

## Glossary

- **Rider_App**: The sendme_rider standalone Flutter application for delivery riders
- **RiderApiService**: The centralized API service class that handles all HTTP calls using `http.Client` with `_authHeaders()`, `_extraGetParams()`, `_extraPostParams()`, `_post()`, and `_get()` methods
- **RiderBottomNav**: The bottom navigation widget that hosts the four tab pages (Orders, Report, Review, Profile)
- **RiderProfile**: The model representing a rider's profile data including id, name, email, contact, status, coordinates, imageUrl, and averageRatings
- **RiderOrder**: The model representing an order assigned to a rider
- **Review_Model**: A data model representing a single customer review with id, userId, hotelId, rating, userName, comment, reply, and dateTime fields
- **Report_Summary**: The aggregated totals returned by the GetTotalBillAmountForReport API, grouped per currency, containing TotalBillAmount, DeliveryChargeAmount, GSTOnDeliveryCharge, and GSTOnBillAmount
- **Report_Entry**: A single order row in the report list returned by the GetReports API, containing orderId, orderOn, deliveryCharge, totalBill, and commissionOnDeliveryCharge (GST)
- **PreferencesHelper**: The utility class for reading/writing shared preferences including saved rider data
- **Order_Status_Flow**: The sequence of status transitions a rider performs: Accepted → Going → Picked → Delivered, governed by the `isRiderGoing` field from the API
- **Pagination_Cursor**: A JSON object returned by the API that tracks the current position in a paginated result set, passed back in subsequent requests to fetch the next page

## Requirements

### Requirement 1: Shared Rider State via Bottom Navigation

**User Story:** As a rider, I want my rider profile to be loaded once at the navigation level, so that all pages (Orders, Report, Review, Profile) share the same rider data without redundant API calls.

#### Acceptance Criteria

1. WHEN the RiderBottomNav widget initializes, THE Rider_App SHALL fetch the RiderProfile via the SwitchUser API using the saved mobile number from PreferencesHelper
2. WHEN the RiderProfile is successfully loaded, THE RiderBottomNav SHALL pass the riderId and RiderProfile to all child pages (Orders, Report, Review, Profile)
3. WHILE the RiderProfile is loading, THE RiderBottomNav SHALL display a loading indicator instead of the child pages
4. IF the RiderProfile fetch fails, THEN THE RiderBottomNav SHALL display an error message with a retry option
5. WHEN the rider profile data changes (e.g., availability toggle), THE RiderBottomNav SHALL propagate the updated RiderProfile to all child pages

### Requirement 2: Report Page

**User Story:** As a rider, I want to view my delivery reports filtered by date range and payment mode, so that I can track my earnings and order history.

#### Acceptance Criteria

1. WHEN the Report page loads, THE Rider_App SHALL display a date range picker defaulting to the 1st of the current month as start date and today as end date
2. WHEN the Report page loads, THE Rider_App SHALL display a payment mode dropdown with options: Both (value 0), Cash (value 1), Online Payment (value 2), defaulting to Both
3. WHEN the rider selects a start date, end date, or payment mode, THE Rider_App SHALL fetch the report summary from the GetTotalBillAmountForReport API and the report list from the GetReports API using the selected filters
4. WHEN the report summary is returned, THE Rider_App SHALL display per-currency totals for: Total Bill Amount, Delivery Charge Amount, GST on Delivery Charges, and GST on Bill Amount (if present)
5. WHEN the report list is returned, THE Rider_App SHALL display a table with columns: Order ID, Date, Delivery Charge, Bill, GST
6. WHEN the rider scrolls to the bottom of the report list and more pages exist, THE Rider_App SHALL fetch the next page and append the results to the existing list
7. WHILE the report summary is loading, THE Rider_App SHALL display a loading indicator next to each summary field
8. WHILE the report list is loading for the first time, THE Rider_App SHALL display a centered loading indicator
9. IF the report list API returns no data, THEN THE Rider_App SHALL display a "No orders" message

### Requirement 3: Report API Integration

**User Story:** As a rider, I want the report page to communicate with the backend APIs, so that I can see accurate report data.

#### Acceptance Criteria

1. THE Rider_App SHALL add a `getReports` endpoint to api_path.dart with the value `'${slsServerPath}GetReports?'`
2. THE RiderApiService SHALL provide a `getRiderReportSummary` method that performs a GET request to the GetTotalBillAmountForReport endpoint with parameters: paymentMode, fromDate, toDate, outletId=0, riderId, deliveryType=0, deliveryManageByType=0, pageIndex=0, userType=rider, isAdmin=1
3. THE RiderApiService SHALL provide a `getRiderReport` method that performs a GET request to the GetReports endpoint with parameters: paymentMode, fromDate, toDate, outletId=0, riderId, deliveryType=0, deliveryManageByType=0, pageIndex, userType=rider, isAdmin=1
4. WHEN the getRiderReportSummary method receives a successful response, THE RiderApiService SHALL return the Data field as a list of summary objects containing Currency, TotalBillAmount, DeliveryChargeAmount, GSTOnDeliveryCharge, and GSTOnBillAmount
5. WHEN the getRiderReport method receives a successful response, THE RiderApiService SHALL return the Data field as a list of report entries and the TotalPage count for pagination

### Requirement 4: Review Page

**User Story:** As a rider, I want to view my customer reviews and average rating, so that I can understand my service quality.

#### Acceptance Criteria

1. WHEN the Review page loads, THE Rider_App SHALL fetch reviews from the GetRatingsAndReviewsForRider API using the riderId
2. WHEN reviews are returned, THE Rider_App SHALL display the average rating with a star icon and numeric value at the top of the page
3. WHEN reviews are returned, THE Rider_App SHALL display each review showing: userName, star rating, decoded comment text, and formatted date
4. WHEN a review comment is received from the API, THE Rider_App SHALL decode the comment from base64 encoding before displaying
5. WHEN the rider scrolls to the bottom of the review list and the pagination cursor is not empty, THE Rider_App SHALL fetch the next page of reviews using the cursor and append results to the existing list
6. WHILE reviews are loading for the first time, THE Rider_App SHALL display shimmer placeholder widgets
7. IF the review list is empty, THEN THE Rider_App SHALL display a "No reviews" message

### Requirement 5: Review API Integration and Model

**User Story:** As a rider, I want the review data to be properly modeled and fetched, so that reviews display correctly.

#### Acceptance Criteria

1. THE Rider_App SHALL define a Review model at `sendme_rider/lib/src/models/review.dart` with fields: id (int), userId (int), hotelId (int), rating (double), userName (String), comment (String), reply (String), dateTime (String)
2. THE RiderApiService SHALL provide a `getRiderReviews` method that performs a POST request to the GetRatingsAndReviewsForRider endpoint with parameters: riderId, pagination (JSON string), userType, deviceId, deviceType, version
3. WHEN the getRiderReviews method receives a successful response, THE RiderApiService SHALL return the parsed list of Review objects, the pagination cursor, and the averageRating value
4. WHEN the Review model parses JSON, THE Review model SHALL handle null and type-mismatched values using safe parsing (matching the existing RiderOrder parsing pattern)

### Requirement 6: Profile Page

**User Story:** As a rider, I want to view my profile information and manage my account, so that I can see my details and log out when needed.

#### Acceptance Criteria

1. WHEN the Profile page loads, THE Rider_App SHALL display the rider's profile image (from imageUrl or a placeholder icon if empty)
2. WHEN the Profile page loads, THE Rider_App SHALL display the rider's name, email, contact number, and average rating
3. THE Profile page SHALL display an availability toggle switch showing the rider's current availability status (available when status=0, unavailable when status=1)
4. WHEN the rider toggles availability on the Profile page, THE Rider_App SHALL call the UpdateRider API and update the displayed status upon success
5. WHEN the rider taps the logout button, THE Rider_App SHALL clear all saved preferences and navigate to the login page, replacing the navigation stack
6. IF the availability toggle API call fails, THEN THE Rider_App SHALL revert the toggle to its previous state and display an error message

### Requirement 7: Order Detail Enhancement with isRiderGoing

**User Story:** As a rider, I want the order detail page to show the correct status action button based on the isRiderGoing field, so that I follow the proper delivery workflow.

#### Acceptance Criteria

1. THE RiderOrder model SHALL include an `isRiderGoing` integer field parsed from the API response JSON key `isRiderGoing`, defaulting to 0
2. WHEN the order detail API returns `isRiderGoing` equal to 0, THE Rider_App SHALL display an "I Am Going" button that sets the status to RIDER_GOING (9)
3. WHEN the order detail API returns `isRiderGoing` equal to 1 AND the order status is RIDER_GOING, ACCEPTED, or PREPARED, THE Rider_App SHALL display a "Picked" button that sets the status to ORDER_PICKED (7)
4. WHEN the order status is ORDER_PICKED (7), THE Rider_App SHALL display a "Delivered" button that sets the status to ORDER_DELIVERED (8)
5. WHEN the order status is ORDER_DELIVERED, THE Rider_App SHALL display a "This order is processed" message in green and hide the status update button
6. WHEN the order status is any cancelled status (USER_CANCELLED, HOTEL_CANCELLED, SENDME_CANCELLED), THE Rider_App SHALL display a "This order is cancelled" message in red and hide the status update button
7. WHEN the order status is ORDER_PENDING, THE Rider_App SHALL hide the status update button
8. WHEN a status update API call succeeds, THE Rider_App SHALL update the local order state with the new orderStatus and the returned isRiderGoing value
9. THE order_helpers.dart `getNextRiderStatus` function SHALL accept an `isRiderGoing` parameter and return the correct next status based on the combined orderStatus and isRiderGoing values
10. THE order_helpers.dart `getNextStatusLabel` function SHALL accept an `isRiderGoing` parameter and return the correct button label based on the combined orderStatus and isRiderGoing values

### Requirement 8: Barrel File and Export Updates

**User Story:** As a developer, I want all new models and pages to be properly exported, so that they are accessible through the project's barrel file.

#### Acceptance Criteria

1. THE flutter_project_imports.dart barrel file SHALL export the Review model from `sendme_rider/lib/src/models/review.dart`
