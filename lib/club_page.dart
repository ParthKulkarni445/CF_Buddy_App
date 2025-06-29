import 'package:acex/friends_landpage.dart';
import 'package:flutter/material.dart';
import 'package:acex/services.dart';
import 'package:acex/utils/loading_widget.dart';
import 'package:provider/provider.dart';
import 'package:acex/providers/user_provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';
import 'dart:io';

class ClubDetailPage extends StatefulWidget {
  final String clubId;
  final String clubName;

  const ClubDetailPage({
    super.key,
    required this.clubId,
    required this.clubName,
  });

  @override
  State<ClubDetailPage> createState() => _ClubDetailPageState();
}

class _ClubDetailPageState extends State<ClubDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool isLoading = true;
  final ClubService _clubService = ClubService();
  Club? _club;
  List<ClubDiscussion> _discussions = [];
  List<ClubProblem> _problems = [];
  List<Map<String, dynamic>> _leaderboard = [];
  bool _isLoadingDiscussions = true;
  bool _isLoadingProblems = true;
  bool _isLoadingLeaderboard = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (mounted) {
        setState(() {}); // This will rebuild the widget on tab change
      }
    });
    _fetchClubDetails();
  }

  Color getColorForRating(int? rating) {
    if (rating == null || rating <= 1199) return Colors.grey;
    if (rating <= 1399) return Colors.green;
    if (rating <= 1599) return Colors.cyan;
    if (rating <= 1899) return const Color.fromARGB(255, 11, 35, 243);
    if (rating <= 2099) return Colors.purple;
    if (rating <= 2299) return Colors.orange;
    if (rating <= 2399) return Colors.orangeAccent;
    if (rating <= 2599) return Colors.red;
    if (rating <= 2899) return Colors.redAccent;
    return const Color.fromARGB(255, 128, 0, 0); // Dark Red
  }

  Future<void> _fetchClubDetails() async {
    setState(() {
      isLoading = true;
    });

    try {
      final club = await _clubService.getClubById(context, widget.clubId);

      setState(() {
        _club = club;
        isLoading = false;
      });

      // Fetch tab data
      _fetchDiscussions();
      _fetchProblems();
      _fetchLeaderboard();
    } catch (e) {
      print('Error fetching club details: $e');
      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load club details: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _fetchDiscussions() async {
    setState(() {
      _isLoadingDiscussions = true;
    });

    try {
      final discussions =
          await _clubService.getClubDiscussions(context, widget.clubId);

      setState(() {
        _discussions = discussions;
        _isLoadingDiscussions = false;
      });
    } catch (e) {
      print('Error fetching discussions: $e');
      setState(() {
        _isLoadingDiscussions = false;
      });
    }
  }

  Future<void> _fetchProblems() async {
    setState(() {
      _isLoadingProblems = true;
    });

    try {
      final problems =
          await _clubService.getClubProblems(context, widget.clubId);

      setState(() {
        _problems = problems;
        _isLoadingProblems = false;
      });
    } catch (e) {
      print('Error fetching problems: $e');
      setState(() {
        _isLoadingProblems = false;
      });
    }
  }

  Future<void> _fetchLeaderboard() async {
    setState(() {
      _isLoadingLeaderboard = true;
    });

    try {
      final leaderboard =
          await _clubService.getClubLeaderboard(context, widget.clubId);

      setState(() {
        _leaderboard = leaderboard;
        _isLoadingLeaderboard = false;
      });
    } catch (e) {
      print('Error fetching leaderboard: $e');
      setState(() {
        _isLoadingLeaderboard = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.grey[200],
        body: isLoading
            ? LoadingCard(primaryColor: Colors.deepPurple)
            : NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    SliverAppBar(
                      expandedHeight: 200.0,
                      floating: false,
                      pinned: true,
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.deepPurple,
                      flexibleSpace: FlexibleSpaceBar(
                        titlePadding:
                            const EdgeInsets.only(left: 50, bottom: 14),
                        title: Text(
                          _club?.name ?? widget.clubName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                blurRadius: 4,
                                color: Colors.black38,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.left,
                        ),
                        background: Stack(
                          fit: StackFit.expand,
                          children: [
                            _club?.bannerUrl != null
                                ? ClipRRect(
                                    child: _club!.bannerUrl!.startsWith('http')
                                        ? Image.network(
                                            _club!.bannerUrl!,
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                            height: double.infinity,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              return Container(
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    begin: Alignment.topCenter,
                                                    end: Alignment.bottomCenter,
                                                    colors: [
                                                      Colors.deepPurple
                                                          .withOpacity(0.7),
                                                      Colors.deepPurple,
                                                    ],
                                                  ),
                                                ),
                                              );
                                            },
                                          )
                                        : Image.file(
                                            File(_club!.bannerUrl!),
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                            height: double.infinity,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              return Container(
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    begin: Alignment.topCenter,
                                                    end: Alignment.bottomCenter,
                                                    colors: [
                                                      Colors.deepPurple
                                                          .withOpacity(0.7),
                                                      Colors.deepPurple,
                                                    ],
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                  )
                                : Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.deepPurple.withOpacity(0.7),
                                          Colors.deepPurple,
                                        ],
                                      ),
                                    ),
                                  ),
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.5),
                                  ],
                                ),
                              ),
                            ),
                            if (_club != null)
                              Positioned(
                                top: 16,
                                left: 50,
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.6),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.people,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${_club!.memberCount} members',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.6),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            _club!.isPublic
                                                ? Icons.public
                                                : Icons.lock,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            _club!.isPublic
                                                ? 'Public'
                                                : 'Private',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      actions: [
                        if (_club != null && _isUserAdmin())
                          IconButton(
                            icon: const Icon(Icons.settings),
                            color: Colors.white,
                            onPressed: () {
                              // Club settings
                              _showClubSettingsDialog();
                            },
                          ),
                        PopupMenuButton<String>(
                          icon:
                              const Icon(Icons.more_vert, color: Colors.white),
                          onSelected: (value) {
                            if (value == 'leave' && _club != null) {
                              _showLeaveClubDialog();
                            }
                            else if (value == 'delete' && _club != null) {
                              _showDeleteClubDialog();
                            } else if (value == 'share') {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Share feature coming soon'),
                                ),
                              );
                            } else if (value == 'report') {
                              // Report club
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Report feature coming soon'),
                                ),
                              );
                            }
                          },
                          itemBuilder: (context) => [
                            if (_club != null &&
                                _isUserMember() &&
                                !_isUserCreator())
                              const PopupMenuItem(
                                value: 'leave',
                                child: Row(
                                  children: [
                                    Icon(Icons.exit_to_app, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Leave Club',
                                        style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                            if(_club != null &&
                                _isUserMember() &&
                                _isUserCreator())
                                const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Delete Club',
                                        style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                            const PopupMenuItem(
                              value: 'share',
                              child: Row(
                                children: [
                                  Icon(Icons.share, color: Colors.black),
                                  SizedBox(width: 8),
                                  Text('Share'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'report',
                              child: Row(
                                children: [
                                  Icon(Icons.flag, color: Colors.black),
                                  SizedBox(width: 8),
                                  Text('Report'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SliverPersistentHeader(
                      delegate: _SliverAppBarDelegate(
                        TabBar(
                          controller: _tabController,
                          indicatorColor: Colors.deepPurple,
                          labelColor: Colors.deepPurple,
                          unselectedLabelColor: Colors.grey,
                          tabs: const [
                            Tab(text: 'Discussions'),
                            Tab(text: 'Problems'),
                            Tab(text: 'Leaderboard'),
                          ],
                        ),
                      ),
                      pinned: true,
                    ),
                  ];
                },
                body: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildDiscussionsTab(),
                    _buildProblemsTab(),
                    _buildLeaderboardTab(),
                  ],
                ),
              ),
        floatingActionButton: _buildFloatingActionButton(),
      ),
    );
  }

  Widget _buildDiscussionsTab() {
    if (_isLoadingDiscussions) {
      return _buildLoadingShimmer();
    }

    if (_discussions.isEmpty) {
      return _buildEmptyState(
        icon: Icons.forum,
        title: 'No discussions yet',
        message: 'Be the first to start a discussion in this club!',
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchDiscussions,
      color: Colors.white,
      backgroundColor: Colors.deepPurple,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _discussions.length,
        itemBuilder: (context, index) {
          final discussion = _discussions[index];
          return _buildDiscussionCard(discussion);
        },
      ),
    );
  }

  Widget _buildDiscussionCard(ClubDiscussion discussion) {
    final formattedDate = DateFormat.yMMMd().format(discussion.createdAt);
    final currentUserId = Provider.of<UserProvider>(context, listen: false).user.id;
    final isCurrentUserAuthor = discussion.authorId == currentUserId;

    return Card(
      margin: EdgeInsets.only(bottom: 16, left: (isCurrentUserAuthor ? 32 : 0), right: (isCurrentUserAuthor ? 0 : 32)),
      color: (!isCurrentUserAuthor)?Colors.white:Colors.deepPurple[100],
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
          topLeft: isCurrentUserAuthor ? Radius.circular(12) : Radius.zero,
          topRight: isCurrentUserAuthor ? Radius.zero : Radius.circular(12), 
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: (isCurrentUserAuthor)?Colors.white:Colors.deepPurple[100],
                  radius: 20,
                  child: Text(
                    discussion.authorName
                        .substring(0, min(2, discussion.authorName.length))
                        .toUpperCase(),
                    style: TextStyle(
                      color: Colors.deepPurple,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        discussion.authorName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        formattedDate,
                        style: TextStyle(
                          fontSize: 12,
                          color: (isCurrentUserAuthor)? Colors.deepPurple[400]:Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              discussion.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            if(discussion.content.isNotEmpty) 
              const SizedBox(height: 8),
            if(discussion.content.isNotEmpty)
              Text(
                discussion.content,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 14,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(
                  Icons.access_time,
                  color: (isCurrentUserAuthor)? Colors.deepPurple:Colors.grey[800],
                  size: 15,
                ),
                const SizedBox(width: 4),
                Text(
                  DateFormat.jm().format(discussion.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: (isCurrentUserAuthor)? Colors.deepPurple:Colors.grey[800],
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildProblemsTab() {
    if (_isLoadingProblems) {
      return _buildLoadingShimmer();
    }

    if (_problems.isEmpty) {
      return _buildEmptyState(
        icon: Icons.code,
        title: 'No problems yet',
        message: 'Add coding problems for club members to solve!',
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchProblems,
      color: Colors.white,
      backgroundColor: Colors.deepPurple,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _problems.length,
        itemBuilder: (context, index) {
          final problem = _problems[index];
          return _buildProblemCard(problem);
        },
      ),
    );
  }

  Widget _buildProblemCard(ClubProblem problem) {
    final Color difficultyColor = _getDifficultyColor(problem.difficulty);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          // Open problem detail
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Problem detail coming soon'),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: difficultyColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      problem.difficulty.capitalize(),
                      style: TextStyle(
                        color: difficultyColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.star,
                          color: Colors.deepPurple,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${problem.points} pts',
                          style: const TextStyle(
                            color: Colors.deepPurple,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                problem.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                problem.description,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 14,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.check_circle, size: 16, color: Colors.green[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${problem.solvedCount} solved',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat.yMMMd().format(problem.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeaderboardTab() {
    if (_isLoadingLeaderboard) {
      return _buildLoadingShimmer();
    }

    if (_leaderboard.isEmpty) {
      return _buildEmptyState(
        icon: Icons.leaderboard,
        title: 'No leaderboard data yet',
        message: 'Solve problems to appear on the leaderboard!',
      );
    }

    final handle =
        Provider.of<UserProvider>(context, listen: false).user.handle;
    //print(_leaderboard);

    return RefreshIndicator(
      onRefresh: _fetchLeaderboard,
      color: Colors.white,
      backgroundColor: Colors.deepPurple,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _leaderboard.length,
        itemBuilder: (context, index) {
          final entry = _leaderboard[index];
          final isCurrentUser = entry['username'] == handle;
          final rank = index + 1;

          // Determine rank color
          Color rankColor = Colors.white;
          if (rank == 1) {
            rankColor = Colors.amber;
          } else if (rank == 2)
            rankColor = Colors.grey.shade400;
          else if (rank == 3) rankColor = Colors.brown.shade500;

          return Card(
            elevation: 2,
            color: Colors.white,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: isCurrentUser
                  ? BorderSide(color: Colors.deepPurple, width: 2)
                  : BorderSide.none,
            ),
            child: InkWell(
              onTap: () {
                if (isCurrentUser) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        FriendLandingPage(handle: entry['username']),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row: Avatar, Handle, Rank
                    Row(
                      children: [
                        // Avatar
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.deepPurple.shade300,
                                Colors.deepPurple.shade700,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.deepPurple.withOpacity(0.3),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: (entry['avatarUrl'] != null)
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    entry['avatarUrl'],
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Center(
                                  child: Text(
                                    entry['username']
                                        .substring(0, 1)
                                        .toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 20,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                        ),
                        const SizedBox(width: 12),

                        // Handle/Username
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry['username'],
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isCurrentUser
                                      ? Colors.deepPurple
                                      : Colors.black87,
                                ),
                              ),
                              Text(
                                entry['rank'],
                                style: TextStyle(
                                  fontSize: 16,
                                  color: getColorForRating(entry['rating']),
                                ),
                              ),
                              if (isCurrentUser)
                                const Row(
                                  children: [
                                    Icon(
                                      Icons.person,
                                      color: Colors.deepPurple,
                                      size: 16,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'You',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.deepPurple,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),

                        // Rank
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: rankColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: rankColor.withOpacity(0.5),
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '#$rank',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    // const Divider(height: 1),
                    // const SizedBox(height: 12),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        // Rating
                        Row(
                          children: [
                            Icon(Icons.star,
                                size: 16, color: Colors.deepPurple),
                            const SizedBox(width: 4),
                            Text(
                              'Rating',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[600]),
                            ),
                            const SizedBox(width: 7),
                            Text(
                              '${entry['rating']}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: getColorForRating(entry['rating']),
                              ),
                            ),
                          ],
                        ),
                        // Vertical divider
                        Container(
                          height: 24,
                          width: 1,
                          color: Colors.grey[400],
                        ),
                        // Problems solved
                        Row(
                          children: [
                            Icon(Icons.person,
                                size: 16, color: Colors.deepPurple),
                            const SizedBox(width: 4),
                            Text(
                              'Position',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[600]),
                            ),
                            const SizedBox(width: 7),
                            Text(
                              (_club!.admins.contains(entry['userId']))
                                  ? 'Admin'
                                  : 'Member',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[50]!,
      child: Column(
        children: [
          // Club info section
          // Container(
          //   color: Colors.white,
          //   padding: const EdgeInsets.all(16),
          //   child: Row(
          //     children: [
          //       // Club avatar placeholder
          //       Container(
          //         width: 60,
          //         height: 60,
          //         decoration: BoxDecoration(
          //           color: Colors.white,
          //           borderRadius: BorderRadius.circular(12),
          //         ),
          //       ),
          //       const SizedBox(width: 16),
          //       Expanded(
          //         child: Column(
          //           crossAxisAlignment: CrossAxisAlignment.start,
          //           children: [
          //             // Club name placeholder
          //             Container(
          //               width: 150,
          //               height: 20,
          //               decoration: BoxDecoration(
          //                 color: Colors.white,
          //                 borderRadius: BorderRadius.circular(4),
          //               ),
          //             ),
          //             const SizedBox(height: 8),
          //             // Club description placeholder
          //             Container(
          //               width: double.infinity,
          //               height: 16,
          //               decoration: BoxDecoration(
          //                 color: Colors.white,
          //                 borderRadius: BorderRadius.circular(4),
          //               ),
          //             ),
          //           ],
          //         ),
          //       ),
          //     ],
          //   ),
          // ),
          // const SizedBox(height: 16),
          // Content cards
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 5,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        // Card header
                        Container(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              // Avatar placeholder
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Title placeholder
                                    Container(
                                      width: 200,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    // Subtitle placeholder
                                    Container(
                                      width: 100,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Card content
                        Container(
                          height: 60,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: double.infinity,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                width: 200,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Card footer
                        Container(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                width: 60,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Container(
                                width: 60,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: Colors.deepPurple.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    if (_club == null) return const SizedBox.shrink();

    final user = Provider.of<UserProvider>(context, listen: false).user;
    final isMember = _club!.members.contains(user.id);

    if (!isMember) {
      return _buildJoinButton();
    }

    // Show different FAB based on current tab
    switch (_tabController.index) {
      case 0: // Discussions tab
        return FloatingActionButton(
          onPressed: () => _showNewDiscussionDialog(),
          backgroundColor: Colors.deepPurple,
          child: const Icon(Icons.add_comment, color: Colors.white),
        );
      case 1: // Problems tab
        if (_isUserAdmin()) {
          return FloatingActionButton(
            onPressed: () => _showAddProblemDialog(),
            backgroundColor: Colors.deepPurple,
            child: const Icon(Icons.add, color: Colors.white),
          );
        }
        break;
    }

    return const SizedBox.shrink();
  }

  Widget _buildJoinButton() {
    if (_club == null) return const SizedBox.shrink();

    final user = Provider.of<UserProvider>(context, listen: false).user;
    final isMember = _club!.members.contains(user.id);

    if (isMember) return const SizedBox.shrink();

    return FloatingActionButton.extended(
      onPressed: _joinClub,
      icon: const Icon(Icons.person_add),
      label: const Text('Join Club'),
      backgroundColor: Colors.deepPurple,
    );
  }

  void _showNewDiscussionDialog() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Discussion'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                maxLength: 100,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: contentController,
                decoration: const InputDecoration(
                  labelText: 'Content',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 5,
                maxLength: 500,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a title'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              Navigator.pop(context);
              _addDiscussion(
                titleController.text.trim(),
                contentController.text.trim(),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
            ),
            child: const Text('Post'),
          ),
        ],
      ),
    );
  }

  Future<void> _addDiscussion(String title, String content) async {
    try {
      final user = Provider.of<UserProvider>(context, listen: false).user;

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      await _clubService.addDiscussion(
        context: context,
        clubId: widget.clubId,
        title: title,
        content: content,
        authorName: user.handle,
      );

      // Hide loading indicator
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Discussion posted successfully'),
          backgroundColor: Colors.green,
        ),
      );

      _fetchDiscussions();
    } catch (e) {
      // Hide loading indicator
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to post discussion: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showAddProblemDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    String difficulty = 'medium';
    int points = 100;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Add Problem'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Problem Title',
                      border: OutlineInputBorder(),
                    ),
                    maxLength: 100,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Difficulty',
                      border: OutlineInputBorder(),
                    ),
                    value: difficulty,
                    items: const [
                      DropdownMenuItem(value: 'easy', child: Text('Easy')),
                      DropdownMenuItem(value: 'medium', child: Text('Medium')),
                      DropdownMenuItem(value: 'hard', child: Text('Hard')),
                      DropdownMenuItem(value: 'expert', child: Text('Expert')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          difficulty = value;
                          // Set default points based on difficulty
                          switch (value) {
                            case 'easy':
                              points = 50;
                              break;
                            case 'medium':
                              points = 100;
                              break;
                            case 'hard':
                              points = 150;
                              break;
                            case 'expert':
                              points = 200;
                              break;
                          }
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('Points: '),
                      Expanded(
                        child: Slider(
                          value: points.toDouble(),
                          min: 10,
                          max: 300,
                          divisions: 29,
                          label: points.toString(),
                          activeColor: Colors.deepPurple,
                          onChanged: (value) {
                            setState(() {
                              points = value.toInt();
                            });
                          },
                        ),
                      ),
                      Text(
                        points.toString(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Problem Statement',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 5,
                    maxLength: 500,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (titleController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a problem title'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  Navigator.pop(context);
                  _addProblem(
                    titleController.text.trim(),
                    descriptionController.text.trim(),
                    difficulty,
                    points,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Add'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _addProblem(
      String title, String description, String difficulty, int points) async {
    try {
      final user = Provider.of<UserProvider>(context, listen: false).user;

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      await _clubService.addProblem(
        context: context,
        clubId: widget.clubId,
        title: title,
        description: description,
        difficulty: difficulty,
        points: points,
      );

      // Hide loading indicator
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Problem added successfully'),
          backgroundColor: Colors.green,
        ),
      );

      _fetchProblems();
    } catch (e) {
      // Hide loading indicator
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add problem: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showClubSettingsDialog() {
    if (_club == null) return;

    final nameController = TextEditingController(text: _club!.name);
    final descriptionController =
        TextEditingController(text: _club!.description);
    bool isPublic = _club!.isPublic;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Club Settings'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Club Name',
                      border: OutlineInputBorder(),
                    ),
                    maxLength: 50,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 3,
                    maxLength: 200,
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Public Club'),
                    subtitle: const Text('Anyone can join a public club'),
                    value: isPublic,
                    activeColor: Colors.deepPurple,
                    onChanged: (value) {
                      setState(() {
                        isPublic = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (nameController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a club name'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  Navigator.pop(context);
                  // Update club settings
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Club settings updated successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDeleteClubDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Club'),
        content: const Text('Are you sure you want to delete this club?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteClub();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showLeaveClubDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Club'),
        content: const Text('Are you sure you want to leave this club?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _leaveClub();
            },
            child: const Text('Leave', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _joinClub() async {
    try {
      await _clubService.joinClub(context, widget.clubId);
      // Refresh club details after joining
      await _fetchClubDetails();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully joined the club'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to join club: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _leaveClub() async {
    try {
      await _clubService.leaveClub(context, widget.clubId);
      // Refresh club details after leaving
      await _fetchClubDetails();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully left the club'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to leave club: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteClub() async {
    try {
      await _clubService.deleteClub(context, widget.clubId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully deleted the club'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Close the club page
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete club: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  bool _isUserMember() {
    if (_club == null) return false;

    final userId = Provider.of<UserProvider>(context, listen: false).user.id;
    return _club!.members.contains(userId);
  }

  bool _isUserAdmin() {
    if (_club == null) return false;

    final userId = Provider.of<UserProvider>(context, listen: false).user.id;
    return _club!.admins.contains(userId);
  }

  bool _isUserCreator() {
    if (_club == null) return false;

    final userId = Provider.of<UserProvider>(context, listen: false).user.id;
    return _club!.createdBy == userId;
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return Colors.green;
      case 'medium':
        return Colors.blue;
      case 'hard':
        return Colors.orange;
      case 'expert':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  int min(int a, int b) {
    return a < b ? a : b;
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverAppBarDelegate(this.tabBar);

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: tabBar,
    );
  }

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  bool shouldRebuild(covariant _SliverAppBarDelegate oldDelegate) {
    return tabBar != oldDelegate.tabBar;
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
