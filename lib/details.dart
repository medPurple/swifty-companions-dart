import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

extension FirstOrNullExtension<E> on List<E> {
  E? get firstOrNull => isNotEmpty ? this.first : null;
}

String safeString(dynamic value, {String defaultValue = '-'}) {
  return value is String ? value : defaultValue;
}

int safeInt(dynamic value, {int defaultValue = 0}) {
  return value is int ? value : defaultValue;
}

double safeDouble(dynamic value, {double defaultValue = 0.0}) {
  return value is num ? value.toDouble() : defaultValue;
}

class DetailsView extends StatefulWidget {
  final Map<String, dynamic> userData;

  const DetailsView({Key? key, required this.userData}) : super(key: key);

  @override
  State<DetailsView> createState() => _DetailsViewState();
}

class _DetailsViewState extends State<DetailsView> {
  late int selectedCursusId;
  Map<int, bool> expandedProjects = {};
  bool showSkills = false;

  @override
  void initState() {
    super.initState();
    selectedCursusId = safeInt((widget.userData['cursus_users'] as List?)?.firstOrNull?['cursus_id']);
  }

  List<dynamic> get cursusUsers => widget.userData['cursus_users'] as List? ?? [];
  List<dynamic> get projects => widget.userData['projects_users'] as List? ?? [];

  Map<String, dynamic> get selectedCursusData {
    return cursusUsers.cast<Map<String, dynamic>>().firstWhere(
      (c) => c['cursus_id'] == selectedCursusId,
      orElse: () => {},
    );
  }

  List<dynamic> get selectedProjects => projects
      .where((project) => (project['cursus_ids'] as List?)?.contains(selectedCursusId) ?? false)
      .toList();

  String integerLevel(double level) => 'Niveau ${level.floor()}';
  String decimalLevel(double level) => ((level - level.floor()) * 100).toStringAsFixed(0);

  Color statusColor(validated) {
    if (validated == true) return Colors.lightGreen;
    if (validated == false) return Colors.redAccent.shade100;
    return Colors.tealAccent.shade400;
  }

  Future<void> openProjectUrl(String slug) async {
    final url = 'https://projects.intra.42.fr/projects/${slug.toLowerCase()}';
    if (await canLaunchUrl(url as Uri)) {
      await launchUrl(url as Uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossible d\'ouvrir $url')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.userData;
    final level = safeDouble(selectedCursusData['level']);
    final skills = selectedCursusData['skills'] as List? ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFF0F1F1A),
      appBar: AppBar(
        title: Text(
          safeString(user['displayname']),
          style: const TextStyle(color: Color(0xFFDC8D64), fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFFDC8D64)),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 50,
                backgroundImage: NetworkImage(
                  safeString(user['image']?['link'], defaultValue: 'https://via.placeholder.com/100'),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                safeString(user['login']),
                style: const TextStyle(
                  fontSize: 22,
                  color: Color(0xFFDC8D64),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Campus 42 ${safeString((user['campus'] as List?)?.firstOrNull?['city'])}',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 4),
              Text(
                safeString(user['email']),
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 4),
              Text(
                user['phone'] != 'hidden' ? safeString(user['phone']) : 'Numéro privé',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 10),
              Text(
                'Correction points: ${safeInt(user['correction_point'])}',
                style: const TextStyle(color: Color(0xFFDC8D64), fontWeight: FontWeight.w600),
              ),
              Text(
                'Wallet: ${safeInt(user['wallet'])}',
                style: const TextStyle(color: Color(0xFFDC8D64), fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 30),

          Text('Cursus', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Color(0xFFDC8D64))),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1F2E2B),
              borderRadius: BorderRadius.circular(14),
            ),
            child: DropdownButton<int>(
              dropdownColor: const Color(0xFF1F2E2B),
              value: selectedCursusId,
              isExpanded: true,
              iconEnabledColor: const Color(0xFFDC8D64),
              style: const TextStyle(color: Colors.white),
              underline: Container(),
              items: cursusUsers.map<DropdownMenuItem<int>>((cursusUser) {
                return DropdownMenuItem(
                  value: safeInt(cursusUser['cursus_id']),
                  child: Text(safeString(cursusUser['cursus']?['name'])),
                );
              }).toList(),
              onChanged: (int? newValue) {
                if (newValue != null) {
                  setState(() {
                    selectedCursusId = newValue;
                  });
                }
              },
            ),
          ),

          const SizedBox(height: 20),
          Text('Informations sur le cursus', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Color(0xFFDC8D64))),
          const SizedBox(height: 8),
          Text(integerLevel(level),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Stack(
            children: [
              Container(
                height: 20,
                decoration: BoxDecoration(
                  color: const Color(0xFF1F2E2B),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              FractionallySizedBox(
                widthFactor: level % 1,
                child: Container(
                  height: 20,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDC8D64),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              Positioned.fill(
                child: Center(
                  child: Text(
                    '${decimalLevel(level)}%',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),

          TextButton(
            onPressed: () {
              setState(() {
                showSkills = !showSkills;
              });
            },
            child: Text(
              showSkills ? '⬆ Skills ⬆' : '⬇ Skills ⬇',
              style: const TextStyle(color: Color(0xFFDC8D64), fontWeight: FontWeight.bold),
            ),
          ),

          if (showSkills)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(
                skills.length,
                (index) {
                  final skill = skills[index] as Map<String, dynamic>;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      '• ${safeString(skill['name'])} - ${safeDouble(skill['level']).toStringAsFixed(2)}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  );
                },
              ),
            ),

          const SizedBox(height: 30),
          if (selectedProjects.isNotEmpty) ...[
            Text('Projets', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Color(0xFFDC8D64))),
            const SizedBox(height: 10),
            ...selectedProjects.map((projectData) {
              final project = projectData as Map<String, dynamic>;
              final isExpanded = expandedProjects[project['id']] ?? false;
              final name = safeString(project['project']?['name']);
              final slug = safeString(project['project']?['slug']);
              return Card(
                color: statusColor(project['validated?']),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  title: Text(
                    name,
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                  subtitle: isExpanded
                      ? TextButton(
                          onPressed: () => openProjectUrl(slug),
                          child: const Text('Lien du projet', style: TextStyle(color: Color(0xFFB74C28))),
                        )
                      : null,
                  trailing: Text(
                    safeInt(project['final_mark']).toString(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  onTap: () {
                    setState(() {
                      expandedProjects[project['id']] = !isExpanded;
                    });
                  },
                ),
              );
            }).toList(),
          ],
        ],
      ),
    );
  }
}
