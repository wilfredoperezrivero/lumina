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
                                final String familyEmail =
                                    capsule.familyEmail ?? '';
                                return Card(
                                  margin: EdgeInsets.only(bottom: 8),
                                  child: Padding(
                                    padding: EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // First line: Name and Status
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                capsule.name ?? '(No Name)',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleMedium
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                              ),
                                            ),
                                            Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: _getStatusColor(
                                                    capsule.status ?? ''),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                capsule.status ?? 'Unknown',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 4),
                                        // Second line: Family Email and Edit Button
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                'Family: ${familyEmail.isNotEmpty ? familyEmail : 'Not assigned'}',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall
                                                    ?.copyWith(
                                                      color: Colors.grey[600],
                                                      fontSize: 11,
                                                    ),
                                              ),
                                            ),
                                            ElevatedButton.icon(
                                              onPressed: () =>
                                                  _openCapsule(capsule),
                                              icon: Icon(Icons.open_in_new,
                                                  size: 14),
                                              label: Text('Open',
                                                  style:
                                                      TextStyle(fontSize: 12)),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    Colors.blue.shade600,
                                                foregroundColor: Colors.white,
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                minimumSize: Size(0, 28),
                                              ),
                                            ),
                                          ],
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
              content: Text('View details for ${capsule.name ?? '(No Name)'}')),
        );
        break;
      case 'edit':
        // TODO: Navigate to edit capsule page
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Edit ${capsule.name ?? '(No Name)'}')),
        );
        break;
      case 'messages':
        // TODO: Navigate to messages page
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('View messages for ${capsule.name ?? '(No Name)'}')),
        );
        break;
    }
  }

  void _openCapsule(Capsule capsule) {
    Navigator.pushNamed(context, '/admin/capsule_details', arguments: capsule);
  }
}
