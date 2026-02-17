# Requirements Document

## Introduction

This document defines the requirements for implementing a white-label/flavor system in the `sendme_rider` Flutter application. The system mirrors the compile-time config switch pattern used in the `sendme` customer app, enabling multiple branded rider apps (SendMe Rider, Eatoz Rider, SendMe6 Rider, Hopshop Rider, Tyeb Rider, SendMe Lebanon Rider, SendMe Talabetak Rider, SendMe Shrirampur Rider) to be produced from a single codebase by swapping a single `activeApp` variable. This is a newer codebase and all code, folder structure, versioning, and syntax SHALL follow modern Dart 3 / Flutter 3.x conventions (non-nullable types where possible, modern class syntax, `const` constructors, `final` fields, current SDK patterns).

## Glossary

- **AppConfig**: A Dart class that holds all brand-specific configuration fields (id, name, color, packageName, packagePassword, domainName, links, bundle identifiers, etc.) using modern non-nullable `final` fields
- **activeApp**: A top-level variable of type `AppConfig` that determines which brand configuration is currently active at compile time
- **Brand**: A specific white-label variant of the rider app (e.g., SendMe Rider, Eatoz Rider)
- **AssetsImage**: A Dart class that centralizes all asset paths, resolving per-brand assets based on `activeApp`
- **AssetsFont**: A Dart class that defines font family constants used across the app
- **AppColors**: A Dart class that derives all app colors dynamically from `activeApp.color`
- **ThemeUI**: A Dart class that exposes brand-specific theme and branding values derived from `activeApp`
- **BarrelFile**: A Dart file that re-exports multiple imports through a single `export` statement for centralized import management
- **ApiPath**: A Dart class that centralizes all API endpoint URLs using a configurable server path

## Requirements

### Requirement 1: AppConfig Class and Brand Instances

**User Story:** As a developer, I want a centralized configuration class with pre-defined brand instances, so that I can switch the entire rider app's branding by changing a single variable.

#### Acceptance Criteria

1. THE AppConfig class SHALL use modern Dart 3 syntax with non-nullable `final` fields and a `const` constructor for: id (String), name (String), color (Color), packageName (String), packagePassword (String), domainName (String), termsAndConditionsLink (String), privacyPolicyLink (String), whatsappLink (String), appType (int), androidAppLink (String), iosAppLink (String), deepLink (String), email (String), androidBundle (String), iosBundle (String), iosAppStoreId (String), and urlLink (String)
2. THE AppConfig file SHALL define a top-level `activeApp` variable of type `AppConfig` that references one of the pre-defined brand instances
3. THE AppConfig file SHALL define separate `const AppConfig` instances for each rider brand: sendmeRider, eatozRider, sendme6Rider, hopshopRider, tyebRider, sendmeLebanonRider, sendmeTalabetakRider, and sendmeShrirampurRider
4. WHEN a developer changes the `activeApp` assignment to a different brand instance, THE AppConfig file SHALL require no other code changes to switch the entire app branding
5. WHEN a brand instance is defined, THE AppConfig instance SHALL use rider-specific package names following the pattern `today.{brandname}.rider` (e.g., `today.sendme.rider`, `today.eatoz.rider`)

### Requirement 2: Dynamic Color System

**User Story:** As a developer, I want app colors to be derived from the active brand configuration, so that each brand has its own color scheme without code duplication.

#### Acceptance Criteria

1. THE AppColors class SHALL derive `mainAppColor` from `activeApp.color`
2. THE AppColors class SHALL derive `secondAppColor` as `mainAppColor` using the modern `Color.withValues()` API instead of the deprecated `withOpacity()`
3. THE AppColors class SHALL provide a `getMaterialColor` static method that converts any `Color` to a `MaterialColor` with 10 shade levels (50–900)
4. THE AppColors class SHALL define static color constants for order statuses (pending, done), text styles (bold, light, lighter), and app bar colors
5. WHEN `activeApp` is changed to a different brand, THE AppColors class SHALL reflect the new brand color without any code modifications to AppColors

### Requirement 3: Per-Brand Asset Resolution

**User Story:** As a developer, I want asset paths organized by brand with automatic resolution based on the active brand, so that each brand can have its own logos, loaders, and default images.

#### Acceptance Criteria

1. THE AssetsImage class SHALL define static `const` paths for common assets under `assets/apps/common/png_images/`, `assets/apps/common/svg_images/`, and `assets/apps/common/gif_images/`
2. THE AssetsImage class SHALL define static `const` paths for brand-specific assets under `assets/apps/{brandName}/png_images/`, `assets/apps/{brandName}/svg_images/`, and `assets/apps/{brandName}/gif_images/`
3. THE AssetsImage class SHALL resolve dynamic asset getters (loadingLogo, loader, defaultItem, defaultOutlet, loadingSVGLogo) by checking `activeApp.id` and returning the corresponding brand-specific asset path
4. WHEN `activeApp.id` does not match any known brand in a dynamic asset getter, THE AssetsImage class SHALL return the SendMe Rider brand asset as the default fallback

### Requirement 4: Font Configuration

**User Story:** As a developer, I want centralized font family definitions, so that all text rendering uses consistent typography across the rider app.

#### Acceptance Criteria

1. THE AssetsFont class SHALL define static `const` string constants for Poppins font variants: textBold (PoppinsBold), textMedium (PoppinsMedium), textRegular (PoppinsRegular), and textThin (PoppinsThin)
2. THE pubspec.yaml SHALL declare font assets for the Poppins family with Regular, Medium, Bold, and Thin weights
3. THE pubspec.yaml SHALL declare font assets for the DINNextLTArabic family with Regular, Medium, and Bold weights

### Requirement 5: Theme Configuration

**User Story:** As a developer, I want a centralized theme class that exposes brand-specific values from the active configuration, so that UI components can access branding data through a single interface.

#### Acceptance Criteria

1. THE ThemeUI class SHALL expose static fields derived from `activeApp`: appPackageName, appPassword, appDomainName, appName, appType, androidLink, iosLink, email, privacyPolicyLink, termsAndConditionsLink, and whatsappLink
2. THE ThemeUI class SHALL define a `languageList` containing English, Arabic, Hindi, and French
3. THE ThemeUI class SHALL define configurable UI theme identifiers for rider-specific screens

### Requirement 6: Barrel Import Files

**User Story:** As a developer, I want centralized barrel import files, so that I can import all common dependencies and project-specific modules through single import statements.

#### Acceptance Criteria

1. THE `flutter_imports.dart` barrel file SHALL re-export core Dart libraries (dart:async, dart:convert, dart:io, dart:math) and common Flutter/third-party packages used across the rider app
2. THE `flutter_imports.dart` barrel file SHALL re-export the AppConfig file so that `activeApp` is accessible from any file importing the barrel
3. THE `flutter_project_imports.dart` barrel file SHALL re-export all project-specific modules: api paths, common utilities, colors, assets, global constants, theme configuration, and controllers

### Requirement 7: Project Folder Structure

**User Story:** As a developer, I want a standardized folder structure mirroring the customer app, so that the rider app codebase is organized consistently and predictably.

#### Acceptance Criteria

1. THE project SHALL organize source code under `lib/src/` with subdirectories: `api/`, `common/`, `controllers/`, `models/`, `providers/`, `resources/`, `service/`, and `ui/`
2. THE project SHALL place barrel import files (`flutter_imports.dart`, `flutter_project_imports.dart`) directly under `lib/`
3. THE project SHALL place the `AppConfig.dart` file directly under `lib/`

### Requirement 8: API Path Configuration

**User Story:** As a developer, I want centralized API endpoint definitions with a configurable server path, so that all network calls reference a single source of truth for URLs.

#### Acceptance Criteria

1. THE ApiPath class SHALL define a static `const` `slsServerPath` string for the base server URL
2. THE ApiPath class SHALL define static `final` endpoint strings for rider-relevant APIs by concatenating `slsServerPath` with the endpoint path
3. THE ApiPath class SHALL reference `ThemeUI` for dynamic link values (termsAndConditions, privacyPolicy, whatsappLink)

### Requirement 9: Localization Support

**User Story:** As a developer, I want localization infrastructure supporting multiple languages, so that the rider app can display content in English, Arabic, Hindi, and French.

#### Acceptance Criteria

1. THE project SHALL include JSON translation files under `assets/i18n/` for four locales: `en.json`, `ar.json`, `hi.json`, and `fr.json`
2. THE pubspec.yaml SHALL declare the `assets/i18n/` directory in the assets section
3. WHEN a translation key is requested, THE localization system SHALL return the translated string for the current locale

### Requirement 10: Asset Declaration in pubspec.yaml

**User Story:** As a developer, I want all asset directories declared in pubspec.yaml, so that Flutter can bundle brand-specific and common assets into the app.

#### Acceptance Criteria

1. THE pubspec.yaml SHALL declare asset directories for common assets: `assets/apps/common/png_images/`, `assets/apps/common/svg_images/`, `assets/apps/common/gif_images/`
2. THE pubspec.yaml SHALL declare asset directories for each brand: `assets/apps/sendmeRider/`, `assets/apps/eatozRider/`, `assets/apps/sendme6Rider/`, `assets/apps/hopshopRider/`, `assets/apps/tyebRider/`, `assets/apps/sendmeLebanonRider/`, `assets/apps/sendmeTalabetakRider/`, `assets/apps/sendmeShrirampurRider/` with their respective `png_images/`, `svg_images/`, and `gif_images/` subdirectories
3. THE pubspec.yaml SHALL declare the `assets/i18n/` directory for localization files

### Requirement 11: Main Entry Point Integration

**User Story:** As a developer, I want the main.dart entry point to use the white-label system, so that the app title, theme color, and branding are driven by the active configuration.

#### Acceptance Criteria

1. WHEN the app starts, THE main.dart SHALL use `activeApp.name` for the MaterialApp title
2. WHEN the app starts, THE main.dart SHALL use `AppColors.mainAppColor` for the primary theme color
3. WHEN the app starts, THE main.dart SHALL import dependencies through the barrel files (`flutter_imports.dart` and `flutter_project_imports.dart`) instead of direct package imports

### Requirement 12: Modern Dart/Flutter Conventions

**User Story:** As a developer, I want the rider app codebase to follow modern Dart 3 and Flutter 3.x best practices, so that the code is clean, type-safe, and uses current SDK patterns.

#### Acceptance Criteria

1. THE codebase SHALL use non-nullable types by default, reserving nullable types only where semantically necessary
2. THE codebase SHALL use `const` constructors and `final` fields wherever possible
3. THE codebase SHALL use the modern `Color.withValues()` API instead of the deprecated `Color.withOpacity()`
4. THE codebase SHALL use `PopScope` instead of the deprecated `WillPopScope`
5. THE codebase SHALL target the Dart SDK constraint `^3.11.0` as specified in the existing pubspec.yaml
6. THE codebase SHALL use modern `package_info_plus` and `device_info_plus` instead of their deprecated predecessors
