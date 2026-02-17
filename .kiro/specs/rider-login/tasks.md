# Implementation Plan: Rider Login

## Overview

Implement phone number + OTP authentication for the sendme_rider app. The implementation follows an incremental approach: data models and helpers first, then the auth UI, then wiring into main.dart. Each step builds on the previous and ends with everything connected.

## Tasks

- [x] 1. Add dependencies to pubspec.yaml
  - Add `firebase_core`, `firebase_auth`, `firebase_messaging`, `intl_phone_field`, `pin_code_fields`, `http`, `shared_preferences`, `geolocator`, `permission_handler`, `device_info_plus`, `package_info_plus` to `sendme_rider/pubspec.yaml` dependencies
  - Only add packages not already present
  - _Requirements: 3.1, 4.1, 5.1, 5.2, 6.1, 2.2_

- [x] 2. Implement UserModel and PreferencesHelper
  - [x] 2.1 Create `lib/src/models/user_model.dart` with UserModel class
    - Fields: userId, name, mobile, email, userType, cityId, latitude, longitude
    - `fromJson` constructor mapping API keys (UserId, Name, userMobile/Mobile, email, userType, cityId, Latitude, Longitude)
    - `toJson` method serializing back to API-compatible map
    - Use null-safe types, handle missing fields gracefully
    - _Requirements: 7.1, 7.2, 7.3, 7.4_

  - [ ]\* 2.2 Write property test for UserModel round-trip
    - **Property 9: UserModel serialization round-trip**
    - **Validates: Requirements 7.1, 7.2, 7.3, 7.4**

  - [x] 2.3 Create `lib/src/resources/preferences_helper.dart`
    - Static methods: `readStringPref`, `saveStringPref`, `isLoggedIn`, `getSavedRider`, `clearSession`
    - `isLoggedIn` reads "RiderData" key, parses JSON, checks for non-null Data field
    - `getSavedRider` parses saved JSON into UserModel
    - `clearSession` clears the "RiderData" key
    - _Requirements: 6.1, 6.2, 6.3, 6.4_

  - [ ]\* 2.4 Write property test for session persistence round-trip
    - **Property 2: Session persistence round-trip**
    - **Validates: Requirements 6.1, 6.3**

- [x] 3. Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [x] 4. Implement PhoneVerificationView
  - [x] 4.1 Create `lib/src/authorization/phone_verification_view.dart`
    - StatefulWidget with `onLoginSuccess` callback
    - Phase 1 (phone entry): IntlPhoneField with country code picker defaulting to "IN", T&C checkbox with tappable links to AppConfig URLs, "Next" button with opacity based on validation state
    - Phase 2 (OTP entry): PinCodeTextField (6 digits, auto-submit on complete), display sent-to phone number with "Change" link, "Resend" link, "Next" button
    - `verifyPhone()` — Firebase verifyPhoneNumber, on codeSent transition to phase 2, on failure call resendOTP
    - `signIn()` — Firebase signInWithCredential, on success call saveUserToDBAndNavigate
    - `saveUserToDBAndNavigate()` — build SaveOTP or VerifyOTP URL with params from GlobalConstants and ThemeUI, parse response, save to PreferencesHelper, call onLoginSuccess
    - `resendOTP()` — call SendOTP API with phone, countryCode, packageName, password
    - `continueButtonOnClick()` — validate phone length and checkbox, initiate OTP flow
    - `changeNumberOnClick()` — reset sendOTPPressed, clear OTP controller
    - Use `PopScope` instead of `WillPopScope`, `Color.withValues()` instead of `withOpacity()`
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7, 3.8, 3.9, 4.1, 4.2, 4.3, 4.4, 4.5, 4.6, 5.1, 5.2, 5.3, 5.4, 5.5, 5.6, 5.7, 9.1, 9.2, 9.3_

  - [ ]\* 4.2 Write property test for OTP API URL construction
    - **Property 7: OTP API URL construction**
    - **Validates: Requirements 4.6, 5.2, 5.4**

  - [ ]\* 4.3 Write unit tests for PhoneVerificationView logic
    - Test button disabled state with various phone lengths and checkbox states (Property 4)
    - Test changeNumberOnClick resets state (Property 6)
    - Test API response handling for Status 1 and Status 0 (Property 8)
    - _Requirements: 3.6, 4.4, 5.5, 5.6_

- [x] 5. Implement LoginPage with location permission modal
  - [x] 5.1 Create `lib/src/authorization/login_page.dart`
    - StatefulWidget, shows location permission modal via `addPostFrameCallback` in initState
    - `showLocationPermissionModal()` — showDialog with "Allow" and "Add Manually" buttons
    - "Allow" calls `Geolocator.requestPermission()` then dismisses
    - "Add Manually" just dismisses the dialog
    - Body contains PhoneVerificationView with onLoginSuccess callback
    - Use `PopScope` for back button handling
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5_

- [x] 6. Implement RiderDashboard placeholder
  - [x] 6.1 Create `lib/src/ui/rider_dashboard.dart`
    - StatelessWidget accepting riderName parameter
    - Display rider name, app bar with brand color, placeholder body text
    - _Requirements: 8.1, 8.2, 8.3_

- [x] 7. Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [x] 8. Wire everything into main.dart and barrel files
  - [x] 8.1 Update `lib/flutter_project_imports.dart`
    - Add exports for login_page, phone_verification_view, user_model, preferences_helper, rider_dashboard
    - _Requirements: all_

  - [x] 8.2 Update `lib/main.dart`
    - Initialize Firebase in main() with `WidgetsFlutterBinding.ensureInitialized()` and `Firebase.initializeApp()`
    - Initialize device info (deviceId, deviceType, appVersion) into GlobalConstants
    - Get Firebase messaging token into GlobalConstants.firebaseToken
    - Replace `MyHomePage` with a `SplashRouter` widget that checks `PreferencesHelper.isLoggedIn()`
    - If logged in → navigate to RiderDashboard with saved rider name
    - If not logged in → navigate to LoginPage
    - LoginPage's onLoginSuccess navigates to RiderDashboard
    - _Requirements: 1.1, 1.2, 1.3, 8.1_

  - [ ]\* 8.3 Write property test for session routing
    - **Property 1: Session routing correctness**
    - **Validates: Requirements 1.1, 1.2, 6.2, 6.3**

- [x] 9. Final checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- The implementation uses modern Dart 3 conventions: non-nullable where possible, const constructors, PopScope, Color.withValues()
- Property tests validate universal correctness; unit tests cover edge cases
- The PhoneVerificationView mirrors the sendme customer app's pattern but uses the rider app's ThemeUI, AppConfig, and GlobalConstants
