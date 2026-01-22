import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dynatrace_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Wrap entire app with automatic gesture detection
    return DynatraceGestureDetector(
      child: MaterialApp(
        title: 'Flutter Auth App',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        // Add NavigatorObserver for automatic screen tracking
        navigatorObservers: [DynatraceNavigatorObserver()],
        home: const LoginPage(),
      ),
    );
  }
}

// Login Page
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with DynatraceTracking {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _errorMessage = '';
  bool _isLoading = false;
  final DynatraceService _dynatrace = DynatraceService();

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      try {
        const url = 'http://localhost:3000/api/login';
        
        final response = await http.post(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'username': _usernameController.text,
            'password': _passwordController.text,
          }),
        );

        setState(() {
          _isLoading = false;
        });

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final username = data['username'];
          
          // Identify user in Dynatrace
          _dynatrace.identifyUser(username);
          _dynatrace.setSessionProperty('userRole', 'authenticated');
          
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => MenuPage(username: username),
                settings: const RouteSettings(name: 'MenuPage'),
              ),
            );
          }
        } else {
          final data = jsonDecode(response.body);
          
          setState(() {
            _errorMessage = data['message'] ?? 'Login failed';
          });
        }
      } catch (e) {
        // Track error
        _dynatrace.reportError('Login error: $e');
        
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error: $e';
        });
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Login'),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.lock_outline,
                  size: 80,
                  color: Colors.blue,
                ),
                const SizedBox(height: 32),
                const Text(
                  'Welcome',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your username';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.password),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'Login',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
                const SizedBox(height: 16),
                if (_errorMessage.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _errorMessage,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.red.shade900,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Menu Page
class MenuPage extends StatelessWidget {
  final String username;

  const MenuPage({super.key, required this.username});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text('Welcome, $username'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () {
              DynatraceService().setSessionProperty('userRole', 'guest');
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const LoginPage(),
                  settings: const RouteSettings(name: 'LoginPage'),
                ),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Select an Option',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              Card(
                elevation: 4,
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HashGeneratorPage(),
                        settings: const RouteSettings(name: 'HashGeneratorPage'),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.tag,
                          size: 48,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Generate Hash',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Generate SHA-256 hash from text',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Card(
                elevation: 4,
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CalculatorPage(),
                        settings: const RouteSettings(name: 'CalculatorPage'),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.calculate,
                          size: 48,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Simple Calculator',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Perform basic arithmetic operations',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Hash Generator Page
class HashGeneratorPage extends StatefulWidget {
  const HashGeneratorPage({super.key});

  @override
  State<HashGeneratorPage> createState() => _HashGeneratorPageState();
}

class _HashGeneratorPageState extends State<HashGeneratorPage> with DynatraceTracking {
  final TextEditingController _messageController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _result = '';
  bool _isLoading = false;

  Future<void> _generateHash() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _result = '';
      });

      try {
        const url = 'http://localhost:3000/api/hash';
        
        final response = await http.post(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'message': _messageController.text,
          }),
        );

        setState(() {
          _isLoading = false;
        });

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          
          setState(() {
            _result = data['hash'];
          });
        } else {
          final data = jsonDecode(response.body);
          
          setState(() {
            _result = 'Error: ${data['message']}';
          });
        }
      } catch (e) {
        // Report error to Dynatrace
        DynatraceService().reportError('Hash generation error: $e');
        
        setState(() {
          _isLoading = false;
          _result = 'Error: $e';
        });
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Generate Hash'),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Enter Message',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    labelText: 'Message',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.message),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a message';
                    }
                    return null;
                  },
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _generateHash,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'Generate Hash',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
                const SizedBox(height: 24),
                if (_result.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _result.startsWith('Error')
                          ? Colors.red.shade100
                          : Colors.green.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _result.startsWith('Error') ? 'Error' : 'SHA-256 Hash:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: _result.startsWith('Error')
                                ? Colors.red.shade900
                                : Colors.green.shade900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SelectableText(
                          _result,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: _result.startsWith('Error')
                                ? Colors.red.shade900
                                : Colors.green.shade900,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Calculator Page
class CalculatorPage extends StatefulWidget {
  const CalculatorPage({super.key});

  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage> with DynatraceTracking {
  final TextEditingController _firstNumberController = TextEditingController();
  final TextEditingController _secondNumberController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _selectedOperator = '+';
  String _result = '';
  bool _isLoading = false;

  final List<String> _operators = ['+', '-', '*', '/'];

  Future<void> _calculate() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _result = '';
      });

      try {
        const url = 'http://localhost:3000/api/calculate';
        
        final response = await http.post(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'firstNumber': _firstNumberController.text,
            'operator': _selectedOperator,
            'secondNumber': _secondNumberController.text,
          }),
        );

        setState(() {
          _isLoading = false;
        });

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          
          setState(() {
            _result = '${data['firstNumber']} ${data['operator']} ${data['secondNumber']} = ${data['result']}';
          });
        } else {
          final data = jsonDecode(response.body);
          
          setState(() {
            _result = 'Error: ${data['message']}';
          });
        }
      } catch (e) {
        // Report error to Dynatrace
        DynatraceService().reportError('Calculation error: $e');
        
        setState(() {
          _isLoading = false;
          _result = 'Error: $e';
        });
      }
    }
  }

  @override
  void dispose() {
    _firstNumberController.dispose();
    _secondNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Simple Calculator'),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Calculate',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _firstNumberController,
                  decoration: const InputDecoration(
                    labelText: 'First Number',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.looks_one),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a number';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedOperator,
                  decoration: const InputDecoration(
                    labelText: 'Operator',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.functions),
                  ),
                  items: _operators.map((String operator) {
                    return DropdownMenuItem<String>(
                      value: operator,
                      child: Text(
                        operator,
                        style: const TextStyle(fontSize: 20),
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedOperator = newValue!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _secondNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Second Number',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.looks_two),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a number';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _calculate,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'Calculate',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
                const SizedBox(height: 24),
                if (_result.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _result.startsWith('Error')
                          ? Colors.red.shade100
                          : Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _result,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _result.startsWith('Error')
                            ? Colors.red.shade900
                            : Colors.blue.shade900,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
