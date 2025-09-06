// In lib/content_manager.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ContentManager extends ChangeNotifier {
  final SupabaseClient _client = Supabase.instance.client;

  Map<String, String> _siteContent = {};
  Map<String, String> get siteContent => _siteContent;

  Future<void> fetchContent() async {
    try {
      final List<Map<String, dynamic>> response = await _client
          .from('site_content')
          .select('key, value');

      final Map<String, String> newContent = {};
      for (var item in response) {
        newContent[item['key']] =
            item['value'] ?? ''; // Ensure value is not null
      }

      _siteContent = newContent;
      notifyListeners();
    } catch (e) {
      debugPrint("Error fetching site content: $e");
      throw Exception("Could not load site content.");
    }
  }

  // --- THIS IS THE NEW METHOD YOU NEED TO ADD ---
  // This allows the admin screen to update the state after saving.
  void updateAllContent(Map<String, String> newContent) {
    _siteContent = newContent;
    // Notify HomePage and any other listeners that the data has changed.
    notifyListeners();
  }
}
