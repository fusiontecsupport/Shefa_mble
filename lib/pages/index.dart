import 'package:flutter/material.dart';
import 'month.dart';
import 'api_service.dart';
import 'edit.dart';
import 'view.dart';
import 'creator_page.dart';
import 'login_page.dart';

class IndexPage extends StatefulWidget {
  final LoginDetails? loginDetails;

  const IndexPage({Key? key, this.loginDetails}) : super(key: key);

  @override
  State<IndexPage> createState() => _IndexPageState();
}

class _IndexPageState extends State<IndexPage> {
  final ApiService _apiService = ApiService();
  List<Month> _months = [];
  Month? _selectedMonth;
  bool _isLoadingMonths = true;
  String? _monthsErrorMessage;

  List<CollectionTarget> _collectionTargets = [];
  bool _isLoadingCollectionTargets = false;
  String? _collectionTargetsErrorMessage;

  // Color palette for the app
  final List<Color> _categoryColors = [
    Colors.blue.shade600,
    Colors.green.shade600,
    Colors.orange.shade600,
    Colors.purple.shade600,
    Colors.red.shade600,
    Colors.teal.shade600,
    Colors.pink.shade600,
    Colors.indigo.shade600,
  ];

  @override
  void initState() {
    super.initState();
    _fetchMonths();
  }

  Future<bool> _showExitConfirmation() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Exit'),
        content: const Text('Are you sure you want to return to login?'),
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
    ) ?? false;
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
      String userName, int branchId, int monthId, int stateId) async {
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
      });
    } catch (e) {
      setState(() {
        _collectionTargetsErrorMessage = 'Failed to load collection targets: $e';
        _isLoadingCollectionTargets = false;
      });
    }
  }

  Color _getCategoryColor(String categoryCode) {
    final hash = categoryCode.codeUnits.fold(0, (a, b) => a + b);
    return _categoryColors[hash % _categoryColors.length];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return WillPopScope(
      onWillPop: _showExitConfirmation,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: _handleLogout,
          ),
          title: Text(
            'Collection Targets',
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.deepPurple,
          elevation: 0,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(20),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              tooltip: 'Refresh',
              onPressed: () {
                if (_selectedMonth != null && widget.loginDetails != null) {
                  _fetchCollectionTargets(
                    widget.loginDetails!.userName,
                    widget.loginDetails!.brnchId,
                    _selectedMonth!.monthId,
                    widget.loginDetails!.stateId,
                  );
                }
              },
            ),
          ],
        ),
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(16.0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildMonthSelectorCard(colorScheme, textTheme),
                  const SizedBox(height: 24),
                  _buildHeaderStats(colorScheme, textTheme),
                  const SizedBox(height: 16),
                ]),
              ),
            ),
            _buildTargetsList(colorScheme, textTheme),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CollectionPlanPage(
                  username: widget.loginDetails?.userName ?? 'admin',
                  password: 'password',
                  initialLoginDetails: widget.loginDetails,
                ),
              ),
            );
          },
          backgroundColor: Colors.deepPurple,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildMonthSelectorCard(ColorScheme colorScheme, TextTheme textTheme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.deepPurple, size: 20),
                const SizedBox(width: 8),
                Text(
                  'SELECT MONTH',
                  style: textTheme.labelLarge?.copyWith(
                    color: Colors.deepPurple,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _isLoadingMonths
                ? const Center(child: CircularProgressIndicator())
                : _monthsErrorMessage != null
                    ? Text(
                        'Error: $_monthsErrorMessage',
                        style: textTheme.bodyMedium?.copyWith(
                          color: Colors.red,
                        ),
                      )
                    : _months.isEmpty
                        ? Text(
                            'No months available.',
                            style: textTheme.bodyMedium,
                          )
                        : Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.deepPurple.withOpacity(0.1),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: DropdownButton<Month>(
                              value: _selectedMonth,
                              hint: Text('Select Month',
                                  style: textTheme.bodyLarge?.copyWith(
                                      color: Colors.deepPurple)),
                              isExpanded: true,
                              underline: const SizedBox(),
                              borderRadius: BorderRadius.circular(16),
                              dropdownColor: Colors.white,
                              icon: Icon(
                                Icons.arrow_drop_down,
                                color: Colors.deepPurple,
                              ),
                              onChanged: (Month? newValue) {
                                setState(() {
                                  _selectedMonth = newValue;
                                  if (newValue != null && widget.loginDetails != null) {
                                    _fetchCollectionTargets(
                                      widget.loginDetails!.userName,
                                      widget.loginDetails!.brnchId,
                                      newValue.monthId,
                                      widget.loginDetails!.stateId,
                                    );
                                  }
                                });
                              },
                              items: _months.map<DropdownMenuItem<Month>>(
                                  (month) {
                                return DropdownMenuItem<Month>(
                                  value: month,
                                  child: Text(
                                    month.monthDesc,
                                    style: textTheme.bodyLarge?.copyWith(
                                        color: Colors.deepPurple),
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

  Widget _buildHeaderStats(ColorScheme colorScheme, TextTheme textTheme) {
    final double totalTarget = _collectionTargets.fold(
        0.0, (sum, item) => sum + item.hamt1);
    final double totalCollected = _collectionTargets.fold(
        0.0, (sum, item) => sum + item.hamt2);
    final double progress = totalTarget > 0 ? (totalCollected / totalTarget) : 0.0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.assessment, color: Colors.deepPurple, size: 20),
                const SizedBox(width: 8),
                Text(
                  'COLLECTION SUMMARY',
                  style: textTheme.labelLarge?.copyWith(
                    color: Colors.deepPurple,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                if (_selectedMonth != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.deepPurple,
                          Colors.purpleAccent,
                        ],
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
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Target',
                    value: totalTarget,
                    color: Colors.deepPurple,
                    icon: Icons.flag_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'Collected',
                    value: totalCollected,
                    color: progress >= 1 ? Colors.green : Colors.orange,
                    icon: Icons.attach_money_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Stack(
              children: [
                Container(
                  height: 12,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: Colors.grey[200],
                  ),
                ),
                Container(
                  height: 12,
                  width: double.infinity,
                  child: FractionallySizedBox(
                    widthFactor: progress,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        gradient: LinearGradient(
                          colors: progress >= 1
                              ? [Colors.green, Colors.lightGreenAccent]
                              : [Colors.deepPurple, Colors.purpleAccent],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(progress * 100).toStringAsFixed(1)}% Completed',
                  style: textTheme.labelSmall?.copyWith(
                    color: Colors.deepPurple,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '₹${totalCollected.toStringAsFixed(2)} of ₹${totalTarget.toStringAsFixed(2)}',
                  style: textTheme.labelSmall?.copyWith(
                    color: Colors.deepPurple,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
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
            valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
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
              Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                'Error loading data',
                style: textTheme.titleMedium?.copyWith(
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _collectionTargetsErrorMessage!,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  if (_selectedMonth != null && widget.loginDetails != null) {
                    _fetchCollectionTargets(
                      widget.loginDetails!.userName,
                      widget.loginDetails!.brnchId,
                      _selectedMonth!.monthId,
                      widget.loginDetails!.stateId,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Retry', style: TextStyle(color: Colors.white)),
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
              Icon(
                Icons.inbox_outlined,
                size: 64,
                color: Colors.deepPurple.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No targets found',
                style: textTheme.titleMedium?.copyWith(
                  color: Colors.deepPurple,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'for selected month',
                style: textTheme.bodyMedium?.copyWith(
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  if (_selectedMonth != null && widget.loginDetails != null) {
                    _fetchCollectionTargets(
                      widget.loginDetails!.userName,
                      widget.loginDetails!.brnchId,
                      _selectedMonth!.monthId,
                      widget.loginDetails!.stateId,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Refresh', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final target = _collectionTargets[index];
            final categoryColor = _getCategoryColor(target.cateCode);
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _TargetCard(
                target: target,
                categoryColor: categoryColor,
                onEdit: () async {
                  final bool? result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          EditClientScreen(tgtplnMid: target.tgtPlnMId),
                    ),
                  );
                  if (result == true) {
                    if (_selectedMonth != null && widget.loginDetails != null) {
                      _fetchCollectionTargets(
                        widget.loginDetails!.userName,
                        widget.loginDetails!.brnchId,
                        _selectedMonth!.monthId,
                        widget.loginDetails!.stateId,
                      );
                    }
                  }
                },
                onView: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ViewTargetActualScreen(tgtplnMid: target.tgtPlnMId),
                    ),
                  );
                },
              ),
            );
          },
          childCount: _collectionTargets.length,
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final double value;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 24, color: color),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                '₹${value.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TargetCard extends StatelessWidget {
  final CollectionTarget target;
  final Color categoryColor;
  final VoidCallback onEdit;
  final VoidCallback onView;

  const _TargetCard({
    required this.target,
    required this.categoryColor,
    required this.onEdit,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final double progress = target.hamt1 > 0 ? (target.hamt2 / target.hamt1) : 0.0;
    final isWideScreen = MediaQuery.of(context).size.width > 400;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    target.cateCode,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: categoryColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                                color: Colors.grey[600],
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
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progress',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        '${(progress * 100).toStringAsFixed(1)}%',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey[200],
                    color: progress >= 1 ? Colors.green : categoryColor,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              isWideScreen
                  ? Row(
                      children: [
                        Expanded(
                          child: _AmountIndicator(
                            title: 'Target',
                            amount: target.hamt1,
                            color: Colors.deepPurple,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _AmountIndicator(
                            title: 'Collected',
                            amount: target.hamt2,
                            color: progress >= 1 ? Colors.green : Colors.orange,
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        _AmountIndicator(
                          title: 'Target',
                          amount: target.hamt1,
                          color: Colors.deepPurple,
                        ),
                        const SizedBox(height: 8),
                        _AmountIndicator(
                          title: 'Collected',
                          amount: target.hamt2,
                          color: progress >= 1 ? Colors.green : Colors.orange,
                        ),
                      ],
                    ),
              if (target.catePHN3.isNotEmpty || target.cateEmail.isNotEmpty) ...[
                const SizedBox(height: 16),
                Divider(
                  height: 1,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (target.catePHN3.isNotEmpty)
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              Icons.phone_outlined,
                              size: 18,
                              color: categoryColor,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                target.catePHN3,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[700],
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
                              color: categoryColor,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                target.cateEmail,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[700],
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onEdit,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(
                          color: categoryColor,
                        ),
                      ),
                      icon: Icon(
                        Icons.edit_outlined,
                        size: 18,
                        color: categoryColor,
                      ),
                      label: Text(
                        'Edit',
                        style: TextStyle(
                          color: categoryColor,
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
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: categoryColor,
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
      ),
    );
  }
}

class _AmountIndicator extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;

  const _AmountIndicator({
    required this.title,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 4),
          Text(
            '₹${amount.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
          ),
        ],
      ),
    );
  }
}