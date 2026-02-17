# Requirements Document

## Introduction

This document specifies the requirements for the Rider Login feature in the `sendme_rider` Flutter app. The login flow uses phone number + OTP authentication mirroring the `sendme` customer app, but simplified for riders. Unlike the customer app, the rider app opens the login page directly (no separate LocationView), handles location permission via a modal dialog on the login page, and navigates to a placeholder Rider Dashboard after successful authentication.

## Glossary

- **Login_Page**: The main entry screen of the rider app that handles location permission prompting and contains the phone verification flow.
- **Phone_Verification_View**: The widget responsible for phone number input (phase 1) and OTP code entry (phase 2).
- **OTP**: One-Time Password — a 6-digit code sent via SMS for phone number verification.
- **Location_Permission_Modal**: A dialog shown on the Login_Page that asks the rider to grant location access or add location manually.
- **Rider_Dashboard**: A placeholder screen shown after successful login, representing the rider's main interface.
- **Preferences_Helper**: A utility class for reading and writing session data to SharedPreferences.
- **User_Model**: A data class representing the authenticated rider's profile returned from the API.
- **Firebase_Phone_Auth**: Firebase's phone number authentication service used as the primary OTP delivery mechanism.
- **API_Fallback**: The custom SendOTP/VerifyOTP/SaveOTP API endpoints used when Firebase Phone Auth encounters errors.
- **Country_Code_Picker**: An international phone number input field that allows selecting a country dial code.

## Requirements

### Requirement 1: App Entry Point

**User Story:** As a rider, I want the app to open the login page directly, so that I can sign in without navigating through a separate location screen.

#### Acceptance Criteria

1. WHEN the rider app launches and no valid session exists in SharedPreferences, THE Login_Page SHALL be displayed as the initial screen.
2. WHEN the rider app launches and a valid session exists in SharedPreferences, THE Rider_Dashboard SHALL be displayed as the initial screen.
3. WHEN the session check completes, THE app SHALL navigate to the appropriate screen within 3 seconds of launch.

### Requirement 2: Location Permission Modal

**User Story:** As a rider, I want to be prompted for location permission on the login page, so that I can grant access or choose to add my location manually.

#### Acceptance Criteria

1. WHEN the Login_Page is displayed for the first time, THE Location_Permission_Modal SHALL appear as a dialog overlay.
2. WHEN the rider taps "Allow" on the Location_Permission_Modal, THE Login_Page SHALL request location permission from the operating system.
3. WHEN the rider taps "Add Manually" on the Location_Permission_Modal, THE Location_Permission_Modal SHALL dismiss and THE Login_Page SHALL continue without requesting location permission.
4. WHEN the operating system grants location permission, THE Location_Permission_Modal SHALL dismiss and THE Login_Page SHALL proceed to the phone verification flow.
5. WHEN the operating system denies location permission, THE Location_Permission_Modal SHALL dismiss and THE Login_Page SHALL proceed to the phone verification flow.

### Requirement 3: Phone Number Entry

**User Story:** As a rider, I want to enter my phone number with a country code picker, so that I can receive an OTP for authentication.

#### Acceptance Criteria

1. THE Phone_Verification_View SHALL display an international phone number input field with a Country_Code_Picker defaulting to "IN".
2. THE Phone_Verification_View SHALL display a checkbox for accepting Terms & Conditions and Privacy Policy.
3. WHEN the rider taps the Terms & Conditions link, THE Phone_Verification_View SHALL open the Terms & Conditions URL from the active AppConfig in a web view.
4. WHEN the rider taps the Privacy Policy link, THE Phone_Verification_View SHALL open the Privacy Policy URL from the active AppConfig in a web view.
5. THE Phone_Verification_View SHALL display a "Next" button for submitting the phone number.
6. WHILE the phone number length is outside the valid range for the selected country OR the Terms & Conditions checkbox is unchecked, THE "Next" button SHALL appear visually disabled with reduced opacity.
7. WHEN the rider taps "Next" with a valid phone number and the checkbox checked, THE Phone_Verification_View SHALL initiate the OTP sending process.
8. WHEN the rider taps "Next" with an empty phone number, THE Phone_Verification_View SHALL display a validation error message.
9. WHEN the rider taps "Next" without checking the Terms & Conditions checkbox, THE Phone_Verification_View SHALL display an acceptance required message.

### Requirement 4: OTP Verification

**User Story:** As a rider, I want to verify my phone number with a 6-digit OTP code, so that I can securely authenticate into the app.

#### Acceptance Criteria

1. WHEN the OTP sending process completes, THE Phone_Verification_View SHALL transition to the OTP entry phase displaying a 6-digit PIN code input field.
2. THE Phone_Verification_View SHALL display the phone number the OTP was sent to alongside a "Change" option.
3. WHEN the rider enters all 6 digits, THE Phone_Verification_View SHALL automatically submit the OTP for verification.
4. WHEN the rider taps "Change" on the OTP screen, THE Phone_Verification_View SHALL return to the phone number entry phase with the OTP field cleared.
5. THE Phone_Verification_View SHALL display a "Resend" option for requesting a new OTP.
6. WHEN the rider taps "Resend", THE Phone_Verification_View SHALL call the SendOTP API endpoint with the rider's phone number, country code, package name, and package password.

### Requirement 5: Firebase Phone Auth with API Fallback

**User Story:** As a rider, I want reliable OTP delivery, so that I can authenticate even when Firebase encounters issues.

#### Acceptance Criteria

1. WHEN the rider submits a phone number, THE Phone_Verification_View SHALL first attempt OTP delivery via Firebase_Phone_Auth using `FirebaseAuth.instance.verifyPhoneNumber()`.
2. WHEN Firebase_Phone_Auth succeeds and the rider enters the correct OTP, THE Phone_Verification_View SHALL call the SaveOTP API endpoint with countryCode, mobileNumber, deviceToken, deviceId, packageName, and password parameters.
3. WHEN Firebase_Phone_Auth fails during verification, THE Phone_Verification_View SHALL fall back to the SendOTP API endpoint for OTP delivery.
4. WHEN using the API_Fallback path and the rider enters an OTP, THE Phone_Verification_View SHALL call the VerifyOTP API endpoint with mobileNumber, accessToken (the OTP), deviceToken, packageName, and password parameters.
5. WHEN the SaveOTP or VerifyOTP API returns Status 1 with non-null Data, THE Phone_Verification_View SHALL parse the response into a User_Model and save the response body to SharedPreferences.
6. IF the SaveOTP or VerifyOTP API returns Status 0, THEN THE Phone_Verification_View SHALL display the error message from the API response and clear the OTP input field.
7. IF the OTP verification request times out after 10 seconds, THEN THE Phone_Verification_View SHALL display an error message and allow the rider to retry.

### Requirement 6: Session Persistence

**User Story:** As a rider, I want my login session to persist, so that I do not have to re-authenticate every time I open the app.

#### Acceptance Criteria

1. WHEN authentication succeeds, THE Preferences_Helper SHALL save the full API response body under the "RiderData" key in SharedPreferences.
2. WHEN the app launches, THE app SHALL read the "RiderData" key from SharedPreferences to determine session validity.
3. WHEN the "RiderData" value is non-empty and contains valid JSON with a non-null Data field, THE app SHALL treat the session as valid.
4. WHEN the "RiderData" value is empty or absent, THE app SHALL treat the session as invalid and display the Login_Page.

### Requirement 7: User Model

**User Story:** As a developer, I want a structured rider user model, so that I can work with authenticated rider data throughout the app.

#### Acceptance Criteria

1. THE User_Model SHALL parse the following fields from the API JSON response: userId, name, mobile, email, userType, cityId, latitude, longitude.
2. THE User_Model SHALL provide a `fromJson` factory constructor that maps API response keys to model fields.
3. THE User_Model SHALL provide a `toJson` method that serializes the model back to a JSON-compatible map.
4. FOR ALL valid User_Model instances, serializing via `toJson` then deserializing via `fromJson` SHALL produce an equivalent User_Model.

### Requirement 8: Post-Login Navigation

**User Story:** As a rider, I want to be taken to the dashboard after logging in, so that I can start using the app.

#### Acceptance Criteria

1. WHEN authentication succeeds and session data is saved, THE app SHALL navigate to the Rider_Dashboard screen.
2. THE Rider_Dashboard SHALL display the authenticated rider's name from the User_Model.
3. THE Rider_Dashboard SHALL serve as a placeholder screen for future rider functionality.

### Requirement 9: Error Handling

**User Story:** As a rider, I want clear error feedback during login, so that I know what went wrong and how to proceed.

#### Acceptance Criteria

1. IF a network request fails due to a timeout or connection error, THEN THE Phone_Verification_View SHALL display a user-facing error toast message.
2. IF the rider enters an incorrect OTP, THEN THE Phone_Verification_View SHALL display an SMS verification error message and clear the OTP input field.
3. IF the API response contains an unexpected format, THEN THE Phone_Verification_View SHALL display a generic error message and allow the rider to retry.
