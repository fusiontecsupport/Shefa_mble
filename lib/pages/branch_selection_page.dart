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
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/bg.jpg', fit: BoxFit.cover),
          Container(color: Colors.black.withOpacity(0.3)),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Header
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'Select Branch',
                            style: Theme.of(
                              context,
                            ).textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    // Welcome message
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.white.withOpacity(0.2),
                            child: Icon(
                              Icons.person,
                              size: 40,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Welcome,  {widget.loginDetails.emplName}!',
                            style: Theme.of(
                              context,
                            ).textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Please select your branch to continue',
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(color: Colors.white70),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Branch selection
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.business,
                                color: Colors.white,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Available Branches',
                                style: Theme.of(
                                  context,
                                ).textTheme.titleLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          if (_isLoading)
                            const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          else if (_errorMessage != null)
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: Colors.red,
                                  size: 48,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Error',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(color: Colors.red),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _errorMessage!,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(color: Colors.white70),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _fetchBranches,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.deepPurple,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text('Retry'),
                                ),
                              ],
                            )
                          else if (_branches.isEmpty)
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.business_outlined,
                                  color: Colors.white70,
                                  size: 48,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No branches available',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Please contact your administrator',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(color: Colors.white70),
                                ),
                              ],
                            )
                          else
                            Column(
                              children: [
                                // Debug info
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.blue.withOpacity(0.5),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Debug Info:',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.labelSmall?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'Found ${_branches.length} branches',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(color: Colors.white70),
                                      ),
                                      if (_selectedBranch != null)
                                        Text(
                                          'Selected: ${_selectedBranch!.branchName}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(color: Colors.white70),
                                        ),
                                    ],
                                  ),
                                ),
                                // Branch dropdown
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.3),
                                    ),
                                  ),
                                  child: DropdownButton<Branch>(
                                    value: _selectedBranch,
                                    isExpanded: true,
                                    underline: const SizedBox(),
                                    dropdownColor: Colors.deepPurple,
                                    icon: const Icon(
                                      Icons.arrow_drop_down,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                    hint: Text(
                                      'Select a branch',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    onChanged: (Branch? newValue) {
                                      setState(() {
                                        _selectedBranch = newValue;
                                      });
                                    },
                                    items:
                                        _branches.map<DropdownMenuItem<Branch>>(
                                          (Branch branch) {
                                            return DropdownMenuItem<Branch>(
                                              value: branch,
                                              child: Text(
                                                branch.branchName,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            );
                                          },
                                        ).toList(),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Continue button
                    if (!_isLoading && _branches.isNotEmpty)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed:
                              _selectedBranch != null
                                  ? _onContinuePressed
                                  : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Continue',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
