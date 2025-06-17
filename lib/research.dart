import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'token_service.dart';
import 'details.dart';
import 'main.dart';

class HomeView extends StatefulWidget {
  final String? token;
  final VoidCallback onLogin;
  final Function(String?) onTokenUpdate; // Nouveau callback

  const HomeView({
    Key? key,
    required this.token,
    required this.onLogin,
    required this.onTokenUpdate,
  }) : super(key: key);

  @override
  _HomeViewState createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final TextEditingController _searchController = TextEditingController();
  final AuthService _authService = AuthService();
  final TokenService _tokenService = TokenService();
  bool _isLoading = false;

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

    setState(() {
      _isLoading = true;
    });

    try {
      final data = await _authService.searchUser(token, query);
      if (data == null) {
        // Vérifier si c'est un problème d'authentification
        final currentToken = await _tokenService.getAccessToken();
        if (currentToken == null) {
          _showSnack('Session expirée, veuillez vous reconnecter');
          widget.onTokenUpdate(null); // Mettre à jour l'état parent
        } else if (currentToken != token) {
          // Le token a été rafraîchi, mettre à jour l'état parent
          widget.onTokenUpdate(currentToken);
          _showSnack('Token mis à jour, réessayez');
        } else {
          _showSnack('Utilisateur non trouvé');
        }
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailsView(userData: data),
          ),
        );
      }
    } catch (e) {
      _showSnack('Erreur lors de la recherche');
      print('Search error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handleLogout() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.logout();
      widget.onTokenUpdate(null); // Mettre à jour l'état parent
      setState(() {
        _searchController.clear();
      });
      _showSnack('Déconnecté avec succès');
    } catch (e) {
      _showSnack('Erreur lors de la déconnexion');
      print('Logout error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSnack(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message), 
          duration: Duration(seconds: 3),
        ),
      );
    }
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
                  icon: const Icon(Icons.logout, color: Color(0xFFDC8D64)),
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
              const Text(
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
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
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
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
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
