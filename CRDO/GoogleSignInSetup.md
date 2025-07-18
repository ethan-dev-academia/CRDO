# Google Sign-In URL Scheme Setup Guide

## Step 4: Configure URL Schemes in Xcode

### Method 1: Using Xcode Interface (Recommended)

1. **Open your project in Xcode**
2. **Select your project** in the navigator (CRDO)
3. **Select your target** (CRDO)
4. **Go to "Info" tab**
5. **Find "URL Types" section** (if not visible, click the "+" button to add it)
6. **Add a new URL Type:**
   - **URL Schemes**: `com.googleusercontent.apps.YOUR_CLIENT_ID_HERE`
   - **Identifier**: `GoogleSignIn`
   - **Role**: `Editor`

### Method 2: Get Your Client ID

1. **Go to Firebase Console** → Your Project → Project Settings
2. **Find your iOS app** in the "Your apps" section
3. **Look for "Client ID"** in the configuration
4. **Replace `YOUR_CLIENT_ID_HERE`** with your actual Client ID

### Example URL Scheme:
```
com.googleusercontent.apps.123456789-abcdefghijklmnop.apps.googleusercontent.com
```

### Method 3: Alternative - Add to Info.plist

If you prefer to edit the Info.plist directly, add this to your Info.plist file:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>GoogleSignIn</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>com.googleusercontent.apps.YOUR_CLIENT_ID_HERE</string>
        </array>
    </dict>
</array>
```

## Next Steps:

1. **Get your Client ID** from Firebase Console
2. **Replace the placeholder** in the URL scheme
3. **Build and test** your app
4. **Test Google Sign-In** functionality

## Troubleshooting:

- **Make sure** you've added the GoogleSignIn package to your project
- **Verify** your Client ID is correct
- **Check** that Google Sign-In is enabled in Firebase Console
- **Ensure** your bundle ID matches in Firebase Console 