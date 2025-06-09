import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'supabase_service.dart';

class EstadisticasPage extends StatefulWidget {
  const EstadisticasPage({super.key});

  @override
  State<EstadisticasPage> createState() => _EstadisticasPageState();
}

class _EstadisticasPageState extends State<EstadisticasPage> {
  List<Map<String, dynamic>> _progress = [];
  Map<int, String> _gameNames = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() { _loading = true; });
    final prefs = await SharedPreferences.getInstance();
    final childId = prefs.getString('selected_child_id');
    if (childId != null) {
      final progress = await SupabaseService().getProgress(childId: childId);
      final games = await SupabaseService().getGames();
      final gameNames = {for (var g in games) g['id'] as int: g['name'] as String};
      setState(() {
        _progress = List<Map<String, dynamic>>.from(progress);
        _gameNames = gameNames;
        _loading = false;
      });
    } else {
      setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Estadísticas del niño')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _progress.isEmpty
              ? const Center(child: Text('No hay progreso registrado.'))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _progress.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, i) {
                    final p = _progress[i];
                    final gameName = _gameNames[p['game_id']] ?? 'Juego';
                    final fecha = DateTime.tryParse(p['played_at'] ?? '') ?? DateTime.now();
                    return ListTile(
                      leading: const Icon(Icons.emoji_events),
                      title: Text(gameName),
                      subtitle: Text('Fecha: ${fecha.day}/${fecha.month}/${fecha.year}  Score: ${p['score']}  Nivel: ${p['level']}'),
                    );
                  },
                ),
    );
  }
} 