import 'dart:convert';
import 'dart:math';
import 'package:acex/auth_page.dart';
import 'package:acex/landing_page.dart';
import 'package:acex/models/user.dart';
import 'package:acex/providers/user_provider.dart';
import 'package:acex/utils/constant.dart';
import 'package:acex/utils/secure_storage.dart';
import 'package:acex/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;

class ProblemDetails {
  final String title;
  final String statement;
  final String inputSpec;
  final String outputSpec;
  final List<Map<String, String>> examples;

  ProblemDetails({
    required this.title,
    required this.statement,
    required this.inputSpec,
    required this.outputSpec,
    required this.examples,
  });
}

class Club {
  final String id;
  final String name;
  final String description;
  final String createdBy;
  final DateTime createdAt;
  final String? bannerUrl;
  final String? avatarUrl;
  final List<String> members;
  final List<String> memberHandles;
  final List<String> admins;
  final int memberCount;
  final bool isPublic;

  Club({
    required this.id,
    required this.name,
    required this.description,
    required this.createdBy,
    required this.createdAt,
    this.bannerUrl,
    this.avatarUrl,
    required this.members,
    required this.memberHandles,
    required this.admins,
    required this.memberCount,
    required this.isPublic,
  });

  factory Club.fromJson(Map<String, dynamic> json) {
    DateTime parseCreatedAt(dynamic createdAt) {
      if (createdAt == null) return DateTime.now();
      if (createdAt is DateTime) return createdAt;
      if (createdAt is Map<String, dynamic>) {
        // Handle Firestore timestamp format
        if (createdAt.containsKey('_seconds')) {
          return DateTime.fromMillisecondsSinceEpoch(
              createdAt['_seconds'] * 1000 +
                  (createdAt['_nanoseconds'] ~/ 1000000));
        }
      }
      // Try parsing string format as fallback
      try {
        return DateTime.parse(createdAt.toString());
      } catch (e) {
        return DateTime.now();
      }
    }

    return Club(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      createdBy: json['createdBy'] ?? '',
      createdAt: parseCreatedAt(json['createdAt']),
      bannerUrl: json['bannerUrl'],
      avatarUrl: json['avatarUrl'],
      members: List<String>.from(json['members'] ?? []),
      memberHandles: List<String>.from(json['memberHandles'] ?? []),
      admins: List<String>.from(json['admins'] ?? []),
      memberCount: json['memberCount'] ?? 0,
      isPublic: json['isPublic'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'bannerUrl': bannerUrl,
      'avatarUrl': avatarUrl,
      'members': members,
      'memberHandles': memberHandles,
      'admins': admins,
      'memberCount': memberCount,
      'isPublic': isPublic,
    };
  }
}

class ClubDiscussion {
  final String id;
  final String clubId;
  final String title;
  final String content;
  final String authorId;
  final String authorName;
  final DateTime createdAt;
  final int commentCount;
  final int likeCount;

  ClubDiscussion({
    required this.id,
    required this.clubId,
    required this.title,
    required this.content,
    required this.authorId,
    required this.authorName,
    required this.createdAt,
    required this.commentCount,
    required this.likeCount,
  });

  factory ClubDiscussion.fromJson(Map<String, dynamic> json) {
    DateTime parseCreatedAt(dynamic createdAt) {
      if (createdAt == null) return DateTime.now();
      if (createdAt is DateTime) return createdAt;
      if (createdAt is Map<String, dynamic>) {
        // Handle Firestore timestamp format
        if (createdAt.containsKey('_seconds')) {
          return DateTime.fromMillisecondsSinceEpoch(
              createdAt['_seconds'] * 1000 +
                  (createdAt['_nanoseconds'] ~/ 1000000));
        }
      }
      // Try parsing string format as fallback
      try {
        return DateTime.parse(createdAt.toString());
      } catch (e) {
        return DateTime.now();
      }
    }

    return ClubDiscussion(
      id: json['id'] ?? '',
      clubId: json['clubId'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      authorId: json['authorId'] ?? '',
      authorName: json['authorName'] ?? '',
      createdAt: parseCreatedAt(json['createdAt']),
      commentCount: json['commentCount'] ?? 0,
      likeCount: json['likeCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clubId': clubId,
      'title': title,
      'content': content,
      'authorId': authorId,
      'authorName': authorName,
      'createdAt': createdAt.toIso8601String(),
      'commentCount': commentCount,
      'likeCount': likeCount,
    };
  }
}

class ClubProblem {
  final String id;
  final String clubId;
  final String title;
  final String description;
  final String difficulty;
  final int points;
  final String authorId;
  final DateTime createdAt;
  final int solvedCount;

  ClubProblem({
    required this.id,
    required this.clubId,
    required this.title,
    required this.description,
    required this.difficulty,
    required this.points,
    required this.authorId,
    required this.createdAt,
    required this.solvedCount,
  });

  factory ClubProblem.fromJson(Map<String, dynamic> json) {
    DateTime parseCreatedAt(dynamic createdAt) {
      if (createdAt == null) return DateTime.now();
      if (createdAt is DateTime) return createdAt;
      if (createdAt is Map<String, dynamic>) {
        // Handle Firestore timestamp format
        if (createdAt.containsKey('_seconds')) {
          return DateTime.fromMillisecondsSinceEpoch(
              createdAt['_seconds'] * 1000 +
                  (createdAt['_nanoseconds'] ~/ 1000000));
        }
      }
      // Try parsing string format as fallback
      try {
        return DateTime.parse(createdAt.toString());
      } catch (e) {
        return DateTime.now();
      }
    }

    return ClubProblem(
      id: json['id'] ?? '',
      clubId: json['clubId'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      difficulty: json['difficulty'] ?? 'medium',
      points: json['points'] ?? 100,
      authorId: json['authorId'] ?? '',
      createdAt: parseCreatedAt(json['createdAt']),
      solvedCount: json['solvedCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clubId': clubId,
      'title': title,
      'description': description,
      'difficulty': difficulty,
      'points': points,
      'authorId': authorId,
      'createdAt': createdAt.toIso8601String(),
      'solvedCount': solvedCount,
    };
  }
}

class AuthService {
  void signUpUser({
    required BuildContext context,
    required String email,
    required String handle,
    Function? onSuccess,
  }) async {
    try {
      User user = User(
        id: '',
        handle: handle,
        email: email,
        token: '',
      );
      http.Response res = await http.post(
        Uri.parse('${Constants.uri}/api/signup'),
        body: user.toJson(),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );
      httpErrorHandle(
        response: res,
        context: context,
        onSuccess: () {
          showAlert(
            context,
            'Success',
            'Account created! Login with the same credentials!',
          );
        },
      );
    } catch (e) {
      showAlert(context, 'Error', e.toString());
    } finally {
      if (onSuccess != null) {
        onSuccess();
      }
    }
  }

  void signInUser({
    required BuildContext context,
    required String handle,
    Function? onSuccess,
  }) async {
    try {
      var userProvider = Provider.of<UserProvider>(context, listen: false);
      final navigator = Navigator.of(context);

      http.Response res = await http.post(
        Uri.parse('${Constants.uri}/api/signin'),
        body: jsonEncode({
          'handle': handle,
        }),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );
      print(res.body);
      httpErrorHandle(
        response: res,
        context: context,
        onSuccess: () async {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          var userData = jsonDecode(res.body);
          userProvider.setUser(res.body);
          print('This is the token: ${userData['token']}');
          await prefs.setString('x-auth-token', userData['token']);
          // Update user ID in provider
          if (userData['id'] != null) {
            userProvider.user.id = userData['id'];
          }
          navigator.pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => const LandingPage(),
            ),
            (route) => false,
          );
        },
      );
    } catch (e) {
      print(e.toString());
      showAlert(
          context, 'Error', "Some error occured, please try again later.");
    } finally {
      if (onSuccess != null) {
        onSuccess();
      }
    }
  }

  Future<void> getUserData(
    BuildContext context,
  ) async {
    try {
      var userProvider = Provider.of<UserProvider>(context, listen: false);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String token = prefs.getString('x-auth-token')?? "";

      if (token.isEmpty) return;

      var tokenRes = await http.post(
        Uri.parse('${Constants.uri}/tokenIsValid'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'x-auth-token': token,
        },
      );
      var response = jsonDecode(tokenRes.body);

      if (response == true) {
        http.Response userRes = await http.get(
          Uri.parse('${Constants.uri}/'),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
            'x-auth-token': token
          },
        );

        userProvider.setUser(userRes.body);
      }
    } catch (e) {
      print(e);
      showAlert(
          context, 'Error', "Some error occured, please try again later.");
    }
  }

  void signOut(BuildContext context) async {
    final navigator = Navigator.of(context);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('x-auth-token', '');
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => const AuthPage(),
      ),
      (route) => false,
    );
  }

  Future<bool> sendVerificationCode({
    required String email,
    required BuildContext context,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${Constants.uri}/api/verify-email'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && (data['success'] ?? true)) {
        showAlert(
          context,
          'Success',
          'Verification code sent to your email!',
        );
        return true;
      } else {
        showAlert(context, 'Error',
            data['msg'] ?? 'Failed to send verification code');
        return false;
      }
    } catch (e) {
      showAlert(context, 'Error', 'An error occurred. Please try again.');
      return false;
    }
  }

  // Add this to AuthService
  Future<bool> validateAuthCode({
    required String email,
    required String code,
    required BuildContext context,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('${Constants.uri}/api/validate-auth-code'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({'email': email, 'verificationCode': code}),
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data['success'] == true) {
        return true;
      } else {
        showAlert(context, 'Error', data['msg'] ?? 'Invalid code');
        return false;
      }
    } catch (e) {
      showAlert(context, 'Error', 'Could not validate code. Please try again.');
      return false;
    }
  }
}
class ApiService {
  final String baseUrl =
      'https://codeforces.com/api/'; // Replace with your server's URL if deployed

  Future<ProblemDetails> getProblemDetails(int contestId, String index) async {
    final url = 'https://codeforces.com/problemset/problem/$contestId/$index';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        return _parseProblemHtml(response.body, contestId, index);
      } else {
        throw Exception('Failed to load problem details');
      }
    } catch (e) {
      // Fallback to mock data if web scraping fails
      return ProblemDetails(
        title: 'Problem $contestId$index',
        statement:
            'Given an array a of n positive integers. In one operation, you can pick any pair of indexes (i,j) such that ai and aj have distinct parity, then replace the smaller one with the sum of them. More formally: \n\nIf ai<aj, replace ai with ai+aj; \nOtherwise, replace aj with ai+aj. \n\nFind the minimum number of operations needed to make all elements of the array have the same parity.',
        inputSpec:
            'The first line contains two integers n and m (1 ≤ n, m ≤ 100) — the number of rows and columns in the matrix.',
        outputSpec:
            'Print "YES" (without quotes) if it is possible to make the matrix beautiful, or "NO" (without quotes) otherwise.',
        examples: [
          {
            'input': '3\n2 1 3',
            'output': '1 2 3',
          },
          {
            'input': '5\n1 2 3 5 4',
            'output': '1 2 3 4 5',
          },
        ],
      );
    }
  }

  ProblemDetails _parseProblemHtml(
      String htmlString, int contestId, String index) {
    final document = html_parser.parse(htmlString);

    // Extract problem title
    final titleElement = document.querySelector('.problem-statement .title');
    final title = titleElement?.text ?? 'Problem $contestId$index';

    // Extract problem statement
    final statementElement =
        document.querySelector('.problem-statement > div:nth-child(1)');
    //print(statementElement!.text);
    String statement = '';
    if (statementElement != null) {
      // Process all child nodes to preserve LaTeX
      statement = _processHtmlContent(statementElement);
    }

    // Extract input specification
    final inputSpecElement =
        document.querySelector('.problem-statement > div.input-specification');
    String inputSpec = '';
    if (inputSpecElement != null) {
      inputSpec = _processHtmlContent(inputSpecElement);
    }

    // Extract output specification
    final outputSpecElement =
        document.querySelector('.problem-statement > div.output-specification');
    String outputSpec = '';
    if (outputSpecElement != null) {
      outputSpec = _processHtmlContent(outputSpecElement);
    }

    final sampleWrappers = document.querySelectorAll(
        '.problem-statement > div.sample-tests > div.sample-test');
    List<Map<String, String>> examples = [];

    for (final wrapper in sampleWrappers) {
      // collect all inputs and outputs inside this wrapper
      final inputPres = wrapper.querySelectorAll('div.input > pre');
      final outputPres = wrapper.querySelectorAll('div.output > pre');
      // pair them up
      final count = min(inputPres.length, outputPres.length);
      for (var i = 0; i < count; i++) {
        final ip = inputPres[i];
        final op = outputPres[i];

        // preserve line–breaks in <pre>
        final inputText = ip.children.isEmpty
            ? ip.text.trim()
            : ip.children
                .where((e) => e.localName == 'div')
                .map((d) => d.text.trim())
                .join('\n');
        final outputText = op.children.isEmpty
            ? op.text.trim()
            : op.children
                .where((e) => e.localName == 'div')
                .map((d) => d.text.trim())
                .join('\n');

        examples.add({
          'input': inputText,
          'output': outputText,
        });
      }
    }

    return ProblemDetails(
      title: title,
      statement: statement,
      inputSpec: inputSpec,
      outputSpec: outputSpec,
      examples: examples.isEmpty
          ? [
              {'input': 'Sample Input', 'output': 'Sample Output'}
            ]
          : examples,
    );
  }

  String _processHtmlContent(dom.Element element) {
    final buffer = StringBuffer();
    // Regex to detect math delimiters: $$$…$$$, $$$$…$$$$ (if any), $$…$$, or $…$
    final latexRegex =
        RegExp(r'(\$\$\$.*?\$\$\$|\$\$.*?\$\$|\$.*?\$)', dotAll: true);

    void recurse(dom.Node node) {
      if (node is dom.Text) {
        final text = node.text;
        int last = 0;
        // Split text around LaTeX/math spans and preserve them as-is
        for (final match in latexRegex.allMatches(text)) {
          if (match.start > last) {
            buffer.write(text.substring(last, match.start));
          }
          // Emit the entire match, including delimiters
          buffer.write(match.group(0));
          last = match.end;
        }
        if (last < text.length) {
          buffer.write(text.substring(last));
        }
      } else if (node is dom.Element) {
        switch (node.localName) {
          case 'div':
            if (!node.classes.contains('section-title')) {
              node.nodes.forEach(recurse);
              buffer.write('\n');
            }
            break;
          case 'img':
            final src = node.attributes['src'];
            final alt = node.attributes['alt'] ?? '';
            if (src != null) {
              buffer.write('![$alt]($src)\n');
            }
            break;
          case 'p':
            node.nodes.forEach(recurse);
            buffer.write('\n\n');
            break;
          case 'ul':
          case 'ol':
            for (final li in node.children.where((e) => e.localName == 'li')) {
              recurse(li);
            }
            buffer.write('\n');
            break;
          case 'li':
            // bullet for unordered, number could be added for ordered
            buffer.write('• ');
            node.nodes.forEach(recurse);
            buffer.write('\n');
            break;
          default:
            node.nodes.forEach(recurse);
        }
      }
    }

    // Start recursion
    for (final child in element.nodes) {
      recurse(child);
    }
    return buffer.toString().trim();
  }

  Future<List<dynamic>> getContests() async {
    final response =
        await http.get(Uri.parse('https://codeforces.com/api/contest.list'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'OK') {
        return data['result'];
      } else {
        throw Exception('Failed to load contest details');
      }
    } else {
      throw Exception('Failed to load contest details');
    }
  }

  Future<Map<String, dynamic>> getContestDetails(int contestId) async {
    final response = await http.get(Uri.parse(
        'https://codeforces.com/api/contest.standings?contestId=$contestId'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'OK') {
        return data['result'];
      } else {
        throw Exception('Failed to load contest details');
      }
    } else {
      throw Exception('Failed to load contest details');
    }
  }

  //getContestRatingChanges
  Future<List<dynamic>> getContestRatingChanges(int contestId) async {
    final response = await http.get(Uri.parse(
        'https://codeforces.com/api/contest.ratingChanges?contestId=$contestId'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'OK') {
        return data['result'];
      } else {
        throw Exception('Failed to load contest rating changes');
      }
    } else {
      throw Exception('Failed to load contest rating changes');
    }
  }

  Future<Map<String, dynamic>> getUserStandings(
      int contestId, String handle) async {
    final response = await http.get(Uri.parse(
        'https://codeforces.com/api/contest.standings?contestId=$contestId&handles=$handle'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'OK') {
        return data['result'];
      } else {
        throw Exception('Failed to fetch user standings');
      }
    } else {
      throw Exception('Failed to fetch user standings');
    }
  }

  Future<Map<String, dynamic>> getUserInfo(String handle) async {
    final response = await http
        .get(Uri.parse('https://codeforces.com/api/user.info?handles=$handle'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'OK') {
        return data['result'][0];
      } else {
        throw Exception('Failed to fetch user info');
      }
    } else {
      throw Exception('Failed to fetch user info');
    }
  }

  Future<List<dynamic>> getRatingHistory(String handle) async {
    final response = await http.get(
        Uri.parse('https://codeforces.com/api/user.rating?handle=$handle'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'OK') {
        return data['result'];
      } else {
        throw Exception('Failed to fetch user info 1');
      }
    } else {
      throw Exception('Failed to fetch user info 2');
    }
  }

  Future<List<dynamic>> getSubmissions(String handle) async {
    final response = await http.get(
        Uri.parse('https://codeforces.com/api/user.status?handle=$handle'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'OK') {
        return data['result'];
      } else {
        throw Exception('Failed to fetch user info');
      }
    } else {
      throw Exception('Failed to fetch user info');
    }
  }

  Future<Map<String, dynamic>> getProblemset() async {
    final response = await http
        .get(Uri.parse('https://codeforces.com/api/problemset.problems'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'OK') {
        return data['result'];
      } else {
        throw Exception('Failed to fetch problem set');
      }
    } else {
      throw Exception('Failed to fetch problem set');
    }
  }

  String _generateApiSig(
      int time, String methodName, String paramString, String? apiSecret) {
    // Create random string of 6 characters
    final rand = Random().nextInt(900000) +
        100000; // Generates a number between 100000 and 999999

    // Format: rand/methodName?param1=value1&param2=value2#apiSecret
    final strToHash = '$rand/$methodName?$paramString#$apiSecret';

    // Generate SHA512 hash
    final bytes = utf8.encode(strToHash);
    final hash = sha512.convert(bytes);

    return '$rand${hash.toString()}';
  }

  Future<Map<String, dynamic>> getFriendStandings(
      String handle, int contestId) async {
    String? apiKey = await SecureStorageService.readData('api_key_$handle');
    String? apiSecret = await SecureStorageService.readData('api_secret_$handle');

    const methodName = 'contest.standings';
    final time = (DateTime.now().millisecondsSinceEpoch / 1000).round();
    final friendsInfo = await fetchFriends(handle, false);
    final friendsHandles = friendsInfo.join(';');
    final paramString =
        'apiKey=$apiKey&contestId=$contestId&handles=$handle;$friendsHandles&time=$time';
    final apiSig = _generateApiSig(time, methodName, paramString, apiSecret);
    final url = Uri.parse('$baseUrl$methodName?$paramString&apiSig=$apiSig');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'OK') {
        return data['result'];
      } else {
        throw Exception('Failed to fetch standings');
      }
    } else {
      throw Exception('Failed to fetch standings');
    }
  }

  Future<List<dynamic>> fetchFriends(String handle, bool isOnline) async {
    String? apiKey = await SecureStorageService.readData('api_key_$handle');
    String? apiSecret = await SecureStorageService.readData('api_secret_$handle');
    const methodName = 'user.friends';
    final time = (DateTime.now().millisecondsSinceEpoch / 1000).round();

    // Create parameter string
    final paramString = 'apiKey=$apiKey&onlyOnline=$isOnline&time=$time';

    // Generate API signature
    final apiSig = _generateApiSig(time, methodName, paramString, apiSecret);
    // Construct full URL with authentication
    final url = Uri.parse('$baseUrl$methodName?$paramString&apiSig=$apiSig');
    final response = await http.get(url);
    //print(response.body);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'OK') {
        return data['result'];
      } else {
        throw Exception('Failed to load friends list: ${data['comment']}');
      }
    } else {
      throw Exception('Failed to load friends list');
    }
  }

  Future<List<dynamic>> fetchFriendsInfo(String handle, bool isOnline) async {
    final friendList = await fetchFriends(handle, isOnline);
    String friends = friendList.join(';');
    final response = await http.get(Uri.parse(
        'https://codeforces.com/api/user.info?handles=$handle;$friends'));
    print(response.body);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'OK') {
        return data['result'];
      } else {
        throw Exception('Failed to fetch user info');
      }
    } else {
      throw Exception('Failed to fetch user info');
    }
  }

  Future<List<Map<String, dynamic>>> scrapeSubmissions(String handle, {bool includeFriends = true}) async {
    List<Map<String, dynamic>> allSubmissions = [];
    List<String> handles = [handle];
    
    // If includeFriends is true, get the list of friends
    if (includeFriends) {
      final friendsList = await fetchFriends(handle, false);
      handles.addAll(friendsList.cast<String>());
    }
    
    // Process each handle
    for (final currentHandle in handles) {
      try {
        // First try to get submissions via API for complete data
        try {
          final apiSubmissions = await getSubmissions(currentHandle);
          
          // Convert API submissions to our format
          for (final sub in apiSubmissions) {
            final submission = _convertApiSubmissionToMap(sub, currentHandle);
            allSubmissions.add(submission);
          }
        } catch (apiError) {
          // If API fails, fall back to scraping
          print('API fetch failed for $currentHandle, falling back to scraping: $apiError');
          final scrapedSubmissions = await _scrapeUserSubmissions(currentHandle);
          allSubmissions.addAll(scrapedSubmissions);
        }
      } catch (e) {
        print('Error getting submissions for $currentHandle: $e');
        // Continue with next handle even if one fails
      }
    }
    
    // Sort by submission time (newest first)
    allSubmissions.sort((a, b) {
      final timeA = a['creationTimeSeconds'] ?? 0;
      final timeB = b['creationTimeSeconds'] ?? 0;
      return timeB.compareTo(timeA);
    });
    
    return allSubmissions;
  }
  
  Map<String, dynamic> _convertApiSubmissionToMap(Map<String, dynamic> apiSubmission, String handle) {
    // Extract problem data
    final problem = apiSubmission['problem'] ?? {};
    final problemTags = problem['tags'] ?? [];
    
    // Extract author data
    final author = apiSubmission['author'] ?? {};
    final authorMembers = author['members'] ?? [];
    
    return {
      'id': apiSubmission['id'],
      'contestId': apiSubmission['contestId'],
      'creationTimeSeconds': apiSubmission['creationTimeSeconds'],
      'relativeTimeSeconds': apiSubmission['relativeTimeSeconds'],
      'problem': {
        'contestId': problem['contestId'],
        'index': problem['index'],
        'name': problem['name'],
        'type': problem['type'],
        'points': problem['points'],
        'rating': problem['rating'],
        'tags': List<String>.from(problemTags),
      },
      'author': {
        'contestId': author['contestId'],
        'participantId': author['participantId'],
        'members': List<Map<String, dynamic>>.from(
          authorMembers.map((m) => {'handle': m['handle']})),
        'participantType': author['participantType'],
        'ghost': author['ghost'] ?? false,
        'startTimeSeconds': author['startTimeSeconds'],
      },
      'programmingLanguage': apiSubmission['programmingLanguage'],
      'verdict': apiSubmission['verdict'],
      'testset': apiSubmission['testset'],
      'passedTestCount': apiSubmission['passedTestCount'],
      'timeConsumedMillis': apiSubmission['timeConsumedMillis'],
      'memoryConsumedBytes': apiSubmission['memoryConsumedBytes'],
      
      // Additional fields for convenience
      'handle': handle,
      'submissionTime': DateTime.fromMillisecondsSinceEpoch(
          (apiSubmission['creationTimeSeconds'] ?? 0) * 1000),
      'isAccepted': apiSubmission['verdict'] == 'OK',
      'problemUrl': 'https://codeforces.com/contest/${problem['contestId']}/problem/${problem['index']}',
      'submissionUrl': 'https://codeforces.com/contest/${apiSubmission['contestId']}/submission/${apiSubmission['id']}',
    };
  }
  
  Future<List<Map<String, dynamic>>> _scrapeUserSubmissions(String handle) async {
    final url = 'https://codeforces.com/submissions/$handle';
    final List<Map<String, dynamic>> submissions = [];
    
    try {
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final document = html_parser.parse(response.body);
        
        // Find the submissions table
        final submissionsTable = document.querySelector('table.status-frame-datatable');
        if (submissionsTable == null) {
          return submissions; // Return empty list if table not found
        }
        
        // Get all rows except the header
        final rows = submissionsTable.querySelectorAll('tr:not(.first-row)');
        
        for (final row in rows) {
          final cells = row.querySelectorAll('td');
          if (cells.length < 7) continue; // Skip if row doesn't have enough cells
          
          // Extract submission ID
          final idCell = cells[0];
          final idLink = idCell.querySelector('a');
          final submissionIdText = idLink?.text.trim() ?? '';
          final submissionId = int.tryParse(submissionIdText) ?? 0;
          
          // Extract submission time
          final timeCell = cells[1];
          final timeText = timeCell.text.trim();
          DateTime submissionTime;
          int creationTimeSeconds = 0;
          
          try {
            // Parse time in format "Today, 12:34" or "Yesterday, 12:34" or "May/12/2023 12:34"
            if (timeText.contains('Today')) {
              final time = timeText.split(', ')[1];
              final now = DateTime.now();
              submissionTime = DateTime(now.year, now.month, now.day, 
                int.parse(time.split(':')[0]), int.parse(time.split(':')[1]));
            } else if (timeText.contains('Yesterday')) {
              final time = timeText.split(', ')[1];
              final now = DateTime.now();
              final yesterday = now.subtract(const Duration(days: 1));
              submissionTime = DateTime(yesterday.year, yesterday.month, yesterday.day, 
                int.parse(time.split(':')[0]), int.parse(time.split(':')[1]));
            } else {
              // Parse date in format "May/12/2023 12:34"
              final parts = timeText.split(' ');
              final dateParts = parts[0].split('/');
              final timeParts = parts[1].split(':');
              
              // Convert month name to number
              final months = {
                'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
                'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12
              };
              final month = months[dateParts[0]] ?? 1;
              
              submissionTime = DateTime(
                int.parse(dateParts[2]), 
                month, 
                int.parse(dateParts[1]),
                int.parse(timeParts[0]), 
                int.parse(timeParts[1])
              );
            }
            creationTimeSeconds = (submissionTime.millisecondsSinceEpoch / 1000).round();
          } catch (e) {
            // Default to current time if parsing fails
            submissionTime = DateTime.now();
            creationTimeSeconds = (submissionTime.millisecondsSinceEpoch / 1000).round();
          }
          
          // Extract problem details
          final problemCell = cells[3];
          final problemLink = problemCell.querySelector('a');
          final problemName = problemLink?.text.trim() ?? '';
          final problemUrl = problemLink?.attributes['href'] ?? '';
          
          // Extract contest and problem ID from URL if available
          int contestId = 0;
          String problemIndex = '';
          if (problemUrl.isNotEmpty) {
            final urlParts = problemUrl.split('/');
            if (urlParts.length >= 4) {
              contestId = int.tryParse(urlParts[urlParts.length - 2]) ?? 0;
              problemIndex = urlParts[urlParts.length - 1];
            }
          }
          
          // Extract language
          final langCell = cells[4];
          final language = langCell.text.trim();
          
          // Extract verdict
          final verdictCell = cells[5];
          final verdictSpan = verdictCell.querySelector('span.verdict-accepted') ?? 
                              verdictCell.querySelector('span.verdict-rejected') ??
                              verdictCell.querySelector('span');
          final verdict = verdictSpan?.text.trim() ?? 'Unknown';
          final isAccepted = verdict.contains('Accepted');
          final standardVerdict = isAccepted ? 'OK' : _standardizeVerdict(verdict);
          
          // Extract time and memory
          final timeMemoryCell = cells[6];
          final timeMemoryText = timeMemoryCell.text.trim();
          final timeParts = RegExp(r'(\d+) ms').firstMatch(timeMemoryText);
          final memoryParts = RegExp(r'(\d+) KB').firstMatch(timeMemoryText);
          final executionTimeMs = timeParts != null ? int.parse(timeParts.group(1)!) : 0;
          final memoryKb = memoryParts != null ? int.parse(memoryParts.group(1)!) : 0;
          final memoryBytes = memoryKb * 1024; // Convert KB to bytes
          
          // Create a submission object with all fields
          final submission = {
            'id': submissionId,
            'contestId': contestId,
            'creationTimeSeconds': creationTimeSeconds,
            'relativeTimeSeconds': 2147483647, // Default value for practice submissions
            'problem': {
              'contestId': contestId,
              'index': problemIndex,
              'name': problemName,
              'type': 'PROGRAMMING', // Default value
              'points': 0.0, // Not available from scraping
              'rating': 0, // Not available from scraping
              'tags': <String>[], // Not available from scraping
            },
            'author': {
              'contestId': contestId,
              'participantId': 0, // Not available from scraping
              'members': [
                {'handle': handle}
              ],
              'participantType': 'PRACTICE', // Default value
              'ghost': false,
              'startTimeSeconds': 0, // Not available from scraping
            },
            'programmingLanguage': language,
            'verdict': standardVerdict,
            'testset': 'TESTS', // Default value
            'passedTestCount': isAccepted ? 100 : 0, // Exact count not available from scraping
            'timeConsumedMillis': executionTimeMs,
            'memoryConsumedBytes': memoryBytes,
            
            // Additional fields for convenience
            'handle': handle,
            'submissionTime': submissionTime,
            'isAccepted': isAccepted,
            'problemUrl': 'https://codeforces.com$problemUrl',
            'submissionUrl': 'https://codeforces.com/contest/$contestId/submission/$submissionId',
          };
          
          submissions.add(submission);
        }
      } else {
        throw Exception('Failed to load submissions page: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error scraping submissions: $e');
    }
    
    return submissions;
  }
  
  String _standardizeVerdict(String scrapedVerdict) {
    // Convert scraped verdict to API format
    final verdictMap = {
      'Accepted': 'OK',
      'Wrong answer': 'WRONG_ANSWER',
      'Runtime error': 'RUNTIME_ERROR',
      'Time limit exceeded': 'TIME_LIMIT_EXCEEDED',
      'Memory limit exceeded': 'MEMORY_LIMIT_EXCEEDED',
      'Compilation error': 'COMPILATION_ERROR',
      'Skipped': 'SKIPPED',
      'Rejected': 'REJECTED',
      'In queue': 'TESTING',
      'Pretests passed': 'PARTIAL',
    };
    
    for (final key in verdictMap.keys) {
      if (scrapedVerdict.contains(key)) {
        return verdictMap[key]!;
      }
    }
    
    return 'UNKNOWN';
  }
  
  // Get submission code by scraping the submission page
  Future<String> getSubmissionCode(int contestId, int submissionId) async {
    final url = 'https://codeforces.com/contest/$contestId/submission/$submissionId';
    
    try {
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final document = html_parser.parse(response.body);
        
        // Find the code element
        final codeElement = document.querySelector('pre#program-source-text');
        if (codeElement != null) {
          return codeElement.text;
        } else {
          throw Exception('Code element not found');
        }
      } else {
        throw Exception('Failed to load submission page: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting submission code: $e');
    }
  }
}
class ClubService {
  // Create a new club

  Future<String> createClub({
    required BuildContext context,
    required String name,
    required String description,
    String? bannerUrl,
    String? avatarUrl,
    bool isPublic = true,
  }) async {
    try {
      var userProvider = Provider.of<UserProvider>(context, listen: false);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('x-auth-token');

      final response = await http.post(
        Uri.parse('${Constants.uri}/api/clubs'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'x-auth-token': token ?? '',
        },
        body: jsonEncode({
          'name': name,
          'description': description,
          'bannerUrl': bannerUrl,
          'avatarUrl': avatarUrl,
          'isPublic': isPublic,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception(
            jsonDecode(response.body)['msg'] ?? 'Failed to create club');
      }

      final data = jsonDecode(response.body);
      if (!data['success']) {
        throw Exception(data['msg'] ?? 'Failed to create club');
      }

      return data['clubId'] ?? '';
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<bool> deleteClub(BuildContext context, String clubId) async {
    try {
      var userProvider = Provider.of<UserProvider>(context, listen: false);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('x-auth-token');

      final response = await http.delete(
        Uri.parse('${Constants.uri}/api/clubs/$clubId'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'x-auth-token': token ?? '',
        },
      );

      if (response.statusCode != 200) {
        throw Exception(
            jsonDecode(response.body)['msg'] ?? 'Failed to delete club');
      }

      return true;
    } catch (e) {
      showAlert(context, 'Error', e.toString());
      return false;
    }
  }

  // Get club by ID
  Future<Club?> getClubById(BuildContext context, String clubId) async {
    try {
      final response = await http.get(
        Uri.parse('${Constants.uri}/api/clubs/$clubId'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      Club? club;
      httpErrorHandle(
        response: response,
        context: context,
        onSuccess: () {
          final data = jsonDecode(response.body);
          club = Club.fromJson(data['club']);
        },
      );
      return club;
    } catch (e) {
      showAlert(context, 'Error', 'Failed to get club');
      return null; // Return null on error
    }
  }

  // Get all clubs
  Future<List<Club>> getAllClubs(BuildContext context) async {
    try {
      final response = await http.get(
        Uri.parse('${Constants.uri}/api/clubs'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );
      List<Club> clubs = [];
      httpErrorHandle(
        response: response,
        context: context,
        onSuccess: () {
          final data = jsonDecode(response.body);
          final clubsData = data['clubs'] as List<dynamic>;
          clubs = clubsData.map((clubData) => Club.fromJson(clubData)).toList();
        },
      );
      return clubs;
    } catch (e) {
      showAlert(context, 'Error', e.toString());
      return []; // Return empty list on error
    }
  }

  // Get clubs for a user
  Future<List<Club>> getUserClubs(BuildContext context, String userId) async {
    try {
      var userProvider = Provider.of<UserProvider>(context, listen: false);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('x-auth-token');
      final response = await http.get(
        Uri.parse('${Constants.uri}/api/users/$userId/clubs'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'x-auth-token': token ?? '',
        },
      );
      List<Club> clubs = [];
      httpErrorHandle(
        response: response,
        context: context,
        onSuccess: () {
          final data = jsonDecode(response.body);
          final clubsData = data['clubs'] as List<dynamic>;
          clubs = clubsData.map((clubData) => Club.fromJson(clubData)).toList();
        },
      );
      return clubs;
    } catch (e) {
      print(e.toString());
      showAlert(context, 'Error', 'Failed to get user clubs');
      return []; // Return empty list on error
    }
  }

  // Join a club
  Future<bool> joinClub(BuildContext context, String clubId) async {
    try {
      var userProvider = Provider.of<UserProvider>(context, listen: false);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('x-auth-token');
      final response = await http.post(
        Uri.parse('${Constants.uri}/api/clubs/$clubId/join'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'x-auth-token': token ?? '',
        },
      );
      print(response.body);
      bool success = false;
      httpErrorHandle(
        response: response,
        context: context,
        onSuccess: () {
          success = true;
          showAlert(context, 'Success', 'Successfully joined the club');
        },
      );
      return success;
    } catch (e) {
      print(e.toString());
      showAlert(context, 'Error', 'Failed to join club');
      return false; // Return false on error
    }
  }

  // Leave a club
  Future<bool> leaveClub(BuildContext context, String clubId) async {
    try {
      var userProvider = Provider.of<UserProvider>(context, listen: false);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('x-auth-token');
      final response = await http.post(
        Uri.parse('${Constants.uri}/api/clubs/$clubId/leave'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'x-auth-token': token ?? '',
        },
      );

      bool success = false;
      httpErrorHandle(
        response: response,
        context: context,
        onSuccess: () {
          success = true;
          showAlert(context, 'Success', 'Successfully left the club');
        },
      );
      return success;
    } catch (e) {
      showAlert(context, 'Error', 'Failed to leave club');
      return false; // Return false on error
    }
  }

  // Add a discussion
  Future<String> addDiscussion({
    required BuildContext context,
    required String clubId,
    required String title,
    required String content,
    required String authorName,
  }) async {
    try {
      var userProvider = Provider.of<UserProvider>(context, listen: false);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('x-auth-token');
      final response = await http.post(
        Uri.parse('${Constants.uri}/api/clubs/$clubId/discussions'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'x-auth-token': token ?? '',
        },
        body: jsonEncode({
          'title': title,
          'content': content,
          'authorName': authorName,
        }),
      );

      String discussionId = '';
      httpErrorHandle(
        response: response,
        context: context,
        onSuccess: () {
          final data = jsonDecode(response.body);
          discussionId = data['discussionId'];
        },
      );
      return discussionId;
    } catch (e) {
      showAlert(context, 'Error', 'Failed to add discussion');
      return ''; // Return empty string on error
    }
  }

  // Get club discussions
  Future<List<ClubDiscussion>> getClubDiscussions(
      BuildContext context, String clubId) async {
    try {
      final response = await http.get(
        Uri.parse('${Constants.uri}/api/clubs/$clubId/discussions'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      List<ClubDiscussion> discussions = [];
      httpErrorHandle(
        response: response,
        context: context,
        onSuccess: () {
          final data = jsonDecode(response.body);
          final discussionsData = data['discussions'] as List<dynamic>;
          discussions = discussionsData
              .map((discussionData) => ClubDiscussion.fromJson(discussionData))
              .toList();
        },
      );
      return discussions;
    } catch (e) {
      showAlert(context, 'Error', 'Failed to get discussions');
      return []; // Return empty list on error
    }
  }

  // Add a problem
  Future<String> addProblem({
    required BuildContext context,
    required String clubId,
    required String title,
    required String description,
    required String difficulty,
    required int points,
  }) async {
    try {
      var userProvider = Provider.of<UserProvider>(context, listen: false);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('x-auth-token');
      final response = await http.post(
        Uri.parse('${Constants.uri}/api/clubs/$clubId/problems'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'x-auth-token': token ?? '',
        },
        body: jsonEncode({
          'title': title,
          'description': description,
          'difficulty': difficulty,
          'points': points,
        }),
      );

      String problemId = '';
      httpErrorHandle(
        response: response,
        context: context,
        onSuccess: () {
          final data = jsonDecode(response.body);
          problemId = data['problemId'];
        },
      );
      return problemId;
    } catch (e) {
      showAlert(context, 'Error', 'Failed to add problem');
      return ''; // Return empty string on error
    }
  }

  // Get club problems
  Future<List<ClubProblem>> getClubProblems(
      BuildContext context, String clubId) async {
    try {
      final response = await http.get(
        Uri.parse('${Constants.uri}/api/clubs/$clubId/problems'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      List<ClubProblem> problems = [];
      httpErrorHandle(
        response: response,
        context: context,
        onSuccess: () {
          final data = jsonDecode(response.body);
          final problemsData = data['problems'] as List<dynamic>;
          problems = problemsData
              .map((problemData) => ClubProblem.fromJson(problemData))
              .toList();
        },
      );
      return problems;
    } catch (e) {
      showAlert(context, 'Error', 'Failed to get problems');
      return []; // Return empty list on error
    }
  }

  // Get club leaderboard
  Future<List<Map<String, dynamic>>> getClubLeaderboard(
      BuildContext context, String clubId) async {
    try {
      // First get the club to access member handles
      final club = await getClubById(context, clubId);
      if (club == null) {
        throw Exception('Club not found');
      }

      // Build a mapping from handle to userId
      final Map<String, String> handleToUserId = {};
      for (int i = 0; i < club.memberHandles.length; i++) {
        if (i < club.members.length) {
          handleToUserId[club.memberHandles[i]] = club.members[i];
        }
      }

      // Get user info for all members
      final response = await http.get(
        Uri.parse(
            'https://codeforces.com/api/user.info?handles=${club.memberHandles.join(";")}'),
      );
      //print(Uri.parse('https://codeforces.com/api/user.info?handles=${club.members.join(";")}'));

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch user data from Codeforces');
      }

      final data = jsonDecode(response.body);
      if (data['status'] != 'OK') {
        throw Exception(
            data['comment'] ?? 'Failed to fetch user data from Codeforces');
      }

      // Transform the data into leaderboard format
      final List<Map<String, dynamic>> leaderboard =
          data['result'].map<Map<String, dynamic>>((user) {
        return {
          'userId': handleToUserId[user['handle']] ?? '',
          'username': user['handle'],
          'avatarUrl': user['titlePhoto'] ?? '',
          'rating': user['rating'] ?? 0,
          'maxRating': user['maxRating'] ?? 0,
          'rank': user['rank'] ?? 'unrated',
          'contribution': user['contribution'] ?? 0,
        };
      }).toList();

      // Sort leaderboard by rating (points)
      leaderboard
          .sort((a, b) => (b['rating'] as int).compareTo(a['rating'] as int));

      return leaderboard;
    } catch (e) {
      print('Error building leaderboard: $e');
      showAlert(context, 'Error', 'Failed to get leaderboard');
      return []; // Return empty list on error
    }
  }

  // Search clubs
  Future<List<Club>> searchClubs(BuildContext context, String query) async {
    try {
      final response = await http.get(
        Uri.parse('${Constants.uri}/api/clubs/search?query=$query'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );
      print(Uri.parse('${Constants.uri}/api/clubs/search?query=$query'));
      print(response.body);
      List<Club> clubs = [];
      httpErrorHandle(
        response: response,
        context: context,
        onSuccess: () {
          final data = jsonDecode(response.body);
          final clubsData = data['clubs'] as List<dynamic>;
          clubs = clubsData.map((clubData) => Club.fromJson(clubData)).toList();
        },
      );
      return clubs;
    } catch (e) {
      showAlert(context, 'Error', 'Failed to search clubs');
      return []; // Return empty list on error
    }
  }
}
