import 'dart:math';
import 'package:acex/services.dart';
import 'package:acex/settings.dart';
import 'package:acex/utils/loading_widget.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

// Constants for the sqrt(2) value used in the erf function
const double sqrt2 = 1.4142135623730951;

// Approximation of inverse error function (erf⁻¹)
double inverseNormalCDF(double p) {
  if (p <= 0 || p >= 1) return double.nan;

  // Modified constants for improved ranking distribution
  const double a1 = -3.969683028665376e+01,
      a2 = 2.209460984245205e+02,
      a3 = -2.759285104469687e+02,
      a4 = 1.383577518672690e+02,
      a5 = -3.066479806614716e+01,
      a6 = 2.506628277459239e+00;
  const double b1 = -5.447609879822406e+01,
      b2 = 1.615858368580409e+02,
      b3 = -1.556989798598866e+02,
      b4 = 6.680131188771972e+01,
      b5 = -1.328068155288572e+01;
  const double c1 = -7.784894002430293e-03,
      c2 = -3.223964580411365e-01,
      c3 = -2.400758277161838e+00,
      c4 = -2.549732539343734e+00,
      c5 = 4.874664141464968e+00,
      c6 = 3.238163982698783e+00;
  const double d1 = 7.784695709041462e-03,
      d2 = 3.324671290700398e-01,
      d3 = 2.545134137142996e+00,
      d4 = 3.954408661907416e+00;

  const double pLow = 0.022;
  const double pHigh = 1 - pLow;

  double q, r, result;

  if (p < pLow) {
    q = sqrt(-2 * log(p));
    result = (((((c1 * q + c2) * q + c3) * q + c4) * q + c5) * q + c6) /
        ((((d1 * q + d2) * q + d3) * q + d4) * q + 1);
  } else if (p <= pHigh) {
    q = p - 0.5;
    r = q * q;
    result = (((((a1 * r + a2) * r + a3) * r + a4) * r + a5) * r + a6) *
        q /
        (((((b1 * r + b2) * r + b3) * r + b4) * r + b5) * r + 1);
  } else {
    q = sqrt(-2 * log(1 - p));
    result = -(((((c1 * q + c2) * q + c3) * q + c4) * q + c5) * q + c6) /
        ((((d1 * q + d2) * q + d3) * q + d4) * q + 1);
  }

  return result;
}

// Approximation of the error function (erf)
double erf(double x) {
  // constants
  const double a1 = 0.254829592, a2 = -0.284496736, a3 = 1.421413741;
  const double a4 = -1.453152027, a5 = 1.061405429, p = 0.3275911;
  int sign = x < 0 ? -1 : 1;
  double absX = x.abs();
  double t = 1.0 / (1.0 + p * absX);
  double y = 1 -
      ((((a5 * t + a4) * t + a3) * t + a2) * t + a1) * t * exp(-absX * absX);
  return sign * y;
}

// Standard normal CDF using erf
double normalCDF(double x) {
  return 0.5 * (1 + erf(x / sqrt2));
}

// Function to calculate performance rating
int calculatePerformanceRating({
  required int rank,
  required int totalParticipants,
  double averageRating = 1062,
  double beta = 462,
}) {
  if (rank <= 0 || totalParticipants <= 0 || rank > totalParticipants) {
    return 0;
  }

  double percentile = 1 - ((rank - 0.5) / totalParticipants);
  double perf = averageRating + (inverseNormalCDF(percentile) * beta);

  return max(0, perf.round());
}

/// Calculates total participants given a known delta and current rating.
///
/// Uses the relation:
///   delta = |currRating - perf| / 4
///   perf = averageRating + Phi^{-1}(percentile) * beta
///   percentile = Phi(z)
///   percentile = 1 - ((rank - 0.5) / N)
/// Solve for N:
///   N = (rank - 0.5) / (1 - percentile)
int findTotalParticipants({
  required int rank,
  required double currRating,
  required double delta,
  required String contestName,
  double averageRating = 1230,
  double beta = 450,
}) {
  if (contestName.contains('Div. 2')) {
    averageRating = 1170;
  } else if (contestName.contains('Div. 3'))
    averageRating = 1100;
  else if (contestName.contains('Div. 4'))
    averageRating = 950;
  else if (contestName.contains('Div. 1')) {
    averageRating = 2200;
    beta = 250;
  }
  print('rank: $rank, currRating: $currRating, delta: $delta');
  // Estimate performance rating from delta (assuming perf >= currRating)
  double perf = currRating + 4 * delta;
  //int predictedPerf = calculatePerformanceRating(rank: rank, totalParticipants: totalParticipants)
  print('perf: $perf');

  // Compute z from perf
  double z = (perf - averageRating) / beta;
  print('z: $z');

  // Compute percentile from z
  double percentile = normalCDF(z);
  if (percentile >= 1) return rank; // edge case: top rank
  print('percentile: $percentile');
  // Solve for total participants
  double N = (rank - 0.5) / (1 - percentile);
  print('N: $N');
  return N.ceil();
}

class StatsPage extends StatefulWidget {
  final String handle;
  const StatsPage({super.key, required this.handle});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  late Future<List<dynamic>> submissions;
  late Future<Map<String, dynamic>> problems;
  late Future<List<dynamic>> contests;
  late Future<List<dynamic>> ratingHistory;
  int _currentPage = 0;
  final PageController _pageController = PageController(initialPage: 0);
  late Map<String, Map<int, int>> rankCounts;
  String _selectedRange = 'Overall';

  final Map<String, Map<String, dynamic>> rankInfo = {
    'newbie': {
      'color': const Color(0xFF808080),
      'name': 'Newbie',
      'range': [800, 1199],
    },
    'pupil': {
      'color': const Color(0xFF008000),
      'name': 'Pupil',
      'range': [1200, 1399],
    },
    'specialist': {
      'color': const Color(0xFF03A89E),
      'name': 'Specialist',
      'range': [1400, 1599],
    },
    'expert': {
      'color': const Color(0xFF0000FF),
      'name': 'Expert',
      'range': [1600, 1899],
    },
    'candidate': {
      'color': const Color(0xFF800080),
      'name': 'Candidate Master',
      'range': [1900, 2099],
    },
    'master': {
      'color': const Color(0xFFFF8C00),
      'name': 'Master',
      'range': [2100, 2299],
    },
    'international': {
      'color': const Color(0xFFFF0000),
      'name': 'International Master',
      'range': [2300, 2399],
    },
    'grandmaster': {
      'color': const Color(0xFFFF0000),
      'name': 'Grandmaster',
      'range': [2400, 2599],
    },
    'legendary': {
      'color': const Color(0xFF8B0000),
      'name': 'Legendary Grandmaster',
      'range': [2600, 3500],
    },
  };

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _fetchData() {
    submissions = ApiService().getSubmissions(widget.handle);
    problems = ApiService().getProblemset();
    contests = ApiService().getContests();
    ratingHistory = ApiService().getRatingHistory(widget.handle);
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
    await Future.wait([submissions, problems, contests, ratingHistory]);
  }

  Map<String, Map<int, int>> processSubmissions(
      List<dynamic> subs, Map<String, dynamic> probs) {
    Map<String, Map<String, dynamic>> acceptedProblems = {};
    // int cnt=0;
    for (var submission in subs) {
      if (submission['verdict'] == 'OK') {
        String problemId =
            '${submission['problem']['contestId']}-${submission['problem']['index']}';
        // print('${++cnt} Processing submission for problem: $problemId');
        if (!acceptedProblems.containsKey(problemId)) {
          acceptedProblems[problemId] = submission['problem'];
        }
      }
    }

    Map<String, Map<int, int>> nonEmptyRankCounts = {};
    // print('Processing ${acceptedProblems.length} accepted problems');
    for (var problem in acceptedProblems.values) {
      if (problem['rating'] != null) {
        int rating = problem['rating'];
        // print('$rating, ${++ct}');
        int ratingKey = (rating ~/ 100) * 100;
        if (ratingKey < 800) ratingKey = 800;
        // print('Rating key: $ratingKey');
        for (var rank in rankInfo.keys) {
          final range = rankInfo[rank]!['range'] as List<int>;
          if (ratingKey >= range[0] && ratingKey <= range[1]) {
            if (!nonEmptyRankCounts.containsKey(rank)) {
              nonEmptyRankCounts[rank] = {};
            }
            if (!nonEmptyRankCounts[rank]!.containsKey(ratingKey)) {
              nonEmptyRankCounts[rank]![ratingKey] = 0;
            }
            nonEmptyRankCounts[rank]![ratingKey] =
                (nonEmptyRankCounts[rank]![ratingKey] ?? 0) + 1;
            break;
          }
        }
      }
    }

    return nonEmptyRankCounts;
  }

  Map<String, dynamic> getTopicStats(List<dynamic> submissions) {
    Map<String, Set<String>> solvedByTag = {};
    Map<String, int> failedAttemptsByTag = {};
    Map<
        String,
        ({
          int correctAttempts,
          int wrongAttempts,
          int totalAttempts,
          double successRate
        })> topicStats = {};

    // Calculate total submissions for threshold
    final int totalSubmissions = submissions.length;
    final int minimumSubmissions =
        (totalSubmissions * 0.03).ceil(); // 3% threshold

    // Collect solved and failed attempts
    for (var submission in submissions) {
      if (submission['problem']['tags'] != null) {
        List<dynamic> tags = submission['problem']['tags'];
        String problemId =
            '${submission['problem']['contestId']}-${submission['problem']['index']}';
        String? verdict = submission['verdict'];
        if (verdict == null) continue;
        for (var tag in tags) {
          if (verdict == 'OK') {
            if (!solvedByTag.containsKey(tag)) {
              solvedByTag[tag] = {};
            }
            solvedByTag[tag]!.add(problemId);
          }

          if (verdict != 'OK') {
            failedAttemptsByTag[tag] = (failedAttemptsByTag[tag] ?? 0) + 1;
          }
        }
      }
    }

    // Combine stats and calculate percentages
    for (var tag in {...solvedByTag.keys, ...failedAttemptsByTag.keys}) {
      final correctAttempts = solvedByTag[tag]?.length ?? 0;
      final wrongAttempts = failedAttemptsByTag[tag] ?? 0;
      final totalAttempts = correctAttempts + wrongAttempts;

      // Only include tags with more than 3% of total submissions
      if (totalAttempts >= minimumSubmissions) {
        final successRate =
            totalAttempts > 0 ? (correctAttempts / totalAttempts * 100) : 0.0;

        topicStats[tag] = (
          correctAttempts: correctAttempts,
          wrongAttempts: wrongAttempts,
          totalAttempts: totalAttempts,
          successRate: successRate
        );
      }
    }

    // Sort by success rate
    var sortedTopics = topicStats.entries.toList()
      ..sort((a, b) => b.value.successRate.compareTo(a.value.successRate));

    // Get top 5 and bottom 5
    var top5 = sortedTopics.take(5).toList();
    var worst5 = sortedTopics.reversed.take(5).toList();

    return {
      'top5': top5,
      'worst5': worst5,
    };
  }

  Widget _buildContestPerformanceCard(List<dynamic> ratingHistory) {
    // Process rating history to calculate percentiles and other stats
    List<Map<String, dynamic>> processedHistory = [];
    // Find longest positie delta streak
    int longestPositiveDeltaStreak = 0;
    int currentStreak = 0;
    for (int i = ratingHistory.length - 1;i >= 0;i--) {
      final contest = ratingHistory[i];
      final rank = contest['rank'] as int;
      final oldRating = contest['oldRating'] as int;
      final newRating = contest['newRating'] as int;
      final delta = newRating - oldRating;
      print('delta: $delta');
      final perf = oldRating + 4 * delta;
      if(delta > 0) {
        currentStreak++;
      } else {
        longestPositiveDeltaStreak = max(longestPositiveDeltaStreak, currentStreak);
        currentStreak = 0;
      }

      // Calculate total participants using the provided function
      //print('contest: ${contest['contestId']} ${contest['contestName']}');

      int totalParticipants = findTotalParticipants(
        rank: rank,
        currRating: oldRating.toDouble(),
        contestName: contest['contestName'],
        delta: delta.toDouble(),
      );
      //print('\n');
      //print('Contest: ${contest['contestName']} ,Rank: $rank,Total Participants: $totalParticipants');

      // If we couldn't calculate participants or got an unreasonable number, use a fallback
      if (totalParticipants <= rank || totalParticipants <= 0) {
        totalParticipants = max(rank * 2, 1000); // Fallback estimation
      }

      // Calculate percentile (lower is better)
      double percentile = (1 - (rank / totalParticipants)) * 100;

      processedHistory.add({
        'contestId': contest['contestId'],
        'contestName': contest['contestName'],
        'rank': rank,
        'oldRating': oldRating,
        'perf': perf,
        'newRating': newRating,
        'delta': delta,
        'totalParticipants': totalParticipants,
        'percentile': percentile,
        'date': DateTime.fromMillisecondsSinceEpoch(
            contest['ratingUpdateTimeSeconds'] * 1000),
      });
    }
    longestPositiveDeltaStreak = max(longestPositiveDeltaStreak, currentStreak);
    //_copyPerformanceTableToClipboard(processedHistory); // optional file dump

    // Calculate stats
    int totalContests = processedHistory.length;

    // Find best and worst ranks
    processedHistory.sort((a, b) => a['rank'].compareTo(b['rank']));
    final bestRank = totalContests > 0 ? processedHistory.first : null;
    final worstRank = totalContests > 0 ? processedHistory.last : null;

    // Find best and worst deltas
    print(processedHistory);
    processedHistory.sort((a, b) => (b['delta']).compareTo(a['delta']));
    final bestDelta = totalContests > 0 ? processedHistory.first : null;
    final worstDelta = totalContests > 0 ? processedHistory.last : null;

    

    // Sort back by contest date for the graph
    processedHistory.sort((a, b) => a['date'].compareTo(b['date']));

    // Prepare data for percentile graph
    List<FlSpot> percentileSpots = [];
    List<String> contestNames = [];
    if(processedHistory.length>15)
    {
      processedHistory = processedHistory.sublist(processedHistory.length - 15);
    } 
    for (int i = processedHistory.length-1; i >=0; i--) {
      percentileSpots.add(FlSpot(i.toDouble(), processedHistory[i]['percentile']));
      contestNames.add(processedHistory[i]['contestName']);
    }

    return Card(
      elevation: 4,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Contest Performance Stats',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // Stats Grid
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildContestStatItem(
                          'Total Contests',
                          '$totalContests',
                          FontAwesomeIcons.trophy,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildContestStatItem(
                          'Best Rank',
                          bestRank != null ? '${bestRank['rank']}' : 'N/A',
                          FontAwesomeIcons.medal,
                          tooltip:
                              bestRank != null ? bestRank['contestName'] : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildContestStatItem(
                          'Worst Rank',
                          worstRank != null ? '${worstRank['rank']}' : 'N/A',
                          FontAwesomeIcons.thumbsDown,
                          tooltip: worstRank != null
                              ? worstRank['contestName']
                              : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildContestStatItem(
                          'Best Delta',
                          bestDelta != null ? '+${bestDelta['delta']}' : 'N/A',
                          FontAwesomeIcons.arrowTrendUp,
                          tooltip: bestDelta != null
                              ? bestDelta['contestName']
                              : null,
                          valueColor: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildContestStatItem(
                          'Worst Delta',
                          worstDelta != null ? '${worstDelta['delta']}' : 'N/A',
                          FontAwesomeIcons.arrowTrendDown,
                          tooltip: worstDelta != null
                              ? worstDelta['contestName']
                              : null,
                          valueColor: Colors.red,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildContestStatItem(
                          'Max +Δ Streak',
                          '$longestPositiveDeltaStreak',
                          FontAwesomeIcons.fire,
                          tooltip: longestPositiveDeltaStreak > 0
                              ? 'Longest positive delta streak'
                              : null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            const Text(
              'Contest Percentile History',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              '*Some predictions involved',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            
            // Percentile Graph
            Container(
              height: 300,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: percentileSpots.isEmpty
                  ? const Center(child: Text('No contest data available'))
                  : _buildPercentileGraph(
                      percentileSpots, contestNames, processedHistory),
            ),

            const SizedBox(height: 15),
          ],
        ),
      ),
    );
  }

  Widget _buildContestStatItem(String label, String value, IconData icon,
      {String? tooltip, Color? valueColor}) {
    return Tooltip(
      message: tooltip ?? '',
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(

              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FaIcon(icon, size: 16, color: Colors.purple),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: valueColor ?? Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPercentileGraph(List<FlSpot> spots, List<String> contestNames,
      List<Map<String, dynamic>> processedHistory) {
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey[300],
              strokeWidth: 1,
            );
          },
          horizontalInterval: 10,
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            //Show date in DD/MM
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= contestNames.length) {
                  return const SizedBox.shrink();
                }
                // extract date and format
                final date = processedHistory[idx]['date'] as DateTime;
                final label = DateFormat('dd MMM').format(date);
                return Column(
                  children: [
                    const SizedBox(height: 20),
                    Transform.rotate(
                      angle: -pi / 2.5, // rotate -45°
                      alignment: Alignment.topCenter,
                      child: Text(
                        label,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  '  ${value.toInt()}%',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: true),
        minX: 0,
        maxX: (spots.length - 1).toDouble(),
        minY: 0,
        maxY: 100,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: false,
            color: Colors.purple,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: Colors.purple,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.purple.withOpacity(0.1),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            maxContentWidth: 150,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((LineBarSpot touchedSpot) {
                final index = touchedSpot.x.toInt();
                final contest = processedHistory[index];
                final percentile = touchedSpot.y;
                final rank = contest['rank'];
                final total = contest['totalParticipants'];
                final delta = contest['delta'];
                final sign = delta >= 0 ? '+' : '';

                return LineTooltipItem(
                  '${contest['contestName']}\n'
                  'Rank: $rank\n'
                  'Delta: $sign$delta',
                  const TextStyle(color: Colors.white),
                );
              }).toList();
            },
          ),
        ),
        backgroundColor: Colors.purple.withOpacity(0.05),
      ),
    );
  }

  Widget _buildTopicStatsCard(List<dynamic> submissions) {
    final topicStats = getTopicStats(submissions);
    final bestTopics = topicStats['top5'] as List<
        MapEntry<
            String,
            ({
              int correctAttempts,
              int wrongAttempts,
              int totalAttempts,
              double successRate
            })>>;
    final worstTopics = topicStats['worst5'] as List<
        MapEntry<
            String,
            ({
              int correctAttempts,
              int wrongAttempts,
              int totalAttempts,
              double successRate
            })>>;

    Color getColorForSuccessRate(double rate) {
      if (rate >= 80) return Colors.green;
      if (rate >= 60) return Colors.blue;
      if (rate >= 40) return Colors.orange;
      return Colors.red;
    }

    Widget buildTopicItem(
        MapEntry<
                String,
                ({
                  int correctAttempts,
                  int wrongAttempts,
                  int totalAttempts,
                  double successRate
                })>
            entry) {
      final topic = entry.key;
      final stats = entry.value;

      return Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    topic,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Text(
                  '${stats.successRate.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: getColorForSuccessRate(stats.successRate),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Stack(
              children: [
                // Background progress bar
                Container(
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                // Success rate progress bar
                FractionallySizedBox(
                  widthFactor: stats.successRate / 100,
                  child: Container(
                    height: 24,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          getColorForSuccessRate(stats.successRate)
                              .withOpacity(0.7),
                          getColorForSuccessRate(stats.successRate),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                // Stats text
                Container(
                  height: 24,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '✓ ${stats.correctAttempts}',
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '✗ ${stats.wrongAttempts}',
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Total attempts: ${stats.totalAttempts}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return Card(
      elevation: 4,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Topic Statistics',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            // Best Topics Section
            const Row(
              children: [
                Icon(Icons.emoji_events, color: Colors.amber),
                SizedBox(width: 8),
                Text(
                  'Best Performing Topics',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...bestTopics.map(buildTopicItem),
            const Divider(height: 32),
            // Worst Topics Section
            const Row(
              children: [
                Icon(Icons.warning_rounded, color: Colors.red),
                SizedBox(width: 8),
                Text(
                  'Topics Needing Improvement',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...worstTopics.map(buildTopicItem),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmissionStatsCard(List<dynamic> submissions) {
    Map<String, dynamic> getSubmissionStats() {
      Map<String, int> verdictCounts = {
        'Accepted': 0,
        'Wrong Answer': 0,
        'Time Limit': 0,
        'Others': 0
      };
      Map<String, Set<String>> problemAttempts = {};
      int total = 0;
      final interval = _selectedRange == 'Last Week'
          ? DateTime.now().subtract(Duration(days: 7))
          : _selectedRange == 'Last Month'
              ? DateTime.now().subtract(Duration(days: 30))
              : DateTime.fromMillisecondsSinceEpoch(0);


      for (var submission in submissions) {
        if (submission['verdict'] == null) continue;
        final submissionTime = DateTime.fromMillisecondsSinceEpoch(
            submission['creationTimeSeconds'] * 1000);
        if (submissionTime.isBefore(interval)) continue;

        total++;
        String verdict = submission['verdict'];
        if (verdict == 'OK') {
          verdictCounts['Accepted'] = verdictCounts['Accepted']! + 1;
        } else if (verdict == 'WRONG_ANSWER') {
          verdictCounts['Wrong Answer'] = verdictCounts['Wrong Answer']! + 1;
        } else if (verdict == 'TIME_LIMIT_EXCEEDED') {
          verdictCounts['Time Limit'] = verdictCounts['Time Limit']! + 1;
        } else {
          verdictCounts['Others'] = verdictCounts['Others']! + 1;
        }

        String problemId =
            '${submission['problem']['contestId']}-${submission['problem']['index']}';
        if (!problemAttempts.containsKey(problemId)) {
          problemAttempts[problemId] = {};
        }
        problemAttempts[problemId]!.add(verdict);
      }

      int uniqueProblems=0;
      for (var pids in problemAttempts.keys) {
        if (problemAttempts[pids]!.contains('OK')) {
          uniqueProblems++;
        }
      }

      int problemsWithMultipleAttempts = problemAttempts.values
          .where((attempts) => attempts.length > 1 && attempts.contains('OK'))
          .length;

      return {
        'verdicts': verdictCounts,
        'total': total,
        'multipleAttempts': problemsWithMultipleAttempts,
        'uniqueProblems': uniqueProblems,
      };
    }

    final stats = getSubmissionStats();
    final verdictColors = {
      'Accepted': Colors.green,
      'Wrong Answer': Colors.red,
      'Time Limit': Colors.orange,
      'Others': Colors.grey,
    };
    print(stats);

    final Map<String, int> verdicts = stats['verdicts'];
    final acceptanceRate = (stats['total']>0)?(verdicts['Accepted'] ?? 0) / stats['total'] * 100 : 0;
    final avgAttempts = stats['multipleAttempts'] > 0
        ? (stats['total'] - (verdicts['Accepted'] ?? 0)) /
            stats['multipleAttempts']
        : 0.0;

    return Card(
      elevation: 4,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Submission Statistics',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text('Filter:'),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _selectedRange,
                  dropdownColor: Colors.white,
                  items: const [
                    DropdownMenuItem(value: 'Last Week', child: Text('Last Week')),
                    DropdownMenuItem(value: 'Last Month', child: Text('Last Month')),
                    DropdownMenuItem(value: 'Overall', child: Text('Overall')),
                  ],
                  onChanged: (newValue) {
                    setState(() {
                      _selectedRange = newValue ?? 'Overall';
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            Center(
              child: SizedBox(
                height: 250,
                child: (stats['total']>0)?PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                    startDegreeOffset: 180,
                    pieTouchData: PieTouchData(
                      enabled: true,
                    ),
                    sections: verdicts.entries.map((entry) {
                      final verdict = entry.key;
                      final count = entry.value;
                      final percentage = (count / stats['total'] * 100);
                      return PieChartSectionData(
                        color: verdictColors[verdict]!,
                        value: count.toDouble(),
                        title: '${percentage.toStringAsFixed(1)}%',
                        radius: 80,
                        titleStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        titlePositionPercentageOffset: 0.7,
                        borderSide: BorderSide(
                          color: Colors.grey[600]!,
                          width: 3,
                        ),
                        showTitle: true,
                      );
                    }).toList(),
                  ),
                  duration: const Duration(milliseconds: 500),
                ): const Center(
                  child: Text(
                    'No submissions available',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: verdicts.entries.map((entry) {
                final verdict = entry.key;
                final count = entry.value;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: verdictColors[verdict] ?? Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$verdict ($count)',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            Column(
              children: [
                _buildStatItem(FontAwesomeIcons.fileLines, 'Total Submissions:',
                    '${stats['total']}'),
                _buildStatItem(FontAwesomeIcons.circleQuestion,
                    'Total Problems:', '${stats['uniqueProblems']}'),
                _buildStatItem(FontAwesomeIcons.check, 'Acceptance Rate:',
                    '${acceptanceRate.toStringAsFixed(2)}%'),
                _buildStatItem(FontAwesomeIcons.circleXmark,
                    'Avg Incorrect Attempts:', avgAttempts.toStringAsFixed(0)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              FaIcon(icon,
                  size: constraints.maxWidth * 0.07, color: Colors.grey[600]),
              SizedBox(
                width: constraints.maxWidth * 0.88,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(label, style: TextStyle(color: Colors.grey[600])),
                    Text(
                      value.length > 19
                          ? '${value.substring(0, 19)}...'
                          : value,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRankStatsCard() {
    List<String> getSortedRankKeys() {
      final rankOrder = [
        'newbie',
        'pupil',
        'specialist',
        'expert',
        'candidate',
        'master',
        'international',
        'grandmaster',
        'legendary'
      ];
      return rankOrder.where((rank) => rankCounts.containsKey(rank)).toList();
    }

    final sortedRankKeys = getSortedRankKeys();

    return StatefulBuilder(
      builder: (context, setState) {
        return Card(
          elevation: 7,
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Problem Rating Statistics',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: DropdownButton<int>(
                    dropdownColor: Colors.white,
                    value: _currentPage,
                    isExpanded: true,
                    items: sortedRankKeys.asMap().entries.map((mapEntry) {
                      final menuIndex = mapEntry.key;
                      final rankKey = mapEntry.value;
                      final menuRank = rankInfo[rankKey]!;

                      return DropdownMenuItem<int>(
                        value: menuIndex,
                        child: Text(
                          menuRank['name'],
                          style: TextStyle(
                            color: menuRank['color'],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (index) {
                      if (index != null) {
                        setState(() {
                          _currentPage = index;
                        });
                        _pageController.jumpToPage(index);
                      }
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: SizedBox(
                    height: 330,
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() {
                          _currentPage = index;
                        });
                      },
                      itemCount: sortedRankKeys.length,
                      itemBuilder: (context, index) {
                        final rankKey = sortedRankKeys[index];
                        final rank = rankInfo[rankKey]!;
                        final rankData = rankCounts[rankKey]!;
                        return Padding(
                          padding: const EdgeInsets.only(
                              top: 16.0, right: 10.0, left: 10.0),
                          child: Column(
                            children: [
                              Expanded(
                                child: Center(
                                  child: buildBarGraph(
                                    rankData,
                                    rank['color'],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget buildBarGraph(Map<int, int> rankData, Color rankColor) {
    final maxProblems =
        rankData.values.isNotEmpty ? rankData.values.reduce(max) : 1;
    final sortedEntries = rankData.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final total = rankData.values.isNotEmpty
        ? rankData.values.reduce((a, b) => a + b)
        : 0;

    return Column(
      children: [
        SizedBox(
          height: 250,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxProblems.toDouble() + 50,
              backgroundColor: rankColor.withOpacity(0.1),
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    return BarTooltipItem(
                      '${rod.toY.toInt()} problems',
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value < 0 || value >= sortedEntries.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          '${sortedEntries[value.toInt()].key}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
                    reservedSize: 30,
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    maxIncluded: false,
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      if (value == 0) return const SizedBox.shrink();
                      return Text(
                        value.toInt().toString(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval:
                    (maxProblems > 0) ? max(10, maxProblems / 5) : 10,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: Colors.grey[400],
                    strokeWidth: 1,
                  );
                },
              ),
              borderData: FlBorderData(
                show: true,
              ),
              barGroups: sortedEntries.asMap().entries.map((entry) {
                final index = entry.key;
                final data = entry.value;
                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: data.value.toDouble(),
                      color: rankColor,
                      width: 45,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: rankColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: rankColor.withOpacity(0.2)),
          ),
          child: Text(
            'Total Problems: $total',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.grey[200],
        appBar: AppBar(
          centerTitle: true,
          elevation: 15,
          shadowColor: Colors.black,
          title: const Text(
            'Statistics',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.purple,
          surfaceTintColor: Colors.purple,
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
          future: Future.wait([submissions, problems, contests, ratingHistory]),
          builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return LoadingCard(primaryColor: Colors.purple);
            }

            if (snapshot.hasError) {
              return _buildErrorWidget();
            }

            rankCounts = processSubmissions(
              snapshot.data![0] as List<dynamic>,
              snapshot.data![1] as Map<String, dynamic>,
            );

            return RefreshIndicator(
              color: Colors.black,
              backgroundColor: Colors.purple,
              onRefresh: _refreshData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildSubmissionStatsCard(
                          snapshot.data![0] as List<dynamic>),
                      const SizedBox(height: 16),
                      _buildRankStatsCard(),
                      const SizedBox(height: 16),
                      _buildContestPerformanceCard(
                          snapshot.data![3] as List<dynamic>),
                      const SizedBox(height: 16),
                      _buildTopicStatsCard(snapshot.data![0] as List<dynamic>),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            );
          },
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
              backgroundColor: Colors.purple,
            ),
            child: const Text('Retry', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }
}
