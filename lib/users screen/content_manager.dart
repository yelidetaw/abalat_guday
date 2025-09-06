import 'package:flutter/material.dart';
import 'package:amde_haymanot_abalat_guday/main.dart'; // For Supabase client
import 'dart:developer' as developer;

// A clean model to hold all the data for the homepage.
class PageContent {
  final Map<String, dynamic> siteContent;
  final List<Map<String, dynamic>> newsAndEvents;
  final List<Map<String, dynamic>> serviceTimes;

  PageContent({
    required this.siteContent,
    required this.newsAndEvents,
    required this.serviceTimes,
  });

  factory PageContent.empty() => PageContent(siteContent: {}, newsAndEvents: [], serviceTimes: []);
}

class ContentManager extends ChangeNotifier {
  PageContent _content = PageContent.empty();
  bool _isLoading = true;
  String? _error;

  PageContent get content => _content;
  Map<String, dynamic> get siteContent => _content.siteContent;
  bool get isLoading => _isLoading;
  String? get error => _error;

  ContentManager() {
    fetchContent();
  }

  Future<void> fetchContent() async {
    if(!_isLoading) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      final response = await supabase.rpc('get_homepage_content').single();
      
      // --- ROBUST DATA PARSING ---
      // This block safely handles nulls from the database to prevent TypeErrors.
      _content = PageContent(
        siteContent: response['site_content'] is Map<String, dynamic>
            ? response['site_content']
            : {},
        newsAndEvents: response['news_and_events'] is List
            ? List<Map<String, dynamic>>.from(response['news_and_events'])
            : [],
        serviceTimes: response['service_times'] is List
            ? List<Map<String, dynamic>>.from(response['service_times'])
            : [],
      );
      _error = null;
    } catch (e, s) {
      developer.log("Error fetching homepage content", name: "ContentManager", error: e, stackTrace: s);
      _error = "የገጽ መረጃን መጫን አልተሳካም።";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}