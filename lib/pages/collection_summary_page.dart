import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'Dealer.dart';

class CollectionSummaryPage extends StatelessWidget {
  final Dealer selectedDealer;
  final List<Map<String, dynamic>> dealerOutstandingList;
  final List<String> firstHalfAmounts;
  final List<String> secondHalfAmounts;

  const CollectionSummaryPage({
    super.key,
    required this.selectedDealer,
    required this.dealerOutstandingList,
    required this.firstHalfAmounts,
    required this.secondHalfAmounts,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Collection Plan Summary'),
        backgroundColor: Colors.teal.shade600,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDealerInfo(),
            const SizedBox(height: 20),
            _buildOutstandingList(),
            const SizedBox(height: 20),
            _buildJsonButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDealerInfo() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dealer Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.teal.shade700,
              ),
            ),
            const Divider(),
            _buildInfoRow('CateId', selectedDealer.cateId.toString()),
            _buildInfoRow('Dealer Name', selectedDealer.cateName),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildOutstandingList() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Outstanding Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.teal.shade700,
              ),
            ),
            const Divider(),
            ...List.generate(dealerOutstandingList.length, (index) {
              final item = dealerOutstandingList[index];
              final autoTrandno = 'KA/24-25/${1441 + index}';

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('TRANMID', item['TRANMID']?.toString() ?? ''),
                  _buildInfoRow('TRANDNO', autoTrandno),
                  _buildInfoRow('TRANDATE', item['TRANDATE']?.toString() ?? ''),
                  _buildInfoRow(
                    'Amount (₹)',
                    (item['TRANNAMT'] is double)
                        ? (item['TRANNAMT'] as double).toInt().toString()
                        : item['TRANNAMT']?.toString() ?? '0',
                  ),
                  _buildInfoRow('Overdue Days', item['OverDueDays']?.toString() ?? '0'),
                  _buildInfoRow('First Half Amount', firstHalfAmounts[index]),
                  _buildInfoRow('Second Half Amount', secondHalfAmounts[index]),
                  if (index != dealerOutstandingList.length - 1) const Divider(),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildJsonButtons(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () {
            final jsonData = _generateJsonData();
            _showJsonDialog(context, jsonData);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal.shade600,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: const Text('View JSON Data'),
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: () {
            final jsonString = getJsonString();
            Clipboard.setData(ClipboardData(text: jsonString));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('JSON copied to clipboard')),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange.shade600,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: const Text('Copy JSON'),
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: () => sendJsonData(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green.shade600,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: const Text('Send'),
        ),
      ],
    );
  }

  Map<String, dynamic> _generateJsonData() {
    return {
      'dealer': {
        'cateId': selectedDealer.cateId,
        'cateName': selectedDealer.cateName,
      },
      'outstandingDetails': List.generate(dealerOutstandingList.length, (index) {
        final item = dealerOutstandingList[index];
        final autoTrandno = 'KA/24-25/${1441 + index}';

        return {
          'TRANMID': item['TRANMID'],
          'TRANDNO': autoTrandno,
          'TRANDATE': item['TRANDATE'] is DateTime
              ? item['TRANDATE'].toIso8601String()
              : item['TRANDATE'].toString(),
          'TRANNAMT': (item['TRANNAMT'] is double)
              ? (item['TRANNAMT'] as double).toInt()
              : int.tryParse(item['TRANNAMT'].toString()) ?? 0,
          'TRANODAYS': item['OverDueDays'],
          'firstHalfAmount': int.tryParse(firstHalfAmounts[index].trim()) ?? 0,
          'secondHalfAmount': int.tryParse(secondHalfAmounts[index].trim()) ?? 0,
        };
      }),
    };
  }

  String getJsonString() {
    final jsonData = _generateJsonData();
    return jsonEncode(jsonData);
  }

  void _showJsonDialog(BuildContext context, Map<String, dynamic> jsonData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('JSON Data'),
        content: SingleChildScrollView(
          child: Text(
            const JsonEncoder.withIndent('  ').convert(jsonData),
            style: const TextStyle(fontFamily: 'monospace'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> sendJsonData(BuildContext context) async {
    final url = Uri.parse('https://fusiontecsoftware.com/shefawebapi/api/dealeroutstanding/save');
    final jsonData = _generateJsonData();

    try {
      final jsonString = jsonEncode(jsonData);
      print('Sending JSON:\n$jsonString');

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonString,
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        final message = responseBody['message'] ?? 'Data sent successfully';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Server error: ${response.statusCode}\n${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending data: $e')),
      );
    }
  }
}