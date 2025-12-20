import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'main_shell.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:paryatan_mantralaya_f/config.dart';

class Loginsignup extends StatefulWidget {
  const Loginsignup({super.key});

  @override
  State<Loginsignup> createState() => _LoginsignupState();
}

class _LoginsignupState extends State<Loginsignup> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _isLogin = true;
  bool _loading = false;

  // Future<void> fetchUsers() async {
  //   final url = 'http://127.0.0.1:8000/login'; // Sample API
  //   final response = await http.post(
  //   Uri.parse(url),
  //   headers: <String, String>{
  //     'Content-Type': 'application/json; charset=UTF-8',
  //   },
  //   body: jsonEncode(<String, String>{
  //     'username': _usernameCtrl.text,
  //     'password': _passwordCtrl.text,
  //   }),
  // );
  //   // if (response.statusCode == 201) {
  //   //   // If the server returns a successful response, parse the JSON
  //     var data = jsonDecode(response.body); // Decode the response body
  //     print(data); // Just printing the data for now
  //   // } else {
  //   //   // If the request failed, throw an error
  //   //   throw Exception('Failed to load users');
  //   // }
  // }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() {
      _isLogin = !_isLogin;
      _formKey.currentState?.reset();
      _usernameCtrl.clear();
      _passwordCtrl.clear();
      _confirmCtrl.clear();
    });
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final url = _isLogin
        ? '${API_URL}/login'
        : '${API_URL}/register';

    final bodyMap = _isLogin
        ? {
            'username': _usernameCtrl.text.trim(),
            'password': _passwordCtrl.text,
          }
        : {
            'username': _usernameCtrl.text.trim(),
            'email': _usernameCtrl.text.trim(),
            'password': _passwordCtrl.text,
          };

    // For login we send form-encoded data, for register we send JSON
    final headers = <String, String>{
      'Content-Type': _isLogin
          ? 'application/x-www-form-urlencoded; charset=UTF-8'
          : 'application/json; charset=UTF-8',
    };

    final body = _isLogin
        ? Uri(queryParameters: bodyMap.map((k, v) => MapEntry(k, v.toString()))).query
        : jsonEncode(bodyMap);

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: body,
      ).timeout(const Duration(seconds: 10));

      if (!mounted) return;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        dynamic data;
        try {
          data = jsonDecode(response.body);
          print(data);
        } catch (_) {
          data = null;
        }

        final message = (data is Map && (data['message'] ?? data['detail'] ?? data['msg']) != null)
            ? (data['message'] ?? data['detail'] ?? data['msg']).toString()
            : (_isLogin ? 'Logged in' : 'Account created');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );

        // Save token if present
        if (data is Map) {
          final token = (data['token'] ?? data['access'] ?? data['access_token'] ?? data['auth_token'] ?? data['idToken'])?.toString();
          if (token != null && token.isNotEmpty) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('auth_token', token);
            // Optionally save username
            await prefs.setString('username', _usernameCtrl.text.trim());
          }
        }

        // On success navigate to main shell (replace login route)
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => MainShell()),
        );
      } else {
        String errorMsg;
        try {
          final data = jsonDecode(response.body);
          errorMsg = (data is Map && (data['error'] ?? data['detail'] ?? data['message']) != null)
              ? (data['error'] ?? data['detail'] ?? data['message']).toString()
              : response.body;
        } catch (_) {
          errorMsg = response.body.isNotEmpty
              ? response.body
              : 'Request failed with status ${response.statusCode}';
        }

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $errorMsg')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Network error: ${e.toString()}')),
      );
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(title: Padding(
      //   padding: const EdgeInsets.fromLTRB(0, 40, 0, 0),
      //   child: Center(child: Text("TravlApes", style: TextStyle(fontSize: 44),)),
      // )),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 0, 0, 40),
                child: Center(
                  child: Text("TravlApes", style: TextStyle(fontSize: 44)),
                ),
              ),
              SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              _isLogin ? 'Welcome back' : 'Create account',
                              style: Theme.of(context).textTheme.headlineMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _usernameCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Username',
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                              keyboardType: TextInputType.text,
                              // validator: (v) {
                              //   if (v == null || v.trim().isEmpty)
                              //     return 'Username required';
                              //   if (v.trim().length < 3)
                              //     return 'Username must be 3+ chars';
                              //   return null;
                              // },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _passwordCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Password',
                                prefixIcon: Icon(Icons.lock_outline),
                              ),
                              obscureText: true,
                              // validator: (v) {
                              //   if (v == null || v.isEmpty)
                              //     return 'Password required';
                              //   if (v.length < 6)
                              //     return 'Password must be 6+ chars';
                              //   return null;
                              // },
                            ),
                            if (!_isLogin) ...[
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _confirmCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Confirm password',
                                  prefixIcon: Icon(Icons.lock),
                                ),
                                obscureText: true,
                                // validator: (v) {
                                //   if (v == null || v.isEmpty)
                                //     return 'Please confirm password';
                                //   if (v != _passwordCtrl.text)
                                //     return 'Passwords do not match';
                                //   return null;
                                // },
                              ),
                            ],
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: _loading ? null : _submit,
                              child: _loading
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      _isLogin ? 'Sign in' : 'Create account',
                                    ),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: _toggleMode,
                              child: Text(
                                _isLogin
                                    ? "Don't have an account? Sign up"
                                    : 'Already have an account? Sign in',
                              ),
                            ),
                          ],
                        ),
                      ),
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
