import 'package:acex/services.dart';
import 'package:acex/suggested_problems.dart';
import 'package:acex/utils/loading_widget.dart';
import 'package:flutter/material.dart';
import 'package:multi_select_flutter/chip_display/multi_select_chip_display.dart';
import 'package:multi_select_flutter/dialog/multi_select_dialog_field.dart';
import 'package:multi_select_flutter/util/multi_select_item.dart';
import 'package:multi_select_flutter/util/multi_select_list_type.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class ProblemPage extends StatefulWidget {
  const ProblemPage({super.key, required this.handle});
  final String handle;

  @override
  State<ProblemPage> createState() => _ProblemPageState();
}

class _ProblemPageState extends State<ProblemPage> {
  late Future<Map<String, dynamic>> problemsetData;
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
  double _startRating = 800;
  double _endRating = 3500;

  // Filters
  RangeValues _ratingRange = const RangeValues(800, 3500);
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

  final Set<String> _selectedTags = {};

  // Toggle options
  bool _showTagsForUnsolved = true;
  bool _showRatingForUnsolved = true;
  bool _isFilterExpanded = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _loadFilterState();
  }

  // Load filter values from SharedPreferences.
  Future<void> _loadFilterState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _startRating = prefs.getDouble('startRating') ?? 800;
      _endRating = prefs.getDouble('endRating') ?? 3500;
      _ratingRange = RangeValues(_startRating, _endRating);
      final savedTags = prefs.getStringList('selectedTags') ?? [];
      _selectedTags.clear();
      _selectedTags.addAll(savedTags);
      _showTagsForUnsolved = prefs.getBool('showTagsForUnsolved') ?? true;
      _showRatingForUnsolved = prefs.getBool('showRatingForUnsolved') ?? true;
    });
  }

  // Save filter values to SharedPreferences.
  Future<void> _saveFilterState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('startRating', _startRating);
    await prefs.setDouble('endRating', _endRating);
    await prefs.setStringList('selectedTags', _selectedTags.toList());
    await prefs.setBool('showTagsForUnsolved', _showTagsForUnsolved);
    await prefs.setBool('showRatingForUnsolved', _showRatingForUnsolved);
  }

  void _fetchData() {
    problemsetData = ApiService().getProblemset();
    submissions = ApiService().getSubmissions(widget.handle);
    problemsetData.then((data) {
      setState(() {
        _problems = data['problems'];
        _problemStatistics = data['problemStatistics'];
        _applyFilters();
      });
    });
    submissions.then((data) {
      setState(() {
        parseSubmissions(data);
      });
    });
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
  }

  void _applyFilters() {
    setState(() {
      _ratingRange = RangeValues(_startRating, _endRating);
      _filteredProblems = _problems.where((problem) {
        // Check if problem has rating
        if (problem['rating'] == null) {
          return false;
        }

        // Filter by rating range
        final rating = problem['rating'] as int;
        if (rating < _ratingRange.start || rating > _ratingRange.end) {
          return false;
        }

        // Filter by tags
        if (_selectedTags.isNotEmpty) {
          final problemTags = List<String>.from(problem['tags']);
          bool hasSelectedTag = false;
          for (final tag in _selectedTags) {
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
      _saveFilterState();
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

  void _toggleFilterExpansion() {
    setState(() {
      _isFilterExpanded = !_isFilterExpanded;
    });
  }

  void _resetFilters() {
    setState(() {
      _startRating = 800;
      _endRating = 3500;
      _selectedTags.clear();
      _applyFilters();
    });
  }

  void _navigateToSuggestedProblems() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SuggestedProblemsPage(handle: widget.handle),
      ),
    );
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
          'Problems',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: Colors.teal,
        surfaceTintColor: Colors.teal,
        actions: [
          IconButton(
            icon: Icon(
              _isFilterExpanded ? Icons.filter_list_off : Icons.filter_list,
              color: Colors.white,
            ),
            onPressed: _toggleFilterExpansion,
          )
        ],
      ),
      body: FutureBuilder(
          future: problemsetData,
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
              child: Column(
                children: [
                  // Inline filter section
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: _isFilterExpanded ? null : 0,
                    child: _isFilterExpanded ? _buildFilterSection() : null,
                  ),
                  // Problem list
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(5.0),
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Suggestions Card
                          _buildSuggestionsCard(),
                          const SizedBox(height: 16),
                          _buildProblemList(),
                          const SizedBox(height: 60),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
    );
  }

  Widget _buildSuggestionsCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      elevation: 8,
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
              Colors.teal.shade50,
              Colors.teal.shade100,
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
                      color: Colors.teal,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.lightbulb_outline,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Suggestions',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.teal.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.teal.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'We have gone through your performance in the last few contests and handpicked some problems to help you improve.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.teal.shade800,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton.icon(
                  onPressed: _navigateToSuggestedProblems,
                  icon: const Icon(Icons.arrow_forward, color:Colors.white, size: 25),
                  label: const Text(
                    'View Suggested Problems',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    return Card(
      margin: const EdgeInsets.all(16),
      color: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Rating range filter
            Row(
              children: [
                const Icon(Icons.star, color: Colors.teal, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Rating Range',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  '${_startRating.round()} - ${_endRating.round()}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.teal),
                ),
              ],
            ),
            const SizedBox(height: 8),
            RangeSlider(
              values: RangeValues(_startRating, _endRating),
              min: 800,
              max: 3500,
              divisions: 27,
              activeColor: Colors.teal,
              inactiveColor: Colors.teal.withOpacity(0.3),
              labels: RangeLabels(
                _startRating.round().toString(),
                _endRating.round().toString(),
              ),
              onChanged: (RangeValues values) {
                setState(() {
                  _startRating = values.start;
                  _endRating = values.end;
                });
              },
              onChangeEnd: (RangeValues values) {
                _applyFilters();
              },
            ),

            const Divider(height: 24),

            // Tags filter
            Row(
              children: [
                const Icon(Icons.label_outline, color: Colors.teal, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Problem Tags',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (_selectedTags.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedTags.clear();
                        _applyFilters();
                      });
                    },
                    child: Text(
                      'Clear (${_selectedTags.length})',
                      style: const TextStyle(color: Colors.teal),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            MultiSelectDialogField<String>(
              items: _availableTags
                  .map((tag) => MultiSelectItem<String>(tag, tag))
                  .toList(),
              title: const Text('Problem Tags'),
              buttonText: const Text('Select Tags'),
              buttonIcon: const Icon(Icons.sell_rounded , color: Colors.teal),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              listType: MultiSelectListType.LIST,
              initialValue: _selectedTags.toList(),
              chipDisplay: MultiSelectChipDisplay(
                chipColor: Colors.teal,
                textStyle: const TextStyle(color: Colors.white, fontSize: 12),
                onTap: (value) {
                  setState(() {
                    _selectedTags.remove(value);
                    _applyFilters();
                  });
                },
              ),
              onConfirm: (values) {
                setState(() {
                  _selectedTags
                    ..clear()
                    ..addAll(values);
                  _applyFilters();
                });
              },
              // Teal‐themed dialog
              backgroundColor: Colors.white,
              selectedColor: Colors.teal,
              unselectedColor: Colors.teal.shade50,
              checkColor: Colors.white,
              confirmText: const Text('OK', style: TextStyle(color: Colors.teal)),
              cancelText: const Text('CANCEL', style: TextStyle(color: Colors.teal)),
              itemsTextStyle: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
              ),
              selectedItemsTextStyle: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
              ),
            ),
            const Divider(height: 24),

            // Toggle options
            Row(
              children: [
                const Icon(Icons.visibility, color: Colors.teal, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Show for unsolved:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const Spacer(),
                ChoiceChip(
                  label: const Text('Tags'),
                  selected: _showTagsForUnsolved,
                  selectedColor: Colors.teal,
                  backgroundColor: Colors.white,
                  checkmarkColor:
                      (_showTagsForUnsolved) ? Colors.white : Colors.black,
                  labelStyle: TextStyle(
                    color: _showTagsForUnsolved ? Colors.white : Colors.black,
                  ),
                  onSelected: (bool selected) {
                    setState(() {
                      _showTagsForUnsolved = selected;
                      _applyFilters();
                    });
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Rating'),
                  selected: _showRatingForUnsolved,
                  selectedColor: Colors.teal,
                  backgroundColor: Colors.white,
                  checkmarkColor:
                      (_showRatingForUnsolved) ? Colors.white : Colors.black,
                  labelStyle: TextStyle(
                    color: _showRatingForUnsolved ? Colors.white : Colors.black,
                  ),
                  onSelected: (bool selected) {
                    setState(() {
                      _showRatingForUnsolved = selected;
                      _applyFilters();
                    });
                  },
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                      onPressed: _resetFilters,
                      icon: const Icon(Icons.refresh, size: 18, color: Colors.teal),
                      label: const Text('Reset All'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.teal,
                        side: const BorderSide(color: Colors.teal, width: 2),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
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
                  'No problems match your filters',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Try adjusting your filter criteria',
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
    //print('Question: $contestId$index is solved: $isSolved');
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
                      (_showRatingForUnsolved || isSolved)
                          ? Container(
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
                            )
                          : Container(),
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
                  (_showTagsForUnsolved || isSolved)
                      ? const SizedBox(height: 8)
                      : const SizedBox.shrink(),
                  (_showTagsForUnsolved || isSolved)
                      ? _buildInfoRow(
                          Icons.label_outline,
                          'Tags:',
                          tags.join(', '),
                          Colors.grey[600]!,
                        )
                      : const SizedBox.shrink(),
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

  Widget _buildExampleWidget(Map<String, String> example) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Input
            const Text(
              'Input:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Text(
                example['input'] ?? '',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Output
            const Text(
              'Output:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Text(
                example['output'] ?? '',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
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