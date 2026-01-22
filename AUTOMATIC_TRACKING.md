# Automatic Dynatrace Tracking - No Manual Names Required! 🎉

## The Problem (Solved!)
❌ Before: Had to manually specify action names for every button
❌ Impractical for banks with hundreds of buttons
❌ Code like: `trackTap('Button Name', () => ...)`

## The Solution ✅
Now buttons **automatically extract their text and context**!

### How It Works

#### 1. **ElevatedButton - Automatic Text Extraction**
```dart
// Old way - manual naming:
ElevatedButton(
  onPressed: () => trackTap('Submit Form', () => submit()),
  child: Text('Submit'),
)

// NEW way - AUTOMATIC:
DynatraceTrackedButton.elevatedButton(
  onPressed: () => submit(),
  child: Text('Submit'),  // ← Text automatically extracted!
)

// Dynatrace sees: "LoginPage: Submit"
```

#### 2. **IconButton - Automatic Tooltip/Icon Detection**
```dart
// NEW - AUTOMATIC:
DynatraceTrackedButton.iconButton(
  icon: Icon(Icons.logout),
  tooltip: 'Logout',  // ← Tooltip automatically used!
  onPressed: () => logout(),
)

// Dynatrace sees: "MenuPage: Logout"
```

#### 3. **InkWell/Cards - Automatic Content Extraction**
```dart
// NEW - AUTOMATIC:
DynatraceTrackedButton.inkWell(
  onTap: () => navigate(),
  child: Column(
    children: [
      Text('Generate Hash'),  // ← Text automatically found!
      Text('Description...'),
    ],
  ),
)

// Dynatrace sees: "MenuPage: Generate Hash"
```

### What Gets Automatically Tracked

✅ **Button text** - Extracted from child Text widgets  
✅ **Screen name** - From route settings (LoginPage, MenuPage, etc.)  
✅ **Icon tooltips** - Used for icon buttons  
✅ **Card content** - First Text widget found in child tree  
✅ **Properties** - Optional custom properties still supported  

### Action Names Generated Automatically

| Widget | What You See in Dynatrace |
|--------|---------------------------|
| Login button | `LoginPage: Login` |
| Logout icon | `MenuPage: Logout` |
| Hash card | `MenuPage: Generate Hash` |
| Calculator card | `MenuPage: Simple Calculator` |
| Generate button | `HashGeneratorPage: Generate Hash` |
| Calculate button | `CalculatorPage: Calculate` |

### How to Use in Your Banking App

#### For Standard Buttons:
```dart
DynatraceTrackedButton.elevatedButton(
  onPressed: () => transferMoney(),
  child: Text('Transfer'),  // ← That's it! No manual naming!
)
```

#### For Icon Buttons:
```dart
DynatraceTrackedButton.iconButton(
  icon: Icon(Icons.send),
  tooltip: 'Send Payment',  // ← Just add tooltip!
  onPressed: () => sendPayment(),
)
```

#### For Custom Widgets/Cards:
```dart
DynatraceTrackedButton.inkWell(
  onTap: () => openFeature(),
  child: YourCustomWidget(
    title: 'Account Details',  // ← Will find this text!
  ),
)
```

### Manual Override (When Needed)
```dart
// Still can override if auto-detection doesn't work:
DynatraceTrackedButton.elevatedButton(
  onPressed: () => submit(),
  actionName: 'Custom Action Name',  // ← Optional override
  properties: {'amount': '100'},      // ← Optional properties
  child: Icon(Icons.check),
)
```

### Benefits for Banking Apps

1. **No Code Duplication** ✅
   - Write button once with text
   - Tracking happens automatically
   - No separate tracking code per button

2. **Maintainable** ✅
   - Change button text → action name updates automatically
   - Add new buttons → automatically tracked
   - Refactor screens → routes tracked automatically

3. **Scales Easily** ✅
   - Works for 10 buttons or 1000 buttons
   - Same simple pattern everywhere
   - No manual tracking list to maintain

4. **Rich Context** ✅
   - Screen name always included
   - Button text always captured
   - Optional properties for business context

### Migration Guide

Replace your existing buttons:

```dart
// Before:
ElevatedButton(
  onPressed: () => action(),
  child: Text('Submit'),
)

// After - just wrap the widget type:
DynatraceTrackedButton.elevatedButton(
  onPressed: () => action(),
  child: Text('Submit'),
)

// Before:
IconButton(
  icon: Icon(Icons.logout),
  onPressed: () => logout(),
)

// After - use iconButton method:
DynatraceTrackedButton.iconButton(
  icon: Icon(Icons.logout),
  tooltip: 'Logout',
  onPressed: () => logout(),
)

// Before:
InkWell(
  onTap: () => navigate(),
  child: Card(...),
)

// After - use inkWell method:
DynatraceTrackedButton.inkWell(
  onTap: () => navigate(),
  child: Card(...),
)
```

### Implementation Details

The widget automatically:
1. **Extracts button text** from child Text widgets
2. **Gets current route name** from Navigator
3. **Combines them**: `"RouteName: ButtonText"`
4. **Sends to Dynatrace** before executing your callback
5. **Includes optional properties** if you provide them

### Example Output in Dynatrace

User session for `admin`:
```
├─ Screen: LoginPage
├─ LoginPage: Login Attempt
├─ LoginPage: Login Success  
├─ Navigate to MenuPage
├─ Screen: MenuPage
├─ MenuPage: Generate Hash          ← Automatically extracted!
├─ Navigate to HashGeneratorPage
├─ Screen: HashGeneratorPage
├─ HashGeneratorPage: Generate Hash ← Automatically extracted!
├─ Hash Generated Successfully
└─ MenuPage: Logout                 ← Automatically extracted!
```

## Summary

🎯 **Zero manual naming for standard buttons**  
🎯 **Automatic text extraction from widgets**  
🎯 **Route context always included**  
🎯 **Scales to thousands of buttons**  
🎯 **Perfect for banking applications**

Just wrap your buttons with `DynatraceTrackedButton.elevatedButton()`, `iconButton()`, or `inkWell()` - that's it!
