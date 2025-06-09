import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  // Singleton
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  final _client = Supabase.instance.client;

  // Agregar un niño
  Future<String> addChild({required String name, required DateTime birthdate}) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');
    final response = await _client.from('children').insert({
      'user_id': user.id,
      'name': name,
      'birthdate': birthdate.toIso8601String(),
    }).select('id').single();
    if (response == null || response['id'] == null) {
      throw Exception('No se pudo crear el niño');
    }
    return response['id'] as String;
  }

  // Obtener todos los niños del usuario
  Future<List<Map<String, dynamic>>> getChildren() async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');
    final response = await _client.from('children').select().eq('user_id', user.id);
    if (response == null) return [];
    return List<Map<String, dynamic>>.from(response);
  }

  // Obtener todos los juegos
  Future<List<Map<String, dynamic>>> getGames() async {
    final response = await _client.from('games').select();
    if (response == null) return [];
    return List<Map<String, dynamic>>.from(response);
  }

  // Guardar progreso
  Future<void> saveProgress({
    required String childId,
    required int gameId,
    required int score,
    required int level,
  }) async {
    await _client.from('progress').insert({
      'child_id': childId,
      'game_id': gameId,
      'score': score,
      'level': level,
      'played_at': DateTime.now().toIso8601String(),
    });
  }

  // Obtener progreso
  Future<List<Map<String, dynamic>>> getProgress({
    required String childId,
    int? gameId,
  }) async {
    var query = _client.from('progress').select().eq('child_id', childId);
    if (gameId != null) {
      query = query.eq('game_id', gameId);
    }
    final response = await query.order('played_at', ascending: false);
    if (response == null) return [];
    return List<Map<String, dynamic>>.from(response);
  }

  // Borrar todo el progreso del usuario
  Future<void> wipeAll() async {
    // Implementación pendiente
    throw UnimplementedError();
  }

  // Borrar todo el progreso de un niño
  Future<void> wipeChild(String childId) async {
    // Implementación pendiente
    throw UnimplementedError();
  }

  // Borrar el progreso de un juego de un niño
  Future<void> wipeChildGame(String childId, int gameId) async {
    await _client.rpc('wipe_child_game_progress', params: {'c_id': childId, 'g_id': gameId});
  }

  // Editar niño
  Future<void> updateChild({
    required String childId,
    required String name,
    required DateTime birthdate,
  }) async {
    await _client.from('children').update({
      'name': name,
      'birthdate': birthdate.toIso8601String(),
    }).eq('id', childId);
  }

  // Eliminar niño y su progreso
  Future<void> deleteChild(String childId) async {
    // Borra el progreso asociado usando el RPC
    await _client.rpc('wipe_child_progress', params: {'c_id': childId});
    // Borra el niño
    await _client.from('children').delete().eq('id', childId);
  }

  // Obtener preferencias del padre
  Future<Map<String, dynamic>?> getParentSettings() async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');
    final response = await _client.from('parent_settings').select().eq('user_id', user.id).maybeSingle();
    return response;
  }

  // Guardar o actualizar el PIN de padres
  Future<void> saveParentPin(String pin) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');
    final existing = await getParentSettings();
    if (existing == null) {
      await _client.from('parent_settings').insert({
        'user_id': user.id,
        'parent_pin': pin,
      });
    } else {
      await _client.from('parent_settings').update({'parent_pin': pin}).eq('user_id', user.id);
    }
  }

  // Obtener el PIN de padres
  Future<String?> getParentPin() async {
    final settings = await getParentSettings();
    return settings != null ? settings['parent_pin'] as String? : null;
  }

  // Guardar o actualizar el último niño seleccionado
  Future<void> saveLastSelectedChild(String? childId) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');
    final existing = await getParentSettings();
    if (existing == null) {
      await _client.from('parent_settings').insert({
        'user_id': user.id,
        'last_selected_child_id': childId,
      });
    } else {
      await _client.from('parent_settings').update({'last_selected_child_id': childId}).eq('user_id', user.id);
    }
  }

  // Obtener el último niño seleccionado
  Future<String?> getLastSelectedChild() async {
    final settings = await getParentSettings();
    return settings != null ? settings['last_selected_child_id'] as String? : null;
  }
} 