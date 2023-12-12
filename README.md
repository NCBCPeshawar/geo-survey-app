# Geo Survey App

## Project Setup

### 1. Google Services File

Add the `google-services.json` file of your project in the `android/app` folder.

### 2. Signing Configuration

Add the following values to the `key.properties` file for signing release:

```properties
storePassword=your_store_password
keyPassword=your_key_password
keyAlias=your_key_alias
storeFile=your_store_file_path
```

### 3. ApplicationId Configuration
Replace the applicationId "com.company.department.app" with your applicationId in the `android/app/build.gradle` file.

### 4. API Key Configuration
Add your API key to the `android/app/src/main/AndroidManifest.xml` file:

```
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="your_api_key" />
```

### 5. SDK Paths Configuration
Update paths to Android SDK and Flutter SDK in the `local.properties` file:
```
sdk.dir=C:\\your\\path\\Android\\sdk
flutter.sdk=D:\\your\\path\\flutter
```

### 6. Realtime Database Configuration
Add your Realtime Database URL to the `appUrls.dart` file.


### 7. Realtime Database Structure
Ensure that your Realtime Database has the following nodes:
- a. data
- b. users

### 8. Firebase Functions
Firebase functions are available in the `firebaseFunctions` folder. Deploy them in your Firebase project.
