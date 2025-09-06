// lib/screens/admin_manage_users.dart
import 'package:flutter/material.dart';
import 'package:amde_haymanot_abalat_guday/main.dart'; // To get supabase client
import 'package:amde_haymanot_abalat_guday/roles.dart'; // Your enums

// A simple model to hold the combined profile data
class UserProfile {
  final String id;
  final String fullName;
  final String email;
  final AppDepartment department;
  final AppPosition position;

  UserProfile({
    required this.id,
    required this.fullName,
    required this.email,
    required this.department,
    required this.position,
  });
}

class AdminManageUsersScreen extends StatefulWidget {
  const AdminManageUsersScreen({super.key});

  @override
  State<AdminManageUsersScreen> createState() => _AdminManageUsersScreenState();
}

class _AdminManageUsersScreenState extends State<AdminManageUsersScreen> {
  late Future<List<UserProfile>> _usersFuture;

  @override
  void initState() {
    super.initState();
    _usersFuture = _fetchUserProfiles();
  }

  // Helper to convert string from DB to Enum safely
  T _enumFromString<T>(String key, List<T> values) {
    return values.firstWhere(
      (v) => v.toString().split('.').last == key,
      orElse: () => values.first,
    );
  }

  Future<List<UserProfile>> _fetchUserProfiles() async {
    try {
      final response = await supabase
          .from('profiles')
          .select(
            'id, full_name, department, position, users(email)',
          ); // Join with auth.users to get email

      final List<UserProfile> profiles = [];
      for (var item in response) {
        profiles.add(
          UserProfile(
            id: item['id'],
            fullName: item['full_name'] ?? 'No Name',
            email: item['users']['email'] ?? 'No Email',
            department: _enumFromString(
              item['department'],
              AppDepartment.values,
            ),
            position: _enumFromString(item['position'], AppPosition.values),
          ),
        );
      }
      return profiles;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error fetching users: $e"),
          backgroundColor: Colors.red,
        ),
      );
      return [];
    }
  }

  Future<void> _showEditRoleDialog(UserProfile user) async {
    AppDepartment selectedDepartment = user.department;
    AppPosition selectedPosition = user.position;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        // Use a StatefulWidget inside the dialog to manage its own state
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text("Edit Role for ${user.fullName}"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Dropdown for Department
                    DropdownButtonFormField<AppDepartment>(
                      value: selectedDepartment,
                      decoration: const InputDecoration(
                        labelText: 'Department',
                      ),
                      items: AppDepartment.values.map((dept) {
                        return DropdownMenuItem(
                          value: dept,
                          child: Text(dept.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => selectedDepartment = value);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    // Dropdown for Position
                    DropdownButtonFormField<AppPosition>(
                      value: selectedPosition,
                      decoration: const InputDecoration(labelText: 'Position'),
                      items: AppPosition.values.map((pos) {
                        return DropdownMenuItem(
                          value: pos,
                          child: Text(pos.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => selectedPosition = value);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      await supabase
                          .from('profiles')
                          .update({
                            'department': selectedDepartment.name,
                            'position': selectedPosition.name,
                          })
                          .eq('id', user.id);

                      Navigator.of(
                        context,
                      ).pop(true); // Close dialog and signal success
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Failed to update role: $e"),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: const Text("Save"),
                ),
              ],
            );
          },
        );
      },
    );

    // If the update was successful, refresh the list
    if (result == true) {
      setState(() {
        _usersFuture = _fetchUserProfiles();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("User role updated successfully!"),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Manage User Roles")),
      body: FutureBuilder<List<UserProfile>>(
        future: _usersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No users found."));
          }

          final users = snapshot.data!;
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: ListTile(
                  title: Text(
                    user.fullName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "${user.department.name.toUpperCase()} - ${user.position.name}",
                  ),
                  trailing: const Icon(Icons.edit),
                  onTap: () => _showEditRoleDialog(user),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
