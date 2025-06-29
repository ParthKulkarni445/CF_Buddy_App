import 'package:acex/providers/user_provider.dart';
import 'package:acex/services.dart';
import 'package:acex/settings.dart';
import 'package:acex/utils/loading_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class SubmissionsPage extends StatefulWidget {
  final String handle;
  const SubmissionsPage({super.key, required this.handle});

  @override
  State<SubmissionsPage> createState() => _SubmissionsPageState();
}

class _SubmissionsPageState extends State<SubmissionsPage> {
  late Future<List<dynamic>> submissions;
  late Future<List<dynamic>> friends;
  late Future<Map<String, dynamic>> problems;
  final int _pageSize = 50;
  int _currentPage = 1;
  List<dynamic> _allSubmissions = [];
  List<dynamic> _problems = [];
  List<dynamic> _friends = [];
  late String _selectedHandle;
  final storage = const FlutterSecureStorage();
  bool isLoading = true;
  bool hasCredentials = false;

  @override
  void initState() {
    super.initState();
    _checkCredentials();
    _selectedHandle = widget.handle;
    _fetchData();
  }

  Future<void> _checkCredentials() async {
    String handle = Provider.of<UserProvider>(context, listen: false).user.handle;
    final apiKey = await storage.read(key: 'api_key_$handle');
    final apiSecret = await storage.read(key: 'api_secret_$handle');
    
    if ( apiKey != null && apiSecret != null) {
      _fetchData();
      setState(() {
        hasCredentials = true;
        isLoading = false;
      });
    } else {
      setState(() {
        hasCredentials = false;
        isLoading = false;
      });
    }
  }

  void _fetchData() {
    submissions = ApiService().getSubmissions(_selectedHandle);
    friends = ApiService().fetchFriends(widget.handle, false);
    problems = ApiService().getProblemset();
  }

  void _retryFetchData() {
    setState(() {
      _fetchData();
    });
  }

  Future<void> _refreshData() async {
    setState(() {
      _fetchData();
      _currentPage = 1;
    });
    await Future.wait([submissions, problems]);
  }

  Widget _buildNoCredentialsMessage() {
    return Card(
      color: Colors.white,
      elevation: 10,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(25),
      ),
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.warning_rounded,
                size: 64,
                color: Colors.orange,
              ),
              const SizedBox(height: 16),
              const Text(
                'API Credentials Required',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please go to Settings and enter your API credentials to view friends.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  elevation: 5
                ),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsPage()));
                },
                child: const Text('Go to Settings'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey[200],
        appBar: AppBar(
          centerTitle: true,
          elevation: 15,
          shadowColor: Colors.black,
          title: const Text(
            'Submissions',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 24,
              letterSpacing: 0.5,
            ),
          ),
          backgroundColor: Colors.green,
          surfaceTintColor: Colors.green,
          actions: [
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'settings') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SettingsPage()),
                  );
                } else if (value == 'signout') {
                  final authService = AuthService();
                  authService.signOut(context);
                }
              },
              icon: const Icon(Icons.more_vert, color: Colors.white, size: 30),
              color: Colors.white, // Dropdown background color
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'settings',
                  child: Row(
                    children: [
                      const Icon(Icons.settings, color: Colors.black),
                      const SizedBox(width: 8),
                      const Text('Settings',
                          style: TextStyle(color: Colors.black)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'signout',
                  child: Row(
                    children: [
                      const Icon(Icons.logout, color: Colors.black),
                      const SizedBox(width: 8),
                      const Text('Sign Out',
                          style: TextStyle(color: Colors.black)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: const Center(child: LoadingCard(primaryColor: Colors.blue)),
      );
    }

    if(!hasCredentials && _selectedHandle != Provider.of<UserProvider>(context, listen: false).user.handle) {
      return Scaffold(
        backgroundColor: Colors.grey[200],
        appBar: AppBar(
          centerTitle: true,
          elevation: 15,
          shadowColor: Colors.black,
          title: const Text(
            'Submissions',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 24,
              letterSpacing: 0.5,
            ),
          ),
          backgroundColor: Colors.green,
          surfaceTintColor: Colors.green,
          actions: [
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'settings') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SettingsPage()),
                  );
                } else if (value == 'signout') {
                  final authService = AuthService();
                  authService.signOut(context);
                }
              },
              icon: const Icon(Icons.more_vert, color: Colors.white, size: 30),
              color: Colors.white, // Dropdown background color
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'settings',
                  child: Row(
                    children: [
                      const Icon(Icons.settings, color: Colors.black),
                      const SizedBox(width: 8),
                      const Text('Settings',
                          style: TextStyle(color: Colors.black)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'signout',
                  child: Row(
                    children: [
                      const Icon(Icons.logout, color: Colors.black),
                      const SizedBox(width: 8),
                      const Text('Sign Out',
                          style: TextStyle(color: Colors.black)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: _buildNoCredentialsMessage(),
      );
    }

    if (!hasCredentials) {
      return Scaffold(
        backgroundColor: Colors.grey[200],
        appBar: AppBar(
          centerTitle: true,
          elevation: 15,
          shadowColor: Colors.black,
          title: const Text(
            'Submissions',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 24,
              letterSpacing: 0.5,
            ),
          ),
          backgroundColor: Colors.green,
          surfaceTintColor: Colors.green,
          actions: [
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'settings') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SettingsPage()),
                  );
                } else if (value == 'signout') {
                  final authService = AuthService();
                  authService.signOut(context);
                }
              },
              icon: const Icon(Icons.more_vert, color: Colors.white, size: 30),
              color: Colors.white, // Dropdown background color
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'settings',
                  child: Row(
                    children: [
                      const Icon(Icons.settings, color: Colors.black),
                      const SizedBox(width: 8),
                      const Text('Settings',
                          style: TextStyle(color: Colors.black)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'signout',
                  child: Row(
                    children: [
                      const Icon(Icons.logout, color: Colors.black),
                      const SizedBox(width: 8),
                      const Text('Sign Out',
                          style: TextStyle(color: Colors.black)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: FutureBuilder(
          future: Future.wait([submissions, problems]),
          builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return LoadingCard(
                primaryColor: Colors.green,
              );
            }
            if (snapshot.hasError || snapshot.data == null) {
              return _buildErrorWidget();
            }
            _allSubmissions = snapshot.data![0];
            _problems = snapshot.data![1]['problems'];

            return RefreshIndicator(
              onRefresh: _refreshData,
              color: Colors.black,
              backgroundColor: Colors.green,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(5.0),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 16),
                    _buildSubmissionsList(),
                    const SizedBox(height: 60),
                  ],
                ),
              ),
            );
          },
        ),
      );
    }

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.grey[200],
        appBar: AppBar(
          centerTitle: true,
          elevation: 15,
          shadowColor: Colors.black,
          title: const Text(
            'Submissions',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 24,
              letterSpacing: 0.5,
            ),
          ),
          backgroundColor: Colors.green,
          surfaceTintColor: Colors.green,
          actions: [
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'settings') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SettingsPage()),
                  );
                } else if (value == 'signout') {
                  final authService = AuthService();
                  authService.signOut(context);
                }
              },
              icon: const Icon(Icons.more_vert, color: Colors.white, size: 30),
              color: Colors.white, // Dropdown background color
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'settings',
                  child: Row(
                    children: [
                      const Icon(Icons.settings, color: Colors.black),
                      const SizedBox(width: 8),
                      const Text('Settings',
                          style: TextStyle(color: Colors.black)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'signout',
                  child: Row(
                    children: [
                      const Icon(Icons.logout, color: Colors.black),
                      const SizedBox(width: 8),
                      const Text('Sign Out',
                          style: TextStyle(color: Colors.black)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: FutureBuilder(
          future: Future.wait([submissions, problems, friends]),
          builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return LoadingCard(
                primaryColor: Colors.green,
              );
            }
            if (snapshot.hasError || snapshot.data == null) {
              return _buildErrorWidget();
            }
            _allSubmissions = snapshot.data![0];
            _problems = snapshot.data![1]['problems'];
            _friends = snapshot.data![2];

            return RefreshIndicator(
              onRefresh: _refreshData,
              color: Colors.black,
              backgroundColor: Colors.green,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(5.0),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          canvasColor: Colors.white,
                          inputDecorationTheme: InputDecorationTheme(
                            filled: true,
                            fillColor: Colors.grey[100],
                            labelStyle: TextStyle(
                              color: Colors.green[800],
                              fontWeight: FontWeight.bold,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: Colors.green[800]!,
                                width: 2,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: Colors.green[800]!,
                                width: 2,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: Colors.green[800]!,
                                width: 2.5,
                              ),
                            ),
                          ),
                        ),
                        child: Card(
                          elevation: 7,
                          color: Colors.transparent,
                          child: DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              labelText: 'Select Handle',
                              fillColor: Colors.white,
                              prefixIcon: Icon(Icons.person, color: Colors.green[800]),
                            ),
                            menuMaxHeight: 500,
                            value: _selectedHandle,
                            icon: Icon(Icons.arrow_drop_down,
                                color: Colors.green[800], size: 28),
                            dropdownColor: Colors.white,
                            style: TextStyle(
                              color: Colors.grey[900],
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Poppins',
                              fontSize: 16,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            items: [
                              DropdownMenuItem(
                                value: widget.handle,
                                child: Text(widget.handle,
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold, 
                                            color: (widget.handle == _selectedHandle)
                                                ? Colors.green[800]
                                                : Colors.grey[900])),
                              ),
                              ..._friends.map((f) => f.toString()).map(
                                    (h) => DropdownMenuItem(
                                        value: h, child:Text(h,
                                        style: TextStyle(fontWeight: FontWeight.bold, 
                                            color: (h == _selectedHandle)
                                                ? Colors.green[800]
                                                : Colors.grey[900]))),
                                  ),
                            ],
                            onChanged: (value) {
                              if (value != null && value != _selectedHandle) {
                                setState(() {
                                  _selectedHandle = value;
                                  _fetchData();
                                });
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildSubmissionsList(),
                    const SizedBox(height: 60),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSubmissionsList() {
    final int totalPages = (_allSubmissions.length / _pageSize).ceil();
    final int startIndex = (_currentPage - 1) * _pageSize;
    final int endIndex = startIndex + _pageSize > _allSubmissions.length
        ? _allSubmissions.length
        : startIndex + _pageSize;
    final List<dynamic> currentPageSubmissions =
        _allSubmissions.sublist(startIndex, endIndex);

    return Column(
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: currentPageSubmissions.length,
          itemBuilder: (context, index) =>
              _buildSubmissionTile(currentPageSubmissions[index]),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton(
                onPressed: _currentPage > 1
                    ? () => setState(() => _currentPage--)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                child: const Icon(Icons.chevron_left),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Page $_currentPage of $totalPages',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.grey[800],
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: _currentPage < totalPages
                    ? () => setState(() => _currentPage++)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                child: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubmissionTile(dynamic submission) {
    final submissionTime = DateTime.fromMillisecondsSinceEpoch(
        submission['creationTimeSeconds'] * 1000);
    final dateFormat = DateFormat('MMM/dd/yy,HH:mm');
    final formattedDate = dateFormat.format(submissionTime);
    final isAccepted = submission['verdict'] == 'OK';
    final problem = _problems.firstWhere((element) =>
        (element['contestId'] == submission['problem']['contestId'] &&
            element['index'] == submission['problem']['index']) ||
        element['name'] == submission['problem']['name']);
    final rating = problem['rating'];
    List<String> tags = problem['tags'].cast<String>();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      elevation: 7,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: isAccepted
              ? Colors.green[50]
              : ((submission['verdict'] == null)
                  ? Colors.orange[50]
                  : Colors.red[50]),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isAccepted
                ? Colors.green[200]!
                : ((submission['verdict'] == null)
                    ? Colors.orange[200]!
                    : Colors.red[200]!),
            width: 1.5,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () async {
              final contestId = submission['problem']['contestId'];
              final submissionId = submission[
                  'id']; // Assuming 'id' is the key for submission ID
              final uri = Uri.parse(
                  'https://codeforces.com/contest/$contestId/submission/$submissionId');
              if (!await launchUrl(
                uri,
                mode: LaunchMode.inAppBrowserView,
              )) {
                throw Exception('Could not launch $uri');
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          "${submission['problem']['contestId']}${submission['problem']['index']} | ${submission['problem']['name']}",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[900],
                            height: 1.3,
                          ),
                        ),
                      ),
                      if (rating != null && isAccepted)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[900],
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey[400]!,
                                blurRadius: 2,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Text(
                            rating.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    Icons.access_time,
                    'Submitted:',
                    formattedDate,
                    Colors.blue[600]!,
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    Icons.check_circle_outline,
                    'Verdict:',
                    submission['verdict'] ?? "SYSTEM_TESTING",
                    isAccepted
                        ? Colors.green[700]!
                        : ((submission['verdict'] == null)
                            ? Colors.orange
                            : Colors.red[700]!),
                  ),
                  
                  if(isAccepted)const SizedBox(height: 8),
                  if(isAccepted)_buildInfoRow(
                    Icons.label_outline,
                    'Tags:',
                    tags.join(', '),
                    Colors.grey[600]!,
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
      IconData icon, String label, String value, Color textColor) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
              Icons.signal_wifi_statusbar_connected_no_internet_4_outlined,
              size: 150),
          const SizedBox(height: 18),
          const Text(
            'Something went wrong',
            style: TextStyle(
                fontSize: 22, color: Colors.black, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: _retryFetchData,
            style: ElevatedButton.styleFrom(
              elevation: 6,
              backgroundColor: Colors.green,
            ),
            child: const Text('Retry', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }
}
