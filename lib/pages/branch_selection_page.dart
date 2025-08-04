import 'package:flutter/material.dart';
import 'api_service.dart';
import 'branch.dart';
import 'index.dart';

class BranchSelectionPage extends StatefulWidget {
  final LoginDetails loginDetails;

  const BranchSelectionPage({super.key, required this.loginDetails});

  @override
  State<BranchSelectionPage> createState() => _BranchSelectionPageState();
}

class _BranchSelectionPageState extends State<BranchSelectionPage> {
  final ApiService _apiService = ApiService();
  List<Branch> _branches = [];
  Branch? _selectedBranch;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchBranches();
  }

  Future<void> _fetchBranches() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      print(
        '🔍 DEBUG: Starting to fetch branches for user: ${widget.loginDetails.userName}, branchId: ${widget.loginDetails.brnchId}',
      );

      final branches = await _apiService.getBranchList(
        widget.loginDetails.userName,
        widget.loginDetails.brnchId,
      );

      // Debug logging
      print('🔍 DEBUG: Found ${branches.length} branches');
      if (branches.isEmpty) {
        print('🔍 WARNING: No branches returned from API');
      } else {
        for (int i = 0; i < branches.length; i++) {
          print(
            '🔍 Branch $i: ${branches[i].branchName} (ID: ${branches[i].branchId})',
          );
        }
      }

      setState(() {
        _branches = branches;
        if (branches.isNotEmpty) {
          _selectedBranch = branches.first;
          print('🔍 Selected first branch: ${_selectedBranch!.branchName}');
        } else {
          print('🔍 No branches available to select');
        }
        _isLoading = false;
      });
    } catch (e) {
      print('🔍 ERROR: Failed to load branches: $e');
      setState(() {
        _errorMessage = 'Failed to load branches: $e';
        _isLoading = false;
      });
    }
  }

  void _proceedToMainApp() {
    if (_selectedBranch != null) {
      // Create updated login details with selected branch
      final updatedLoginDetails = LoginDetails(
        id: widget.loginDetails.id,
        userName: widget.loginDetails.userName,
        brnchName: _selectedBranch!.branchName,
        emplName: widget.loginDetails.emplName,
        stateName: _selectedBranch!.stateName,
        brnchId: _selectedBranch!.branchId,
        stateId: _selectedBranch!.stateId,
        isAdmin: widget.loginDetails.isAdmin,
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => IndexPage(loginDetails: updatedLoginDetails),
        ),
      );
    }
  }

  Future<void> _onContinuePressed() async {
    if (_selectedBranch == null) return;
    setState(() => _isLoading = true);
    try {
      // Call the state API with the selected branch's stateId
      await _apiService.getBranchStateDetails(_selectedBranch!.stateId);
      // Optionally, do something with the states result here
      _proceedToMainApp();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to fetch state details: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // Compact Header
              Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Color(0xFF2C3E50),
                      size: 18,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Branch Selection',
                          style: TextStyle(
                            color: const Color(0xFF2C3E50),
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Choose your workspace',
                          style: TextStyle(
                            color: const Color(0xFF7F8C8D),
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Compact Welcome Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [const Color(0xFF3498DB), const Color(0xFF2980B9)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3498DB).withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person,
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
                            'Welcome back!',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.loginDetails.emplName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Compact Branch Selection
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
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
                            color: const Color(0xFF3498DB).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.business,
                            color: Color(0xFF3498DB),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Available Branches',
                          style: TextStyle(
                            color: const Color(0xFF2C3E50),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    if (_isLoading)
                      Container(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  const Color(0xFF3498DB),
                                ),
                                strokeWidth: 2,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Loading branches...',
                              style: TextStyle(
                                color: const Color(0xFF7F8C8D),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE74C3C).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFE74C3C).withOpacity(0.2),
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: const Color(0xFFE74C3C),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Connection Error',
                                  style: TextStyle(
                                    color: const Color(0xFFE74C3C),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _errorMessage!,
                              style: TextStyle(
                                color: const Color(0xFF7F8C8D),
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _fetchBranches,
                                icon: const Icon(Icons.refresh, size: 16),
                                label: const Text('Try Again'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF3498DB),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (_branches.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Icon(
                              Icons.business_outlined,
                              color: const Color(0xFFBDC3C7),
                              size: 40,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No Branches Available',
                              style: TextStyle(
                                color: const Color(0xFF7F8C8D),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Contact your administrator',
                              style: TextStyle(
                                color: const Color(0xFFBDC3C7),
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    else
                      Column(
                        children: [
                          // Compact Dropdown
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8F9FA),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color:
                                    _selectedBranch != null
                                        ? const Color(0xFF3498DB)
                                        : const Color(0xFFE5E7EB),
                                width: 1.5,
                              ),
                            ),
                            child: DropdownButton<Branch>(
                              value: _selectedBranch,
                              isExpanded: true,
                              underline: const SizedBox(),
                              dropdownColor: Colors.white,
                              icon: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF3498DB,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(
                                  Icons.keyboard_arrow_down,
                                  color: Color(0xFF3498DB),
                                  size: 18,
                                ),
                              ),
                              hint: Text(
                                'Select your branch',
                                style: TextStyle(
                                  color: const Color(0xFF9CA3AF),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              style: const TextStyle(
                                color: Color(0xFF2C3E50),
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                              onChanged: (Branch? newValue) {
                                setState(() {
                                  _selectedBranch = newValue;
                                });
                              },
                              items:
                                  _branches.map<DropdownMenuItem<Branch>>((
                                    Branch branch,
                                  ) {
                                    return DropdownMenuItem<Branch>(
                                      value: branch,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 8,
                                          horizontal: 4,
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.business,
                                              color: const Color(0xFF3498DB),
                                              size: 16,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                branch.branchName,
                                                style: const TextStyle(
                                                  color: Color(0xFF2C3E50),
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 14,
                                                ),
                                                overflow: TextOverflow.visible,
                                                maxLines: null,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                            ),
                          ),

                          // Compact Branch Counter
                          if (_branches.isNotEmpty)
                            Container(
                              margin: const EdgeInsets.only(top: 12),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF3498DB).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${_branches.length} branch${_branches.length > 1 ? 'es' : ''} available',
                                style: TextStyle(
                                  color: const Color(0xFF3498DB),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
              ),

              const Spacer(),

              // Compact Continue Button
              if (!_isLoading && _branches.isNotEmpty)
                Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors:
                          _selectedBranch != null
                              ? [
                                const Color(0xFF3498DB),
                                const Color(0xFF2980B9),
                              ]
                              : [
                                const Color(0xFFBDC3C7),
                                const Color(0xFF95A5A6),
                              ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow:
                        _selectedBranch != null
                            ? [
                              BoxShadow(
                                color: const Color(0xFF3498DB).withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ]
                            : null,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap:
                          _selectedBranch != null ? _onContinuePressed : null,
                      borderRadius: BorderRadius.circular(12),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_selectedBranch != null) ...[
                              const Icon(
                                Icons.arrow_forward,
                                color: Colors.white,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                            ],
                            Text(
                              _selectedBranch != null
                                  ? 'Continue to App'
                                  : 'Select Branch',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
