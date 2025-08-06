import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class EditClientScreen extends StatefulWidget {
  final int tgtplnMid;

  const EditClientScreen({super.key, required this.tgtplnMid});

  @override
  State<EditClientScreen> createState() => _EditClientScreenState();
}

class _EditClientScreenState extends State<EditClientScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> transactionList = [];

  final List<TextEditingController> _hamt1Controllers = [];
  final List<TextEditingController> _hamt2Controllers = [];
  final List<TextEditingController> _aamt1Controllers = [];
  final List<TextEditingController> _aamt2Controllers = [];
  final List<GlobalKey<FormState>> _formKeys = [];

  @override
  void initState() {
    super.initState();
    fetchEditData();
  }

  @override
  void dispose() {
    for (var controller in _hamt1Controllers) {
      controller.dispose();
    }
    for (var controller in _hamt2Controllers) {
      controller.dispose();
    }
    for (var controller in _aamt1Controllers) {
      controller.dispose();
    }
    for (var controller in _aamt2Controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> fetchEditData() async {
    final url = Uri.parse(
      'https://fusiontecsoftware.com/shefawebapi/shefaapi/collectiontargeteditDetails?id=${widget.tgtplnMid}',
    );
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final List<dynamic> data = decoded['myRoot'] ?? [];

        final List<Map<String, dynamic>> tempList =
            List<Map<String, dynamic>>.from(data);

        // Dispose existing controllers before clearing lists
        for (var controller in _hamt1Controllers) {
          controller.dispose();
        }
        for (var controller in _hamt2Controllers) {
          controller.dispose();
        }
        for (var controller in _aamt1Controllers) {
          controller.dispose();
        }
        for (var controller in _aamt2Controllers) {
          controller.dispose();
        }

        _hamt1Controllers.clear();
        _hamt2Controllers.clear();
        _aamt1Controllers.clear();
        _aamt2Controllers.clear();
        _formKeys.clear();

        for (var item in tempList) {
          _hamt1Controllers.add(
            TextEditingController(text: item['TRANHAMT1'].toString()),
          );
          _hamt2Controllers.add(
            TextEditingController(text: item['TRANHAMT2'].toString()),
          );
          _aamt1Controllers.add(
            TextEditingController(text: item['TRANAAMT1'].toString()),
          );
          _aamt2Controllers.add(
            TextEditingController(text: item['TRANAAMT2'].toString()),
          );
          _formKeys.add(GlobalKey<FormState>());
        }

        setState(() {
          transactionList = tempList;
          _isLoading = false;
        });
      } else {
        throw Exception(
          "Failed to load edit data. Status code: ${response.statusCode}",
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching data: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  String formatDate(String date) {
    try {
      final dateTime = DateTime.parse(date);
      return "${dateTime.day.toString().padLeft(2, '0')}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.year}";
    } catch (_) {
      return date;
    }
  }

  Future<void> saveEditedData() async {
    // Validate all forms first
    bool allValid = true;
    for (int i = 0; i < _formKeys.length; i++) {
      if (!_formKeys[i].currentState!.validate()) {
        allValid = false;
        // Scroll to the first error
        Scrollable.ensureVisible(
          _formKeys[i].currentContext!,
          duration: const Duration(milliseconds: 300),
        );
        break;
      }
    }

    if (!allValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fix all validation errors before saving.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final List<Map<String, dynamic>> updateData = [];

      for (int i = 0; i < transactionList.length; i++) {
        updateData.add({
          'TGTPLNDID': transactionList[i]['TGTPLNDID'],
          'TRANHAMT1': double.tryParse(_hamt1Controllers[i].text) ?? 0,
          'TRANHAMT2': double.tryParse(_hamt2Controllers[i].text) ?? 0,
          'TRANAAMT1': double.tryParse(_aamt1Controllers[i].text) ?? 0,
          'TRANAAMT2': double.tryParse(_aamt2Controllers[i].text) ?? 0,
          'CUSRID': transactionList[i]['CUSRID'] ?? 'admin',
        });
      }

      final requestBody = {'updatecollectionDetails': updateData};

      final url = Uri.parse(
        'https://fusiontecsoftware.com/shefawebapi/api/collectiontargetupdate/update',
      );
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Changes saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      } else {
        throw Exception(
          "Failed to save data. Status code: ${response.statusCode}",
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving data: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildEditableField(
    String label,
    TextEditingController controller, {
    double? tranNAmt,
    TextEditingController? otherController,
    required int index,
    bool isActualField = false,
    TextEditingController? actualOtherController,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 4),
          TextFormField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              prefixText: '₹ ',
              prefixStyle: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.blue, width: 1.0),
              ),
            ),
            validator: (value) {
              if (tranNAmt != null && otherController != null) {
                final val1 = double.tryParse(controller.text) ?? 0;
                final val2 = double.tryParse(otherController.text) ?? 0;
                if (val1 + val2 > tranNAmt) {
                  return 'Sum exceeds total amount (₹$tranNAmt)';
                }
              }

              // Additional validation for actual amounts
              if (isActualField && actualOtherController != null) {
                final actual1 = double.tryParse(controller.text) ?? 0;
                final actual2 =
                    double.tryParse(actualOtherController.text) ?? 0;
                if (actual1 + actual2 > tranNAmt!) {
                  return 'Actual sum exceeds net amount (₹$tranNAmt)';
                }
              }
              return null;
            },
            onChanged: (value) {
              if (tranNAmt != null && otherController != null) {
                _formKeys[index].currentState?.validate();
              }
              if (isActualField && actualOtherController != null) {
                _formKeys[index].currentState?.validate();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String title, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: valueColor ?? Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(int index) {
    final item = transactionList[index];
    final colors = [
      Colors.blue.shade600,
      Colors.green.shade600,
      Colors.purple.shade600,
      Colors.orange.shade600,
      Colors.teal.shade600,
    ];
    final cardColor = colors[index % colors.length];
    final tranNAmt = double.tryParse(item['TRANNAMT'].toString()) ?? 0;

    return Form(
      key: _formKeys[index],
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header with gradient
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [cardColor, cardColor.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Transaction ${item['TRANDNO']}",
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      formatDate(item['TRANDATE']),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  // Summary row
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: cardColor.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        _buildInfoRow(
                          "Net Amount",
                          '₹$tranNAmt',
                          valueColor: Colors.green.shade700,
                        ),
                        _buildInfoRow(
                          "Pending Amount",
                          '₹${item['TRANPAMT']}',
                          valueColor: Colors.blue.shade700,
                        ),
                        _buildInfoRow(
                          "Due Days",
                          '${item['TRANODAYS']} days',
                          valueColor: Colors.orange.shade700,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Editable fields in a compact grid
                  Row(
                    children: [
                      Expanded(
                        child: _buildEditableField(
                          "Plan 1st Half",
                          _hamt1Controllers[index],
                          tranNAmt: tranNAmt,
                          otherController: _hamt2Controllers[index],
                          index: index,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildEditableField(
                          "Plan 2nd Half",
                          _hamt2Controllers[index],
                          tranNAmt: tranNAmt,
                          otherController: _hamt1Controllers[index],
                          index: index,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _buildEditableField(
                          "Actual 1st Half",
                          _aamt1Controllers[index],
                          tranNAmt: tranNAmt,
                          index: index,
                          isActualField: true,
                          actualOtherController: _aamt2Controllers[index],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildEditableField(
                          "Actual 2nd Half",
                          _aamt2Controllers[index],
                          tranNAmt: tranNAmt,
                          index: index,
                          isActualField: true,
                          actualOtherController: _aamt1Controllers[index],
                        ),
                      ),
                    ],
                  ),

                  // Created by info
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        "Updated by ${item['CUSRID']}",
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[500],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "Edit Collection Plan",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.blue.shade700, Colors.blue.shade500],
            ),
          ),
        ),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (!_isLoading && transactionList.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.save, color: Colors.white),
              onPressed: saveEditedData,
            ),
        ],
      ),
      body:
          _isLoading
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.blue.shade700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Loading collection data...",
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                  ],
                ),
              )
              : transactionList.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.receipt_long, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      "No collection plan data found",
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  ],
                ),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    ...List.generate(
                      transactionList.length,
                      (index) => _buildTransactionCard(index),
                    ),
                    const SizedBox(height: 12),
                    if (transactionList.isNotEmpty)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : saveEditedData,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade700,
                            foregroundColor: Colors.white,
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon:
                              _isLoading
                                  ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                  : const Icon(Icons.save_alt, size: 20),
                          label: Text(
                            _isLoading ? "SAVING..." : "SAVE ALL CHANGES",
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
    );
  }
}
