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
import 'package:hive_flutter/hive_flutter.dart';
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
      showAlert(context, 'Error', "Some error occured, please try again later.");
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
      showAlert(context, 'Error', "Some error occured, please try again later.");
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
  
  Future<void> deleteAccount({
    required BuildContext context,
    Function? onSuccess,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('x-auth-token') ?? '';
      final res = await http.delete(
        Uri.parse('${Constants.uri}/api/delete-account'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'x-auth-token': token,
        },
      );
      httpErrorHandle(
        response: res,
        context: context,
        onSuccess: () async {
          // clear local token and navigate to auth page
          await prefs.setString('x-auth-token', '');
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const AuthPage()),
            (_) => false,
          );
          showAlert(context, 'Success', 'Your account has been deleted.');
          if (onSuccess != null) onSuccess();
        },
      );
    } catch (e) {
      showAlert(context, 'Error', e.toString());
    }
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
  final Box _cache = Hive.box('apiCache');

  Future<T> _withCache<T>(
    String key,
    Future<T> Function() fetcher, {
    Duration ttl = const Duration(hours: 1),
    bool force = false,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (!force && _cache.containsKey(key)) {
      final entry = _cache.get(key) as Map;
      if (now - entry['ts'] < ttl.inMilliseconds) {
        return entry['data'] as T;
      }
    }
    final data = await fetcher();
    _cache.put(key, {'ts': now, 'data': data});
    return data;
  }

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

  /// 1h cache, force reload with `force: true`
  Future<List<dynamic>> getContests({bool force = false}) =>
    _withCache<List<dynamic>>(
      'contests',
      () async {
        final resp = await http.get(Uri.parse('${baseUrl}contest.list'));
        final json = jsonDecode(resp.body);
        if (json['status'] != 'OK') throw Exception('Error loading contests');
        return json['result'] as List<dynamic>;
      },
      ttl: const Duration(hours: 1),
      force: force,
    );

  Future<List<Map<String, dynamic>>> _getRecentContests(int count) async {
    try {
      final response = await http.get(
        Uri.parse('https://codeforces.com/api/contest.list'),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final contests = List<Map<String, dynamic>>.from(data['result']);
          // Filter finished contests and take the most recent ones
          final finishedContests = contests
              .where((contest) => contest['phase'] == 'FINISHED')
              .take(count)
              .toList();
          return finishedContests;
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Hard‐coded list of all CF tags
  final List<String> _availableTags = [
    '2-sat',
    'binary search',
    'bitmasks',
    'brute force',
    'chinese remainder theorem',
    'combinatorics',
    'constructive algorithms',
    'data structures',
    'dfs and similar',
    'divide and conquer',
    'dp',
    'dsu',
    'expression parsing',
    'fft',
    'flows',
    'games',
    'geometry',
    'graph matchings',
    'graphs',
    'greedy',
    'hashing',
    'implementation',
    'interactive',
    'math',
    'matrices',
    'meet-in-the-middle',
    'number theory',
    'probabilities',
    'shortest paths',
    'sortings',
    'string suffix structures',
    'strings',
    'ternary search',
    'trees',
    'two pointers',
  ];

  /// Public, cached version – TTL 6h, bypass with `force: true`
  Future<List<String>> getUnsolvedTagsFromLastContests(
    String handle,
    int contestCount, {
    bool force = false,
  }) =>
    _withCache<List<String>>(
      'unsolved_tags_${handle}_$contestCount',
      () => _fetchUnsolvedTagsFromLastContests(handle, contestCount),
      ttl: const Duration(hours: 12),
      force: force,
    );
  /// Get user’s unsolved tags from last N contests, using only
  /// the above hard-coded tag list and CF standings with &handles=
  Future<List<String>> _fetchUnsolvedTagsFromLastContests(
      String handle, int contestCount) async {
    try {
      // 1) fetch the N most‐recent finished contests
      final recent = await _getRecentContests(contestCount);
      final ids = recent.map((c) => c['id'] as int).toList();

      final Set<String> unsolvedTags = {};

      // 2) for each contest, pull standings just for this handle
      for (final cid in ids) {
        final standing = await getUserStandings(cid, handle);
        final problems = standing['problems'] as List<dynamic>;
        final rows = standing['rows'] as List<dynamic>;
        if (rows.isEmpty) continue;

        // only one row when you pass &handles=
        final results = rows[0]['problemResults'] as List<dynamic>;
        // First pass: collect tags for all problems you attempted (rejectedAttemptCount > 0)
        for (var i = 0; i < problems.length && i < results.length; i++) {
          final res = results[i];
          final points = (res['points'] as num).toDouble();
          final rejected = (res['rejectedAttemptCount'] as int);
          if (points == 0 && rejected > 0) {
            final prob = problems[i] as Map<String, dynamic>;
            final tags = List<String>.from(prob['tags'] ?? <String>[]);
            for (var t in tags) {
              if (_availableTags.contains(t)) unsolvedTags.add(t);
            }
          }
        }

        // Second pass: collect tags for the first completely unattempted unsolved problem
        final firstUnattempted = results.indexWhere((r) =>
            (r['points'] as num).toDouble() == 0 &&
            (r['rejectedAttemptCount'] as int) == 0);
        if (firstUnattempted >= 0 && firstUnattempted < problems.length) {
          final prob = problems[firstUnattempted] as Map<String, dynamic>;
          final tags = List<String>.from(prob['tags'] ?? <String>[]);
          for (var t in tags) {
            if (_availableTags.contains(t)) unsolvedTags.add(t);
          }
        }
      }

      return unsolvedTags.toList();
    } catch (e) {
      return <String>[];
    }
  }

   /// 6h cache per contest
  Future<Map<String, dynamic>> getContestDetails(int contestId,
      {bool force = false}) =>
    _withCache<Map<String, dynamic>>(
      'contest_details_$contestId',
      () async {
        final resp = await http.get(Uri.parse(
            '${baseUrl}contest.standings?contestId=$contestId'));
        final json = jsonDecode(resp.body);
        if (json['status'] != 'OK') throw Exception('Error loading standings');
        return json['result'] as Map<String, dynamic>;
      },
      ttl: const Duration(hours: 6),
      force: force,
    );

  /// 6h cache per contest
  Future<List<dynamic>> getContestRatingChanges(int contestId,
      {bool force = false}) =>
    _withCache<List<dynamic>>(
      'rating_changes_$contestId',
      () async {
        final resp = await http.get(Uri.parse(
            '${baseUrl}contest.ratingChanges?contestId=$contestId'));
        final json = jsonDecode(resp.body);
        if (json['status'] != 'OK') throw Exception('Error loading ratings');
        return json['result'] as List<dynamic>;
      },
      ttl: const Duration(hours: 6),
      force: force,
    );

  /// 1h cache per handle
  Future<Map<String, dynamic>> getUserStandings(int contestId, String handle,
      {bool force = false}) =>
    _withCache<Map<String, dynamic>>(
      'user_standings_${contestId}_$handle',
      () async {
        final resp = await http.get(Uri.parse(
            '${baseUrl}contest.standings?contestId=$contestId&handles=$handle'));
        final json = jsonDecode(resp.body);
        if (json['status'] != 'OK') throw Exception('Error loading user');
        return json['result'] as Map<String, dynamic>;
      },
      ttl: const Duration(hours: 1),
      force: force,
    );

  /// 12h cache per handle
  Future<Map<String, dynamic>> getUserInfo(String handle,
      {bool force = false}) =>
    _withCache<Map<String, dynamic>>(
      'user_info_$handle',
      () async {
        final resp = await http
            .get(Uri.parse('${baseUrl}user.info?handles=$handle'));
        final json = jsonDecode(resp.body);
        if (json['status'] != 'OK') throw Exception('Error loading user info');
        return (json['result'] as List).first as Map<String, dynamic>;
      },
      ttl: const Duration(hours: 12),
      force: force,
    );

  /// 6h cache per handle
  Future<List<dynamic>> getRatingHistory(String handle,
      {bool force = false}) =>
    _withCache<List<dynamic>>(
      'rating_history_$handle',
      () async {
        final resp = await http
            .get(Uri.parse('${baseUrl}user.rating?handle=$handle'));
        final json = jsonDecode(resp.body);
        if (json['status'] != 'OK') throw Exception('Error loading history');
        return json['result'] as List<dynamic>;
      },
      ttl: const Duration(hours: 6),
      force: force,
    );

  /// 0.5hr cache per handle
  Future<List<dynamic>> getSubmissions(String handle, {bool force = false}) =>
    _withCache<List<dynamic>>(
      'submissions_$handle',
      () async {
        final resp = await http
            .get(Uri.parse('${baseUrl}user.status?handle=$handle'));
        final json = jsonDecode(resp.body);
        if (json['status'] != 'OK') throw Exception('Error loading subs');
        return json['result'] as List<dynamic>;
      },
      ttl: const Duration(minutes: 30),
      force: force,
    );

  /// 24h cache for full problemset
  Future<Map<String, dynamic>> getProblemset({bool force = false}) =>
    _withCache<Map<String, dynamic>>(
      'problemset',
      () async {
        final resp = await http
            .get(Uri.parse('${baseUrl}problemset.problems'));
        final json = jsonDecode(resp.body);
        if (json['status'] != 'OK') throw Exception('Error loading problems');
        return json['result'] as Map<String, dynamic>;
      },
      ttl: const Duration(hours: 24),
      force: force,
    );

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

  /// 30 min cache for friend standings
  Future<Map<String, dynamic>> getFriendStandings(
    String handle,
    int contestId, {
    bool force = false,
  }) =>
      _withCache<Map<String, dynamic>>(
        'friend_standings_${handle}_$contestId',
        () async {
          String? apiKey   = await SecureStorageService.readData('api_key_$handle');
          String? apiSecret= await SecureStorageService.readData('api_secret_$handle');
          const methodName = 'contest.standings';
          final time       = (DateTime.now().millisecondsSinceEpoch / 1000).round();
          final friends    = await fetchFriends(handle, false);
          final fh         = friends.join(';');
          final params     = 'apiKey=$apiKey&contestId=$contestId&handles=$handle;$fh&time=$time';
          final sig        = _generateApiSig(time, methodName, params, apiSecret);
          final url        = Uri.parse('$baseUrl$methodName?$params&apiSig=$sig');
          final resp       = await http.get(url);
          if (resp.statusCode != 200) throw Exception('Failed to fetch standings');
          final data = jsonDecode(resp.body);
          if (data['status'] != 'OK') throw Exception('Failed to fetch standings');
          return data['result'] as Map<String, dynamic>;
        },
        ttl: const Duration(minutes: 30),
        force: force,
      );

  /// 15 min cache for friends list
  Future<List<dynamic>> fetchFriends(
    String handle,
    bool isOnline, {
    bool force = false,
  }) =>
      _withCache<List<dynamic>>(
        'friends_${handle}_${isOnline ? "online" : "all"}',
        () async {
          String? apiKey   = await SecureStorageService.readData('api_key_$handle');
          String? apiSecret= await SecureStorageService.readData('api_secret_$handle');
          const methodName = 'user.friends';
          final time       = (DateTime.now().millisecondsSinceEpoch / 1000).round();
          final params     = 'apiKey=$apiKey&onlyOnline=$isOnline&time=$time';
          final sig        = _generateApiSig(time, methodName, params, apiSecret);
          final url        = Uri.parse('$baseUrl$methodName?$params&apiSig=$sig');
          final resp       = await http.get(url);
          if (resp.statusCode != 200) throw Exception('Failed to load friends list');
          final data = jsonDecode(resp.body);
          if (data['status'] != 'OK') {
            throw Exception('Failed to load friends: ${data['comment']}');
          }
          return data['result'] as List<dynamic>;
        },
        ttl: const Duration(minutes: 15),
        force: force,
      );

  /// 1 h cache for bulk friends info
  Future<List<dynamic>> fetchFriendsInfo(
    String handle,
    bool isOnline, {
    bool force = false,
  }) =>
      _withCache<List<dynamic>>(
        'friends_info_${handle}_${isOnline ? "online" : "all"}',
        () async {
          final list = await fetchFriends(handle, isOnline);
          final s    = list.join(';');
          final uri  = Uri.parse('$baseUrl/user.info?handles=$handle;$s');
          final resp = await http.get(uri);
          if (resp.statusCode != 200) throw Exception('Failed to fetch user info');
          final data = jsonDecode(resp.body);
          if (data['status'] != 'OK') throw Exception('Failed to fetch user info');
          return data['result'] as List<dynamic>;
        },
        ttl: const Duration(hours: 1),
        force: force,
      );
}