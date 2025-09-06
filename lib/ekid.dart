import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';

// Add this to your plan_model.dart file
class PlanItem {
  final String id;
  final String title;
  final String? description;
  final DateTime? planDate;
  final String? assignee;
  final String? teamName;
  final bool isDone;

  PlanItem({
    required this.id,
    required this.title,
    this.description,
    this.planDate,
    this.assignee,
    this.teamName,
    this.isDone = false,
  });

  // Add this copyWith method to fix the error
  PlanItem copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? planDate,
    String? assignee,
    String? teamName,
    bool? isDone,
  }) {
    return PlanItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      planDate: planDate ?? this.planDate,
      assignee: assignee ?? this.assignee,
      teamName: teamName ?? this.teamName,
      isDone: isDone ?? this.isDone,
    );
  }
}

class PlanControlScreen extends StatefulWidget {
  const PlanControlScreen({super.key});

  @override
  _PlanControlScreenState createState() => _PlanControlScreenState();
}

class _PlanControlScreenState extends State<PlanControlScreen> {
  List<PlanItem> _plans = [];
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _selectedDate;
  String? _selectedAssignee;
  String? _selectedTeam;
  String _currentFilter = 'all';

  final List<String> _assignees = ['Alice', 'Bob', 'Charlie', 'Diana'];
  final List<String> _teams = ['Team A', 'Team B', 'Development', 'Marketing'];

  Widget _buildNeumorphicContainer({
    required BuildContext context,
    required Widget child,
    double borderRadius = 12,
    Color? color,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: color ?? (isDarkMode ? Colors.grey[800]! : Colors.grey[200]!),
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: isDarkMode ? Colors.black54 : Colors.grey.shade500,
            offset: const Offset(4, 4),
            blurRadius: 8,
          ),
          BoxShadow(
            color: isDarkMode ? Colors.grey[900]! : Colors.white,
            offset: const Offset(-4, -4),
            blurRadius: 8,
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildNeumorphicInputField({
    required TextEditingController controller,
    required String labelText,
    required BuildContext context,
    int? maxLines,
    String? Function(String?)? validator,
  }) {
    return _buildNeumorphicContainer(
      context: context,
      borderRadius: 10,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: TextFormField(
          controller: controller,
          decoration: InputDecoration(
            labelText: labelText,
            labelStyle: GoogleFonts.poppins(color: Colors.grey[600]),
            border: InputBorder.none,
          ),
          maxLines: maxLines,
          style: GoogleFonts.poppins(),
          validator: validator,
        ),
      ),
    );
  }

  Widget _buildNeumorphicDropdown({
    required String? value,
    required String hint,
    required List<String> items,
    required void Function(String?) onChanged,
    required BuildContext context,
    String? Function(String?)? validator,
  }) {
    return _buildNeumorphicContainer(
      context: context,
      borderRadius: 10,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            labelText: hint,
            labelStyle: GoogleFonts.poppins(color: Colors.grey[600]),
            border: InputBorder.none,
          ),
          items: items
              .map(
                (item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(item, style: GoogleFonts.poppins()),
                ),
              )
              .toList(),
          onChanged: onChanged,
          style: GoogleFonts.poppins(),
          validator: validator,
          isExpanded: true,
        ),
      ),
    );
  }

  void _addPlan() {
    if (_formKey.currentState!.validate()) {
      final newPlan = PlanItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text,
        description: _descriptionController.text,
        planDate: _selectedDate,
        assignee: _selectedAssignee,
        teamName: _selectedTeam,
      );
      setState(() => _plans.add(newPlan));
      _clearForm();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Plan added successfully')));
      Navigator.of(context).pop();
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  // Show the add plan form in a dialog
  void _showAddPlanDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Plan'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Title'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a title';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12), // Add spacing
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(labelText: 'Description'),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12), // Add spacing
                  // Dropdown for Assignee
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Who will do it?',
                    ),
                    value: _selectedAssignee,
                    items: _assignees.map((assignee) {
                      return DropdownMenuItem<String>(
                        value: assignee,
                        child: Text(assignee),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedAssignee = newValue;
                      });
                    },
                    validator: (value) => value == null
                        ? 'Please select an assignee'
                        : null, // Optional Validation
                  ),
                  const SizedBox(height: 12), // Add spacing
                  // Dropdown for Team Name
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Team Name'),
                    value: _selectedTeam,
                    items: _teams.map((team) {
                      return DropdownMenuItem<String>(
                        value: team,
                        child: Text(team),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedTeam = newValue;
                      });
                    },
                    validator: (value) => value == null
                        ? 'Please select a team'
                        : null, // Optional Validation
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedDate == null
                            ? 'Select Date'
                            : 'Date: ${DateFormat.yMMMd().format(_selectedDate!)}',
                      ),
                      ElevatedButton(
                        onPressed: () => _selectDate(context),
                        child: const Text('Choose Date'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss dialog
                _clearForm(); // Clear the form
              },
            ),
            ElevatedButton(
              child: const Text('Add'),
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  _addPlan();
                  Navigator.of(context).pop(); // Dismiss dialog
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _clearForm() {
    _titleController.clear();
    _descriptionController.clear();
    _selectedDate = null;
    _selectedAssignee = null;
    _selectedTeam = null;
  }

  void _togglePlanStatus(String planId) {
    setState(() {
      _plans = _plans.map((plan) {
        if (plan.id == planId) {
          return plan.copyWith(isDone: !plan.isDone);
        }
        return plan;
      }).toList();
    });
  }

  void _deletePlan(String planId) {
    setState(() => _plans.removeWhere((plan) => plan.id == planId));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Plan deleted')));
  }

  List<PlanItem> get _filteredPlans {
    switch (_currentFilter) {
      case 'active':
        return _plans.where((plan) => !plan.isDone).toList();
      case 'completed':
        return _plans.where((plan) => plan.isDone).toList();
      default:
        return _plans;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final accentColor = const Color(0xFF8B4513);

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
      appBar: AppBar(
        title: Text(
          'Plan Control',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) => setState(() => _currentFilter = value),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('All Plans')),
              const PopupMenuItem(value: 'active', child: Text('Active Plans')),
              const PopupMenuItem(
                value: 'completed',
                child: Text('Completed Plans'),
              ),
            ],
          ),
        ],
      ),
      body: _plans.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FadeIn(
                    child: Icon(
                      Icons.assignment,
                      size: 60,
                      color: Colors.grey[400],
                    ),
                  ),
                  const SizedBox(height: 16),
                  FadeInUp(
                    child: Text(
                      'No plans yet',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        color: textColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  FadeInUp(
                    delay: const Duration(milliseconds: 100),
                    child: Text(
                      'Tap the + button to add a new plan',
                      style: GoogleFonts.poppins(color: Colors.grey),
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredPlans.length,
              itemBuilder: (context, index) {
                final plan = _filteredPlans[index];
                return FadeInUp(
                  duration: const Duration(milliseconds: 400),
                  delay: Duration(milliseconds: index * 100),
                  child: Dismissible(
                    key: Key(plan.id),
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    direction: DismissDirection.endToStart,
                    confirmDismiss: (direction) async {
                      return await showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: Theme.of(
                            context,
                          ).scaffoldBackgroundColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          title: Text(
                            'Confirm',
                            style: GoogleFonts.poppins(color: textColor),
                          ),
                          content: Text(
                            'Delete this plan?',
                            style: GoogleFonts.poppins(color: textColor),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: Text(
                                'Cancel',
                                style: GoogleFonts.poppins(color: Colors.grey),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: accentColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: Text(
                                'Delete',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    onDismissed: (_) => _deletePlan(plan.id),
                    child: _buildNeumorphicContainer(
                      context: context,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    plan.title,
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                      decoration: plan.isDone
                                          ? TextDecoration.lineThrough
                                          : null,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    plan.isDone
                                        ? Icons.check_circle
                                        : Icons.check_circle_outline,
                                    color: plan.isDone
                                        ? Colors.green
                                        : Colors.grey,
                                  ),
                                  onPressed: () => _togglePlanStatus(plan.id),
                                ),
                              ],
                            ),
                            if (plan.description?.isNotEmpty ?? false) ...[
                              const SizedBox(height: 8),
                              Text(
                                plan.description!,
                                style: GoogleFonts.poppins(color: textColor),
                              ),
                            ],
                            if (plan.assignee?.isNotEmpty ?? false) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.person, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    plan.assignee!,
                                    style: GoogleFonts.poppins(
                                      color: textColor,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (plan.teamName?.isNotEmpty ?? false) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.group, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    plan.teamName!,
                                    style: GoogleFonts.poppins(
                                      color: textColor,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (plan.planDate != null) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    DateFormat.yMMMd().format(plan.planDate!),
                                    style: GoogleFonts.poppins(
                                      color: textColor,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddPlanDialog(context),
        backgroundColor: accentColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
