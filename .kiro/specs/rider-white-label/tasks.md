# Implementation Plan: Rider White-Label System

## Overview

Set up the complete white-label infrastructure in `sendme_rider` mirroring the `sendme` customer app pattern. Each task builds incrementally — starting with the core config, then supporting classes, then wiring everything together in main.dart. All code uses modern Dart 3 / Flutter 3.x conventions.

## Tasks

- [x] 1. Create project folder structure and AppConfig
  - [x] 1.1 Create the directory structure under `lib/src/` with subdirectories: `api/`, `common/`, `controllers/`, `controllers/localization/`, `models/`, `providers/`, `resources/`, `service/`, `ui/`
    - Create placeholder `.gitkeep` files in empty directories so they are tracked
    - _Requirements: 7.1, 7.2, 7.3_

  - [x] 1.2 Create `lib/AppConfig.dart` with the `AppConfig` class using non-nullable `final` fields, `const` constructor, and all 8 rider brand instances (`sendmeRider`, `eatozRider`, `sendme6Rider`, `hopshopRider`, `tyebRider`, `sendmeLebanonRider`, `sendmeTalabetakRider`, `sendmeShrirampurRider`) with rider-specific package names (e.g., `today.sendme.rider`). Define `activeApp` top-level variable defaulting to `sendmeRider`.
    - Mirror the field set from `sendme/lib/AppConfig.dart` but use modern Dart 3 syntax (non-nullable, final, const constructor)
    - Each brand's color, domainName, and links should mirror the corresponding customer app brand but with rider-specific package names
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 12.1, 12.2_

  - [ ]\* 1.3 Write property test for AppConfig brand instances
    - **Property 1: Brand instance completeness and naming convention**
    - Iterate over all brand instances, verify all fields are non-empty and packageName contains `.rider`
    - **Validates: Requirements 1.3, 1.5**

- [x] 2. Implement dynamic color system and asset paths
  - [x] 2.1 Create `lib/src/common/colors.dart` with `AppColors` class
    - Derive `mainAppColor` from `activeApp.color`, `secondAppColor` using `Color.withValues(alpha: 0.4)`
    - Implement `getMaterialColor` static method producing 10 shade levels
    - Define static constants for order status colors, text colors, app bar colors
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 12.3_

  - [ ]\* 2.2 Write property test for getMaterialColor
    - **Property 2: getMaterialColor produces valid MaterialColor**
    - Generate random Colors, verify all 10 shade keys [50..900] are present and non-null
    - **Validates: Requirements 2.3**

  - [x] 2.3 Create `lib/src/common/assets_path.dart` with `AssetsImage` class and `AssetsFont` class
    - Define `const` common asset paths under `assets/apps/common/` (rider-relevant subset: location pin, rider map, user map, outlet map, call icon, no internet, etc.)
    - Define `const` brand-specific asset paths for each brand folder
    - Implement dynamic getters (`loadingLogo`, `loader`, `defaultItem`, `defaultOutlet`, `loadingSVGLogo`) using `switch` on `activeApp.id` with SendMe Rider as default fallback
    - Define `AssetsFont` with Poppins font family constants
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 4.1_

  - [ ]\* 2.4 Write property test for asset path resolution
    - **Property 3: Asset path prefix consistency**
    - **Property 4: Dynamic asset resolution matches active brand**
    - Verify common paths start with `assets/apps/common/`, brand paths start with `assets/apps/{brand}/`, and dynamic getters resolve correctly per brand
    - **Validates: Requirements 3.1, 3.2, 3.3, 3.4**

- [x] 3. Implement ThemeUI and API paths
  - [x] 3.1 Create `lib/src/controllers/theme_ui.dart` with `ThemeUI` class
    - Expose static fields derived from `activeApp`: appPackageName, appPassword, appDomainName, appName, appType, androidLink, iosLink, email, privacyPolicyLink, termsAndConditionsLink, whatsappLink
    - Define `languageList` with 4 languages
    - Define configurable UI theme identifiers for rider screens
    - _Requirements: 5.1, 5.2, 5.3_

  - [ ]\* 3.2 Write property test for ThemeUI delegation
    - **Property 5: ThemeUI fields mirror activeApp**
    - For each brand instance, verify ThemeUI fields equal corresponding activeApp fields
    - **Validates: Requirements 5.1**

  - [x] 3.3 Create `lib/src/api/api_path.dart` with `ApiPath` class
    - Define `static const slsServerPath` for base server URL
    - Define rider-relevant API endpoints (saveRiderLocation, updateRider, getRatingsAndReviewsForRider, getGeoPointByRiderId, getCustomerInfo, uploadBill, uploadQRPayment, getDynamicQR, plus common endpoints like saveOTP, sendOTP, verifyOTP, userRegistration, etc.)
    - Add dynamic getters for termsAndConditions, privacyPolicy, whatsappLink referencing ThemeUI
    - _Requirements: 8.1, 8.2, 8.3_

  - [ ]\* 3.4 Write property test for API endpoint prefix
    - **Property 6: API endpoints use server path prefix**
    - Verify all static endpoint strings start with `ApiPath.slsServerPath`
    - **Validates: Requirements 8.2**

- [x] 4. Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [x] 5. Create barrel files, global constants, and localization
  - [x] 5.1 Create `lib/src/common/global_constants.dart` with `GlobalConstants` class
    - Define rider-relevant constants: order statuses, delivery types, payment modes, user types, Google Maps key, device info fields
    - Keep minimal — only constants needed for the rider app infrastructure
    - _Requirements: 6.3_

  - [x] 5.2 Create `lib/flutter_imports.dart` barrel file
    - Re-export core Dart libraries: `dart:async`, `dart:convert`, `dart:io`, `dart:math`
    - Re-export Flutter SDK: `package:flutter/material.dart`, `package:flutter/services.dart`, `package:flutter/foundation.dart`
    - Re-export `package:sendme_rider/AppConfig.dart`
    - _Requirements: 6.1, 6.2_

  - [x] 5.3 Create `lib/flutter_project_imports.dart` barrel file
    - Re-export all project modules: api_path, colors, assets_path, global_constants, theme_ui
    - _Requirements: 6.3_

  - [x] 5.4 Create localization infrastructure
    - Create `lib/src/controllers/localization/app_localization.dart` with `AppLocalizations` class and `AppLocalizationsDelegate`
    - The class loads JSON from `assets/i18n/{locale}.json` and provides `translate(key)` method
    - Create placeholder JSON files: `assets/i18n/en.json`, `assets/i18n/ar.json`, `assets/i18n/hi.json`, `assets/i18n/fr.json` with a few sample keys (e.g., appName, welcome, riderDashboard)
    - _Requirements: 9.1, 9.2, 9.3_

  - [ ]\* 5.5 Write property test for localization round-trip
    - **Property 7: Localization round-trip**
    - Load each translation file, verify all keys return their expected values
    - **Validates: Requirements 9.3**

- [x] 6. Set up assets, fonts, and pubspec.yaml configuration
  - [x] 6.1 Create asset directory structure
    - Create `assets/apps/common/png_images/`, `assets/apps/common/svg_images/`, `assets/apps/common/gif_images/`
    - Create brand directories: `assets/apps/sendmeRider/png_images/`, `svg_images/`, `gif_images/` (and same for eatozRider, sendme6Rider, hopshopRider, tyebRider, sendmeLebanonRider, sendmeTalabetakRider, sendmeShrirampurRider)
    - Add `.gitkeep` files in empty asset directories
    - _Requirements: 10.1, 10.2_

  - [x] 6.2 Update `pubspec.yaml` with asset declarations, font declarations, and localization directory
    - Add all asset directories under `flutter.assets`
    - Add `assets/i18n/` directory
    - Add Poppins font family (Regular, Medium, Bold, Thin) under `assets/fonts/`
    - Add DINNextLTArabic font family (Regular, Medium, Bold) under `assets/fonts/`
    - Declare both font families under `flutter.fonts`
    - _Requirements: 4.2, 4.3, 10.1, 10.2, 10.3_

- [x] 7. Wire everything together in main.dart
  - [x] 7.1 Update `lib/main.dart` to use the white-label system
    - Import through barrel files (`flutter_imports.dart`, `flutter_project_imports.dart`)
    - Use `activeApp.name` for MaterialApp title
    - Use `AppColors.mainAppColor` and `AppColors.appPrimaryColor` for theme
    - Use `AssetsFont.textRegular` as default font family
    - Set up localization delegates and supported locales
    - _Requirements: 11.1, 11.2, 11.3_

  - [ ]\* 7.2 Write unit tests for main.dart integration
    - Verify MaterialApp uses activeApp.name as title
    - Verify theme uses AppColors.mainAppColor
    - _Requirements: 11.1, 11.2_

- [x] 8. Final checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation
- Property tests validate universal correctness properties using the `glados` package
- Unit tests validate specific examples and edge cases
- All code uses modern Dart 3 conventions: non-nullable types, const constructors, final fields, modern Color APIs
