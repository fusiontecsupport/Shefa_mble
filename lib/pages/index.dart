import 'package:flutter/material.dart';
import 'month.dart';
import 'api_service.dart';
import 'edit.dart';
import 'view.dart';
import 'creator_page.dart';
import 'login_page.dart';
import 'branch_selection_page.dart';
import 'state.dart' as state_model;

typedef StateModel = state_model.State;

class IndexPage extends StatefulWidget {
  final LoginDetails? loginDetails;

  const IndexPage({super.key, this.loginDetails});

  @override
  State<IndexPage> createState() => _IndexPageState();
}

class _IndexPageState extends State<IndexPage> with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  List<Month> _months = [];
  Month? _selectedMonth;
  bool _isLoadingMonths = true;
  String? _monthsErrorMessage;

  List<CollectionTarget> _collectionTargets = [];
  bool _isLoadingCollectionTargets = false;
  String? _collectionTargetsErrorMessage;

  // Company search functionality
  final TextEditingController _companySearchController =
      TextEditingController();
  List<CollectionTarget> _filteredTargets = [];
  bool _isSearching = false;
  CollectionTarget? _selectedCompany;

  // 1. Add variable to store state details
  List<state_model.State> _stateDetails = [];

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Advanced color palette with gradients
  final List<LinearGradient> _categoryGradients = [
    const LinearGradient(colors: [Color(0xFF667eea), Color(0xFF764ba2)]),
    const LinearGradient(colors: [Color(0xFFf093fb), Color(0xFFf5576c)]),
    const LinearGradient(colors: [Color(0xFF4facfe), Color(0xFF00f2fe)]),
    const LinearGradient(colors: [Color(0xFF43e97b), Color(0xFF38f9d7)]),
    const LinearGradient(colors: [Color(0xFFfa709a), Color(0xFFfee140)]),
    const LinearGradient(colors: [Color(0xFFa8edea), Color(0xFFfed6e3)]),
    const LinearGradient(colors: [Color(0xFFff9a9e), Color(0xFFfecfef)]),
    const LinearGradient(colors: [Color(0xFFffecd2), Color(0xFFfcb69f)]),
  ];

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _fadeController.forward();
    _slideController.forward();

    // Add listener to company search controller
    _companySearchController.addListener(() {
      setState(() {}); // Trigger rebuild to update clear button visibility
    });

    if (widget.loginDetails?.stateId != null) {
      _fetchStateDetails(widget.loginDetails!.stateId);
    }
    _fetchMonths();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _companySearchController.dispose();
    super.dispose();
  }

  Future<bool> _showExitConfirmation() async {
    return await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                title: const Text('Confirm Exit'),
                content: const Text(
                  'Are you sure you want to return to login?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Yes'),
                  ),
                ],
              ),
        ) ??
        false;
  }

  Future<void> _handleLogout() async {
    final shouldLogout = await _showExitConfirmation();
    if (shouldLogout && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  Future<void> _fetchMonths() async {
    try {
      setState(() {
        _isLoadingMonths = true;
        _monthsErrorMessage = null;
      });
      final fetchedMonths = await _apiService.getMonthDetails();
      setState(() {
        _months = fetchedMonths;
        if (_months.isNotEmpty) {
          _selectedMonth = _months[0];
          if (widget.loginDetails != null) {
            _fetchCollectionTargets(
              widget.loginDetails!.userName,
              widget.loginDetails!.brnchId,
              _selectedMonth!.monthId,
              widget.loginDetails!.stateId,
            );
          }
        }
        _isLoadingMonths = false;
      });
    } catch (e) {
      setState(() {
        _monthsErrorMessage = 'Failed to load months: $e';
        _isLoadingMonths = false;
      });
    }
  }

  Future<void> _fetchCollectionTargets(
    String userName,
    int branchId,
    int monthId,
    int stateId,
  ) async {
    try {
      setState(() {
        _isLoadingCollectionTargets = true;
        _collectionTargetsErrorMessage = null;
        _collectionTargets = [];
      });
      final fetchedTargets = await _apiService.getCollectionTargetListDetails(
        userName,
        branchId,
        monthId,
        stateId,
      );
      setState(() {
        _collectionTargets = fetchedTargets;
        _isLoadingCollectionTargets = false;
        // Clear filtered results when new data is loaded
        _filteredTargets = [];
        _isSearching = false;
        _selectedCompany =
            null; // Clear selected company when new data is loaded
      });
    } catch (e) {
      setState(() {
        _collectionTargetsErrorMessage =
            'Failed to load collection targets: $e';
        _isLoadingCollectionTargets = false;
      });
    }
  }

  // 2. Add fetch function for state details
  Future<void> _fetchStateDetails(int stateId) async {
    try {
      final stateDetails = await _apiService.getBranchStateDetails(stateId);
      setState(() {
        _stateDetails = stateDetails;
      });
    } catch (e) {
      // Optionally handle error
    }
  }

  LinearGradient _getCategoryGradient(String categoryCode) {
    final hash = categoryCode.codeUnits.fold(0, (a, b) => a + b);
    return _categoryGradients[hash % _categoryGradients.length];
  }

  // Company search functionality
  void _performCompanySearch(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _filteredTargets = [];
        _isSearching = false;
        _selectedCompany =
            null; // Clear selected company when search is cleared
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _selectedCompany = null; // Clear selected company when searching
      _filteredTargets =
          _collectionTargets.where((target) {
            final searchQuery = query.toLowerCase().trim();
            final companyName = target.cateName.toLowerCase();
            final companyCode = target.cateCode.toLowerCase();

            return companyName.contains(searchQuery) ||
                companyCode.contains(searchQuery);
          }).toList();
    });
  }

  void _clearCompanySearch() {
    _companySearchController.clear();
    setState(() {
      _selectedCompany = null;
      _filteredTargets = [];
      _isSearching = false;
    });
  }

  void _selectCompany(CollectionTarget target) {
    _companySearchController.text = target.cateName;
    setState(() {
      _selectedCompany = target;
      _filteredTargets = [];
      _isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final size = MediaQuery.of(context).size;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final shouldLogout = await _showExitConfirmation();
        if (shouldLogout && mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
          );
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFf8fafc),
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Modern App Bar
            SliverAppBar(
              expandedHeight: 120,
              floating: false,
              pinned: true,
              elevation: 0,
              backgroundColor: Colors.transparent,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF667eea),
                        const Color(0xFF764ba2),
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.arrow_back_ios,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                onPressed: _handleLogout,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Collection Targets',
                                      style: textTheme.headlineSmall?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    if (widget.loginDetails != null)
                                      Text(
                                        widget.loginDetails!.brnchName,
                                        style: textTheme.bodySmall?.copyWith(
                                          color: Colors.white70,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.business,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                tooltip: 'Switch Branch',
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => BranchSelectionPage(
                                            loginDetails: widget.loginDetails!,
                                          ),
                                    ),
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.refresh,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                tooltip: 'Refresh',
                                onPressed: () {
                                  if (_selectedMonth != null &&
                                      widget.loginDetails != null) {
                                    final stateId =
                                        widget.loginDetails!.stateId;
                                    _fetchCollectionTargets(
                                      widget.loginDetails!.userName,
                                      widget.loginDetails!.brnchId,
                                      _selectedMonth!.monthId,
                                      stateId,
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Content
            SliverPadding(
              padding: const EdgeInsets.all(20.0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        children: [
                          _buildMonthSelectorCard(colorScheme, textTheme),
                          const SizedBox(height: 24),
                          _buildCompanySearchCard(colorScheme, textTheme),
                          const SizedBox(height: 24),
                          if (_selectedCompany != null) ...[
                            _buildSelectedCompanyCard(textTheme),
                            const SizedBox(height: 24),
                          ],
                          _buildHeaderStats(colorScheme, textTheme),
                          const SizedBox(height: 24),
                          // State details section
                          if (_stateDetails.isNotEmpty)
                            _buildStateDetailsCard(textTheme),
                        ],
                      ),
                    ),
                  ),
                ]),
              ),
            ),
            _buildTargetsList(colorScheme, textTheme),
          ],
        ),
        floatingActionButton: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF667eea).withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 10),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => CollectionPlanPage(
                        username: widget.loginDetails?.userName ?? 'admin',
                        password: 'password',
                        initialLoginDetails: widget.loginDetails,
                        stateId: widget.loginDetails?.stateId,
                      ),
                ),
              );
            },
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: const Icon(Icons.add, color: Colors.white, size: 28),
          ),
        ),
      ),
    );
  }

  Widget _buildMonthSelectorCard(ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.9),
            Colors.white.withOpacity(0.7),
          ],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667eea).withOpacity(0.1),
            blurRadius: 30,
            offset: const Offset(0, 15),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF667eea).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.calendar_today,
                    color: Color(0xFF667eea),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'SELECT MONTH',
                  style: textTheme.labelLarge?.copyWith(
                    color: const Color(0xFF667eea),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _isLoadingMonths
                ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF667eea),
                    ),
                  ),
                )
                : _monthsErrorMessage != null
                ? Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade600),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Error: $_monthsErrorMessage',
                          style: textTheme.bodyMedium?.copyWith(
                            color: Colors.red.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
                : _months.isEmpty
                ? Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.grey.shade600),
                      const SizedBox(width: 12),
                      Text(
                        'No months available.',
                        style: textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                )
                : Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: DropdownButton<Month>(
                    value: _selectedMonth,
                    hint: Text(
                      'Select Month',
                      style: textTheme.bodyLarge?.copyWith(
                        color: const Color(0xFF667eea),
                      ),
                    ),
                    isExpanded: true,
                    underline: const SizedBox(),
                    borderRadius: BorderRadius.circular(16),
                    dropdownColor: Colors.white,
                    icon: const Icon(
                      Icons.arrow_drop_down,
                      color: Color(0xFF667eea),
                    ),
                    onChanged: (Month? newValue) {
                      setState(() {
                        _selectedMonth = newValue;
                        if (newValue != null && widget.loginDetails != null) {
                          final stateId = widget.loginDetails!.stateId;
                          _fetchCollectionTargets(
                            widget.loginDetails!.userName,
                            widget.loginDetails!.brnchId,
                            newValue.monthId,
                            stateId,
                          );
                        }
                      });
                    },
                    items:
                        _months.map<DropdownMenuItem<Month>>((month) {
                          return DropdownMenuItem<Month>(
                            value: month,
                            child: Text(
                              month.monthDesc,
                              style: textTheme.bodyLarge?.copyWith(
                                color: const Color(0xFF667eea),
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompanySearchCard(ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.9),
            Colors.white.withOpacity(0.7),
          ],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667eea).withOpacity(0.1),
            blurRadius: 30,
            offset: const Offset(0, 15),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF667eea).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.search,
                    color: Color(0xFF667eea),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'SEARCH COMPANY',
                  style: textTheme.labelLarge?.copyWith(
                    color: const Color(0xFF667eea),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _companySearchController,
              onChanged: _performCompanySearch,
              decoration: InputDecoration(
                hintText: 'Search by company name or code',
                hintStyle: textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF667eea)),
                suffixIcon:
                    _companySearchController.text.isNotEmpty
                        ? IconButton(
                          icon: const Icon(
                            Icons.clear,
                            color: Color(0xFF667eea),
                          ),
                          onPressed: _clearCompanySearch,
                        )
                        : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.8),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_isSearching && _filteredTargets.isNotEmpty)
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _filteredTargets.length,
                itemBuilder: (context, index) {
                  final target = _filteredTargets[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: _CompanySearchResultItem(
                      target: target,
                      onSelect: () {
                        _selectCompany(target);
                      },
                    ),
                  );
                },
              ),
            if (_isSearching && _filteredTargets.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'No results found for "${_companySearchController.text}"',
                  style: textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderStats(ColorScheme colorScheme, TextTheme textTheme) {
    final double totalTarget = _collectionTargets.fold(
      0.0,
      (sum, item) => sum + item.hamt1,
    );
    final double totalCollected = _collectionTargets.fold(
      0.0,
      (sum, item) => sum + item.hamt2,
    );
    final double progress =
        totalTarget > 0 ? (totalCollected / totalTarget) : 0.0;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Colors.grey.shade50],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF667eea).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.assessment,
                        color: Color(0xFF667eea),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'COLLECTION SUMMARY',
                        style: textTheme.labelLarge?.copyWith(
                          color: const Color(0xFF667eea),
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ],
                ),
                if (_selectedMonth != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _selectedMonth!.monthDesc,
                      style: textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                final isWideScreen = constraints.maxWidth > 400;
                return isWideScreen
                    ? Row(
                      children: [
                        Expanded(
                          child: _ModernStatCard(
                            title: 'First Half',
                            value: totalTarget,
                            color: const Color(0xFF667eea),
                            icon: Icons.flag_outlined,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _ModernStatCard(
                            title: 'Second Half',
                            value: totalCollected,
                            color:
                                progress >= 1
                                    ? const Color(0xFF43e97b)
                                    : const Color(0xFFf5576c),
                            icon: Icons.attach_money_outlined,
                            gradient:
                                progress >= 1
                                    ? const LinearGradient(
                                      colors: [
                                        Color(0xFF43e97b),
                                        Color(0xFF38f9d7),
                                      ],
                                    )
                                    : const LinearGradient(
                                      colors: [
                                        Color(0xFFf5576c),
                                        Color(0xFFf093fb),
                                      ],
                                    ),
                          ),
                        ),
                      ],
                    )
                    : Column(
                      children: [
                        _ModernStatCard(
                          title: 'First Half',
                          value: totalTarget,
                          color: const Color(0xFF667eea),
                          icon: Icons.flag_outlined,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _ModernStatCard(
                          title: 'Second Half',
                          value: totalCollected,
                          color:
                              progress >= 1
                                  ? const Color(0xFF43e97b)
                                  : const Color(0xFFf5576c),
                          icon: Icons.attach_money_outlined,
                          gradient:
                              progress >= 1
                                  ? const LinearGradient(
                                    colors: [
                                      Color(0xFF43e97b),
                                      Color(0xFF38f9d7),
                                    ],
                                  )
                                  : const LinearGradient(
                                    colors: [
                                      Color(0xFFf5576c),
                                      Color(0xFFf093fb),
                                    ],
                                  ),
                        ),
                      ],
                    );
              },
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Progress',
                    style: textTheme.labelMedium?.copyWith(
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Stack(
                    children: [
                      Container(
                        height: 8,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: Colors.grey.shade200,
                        ),
                      ),
                      Container(
                        height: 8,
                        width: double.infinity,
                        child: FractionallySizedBox(
                          widthFactor: progress,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              gradient:
                                  progress >= 1
                                      ? const LinearGradient(
                                        colors: [
                                          Color(0xFF43e97b),
                                          Color(0xFF38f9d7),
                                        ],
                                      )
                                      : const LinearGradient(
                                        colors: [
                                          Color(0xFF667eea),
                                          Color(0xFF764ba2),
                                        ],
                                      ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '₹${totalCollected.toStringAsFixed(2)} of ₹${totalTarget.toStringAsFixed(2)}',
                        style: textTheme.labelSmall?.copyWith(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Progress: ${(progress * 100).toStringAsFixed(1)}%',
                            style: textTheme.labelSmall?.copyWith(
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  progress >= 1
                                      ? Colors.green.shade50
                                      : Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              progress >= 1 ? 'Completed' : 'In Progress',
                              style: textTheme.labelSmall?.copyWith(
                                color:
                                    progress >= 1
                                        ? Colors.green.shade700
                                        : Colors.orange.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedCompanyCard(TextTheme textTheme) {
    if (_selectedCompany == null) return const SizedBox.shrink();

    final target = _selectedCompany!;
    final categoryGradient = _getCategoryGradient(target.cateCode);
    final double progress =
        target.hamt1 > 0 ? (target.hamt2 / target.hamt1) : 0.0;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.95),
            Colors.white.withOpacity(0.8),
          ],
        ),
        border: Border.all(
          color: categoryGradient.colors.first.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: categoryGradient.colors.first.withOpacity(0.15),
            blurRadius: 30,
            offset: const Offset(0, 15),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: categoryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.business,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SELECTED COMPANY',
                        style: textTheme.labelLarge?.copyWith(
                          color: const Color(0xFF667eea),
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        target.cateName,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _clearCompanySearch,
                  icon: const Icon(Icons.close, color: Color(0xFF667eea)),
                  tooltip: 'Clear Selection',
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.9),
                    Colors.white.withOpacity(0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: categoryGradient.colors.first.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          target.cateCode,
                          style: textTheme.labelMedium?.copyWith(
                            color: categoryGradient.colors.first,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (target.catePName.isNotEmpty)
                        Expanded(
                          child: Text(
                            target.catePName,
                            style: textTheme.bodyMedium?.copyWith(
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      if (target.catePHN3.isNotEmpty) ...[
                        Icon(
                          Icons.phone_outlined,
                          size: 18,
                          color: categoryGradient.colors.first,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            target.catePHN3,
                            style: textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                      if (target.cateEmail.isNotEmpty) ...[
                        const SizedBox(width: 16),
                        Icon(
                          Icons.email_outlined,
                          size: 18,
                          color: categoryGradient.colors.first,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            target.cateEmail,
                            style: textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: categoryGradient,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Collection Progress',
                        style: textTheme.labelMedium?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${(progress * 100).toStringAsFixed(1)}%',
                          style: textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    color: Colors.white,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Target',
                              style: textTheme.labelSmall?.copyWith(
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '₹${target.hamt1.toStringAsFixed(2)}',
                              style: textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Collected',
                              style: textTheme.labelSmall?.copyWith(
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '₹${target.hamt2.toStringAsFixed(2)}',
                              style: textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final bool? result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) =>
                                  EditClientScreen(tgtplnMid: target.tgtPlnMId),
                        ),
                      );
                      if (result == true) {
                        if (_selectedMonth != null &&
                            widget.loginDetails != null) {
                          final stateId = widget.loginDetails!.stateId;
                          _fetchCollectionTargets(
                            widget.loginDetails!.userName,
                            widget.loginDetails!.brnchId,
                            _selectedMonth!.monthId,
                            stateId,
                          );
                        }
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: categoryGradient.colors.first),
                    ),
                    icon: Icon(
                      Icons.edit_outlined,
                      size: 18,
                      color: categoryGradient.colors.first,
                    ),
                    label: Text(
                      'Edit',
                      style: TextStyle(
                        color: categoryGradient.colors.first,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => ViewTargetActualScreen(
                                tgtplnMid: target.tgtPlnMId,
                              ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: categoryGradient.colors.first,
                    ),
                    icon: const Icon(
                      Icons.visibility_outlined,
                      size: 18,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'View',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStateDetailsCard(TextTheme textTheme) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Colors.grey.shade50],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF667eea).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.location_on,
                    color: Color(0xFF667eea),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'STATE DETAILS',
                  style: textTheme.labelLarge?.copyWith(
                    color: const Color(0xFF667eea),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._stateDetails.map(
              (state) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.place, color: const Color(0xFF667eea), size: 20),
                    const SizedBox(width: 12),
                    Text(
                      state.stateName,
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTargetsList(ColorScheme colorScheme, TextTheme textTheme) {
    if (_isLoadingCollectionTargets) {
      return const SliverFillRemaining(
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667eea)),
          ),
        ),
      );
    }

    if (_collectionTargetsErrorMessage != null) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline,
                  color: Colors.red.shade600,
                  size: 48,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Error loading data',
                style: textTheme.titleMedium?.copyWith(
                  color: Colors.red.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _collectionTargetsErrorMessage!,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  if (_selectedMonth != null && widget.loginDetails != null) {
                    final stateId = widget.loginDetails!.stateId;
                    _fetchCollectionTargets(
                      widget.loginDetails!.userName,
                      widget.loginDetails!.brnchId,
                      _selectedMonth!.monthId,
                      stateId,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF667eea),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_collectionTargets.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF667eea).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.inbox_outlined,
                  size: 48,
                  color: const Color(0xFF667eea),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No targets found',
                style: textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF667eea),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'for selected month',
                style: textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  if (_selectedMonth != null && widget.loginDetails != null) {
                    final stateId = widget.loginDetails!.stateId;
                    _fetchCollectionTargets(
                      widget.loginDetails!.userName,
                      widget.loginDetails!.brnchId,
                      _selectedMonth!.monthId,
                      stateId,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF667eea),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final target = _collectionTargets[index];
          final categoryGradient = _getCategoryGradient(target.cateCode);
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _ModernTargetCard(
              target: target,
              categoryGradient: categoryGradient,
              onEdit: () async {
                final bool? result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) =>
                            EditClientScreen(tgtplnMid: target.tgtPlnMId),
                  ),
                );
                if (result == true) {
                  if (_selectedMonth != null && widget.loginDetails != null) {
                    final stateId = widget.loginDetails!.stateId;
                    _fetchCollectionTargets(
                      widget.loginDetails!.userName,
                      widget.loginDetails!.brnchId,
                      _selectedMonth!.monthId,
                      stateId,
                    );
                  }
                }
              },
              onView: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) =>
                            ViewTargetActualScreen(tgtplnMid: target.tgtPlnMId),
                  ),
                );
              },
            ),
          );
        }, childCount: _collectionTargets.length),
      ),
    );
  }
}

class _ModernStatCard extends StatelessWidget {
  final String title;
  final double value;
  final Color color;
  final IconData icon;
  final LinearGradient gradient;

  const _ModernStatCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 20, color: Colors.white),
              ),
              const Spacer(),
              Icon(
                Icons.trending_up,
                color: Colors.white.withOpacity(0.7),
                size: 16,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.white.withOpacity(0.8),
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              '₹${value.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModernTargetCard extends StatelessWidget {
  final CollectionTarget target;
  final LinearGradient categoryGradient;
  final VoidCallback onEdit;
  final VoidCallback onView;

  const _ModernTargetCard({
    required this.target,
    required this.categoryGradient,
    required this.onEdit,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final double progress =
        target.hamt1 > 0 ? (target.hamt2 / target.hamt1) : 0.0;
    final isWideScreen = MediaQuery.of(context).size.width > 400;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.95),
            Colors.white.withOpacity(0.8),
          ],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: categoryGradient.colors.first.withOpacity(0.1),
            blurRadius: 30,
            offset: const Offset(0, 15),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: categoryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.category,
                    size: 24,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        target.cateCode,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: categoryGradient.colors.first,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        target.cateName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (target.catePName.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            target.catePName,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.9),
                    Colors.white.withOpacity(0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progress',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color:
                              progress >= 1
                                  ? Colors.green.shade50
                                  : Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${(progress * 100).toStringAsFixed(1)}%',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color:
                                progress >= 1
                                    ? Colors.green.shade700
                                    : Colors.orange.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey.shade200,
                    color:
                        progress >= 1
                            ? Colors.green
                            : categoryGradient.colors.first,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            isWideScreen
                ? Row(
                  children: [
                    Expanded(
                      child: _ModernAmountIndicator(
                        title: 'First Half',
                        amount: target.hamt1,
                        color: const Color(0xFF667eea),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ModernAmountIndicator(
                        title: 'Second Half',
                        amount: target.hamt2,
                        color:
                            progress >= 1
                                ? const Color(0xFF43e97b)
                                : const Color(0xFFf5576c),
                        gradient:
                            progress >= 1
                                ? const LinearGradient(
                                  colors: [
                                    Color(0xFF43e97b),
                                    Color(0xFF38f9d7),
                                  ],
                                )
                                : const LinearGradient(
                                  colors: [
                                    Color(0xFFf5576c),
                                    Color(0xFFf093fb),
                                  ],
                                ),
                      ),
                    ),
                  ],
                )
                : Column(
                  children: [
                    _ModernAmountIndicator(
                      title: 'First Half',
                      amount: target.hamt1,
                      color: const Color(0xFF667eea),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _ModernAmountIndicator(
                      title: 'Second Half',
                      amount: target.hamt2,
                      color:
                          progress >= 1
                              ? const Color(0xFF43e97b)
                              : const Color(0xFFf5576c),
                      gradient:
                          progress >= 1
                              ? const LinearGradient(
                                colors: [Color(0xFF43e97b), Color(0xFF38f9d7)],
                              )
                              : const LinearGradient(
                                colors: [Color(0xFFf5576c), Color(0xFFf093fb)],
                              ),
                    ),
                  ],
                ),
            if (target.catePHN3.isNotEmpty || target.cateEmail.isNotEmpty) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    if (target.catePHN3.isNotEmpty)
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              Icons.phone_outlined,
                              size: 18,
                              color: categoryGradient.colors.first,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                target.catePHN3,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.grey.shade700,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (target.cateEmail.isNotEmpty)
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              Icons.email_outlined,
                              size: 18,
                              color: categoryGradient.colors.first,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                target.cateEmail,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.grey.shade700,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onEdit,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: categoryGradient.colors.first),
                    ),
                    icon: Icon(
                      Icons.edit_outlined,
                      size: 18,
                      color: categoryGradient.colors.first,
                    ),
                    label: Text(
                      'Edit',
                      style: TextStyle(
                        color: categoryGradient.colors.first,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onView,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: categoryGradient.colors.first,
                    ),
                    icon: const Icon(
                      Icons.visibility_outlined,
                      size: 18,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'View',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ModernAmountIndicator extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;
  final LinearGradient gradient;

  const _ModernAmountIndicator({
    required this.title,
    required this.amount,
    required this.color,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.white.withOpacity(0.8),
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              '₹${amount.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompanySearchResultItem extends StatelessWidget {
  final CollectionTarget target;
  final VoidCallback onSelect;

  const _CompanySearchResultItem({
    required this.target,
    required this.onSelect,
  });

  LinearGradient _getCategoryGradient(String categoryCode) {
    final List<LinearGradient> categoryGradients = [
      const LinearGradient(colors: [Color(0xFF667eea), Color(0xFF764ba2)]),
      const LinearGradient(colors: [Color(0xFFf093fb), Color(0xFFf5576c)]),
      const LinearGradient(colors: [Color(0xFF4facfe), Color(0xFF00f2fe)]),
      const LinearGradient(colors: [Color(0xFF43e97b), Color(0xFF38f9d7)]),
      const LinearGradient(colors: [Color(0xFFfa709a), Color(0xFFfee140)]),
      const LinearGradient(colors: [Color(0xFFa8edea), Color(0xFFfed6e3)]),
      const LinearGradient(colors: [Color(0xFFff9a9e), Color(0xFFfecfef)]),
      const LinearGradient(colors: [Color(0xFFffecd2), Color(0xFFfcb69f)]),
    ];
    final hash = categoryCode.codeUnits.fold(0, (a, b) => a + b);
    return categoryGradients[hash % categoryGradients.length];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoryGradient = _getCategoryGradient(target.cateCode);

    return GestureDetector(
      onTap: onSelect,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: categoryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.category, size: 24, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: categoryGradient.colors.first.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          target.cateCode,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: categoryGradient.colors.first,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    target.cateName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (target.catePName.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        target.catePName,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
