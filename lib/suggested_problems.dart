import 'package:acex/services.dart';
import 'package:acex/utils/loading_widget.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SuggestedProblemsPage extends StatefulWidget {
  const SuggestedProblemsPage({super.key, required this.handle});
  final String handle;

  @override
  State<SuggestedProblemsPage> createState() => _SuggestedProblemsPageState();
}

class _SuggestedProblemsPageState extends State<SuggestedProblemsPage> {
  late Future<Map<String, dynamic>> problemsetData;
  late Future<Map<String, dynamic>> userDataFuture;
  List<dynamic> _problems = [];
  List<dynamic> _problemStatistics = [];
  List<dynamic> _filteredProblems = [];
  late Future<List<dynamic>> submissions;
  final Set<String> _solvedProblemKeys = {};
  final Set<String> _attemptedProblemKeys = {};
  String _problemKey(String contestId, String index) => '$contestId$index';

  // Pagination
  int _currentPage = 1;
  final int _pageSize = 50;
  
  // Auto-set filters based on user data
  double _startRating = 800;
  double _endRating = 3500;
  Set<String> _suggestedTags = {};
  int _userCurrentRating = 1200; // Default rating

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() {
    problemsetData = ApiService().getProblemset();
    submissions = ApiService().getSubmissions(widget.handle);
    userDataFuture = _fetchUserDataAndTags();
    
    problemsetData.then((data) {
      setState(() {
        _problems = data['problems'];
        _problemStatistics = data['problemStatistics'];
      });
    });
    
    submissions.then((data) {
      setState(() {
        parseSubmissions(data);
      });
    });

    userDataFuture.then((userData) {
      setState(() {
        _userCurrentRating = userData['currentRating'] ?? 1200;
        _suggestedTags = Set<String>.from(userData['suggestedTags'] ?? []);
        _setRatingRange();
        _applyFilters();
      });
    });
  }

  Future<Map<String, dynamic>> _fetchUserDataAndTags() async {
    try {
      // Fetch user's current rating
      final userInfo = await ApiService().getUserInfo(widget.handle);
      final currentRating = userInfo['rating'] ?? 1200;
      
      // Fetch unsolved problem tags from last 3 contests
      // This assumes you have a method in ApiService to get this data
      final unsolvedTags = await ApiService().getUnsolvedTagsFromLastContests(widget.handle, 3);
      
      return {
        'currentRating': currentRating,
        'suggestedTags': unsolvedTags,
      };
    } catch (e) {
      // Fallback values if API calls fail
      return {
        'currentRating': 1200,
        'suggestedTags': <String>[],
      };
    }
  }

  void _setRatingRange() {
    // Set rating range to current_rating ± 200
    _startRating = (_userCurrentRating - 200).clamp(800, 3500).toDouble();
    _endRating = (_userCurrentRating + 200).clamp(800, 3500).toDouble();
  }

  void _retryFetchData() {
    setState(() {
      _fetchData();
    });
  }

  Future<void> _refreshData() async {
    setState(() {
      _fetchData();
    });
    await problemsetData;
    await userDataFuture;
  }

  void _applyFilters() {
    setState(() {
      _filteredProblems = _problems.where((problem) {
        // Check if problem has rating
        if (problem['rating'] == null) {
          return false;
        }

        // Filter by rating range (current_rating ± 200)
        final rating = problem['rating'] as int;
        if (rating < _startRating || rating > _endRating) {
          return false;
        }

        // Filter by suggested tags (from unsolved problems in last 3 contests)
        if (_suggestedTags.isNotEmpty) {
          final problemTags = List<String>.from(problem['tags']);
          bool hasSelectedTag = false;
          for (final tag in _suggestedTags) {
            if (problemTags.contains(tag)) {
              hasSelectedTag = true;
              break;
            }
          }
          if (!hasSelectedTag) {
            return false;
          }
        }

        return true;
      }).toList();
      _currentPage = 1;
    });
  }

  Future<void> _launchURL(String contestId, String index) async {
    final url = 'https://codeforces.com/problemset/problem/$contestId/$index';
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(
      uri,
      mode: LaunchMode.inAppBrowserView,
    )) {
      throw Exception('Could not launch $url');
    }
  }

  void parseSubmissions(List<dynamic> submissions) {
    for (final submission in submissions) {
      final verdict = submission['verdict'];
      final problem = submission['problem'];
      final contestId = problem['contestId'].toString();
      final index = problem['index'];
      final problemKey = _problemKey(contestId, index);
      if (verdict == 'OK') {
        _solvedProblemKeys.add(problemKey);
      } else {
        _attemptedProblemKeys.add(problemKey);
      }
    }
  }

  bool _isProblemSolved(String contestId, String index) {
    return _solvedProblemKeys.contains(_problemKey(contestId, index));
  }

  bool _isProblemAttempted(String contestId, String index) {
    return _attemptedProblemKeys.contains(_problemKey(contestId, index));
  }

  int _getProblemSolvedCount(String contestId, String index) {
    final stat = _problemStatistics.firstWhere(
      (stat) =>
          stat['contestId'].toString() == contestId && stat['index'] == index,
      orElse: () => {'solvedCount': 0},
    );
    return stat['solvedCount'] ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        centerTitle: true,
        elevation: 15,
        shadowColor: Colors.black,
        title: const Text(
          'Suggested Problems',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: Colors.teal,
        surfaceTintColor: Colors.teal,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder(
          future: Future.wait([problemsetData, userDataFuture]),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const LoadingCard(primaryColor: Colors.teal);
            }
            if (snapshot.hasError || snapshot.data == null) {
              return _buildErrorWidget();
            }

            return RefreshIndicator(
              onRefresh: _refreshData,
              color: Colors.black,
              backgroundColor: Colors.teal,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(5.0),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSuggestionInfoCard(),
                    const SizedBox(height: 16),
                    _buildProblemList(),
                    const SizedBox(height: 60),
                  ],
                ),
              ),
            );
          }),
    );
  }

  Widget _buildSuggestionInfoCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade50,
              Colors.blue.shade100,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Personalized Suggestions',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildInfoChip(
                'Rating Range', 
                '${_startRating.round()} - ${_endRating.round()}',
                Icons.star,
                Colors.orange,
              ),
              const SizedBox(height: 8),
              if (_suggestedTags.isNotEmpty)
                _buildInfoChip(
                  'Focus Tags', 
                  _suggestedTags.take(3).join(', ') + 
                    (_suggestedTags.length > 3 ? '...' : ''),
                  Icons.label,
                  Colors.green,
                ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Problems are filtered based on your current rating (±200) and tags from your recent unsolved attempts.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue.shade800,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
            fontSize: 14,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProblemList() {
    if (_filteredProblems.isEmpty) {
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        elevation: 7,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: Colors.white,
        child: const Padding(
          padding: EdgeInsets.all(24.0),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.search_off, size: 48, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No suggested problems found',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Try solving more problems to get better suggestions',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final int totalPages = (_filteredProblems.length / _pageSize).ceil();
    final int startIndex = (_currentPage - 1) * _pageSize;
    final int endIndex = startIndex + _pageSize > _filteredProblems.length
        ? _filteredProblems.length
        : startIndex + _pageSize;
    final List<dynamic> currentPageProblems =
        _filteredProblems.sublist(startIndex, endIndex);

    return Column(
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: currentPageProblems.length,
          itemBuilder: (context, index) =>
              _buildProblemTile(currentPageProblems[index]),
        ),
        if (totalPages > 1)
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
                    backgroundColor: Colors.teal,
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
                    backgroundColor: Colors.teal,
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

  Widget _buildProblemTile(dynamic problem) {
    final String contestId = problem['contestId'].toString();
    final String index = problem['index'];
    final String name = problem['name'];
    final int rating = problem['rating'] ?? 0;
    final List<String> tags = List<String>.from(problem['tags']);
    final bool isSolved = _isProblemSolved(contestId, index);
    final bool isAttempted = _isProblemAttempted(contestId, index);
    final int solvedCount = _getProblemSolvedCount(contestId, index);

    Color backgroundColor = Colors.white;
    Color borderColor = Colors.grey[600]!;

    if (isSolved) {
      backgroundColor = Colors.green[50]!;
      borderColor = Colors.green[200]!;
    } else if (isAttempted) {
      backgroundColor = Colors.red[50]!;
      borderColor = Colors.red[200]!;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      elevation: 7,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: borderColor,
            width: 1.5,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () async {
              _launchURL(contestId, index);
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
                          name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[900],
                            height: 1.3,
                          ),
                        ),
                      ),
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
                    Icons.numbers,
                    'Problem:',
                    '$contestId$index',
                    Colors.teal,
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    Icons.people,
                    'Solved by:',
                    'x${solvedCount.toString()}',
                    Colors.indigo[600]!,
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    Icons.label_outline,
                    'Tags:',
                    tags.join(', '),
                    Colors.grey[600]!,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (isSolved)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle,
                                  size: 16, color: Colors.green[700]),
                              const SizedBox(width: 4),
                              Text(
                                'Solved',
                                style: TextStyle(
                                  color: Colors.green[700],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        )
                      else if (isAttempted)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.error_outline,
                                  size: 16, color: Colors.red[700]),
                              const SizedBox(width: 4),
                              Text(
                                'Attempted',
                                style: TextStyle(
                                  color: Colors.red[700],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        )
                    ],
                  ),
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
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}