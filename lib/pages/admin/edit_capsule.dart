import 'package:flutter/material.dart';
import '../../services/capsule_service.dart';
import '../../models/capsule.dart';
import '../../services/auth_service.dart';

class EditCapsulePage extends StatefulWidget {
  @override
  _EditCapsulePageState createState() => _EditCapsulePageState();
}

class _EditCapsulePageState extends State<EditCapsulePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCapsule();
    });
  }

  void _loadCapsule() {
    final capsule = ModalRoute.of(context)!.settings.arguments as Capsule;
    setState(() {
      _capsule = capsule;
      _nameController.text = capsule.name ?? '';
      _descriptionController.text = capsule.description ?? '';
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
      appBar: AppBar(
        title: Text('Edit Capsule'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.home),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Go Back',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
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
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.description),
                        ),
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a description';
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
                              color: _scheduledDate != null
                                  ? Colors.black
                                  : Colors.grey,
                            ),
                          ),
                        ),
                      ),
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
                          onPressed: _isSaving ? null : _saveCapsule,
                          child: _isSaving
                              ? CircularProgressIndicator(color: Colors.white)
                              : Text('Save Changes'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Future<void> _selectDateOfBirth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          DateTime.tryParse(_dateOfBirthController.text) ?? DateTime.now(),
      firstDate: DateTime(1900),
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
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dateOfDeathController.text =
            '${picked.day}/${picked.month}/${picked.year}';
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _scheduledDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365 * 10)),
    );
    if (picked != null && picked != _scheduledDate) {
      setState(() {
        _scheduledDate = picked;
      });
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
        description: _descriptionController.text,
        dateOfBirth: _dateOfBirthController.text.isNotEmpty
            ? _dateOfBirthController.text
            : null,
        dateOfDeath: _dateOfDeathController.text.isNotEmpty
            ? _dateOfDeathController.text
            : null,
        language: _selectedLanguage,
        scheduledDate: _scheduledDate,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Capsule updated successfully!'),
          backgroundColor: Colors.green,
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
    _descriptionController.dispose();
    _dateOfBirthController.dispose();
    _dateOfDeathController.dispose();
    super.dispose();
  }
}
