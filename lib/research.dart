import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'token_service.dart';
import 'details.dart';
import 'main.dart';

class HomeView extends StatefulWidget {
  final String? token;
  final VoidCallback onLogin;

  const HomeView({
    Key? key,
    required this.token,
    required this.onLogin,
  }) : super(key: key);

  @override
  _HomeViewState createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final TextEditingController _searchController = TextEditingController();
  final AuthService _authService = AuthService();

  void _handleSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      _showSnack('Veuillez saisir un login 42');
      return;
    }

    final token = widget.token;
    if (token == null) {
      _showSnack('Vous devez être connecté');
      return;
    }

    final data = await _authService.searchUser(token, query);
    if (data == null) {
      _showSnack('Utilisateur non trouvé');
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DetailsView(userData: data),
        ),
      );
    }
  }

  void _handleLogout() async {
    await TokenService().clearToken();
    setState(() {
      _searchController.clear();
    });
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => MainScreen()),
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = widget.token != null;

    return Scaffold(
      backgroundColor: const Color(0xFF0F1F1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: isConnected
            ? [
                IconButton(
                  icon: Icon(Icons.logout, color: Color(0xFFDC8D64)),
                  onPressed: _handleLogout,
                  tooltip: 'Déconnexion',
                ),
              ]
            : null,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Swifty\nCompanions',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFDC8D64),
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 40),
              if (!isConnected) ...[
                ElevatedButton(
                  onPressed: widget.onLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB74C28),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Se connecter', style: TextStyle(fontSize: 18)),
                ),
              ] else ...[
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F2E2B),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Enter a 42 login',
                      hintStyle: TextStyle(color: Colors.white70),
                    ),
                    onSubmitted: (_) => _handleSearch(),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _handleSearch,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB74C28),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Search', style: TextStyle(fontSize: 18)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
