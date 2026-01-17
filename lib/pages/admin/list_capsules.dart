import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/capsule_service.dart';
import '../../models/capsule.dart';
import '../../theme/app_theme.dart';

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
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.accent),
          onPressed: () => context.go('/admin/dashboard'),
        ),
        title: Text('Capsules', style: AppTextStyles.h3.copyWith(fontSize: 18)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              icon: const Icon(Icons.refresh_rounded, color: AppColors.accent),
              onPressed: _refreshCapsules,
              tooltip: 'Refresh',
            ),
          ),
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryDark))
          : _errorMessage != null
              ? _buildErrorState()
              : _capsules.isEmpty
                  ? _buildEmptyState()
                  : _buildCapsulesList(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.errorLight,
                borderRadius: BorderRadius.circular(AppRadius.xl),
              ),
              child: Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
            ),
            const SizedBox(height: 24),
            Text('Something went wrong', style: AppTextStyles.h3),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: AppTextStyles.bodySecondary,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _refreshCapsules,
              style: primaryButtonStyle,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.xl),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(Icons.inventory_2_outlined, size: 48, color: AppColors.accent),
            ),
            const SizedBox(height: 24),
            Text('No Capsules Yet', style: AppTextStyles.h3),
            const SizedBox(height: 8),
            Text(
              'Create your first capsule to get started',
              style: AppTextStyles.bodySecondary,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.go('/admin/create_capsule'),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create Capsule'),
              style: primaryButtonStyle,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCapsulesList() {
    return RefreshIndicator(
      onRefresh: _refreshCapsules,
      color: AppColors.primaryDark,
      child: Column(
        children: [
          // Header section
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stats row
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: AppDecorations.card,
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(AppRadius.md),
                              ),
                              child: const Icon(Icons.inventory_2_outlined, color: AppColors.primaryDark, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('$_totalCapsules', style: AppTextStyles.h3),
                                Text('Total Capsules', style: AppTextStyles.caption),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Create button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => context.go('/admin/create_capsule'),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Create New Capsule', style: TextStyle(fontWeight: FontWeight.w600)),
                    style: primaryButtonStyle,
                  ),
                ),
                const SizedBox(height: 16),

                // Filter row
                Row(
                  children: [
                    Text('Filter:', style: AppTextStyles.label),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _statusFilter,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.accent),
                          items: ['All', 'Active', 'Draft', 'Completed']
                              .map((status) => DropdownMenuItem(
                                    value: status,
                                    child: Text(status, style: AppTextStyles.body),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _statusFilter = value);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Capsules list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _filteredCapsules.length + (_hasMoreCapsules ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _filteredCapsules.length) {
                  return _isLoadingMore
                      ? const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator(color: AppColors.primaryDark)),
                        )
                      : const SizedBox.shrink();
                }
                return _buildCapsuleCard(_filteredCapsules[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCapsuleCard(Capsule capsule) {
    final familyEmail = capsule.familyEmail ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppDecorations.card,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openCapsule(capsule),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon container
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: const Icon(Icons.inventory_2_outlined, color: AppColors.primaryDark, size: 24),
                ),
                const SizedBox(width: 16),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        capsule.name ?? '(No Name)',
                        style: AppTextStyles.subtitle,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        familyEmail.isNotEmpty ? familyEmail : 'No family assigned',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),

                // Status badge
                buildStatusBadge(capsule.status ?? 'Unknown'),

                const SizedBox(width: 8),

                // Arrow icon
                const Icon(Icons.chevron_right_rounded, color: AppColors.accent),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openCapsule(Capsule capsule) {
    context.go('/admin/capsule_details', extra: capsule);
  }
}
