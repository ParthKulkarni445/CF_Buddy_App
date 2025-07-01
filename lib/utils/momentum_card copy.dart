import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'dart:math';

class MomentumCard extends StatelessWidget {
  final List<dynamic> ratingHistory;
  final List<dynamic> submissions;
  final Map<String, dynamic> problemset;
  final int Rating;

  const MomentumCard({
    super.key,
    required this.ratingHistory,
    required this.submissions,
    required this.problemset,
    required this.Rating,
  });

  double _calculateMomentum() {
    double rawMomentum = 0;
    
    // Calculate contest performance (60% of momentum)
    if (ratingHistory.isNotEmpty) {
      final now = DateTime.now();
      final twoMonthsAgo = now.subtract(const Duration(days: 60));
      
      // Filter contests from last 2 months
      final recentContests = ratingHistory.where((contest) {
        final contestTime = DateTime.fromMillisecondsSinceEpoch(
            contest['ratingUpdateTimeSeconds'] * 1000);
        return contestTime.isAfter(twoMonthsAgo);
      }).toList();
      
      int totalDelta = 0;
      int positiveContests = 0;
      
      for (var contest in recentContests) {
        int delta = contest['newRating'] - contest['oldRating'];
        totalDelta += delta;
        if (delta > 0) positiveContests++;
      }
      
      // Calculate contest score
      double contestScore = 0;
      if (recentContests.isNotEmpty) {
        // Average delta impact
        double avgDelta = totalDelta.toDouble();
        contestScore += (avgDelta > 0) ? 6 * (1 - exp(-avgDelta / 100)) : 0; // Scale to 8 points max
        print('Average Delta: $avgDelta, Contest Score: $contestScore');
        
        // Consistency impact
        contestScore += (positiveContests / recentContests.length) * 2;
        print('Positive Contests: $positiveContests, Contest Score: $contestScore');
        
        // Frequency bonus (more contests = better)
        double frequencyBonus = (recentContests.length / max(10.0,recentContests.length.toDouble()))* 2;
        contestScore += frequencyBonus;
        print('Frequency Bonus: $frequencyBonus, Contest Score: $contestScore');
      }
      
      rawMomentum += contestScore; 
      print('Contest Score: $contestScore, Raw Momentum: $rawMomentum');
    }
    
    // Calculate recent practice (40% of momentum)
    if (submissions.isNotEmpty) {
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 10));
      
      int acceptedSubmissions = 0;
      int totalSubmissions = 0;
      Set<String> uniqueProblems = {};
      
      for (var submission in submissions) {
        final submissionTime = DateTime.fromMillisecondsSinceEpoch(
            submission['creationTimeSeconds'] * 1000);
        
        if (submissionTime.isAfter(weekAgo)) {
          totalSubmissions++;
          
          if (submission['verdict'] == 'OK') {
            acceptedSubmissions++;
            uniqueProblems.add('${submission['problem']['contestId']}${submission['problem']['index']}');
          }
        }
      }
      
      // Calculate practice score
      double practiceScore = 0;
      
      // Unique problems solved impact
      practiceScore += (uniqueProblems.length / max(40,uniqueProblems.length.toDouble()))*4.0; // Scale to 4 points max
      print('Unique Problems Solved: ${uniqueProblems.length}, Practice Score: $practiceScore');
      
      // Acceptance rate impact
      if (totalSubmissions > 0) {
        double acceptanceRate = acceptedSubmissions / totalSubmissions;
        practiceScore += acceptanceRate * 2;
        print('Acceptance Rate: ${acceptanceRate.toStringAsFixed(2)}, Practice Score: $practiceScore');
      }
      
      // Activity consistency (submissions spread over time)
      if (totalSubmissions > 0) {
        double activityBonus = min(totalSubmissions / max(120,totalSubmissions.toDouble()), 1.0) * 2;
        practiceScore += activityBonus;
        print('Activity Bonus: $activityBonus, Practice Score: $practiceScore');
      }
      double avgRating = 0;
      if (uniqueProblems.isNotEmpty) {
        int sumRatings = 0, count = 0;
        for (var pid in uniqueProblems) {
          // pid is e.g. "1234A"
          final m = RegExp(r'(\d+)([A-Za-z]\d*)').firstMatch(pid);
          if (m != null) {
            final cid = int.parse(m.group(1)!);
            final idx = m.group(2)!;
            print('Looking for problem $pid in problemset');
            
            final p = problemset['problems'].firstWhere((e) =>
              e['contestId'] == cid && e['index'] == idx,
              orElse: () => {'rating': null} // Fallback if not found
            );
            if (p['rating'] != null) sumRatings += (p['rating'] as int);
            count++;
          }
        }
        avgRating = sumRatings / count;
      }
      practiceScore += (avgRating >= 0.75*Rating) ? 2 : 0; // Bonus for solving high-rated problems
      
      rawMomentum += practiceScore ; // 40% weight
      print('Practice Score: $practiceScore, Raw Momentum: $rawMomentum');
    }
    
    
    // Ensure momentum is between 0 and 10, with single decimal precision
    return rawMomentum/2;
  }

  double min(double a, double b) => a < b ? a : b;
  double max(double a, double b) => a > b ? a : b;

  String _getMomentumDescription(double momentum) {
    if (momentum >= 9.5) return "Competitive Programming God!";
    if (momentum >= 9.0) return "Absolutely Unstoppable!";
    if (momentum >= 8.5) return "Elite Performance!";
    if (momentum >= 8.0) return "Outstanding work!";
    if (momentum >= 7.5) return "You're on fire!";
    if (momentum >= 7.0) return "Keep dominating!";
    if (momentum >= 6.0) return "Great momentum! You're crushing it!";
    if (momentum >= 5.0) return "Good progress! Stay consistent!";
    if (momentum >= 4.0) return "Steady pace! Push a bit harder!";
    if (momentum >= 3.0) return "Building momentum! More practice needed!";
    if (momentum >= 2.0) return "Getting started! Keep grinding!";
    if (momentum >= 1.0) return "Early stages! Don't give up!";
    return "Time to get back on track!";
  }

  Color _getMomentumColor(double momentum) {
    if (momentum >= 9.5) return const Color(0xFFFFD700); // Gold
    if (momentum >= 9.0) return const Color(0xFFFF1493); // Deep Pink
    if (momentum >= 8.5) return Colors.purple;
    if (momentum >= 8.0) return Colors.red;
    if (momentum >= 7.0) return Colors.orange;
    if (momentum >= 5.0) return Colors.blue;
    if (momentum >= 3.0) return Colors.green;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final momentum = _calculateMomentum();
    
    return Card(
      elevation: 4,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Momentum',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              // Info box explaining momentum criteria
              _buildMomentumInfoBox(),
              const SizedBox(height: 16),
              _buildMomentumMeter(momentum),
              const SizedBox(height: 8),
              // Momentum remarks below the graph
              Center(
                child: Text(
                  _getMomentumDescription(momentum),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: _getMomentumColor(momentum),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildMomentumStats(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMomentumInfoBox() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.teal.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.teal.shade700,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Momentum Calculation',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildCriteriaItem(
            '📊 Contest Performance (60%)',
            '• Rating changes in last 2 months\n• Consistency in positive results\n• Contest participation frequency',
          ),
          const SizedBox(height: 6),
          _buildCriteriaItem(
            '💻 Practice Activity (40%)',
            '• Unique problems solved (last 10 days)\n• Submission acceptance rate\n• Problem difficulty vs your rating',
          ),
        ],
      ),
    );
  }

  Widget _buildCriteriaItem(String title, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.teal.shade700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          description,
          style: TextStyle(
            fontSize: 11,
            color: Colors.teal.shade600,
            height: 1.3,
          ),
        ),
      ],
    );
  }

  Widget _buildMomentumMeter(double momentum) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        
        return SizedBox(
          width: availableWidth,
          height: 250,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Syncfusion Radial Gauge
              Expanded(
                child: SfRadialGauge(
                  axes: <RadialAxis>[
                    RadialAxis(
                      minimum: 0,
                      maximum: 10,
                      startAngle: 180,
                      endAngle: 0,
                      showLabels: true,
                      showLastLabel: true,
                      showTicks: true,
                      radiusFactor: 1,
                      canScaleToFit: true,
                      axisLineStyle: AxisLineStyle(
                        thickness: 0.2,
                        color: Colors.grey[300],
                        cornerStyle: CornerStyle.bothCurve,
                        thicknessUnit: GaugeSizeUnit.factor,
                      ),
                      // Add ranges to show difficulty levels
                      ranges: <GaugeRange>[
                        GaugeRange(
                          startValue: 0,
                          endValue: 5,
                          color: Colors.transparent,
                          startWidth: 0.05,
                          endWidth: 0.05,
                          sizeUnit: GaugeSizeUnit.factor,
                        ),
                        GaugeRange(
                          startValue: 5,
                          endValue: 8,
                          color:  Colors.transparent,
                          startWidth: 0.05,
                          endWidth: 0.05,
                          sizeUnit: GaugeSizeUnit.factor,
                        ),
                        GaugeRange(
                          startValue: 8,
                          endValue: 10,
                          color: Colors.transparent,
                          startWidth: 0.05,
                          endWidth: 0.05,
                          sizeUnit: GaugeSizeUnit.factor,
                        ),
                      ],
                      pointers: <GaugePointer>[
                        RangePointer(
                          value: momentum,
                          width: 0.2,
                          cornerStyle: CornerStyle.startCurve,
                          sizeUnit: GaugeSizeUnit.factor,
                          color: _getMomentumColor(momentum),
                          enableAnimation: true,
                          animationDuration: 2000,
                          animationType: AnimationType.easeInCirc,
                        ),
                      ],
                      annotations: <GaugeAnnotation>[
                        GaugeAnnotation(
                          widget: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                momentum.toStringAsFixed(1),
                                style: TextStyle(
                                  fontSize: 35,
                                  fontWeight: FontWeight.bold,
                                  color: _getMomentumColor(momentum),
                                ),
                              ),
                              Text(
                                '/ 10.0',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          angle: 90,
                          positionFactor: 0,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }
    );
  }

  Widget _buildMomentumStats() {
    final now = DateTime.now();
    final twoMonthsAgo = now.subtract(const Duration(days: 60));
    final weekAgo = now.subtract(const Duration(days: 10));
    
    // Contest stats (from last 2 months)
    final recentContests = ratingHistory.where((contest) {
      final contestTime = DateTime.fromMillisecondsSinceEpoch(
          contest['ratingUpdateTimeSeconds'] * 1000);
      return contestTime.isAfter(twoMonthsAgo);
    }).toList();
    
    num contestDelta = 0;
    for (var contest in recentContests) {
      contestDelta += contest['newRating'] - contest['oldRating'];
    }
    
    // Submission stats (from last 2 months)
    int periodSubmissions = 0;
    int acceptedSubmissions = 0;
    Set<String> uniqueProblems = {};
    
    for (var submission in submissions) {
      final submissionTime = DateTime.fromMillisecondsSinceEpoch(
          submission['creationTimeSeconds'] * 1000);
      
      if (submissionTime.isAfter(weekAgo)) {
        periodSubmissions++;
        
        if (submission['verdict'] == 'OK') {
          acceptedSubmissions++;
          uniqueProblems.add('${submission['problem']['contestId']}${submission['problem']['index']}');
        }
      }
    }
    double avgRating = 0;
    if (uniqueProblems.isNotEmpty) {
      int sumRatings = 0, count = 0;
      for (var pid in uniqueProblems) {
        // pid is e.g. "1234A"
        final m = RegExp(r'(\d+)([A-Za-z]\d*)').firstMatch(pid);
        if (m != null) {
          final cid = int.parse(m.group(1)!);
          final idx = m.group(2)!;
          final p = problemset['problems'].firstWhere((e) =>
            e['contestId'] == cid && e['index'] == idx,
            orElse: () => {'rating': null} // Fallback if not found
          );
          if (p['rating'] != null) sumRatings += (p['rating'] as int);
          count++;
        }
      }
      avgRating = sumRatings / count;
    }
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Divider(),
        _buildStatItem(
          FontAwesomeIcons.trophy, 
          'Contests (2m): ${recentContests.length}', 
          contestDelta >= 0 ? '+$contestDelta' : '$contestDelta',
          contestDelta >= 0 ? Colors.green : Colors.red,
        ),
        _buildStatItem(
          FontAwesomeIcons.code, 
          'Problems Solved (10d)', 
          uniqueProblems.length.toString(),
          Colors.black
        ),
        _buildStatItem(
          FontAwesomeIcons.check, 
          'Acceptance Rate (10d)', 
          periodSubmissions > 0 
              ? '${(acceptedSubmissions / periodSubmissions * 100).toStringAsFixed(1)}%' 
              : 'N/A',
          Colors.black
        ),
        _buildStatItem(
          FontAwesomeIcons.star,
          'Avg Problem Rating',
          uniqueProblems.isNotEmpty
            ? avgRating.toStringAsFixed(0)
            : 'N/A',
          Colors.black,
        ),
      ],
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value, Color color) {
    return LayoutBuilder(
      builder: (context,constraints) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              FaIcon(icon, size: constraints.maxWidth*0.07, color: Colors.grey[600]),
              SizedBox(
                width: constraints.maxWidth * 0.88,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(label, style: TextStyle(color: Colors.grey[600])),
                    Text(value.length > 19 ? '${value.substring(0, 19)}...' : value,
                      style: TextStyle(fontWeight: FontWeight.bold, color: color),
                      maxLines: 1,),
                  ],
                ),
              ),
            ],
          ),
        );
      }
    );
  }
}