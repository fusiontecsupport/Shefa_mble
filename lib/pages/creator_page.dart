import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'api_service.dart';
import 'location.dart';
import 'dealer.dart';
import 'month.dart';
import 'state.dart' as state_model;
import 'index.dart';

class CollectionPlanPage extends StatefulWidget {
  final String username;
  final String password;
  final LoginDetails? initialLoginDetails;
  final int? stateId;

  const CollectionPlanPage({
    super.key,
    required this.username,
    required this.password,
    this.initialLoginDetails,
    this.stateId,
  });

  @override
  State<CollectionPlanPage> createState() => _CollectionPlanPageState();
}

class _CollectionPlanPageState extends State<CollectionPlanPage> {
  final ApiService _apiService = ApiService();
  final GlobalKey<FormState> _formKey = GlobalKey();
  final List<String> categories = ['Select Categories', 'Diamond', 'Golden'];

  String? stateName;
  String? usernameFromLogin;
  int? branchId;
  int? stateId;
  bool isAdmin = false;

  String? selectedCategory = 'Select Categories';
  Location? selectedLocation;
  Dealer? selectedDealer;
  Month? selectedMonth;
  state_model.State? selectedState;

  bool isLoading = true;
  bool isSaving = false;
  List<Location> locations = [];
  List<Dealer> dealers = [];
  List<Month> months = [];
  List<Map<String, dynamic>> dealerOutstandingList = [];
  List<TextEditingController> firstHalfControllers = [];
  List<TextEditingController> secondHalfControllers = [];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    if (widget.stateId != null) {
      stateId = widget.stateId;
      fetchStateDetails(widget.stateId!);
      fetchLocations(widget.stateId!);
    }

    if (widget.initialLoginDetails != null) {
      _handleLoginDetails(widget.initialLoginDetails!);
    } else if (widget.stateId == null) {
      fetchLoginAndState();
    }

    fetchMonths();
  }

  @override
  void dispose() {
    _cleanupControllers();
    super.dispose();
  }

  void _cleanupControllers() {
    for (var c in [...firstHalfControllers, ...secondHalfControllers]) {
      c.dispose();
    }
  }

  void _handleLoginDetails(LoginDetails loginData) {
    setState(() {
      usernameFromLogin = loginData.userName;
      branchId = loginData.brnchId;
      stateId ??= loginData.stateId;
      stateName = loginData.stateName;
      isAdmin = loginData.isAdmin;
      isLoading = false;
    });

    // Fetch state details to get the description
    fetchStateDetails(loginData.stateId);

    if (isAdmin) {
      // Only fetch locations if not an admin, as admin fetches all states
      if (!isAdmin) {
        fetchLocations(loginData.stateId);
      }
    } else {
      fetchLocations(loginData.stateId);
    }
  }

  Future<void> fetchMonths() async {
    try {
      final monthList = await _apiService.getMonthDetails();
      if (mounted) {
        setState(() => months = monthList);
      }
    } catch (e) {
      _showError('Error fetching months: ${e.toString()}');
    }
  }

  Future<void> fetchLoginAndState() async {
    try {
      final LoginDetails? loginData = await _apiService
          .login(widget.username, widget.password)
          .timeout(const Duration(seconds: 30));

      if (loginData != null && mounted) {
        _handleLoginDetails(loginData);
      } else {
        _showError('Login failed: No login data received');
      }
    } catch (e) {
      _showError('Error fetching login data: ${e.toString()}');
    }
  }

  Future<void> fetchStateDetails(int stateId) async {
    try {
      final stateList = await _apiService
          .getBranchStateDetails(stateId)
          .timeout(const Duration(seconds: 30));

      if (mounted && stateList.isNotEmpty) {
        setState(() {
          selectedState = stateList.first;
          stateName = stateList.first.stateName;
        });
      }
    } catch (e) {
      _showError('Error fetching state details: ${e.toString()}');
    }
  }

  Future<void> fetchLocations(int stateId) async {
    try {
      final locationList = await _apiService
          .getLocationDetails(stateId)
          .timeout(const Duration(seconds: 30));

      if (mounted) {
        setState(() {
          locations = locationList;
          isLoading = false;
        });
      }
    } catch (e) {
      _showError('Error fetching locations: ${e.toString()}');
    }
  }

  void _onStateChanged(state_model.State? newState) {
    if (newState != null) {
      setState(() {
        selectedState = newState;
        stateId = newState.id;
        stateName = newState.stateName;
        selectedLocation = null;
        locations = [];
        _resetDealerData();
      });
      fetchLocations(newState.id);
    }
  }

  Future<void> fetchDealers() async {
    if (selectedLocation == null ||
        selectedCategory == 'Select Categories' ||
        selectedMonth == null) {
      _resetDealerData();
      return;
    }

    try {
      final List<Dealer> dealerList = await _apiService
          .getDealerListDetails(
            selectedLocation!.loctId.toString(),
            selectedCategory == 'Diamond' ? '1' : '2',
            selectedMonth!.monthId.toString(),
          )
          .timeout(const Duration(seconds: 30));

      if (mounted) {
        setState(() {
          dealers = dealerList;
          if (selectedDealer != null &&
              !dealers.any((d) => d.cateId == selectedDealer!.cateId)) {
            _resetDealerData();
          }
        });
      }
    } catch (e) {
      _showError('Error fetching dealers: ${e.toString()}');
      _resetDealerData();
    }
  }

  Future<void> fetchDealerOutstanding() async {
    if (selectedDealer == null) {
      _resetDealerData();
      return;
    }

    try {
      final data = await _apiService
          .getDealerOutstandingDetails(
            selectedDealer!.cateId.toString(),
            branchId!,
          )
          .timeout(const Duration(seconds: 30));

      if (mounted) {
        setState(() {
          dealerOutstandingList = List<Map<String, dynamic>>.from(
            data['myRoot'] ?? [],
          );
          _initializeAmountControllers();
        });
      }
    } catch (e) {
      _showError('Error fetching dealer outstanding: ${e.toString()}');
      _resetDealerData();
    }
  }

  Future<void> saveCollectionPlan() async {
    if (!_validateForm()) return;

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirm Save'),
            content: const Text(
              'Are you sure you want to save this collection plan?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Yes'),
              ),
            ],
          ),
    );

    if (confirm != true) return;

    setState(() => isSaving = true);

    try {
      final requestBody = _buildRequestBody();
      debugPrint('Sending to API: ${jsonEncode(requestBody)}');

      final response = await _apiService.saveCollectionPlan(requestBody);
      debugPrint('API Response: ${response.toString()}');

      if (mounted) {
        if (response['Message']?.toString().toLowerCase().contains('success') ??
            false) {
          await _showSuccessDialog();
          _navigateToIndexPage();
        } else {
          _showError(response['Message'] ?? 'Failed to save collection plan');
        }
      }
    } catch (e) {
      _showError('Error saving collection plan: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  Map<String, dynamic> _buildRequestBody() {
    return {
      "dealer": {
        "cateId": selectedDealer!.cateId,
        "cateName": selectedDealer!.cateName,
        "brnchid": branchId!,
        "monthid": selectedMonth!.monthId,
        "cusrid": usernameFromLogin ?? widget.username,
      },
      "outstandingDetails":
          dealerOutstandingList.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;

            return {
              "TRANMID": item['TRANMID'],
              "TRANDNO": item['TRANDNO'].toString(),
              "TRANDATE": item['TRANDATE'].toString(),
              "TRANNAMT": _convertToDouble(item['TRANNAMT']),
              "TRANPAMT": _convertToDouble(item['TRANPAMT']),
              "TRANODAYS": item['OverDueDays'] ?? 0,
              "firstHalfAmount":
                  _parseAmount(firstHalfControllers[index].text) ?? 0.0,
              "secondHalfAmount":
                  _parseAmount(secondHalfControllers[index].text) ?? 0.0,
            };
          }).toList(),
    };
  }

  double _convertToDouble(dynamic value) {
    return value is int ? value.toDouble() : (value as double);
  }

  double? _parseAmount(String text) {
    return text.trim().isEmpty ? null : double.tryParse(text.trim());
  }

  Future<void> _showSuccessDialog() async {
    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Success'),
            content: const Text('Data sent successfully!'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _navigateToIndexPage();
                },
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  void _navigateToIndexPage() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder:
            (context) => IndexPage(loginDetails: widget.initialLoginDetails),
      ),
      (route) => false,
    );
  }

  void _resetDealerData() {
    if (mounted) {
      setState(() {
        dealers = [];
        selectedDealer = null;
        dealerOutstandingList = [];
        _clearAmountControllers();
      });
    }
  }

  void _initializeAmountControllers() {
    _clearAmountControllers();
    firstHalfControllers = List.generate(
      dealerOutstandingList.length,
      (_) => TextEditingController(),
    );
    secondHalfControllers = List.generate(
      dealerOutstandingList.length,
      (_) => TextEditingController(),
    );
  }

  void _clearAmountControllers() {
    _cleanupControllers();
    firstHalfControllers = [];
    secondHalfControllers = [];
  }

  void _showError(String message) {
    debugPrint(message);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      setState(() => isLoading = false);
    }
  }

  bool _validateForm() {
    if (selectedLocation == null ||
        selectedCategory == 'Select Categories' ||
        selectedMonth == null ||
        selectedDealer == null) {
      _showError('Please select all required fields');
      return false;
    }

    bool hasValidAmounts = true;

    for (int i = 0; i < dealerOutstandingList.length; i++) {
      final firstHalfText = firstHalfControllers[i].text.trim();
      final secondHalfText = secondHalfControllers[i].text.trim();

      // Check if both are empty or both have values
      if ((firstHalfText.isEmpty && secondHalfText.isNotEmpty) ||
          (firstHalfText.isNotEmpty && secondHalfText.isEmpty)) {
        _showError(
          'Please fill both amounts or leave both empty for invoice ${dealerOutstandingList[i]['TRANDNO']}',
        );
        hasValidAmounts = false;
        break;
      }

      // Validate if inputs are valid numbers
      final double? firstHalf = _parseAmount(firstHalfText);
      final double? secondHalf = _parseAmount(secondHalfText);

      if (firstHalfText.isNotEmpty && firstHalf == null) {
        _showError(
          'Please enter a valid number for First Half amount for invoice ${dealerOutstandingList[i]['TRANDNO']}',
        );
        hasValidAmounts = false;
        break;
      }
      if (secondHalfText.isNotEmpty && secondHalf == null) {
        _showError(
          'Please enter a valid number for Second Half amount for invoice ${dealerOutstandingList[i]['TRANDNO']}',
        );
        hasValidAmounts = false;
        break;
      }

      // If both are filled, apply the sum validation
      if (firstHalf != null && secondHalf != null) {
        final totalEnteredAmount = firstHalf + secondHalf;
        final trannamt = _convertToDouble(dealerOutstandingList[i]['TRANNAMT']);

        if (totalEnteredAmount > trannamt) {
          _showError(
            'The sum of First Half and Second Half amounts for invoice ${dealerOutstandingList[i]['TRANDNO']} cannot exceed the Total Amount (₹${trannamt.toStringAsFixed(2)})',
          );
          hasValidAmounts = false;
          break;
        }
      }
    }

    return hasValidAmounts;
  }

  // _validateAmount is no longer strictly needed as its logic is merged into _validateForm
  // bool _validateAmount(String value, String fieldName) {
  //   if (value.isNotEmpty && double.tryParse(value) == null) {
  //     _showError('Please enter valid numbers in $fieldName amounts');
  //     return false;
  //   }
  //   return true;
  // }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    try {
      return DateFormat('dd-MM-yyyy').format(DateTime.parse(date.toString()));
    } catch (e) {
      return 'Invalid Date';
    }
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_today, color: Colors.blue),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '2025 - 2026',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    'Set Collection Target',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (isAdmin) ...[
          _buildStateDropdown(),
          const SizedBox(height: 16),
        ] else ...[
          _buildInfoCard('', stateName ?? 'Loading...', Icons.location_on),
          const SizedBox(height: 16),
        ],
        _buildInfoCard(
          'Branch ID',
          branchId?.toString() ?? 'Loading...',
          Icons.apartment,
        ),
      ],
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: Colors.grey),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStateDropdown() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, color: Colors.grey),
                const SizedBox(width: 12),
                Text(
                  'State',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Replace the dropdown with a read-only display of the state name
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.deepPurple),
                const SizedBox(width: 8),
                Text(
                  stateName ?? 'State',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionSection() {
    return Column(
      children: [
        _buildSectionTitle('Select Dealer Details'),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildDropdown<Location>(
                  label: 'Location',
                  value: selectedLocation,
                  items: [
                    Location(loctId: '0', loctDesc: 'Select Location'),
                    ...locations,
                  ],
                  displayText: (loc) => loc?.loctDesc ?? '',
                  onChanged: (newValue) {
                    setState(() {
                      selectedLocation =
                          newValue?.loctId == '0' ? null : newValue;
                      _resetDealerData();
                      fetchDealers();
                    });
                  },
                ),
                const SizedBox(height: 16),
                _buildDropdown<String>(
                  label: 'Category',
                  value: selectedCategory,
                  items: categories,
                  displayText: (item) => item ?? '',
                  onChanged: (newValue) {
                    setState(() {
                      selectedCategory = newValue;
                      _resetDealerData();
                      fetchDealers();
                    });
                  },
                ),
                const SizedBox(height: 16),
                _buildDropdown<Month>(
                  label: 'Month',
                  value: selectedMonth,
                  items: [
                    Month(monthId: 0, monthDesc: 'Select Month', dispOrder: 0),
                    ...months,
                  ],
                  displayText: (month) => month?.monthDesc ?? '',
                  onChanged: (newValue) {
                    setState(() {
                      selectedMonth = newValue?.monthId == 0 ? null : newValue;
                      _resetDealerData();
                      fetchDealers();
                    });
                  },
                ),
                const SizedBox(height: 16),
                _buildDropdown<Dealer>(
                  label: 'Dealer',
                  value: selectedDealer,
                  items: [
                    Dealer(
                      cateId: 0,
                      cateName: 'Select Dealer',
                      creditPeriod: 0,
                    ),
                    ...dealers,
                  ],
                  displayText: (dealer) => dealer?.cateName ?? '',
                  onChanged: (newValue) async {
                    setState(
                      () =>
                          selectedDealer =
                              newValue?.cateId == 0 ? null : newValue,
                    );
                    if (selectedDealer != null) await fetchDealerOutstanding();
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T? value,
    required List<T> items,
    required String Function(T?) displayText,
    required void Function(T?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonFormField<T>(
            value: value,
            isExpanded: true,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
            items:
                items
                    .map(
                      (item) => DropdownMenuItem<T>(
                        value: item,
                        child: Text(
                          displayText(item),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
            onChanged: onChanged,
            validator:
                (value) =>
                    value == null ||
                            (value is Location && value.loctId == '0') ||
                            (value is Month && value.monthId == 0) ||
                            (value is Dealer && value.cateId == 0) ||
                            (value is String && value == 'Select Categories')
                        ? 'Please select a $label'
                        : null,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(height: 24, width: 4, color: Colors.blue),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildOutstandingSection() {
    return Column(
      children: [
        _buildSectionTitle('Dealer Outstanding'),
        const SizedBox(height: 12),
        if (dealerOutstandingList.isEmpty)
          _buildEmptyState()
        else ...[
          _buildSummaryCard(),
          const SizedBox(height: 16),
          ...dealerOutstandingList
              .asMap()
              .entries
              .map((entry) => _buildOutstandingItem(entry.key, entry.value))
              .toList(),
          const SizedBox(height: 20),
          _buildSaveButton(),
        ],
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isSaving ? null : saveCollectionPlan,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child:
            isSaving
                ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                : const Text(
                  'Save Collection',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final totalBills = dealerOutstandingList.length;
    final totalAmount = dealerOutstandingList.fold<double>(
      0.0,
      (sum, item) => sum + _convertToDouble(item['TRANNAMT']),
    );

    // Get credit period and outstanding due from first item (all are same)
    final creditPeriod =
        dealerOutstandingList.isNotEmpty
            ? dealerOutstandingList.first['Cate_CrdtPrd'] ?? 0
            : 0;
    final oDueAmt =
        dealerOutstandingList.isNotEmpty
            ? (dealerOutstandingList.first['ODueAmt'] as num?)?.toDouble() ??
                0.0
            : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Colors.indigo.shade50],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Compact Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.indigo.shade400, Colors.purple.shade500],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.insights, size: 14, color: Colors.white),
              ),
              const SizedBox(width: 8),
              Text(
                'Collection Summary',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${dealerOutstandingList.length} items',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Single Row Stats
          Row(
            children: [
              Expanded(
                child: _buildCompactElegantStat(
                  icon: Icons.receipt_long,
                  value: '$totalBills',
                  label: 'Bills',
                  color: Colors.blue,
                  gradient: [Colors.blue.shade400, Colors.blue.shade600],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildCompactElegantStat(
                  icon: Icons.currency_rupee,
                  value: '₹${totalAmount.toStringAsFixed(0)}',
                  label: ' total Invoice Amount',
                  color: Colors.teal,
                  gradient: [Colors.teal.shade400, Colors.teal.shade600],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildCompactElegantStat(
                  icon: Icons.access_time,
                  value: '$creditPeriod',
                  label: 'Days',
                  color: Colors.purple,
                  gradient: [Colors.purple.shade400, Colors.purple.shade600],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildCompactElegantStat(
                  icon: Icons.account_balance_wallet,
                  value: '₹${oDueAmt.toStringAsFixed(0)}',
                  label: 'Outstanding Due',
                  color: oDueAmt < 0 ? Colors.green : Colors.red,
                  gradient:
                      oDueAmt < 0
                          ? [Colors.green.shade400, Colors.green.shade600]
                          : [Colors.red.shade400, Colors.red.shade600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildElegantStat({
    required IconData icon,
    required String value,
    required String label,
    required String subtitle,
    required Color color,
    required List<Color> gradient,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
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
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: Colors.white),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.95),
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactElegantStat({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required List<Color> gradient,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 12, color: Colors.white),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: const Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.receipt_long, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text('No outstanding records found', textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildOutstandingItem(int index, Map<String, dynamic> item) {
    final totalAmount = (item['TRANNAMT'] as num).toDouble();
    final paidAmount = (item['TRANPAMT'] as num).toDouble();

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '₹${totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Invoice: ${item['TRANDNO'] ?? 'N/A'}',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildDateInfo(
                    Icons.calendar_today,
                    'Inv: ${_formatDate(item['TRANDATE'])}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildAmountField(
                    controller: firstHalfControllers[index],
                    label: 'First Half',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildAmountField(
                    controller: secondHalfControllers[index],
                    label: 'Second Half',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateInfo(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(color: Colors.grey.shade600)),
      ],
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(fontSize: 10, color: color.withOpacity(0.8)),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryInfoChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: TextStyle(fontSize: 11, color: color.withOpacity(0.8)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAmountField({
    required TextEditingController controller,
    required String label,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade600)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
          ), // Allow decimals
          decoration: InputDecoration(
            hintText: '0.00',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Collection Plan'),
        centerTitle: true,
        backgroundColor: Colors.blue.shade100,
        actions: [
          IconButton(
            icon: const Icon(Icons.list),
            onPressed:
                () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) =>
                            IndexPage(loginDetails: widget.initialLoginDetails),
                  ),
                ),
          ),
        ],
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- Show selected state description only ---
                      if (selectedState?.stateDesc != null) ...[
                        Row(
                          children: [
                            const Icon(
                              Icons.description,
                              color: Colors.blue,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                selectedState!.stateDesc!,
                                style: const TextStyle(
                                  color: Colors.blue,
                                  fontSize: 14,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                      const SizedBox(height: 16),
                      // --- End state id display ---
                      _buildHeader(),
                      const SizedBox(height: 24),
                      _buildSelectionSection(),
                      if (selectedDealer != null) ...[
                        const SizedBox(height: 24),
                        _buildOutstandingSection(),
                      ],
                    ],
                  ),
                ),
              ),
    );
  }
}
