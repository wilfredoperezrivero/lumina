import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../services/capsule_service.dart';
import '../../services/credits_service.dart';
import '../../services/auth_service.dart';
import '../../models/capsule.dart';
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
      setState(() {
        _loadingCredits = true;
      });

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
      appBar: AppBar(
        title: Text('Create New Capsule'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Credits Display
              if (!_loadingCredits) ...[
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16),
                  margin: EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: _availableCredits > 0
                        ? Colors.green.shade50
                        : Colors.red.shade50,
                    border: Border.all(
                      color: _availableCredits > 0
                          ? Colors.green.shade200
                          : Colors.red.shade200,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Available Credits: $_availableCredits',
                            style: TextStyle(
                              color: _availableCredits > 0
                                  ? Colors.green.shade800
                                  : Colors.red.shade800,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          if (_availableCredits <= 0)
                            TextButton(
                              onPressed: () => context.go('/admin/buy_packs'),
                              child: Text('Buy Packs'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],

              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Capsule Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.label),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a capsule name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _familyEmailController,
                decoration: InputDecoration(
                  labelText: 'Family Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a family email';
                  }
                  if (!RegExp(
                          r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
                      .hasMatch(value)) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              // Date of Birth
              InkWell(
                onTap: () => _selectDateOfBirth(context),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Date of Birth (Optional)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.cake),
                  ),
                  child: Text(
                    _dateOfBirthController.text.isNotEmpty
                        ? _dateOfBirthController.text
                        : 'Select date of birth',
                    style: TextStyle(
                      color: _dateOfBirthController.text.isNotEmpty
                          ? Colors.black
                          : Colors.grey,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16),
              // Date of Death
              InkWell(
                onTap: () => _selectDateOfDeath(context),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Date of Death (Optional)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.event),
                  ),
                  child: Text(
                    _dateOfDeathController.text.isNotEmpty
                        ? _dateOfDeathController.text
                        : 'Select date of death',
                    style: TextStyle(
                      color: _dateOfDeathController.text.isNotEmpty
                          ? Colors.black
                          : Colors.grey,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16),
              // Scheduled Date
              InkWell(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Scheduled Date (Optional)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.schedule),
                  ),
                  child: Text(
                    _scheduledDate != null
                        ? '${_scheduledDate!.day}/${_scheduledDate!.month}/${_scheduledDate!.year}'
                        : 'Select scheduled date',
                    style: TextStyle(
                      color:
                          _scheduledDate != null ? Colors.black : Colors.grey,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16),
              // Language Dropdown
              DropdownButtonFormField<String>(
                value: _selectedLanguage,
                decoration: InputDecoration(
                  labelText: 'Language (Optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.language),
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
                validator: (value) {
                  // Language is optional, so no validation needed
                  return null;
                },
              ),
              if (_loadingCredits) Center(child: CircularProgressIndicator()),
              SizedBox(height: 24),
              if (_errorMessage != null)
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red.shade800),
                  ),
                ),
              SizedBox(height: 16),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed:
                      _isLoading || _loadingCredits || (_availableCredits <= 0)
                          ? null
                          : _createCapsule,
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text('Create Capsule'),
                ),
              ),
            ],
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
      lastDate:
          DateTime.now().add(Duration(days: 365 * 10)), // 10 years from now
    );
    if (picked != null && picked != _scheduledDate) {
      setState(() {
        _scheduledDate = picked;
      });
    }
  }

  Future<void> _selectDateOfBirth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          DateTime.tryParse(_dateOfBirthController.text) ?? DateTime.now(),
      firstDate: DateTime(1900), // Example: 100 years ago
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dateOfBirthController.text =
            '${picked.day}/${picked.month}/${picked.year}';
      });
    }
  }

  Future<void> _selectDateOfDeath(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          DateTime.tryParse(_dateOfDeathController.text) ?? DateTime.now(),
      firstDate: DateTime(1900), // Example: 100 years ago
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dateOfDeathController.text =
            '${picked.day}/${picked.month}/${picked.year}';
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
      // Create a new user with the family email via backend
      final String password =
          'temp_password_${DateTime.now().millisecondsSinceEpoch}';
      final response = await http.post(
        Uri.parse(dotenv.env['API_CREATE_FAMILY_USER']!),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${dotenv.env['SUPABASE_ANON_KEY']}',
        },
        body: jsonEncode({
          'email': _familyEmailController.text,
          'password': password,
          'capsuleTitle': _nameController.text,
          'capsuleDescription': '', // Removed description
        }),
      );

      if (response.statusCode != 200) {
        setState(() {
          _errorMessage = 'Failed to create user: \\${response.body}';
          _isLoading = false;
        });
        return;
      }

      final newUser = jsonDecode(response.body);
      final familyUserId = newUser['id'];

      // Get the current user (admin)
      final adminUser = AuthService.currentUser();
      if (adminUser == null) {
        setState(() {
          _errorMessage = 'Current user not authenticated.';
          _isLoading = false;
        });
        return;
      }

      // Create the capsule with admin_id as current user and family_id as new user
      final capsule = await CapsuleService.createCapsule(
        name: _nameController.text,
        dateOfBirth: _dateOfBirthController.text.isNotEmpty
            ? _dateOfBirthController.text
            : null,
        dateOfDeath: _dateOfDeathController.text.isNotEmpty
            ? _dateOfDeathController.text
            : null,
        language: _selectedLanguage,
        adminId: adminUser.id,
        familyId: familyUserId,
        familyEmail: _familyEmailController.text,
        scheduledDate: _scheduledDate,
        status: 'active',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Capsule created successfully! Email sent to ${_familyEmailController.text}'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pop(capsule);
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
