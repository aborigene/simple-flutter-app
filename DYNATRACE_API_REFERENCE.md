# Dynatrace JavaScript API Reference

This document summarizes the correct usage of Dynatrace RUM JavaScript API based on official documentation (version 1.329.4).

## Current Issues in Flutter App

The Flutter app has **INCORRECT** API calls causing "Wrong argument types" warnings. The issues are:

### ❌ Current (Incorrect) Implementation

```dart
// WRONG: Using arrays to pass arguments
js.context['dtrum'].callMethod('identifyUser', [username]);
js.context['dtrum'].callMethod('enterAction', [actionName]);
js.context['dtrum'].callMethod('addActionProperties', [actionId, key, value]);
```

### ✅ Correct Implementation Needed

The Dynatrace API expects positional arguments, not arrays.

## API Method Signatures

### 1. identifyUser()

**Signature:** `dtrum.identifyUser(username)`

**Example:**
```javascript
dtrum.identifyUser('admin');
```

**Dart Implementation:**
```dart
void identifyUser(String username) {
  if (!isDynatraceAvailable) return;
  
  try {
    js.context.callMethod('eval', ['dtrum.identifyUser("$username")']);
    debugPrint('[Dynatrace] User identified: $username');
  } catch (e) {
    debugPrint('[Dynatrace] Error identifying user: $e');
  }
}
```

### 2. enterAction()

**Signature:** `dtrum.enterAction(actionName, actionType, startTime, sourceUrl)`

**Parameters:**
- `actionName` (string, required): Name of the action
- `actionType` (string, optional): Type of action (e.g., 'info')
- `startTime` (number, optional): Custom start timestamp
- `sourceUrl` (string, optional): Source URL

**Returns:** Action ID (number) to be used with `leaveAction()` and `addActionProperties()`

**Examples:**
```javascript
// Simple action
var actionId = dtrum.enterAction('simple action');

// With action type
dtrum.enterAction('change page', null, null, 'info');

// With custom start time
var actionId = dtrum.enterAction("custom action", null, startTime);
```

**Dart Implementation:**
```dart
int? sendAction(String actionName, {Map<String, dynamic>? properties}) {
  if (!isDynatraceAvailable) return null;
  
  try {
    // Escape action name for safe eval
    final escapedName = actionName.replaceAll("'", "\\'");
    
    // Enter action and get ID
    final result = js.context.callMethod('eval', ["dtrum.enterAction('$escapedName')"]);
    final actionId = result is int ? result : null;
    
    if (actionId != null && properties != null && properties.isNotEmpty) {
      // Add properties using correct API
      _addActionProperties(actionId, properties);
    }
    
    // Leave action immediately (for simple tracking)
    if (actionId != null) {
      js.context.callMethod('eval', ['dtrum.leaveAction($actionId)']);
    }
    
    debugPrint('[Dynatrace] Action sent: $actionName');
    return actionId;
  } catch (e) {
    debugPrint('[Dynatrace] Error sending action: $e');
    return null;
  }
}
```

### 3. leaveAction()

**Signature:** `dtrum.leaveAction(actionId, stopTime, documentLoaded)`

**Parameters:**
- `actionId` (number, required): Action ID returned from `enterAction()`
- `stopTime` (number, optional): Custom end timestamp
- `documentLoaded` (boolean, optional): Whether document is loaded

**Example:**
```javascript
var actionId = dtrum.enterAction('simple action');
// Do something...
dtrum.leaveAction(actionId);

// With custom end time
dtrum.leaveAction(actionId, startTime + 100);
```

**Dart Implementation:**
```dart
void leaveAction(int actionId) {
  if (!isDynatraceAvailable) return;
  
  try {
    js.context.callMethod('eval', ['dtrum.leaveAction($actionId)']);
    debugPrint('[Dynatrace] Action left: $actionId');
  } catch (e) {
    debugPrint('[Dynatrace] Error leaving action: $e');
  }
}
```

### 4. addActionProperties()

**Signature:** `dtrum.addActionProperties(actionId, longProperties, dateProperties, stringProperties, doubleProperties)`

**Parameters:**
- `actionId` (number, required): Action ID from `enterAction()`
- `longProperties` (object, optional): Map of long/integer properties `{key: value}`
- `dateProperties` (object, optional): Map of date properties `{key: dateValue}`
- `stringProperties` (object, optional): Map of string properties `{key: "value"}`
- `doubleProperties` (object, optional): Map of double/float properties `{key: 0.123}`

**Example:**
```javascript
var actionId = dtrum.enterAction('simple action');

// Add different property types
var longProps = {count: 123, userId: 456};
var stringProps = {status: 'success', page: 'home'};
var doubleProps = {rating: 4.5};

dtrum.addActionProperties(actionId, longProps, null, stringProps, doubleProps);

dtrum.leaveAction(actionId);
```

**Dart Implementation:**
```dart
void _addActionProperties(int actionId, Map<String, dynamic> properties) {
  try {
    // Separate properties by type
    final longProps = <String, int>{};
    final stringProps = <String, String>{};
    final doubleProps = <String, double>{};
    
    properties.forEach((key, value) {
      if (value is int) {
        longProps[key] = value;
      } else if (value is double) {
        doubleProps[key] = value;
      } else {
        stringProps[key] = value.toString();
      }
    });
    
    // Build property objects as JSON strings
    final longJson = longProps.isEmpty ? 'null' : _toJsonString(longProps);
    final stringJson = stringProps.isEmpty ? 'null' : _toJsonString(stringProps);
    final doubleJson = doubleProps.isEmpty ? 'null' : _toJsonString(doubleProps);
    
    // Call API with proper signature
    js.context.callMethod('eval', [
      'dtrum.addActionProperties($actionId, $longJson, null, $stringJson, $doubleJson)'
    ]);
    
    debugPrint('[Dynatrace] Properties added to action $actionId');
  } catch (e) {
    debugPrint('[Dynatrace] Error adding properties: $e');
  }
}

String _toJsonString(Map<String, dynamic> map) {
  final entries = map.entries.map((e) {
    final value = e.value is String ? '"${e.value}"' : e.value;
    return '"${e.key}": $value';
  }).join(', ');
  return '{$entries}';
}
```

### 5. sendSessionProperties()

**Signature:** `dtrum.sendSessionProperties(longProperties, dateProperties, stringProperties, doubleProperties)`

**Parameters:**
- `longProperties` (object, optional): Map of long/integer properties
- `dateProperties` (object, optional): Map of date properties  
- `stringProperties` (object, optional): Map of string properties
- `doubleProperties` (object, optional): Map of double/float properties

**Example:**
```javascript
// Add long properties
var longProps = {sessionCount: 5};
dtrum.sendSessionProperties(longProps);

// Add string properties
var stringProps = {userRole: 'authenticated', tier: 'premium'};
dtrum.sendSessionProperties(null, null, stringProps);

// Add multiple types
dtrum.sendSessionProperties(longProps, null, stringProps, null);
```

**Dart Implementation:**
```dart
void setSessionProperty(String key, dynamic value) {
  if (!isDynatraceAvailable) return;
  
  try {
    final escapedKey = key.replaceAll("'", "\\'");
    
    if (value is int) {
      js.context.callMethod('eval', [
        'dtrum.sendSessionProperties({"$escapedKey": $value})'
      ]);
    } else if (value is double) {
      js.context.callMethod('eval', [
        'dtrum.sendSessionProperties(null, null, null, {"$escapedKey": $value})'
      ]);
    } else {
      final escapedValue = value.toString().replaceAll("'", "\\'");
      js.context.callMethod('eval', [
        'dtrum.sendSessionProperties(null, null, {"$escapedKey": "$escapedValue"})'
      ]);
    }
    
    debugPrint('[Dynatrace] Session property set: $key = $value');
  } catch (e) {
    debugPrint('[Dynatrace] Error setting session property: $e');
  }
}
```

### 6. reportError()

**Signature:** `dtrum.reportError(errorMessage)` or `dtrum.reportError(errorObject)`

**Parameters:**
- `errorMessage` (string): Error message text
- OR `errorObject` (Error): JavaScript Error object

**Example:**
```javascript
// Simple error message
dtrum.reportError('Error: Something went wrong');

// With Error object
try {
  // some code
} catch (e) {
  dtrum.reportError(e);
}
```

**Dart Implementation:**
```dart
void reportError(String errorMessage, {String? errorType}) {
  if (!isDynatraceAvailable) return;
  
  try {
    final escapedMessage = errorMessage.replaceAll("'", "\\'").replaceAll('"', '\\"');
    js.context.callMethod('eval', [
      'dtrum.reportError(new Error("$escapedMessage"))'
    ]);
    debugPrint('[Dynatrace] Error reported: $errorMessage');
  } catch (e) {
    debugPrint('[Dynatrace] Error reporting error: $e');
  }
}
```

## Why eval() is Needed for Flutter/Dart

The issue with using `callMethod()` directly is that dart:js doesn't support:
1. Multiple positional arguments correctly
2. Optional/null arguments properly  
3. Complex object structures

**Solution:** Use `eval()` to execute JavaScript code as a string, which gives us full control over the exact API call format.

## Complete Fixed Implementation

See the updated `dynatrace_service.dart` file with corrected API calls using `eval()` for all Dynatrace methods.

## Testing

To verify the fixes:
1. Monitor browser console for Dynatrace API calls
2. Check Dynatrace RUM dashboard for:
   - User identification (Sessions -> User)
   - Custom actions appearing
   - Action properties attached
   - Session properties recorded
3. Verify no "Wrong argument types" warnings in console

## References

- Dynatrace RUM JavaScript API v1.329.4
- Sample files in `/Downloads/dynatraceapi-1.329.4.20260115-094557/samples/`
- Official docs: https://www.dynatrace.com/support/help/platform-modules/digital-experience/web-applications/initial-setup/rum-injection
