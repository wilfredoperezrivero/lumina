import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../models/settings.dart';
import '../../services/settings_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import 'dart:typed_data';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _contactNameController = TextEditingController();
  final _addressController = TextEditingController();

  Settings? _currentSettings;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  String? _logoUrl;
  Uint8List? _selectedLogoBytes;

  String? _selectedLanguage;

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
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final settings = await SettingsService.getAdminSettings();
      setState(() {
        _currentSettings = settings;
        if (settings != null) {
          _nameController.text = settings.name ?? '';
          _emailController.text = settings.email ?? '';
          _phoneController.text = settings.phone ?? '';
          _contactNameController.text = settings.contactName ?? '';
          _addressController.text = settings.address ?? '';
          _selectedLanguage = settings.language;
          _logoUrl = settings.logoImage;
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load settings: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _pickLogo() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.bytes != null) {
          setState(() {
            _selectedLogoBytes = file.bytes!;
            _logoUrl = null;
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      String? logoImageUrl = _logoUrl;

      if (_selectedLogoBytes != null) {
        logoImageUrl = await SettingsService.uploadLogoImage(
          _selectedLogoBytes!,
        );
      }

      final settings = Settings(
        adminId: AuthService.currentUser()!.id,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        contactName: _contactNameController.text.trim(),
        address: _addressController.text.trim(),
        language: _selectedLanguage,
        logoImage: logoImageUrl,
        info: _currentSettings?.info ?? {},
        createdAt: _currentSettings?.createdAt,
        updatedAt: DateTime.now(),
      );

      await SettingsService.saveAdminSettings(settings);

      setState(() {
        _currentSettings = settings;
        _logoUrl = logoImageUrl;
        _selectedLogoBytes = null;
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Settings saved successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to save settings: ${e.toString()}';
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: buildAppBar(context: context, title: 'Settings'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryDark))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Information Card
                    _buildSectionCard(
                      title: 'Profile Information',
                      icon: Icons.person_outline_rounded,
                      children: [
                        TextFormField(
                          controller: _nameController,
                          decoration: AppDecorations.inputDecoration(
                            label: 'Business Name',
                            prefixIcon: Icons.business_rounded,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a business name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _emailController,
                          decoration: AppDecorations.inputDecoration(
                            label: 'Email',
                            prefixIcon: Icons.email_outlined,
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter an email address';
                            }
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                              return 'Please enter a valid email address';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _phoneController,
                          decoration: AppDecorations.inputDecoration(
                            label: 'Phone Number',
                            prefixIcon: Icons.phone_outlined,
                          ),
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _contactNameController,
                          decoration: AppDecorations.inputDecoration(
                            label: 'Contact Name',
                            prefixIcon: Icons.person_outline_rounded,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _addressController,
                          decoration: AppDecorations.inputDecoration(
                            label: 'Address',
                            prefixIcon: Icons.location_on_outlined,
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _selectedLanguage,
                          decoration: AppDecorations.inputDecoration(
                            label: 'Language',
                            prefixIcon: Icons.language_rounded,
                          ),
                          items: _languages.map((String language) {
                            return DropdownMenuItem<String>(
                              value: language,
                              child: Text(language),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedLanguage = newValue;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Logo Card
                    _buildSectionCard(
                      title: 'Logo',
                      icon: Icons.image_outlined,
                      children: [
                        Center(
                          child: Column(
                            children: [
                              if (_logoUrl != null || _selectedLogoBytes != null)
                                Container(
                                  width: 200,
                                  height: 200,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: AppColors.border),
                                    borderRadius: BorderRadius.circular(AppRadius.md),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(AppRadius.md),
                                    child: _selectedLogoBytes != null
                                        ? Image.memory(_selectedLogoBytes!, fit: BoxFit.contain)
                                        : Image.network(
                                            _logoUrl!,
                                            fit: BoxFit.contain,
                                            errorBuilder: (context, error, stackTrace) {
                                              return const Icon(
                                                Icons.image_not_supported_outlined,
                                                size: 64,
                                                color: AppColors.accent,
                                              );
                                            },
                                          ),
                                  ),
                                ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _pickLogo,
                                icon: const Icon(Icons.upload_rounded),
                                label: const Text('Upload Logo'),
                                style: primaryButtonStyle,
                              ),
                              if (_logoUrl != null || _selectedLogoBytes != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _logoUrl = null;
                                        _selectedLogoBytes = null;
                                      });
                                    },
                                    child: Text(
                                      'Remove Logo',
                                      style: TextStyle(color: AppColors.error),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Error message
                    if (_errorMessage != null) ...[
                      buildAlertContainer(message: _errorMessage!, isError: true),
                      const SizedBox(height: 20),
                    ],

                    // Save button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveSettings,
                        style: primaryButtonStyle,
                        child: _isSaving
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text(
                                'Save Settings',
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

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
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
                child: Icon(icon, color: AppColors.primaryDark, size: 20),
              ),
              const SizedBox(width: 12),
              Text(title, style: AppTextStyles.h3),
            ],
          ),
          const SizedBox(height: 24),
          ...children,
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _contactNameController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}
