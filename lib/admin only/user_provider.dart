import 'package:flutter/material.dart';
import 'package:amde_haymanot_abalat_guday/main.dart';

/// Manages the current user's permissions, profile picture, and authentication state.
///
/// This provider fetches a user's screen access permissions from Supabase
/// and notifies listeners when the user logs in, logs out, or when permissions
/// are updated. It also caches the user's avatar URL.
class UserProvider extends ChangeNotifier {
  // --- Private State Variables ---

  // A constant set of screens that should be available to ALL logged-in users,
  // regardless of their specific role or permissions from the database.
  // This ensures the app is always navigable even if the permission fetch fails.
  static const Set<String> _kPublicLoggedInScreens = {
    '/home',
    '/profile',
    '/learning',
    '/book-reviews',
    '/attendance-history',
    '/amde-platform',
    '/about-us',
    '/family-view',
  };

  Set<String> _allowedScreens = {};
  String? _avatarUrl;
  bool _isLoading = false;
  bool _isInitialFetchDone = false;

  // --- Public Getters ---

  Set<String> get allowedScreens => _allowedScreens;
  bool get isLoading => _isLoading;
  String? get avatarUrl => _avatarUrl;

  bool canAccess(String screenKey) => _allowedScreens.contains(screenKey);
  bool get isSuperiorAdmin => _allowedScreens.contains('/admin/permission-manager');
  bool get isAdmin => _allowedScreens.contains('/admin/user-manager');

  UserProvider() {
    supabase.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (_isInitialFetchDone) {
        if (session != null) {
          fetchUserPermissions();
        } else {
          clear();
        }
      }
    });
    _initialize();
  }

  Future<void> _initialize() async {
    if (supabase.auth.currentSession != null) {
      await fetchUserPermissions();
    }
    _isInitialFetchDone = true;
  }

  /// Fetches the current user's permissions from the Supabase backend.
  Future<void> fetchUserPermissions() async {
    if (_isLoading) return;

    try {
      _isLoading = true;
      notifyListeners();

      final response = await supabase.rpc('get_my_permissions').single();

      debugPrint("--- UserProvider: Received from Supabase ---");
      debugPrint("Response data: $response");

      if (response != null && response['screens'] is List) {
        final screenList = (response['screens'] as List<dynamic>).cast<String>();
        // SUCCESS: Combine public screens with fetched screens
        _allowedScreens = {..._kPublicLoggedInScreens, ...screenList};
        debugPrint("Successfully parsed and merged screens: $_allowedScreens");
      } else {
        // Response was null or malformed, but user is logged in. Default to public screens.
        _allowedScreens = _kPublicLoggedInScreens;
        debugPrint("Response was null. Setting allowed screens to public defaults.");
      }
    } catch (e) {
      debugPrint("--- UserProvider: ERROR fetching user permissions ---");
      debugPrint("Error: $e");
      // FAILURE (e.g., no internet): Instead of clearing, default to public screens.
      // This ensures the user isn't stuck with an empty drawer.
      _allowedScreens = _kPublicLoggedInScreens;
      debugPrint("Fetch failed. Setting allowed screens to public defaults.");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setAvatarUrl(String? url) {
    if (_avatarUrl != url) {
      _avatarUrl = url;
      notifyListeners();
    }
  }

  /// Clears all user permissions and data. Called ONLY on logout.
  void clear() {
    _allowedScreens = {};
    _avatarUrl = null;
    notifyListeners();
  }
}