# Dynatrace Tracking Optimization Summary

## Problem
The application was sending too many duplicate actions to Dynatrace, creating "chatty" tracking that made analysis difficult:

**Before (Too Many Actions):**
- `Navigate to /`
- `Screen: LoginPage`  
- `/: Login`
- `LoginPage: Login Attempt`
- `LoginPage: Login Success`

This resulted in 4-5 actions for a single user interaction!

## Solution
Simplified tracking to only send meaningful, non-duplicate actions:

### 1. Page Navigation Tracking
**Changed:** NavigatorObserver now only sends **ONE** action per page change
- **Before:** `Navigate to LoginPage` with navigation_type property
- **After:** `Page: LoginPage` with simplified properties

### 2. Button Click Tracking
**Changed:** Buttons now send simple, clear action names
- **Before:** `/: Login` or `UnknownRoute: Login`
- **After:** `Click: Login`

### 3. Removed Duplicate Tracking
**Removed:** All manual `trackAction()` calls that duplicated button clicks:
- ❌ Removed: `Login Attempt` (button already tracks `Click: Login`)
- ❌ Removed: `Generate Hash Button` (button already tracks `Click: Generate Hash`)
- ❌ Removed: `Calculate Button` (button already tracks `Click: Calculate`)
- ❌ Removed: Duplicate success/failure tracking

### 4. Removed Automatic Screen Tracking
**Changed:** DynatraceTracking mixin no longer sends automatic `Screen: X` actions in `initState()`
- This was redundant with NavigatorObserver's page tracking
- Reduces duplicate actions by 50%

## New Tracking Behavior

### Page Changes
**One action per page navigation:**
```
Page: /              → Landing page
Page: MenuPage       → Menu page
Page: HashGeneratorPage  → Hash generator
Page: CalculatorPage → Calculator
```

### Button Clicks
**One action per button click:**
```
Click: Login          → Login button clicked
Click: Generate Hash  → Generate hash button clicked
Click: Calculate      → Calculate button clicked
Click: Logout         → Logout button clicked
```

### User Identification
**Still tracked (important for user sessions):**
```
dtrum.identifyUser('username')
dtrum.setSessionProperty('userRole', 'authenticated')
```

### Errors
**Still tracked (important for debugging):**
```
dtrum.reportError('error message')
```

## Results

**Before:**
- Login flow: ~5 actions
- Hash generation: ~3 actions  
- Total: Very chatty, hard to analyze

**After:**
- Login flow: 2 actions (`Page: /`, `Click: Login`)
- Hash generation: 2 actions (`Page: HashGeneratorPage`, `Click: Generate Hash`)
- Total: Clean, meaningful data

## Web Request Tracking

**Note:** Web requests (XHR/Fetch) are automatically tracked by Dynatrace RUM agent. No manual instrumentation needed. They appear in Dynatrace as:
- `/api/login`
- `/api/hash`
- `/api/calculate`

The requests are correlated with user actions automatically.

## Code Changes

### Files Modified:
1. **lib/dynatrace_service.dart**
   - Simplified NavigatorObserver to send `Page: X` instead of `Navigate to X`
   - Removed automatic screen tracking from DynatraceTracking mixin
   - Changed button tracking to `Click: ButtonText` (no route prefix)
   - Removed route context from all button wrappers

2. **lib/main.dart**
   - Removed all manual `trackAction()` calls for button clicks
   - Removed duplicate success/failure tracking
   - Kept only essential user identification and error tracking

## Testing

To verify the changes:
1. ✅ Open Dynatrace RUM dashboard
2. ✅ Navigate through the app (Login → Menu → Hash/Calculator)
3. ✅ Check that actions are:
   - Named clearly (`Page: X`, `Click: Y`)
   - Not duplicated
   - Correlated with web requests
4. ✅ Verify web requests appear automatically

## Best Practices Going Forward

### ✅ DO Track:
- Page navigation (automatic via NavigatorObserver)
- Button clicks (automatic via DynatraceTrackedButton)
- User identification (`identifyUser()`)
- Session properties (`setSessionProperty()`)
- Errors (`reportError()`)

### ❌ DON'T Track:
- Manual button click actions (let auto-tracking handle it)
- Duplicate screen/page actions
- Every function call or state change
- Internal implementation details

This creates clean, actionable data in Dynatrace! 🎉
