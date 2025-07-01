# Codebase Analysis: Instant Grader Pro

## 1. Project Overview

**Instant Grader Pro** is a Flutter application designed to be an AI-powered instant grading tool. It utilizes OCR (Optical Character Recognition) technology to grade quizzes and other documents. The application allows users to either capture an image of a document using their device's camera or upload an image from the gallery. The app is intended to have features like analytics, data export, and various settings to customize the user experience.

The project is structured as a standard Flutter application, with support for Android, iOS, and other platforms.

## 2. Project Structure

The main application logic is located in the `lib` directory. Here's an overview of its structure:

```
lib/
├── screens/
│   ├── camera_screen.dart
│   ├── home_screen.dart
│   ├── main_shell.dart
│   ├── settings_screen.dart
│   └── upload_screen.dart
├── utils/
│   └── app_icons.dart
└── main.dart
```

-   **`main.dart`**: The entry point of the application. It initializes the app and sets up the theme.
-   **`screens/`**: This directory contains all the different screens of the application.
    -   **`main_shell.dart`**: A stateful widget that acts as the main container for the app, providing a bottom navigation bar to switch between the home and settings screens.
    -   **`home_screen.dart`**: The main screen of the app, which displays a welcome message and provides quick actions to scan or upload a document.
    -   **`camera_screen.dart`**: This screen allows the user to take a picture of a document using the device's camera.
    -   **`upload_screen.dart`**: This screen allows the user to select an image from the device's gallery.
    -   **`settings_screen.dart`**: This screen provides various options to configure the app, such as scan settings, app settings, and data management.
-   **`utils/`**: This directory contains utility files, such as `app_icons.dart`, which likely defines the icons used in the app.

## 3. Dependencies

The main dependencies used in this project are listed in the `pubspec.yaml` file:

-   **`flutter`**: The core framework for building the application.
-   **`cupertino_icons`**: Provides iOS-style icons.
-   **`camera`**: Enables camera support to capture images.
-   **`tflite_flutter`**: A plugin for running TensorFlow Lite models, which is intended to be used for the OCR functionality.
-   **`shared_preferences`**: Used for storing simple key-value data locally.
-   **`path_provider`**: Helps in finding commonly used locations on the file system.
-   **`flutter_lucide`**: Provides a set of beautiful and consistent icons.
-   **`image_picker`**: A plugin for selecting images from the device's gallery.

## 4. Core Components

### `main.dart`

This file is the entry point of the application. It initializes the `MyApp` widget, which is a `StatelessWidget`.

-   **`MyApp`**: This widget sets up the `MaterialApp`, defining the title, theme, and home page.
    -   It defines both a light and a dark theme for the application.
    -   The home page is set to `MainShell`.

### `screens/main_shell.dart`

This is a `StatefulWidget` that implements the main navigation structure of the app.

-   It uses a `PageView` and a `NavigationBar` to switch between `HomeScreen` and `SettingsScreen`.
-   A `FloatingActionButton` is displayed on the `HomeScreen` to provide a shortcut to the `CameraScreen`.

### `screens/home_screen.dart`

This is the main screen of the application.

-   It displays a welcome message to the user.
-   It provides "Quick Actions" for the user:
    -   **Scan Quiz**: Navigates to the `CameraScreen`.
    -   **Upload**: Navigates to the `UploadScreen`.
    -   **Analytics**: A placeholder for a future analytics feature.
    -   **Export**: A placeholder for a future data export feature.

### `screens/camera_screen.dart`

This screen is responsible for capturing images using the device's camera.

-   It initializes the camera and displays a camera preview.
-   A floating action button allows the user to take a picture.
-   After capturing an image, it displays a snackbar with the path to the captured image.
-   **Note**: The captured image is not yet processed for grading.

### `screens/upload_screen.dart`

This screen allows users to select an image from their gallery.

-   It uses the `image_picker` plugin to open the gallery and let the user select an image.
-   The selected image is displayed on the screen.
-   **Note**: The selected image is not yet processed for grading.

### `screens/settings_screen.dart`

This screen provides a variety of settings to the user, grouped into different sections.

-   **Profile**: Placeholder for user profile management.
-   **Scan Settings**: Options to configure the scanning process, such as auto-save, scan quality, and auto-crop.
-   **App Settings**: Options for theme, language, and notifications.
-   **Data & Storage**: Options for exporting, importing, and clearing data.
-   **About**: Information about the app, such as version number, privacy policy, and terms of service.
-   **Note**: Most of the settings are placeholders and not yet implemented.

## 5. Functionality

### Grading Process (Intended)

The intended grading process is as follows:

1.  The user either takes a picture of a document using the `CameraScreen` or uploads an image from the `UploadScreen`.
2.  The application processes the image using a TensorFlow Lite model for OCR. This step will extract the text from the image.
3.  The extracted text is then compared against a pre-defined answer key to grade the document.
4.  The results of the grading are displayed to the user, possibly on the `HomeScreen` or a new dedicated screen.

**Note**: The OCR and grading logic is not yet implemented in the current codebase.

### Data Management

-   The application uses `shared_preferences` for storing simple data, such as user settings.
-   The `SettingsScreen` includes options for exporting and importing data, as well as clearing all data. This functionality is not yet implemented but suggests that the app will have a way to manage user-generated data.

## 6. Future Work

Based on the analysis of the codebase, the following features are planned but not yet implemented:

-   **OCR and Grading**: The core functionality of the app, which involves processing images with a TFLite model and grading them, is not yet implemented.
-   **Analytics**: The analytics feature, which would likely provide insights into graded results, is a placeholder.
-   **Data Export/Import**: The functionality to export and import user data is not yet implemented.
-   **User Profile**: The user profile section is a placeholder.
-   **Most Settings**: Many of the settings in the `SettingsScreen` are not yet functional.
-   **Notifications**: The notification system is not yet implemented. 