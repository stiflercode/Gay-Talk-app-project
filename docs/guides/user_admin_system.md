# User/Admin System Implementation ✅

## Overview

The app now supports two types of users:
- **Regular Users**: Can only see and call admins, get charged for calls
- **Admins**: Can receive calls, see all users, and don't get charged

## Features Implemented

### 1. **User Role System** ✅
- Added `role` field to user documents in Firestore
- Default role is `'user'`
- Admins have role `'admin'`

### 2. **User Filtering** ✅
- Regular users only see admin users in the home page
- Admins see all users (for admin dashboard)
- Filtering happens automatically based on user role

### 3. **Call Request System** ✅
- Users create call requests instead of directly calling
- Admins receive incoming call notifications
- Call requests stored in Firestore `callRequests` collection
- Status tracking: `pending`, `accepted`, `rejected`, `completed`, `cancelled`

### 4. **Incoming Call Screen for Admins** ✅
- Beautiful animated incoming call UI
- Shows caller name and call rate
- Accept/Reject buttons
- Auto-rejects after 30 seconds if not answered
- Pulse animation and ringing effect

### 5. **Call Charging** ✅
- Only regular users are charged for calls
- Admins receive calls for free
- Charges calculated based on call duration and coins per minute
- Wallet balance updated after call ends

## How to Set User Roles

### Option 1: Via Firestore Console

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Navigate to **Firestore Database**
3. Open the `users` collection
4. Select a user document
5. Add or update the `role` field:
   - For regular users: `"user"` (or leave empty, defaults to user)
   - For admins: `"admin"`

### Option 2: Via Code (During User Creation)

Update user creation code to set role:

```dart
await userService.createOrUpdateUser(
  user,
  name: 'John Doe',
  role: 'admin', // or 'user'
);
```

### Option 3: Update Existing User

```dart
await FirebaseFirestore.instance
    .collection('users')
    .doc(userId)
    .update({'role': 'admin'});
```

## Firestore Structure

### Users Collection
```
users/{userId}
  - uid: string
  - email: string
  - displayName: string
  - role: string ('user' or 'admin') // Default: 'user'
  - walletBalance: number
  - ... other fields
```

### Call Requests Collection
```
callRequests/{requestId}
  - requestId: string
  - callerId: string
  - callerName: string
  - adminId: string
  - adminName: string
  - channelName: string
  - coinsPerMin: number
  - status: string ('pending', 'accepted', 'rejected', 'completed', 'cancelled')
  - createdAt: timestamp
  - acceptedAt: timestamp (nullable)
  - endedAt: timestamp (nullable)
  - duration: number (seconds)
  - coinsCharged: number
```

## Firestore Indexes Required

You may need to create composite indexes for these queries:

1. **Pending requests for admin:**
   - Collection: `callRequests`
   - Fields: `adminId` (Ascending), `status` (Ascending), `createdAt` (Descending)

2. **Active request for user:**
   - Collection: `callRequests`
   - Fields: `callerId` (Ascending), `status` (Ascending), `createdAt` (Descending)

Firebase will prompt you to create these indexes when needed, or you can create them manually in the Firebase Console.

## User Flow

### Regular User Flow:
1. User opens app → Sees only admin users
2. User taps "Talk" on an admin
3. Call request created → Status: `pending`
4. Admin receives incoming call notification
5. Admin accepts → Status: `accepted`
6. User joins call → Call proceeds
7. Call ends → User charged, status: `completed`

### Admin Flow:
1. Admin opens app → Sees all users
2. Admin receives incoming call notification (if user calls)
3. Admin accepts/rejects call
4. If accepted → Admin joins call
5. Call ends → No charge for admin

## Code Files Modified/Created

### New Files:
- `lib/services/call_request_service.dart` - Call request management
- `lib/screens/incoming_call_screen.dart` - Incoming call UI for admins
- `USER_ADMIN_SYSTEM.md` - This documentation

### Modified Files:
- `lib/services/user_service.dart` - Added role support and filtering
- `lib/screens/home_page.dart` - Added role-based filtering and call request flow
- `lib/screens/connecting_screen.dart` - Added callRequestId support
- `lib/screens/call_screen.dart` - Added callRequestId support

## Testing

### Test as Regular User:
1. Set a user's role to `'user'` in Firestore
2. Login as that user
3. Verify only admins are shown
4. Call an admin
5. Verify call request is created
6. Verify wallet is charged after call

### Test as Admin:
1. Set a user's role to `'admin'` in Firestore
2. Login as that user
3. Verify all users are shown
4. Have another user call you
5. Verify incoming call screen appears
6. Accept/reject call
7. Verify no charges applied

## Troubleshooting

### Users see no one in the list
- **Check**: User role is set correctly
- **Check**: There are admin users in the database
- **Check**: User is authenticated

### Incoming calls not showing for admin
- **Check**: Admin role is set correctly
- **Check**: Call request is created in Firestore
- **Check**: Firestore indexes are created
- **Check**: App has proper permissions

### Calls not charging users
- **Check**: User role is `'user'` (not `'admin'`)
- **Check**: Wallet balance is sufficient
- **Check**: Call request status is `'completed'`
- **Check**: Firestore updates are working

### Call requests stuck in pending
- **Check**: Admin is online and receiving notifications
- **Check**: Firestore listener is active
- **Check**: Network connectivity

## Security Notes

- ✅ User roles are stored server-side (Firestore)
- ✅ Call requests require authentication
- ✅ Only users can create call requests to admins
- ✅ Charging logic is enforced client-side and server-side
- ⚠️ Consider adding server-side validation for role changes

## Future Enhancements

- [ ] Server-side role validation
- [ ] Admin dashboard with call statistics
- [ ] Push notifications for incoming calls
- [ ] Call history for admins
- [ ] Multiple admins per call
- [ ] Call scheduling
- [ ] Admin availability status

---

**Status**: ✅ **Fully Implemented and Ready to Use!**

