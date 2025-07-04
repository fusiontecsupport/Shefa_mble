import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class ViewTargetActualScreen extends StatefulWidget {
  final int tgtplnMid;

  const ViewTargetActualScreen({super.key, required this.tgtplnMid});

  @override
  State<ViewTargetActualScreen> createState() => _ViewTargetActualScreenState();
}

class _ViewTargetActualScreenState extends State<ViewTargetActualScreen> {
  bool _isLoading = true;
  List<dynamic> _transactions = [];
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    fetchTransactionDetails();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> fetchTransactionDetails() async {
    final url = Uri.parse(
        'https://fusiontecsoftware.com/shefawebapi/shefaapi/collectiontargeteditDetails?id=${widget.tgtplnMid}');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        setState(() {
          _transactions = jsonData['myRoot'] ?? [];
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load transactions');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $e')),
      );
    }
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            '📊 Target vs Actual',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Track collection performance visually',
            style: TextStyle(
              fontSize: 15,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> txn, int index) {
    final date = DateTime.parse(txn['TRANDATE']);
    final formattedDate = DateFormat('dd MMM yyyy').format(date);

    return AnimatedContainer(
      duration: Duration(milliseconds: 300 + index * 40),
      curve: Curves.easeOut,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow("Transaction No.", '#${txn['TRANDNO']}', bold: true),
            _buildInfoRow("Date", formattedDate),
            _buildDivider(),
            _buildInfoRow("Amount", '₹${txn['TRANNAMT']}', highlight: true),
            _buildInfoRow("Total Amount", '₹${txn['TRANPAMT']}'),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _buildHalfBlock('1st Half', txn['TRANHAMT1'], txn['TRANAAMT1'], Colors.blue)),
                const SizedBox(width: 10),
                Expanded(child: _buildHalfBlock('2nd Half', txn['TRANHAMT2'], txn['TRANAAMT2'], Colors.orange)),
              ],
            ),
            const SizedBox(height: 12),
            _buildDivider(),
            _buildInfoRow('Overdue Days', '${txn['TRANODAYS']}'),
            _buildInfoRow('User ID', txn['CUSRID']),
          ],
        ),
      ),
    );
  }

  Widget _buildHalfBlock(String title, dynamic plan, dynamic actual, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: color.withOpacity(0.05),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text("Plan: ₹$plan", style: const TextStyle(color: Colors.black87)),
          Text("Actual: ₹$actual", style: const TextStyle(color: Colors.black)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool bold = false, bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.black54,
                fontSize: 14,
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: highlight ? Colors.green : Colors.black87,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(color: Colors.black12, height: 20, thickness: 1);
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(CupertinoIcons.cube_box, size: 80, color: Colors.grey),
            SizedBox(height: 20),
            Text("No data available", style: TextStyle(color: Colors.black45, fontSize: 18)),
            SizedBox(height: 8),
            Text("Please try again later or refresh.", style: TextStyle(color: Colors.black38)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.6,
        title: const Text(
          "📈 Target vs Actual",
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.black87),
            onPressed: fetchTransactionDetails,
          ),
        ],
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _transactions.isEmpty
              ? _buildEmptyState()
              : CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    SliverToBoxAdapter(child: _buildHeader()),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _buildTransactionCard(_transactions[index], index),
                        childCount: _transactions.length,
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 40)),
                  ],
                ),
      floatingActionButton: _transactions.isNotEmpty
          ? FloatingActionButton(
              onPressed: () {
                _scrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOut,
                );
              },
              backgroundColor: Colors.black87,
              child: const Icon(Icons.arrow_upward_rounded, color: Colors.white),
            )
          : null,
    );
  }
}
