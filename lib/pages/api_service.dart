import 'dart:convert';
import 'package:http/http.dart' as http;
import 'location.dart';
import 'dealer.dart';
import 'month.dart';
import 'state.dart';

class LoginDetails {
  final String id;
  final String userName;
  final String brnchName;
  final String emplName;
  final String stateName;
  final int brnchId;
  final int stateId;
  final bool isAdmin;

  LoginDetails({
    required this.id,
    required this.userName,
    required this.brnchName,
    required this.emplName,
    required this.stateName,
    required this.brnchId,
    required this.stateId,
    this.isAdmin = false,
  });

  factory LoginDetails.fromJson(Map<String, dynamic> json) {
    final userName = json['UserName'] as String;
    final isAdmin = userName.toLowerCase() == 'admin';
    
    return LoginDetails(
      id: json['Id'] as String,
      userName: userName,
      brnchName: json['BrnchName'] as String,
      emplName: json['EmplName'] as String,
      stateName: json['StateName'] as String,
      brnchId: json['BrnchId'] as int,
      stateId: json['StateId'] as int,
      isAdmin: isAdmin,
    );
  }
}

class CollectionTarget {
  final String cateCode;
  final String cateName;
  final String catePName;
  final String catePHN3;
  final String cateEmail;
  final double hamt1;
  final double hamt2;
  final int cateId;
  final int tgtPlnMId;

  CollectionTarget({
    required this.cateCode,
    required this.cateName,
    required this.catePName,
    required this.catePHN3,
    required this.cateEmail,
    required this.hamt1,
    required this.hamt2,
    required this.cateId,
    required this.tgtPlnMId,
  });

  factory CollectionTarget.fromJson(Map<String, dynamic> json) {
    return CollectionTarget(
      cateCode: json['CATECODE'] ?? '',
      cateName: json['CATENAME'] ?? '',
      catePName: json['CATEPNAME'] ?? '',
      catePHN3: json['CATEPHN3'] ?? '',
      cateEmail: json['CATEMAIL'] ?? '',
      hamt1: (json['HAMT1'] ?? 0.0).toDouble(),
      hamt2: (json['HAMT2'] ?? 0.0).toDouble(),
      cateId: json['CATEID'] ?? 0,
      tgtPlnMId: json['TGTPLNMID'] ?? 0,
    );
  }
}

class ApiService {
  final String _baseUrl = 'http://fusiontecsoftware.com/shefawebapi/shefaapi';
  final String _saveCollectionUrl = 'https://fusiontecsoftware.com/shefawebapi/api/dealeroutstanding/save';
  final bool _debugMode = true;

  void _log(String message, {bool isError = false}) {
    if (_debugMode) {
      final prefix = isError ? '🔴 ERROR: ' : '🔵 DEBUG: ';
      print('$prefix$message');
    }
  }

  Future<LoginDetails?> login(String username, String password) async {
    final url = '$_baseUrl/employeeloginDetails?ids=$username~$password';
    _log('Login Request: $url');

    try {
      final response = await http.get(Uri.parse(url));
      _log('Login Response (${response.statusCode}): ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['myRoot'] != null && data['myRoot'] is List && data['myRoot'].isNotEmpty) {
          final loginDetails = LoginDetails.fromJson(data['myRoot'][0]);
          _log('''
Parsed Login Details:
  - ID: ${loginDetails.id}
  - Username: ${loginDetails.userName}
  - Branch: ${loginDetails.brnchName} (ID: ${loginDetails.brnchId})
  - Employee: ${loginDetails.emplName}
  - State: ${loginDetails.stateName} (ID: ${loginDetails.stateId})
  - Is Admin: ${loginDetails.isAdmin}
''');
          return loginDetails;
        }
        return null;
      } else {
        throw Exception('Failed to login. Status code: ${response.statusCode}');
      }
    } catch (e) {
      _log('Login Error: $e', isError: true);
      rethrow;
    }
  }

  Future<List<Month>> getMonthDetails() async {
    final url = '$_baseUrl/monthDetails';
    _log('Month Details Request: $url');

    try {
      final response = await http.get(Uri.parse(url));
      _log('Month Details Response (${response.statusCode}): ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['myRoot'] != null && data['myRoot'] is List) {
          final months = (data['myRoot'] as List).map((month) => Month.fromJson(month)).toList();
          _log('Found ${months.length} months');
          return months;
        }
        return [];
      } else {
        throw Exception('Failed to load month details');
      }
    } catch (e) {
      _log('Month Details Error: $e', isError: true);
      rethrow;
    }
  }

  Future<List<State>> getAllStatesForAdmin(String username) async {
    final url = '$_baseUrl/loginstateDetails?ids=$username~5';
    _log('All States for Admin Request: $url');

    try {
      final response = await http.get(Uri.parse(url));
      _log('All States for Admin Response (${response.statusCode}): ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['myRoot'] != null && data['myRoot'] is List) {
          final states = (data['myRoot'] as List).map((state) => State.fromJson(state)).toList();
          _log('Found ${states.length} states for admin user $username');
          return states;
        }
        return [];
      } else {
        throw Exception('Failed to load all states for admin');
      }
    } catch (e) {
      _log('All States for Admin Error: $e', isError: true);
      rethrow;
    }
  }

  Future<List<Location>> getLocationDetails(int stateId) async {
    final url = '$_baseUrl/locationdetails?id=$stateId';
    _log('Location Details Request: $url');

    try {
      final response = await http.get(Uri.parse(url));
      _log('Location Details Response (${response.statusCode}): ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['myRoot'] != null && data['myRoot'] is List) {
          final locations = (data['myRoot'] as List).map((loc) => Location.fromJson(loc)).toList();
          _log('Found ${locations.length} locations for state $stateId');
          return locations;
        }
        return [];
      } else {
        throw Exception('Failed to load location details');
      }
    } catch (e) {
      _log('Location Details Error: $e', isError: true);
      rethrow;
    }
  }

  Future<List<Dealer>> getDealerListDetails(String locationId, String categoryId, String monthId) async {
    final url = '$_baseUrl/dealerlistDetails?ids=$locationId~$categoryId~$monthId';
    _log('Dealer List Request: $url');

    try {
      final response = await http.get(Uri.parse(url));
      _log('Dealer List Response (${response.statusCode}): ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['myRoot'] != null && data['myRoot'] is List) {
          final dealers = (data['myRoot'] as List).map<Dealer>((dealerJson) => Dealer.fromJson(dealerJson)).toList();
          _log('Found ${dealers.length} dealers');
          return dealers;
        } else {
          _log('No dealers found or invalid response format');
          return [];
        }
      } else {
        throw Exception('Failed to load dealer list. Status code: ${response.statusCode}');
      }
    } catch (e) {
      _log('Dealer List Error: $e', isError: true);
      rethrow;
    }
  }

  Future<List<CollectionTarget>> getCollectionTargetListDetails(
      String userName, int branchId, int monthId, int stateId) async {
    final url = '$_baseUrl/collectiontargetlistDetails?ids=$userName~$branchId~$monthId~$stateId';
    _log('Collection Targets Request: $url');

    try {
      final response = await http.get(Uri.parse(url));
      _log('Collection Targets Response (${response.statusCode}): ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['myRoot'] != null && data['myRoot'] is List) {
          final targets = (data['myRoot'] as List)
              .map((target) => CollectionTarget.fromJson(target))
              .toList();
          
          _log('''
Found ${targets.length} collection targets:
${targets.map((t) => '''
  - ${t.cateName} (${t.cateCode})
    Contact: ${t.catePName} | ${t.catePHN3} | ${t.cateEmail}
    Target: ₹${t.hamt1} | Collected: ₹${t.hamt2}
    IDs: CateID=${t.cateId} | TgtPlnMId=${t.tgtPlnMId}
    ---------------------------------''').join('\n')}
''');
          return targets;
        }
        return [];
      } else {
        throw Exception('Failed to load collection target details. Status code: ${response.statusCode}');
      }
    } catch (e) {
      _log('Collection Targets Error: $e', isError: true);
      rethrow;
    }
  }

  Future<dynamic> getDealerOutstandingDetails(String cateId, int branchId) async {
    final url = Uri.parse('$_baseUrl/dealeroutstandingDetails?ids=$cateId~$branchId');
    _log('Dealer Outstanding Request: $url');

    try {
      final response = await http.get(url);
      _log('Dealer Outstanding Response (${response.statusCode}): ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _log('Dealer Outstanding Data: $data');
        return data;
      } else {
        throw Exception('Failed to load dealer outstanding details');
      }
    } catch (e) {
      _log('Dealer Outstanding Error: $e', isError: true);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> saveCollectionPlan(Map<String, dynamic> data) async {
    final url = Uri.parse(_saveCollectionUrl);
    _log('Save Collection Plan Request: $url\nData: ${jsonEncode(data)}');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      _log('Save Collection Plan Response (${response.statusCode}): ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        // Additional check for success message in response
        if (responseData['Message']?.toString().toLowerCase().contains('success') ?? false) {
          _log('Collection plan saved successfully: $responseData');
          return responseData;
        } else {
          throw Exception('API returned success status but indicated failure: ${responseData['Message']}');
        }
      } else {
        // Parse error message if available
        final errorMessage = _parseErrorMessage(response);
        throw Exception('Failed to save collection plan: $errorMessage');
      }
    } catch (e) {
      _log('Error saving collection plan: $e', isError: true);
      throw Exception('Failed to save collection plan: ${e.toString()}');
    }
  }

  String _parseErrorMessage(http.Response response) {
    try {
      final responseData = jsonDecode(response.body);
      return responseData['Message'] ?? response.body;
    } catch (e) {
      return 'Status code: ${response.statusCode}';
    }
  }
}