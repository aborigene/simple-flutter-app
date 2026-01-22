import 'dart:js' as js;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/gestures.dart';

/// Service to interact with Dynatrace RUM JavaScript API
class DynatraceService {
  static final DynatraceService _instance = DynatraceService._internal();
  factory DynatraceService() => _instance;
  DynatraceService._internal();

  /// Check if Dynatrace is available
  bool get isDynatraceAvailable {
    try {
      return js.context.hasProperty('dtrum');
    } catch (e) {
      return false;
    }
  }

  /// Identify the current user
  void identifyUser(String username) {
    if (!isDynatraceAvailable) return;
    
    try {
      final escapedUsername = username.replaceAll("'", "\\'");
      js.context.callMethod('eval', ['dtrum.identifyUser("$escapedUsername")']);
      debugPrint('[Dynatrace] User identified: $username');
    } catch (e) {
      debugPrint('[Dynatrace] Error identifying user: $e');
    }
  }

  /// Send a custom action to Dynatrace
  void sendAction(String actionName, {Map<String, dynamic>? properties}) {
    if (!isDynatraceAvailable) return;
    
    try {
      // Escape action name for safe eval
      final escapedName = actionName.replaceAll("'", "\\'");
      
      // Enter action and get ID
      final result = js.context.callMethod('eval', ["dtrum.enterAction('$escapedName')"]);
      final actionId = (result is num) ? result.toInt() : null;
      
      // Add properties if provided
      if (actionId != null && properties != null && properties.isNotEmpty) {
        _addActionProperties(actionId, properties);
      }
      
      // Leave action to complete it
      if (actionId != null) {
        js.context.callMethod('eval', ['dtrum.leaveAction($actionId)']);
      }
      
      debugPrint('[Dynatrace] Action sent: $actionName');
    } catch (e) {
      debugPrint('[Dynatrace] Error sending action: $e');
    }
  }

  /// Helper method to add properties to an action
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
      
      // Call API with proper signature: addActionProperties(actionId, long, date, string, double)
      js.context.callMethod('eval', [
        'dtrum.addActionProperties($actionId, $longJson, null, $stringJson, $doubleJson)'
      ]);
      
      debugPrint('[Dynatrace] Properties added to action $actionId');
    } catch (e) {
      debugPrint('[Dynatrace] Error adding properties: $e');
    }
  }

  /// Convert map to JSON string for eval
  String _toJsonString(Map<String, dynamic> map) {
    final entries = map.entries.map((e) {
      final value = e.value is String ? '"${e.value}"' : e.value;
      return '"${e.key}": $value';
    }).join(', ');
    return '{$entries}';
  }

  /// Report an error to Dynatrace
  void reportError(String errorMessage, {String? errorType}) {
    if (!isDynatraceAvailable) return;
    
    try {
      final escapedMessage = errorMessage.replaceAll("'", "\\'").replaceAll('"', '\\"');
      js.context.callMethod('eval', ['dtrum.reportError(new Error("$escapedMessage"))']);
      debugPrint('[Dynatrace] Error reported: $errorMessage');
    } catch (e) {
      debugPrint('[Dynatrace] Error reporting error: $e');
    }
  }

  /// Send session properties
  void setSessionProperty(String key, dynamic value) {
    if (!isDynatraceAvailable) return;
    
    try {
      final escapedKey = key.replaceAll("'", "\\'");
      
      if (value is int) {
        // Send as long property
        js.context.callMethod('eval', [
          'dtrum.sendSessionProperties({"$escapedKey": $value})'
        ]);
      } else if (value is double) {
        // Send as double property
        js.context.callMethod('eval', [
          'dtrum.sendSessionProperties(null, null, null, {"$escapedKey": $value})'
        ]);
      } else {
        // Send as string property
        final escapedValue = value.toString().replaceAll("'", "\\'").replaceAll('"', '\\"');
        js.context.callMethod('eval', [
          'dtrum.sendSessionProperties(null, null, {"$escapedKey": "$escapedValue"})'
        ]);
      }
      
      debugPrint('[Dynatrace] Session property set: $key = $value');
    } catch (e) {
      debugPrint('[Dynatrace] Error setting session property: $e');
    }
  }

  /// Leave current action (deprecated - now handled automatically in sendAction)
  void leaveAction() {
    if (!isDynatraceAvailable) return;
    
    try {
      js.context.callMethod('eval', ['dtrum.leaveAction()']);
      debugPrint('[Dynatrace] Action left');
    } catch (e) {
      debugPrint('[Dynatrace] Error leaving action: $e');
    }
  }
}

/// NavigatorObserver to automatically track screen navigation
class DynatraceNavigatorObserver extends NavigatorObserver {
  final DynatraceService _dynatrace = DynatraceService();

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _trackNavigation(route, 'push');
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _trackNavigation(previousRoute, 'pop');
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) {
      _trackNavigation(newRoute, 'replace');
    }
  }

  void _trackNavigation(Route<dynamic>? route, String action) {
    if (route == null) return;
    
    final routeName = route.settings.name ?? _extractRouteName(route);
    if (routeName.isNotEmpty) {
      // Only track meaningful navigation - simplified action name
      _dynatrace.sendAction('Page: $routeName', properties: {
        'page': routeName,
      });
    }
  }

  String _extractRouteName(Route<dynamic> route) {
    // Try to extract route name from widget type
    if (route is MaterialPageRoute) {
      final widget = route.builder(route.navigator!.context);
      return widget.runtimeType.toString();
    }
    return 'Unknown';
  }
}

/// Mixin to add automatic Dynatrace tracking to StatefulWidgets
mixin DynatraceTracking<T extends StatefulWidget> on State<T> {
  final DynatraceService _dynatrace = DynatraceService();

  // NOTE: Removed automatic initState tracking to reduce duplicate actions
  // NavigatorObserver already tracks page changes

  /// Track a user action (manual call only when needed)
  void trackAction(String actionName, {Map<String, dynamic>? properties}) {
    _dynatrace.sendAction(actionName, properties: properties);
  }
}

/// Widget wrapper to automatically track button/tap interactions
class DynatraceTrackedButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final String? actionName;
  final Map<String, dynamic>? properties;

  const DynatraceTrackedButton({
    super.key,
    required this.child,
    this.onPressed,
    this.actionName,
    this.properties,
  });

  @override
  Widget build(BuildContext context) {
    return child;
  }

  /// Wrap an ElevatedButton with automatic tracking
  static Widget elevatedButton({
    required Widget child,
    required VoidCallback? onPressed,
    String? actionName,
    Map<String, dynamic>? properties,
    ButtonStyle? style,
  }) {
    return Builder(
      builder: (context) {
        return ElevatedButton(
          onPressed: onPressed == null ? null : () {
            // Simple action name: just "Click: ButtonText"
            final autoName = actionName ?? _extractTextFromWidget(child);
            DynatraceService().sendAction('Click: $autoName', properties: properties);
            onPressed();
          },
          style: style,
          child: child,
        );
      },
    );
  }

  /// Wrap an IconButton with automatic tracking
  static Widget iconButton({
    required Widget icon,
    required VoidCallback? onPressed,
    String? actionName,
    Map<String, dynamic>? properties,
    String? tooltip,
  }) {
    return Builder(
      builder: (context) {
        return IconButton(
          icon: icon,
          tooltip: tooltip,
          onPressed: onPressed == null ? null : () {
            // Simple action name: just "Click: IconName" or tooltip
            final autoName = actionName ?? tooltip ?? _extractIconType(icon);
            DynatraceService().sendAction('Click: $autoName', properties: properties);
            onPressed();
          },
        );
      },
    );
  }

  /// Wrap an InkWell/GestureDetector with automatic tracking
  static Widget inkWell({
    required Widget child,
    required VoidCallback? onTap,
    String? actionName,
    Map<String, dynamic>? properties,
  }) {
    return Builder(
      builder: (context) {
        return InkWell(
          onTap: onTap == null ? null : () {
            // Simple action name: just "Click: ElementText"
            final autoName = actionName ?? _extractTextFromWidget(child);
            DynatraceService().sendAction('Click: $autoName', properties: properties);
            onTap();
          },
          child: child,
        );
      },
    );
  }

  /// Create a tracked tap callback (legacy, use widget methods instead)
  static VoidCallback trackTap(
    String actionName,
    VoidCallback onTap, {
    Map<String, dynamic>? properties,
  }) {
    return () {
      DynatraceService().sendAction(actionName, properties: properties);
      onTap();
    };
  }

  /// Extract text from a widget tree
  static String _extractTextFromWidget(Widget widget) {
    if (widget is Text) {
      final data = widget.data;
      if (data != null) return data;
      final span = widget.textSpan;
      if (span is TextSpan) return span.toPlainText();
    }
    
    if (widget is Icon) {
      return widget.icon.toString().replaceAll('IconData(U+', '').replaceAll(')', '');
    }

    // Try to find Text widget in children
    if (widget is Row || widget is Column || widget is Padding || widget is Center) {
      try {
        final String widgetString = widget.toString();
        final match = RegExp(r'Text\("([^"]+)"\)').firstMatch(widgetString);
        if (match != null) return match.group(1) ?? 'Unknown';
      } catch (e) {
        // Ignore
      }
    }

    return widget.runtimeType.toString();
  }

  /// Extract icon type
  static String _extractIconType(Widget icon) {
    if (icon is Icon) {
      final iconString = icon.icon.toString();
      if (iconString.contains('logout')) return 'Logout Button';
      if (iconString.contains('login')) return 'Login Button';
      if (iconString.contains('menu')) return 'Menu Button';
      if (iconString.contains('back')) return 'Back Button';
      if (iconString.contains('close')) return 'Close Button';
      return 'Icon Button';
    }
    return 'Button';
  }
}

/// Global gesture detector to track all taps automatically
/// Wrap your MaterialApp with this to get automatic click tracking without modifying buttons
class DynatraceGestureDetector extends StatelessWidget {
  final Widget child;

  const DynatraceGestureDetector({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (event) {
        // Try to identify what was clicked
        _handleTap(context, event);
      },
      child: child,
    );
  }

  void _handleTap(BuildContext context, PointerDownEvent event) {
    try {
      // Perform hit test to find what was clicked
      final result = HitTestResult();
      WidgetsBinding.instance.hitTest(result, event.position);
      
      // Look for interactive widgets in the hit test results
      for (final entry in result.path) {
        final target = entry.target;
        
        // Check if we hit a RenderObject
        if (target is RenderBox) {
          // Try to find the widget that owns this RenderObject
          final element = _findElementForRenderBox(target);
          if (element != null) {
            final actionName = _extractActionFromElement(element);
            if (actionName != null) {
              DynatraceService().sendAction('Click: $actionName', properties: {
                'x': event.position.dx.round(),
                'y': event.position.dy.round(),
              });
              break; // Only track the first meaningful widget found
            }
          }
        }
      }
    } catch (e) {
      // Silently fail - don't break the app
      debugPrint('[Dynatrace] Error tracking click: $e');
    }
  }

  Element? _findElementForRenderBox(RenderBox box) {
    Element? result;
    void visitor(Element element) {
      if (element.renderObject == box) {
        result = element;
      }
      if (result == null) {
        element.visitChildren(visitor);
      }
    }
    
    try {
      WidgetsBinding.instance.renderViewElement?.visitChildren(visitor);
    } catch (e) {
      // Ignore errors during traversal
    }
    
    return result;
  }

  String? _extractActionFromElement(Element element) {
    final widget = element.widget;
    
    // Check for buttons
    if (widget is ElevatedButton || widget is TextButton || widget is OutlinedButton) {
      return _extractTextFromButtonChild(widget);
    }
    
    if (widget is IconButton) {
      final iconButton = widget as IconButton;
      return iconButton.tooltip ?? 'Icon Button';
    }
    
    if (widget is InkWell || widget is GestureDetector) {
      // Try to extract text from child
      final childText = _findTextInChildren(element);
      if (childText != null) return childText;
    }
    
    // Check for Card with InkWell (like menu items)
    if (widget is Card) {
      final childText = _findTextInChildren(element);
      if (childText != null) return childText;
    }
    
    return null;
  }

  String? _extractTextFromButtonChild(dynamic button) {
    // Try to get child widget
    try {
      if (button is ButtonStyleButton) {
        final child = button.child;
        if (child is Text) {
          return child.data ?? child.textSpan?.toPlainText();
        }
      }
    } catch (e) {
      // Ignore
    }
    return null;
  }

  String? _findTextInChildren(Element element) {
    String? foundText;
    
    void visitor(Element child) {
      if (foundText != null) return;
      
      final widget = child.widget;
      if (widget is Text) {
        foundText = widget.data ?? widget.textSpan?.toPlainText();
        return;
      }
      
      if (foundText == null) {
        child.visitChildren(visitor);
      }
    }
    
    try {
      element.visitChildren(visitor);
    } catch (e) {
      // Ignore errors
    }
    
    return foundText;
  }
}

/// Extension on BuildContext for easy tracking
extension DynatraceContext on BuildContext {
  void trackAction(String actionName, {Map<String, dynamic>? properties}) {
    DynatraceService().sendAction(actionName, properties: properties);
  }
}
