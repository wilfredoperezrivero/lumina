import 'package:flutter/material.dart';
import '../../services/capsule_service.dart';
import '../../models/capsule.dart';

class CreateCapsulePage extends StatefulWidget {
  @override
  _CreateCapsulePageState createState() => _CreateCapsulePageState();
}

class _CreateCapsulePageState extends State<CreateCapsulePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _familyEmailController = TextEditingController();
  DateTime? _scheduledDate;
  bool _isLoading = false;
  String? _errorMessage;
  int _packs = 0;
  int _capsules = 0;
  bool _loadingCredits = true;

  @override
  void initState() {
    super.initState();
    _loadCredits();
  }

  Future<void> _loadCredits() async {
    setState(() {
      _loadingCredits = true;
    });
    // TODO: Replace with real API calls to get packs and capsules count
    // For now, use dummy values
    _packs = 3; // Example: fetch from Supabase
    _capsules = 3; // Example: fetch from Supabase
    setState(() {
      _loadingCredits = false;
    });
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
              TextFormField(
                controller: _familyEmailController,
                decoration: InputDecoration(
                  labelText: 'Family Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a family email';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              ListTile(
                leading: Icon(Icons.calendar_today),
                title: Text('Scheduled Date (Optional)'),
                subtitle: Text(_scheduledDate != null
                    ? '${_scheduledDate!.day}/${_scheduledDate!.month}/${_scheduledDate!.year}'
                    : 'No date set'),
                trailing: IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: _scheduledDate != null
                      ? () {
                          setState(() {
                            _scheduledDate = null;
                          });
                        }
                      : null,
                ),
                onTap: () => _selectDate(context),
              ),
              SizedBox(height: 16),
              if (_loadingCredits) Center(child: CircularProgressIndicator()),
              if (!_loadingCredits)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Available Credits: ${_packs - _capsules}'),
                    if (_packs - _capsules <= 0)
                      TextButton(
                        onPressed: () =>
                            Navigator.of(context).pushNamed('/admin/buy_packs'),
                        child: Text('Buy Packs'),
                      ),
                  ],
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
                  onPressed:
                      _isLoading || _loadingCredits || (_packs - _capsules <= 0)
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

  Future<void> _createCapsule() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Create a new user for the family email (if needed)
      // TODO: Replace with real user creation logic
      await Future.delayed(Duration(milliseconds: 500)); // Simulate network
      // Then create the capsule
      final capsule = await CapsuleService.createCapsule(
        name: _nameController.text,
        description: _descriptionController.text,
        scheduledDate: _scheduledDate,
        // Optionally pass family email in settings or another field
        settings: {'family_email': _familyEmailController.text},
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Capsule "${capsule.title ?? '(No Title)'}" created successfully!'),
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
    _descriptionController.dispose();
    _familyEmailController.dispose();
    super.dispose();
  }
}
