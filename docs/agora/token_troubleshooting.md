# Agora Token Error Fix

## Problem
You're seeing this error:
```
Agora error: ErrorCodeType.errInvalidToken
Connection state changed: ConnectionStateType.connectionStateFailed, reason: ConnectionChangedReasonType.connectionChangedInvalidToken
```

## Cause
Your Agora project is configured to **require token authentication**. Temporary tokens are **channel-specific** - they must be generated for the exact channel name you're using.

## Solution

### Option 1: Generate Token for "test" Channel (Quick Fix)

1. Go to [Agora Console](https://console.agora.io)
2. Navigate to **Projects** → Your Project → **Temporary Token**
3. Generate a token with:
   - **Channel Name**: `test` (or any name you prefer)
   - **UID**: `0` (or any number)
4. The app will automatically use the channel name `test` in development mode

### Option 2: Use Custom Channel Name

If you generated the token for a different channel name (e.g., "mychannel"):

```bash
flutter run --dart-define=AGORA_TEMP_TOKEN=your_token_here --dart-define=AGORA_DEV_CHANNEL=mychannel
```

### Option 3: Disable Token Authentication (If Allowed)

1. Go to Agora Console → Your Project → **Config**
2. Check if there's an option to disable token authentication for development
3. If available, disable it temporarily for testing

**Note**: This may not be available depending on your Agora plan.

### Option 4: Use Production Token Server (Recommended for Production)

Set up a token server as described in `../guides/production_setup.md` and use production mode.

## Quick Test Command

```bash
# Replace YOUR_TOKEN with the token from Agora Console
# Make sure the token was generated for channel "test"
flutter run --dart-define=AGORA_TEMP_TOKEN=YOUR_TOKEN
```

## Important Notes

1. **Channel Name Must Match**: The channel name used when generating the temporary token must match the channel name the app uses. By default, the app uses `test` in development mode.

2. **Token Expiration**: Temporary tokens expire after 24 hours. You'll need to regenerate them.

3. **UID**: The UID used when generating the token doesn't need to match exactly, but it's good practice to use `0` for testing.

## What Was Fixed

1. ✅ **LateInitializationError**: Fixed `_balance` initialization in `home_page.dart`
2. ✅ **UI Overflow**: Made `personal_details_screen.dart` scrollable
3. ✅ **Better Error Messages**: Added specific error handling for invalid token errors
4. ✅ **Channel Name Handling**: App now uses a fixed channel name (`test`) in development mode when using temporary tokens

## Next Steps

1. Generate a temporary token in Agora Console for channel name `test`
2. Update the token in `agora_config.dart` or use `--dart-define=AGORA_TEMP_TOKEN=your_token`
3. Test your calls
4. For production, set up a proper token server
