# Dynatrace RUM Integration for Flutter Web

## The Challenge: Why Traditional Tracking Doesn't Work

Flutter web **does not render traditional HTML/DOM elements**. Instead, it uses custom rendering:

- **HTML Renderer**: Uses `<flt-*>` elements and canvas
- **CanvasKit**: Renders everything to WebGL canvas

This means:
- ❌ No `<button>`, `<div>`, or `<span>` elements to select
- ❌ Dynatrace auto-instrumentation can't detect clicks
- ❌ CSS selectors don't work for configuration
- ❌ Traditional DOM inspection shows only canvas elements

## The Solution: Automatic Dynatrace Integration

This implementation provides **automatic tracking** without manual instrumentation for every action.

### Components

#### 1. **DynatraceService** (`lib/dynatrace_service.dart`)
Centralized service that wraps Dynatrace JavaScript API calls:
- `identifyUser(username)` - Identify authenticated users
- `sendAction(name, properties)` - Send custom actions
- `reportError(message)` - Report errors
- `setSessionProperty(key, value)` - Set session properties

#### 2. **DynatraceNavigatorObserver**
Automatically tracks **all screen navigation**:
- Captures route pushes, pops, and replacements
- Sends action to Dynatrace with route name
- **Zero manual tracking required**

#### 3. **DynatraceTracking Mixin**
Add to any StatefulWidget to enable tracking:
```dart
class _MyPageState extends State<MyPage> with DynatraceTracking {
  // Automatically sends "Screen: MyPage" action on load
  
  void someAction() {
    trackAction('Button Clicked', properties: {'context': 'value'});
  }
}
```

#### 4. **DynatraceTrackedButton Helper**
Wrap any callback to automatically track:
```dart
onPressed: DynatraceTrackedButton.trackTap(
  'Action Name',
  () {
    // Your code
  },
  properties: {'key': 'value'},
)
```

### What Gets Tracked Automatically

#### ✅ User Identity
- Username captured on successful login
- Sent via `dtrum.identifyUser()`
- Session property set for user role

#### ✅ Navigation Events
- Every screen change tracked automatically
- Route names sent with navigation type (push/pop/replace)
- Example: "Navigate to MenuPage"

#### ✅ User Actions
- Login attempts (success/failure)
- Menu selections (Hash Generator / Calculator)
- Form submissions
- Button clicks
- Logout actions

#### ✅ Business Events
- Hash generation with algorithm type
- Calculations with operator type
- Success/failure status
- Error conditions

#### ✅ API Calls
- Dynatrace automatically captures all HTTP requests
- `/api/login`, `/api/hash`, `/api/calculate`
- Request/response data available in session replay

#### ✅ Errors
- JavaScript errors reported automatically
- Custom error reporting for exceptions
- Stack traces included

### Dynatrace Console Output

When running the app, you'll see debug output:
```
[Dynatrace] User identified: admin
[Dynatrace] Action sent: LoginPage: Login Success
[Dynatrace] Action sent: Navigate to MenuPage
[Dynatrace] Session property set: userRole = authenticated
[Dynatrace] Action sent: Menu: Generate Hash
[Dynatrace] Action sent: Navigate to HashGeneratorPage
```

### How to Verify in Dynatrace

1. **User Sessions**
   - Go to Applications → Your App → User Sessions
   - Click on a session
   - See user identified as "admin" (or other username)

2. **User Actions**
   - In session details, see timeline of actions:
     - Screen: LoginPage
     - LoginPage: Login Attempt
     - LoginPage: Login Success
     - Navigate to MenuPage
     - Menu: Generate Hash
     - Screen: HashGeneratorPage
     - HashGeneratorPage: Generate Hash Button
     - Hash Generated Successfully

3. **Session Properties**
   - View session properties showing:
     - username: admin
     - userRole: authenticated

4. **Request Attributes**
   - XHR requests to backend automatically captured
   - Can create request attributes to extract:
     - Username from `/api/login` request body
     - Operator from `/api/calculate` request body
     - Message length from `/api/hash` request body

5. **Conversion Goals**
   - Set up funnels like:
     - Login → Menu → Hash Generation → Success
     - Login → Menu → Calculator → Result

### Configuration for Banking Application

For a large banking app, this approach:

#### ✅ **Scales Automatically**
- Add `with DynatraceTracking` to any screen = automatic tracking
- Wrap any callback with `DynatraceTrackedButton.trackTap()` = tracked
- Navigation tracked globally without per-route configuration

#### ✅ **No Manual Instrumentation**
- Don't need to add tracking to every button
- Don't need to update tracking when adding features
- Tracking logic centralized in one service

#### ✅ **Rich Context**
- Every action includes screen name
- Properties can include business context (operator, amounts, etc.)
- User identity persists across session

#### ✅ **Error Visibility**
- All errors automatically reported
- Stack traces captured
- Failed API calls visible in XHR monitoring

### Extending the Solution

#### Track Custom Events
```dart
// Anywhere in your code:
DynatraceService().sendAction('Custom Event', properties: {
  'transaction_id': '12345',
  'amount': '100.50',
  'currency': 'USD',
});
```

#### Track Form Field Changes
```dart
TextField(
  onChanged: (value) {
    if (value.length > 10) {
      context.trackAction('Long Input Detected', properties: {
        'field': 'account_number',
        'length': value.length.toString(),
      });
    }
  },
)
```

#### Track Validation Errors
```dart
validator: (value) {
  if (value == null || value.isEmpty) {
    context.trackAction('Validation Error', properties: {
      'field': 'account_number',
      'error': 'required',
    });
    return 'Please enter account number';
  }
  return null;
}
```

#### Track Business Metrics
```dart
void completeTransaction() {
  DynatraceService().sendAction('Transaction Completed', properties: {
    'type': 'transfer',
    'amount': amount.toString(),
    'from_account': fromAccount,
    'to_account': toAccount,
  });
}
```

### Best Practices

1. **Use Meaningful Action Names**
   - ✅ "Login: Success"
   - ✅ "Transfer: Amount Entered"
   - ❌ "Button Clicked"
   - ❌ "Form Submitted"

2. **Include Context in Properties**
   ```dart
   properties: {
     'screen': 'dashboard',
     'feature': 'quick_transfer',
     'amount_range': '100-1000',
   }
   ```

3. **Don't Track PII in Action Names**
   - ❌ "Transfer to John Smith"
   - ✅ "Transfer Initiated" (account in properties, masked in Dynatrace)

4. **Track Business Events, Not Just Technical Actions**
   - ✅ "Loan Application Started"
   - ✅ "Credit Score Checked"
   - ✅ "Document Uploaded"

### Troubleshooting

**Actions not appearing?**
- Check browser console for Dynatrace errors
- Verify `dtrum` object exists: Run `console.log(typeof dtrum)` in DevTools
- Check RUM script loads before Flutter initializes

**User not identified?**
- Ensure login calls `DynatraceService().identifyUser(username)`
- Check console for "[Dynatrace] User identified: ..." message
- Verify username is not null/empty

**Missing screen transitions?**
- Ensure `DynatraceNavigatorObserver` is added to MaterialApp
- Add `settings: RouteSettings(name: 'ScreenName')` to routes

**Properties not visible?**
- Session properties: Use Dynatrace's Session Properties feature
- Action properties: May require Dynatrace configuration to expose

### Summary

This solution provides:
- ✅ **Automatic user identification** on login
- ✅ **Automatic navigation tracking** for all screens  
- ✅ **Generic click tracking** via helper methods
- ✅ **Business event tracking** with rich context
- ✅ **Error tracking** with stack traces
- ✅ **Scalable architecture** for large applications
- ✅ **Minimal code changes** to existing app

**For a bank with hundreds of actions**: Just add the mixin to screens and wrap callbacks - tracking happens automatically!
