import 'package:shared_preferences/shared_preferences.dart';

class RecentSearchService {
  static const String _recentSearchesKey = 'recent_searches';
  final int _maxRecentSearches = 10;

  // Save a search term to recent searches
  Future<void> saveSearchTerm(String searchTerm) async {
    if (searchTerm.trim().isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    List<String> recentSearches = prefs.getStringList(_recentSearchesKey) ?? [];

    // Remove if already exists to avoid duplicates
    recentSearches.remove(searchTerm);

    // Add to beginning of list
    recentSearches.insert(0, searchTerm);

    // Keep only the last 10 searches
    if (recentSearches.length > _maxRecentSearches) {
      recentSearches = recentSearches.sublist(0, _maxRecentSearches);
    }

    await prefs.setStringList(_recentSearchesKey, recentSearches);
  }

  // Get recent searches
  Future<List<String>> getRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_recentSearchesKey) ?? [];
  }

  // Remove a specific search term
  Future<void> removeSearchTerm(String searchTerm) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> recentSearches = prefs.getStringList(_recentSearchesKey) ?? [];
    recentSearches.remove(searchTerm);
    await prefs.setStringList(_recentSearchesKey, recentSearches);
  }

  // Clear all recent searches
  Future<void> clearAllRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_recentSearchesKey);
  }
}
