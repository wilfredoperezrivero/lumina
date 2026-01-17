import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../services/capsule_service.dart';
import '../../services/auth_service.dart';
import '../../services/credits_service.dart';
import '../../theme/app_theme.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CreateCapsulePage extends StatefulWidget {
  @override
  _CreateCapsulePageState createState() => _CreateCapsulePageState();
}

class _CreateCapsulePageState extends State<CreateCapsulePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _familyEmailController = TextEditingController();
  final _dateOfBirthController = TextEditingController();
  final _dateOfDeathController = TextEditingController();

  DateTime? _scheduledDate;
  String? _selectedLanguage;
  bool _isLoading = false;
  bool _loadingCredits = true;
  String? _errorMessage;

  int _availableCredits = 0;

  final List<String> _languages = [
    'English',
    'Spanish',
    'French',
    'German',
    'Italian',
    'Portuguese',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _loadCredits();
  }

  Future<void> _loadCredits() async {
    try {
      setState(() => _loadingCredits = true);
      final credits = await CreditsService.getAvailableCredits();
      setState(() {
        _availableCredits = credits;
        _loadingCredits = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load credits: ${e.toString()}';
        _loadingCredits = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: buildAppBar(
        context: context,
        title: 'Create Capsule',
        onBack: () => context.go('/admin/dashboard'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              icon: const Icon(Icons.home_rounded, color: AppColors.accent),
              onPressed: () => context.go('/admin/dashboard'),
              tooltip: 'Dashboard',
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Credits Display
              if (!_loadingCredits) _buildCreditsCard(),

              // Form Section
              _buildFormSection(),

              // Error message
              if (_errorMessage != null) ...[
                const SizedBox(height: 20),
                buildAlertContainer(message: _errorMessage!, isError: true),
              ],

              const SizedBox(height: 24),

              // Submit button
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading || _loadingCredits || (_availableCredits <= 0)
                      ? null
                      : _createCapsule,
                  style: primaryButtonStyle,
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'Create Capsule',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCreditsCard() {
    final hasCredits = _availableCredits > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: hasCredits ? AppColors.successLight : AppColors.errorLight,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: hasCredits
              ? AppColors.success.withValues(alpha: 0.3)
              : AppColors.error.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: hasCredits
                  ? AppColors.success.withValues(alpha: 0.2)
                  : AppColors.error.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(
              hasCredits ? Icons.check_circle_rounded : Icons.error_rounded,
              color: hasCredits ? AppColors.success : AppColors.error,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Available Credits',
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: 2),
                Text(
                  '$_availableCredits',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: hasCredits ? AppColors.success : AppColors.error,
                  ),
                ),
              ],
            ),
          ),
          if (!hasCredits)
            ElevatedButton(
              onPressed: () => context.go('/admin/buy_packs'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryDark,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
              child: const Text('Buy Packs'),
            ),
        ],
      ),
    );
  }

  Widget _buildFormSection() {
    return Container(
      decoration: AppDecorations.card,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(Icons.add_rounded, color: AppColors.primaryDark, size: 20),
              ),
              const SizedBox(width: 12),
              Text('Capsule Details', style: AppTextStyles.h3),
            ],
          ),
          const SizedBox(height: 24),

          // Capsule Name
          TextFormField(
            controller: _nameController,
            decoration: AppDecorations.inputDecoration(
              label: 'Capsule Name',
              prefixIcon: Icons.label_outline_rounded,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a capsule name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Family Email
          TextFormField(
            controller: _familyEmailController,
            decoration: AppDecorations.inputDecoration(
              label: 'Family Email',
              prefixIcon: Icons.email_outlined,
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a family email';
              }
              if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(value)) {
                return 'Please enter a valid email address';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Date of Birth
          _buildDateField(
            label: 'Date of Birth (Optional)',
            icon: Icons.cake_outlined,
            value: _dateOfBirthController.text,
            onTap: () => _selectDateOfBirth(context),
          ),
          const SizedBox(height: 16),

          // Date of Death
          _buildDateField(
            label: 'Date of Death (Optional)',
            icon: Icons.event_outlined,
            value: _dateOfDeathController.text,
            onTap: () => _selectDateOfDeath(context),
          ),
          const SizedBox(height: 16),

          // Scheduled Date
          _buildDateField(
            label: 'Scheduled Date (Optional)',
            icon: Icons.schedule_rounded,
            value: _scheduledDate != null
                ? '${_scheduledDate!.day}/${_scheduledDate!.month}/${_scheduledDate!.year}'
                : '',
            onTap: () => _selectDate(context),
          ),
          const SizedBox(height: 16),

          // Language Dropdown
          DropdownButtonFormField<String>(
            value: _selectedLanguage,
            decoration: AppDecorations.inputDecoration(
              label: 'Language (Optional)',
              prefixIcon: Icons.language_rounded,
            ),
            items: _languages.map((String language) {
              return DropdownMenuItem<String>(
                value: language,
                child: Text(language),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() => _selectedLanguage = newValue);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required IconData icon,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InputDecorator(
        decoration: AppDecorations.inputDecoration(
          label: label,
          prefixIcon: icon,
        ),
        child: Text(
          value.isNotEmpty ? value : 'Select date',
          style: TextStyle(
            color: value.isNotEmpty ? AppColors.textPrimary : AppColors.textMuted,
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _scheduledDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );
    if (picked != null && picked != _scheduledDate) {
      setState(() => _scheduledDate = picked);
    }
  }

  Future<void> _selectDateOfBirth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_dateOfBirthController.text) ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dateOfBirthController.text = '${picked.day}/${picked.month}/${picked.year}';
      });
    }
  }

  Future<void> _selectDateOfDeath(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_dateOfDeathController.text) ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dateOfDeathController.text = '${picked.day}/${picked.month}/${picked.year}';
      });
    }
  }

  Future<void> _createCapsule() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      const String password = 'test2025';

      final apiUrl = dotenv.env['API_CREATE_FAMILY_USER'];
      final anonKey = dotenv.env['SUPABASE_ANON_KEY'];

      if (apiUrl == null || apiUrl.isEmpty) {
        setState(() {
          _errorMessage = 'Environment variable API_CREATE_FAMILY_USER is not set.';
          _isLoading = false;
        });
        return;
      }

      if (anonKey == null || anonKey.isEmpty) {
        setState(() {
          _errorMessage = 'Environment variable SUPABASE_ANON_KEY is not set.';
          _isLoading = false;
        });
        return;
      }

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $anonKey',
        },
        body: jsonEncode({
          'email': _familyEmailController.text,
          'password': password,
          'capsuleName': _nameController.text,
        }),
      );

      if (response.statusCode != 200) {
        setState(() {
          _errorMessage = 'Failed to create user: ${response.body}';
          _isLoading = false;
        });
        return;
      }

      if (response.body.isEmpty) {
        setState(() {
          _errorMessage = 'Empty response from user creation API';
          _isLoading = false;
        });
        return;
      }

      final newUser = jsonDecode(response.body);

      if (newUser == null || newUser['success'] != true) {
        setState(() {
          _errorMessage = 'Failed to create user: ${newUser?['message'] ?? 'Unknown error'}';
          _isLoading = false;
        });
        return;
      }

      if (newUser['user'] == null || newUser['user']['id'] == null) {
        setState(() {
          _errorMessage =
              'User creation succeeded but no user ID returned. Magic link was sent to ${_familyEmailController.text}. Please try creating the capsule again after the user logs in.';
          _isLoading = false;
        });
        return;
      }

      final familyUserId = newUser['user']['id'];

      final adminUser = AuthService.currentUser();
      if (adminUser == null) {
        setState(() {
          _errorMessage = 'Current user not authenticated.';
          _isLoading = false;
        });
        return;
      }

      await CapsuleService.createCapsule(
        name: _nameController.text,
        dateOfBirth: _dateOfBirthController.text.isNotEmpty ? _dateOfBirthController.text : null,
        dateOfDeath: _dateOfDeathController.text.isNotEmpty ? _dateOfDeathController.text : null,
        language: _selectedLanguage,
        adminId: adminUser.id,
        familyId: familyUserId,
        familyEmail: _familyEmailController.text,
        scheduledDate: _scheduledDate,
        status: 'active',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Capsule created! Login link sent to ${_familyEmailController.text}'),
          backgroundColor: AppColors.success,
        ),
      );

      context.go('/admin/list_capsules');
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to create capsule: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _familyEmailController.dispose();
    _dateOfBirthController.dispose();
    _dateOfDeathController.dispose();
    super.dispose();
  }
}
