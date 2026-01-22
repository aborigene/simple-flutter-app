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

## The Solution: Zero-Code Automatic Tracking

This implementation provides **fully automatic tracking** with **zero manual instrumentation per button/action**. Just wrap your app once and everything works!

### Quick Start - 3 Simple Steps

#### 1. Add Dynatrace Script to `web/index.html`
```html
<head>
  <!-- Your other head content -->
  <script type="text/javascript" src="YOUR_DYNATRACE_RUM_URL"></script>
</head>
```

#### 2. Wrap Your App with Global Gesture Detector in `main.dart`
```dart
import 'dynatrace_service.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Just wrap MaterialApp with DynatraceGestureDetector - that's it!
    return DynatraceGestureDetector(
      child: MaterialApp(
        // Add NavigatorObserver for automatic page tracking
        navigatorObservers: [DynatraceNavigatorObserver()],
        home: const HomePage(),
      ),
    );
  }
}
```

#### 3. Identify Users After Login
```dart
void onLoginSuccess(String username) {
  DynatraceService().identifyUser(username);
  DynatraceService().setSessionProperty('userRole', 'authenticated');
}
```

**That's it!** All buttons, navigation, and interactions are now tracked automatically.

### What Gets Tracked Automatically

#### ✅ All Button Clicks (Zero Code Required)
The `DynatraceGestureDetector` automatically captures:
- **ElevatedButton** - Extracts text from child
- **TextButton** - Extracts text from child  
- **OutlinedButton** - Extracts text from child
- **IconButton** - Uses tooltip or "Icon Button"
- **InkWell / GestureDetector** - Extracts text from children
- **Card with InkWell** - Finds text in nested widgets

**Your code stays clean:**
```dart
// Just write normal Flutter code - no tracking wrappers needed!
ElevatedButton(
  onPressed: _login,
  child: const Text('Login'),
)

IconButton(
  icon: const Icon(Icons.logout),
  tooltip: 'Logout',
  onPressed: _logout,
)
```

Dynatrace sees: `Click: Login`, `Click: Logout`

#### ✅ All Navigation (Automatic)
The `DynatraceNavigatorObserver` tracks all screen changes:
- Route pushes, pops, and replacements
- Sends: `Page: ScreenName`

**Just name your routes:**
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const MenuPage(),
    settings: const RouteSettings(name: 'MenuPage'), // That's it!
  ),
);
```

Dynatrace sees: `Page: MenuPage`

#### ✅ User Identity & Session Properties
```dart
// After successful login:
DynatraceService().identifyUser(username);
DynatraceService().setSessionProperty('userRole', 'authenticated');
```

#### ✅ Custom Actions (When Needed)
For special events not captured by clicks:
```dart
DynatraceService().sendAction('Transaction Completed', properties: {
  'amount': '1000',
  'type': 'transfer',
});
```

#### ✅ Error Tracking
```dart
catch (e) {
  DynatraceService().reportError('Login failed: $e');
}
```

#### ✅ API Calls
All HTTP requests automatically captured by Dynatrace RUM agent - no code needed!

### Components Overview

#### 1. **DynatraceGestureDetector** - Global Click Listener
Wraps your entire app and intercepts all pointer events:
- Uses Flutter's hit testing to identify clicked widgets
- Automatically extracts button text, tooltips, or child text
- Sends clean action names: `Click: ButtonText`
- **No per-button code required!**

#### 2. **DynatraceNavigatorObserver** - Automatic Page Tracking  
Observes all navigation events and sends page actions:
- Tracks: push, pop, replace
- Sends: `Page: RouteName`
- **No per-page code required!**

#### 3. **DynatraceService** - Core API Wrapper
Centralized service for Dynatrace JavaScript API:
- `identifyUser(username)` - Identify users
- `sendAction(name, properties)` - Custom actions
- `reportError(message)` - Error reporting
- `setSessionProperty(key, value)` - Session metadata

#### 4. **DynatraceTracking Mixin** - Optional Helper
For screens that need custom tracking:
```dart
class _MyPageState extends State<MyPage> with DynatraceTracking {
  void onSpecialEvent() {
    trackAction('Special Event', properties: {'context': 'value'});
  }
}
```

### Dynatrace Console Output

When running the app, you'll see debug output:
```
[Dynatrace] User identified: admin
[Dynatrace] Action sent: Page: /
[Dynatrace] Action sent: Click: Login
[Dynatrace] Action sent: Page: MenuPage
[Dynatrace] Session property set: userRole = authenticated
[Dynatrace] Action sent: Click: Generate Hash
[Dynatrace] Action sent: Page: HashGeneratorPage
```

### How to Verify in Dynatrace

1. **User Sessions**
   - Go to Applications → Your App → User Sessions
   - Click on a session
   - See user identified as "admin" (or other username)

2. **User Actions**
   - In session details, see timeline of clean actions:
     - Page: LoginPage
     - Click: Login
     - Page: MenuPage
     - Click: Generate Hash
     - Page: HashGeneratorPage
     - Click: Generate Hash

3. **Session Properties**
   - View session properties showing:
     - username: admin
     - userRole: authenticated

4. **XHR Monitoring**
   - XHR requests to backend automatically captured
   - See `/api/login`, `/api/hash`, `/api/calculate` calls
   - Request/response timing, status codes, payloads

5. **Conversion Goals**
   - Set up funnels like:
     - Page: LoginPage → Click: Login → Page: MenuPage
     - Page: MenuPage → Click: Generate Hash → Page: HashGeneratorPage

### Configuration for Large Banking Applications

For a large banking app with hundreds of screens and actions:

#### ✅ **Zero Per-Screen Configuration**
- Wrap app once with `DynatraceGestureDetector`
- Add `DynatraceNavigatorObserver` once
- **Done!** All 100+ screens tracked automatically

#### ✅ **Zero Per-Button Configuration**
- No need to wrap every button
- No need to add tracking to every callback
- Automatic text extraction from all button types
- Works with custom widgets that contain buttons

#### ✅ **Minimal Code Changes**
```dart
// Before: Standard Flutter app
return MaterialApp(
  home: HomePage(),
);

// After: Full Dynatrace tracking
return DynatraceGestureDetector(
  child: MaterialApp(
    navigatorObservers: [DynatraceNavigatorObserver()],
    home: HomePage(),
  ),
);
```

#### ✅ **Clean, Readable Action Names**
- `Page: Dashboard` - Screen view
- `Click: Transfer Money` - Button click
- `Click: Logout` - Icon button with tooltip
- `Click: View Statement` - Card tap with nested text

#### ✅ **Rich Context When Needed**
```dart
// Optional: Add business context to specific actions
void onTransferComplete() {
  DynatraceService().sendAction('Transaction Completed', properties: {
    'amount': amount.toString(),
    'type': 'transfer',
    'from': fromAccount,
    'to': toAccount,
  });
}
```

### Extending the Solution

#### Add Custom Business Event Tracking
```dart
// Track specific business events anywhere in your code:
DynatraceService().sendAction('Transaction Completed', properties: {
  'transaction_id': '12345',
  'amount': '100.50',
  'currency': 'USD',
});
```

#### Track Validation Errors
```dart
validator: (value) {
  if (value == null || value.isEmpty) {
    DynatraceService().sendAction('Validation Error', properties: {
      'field': 'account_number',
      'error': 'required',
    });
    return 'Please enter account number';
  }
  return null;
}
```

#### Track Background Operations
```dart
void syncData() async {
  try {
    await api.sync();
    DynatraceService().sendAction('Data Sync Completed');
  } catch (e) {
    DynatraceService().reportError('Data sync failed: $e');
  }
}
```

### How It Works Internally

The automatic tracking system uses Flutter's event system:

1. **Hit Testing**: When user taps screen, `DynatraceGestureDetector.Listener` intercepts the pointer event
2. **Widget Discovery**: Performs hit test to find which widgets were touched
3. **Smart Extraction**: Traverses widget tree to find interactive elements (buttons, InkWells, etc.)
4. **Text Extraction**: Extracts meaningful text from:
   - Button `child` widgets (Text widgets)
   - IconButton `tooltip` property
   - Nested Text widgets in Cards/InkWells
5. **Action Sending**: Sends `Click: ExtractedText` to Dynatrace with coordinates

No manual naming required - it just works!

### Best Practices

1. **Name Your Routes**
   ```dart
   // Always provide route names for clear tracking
   Navigator.push(
     context,
     MaterialPageRoute(
       builder: (context) => const MenuPage(),
       settings: const RouteSettings(name: 'MenuPage'), // ✅
     ),
   );
   ```

2. **Use Clear Button Text**
   ```dart
   // Good - Dynatrace sees "Click: Transfer Money"
   ElevatedButton(
     child: const Text('Transfer Money'),
     onPressed: _transfer,
   )
   
   // Avoid - Dynatrace sees "Click: >" or similar
   ElevatedButton(
     child: const Icon(Icons.arrow_forward),
     onPressed: _next,
   )
   
   // Better - Add tooltip for icon buttons
   IconButton(
     icon: const Icon(Icons.arrow_forward),
     tooltip: 'Next Step', // ✅ Dynatrace sees "Click: Next Step"
     onPressed: _next,
   )
   ```

3. **Add Custom Actions for Business Events**
   Track important business events that buttons don't capture:
   ```dart
   // ✅ Track outcomes, not just clicks
   void processPayment() async {
     // Button click tracked automatically as "Click: Process Payment"
     try {
       await api.pay();
       DynatraceService().sendAction('Payment Successful', properties: {
         'amount': amount.toString(),
         'method': 'credit_card',
       });
     } catch (e) {
       DynatraceService().reportError('Payment failed: $e');
     }
   }
   ```

4. **Don't Track PII in Action Names**
   ```dart
   // ❌ Never include PII in action names
   DynatraceService().sendAction('Transfer to John Smith');
   
   // ✅ Use generic names, mask data in properties if needed
   DynatraceService().sendAction('Transfer Initiated', properties: {
     'account_type': 'savings',
     'amount_range': '100-1000',
   });
   ```

5. **Identify Users Early**
   ```dart
   // Call immediately after successful authentication
   void onLoginSuccess(User user) {
     DynatraceService().identifyUser(user.username);
     DynatraceService().setSessionProperty('userRole', user.role);
     DynatraceService().setSessionProperty('accountType', user.accountType);
   }
   ```

### Troubleshooting

**Actions not appearing in Dynatrace?**
- Open browser DevTools console
- Check for `[Dynatrace]` debug messages
- Verify RUM script loaded: Run `console.log(typeof dtrum)` should return "object"
- Ensure script tag is in `<head>` before Flutter initialization

**User not identified in sessions?**
- Check console for `[Dynatrace] User identified: username` message
- Ensure `identifyUser()` is called after successful login
- Verify username is not null or empty string

**Button clicks not tracked?**
- Ensure app is wrapped with `DynatraceGestureDetector`
- Check that buttons have visible text or tooltips
- Look for error messages in console starting with `[Dynatrace] Error tracking click:`

**Navigation not tracked?**
- Verify `DynatraceNavigatorObserver` is in `navigatorObservers` array
- Add `settings: RouteSettings(name: 'PageName')` to all routes
- Check for `[Dynatrace] Action sent: Page: ...` in console

**Too many duplicate actions?**
- Check that you only have ONE `DynatraceGestureDetector` wrapping MaterialApp
- Ensure you're not also manually tracking the same actions

### Summary

This solution provides enterprise-grade tracking with minimal implementation:

✅ **One wrapper** - `DynatraceGestureDetector` around app  
✅ **One observer** - `DynatraceNavigatorObserver` for navigation  
✅ **One service call** - `identifyUser()` after login  
✅ **Zero per-button code** - All clicks tracked automatically  
✅ **Zero per-page code** - All navigation tracked automatically  
✅ **Clean action names** - `Page: X`, `Click: Y`  
✅ **Scales to 1000s of screens** - No maintenance overhead  
✅ **Business event tracking** - Add custom actions only when needed  

**Perfect for large banking apps** - Track everything automatically without polluting your codebase with monitoring code!
