import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/capsule_service.dart';
import '../../models/capsule.dart';

class ListCapsulesPage extends StatefulWidget {
  @override
  _ListCapsulesPageState createState() => _ListCapsulesPageState();
}

class _ListCapsulesPageState extends State<ListCapsulesPage> {
  List<Capsule> _capsules = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMoreCapsules = true;
  String? _errorMessage;
  String _statusFilter = 'All';
  int _currentPage = 0;
  int _totalCapsules = 0;
  static const int _pageSize = 10;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadCapsules();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreCapsules();
    }
  }

  Future<void> _loadCapsules() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _currentPage = 0;
      _hasMoreCapsules = true;
    });

    try {
      final capsules = await CapsuleService.getCapsulesPaginated(
        page: 0,
        pageSize: _pageSize,
      );
      final totalCount = await CapsuleService.getCapsulesCount();

      setState(() {
        _capsules = capsules;
        _totalCapsules = totalCount;
        _isLoading = false;
        _hasMoreCapsules = capsules.length == _pageSize;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load capsules: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreCapsules() async {
    if (_isLoadingMore || !_hasMoreCapsules) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final nextPage = _currentPage + 1;
      final moreCapsules = await CapsuleService.getCapsulesPaginated(
        page: nextPage,
        pageSize: _pageSize,
      );

      setState(() {
        _capsules.addAll(moreCapsules);
        _currentPage = nextPage;
        _isLoadingMore = false;
        _hasMoreCapsules = moreCapsules.length == _pageSize;
      });
    } catch (e) {
      setState(() {
        _isLoadingMore = false;
        _errorMessage = 'Failed to load more capsules: ${e.toString()}';
      });
    }
  }

  Future<void> _refreshCapsules() async {
    await _loadCapsules();
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
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => context.go('/admin/dashboard'),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _refreshCapsules,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: Icon(Icons.home),
            onPressed: () => context.go('/admin/dashboard'),
            tooltip: 'Go to Dashboard',
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
                        onPressed: _refreshCapsules,
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
                            onPressed: () =>
                                context.go('/admin/create_capsule'),
                            child: Text('Create Capsule'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _refreshCapsules,
                      child: Column(
                        children: [
                          // Total count display
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            color: Colors.blue.shade50,
                            child: Text(
                              'Total: $_totalCapsules capsule(s)',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue.shade800,
                              ),
                            ),
                          ),
                          // Create new capsule button
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            child: ElevatedButton.icon(
                              onPressed: () =>
                                  context.go('/admin/create_capsule'),
                              icon: Icon(Icons.add, color: Colors.white),
                              label: Text(
                                'Create New Capsule',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade600,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
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
                              controller: _scrollController,
                              padding: EdgeInsets.all(16),
                              itemCount: _filteredCapsules.length +
                                  (_hasMoreCapsules ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == _filteredCapsules.length) {
                                  // Loading indicator at the bottom
                                  return _isLoadingMore
                                      ? Padding(
                                          padding: EdgeInsets.all(16),
                                          child: Center(
                                            child: CircularProgressIndicator(),
                                          ),
                                        )
                                      : SizedBox.shrink();
                                }
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

  void _openCapsule(Capsule capsule) {
    context.go('/admin/capsule_details', extra: capsule);
  }
}
