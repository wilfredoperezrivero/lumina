import 'package:flutter/material.dart';
import '../../services/capsule_service.dart';
import '../../models/capsule.dart';

class ListCapsulesPage extends StatefulWidget {
  @override
  _ListCapsulesPageState createState() => _ListCapsulesPageState();
}

class _ListCapsulesPageState extends State<ListCapsulesPage> {
  List<Capsule> _capsules = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _statusFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadCapsules();
  }

  Future<void> _loadCapsules() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final capsules = await CapsuleService.getUserCapsules();
      setState(() {
        _capsules = capsules;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load capsules: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  List<Capsule> get _filteredCapsules {
    if (_statusFilter == 'All') return _capsules;
    return _capsules
        .where((c) =>
            (c.status ?? '').toLowerCase() == _statusFilter.toLowerCase())
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Capsules'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadCapsules,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red),
                      SizedBox(height: 16),
                      Text(
                        'Error',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      SizedBox(height: 8),
                      Text(
                        _errorMessage!,
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadCapsules,
                        child: Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _capsules.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox_outlined,
                              size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No Capsules Yet',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Create your first capsule to get started',
                            style: Theme.of(context).textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => Navigator.pushNamed(
                                context, '/admin/create_capsule'),
                            child: Text('Create Capsule'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadCapsules,
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: Row(
                              children: [
                                Text('Filter by status: '),
                                SizedBox(width: 8),
                                DropdownButton<String>(
                                  value: _statusFilter,
                                  items: [
                                    'All',
                                    'Active',
                                    'Draft',
                                    'Completed',
                                  ]
                                      .map((status) => DropdownMenuItem(
                                            value: status,
                                            child: Text(status),
                                          ))
                                      .toList(),
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() {
                                        _statusFilter = value;
                                      });
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: ListView.builder(
                              padding: EdgeInsets.all(16),
                              itemCount: _filteredCapsules.length,
                              itemBuilder: (context, index) {
                                final capsule = _filteredCapsules[index];
                                final String description =
                                    capsule.description ?? '';
                                final String familyEmail =
                                    capsule.familyEmail ?? '';
                                return Card(
                                  margin: EdgeInsets.only(bottom: 16),
                                  child: ListTile(
                                    contentPadding: EdgeInsets.all(16),
                                    leading: CircleAvatar(
                                      backgroundColor:
                                          _getStatusColor(capsule.status ?? ''),
                                      child: Icon(
                                        _getStatusIcon(capsule.status ?? ''),
                                        color: Colors.white,
                                      ),
                                    ),
                                    title: Text(
                                      capsule.title ?? '(No Title)',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium,
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(height: 4),
                                        if (description.isNotEmpty)
                                          Text(
                                            description,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        if (familyEmail.isNotEmpty)
                                          Row(
                                            children: [
                                              Icon(Icons.email, size: 16),
                                              SizedBox(width: 4),
                                              Text(
                                                familyEmail,
                                                style: TextStyle(fontSize: 12),
                                              ),
                                            ],
                                          ),
                                        if (capsule.expiresAt != null)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                top: 8.0, bottom: 4.0),
                                            child: Row(
                                              children: [
                                                Icon(Icons.calendar_today,
                                                    size: 16),
                                                SizedBox(width: 4),
                                                Text(
                                                  'Expires: ${_formatDate(capsule.expiresAt!)}',
                                                  style:
                                                      TextStyle(fontSize: 12),
                                                ),
                                              ],
                                            ),
                                          ),
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: _getStatusColor(
                                                    capsule.status ?? '')
                                                .withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            (capsule.status ?? '')
                                                .toUpperCase(),
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: _getStatusColor(
                                                  capsule.status ?? ''),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    trailing: PopupMenuButton<String>(
                                      onSelected: (value) =>
                                          _handleMenuAction(value, capsule),
                                      itemBuilder: (context) => [
                                        PopupMenuItem(
                                          value: 'view',
                                          child: Row(
                                            children: [
                                              Icon(Icons.visibility),
                                              SizedBox(width: 8),
                                              Text('View Details'),
                                            ],
                                          ),
                                        ),
                                        PopupMenuItem(
                                          value: 'edit',
                                          child: Row(
                                            children: [
                                              Icon(Icons.edit),
                                              SizedBox(width: 8),
                                              Text('Edit'),
                                            ],
                                          ),
                                        ),
                                        PopupMenuItem(
                                          value: 'messages',
                                          child: Row(
                                            children: [
                                              Icon(Icons.message),
                                              SizedBox(width: 8),
                                              Text('View QR Code'),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return Colors.grey;
      case 'active':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return Icons.edit;
      case 'active':
        return Icons.account_box;
      case 'completed':
        return Icons.check;
      default:
        return Icons.help;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _handleMenuAction(String action, Capsule capsule) {
    switch (action) {
      case 'view':
        // TODO: Navigate to capsule details page
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('View details for ${capsule.title ?? '(No Title)'}')),
        );
        break;
      case 'edit':
        // TODO: Navigate to edit capsule page
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Edit ${capsule.title ?? '(No Title)'}')),
        );
        break;
      case 'messages':
        // TODO: Navigate to messages page
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('View messages for ${capsule.title ?? '(No Title)'}')),
        );
        break;
    }
  }
}
