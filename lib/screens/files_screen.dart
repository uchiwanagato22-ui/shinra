import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/agent_service.dart';

class FilesScreen extends StatefulWidget {
  const FilesScreen({super.key});

  @override
  State<FilesScreen> createState() => _FilesScreenState();
}

class _FilesScreenState extends State<FilesScreen> {
  String _currentPath = "C:/"; // Chemin initial par défaut
  String _directoryContent = "";
  bool _loading = false;

  static const crimson = Color(0xFFE1233D);
  static const gold = Color(0xFFD4AF37);
  static const surface2 = Color(0xFF0D1225);

  @override
  void initState() {
    super.initState();
    _loadDirectory();
  }

  Future<void> _loadDirectory() async {
    setState(() => _loading = true);
    // On appelle notre agent Python en direct !
    final result = await AgentService.listDir(_currentPath);
    setState(() {
      _directoryContent = result;
      _loading = false;
    });
  }

  void _navigateTo(String newPath) {
    setState(() {
      _currentPath = newPath;
    });
    _loadDirectory();
  }

  @override
  Widget build(BuildContext context) {
    // Découpage des lignes renvoyées par Python
    final items = _directoryContent.split('\n').where((item) => item.isNotEmpty).toList();

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'EXPLORATEUR DE SYSTÈME',
            style: GoogleFonts.shareTechMono(color: crimson, fontSize: 24, letterSpacing: 2),
          ),
          const SizedBox(height: 10),
          
          // Barre de chemin d'accès
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: surface2,
              border: Border.all(color: crimson.withOpacity(0.2)),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                const Icon(Icons.computer, color: crimson, size: 16),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _currentPath,
                    style: GoogleFonts.shareTechMono(color: Colors.white, fontSize: 14),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: crimson, size: 16),
                  onPressed: _loadDirectory,
                )
              ],
            ),
          ),
          const SizedBox(height: 15),

          // Liste des fichiers et dossiers
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: crimson))
                : Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF060A12),
                      border: Border.all(color: Colors.white10),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: items.isEmpty || _directoryContent.contains('❌')
                        ? Center(
                            child: Text(
                              _directoryContent.contains('❌') 
                                  ? _directoryContent 
                                  : '// Dossier vide ou accès restreint',
                              style: GoogleFonts.shareTechMono(color: Colors.white38),
                            ),
                          )
                        : ListView.builder(
                            itemCount: items.length,
                            itemBuilder: (context, index) {
                              final rawItem = items[index];
                              final isDir = rawItem.startsWith('📁');
                              // Nettoyage de l'icône pour récupérer le nom pur
                              final name = rawItem.replaceFirst('📁 ', '').replaceFirst('📄 ', '');

                              return ListTile(
                                dense: true,
                                leading: Icon(
                                  isDir ? Icons.folder : Icons.insert_drive_file,
                                  color: isDir ? gold : crimson.withOpacity(0.7),
                                  size: 18,
                                ),
                                title: Text(
                                  name,
                                  style: GoogleFonts.rajdhani(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: isDir ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                                trailing: const Icon(Icons.chevron_right, color: Colors.white24, size: 14),
                                onTap: () {
                                  if (isDir) {
                                    // Gère la navigation dans les sous-dossiers
                                    final slash = _currentPath.endsWith('/') ? '' : '/';
                                    _navigateTo('$_currentPath$slash$name');
                                  } else {
                                    // C'est un fichier : on pourrait l'ouvrir avec AgentService.readFile !
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Lecture de $name disponible bientôt !')),
                                    );
                                  }
                                },
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}