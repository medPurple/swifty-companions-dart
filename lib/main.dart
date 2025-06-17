import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uni_links/uni_links.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:async';

import 'auth_service.dart';
import 'token_service.dart';
import 'research.dart';
import 'details.dart';

void main() {
  runApp(
    MaterialApp(
      initialRoute: '/',
      routes: {
        '/': (context) => MainScreen(),
        '/callback': (context) => CallbackScreen(),
      },
      debugShowCheckedModeBanner: false,
    ),
  );
}


class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  String? token;
  late List<Widget> _pages;
  final AuthService authService = AuthService();
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomeView(token: token, onLogin: handleLogin),
    ];
    listenForRedirect();
    checkExistingToken();
  }

  Future<void> checkExistingToken() async {
    final existingToken = await TokenService().getToken();
    if (existingToken != null) {
      setState(() {
        token = existingToken;
        _pages[0] = HomeView(token: token, onLogin: handleLogin);
      });
    }
  }

  void listenForRedirect() {
    if (kIsWeb) {
      final uri = Uri.base;
      if (uri.queryParameters.containsKey('code')) {
        final code = uri.queryParameters['code'];
        handleCode(code);
      }
    } else {
      _sub = uriLinkStream.listen((Uri? uri) {
        if (uri != null && uri.queryParameters.containsKey('code')) {
          final code = uri.queryParameters['code'];
          handleCode(code);
        }
      }, onError: (err) {
        print('Erreur de redirection: $err');
      });
    }
  }

  void handleCode(String? code) async {
    if (code == null) return;
    final accessToken = await authService.exchangeCodeForToken(code);
    if (accessToken != null) {
      await TokenService().saveToken(accessToken);
      setState(() {
        token = accessToken;
        _pages[0] = HomeView(token: token, onLogin: handleLogin);
      });
    }
  }



  void handleLogin() async {
    await authService.startAuth();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
    );
  }
}

class CallbackScreen extends StatefulWidget {
  @override
  _CallbackScreenState createState() => _CallbackScreenState();
}

class _CallbackScreenState extends State<CallbackScreen> {
  final AuthService authService = AuthService();

  @override
  void initState() {
    super.initState();
    _handleCallback();
  }

  void _handleCallback() async {
    final uri = Uri.base;
    final code = uri.queryParameters['code'];

    if (code != null) {
      final token = await authService.exchangeCodeForToken(code);
      if (token != null) {
        await TokenService().saveToken(token);
      } else {
        print("Échec de l'échange de code");
      }
    }

    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}