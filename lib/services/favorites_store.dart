import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/station.dart';

/// Favourites and "last played" state — stored locally on-device via
/// SharedPreferences only. Never leaves the phone, same principle as the
/// desktop app's ~/.config JSON files.
class FavoritesStore {
  static const _favKey = 'favorites';
  static const _lastStationKey = 'last_station';
  static const _volumeKey = 'volume';

  Future<List<Station>> loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_favKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) => Station.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> saveFavorites(List<Station> favs) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_favKey, jsonEncode(favs.map((s) => s.toJson()).toList()));
  }

  Future<bool> isFavorite(String stationUuid) async {
    final favs = await loadFavorites();
    return favs.any((s) => s.stationUuid == stationUuid);
  }

  Future<List<Station>> toggleFavorite(Station station) async {
    final favs = await loadFavorites();
    final idx = favs.indexWhere((s) => s.stationUuid == station.stationUuid);
    if (idx == -1) {
      favs.add(station);
    } else {
      favs.removeAt(idx);
    }
    await saveFavorites(favs);
    return favs;
  }

  Future<void> saveLastState({required Station? station, required double volume}) async {
    final prefs = await SharedPreferences.getInstance();
    if (station != null) {
      await prefs.setString(_lastStationKey, jsonEncode(station.toJson()));
    }
    await prefs.setDouble(_volumeKey, volume);
  }

  Future<Station?> loadLastStation() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_lastStationKey);
    if (raw == null) return null;
    return Station.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<double> loadLastVolume() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_volumeKey) ?? 0.8;
  }
}
