import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:amde_haymanot_abalat_guday/main.dart'; // Adjust import if needed
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// --- DATA MODELS ---
// (Your data models remain the same)
class Department {
  final String id;
  final String name;
  final String? description;
  final Color color;
  final int taskCount;

  Department({
    required this.id,
    required this.name,
    this.description,
    required this.color,
    this.taskCount = 0,
  });

  factory Department.fromJson(Map<String, dynamic> json) {
    var plans = json['plans'];
    int count = 0;
    if (plans != null && plans is List && plans.isNotEmpty) {
      count = plans[0]['count'] ?? 0;
    }
    return Department(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      color: _parseColor(json['color_code']?.toString()),
      taskCount: count,
    );
  }

  static Color _parseColor(String? colorCode) {
    const List<Color> departmentColors = [
      Color(0xFF8B4513),
      Color(0xFF5F9EA0),
      Color(0xFFD2691E),
      Color(0xFF6495ED),
      Color(0xFFDC143C),
      Color(0xFF20B2AA),
      Color(0xFF9370DB),
      Color(0xFF32CD32),
      Color(0xFF8A2BE2),
      Color(0xFFFF6347),
      Color(0xFF4169E1)
    ];
    try {
      if (colorCode == null || colorCode.isEmpty) return departmentColors[0];
      String hex = '0xFF${colorCode.replaceAll('#', '')}';
      return Color(int.parse(hex));
    } catch (e) {
      return departmentColors[colorCode.hashCode % departmentColors.length];
    }
  }
}

class PlanItem {
  final String id;
  final String title;
  final String? description;
  final DateTime? planDate;
  final String? assigneeId;
  final String? assigneeName;
  final String departmentId;
  final String departmentName;
  final Color departmentColor;
  final bool isDone;
  final DateTime createdAt;

  PlanItem({
    required this.id,
    required this.title,
    this.description,
    this.planDate,
    this.assigneeId,
    this.assigneeName,
    required this.departmentId,
    required this.departmentName,
    required this.departmentColor,
    this.isDone = false,
    required this.createdAt,
  });

  factory PlanItem.fromJson(Map<String, dynamic> json) {
    return PlanItem(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      planDate: json['plan_date'] != null
          ? DateTime.tryParse(json['plan_date'] ?? '')
          : null,
      assigneeId: json['assignee_id']?.toString(),
      assigneeName: json['assignee']?['full_name']?.toString(),
      departmentId: json['department_id']?.toString() ?? '',
      departmentName: json['department']?['name']?.toString() ?? 'ያልታወቀ ክፍል',
      departmentColor:
          Department._parseColor(json['department']?['color_code']?.toString()),
      isDone: json['is_done'] as bool? ?? false,
      createdAt: DateTime.parse(
          json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class PlanControlScreen extends StatefulWidget {
  const PlanControlScreen({super.key});

  @override
  State<PlanControlScreen> createState() => _PlanControlScreenState();
}

class _PlanControlScreenState extends State<PlanControlScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  final _formKey = GlobalKey<FormState>();

  static const Color primaryColor = Color.fromARGB(255, 1, 37, 100);
  static const Color accentColor = Color(0xFFFFD700);

  List<Department> _allowedDepartments = [];
  List<PlanItem> _plans = [];
  List<Map<String, dynamic>> _assignees = [];
  int _currentTabIndex = 0;
  String? _selectedDepartmentIdForFilter;

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // --- NEW: Centralized Error Logging Function ---
  void _logError(String functionName, Object e, StackTrace s) {
    debugPrint('''
    ===============================================================
    [ERROR] In PlanControlScreen -> $functionName
    ---------------------------------------------------------------
    MESSAGE:
    $e
    ---------------------------------------------------------------
    STACK TRACE:
    $s
    ===============================================================
    ''');
  }

  Future<void> _initializeData() async {
    try {
      if (!mounted) return;
      setState(() => _isLoading = true);
      await Future.wait([_loadAllowedDepartments(), _loadAssignees()]);
      await _loadPlans();
    } catch (e, s) {
      _logError('_initializeData', e, s);
      if (mounted) _showErrorSnackbar('መረጃውን በማምጣት ላይ ስህተት ተፈጥሯል።');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ===========================================================================
  // DATA LOADING AND CORE LOGIC (WITH ENHANCED LOGGING)
  // ===========================================================================

  Future<void> _loadAllowedDepartments() async {
    try {
      final response = await supabase.rpc('get_my_department_permissions');
      if (response == null || (response as List).isEmpty) {
        if (mounted) setState(() => _allowedDepartments = []);
        return;
      }
      final List<String> myDeptIds = List<String>.from(response);
      final data = await supabase
          .from('departments')
          .select('*, plans(count)')
          .inFilter('id', myDeptIds)
          .order('name', ascending: true);
      if (mounted) {
        setState(() => _allowedDepartments =
            data.map((json) => Department.fromJson(json)).toList());
      }
    } catch (e, s) {
      _logError('_loadAllowedDepartments', e, s);
      _showErrorSnackbar('የተፈቀዱ ክፍሎችን በማምጣት ላይ ስህተት ተፈጥሯል።');
    }
  }

  Future<void> _loadPlans() async {
    try {
      if (!mounted) return;
      setState(() => _isLoading = true);
      var query = supabase.from('plans').select('''*,
        assignee:profiles!plans_assignee_id_fkey(full_name),
        department:departments(id, name, color_code)''');

      if (_currentTabIndex == 1 && _selectedDepartmentIdForFilter != null) {
        query = query.eq('department_id', _selectedDepartmentIdForFilter!);
      } else {
        final response = await supabase.rpc('get_my_department_permissions');
        if (response == null || (response as List).isEmpty) {
          if (mounted) setState(() => _plans = []);
          return;
        }
        final List<String> myDeptIds = List<String>.from(response);
        query = query.inFilter('department_id', myDeptIds);
      }
      final data = await query.order('created_at', ascending: false);
      if (mounted) {
        setState(() => _plans =
            data.map<PlanItem>((json) => PlanItem.fromJson(json)).toList());
      }
    } catch (e, s) {
      _logError('_loadPlans', e, s);
      if (mounted) _showErrorSnackbar('እቅዶችን በማምጣት ላይ ስህተት ተፈጥሯል።');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadAssignees() async {
    try {
      final data = await supabase.from('profiles').select('id, full_name');
      if (mounted) setState(() => _assignees = data);
    } catch (e, s) {
      _logError('_loadAssignees', e, s);
      _showErrorSnackbar('ኃላፊዎችን በማምጣት ላይ ስህተት ተፈጥሯል።');
    }
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging || !mounted) return;
    setState(() {
      _currentTabIndex = _tabController.index;
      if (_currentTabIndex == 0) _selectedDepartmentIdForFilter = null;
    });
    _loadPlans();
  }

  Future<void> _deletePlan(String planId) async {
    try {
      await supabase.from('plans').delete().eq('id', planId);
      setState(() {
        _plans.removeWhere((plan) => plan.id == planId);
      });
      _showSuccessSnackbar("እቅዱ በተሳካ ሁኔታ ተሰርዟል።");
      await _loadAllowedDepartments(); // Refresh task count
    } catch (e, s) {
      _logError('_deletePlan', e, s);
      _showErrorSnackbar("እቅዱን መሰረዝ አልተቻለም።");
    }
  }

  Future<void> _togglePlanStatus(PlanItem plan, bool isDone) async {
    try {
      await supabase
          .from('plans')
          .update({'is_done': isDone}).eq('id', plan.id);
      setState(() {
        final index = _plans.indexWhere((p) => p.id == plan.id);
        if (index != -1) {
          _plans[index] =
              PlanItem.fromJson({...plan.toJson(), 'is_done': isDone});
        }
      });
    } catch (e, s) {
      _logError('_togglePlanStatus', e, s);
      _showErrorSnackbar("የእቅዱን ሁኔታ ማዘመን አልተቻለም።");
    }
  }

  Future<void> _addPlan(
      String departmentId, String? assigneeId, DateTime? date) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');
      final newPlan = {
        'title': _titleController.text,
        'description': _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        'plan_date': date?.toIso8601String(),
        'department_id': departmentId,
        'assignee_id': assigneeId,
        'created_by': user.id
      };
      await supabase.from('plans').insert(newPlan);
      await _initializeData(); // Refresh everything
      _showSuccessSnackbar('እቅዱ በተሳካ ሁኔታ ተጨምሯል።');
    } catch (e, s) {
      _logError('_addPlan', e, s);
      _showErrorSnackbar('እቅድ ሲጨመር ስህተት ተፈጥሯል።');
    }
  }

  Future<void> _updatePlan(PlanItem plan, String departmentId,
      String? assigneeId, DateTime? date, bool isDone) async {
    try {
      final updatedPlan = {
        'title': _titleController.text,
        'description': _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        'plan_date': date?.toIso8601String(),
        'assignee_id': assigneeId,
        'department_id': departmentId,
        'is_done': isDone
      };
      await supabase.from('plans').update(updatedPlan).eq('id', plan.id);
      await _initializeData(); // Refresh everything
      _showSuccessSnackbar('እቅዱ በተሳካ ሁኔታ ተስተካክሏል።');
    } catch (e, s) {
      _logError('_updatePlan', e, s);
      _showErrorSnackbar('እቅድ ሲስተካከል ስህተት ተፈጥሯል።');
    }
  }

  // --- UI Methods and Snackbars (No changes needed below this line) ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        title: Text('እቅድ ቁጥጥር',
            style: GoogleFonts.notoSansEthiopic(
                fontWeight: FontWeight.w600, color: accentColor)),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: accentColor),
            onPressed: () => context.go('/home')),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: accentColor,
          labelColor: accentColor,
          labelStyle: GoogleFonts.notoSansEthiopic(fontWeight: FontWeight.w600),
          unselectedLabelColor: accentColor.withOpacity(0.7),
          tabs: const [
            Tab(icon: Icon(Icons.dashboard_rounded), text: "ክፍላት"),
            Tab(icon: Icon(Icons.list_alt_rounded), text: "ሁሉም እቅዶች"),
          ],
        ),
      ),
      body: _isLoading && _allowedDepartments.isEmpty
          ? const Center(child: CircularProgressIndicator(color: accentColor))
          : TabBarView(
              controller: _tabController,
              children: [_buildDepartmentGrid(), _buildPlanList()]),
      floatingActionButton: FloatingActionButton(
        onPressed: _allowedDepartments.isNotEmpty
            ? () => _showAddOrEditPlanDialog()
            : null,
        backgroundColor:
            _allowedDepartments.isNotEmpty ? accentColor : Colors.grey.shade700,
        tooltip: _allowedDepartments.isNotEmpty
            ? 'አዲስ እቅድ ያክሉ'
            : 'እቅድ ለመጨመር የተፈቀደ ክፍል የለም',
        foregroundColor: primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildDepartmentGrid() {
    if (_allowedDepartments.isEmpty) {
      return Center(
          child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Text("እቅዶችን ለማየት ወይም ለማስተዳደር የተፈቀደልዎት ክፍል የለም።",
            textAlign: TextAlign.center,
            style:
                GoogleFonts.notoSansEthiopic(color: accentColor, fontSize: 18)),
      ));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      itemCount: _allowedDepartments.length,
      itemBuilder: (context, index) {
        final department = _allowedDepartments[index];
        return FadeInUp(
          delay: Duration(milliseconds: index * 50),
          child: Card(
            elevation: 4,
            color: department.color,
            clipBehavior: Clip.antiAlias,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Stack(
              children: [
                Positioned.fill(
                  child: InkWell(
                    onTap: () {
                      setState(
                          () => _selectedDepartmentIdForFilter = department.id);
                      _tabController.animateTo(1);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              department.color.withOpacity(0.7),
                              department.color
                            ]),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(department.name,
                                style: GoogleFonts.notoSansEthiopic(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis),
                            Align(
                              alignment: Alignment.bottomRight,
                              child: Chip(
                                backgroundColor: Colors.white.withOpacity(0.2),
                                label: Text('${department.taskCount} እቅዶች',
                                    style: GoogleFonts.notoSansEthiopic(
                                        color: Colors.white, fontSize: 12)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: Material(
                    color: Colors.transparent,
                    child: IconButton(
                      icon: const Icon(Icons.add_circle),
                      color: Colors.white.withOpacity(0.9),
                      tooltip: "ለዚህ ክፍል እቅድ ያክሉ",
                      onPressed: () =>
                          _showAddOrEditPlanDialog(departmentId: department.id),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlanList() {
    if (_isLoading)
      return const Center(child: CircularProgressIndicator(color: accentColor));
    if (_plans.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.assignment_outlined,
              size: 80, color: accentColor.withOpacity(0.3)),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Text(
              _selectedDepartmentIdForFilter == null
                  ? 'ምንም እቅድ አልተገኘም'
                  : 'ለዚህ ክፍል ምንም እቅድ የለም',
              textAlign: TextAlign.center,
              style: GoogleFonts.notoSansEthiopic(
                  fontSize: 18, color: accentColor),
            ),
          ),
        ]),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadPlans,
      color: accentColor,
      backgroundColor: primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _plans.length,
        itemBuilder: (context, index) => _buildPlanItem(_plans[index]),
      ),
    );
  }

  Widget _buildPlanItem(PlanItem plan) {
    return Dismissible(
      key: Key(plan.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red.shade800,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete_forever, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
              context: context,
              builder: (BuildContext context) => AlertDialog(
                backgroundColor: primaryColor,
                title: Text('እቅዱን ሰርዝ',
                    style: GoogleFonts.notoSansEthiopic(color: accentColor)),
                content: Text('ይህን እቅድ ለመሰረዝ እርግጠኛ ነዎት? ይህን ድርጊት መመለስ አይቻልም።',
                    style: GoogleFonts.notoSansEthiopic(color: Colors.white)),
                actions: <Widget>[
                  TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text('ይቅር',
                          style: GoogleFonts.notoSansEthiopic(
                              color: accentColor))),
                  TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: Text('አዎ, ሰርዝ',
                          style:
                              GoogleFonts.notoSansEthiopic(color: Colors.red))),
                ],
              ),
            ) ??
            false;
      },
      onDismissed: (direction) {
        _deletePlan(plan.id);
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 2,
        color: const Color.fromARGB(255, 20, 47, 83),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
              color: plan.departmentColor.withOpacity(0.5), width: 1),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showAddOrEditPlanDialog(plan: plan),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(plan.title,
                          style: GoogleFonts.notoSansEthiopic(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              decoration: plan.isDone
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: plan.isDone
                                  ? accentColor.withOpacity(0.5)
                                  : accentColor)),
                    ),
                    const SizedBox(width: 8),
                    Checkbox(
                      value: plan.isDone,
                      onChanged: (isDone) =>
                          _togglePlanStatus(plan, isDone ?? false),
                      activeColor: Colors.green,
                      checkColor: primaryColor,
                      side: BorderSide(color: accentColor.withOpacity(0.5)),
                    )
                  ],
                ),
                if (plan.description?.isNotEmpty ?? false) ...[
                  const SizedBox(height: 8),
                  Text(plan.description!,
                      style: GoogleFonts.notoSansEthiopic(
                          fontSize: 14, color: accentColor.withOpacity(0.8)),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ],
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(
                      avatar: Icon(Icons.business,
                          size: 16, color: plan.departmentColor),
                      label: Text(plan.departmentName,
                          style: GoogleFonts.notoSansEthiopic(
                              color: Colors.white)),
                      backgroundColor: plan.departmentColor.withOpacity(0.3),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                    ),
                    if (plan.assigneeName != null)
                      Chip(
                        avatar: const Icon(Icons.person_outline,
                            size: 16, color: accentColor),
                        label: Text(plan.assigneeName!,
                            style: GoogleFonts.notoSansEthiopic(
                                color: accentColor)),
                        backgroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                      ),
                    if (plan.planDate != null)
                      Chip(
                        avatar: const Icon(Icons.calendar_today_outlined,
                            size: 16, color: accentColor),
                        label: Text(
                            DateFormat.yMMMd('am').format(plan.planDate!),
                            style: GoogleFonts.notoSansEthiopic(
                                color: accentColor)),
                        backgroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showAddOrEditPlanDialog(
      {PlanItem? plan, String? departmentId}) async {
    if (_allowedDepartments.isEmpty) {
      _showErrorSnackbar("እቅድ ለመጨመር የተፈቀደልዎት ክፍል የለም።");
      return;
    }

    final isEditing = plan != null;
    _titleController.text = isEditing ? plan.title : '';
    _descriptionController.text = isEditing ? plan.description ?? '' : '';

    String? selectedDeptId;
    if (isEditing) {
      selectedDeptId = plan.departmentId;
    } else if (departmentId != null) {
      selectedDeptId = departmentId;
    } else if (_selectedDepartmentIdForFilter != null) {
      selectedDeptId = _selectedDepartmentIdForFilter;
    } else {
      selectedDeptId = _allowedDepartments.first.id;
    }

    if (!_allowedDepartments.any((d) => d.id == selectedDeptId)) {
      selectedDeptId = _allowedDepartments.first.id;
    }

    String? selectedAssigneeId = isEditing ? plan.assigneeId : null;
    DateTime? selectedDate = isEditing ? plan.planDate : null;
    bool isDone = isEditing ? plan.isDone : false;

    InputDecoration getDialogInputDecoration(String label) {
      return InputDecoration(
        labelText: label,
        labelStyle:
            GoogleFonts.notoSansEthiopic(color: accentColor.withOpacity(0.7)),
        enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: accentColor.withOpacity(0.5))),
        focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: accentColor)),
        errorStyle: GoogleFonts.notoSansEthiopic(),
      );
    }

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: primaryColor,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0),
              side: BorderSide(color: accentColor.withOpacity(0.5))),
          title: Text(isEditing ? 'እቅድ ያርትዑ' : 'አዲስ እቅድ ያክሉ',
              style: GoogleFonts.notoSansEthiopic(
                  color: accentColor, fontWeight: FontWeight.w600)),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                      controller: _titleController,
                      style: GoogleFonts.notoSansEthiopic(color: accentColor),
                      decoration: getDialogInputDecoration('ርዕስ'),
                      validator: (value) =>
                          value == null || value.isEmpty ? 'ርዕስ ያስገቡ' : null),
                  const SizedBox(height: 16),
                  TextFormField(
                      controller: _descriptionController,
                      style: GoogleFonts.notoSansEthiopic(color: accentColor),
                      decoration: getDialogInputDecoration('ዝርዝር'),
                      maxLines: 3),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedDeptId,
                    style: GoogleFonts.notoSansEthiopic(color: accentColor),
                    dropdownColor: primaryColor,
                    decoration: getDialogInputDecoration('ክፍል'),
                    items: _allowedDepartments
                        .map((d) => DropdownMenuItem(
                            value: d.id,
                            child: Text(d.name,
                                style: GoogleFonts.notoSansEthiopic(
                                    color: Colors.white))))
                        .toList(),
                    onChanged: (value) =>
                        setDialogState(() => selectedDeptId = value),
                    validator: (value) =>
                        value == null ? 'እባክዎ ክፍል ይምረጡ' : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          color: accentColor, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          selectedDate == null
                              ? 'ቀን አልተመረጠም'
                              : DateFormat.yMMMd('am').format(selectedDate!),
                          style: GoogleFonts.notoSansEthiopic(
                              color: Colors.white, fontSize: 16),
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          final pickedDate = await showDatePicker(
                            context: context,
                            initialDate: selectedDate ?? DateTime.now(),
                            firstDate: DateTime.now()
                                .subtract(const Duration(days: 365)),
                            lastDate: DateTime.now()
                                .add(const Duration(days: 365 * 5)),
                            locale: const Locale('am', 'ET'),
                            builder: (context, child) => Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.dark(
                                  primary: accentColor,
                                  onPrimary: primaryColor,
                                  surface: primaryColor,
                                  onSurface: Colors.white,
                                ),
                                dialogBackgroundColor: primaryColor,
                                textTheme: TextTheme(
                                    bodyLarge: GoogleFonts.notoSansEthiopic(),
                                    titleMedium:
                                        GoogleFonts.notoSansEthiopic()),
                              ),
                              child: child!,
                            ),
                          );
                          if (pickedDate != null &&
                              pickedDate != selectedDate) {
                            setDialogState(() => selectedDate = pickedDate);
                          }
                        },
                        child: Text('ቀን ምረጥ',
                            style: GoogleFonts.notoSansEthiopic(
                                color: accentColor)),
                      ),
                    ],
                  ),
                  if (isEditing)
                    SwitchListTile(
                      title: Text('ተግባሩ ተጠናቋል',
                          style:
                              GoogleFonts.notoSansEthiopic(color: accentColor)),
                      value: isDone,
                      activeColor: accentColor,
                      onChanged: (val) => setDialogState(() => isDone = val),
                    )
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('ይቅር',
                    style: GoogleFonts.notoSansEthiopic(color: accentColor))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor, foregroundColor: primaryColor),
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  isEditing
                      ? await _updatePlan(plan!, selectedDeptId!,
                          selectedAssigneeId, selectedDate, isDone)
                      : await _addPlan(
                          selectedDeptId!, selectedAssigneeId, selectedDate);
                  if (mounted) Navigator.pop(context);
                }
              },
              child: Text(isEditing ? 'አስቀምጥ' : 'አክል',
                  style: GoogleFonts.notoSansEthiopic(
                      fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message,
            style: GoogleFonts.notoSansEthiopic(color: primaryColor)),
        backgroundColor: accentColor));
  }

  void _showErrorSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message, style: GoogleFonts.notoSansEthiopic()),
        backgroundColor: Colors.red.shade700));
  }
}

extension PlanItemJson on PlanItem {
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'plan_date': planDate?.toIso8601String(),
        'assignee_id': assigneeId,
        'department_id': departmentId,
        'is_done': isDone,
        'created_at': createdAt.toIso8601String(),
        'department': {'name': departmentName, 'color_code': ''},
        'assignee': {'full_name': assigneeName}
      };
}
