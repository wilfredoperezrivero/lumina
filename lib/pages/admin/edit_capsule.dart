import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/capsule_service.dart';
import '../../models/capsule.dart';
import '../../theme/app_theme.dart';

class EditCapsulePage extends StatefulWidget {
  final Capsule capsule;
  const EditCapsulePage({Key? key, required this.capsule}) : super(key: key);

  @override
  _EditCapsulePageState createState() => _EditCapsulePageState();
}

class _EditCapsulePageState extends State<EditCapsulePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dateOfBirthController = TextEditingController();
  final _dateOfDeathController = TextEditingController();
  DateTime? _scheduledDate;
  String? _selectedLanguage;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  Capsule? _capsule;

  final List<String> _languages = [
    'English',
    'Spanish',
    'French',
    'German',
    'Italian',
    'Portuguese',
    'Dutch',
    'Russian',
    'Chinese',
    'Japanese',
    'Korean',
    'Arabic',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _loadCapsule();
  }

  void _loadCapsule() {
    final capsule = widget.capsule;
    setState(() {
      _capsule = capsule;
      _nameController.text = capsule.name ?? '';
      _dateOfBirthController.text = capsule.dateOfBirth ?? '';
      _dateOfDeathController.text = capsule.dateOfDeath ?? '';
      _selectedLanguage = capsule.language;
      _scheduledDate = capsule.scheduledDate;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: buildAppBar(
        context: context,
        title: 'Edit Capsule',
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryDark))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildFormSection(),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 20),
                      buildAlertContainer(message: _errorMessage!, isError: true),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveCapsule,
                        style: primaryButtonStyle,
                        child: _isSaving
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text(
                                'Save Changes',
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
                child: const Icon(Icons.edit_rounded, color: AppColors.primaryDark, size: 20),
              ),
              const SizedBox(width: 12),
              Text('Capsule Details', style: AppTextStyles.h3),
            ],
          ),
          const SizedBox(height: 24),

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

          _buildDateField(
            label: 'Date of Birth (Optional)',
            icon: Icons.cake_outlined,
            value: _dateOfBirthController.text,
            onTap: () => _selectDateOfBirth(context),
          ),
          const SizedBox(height: 16),

          _buildDateField(
            label: 'Date of Death (Optional)',
            icon: Icons.event_outlined,
            value: _dateOfDeathController.text,
            onTap: () => _selectDateOfDeath(context),
          ),
          const SizedBox(height: 16),

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
          const SizedBox(height: 16),

          _buildDateField(
            label: 'Scheduled Date (Optional)',
            icon: Icons.schedule_rounded,
            value: _scheduledDate != null
                ? '${_scheduledDate!.day}/${_scheduledDate!.month}/${_scheduledDate!.year}'
                : '',
            onTap: () => _selectDate(context),
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

  Future<void> _saveCapsule() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final updatedCapsule = await CapsuleService.updateCapsule(
        capsuleId: _capsule!.id,
        name: _nameController.text,
        dateOfBirth: _dateOfBirthController.text.isNotEmpty ? _dateOfBirthController.text : null,
        dateOfDeath: _dateOfDeathController.text.isNotEmpty ? _dateOfDeathController.text : null,
        language: _selectedLanguage,
        scheduledDate: _scheduledDate,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Capsule updated successfully!'),
          backgroundColor: AppColors.success,
        ),
      );

      Navigator.of(context).pop(updatedCapsule);
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to update capsule: ${e.toString()}';
        _isSaving = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dateOfBirthController.dispose();
    _dateOfDeathController.dispose();
    super.dispose();
  }
}
