import 'dart:io';


import 'package:acex/club_page.dart';
import 'package:acex/friends_landpage.dart';
import 'package:acex/services.dart';
import 'package:acex/settings.dart';
import 'package:acex/utils/loading_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:acex/providers/user_provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class SocialPage extends StatefulWidget {
  const SocialPage({super.key});

  @override
  State<SocialPage> createState() => _SocialPageState();
}

class _SocialPageState extends State<SocialPage>
    with SingleTickerProviderStateMixin {
  final storage = const FlutterSecureStorage();
  bool isLoading = true;
  bool hasCredentials = false;
  late String _handle;
  late TabController _tabController;
  final ClubService _clubService = ClubService();
  List<Club> _userClubs = [];
  List<Club> _popularClubs = [];
  bool _isLoadingClubs = true;
  final TextEditingController _clubsSearchController = TextEditingController();
  final ValueNotifier<String> _clubsSearchQueryNotifier = ValueNotifier<String>('');
  final FocusNode _clubsSearchFocusNode = FocusNode();
  List<Club> _searchResults = [];

  // Add these controllers as class variables
  final ValueNotifier<String> _friendsSearchQueryNotifier = ValueNotifier<String>('');
  final TextEditingController _friendsSearchController = TextEditingController();
  final FocusNode _friendsSearchFocusNode = FocusNode();
  
  // Add this to cache the friends future
  late Future<List<List<dynamic>>> _friendsFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      // This triggers a rebuild when tab changes to show/hide FAB
      setState(() {});
    });
    _checkCredentials();
  }

  void _initializeFriendsFuture() {
    _friendsFuture = Future.wait([
      ApiService().fetchFriendsInfo(_handle, true), // Online friends
      ApiService().fetchFriendsInfo(_handle, false), // All friends
    ]);
  }

  Future<void> _refreshFriends() async {
    setState(() {
      _initializeFriendsFuture();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _clubsSearchController.dispose();
    _clubsSearchQueryNotifier.dispose();
    _clubsSearchFocusNode.dispose();
    _friendsSearchController.dispose();
    _friendsSearchQueryNotifier.dispose();
    _friendsSearchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _checkCredentials() async {
    final apiKey = await storage.read(key: 'api_key_$_handle');
    final apiSecret = await storage.read(key: 'api_secret_$_handle');

    if (apiKey != null && apiSecret != null) {
      final user = Provider.of<UserProvider>(context, listen: false).user;
      _handle = user.handle;
      _initializeFriendsFuture(); // Initialize the friends future
      _fetchClubs();
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

  Future<void> _fetchClubs() async {
    setState(() {
      _isLoadingClubs = true;
    });
    try {
      final user = Provider.of<UserProvider>(context, listen: false).user;
      final userClubs = await _clubService.getUserClubs(context, user.id);
      final allClubs = await _clubService.getAllClubs(context);
      // Sort popular clubs by member count
      final popularClubs = List<Club>.from(allClubs)
        ..sort((a, b) => b.memberCount.compareTo(a.memberCount));

      setState(() {
        _userClubs = userClubs;
        _popularClubs = popularClubs.take(5).toList(); // Top 5 popular clubs
        _isLoadingClubs = false;
      });
    } catch (e) {
      print('Error fetching clubs: $e');
      setState(() {
        _isLoadingClubs = false;
      });
    }
  }

 // Fix for the club search functionality
Future<void> _searchClubs(String query) async {
  try {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }
    final results = await _clubService.searchClubs(context, query);
    setState(() {
      _searchResults = results;
    });
  } catch (e) {
    print('Error searching clubs: $e');
  }
}

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey[300],
        appBar: _buildAppBar(),
        body: LoadingCard(primaryColor: Colors.blue),
      );
    }

    if (!hasCredentials) {
      return Scaffold(
        backgroundColor: Colors.grey[300],
        appBar: _buildAppBar(),
        body: _buildNoCredentialsMessage(),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: _buildAppBar(),
      floatingActionButton: _tabController.index == 1 ? Padding(
        padding: const EdgeInsets.only(bottom: 100), // Add padding to lift FAB above bottom nav bar
        child: FloatingActionButton(
          onPressed: _showCreateClubDialog,
          backgroundColor: Colors.blue,
          elevation: 4,
          child: const Icon(
            Icons.add,
            color: Colors.white,
          ),
        ),
      ) : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: Column(
        children: [
          Expanded(
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 1,
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: Colors.blue,
                    indicatorWeight: 3,
                    labelColor: Colors.blue,
                    unselectedLabelColor: Colors.grey,
                    tabs: const [
                      Tab(text: 'Friends'),
                      Tab(text: 'Clubs'),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildFriendsTabContent(),
                      _buildClubsTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendsTabContent() {
    print("Building friends tab content for $_handle on time ${DateTime.now()}");
    return FutureBuilder<List<List<dynamic>>>(
      future: _friendsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return LoadingCard(primaryColor: Colors.blue);
        }

        if (snapshot.hasError || snapshot.data == null) {
          return _buildErrorWidget();
        }

        final onlineFriendsList = snapshot.data![0];
        final allFriendsList = snapshot.data![1];

        // Sort by rating (highest first)
        onlineFriendsList
            .sort((a, b) => (b['rating'] ?? 0).compareTo(a['rating'] ?? 0));
        allFriendsList
            .sort((a, b) => (b['rating'] ?? 0).compareTo(a['rating'] ?? 0));

        // Get offline friends (all friends minus online friends)
        final offlineFriendsList = allFriendsList
            .where((friend) => !onlineFriendsList
                .any((online) => online['handle'] == friend['handle']))
            .toList();

        return Column(
          children: [
            // Include the search bar from FriendsPage
            Card(
              elevation: 7,
              color: Colors.white,
              margin: const EdgeInsets.only(left:16, right:16, top:16, bottom:16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: TextField(
                  cursorColor: Colors.blue,
                  controller: _friendsSearchController,
                  focusNode: _friendsSearchFocusNode,
                  style: const TextStyle(
                    decorationThickness: 0,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search friends...',
                    border: InputBorder.none,
                    icon: const Icon(Icons.search, color: Colors.grey),
                    contentPadding: const EdgeInsets.only(top: 10),
                    suffixIcon: ValueListenableBuilder<String>(
                      valueListenable: _friendsSearchQueryNotifier,
                      builder: (context, value, child) {
                        return value.isNotEmpty
                            ? IconButton(
                                icon:
                                    const Icon(Icons.clear, color: Colors.grey),
                                onPressed: () {
                                  _friendsSearchController.clear();
                                  _friendsSearchQueryNotifier.value = '';
                                },
                              )
                            : const SizedBox.shrink();
                      },
                    ),
                  ),
                  onChanged: (value) {
                    _friendsSearchQueryNotifier.value = value.toLowerCase();
                  },
                ),
              ),
            ),

            // Rest of the friends content in a scrollable list
            Expanded(
              child: ValueListenableBuilder<String>(
                valueListenable: _friendsSearchQueryNotifier,
                builder: (context, searchQuery, child) {
                  // Filter friends based on search query
                  final filteredOnlineFriends = onlineFriendsList
                      .where((friend) => friend['handle']
                          .toString()
                          .toLowerCase()
                          .contains(searchQuery))
                      .toList();
                  final filteredOfflineFriends = offlineFriendsList
                      .where((friend) => friend['handle']
                          .toString()
                          .toLowerCase()
                          .contains(searchQuery))
                      .toList();

                  // Handle empty states
                  if (onlineFriendsList.isEmpty && allFriendsList.isEmpty) {
                    return Center(child: _buildEmptyFriendsState());
                  }
                  if (filteredOnlineFriends.isEmpty &&
                      filteredOfflineFriends.isEmpty &&
                      searchQuery.isNotEmpty) {
                    return Center(child: _buildNoSearchResults(searchQuery));
                  }

                  return RefreshIndicator(
                    color: Colors.black,
                    backgroundColor: Colors.blue,
                    onRefresh: _refreshFriends,
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        // Online friends first
                        ...filteredOnlineFriends
                            .map((friend) => _buildFriendCard(friend, true)),
                        // Then offline friends
                        ...filteredOfflineFriends
                            .map((friend) => _buildFriendCard(friend, false)),
                        const SizedBox(height: 60), // Bottom padding
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyFriendsState() {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 100,
              color: Colors.blue,
            ),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'No friends found for $_handle',
                style: const TextStyle(
                  fontSize: 22,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Add friends on Codeforces to see them here',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                setState(() {});
              },
              style: ElevatedButton.styleFrom(
                elevation: 6,
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text(
                'Retry',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

// No search results state
  Widget _buildNoSearchResults(String searchQuery) {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 100,
              color: Colors.blue,
            ),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'No friends found matching "$searchQuery"',
                style: const TextStyle(
                  fontSize: 22,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Try a different search term or add friends on Codeforces',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            )
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
            size: 150,
          ),
          const SizedBox(height: 18),
          const Text(
            'Something went wrong',
            style: TextStyle(
              fontSize: 22,
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: () {
              setState(() {});
            },
            style: ElevatedButton.styleFrom(
              elevation: 6,
              backgroundColor: Colors.blue,
            ),
            child: const Text(
              'Retry',
              style: TextStyle(color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  // Friend card building logic from FriendsPage
  Widget _buildFriendCard(Map<String, dynamic> friend, bool isOnline) {
    final handle = friend['handle'] as String;
    final titlePhoto = friend['titlePhoto'] as String?;
    final rating = friend['rating'] as int?;
    final ratingColor = _getColorForRating(rating);

    final List<Color> avatarColors = [
      Colors.red[400]!,
      Colors.yellow[600]!,
      Colors.green[400]!,
      Colors.blue[400]!,
      Colors.purple[400]!,
    ];

    return Card(
      elevation: 7,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: (isOnline) ? Colors.green[50] : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: isOnline
              ? Border.all(
                  color: Colors.green[400]!,
                  width: 1.5,
                )
              : null,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            if(handle == _handle)return;
            FocusManager.instance.primaryFocus?.unfocus();

            Future.delayed(const Duration(milliseconds: 100), () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FriendLandingPage(handle: handle),
                ),
              );
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // User avatar or title photo
                titlePhoto != null && titlePhoto.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          titlePhoto,
                          width: 55,
                          height: 55,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            // Fallback to initials if image fails to load
                            return _buildInitialsAvatar(handle, avatarColors);
                          },
                        ),
                      )
                    : _buildInitialsAvatar(handle, avatarColors),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        handle,
                        style: TextStyle(
                          color: ratingColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (rating != null)
                        Row(
                          children: [
                            Text(
                              'Rating:',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              rating.toString(),
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      if (isOnline)
                        Text(
                          'Online',
                          style: TextStyle(
                            color: Colors.green[400],
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.grey, size: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

// Helper method to build initials avatar
  Widget _buildInitialsAvatar(String handle, List<Color> avatarColors) {
    final colorIndex = handle.hashCode % avatarColors.length;
    final avatarColor = avatarColors[colorIndex];

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: avatarColor,
        boxShadow: [
          BoxShadow(
            color: avatarColor.withOpacity(0.5),
            blurRadius: 4,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Center(
        child: Text(
          (handle.length > 2)
              ? handle.substring(0, 2).toUpperCase()
              : handle.toUpperCase(),
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getColorForRating(int? rating) {
    if (rating == null || rating <= 1199) return Colors.grey;
    if (rating <= 1399) return Colors.green;
    if (rating <= 1599) return Colors.cyan;
    if (rating <= 1899) return const Color.fromARGB(255, 11, 35, 243);
    if (rating <= 2099) return Colors.purple;
    if (rating <= 2299) return Colors.orange;
    if (rating <= 2399) return Colors.orangeAccent;
    if (rating <= 2599) return Colors.red;
    if (rating <= 2899) return Colors.redAccent;
    return const Color.fromARGB(255, 128, 0, 0);
  }

  Widget _buildClubsTab() {
    if (_isLoadingClubs) {
      return _buildLoadingClubs();
    }

    return Column(
      children: [
        // Search bar with same styling as friends search
        Card(
          elevation: 7,
          color: Colors.white,
          margin: const EdgeInsets.only(left:16, right:16, top:16, bottom:16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              cursorColor: Colors.blue,
              controller: _clubsSearchController,
              focusNode: _clubsSearchFocusNode,
              style: const TextStyle(
                decorationThickness: 0,
              ),
              decoration: InputDecoration(
                hintText: 'Search clubs...',
                border: InputBorder.none,
                icon: const Icon(Icons.search, color: Colors.grey),
                contentPadding: const EdgeInsets.only(top: 10),
                suffixIcon: ValueListenableBuilder<String>(
                  valueListenable: _clubsSearchQueryNotifier,
                  builder: (context, value, child) {
                    return value.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            _clubsSearchController.clear();
                            _clubsSearchQueryNotifier.value = '';
                            _searchClubs('');
                          },
                        )
                      : const SizedBox.shrink();
                  },
                ),
              ),
              onChanged: (value) {
                _clubsSearchQueryNotifier.value = value.toLowerCase();
                _searchClubs(value);
              },
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _fetchClubs,
            color: Colors.black,
            backgroundColor: Colors.blue,
            child: ValueListenableBuilder<String>(
              valueListenable: _clubsSearchQueryNotifier,
              builder: (context, searchQuery, child) {
                if (searchQuery.isEmpty) {
                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Your Clubs',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _userClubs.isEmpty
                              ? _buildEmptyClubsMessage()
                              : Column(
                                  children: _userClubs
                                      .map((club) =>
                                          _buildClubCard(club, showJoinedTag: false))
                                      .toList(),
                                ),
                          const SizedBox(height: 24),
                          const Text(
                            'Popular Clubs',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Column(
                            children:
                                _popularClubs.map((club) => _buildClubCard(club)).toList(),
                          ),
                          const SizedBox(height: 80), // Space for FAB
                        ],
                      ),
                    ),
                  );
                }

                // Show search results
                if (_searchResults.isEmpty) {
                  return Center(
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 100,
                            color: Colors.blue,
                          ),
                          const SizedBox(height: 18),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Text(
                              'No clubs found matching "$searchQuery"',
                              style: const TextStyle(
                                fontSize: 22,
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Text(
                              'Try a different search term or browse popular clubs',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  );
                }

                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: _searchResults.map((club) => _buildClubCard(club)).toList(),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingClubs() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[350]!,
      highlightColor: Colors.grey[50]!,
      child: Column(
        children: [
          // Search bar shimmer
          Card(
            elevation: 7,
            color: Colors.white,
            margin: const EdgeInsets.only(left:16, right:16, top:16, bottom:16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // "Your Clubs" section
                  Container(
                    width: 100,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Club cards
                  ...List.generate(2, (index) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  )),
                  const SizedBox(height: 24),
                  // "Popular Clubs" section
                  Container(
                    width: 120,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Popular club cards
                  ...List.generate(3, (index) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyClubsMessage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.group_add,
            size: 150,
            color: Colors.blue,
          ),
          const SizedBox(height: 18),
          const Text(
            'No clubs found',
            style: TextStyle(
              fontSize: 22,
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Join a club to collaborate with other coders\nand participate in discussions',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  _fetchClubs();
                },
                style: ElevatedButton.styleFrom(
                  elevation: 6,
                  backgroundColor: Colors.blue,
                ),
                child: const Text(
                  'Refresh',
                  style: TextStyle(color: Colors.black),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () {
                  _showCreateClubDialog();
                },
                icon: const Icon(Icons.add, color: Colors.black),
                label: const Text('Create Club', style: TextStyle(color: Colors.black)),
                style: ElevatedButton.styleFrom(
                  elevation: 6,
                  backgroundColor: Colors.blue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
Widget _buildClubCard(Club club, {bool showJoinedTag = true}) {
  final bool isUserMember = club.members
      .contains(Provider.of<UserProvider>(context, listen: false).user.id);
  final Color clubColor = _getClubColor(club.name);
  print(club.bannerUrl);
  return Card(
    elevation: 4, // Increased elevation for better shadow
    color: Colors.white,
    margin: const EdgeInsets.only(bottom: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16), // Increased border radius
      side: BorderSide(
        color: isUserMember ? clubColor.withOpacity(0.3) : Colors.transparent,
        width: 1.5,
      ),
    ),
    child: InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ClubDetailPage(
              clubId: club.id,
              clubName: club.name,
            ),
          ),
        ).then((_) => _fetchClubs());
      },
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Improved club avatar
            Container(
              width: 70, // Slightly larger
              height: 70, // Slightly larger
              decoration: BoxDecoration(
                color: clubColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: clubColor.withOpacity(0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: clubColor.withOpacity(0.1),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: club.bannerUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        club.bannerUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Text(
                              club.name
                                  .substring(0, min(2, club.name.length))
                                  .toUpperCase(),
                              style: TextStyle(
                                color: clubColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 24, // Larger font
                              ),
                            ),
                          );
                        },
                      ),
                    )
                  : Center(
                      child: Text(
                        club.name
                            .substring(0, min(2, club.name.length))
                            .toUpperCase(),
                        style: TextStyle(
                          color: clubColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 24, // Larger font
                        ),
                      ),
                    ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          club.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.left,
                        ),
                      ),
                      if (isUserMember && showJoinedTag)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4), // Larger padding
                          decoration: BoxDecoration(
                            color: clubColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: clubColor.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            'Joined',
                            style: TextStyle(
                              color: clubColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6), // Slightly more spacing
                  Text(
                    club.description,
                    style: TextStyle(
                      color: Colors.grey[700], // Slightly darker for better readability
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10), // More spacing
                  // Improved stats row with better visual separation
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.people,
                          size: 16,
                          color: clubColor.withOpacity(0.8),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${club.memberCount} members',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          club.isPublic ? Icons.public : Icons.lock,
                          size: 16,
                          color: club.isPublic ? Colors.green[600] : Colors.orange[700],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          club.isPublic ? 'Public' : 'Private',
                          style: TextStyle(
                            color: club.isPublic ? Colors.green[600] : Colors.orange[700],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (!isUserMember && club.isPublic)
              ElevatedButton(
                onPressed: () => _joinClub(club.id),
                style: ElevatedButton.styleFrom(
                  backgroundColor: clubColor,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  minimumSize: const Size(0, 40),
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  'Join',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
  Future<void> _joinClub(String clubId) async {
    try {
      final user = Provider.of<UserProvider>(context, listen: false).user;
      await _clubService.joinClub(context, clubId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Successfully joined the club'),
          backgroundColor: Colors.green,
        ),
      );

      _fetchClubs();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to join club: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Color _getClubColor(String clubName) {
    return Colors.blue;
  }

  int min(int a, int b) {
    return a < b ? a : b;
  }

  Widget _buildFeatureItem(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: Colors.blue,
            size: 20,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  void _showCreateClubDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    String? bannerUrl;
    bool isPublic = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Icon(Icons.group_add, size: 28, color: Colors.blue),
                        SizedBox(width: 12),
                        Text(
                          'Create New Club',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.left,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Banner Image Upload
                    GestureDetector(
                      onTap: () async {
                        final ImagePicker picker = ImagePicker();
                        final XFile? image = await picker.pickImage(
                          source: ImageSource.gallery,
                          maxWidth: 1920,
                          maxHeight: 1080,
                          imageQuality: 85,
                        );

                        if (image != null) {
                          // Here you would typically upload the image to your storage service
                          // and get back a URL. For now, we'll just store the local path
                          setState(() {
                            bannerUrl = image.path;
                            print(bannerUrl);
                          });
                        }
                      },
                      child: Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[400]!),
                        ),
                        child: bannerUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  File(bannerUrl!),
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_photo_alternate_outlined,
                                    size: 40,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Add Banner Image',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Club Name Field
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Club Name',
                        hintText: 'Enter club name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.group),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                      maxLength: 50,
                    ),
                    const SizedBox(height: 16),

                    // Description Field
                    TextField(
                      controller: descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        hintText: 'Enter club description',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.description),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                      maxLines: 3,
                      maxLength: 200,
                    ),
                    const SizedBox(height: 16),

                    // Privacy Setting
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: SwitchListTile(
                        title: const Text(
                          'Public Club',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Anyone can join a public club',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        value: isPublic,
                        activeColor: Colors.blue,
                        onChanged: (value) {
                          setState(() {
                            isPublic = value;
                          });
                        },
                        secondary: Icon(
                          isPublic ? Icons.public : Icons.lock,
                          color: isPublic ? Colors.blue : Colors.grey[600],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Action Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
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
                            print("Calling _createClub");
                            _createClub(
                              nameController.text.trim(),
                              descriptionController.text.trim(),
                              isPublic,
                              bannerUrl,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add),
                              SizedBox(width: 8),
                              Text(
                                'Create Club',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
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

  Future<void> _createClub(
  String name,
  String description,
  bool isPublic,
  [String? bannerUrl]
) async {
  final BuildContext dialogContext = context;
  
  try {
    showDialog(
      context: dialogContext,
      barrierDismissible: false,
      builder: (_) => WillPopScope(
        onWillPop: () async => false,
        child: const Center(child: CircularProgressIndicator()),
      ),
    );

    String? uploadedBannerUrl;
    if (bannerUrl != null) {
      final file = File(bannerUrl);
      final fileName = 'club_banners/${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      final ref = FirebaseStorage.instance.ref().child(fileName);

      // === FIXED upload logic ===
      final uploadTask = ref.putFile(file);
      final TaskSnapshot snapshot = await uploadTask;
      uploadedBannerUrl = await snapshot.ref.getDownloadURL();
    }

    await _clubService.createClub(
      context: dialogContext,
      name: name,
      description: description,
      isPublic: isPublic,
      bannerUrl: uploadedBannerUrl,
    );

    if (dialogContext.mounted) Navigator.of(dialogContext).pop();
    if (dialogContext.mounted) {
      ScaffoldMessenger.of(dialogContext).showSnackBar(
        const SnackBar(
          content: Text('Club created successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }

    await _fetchClubs();
  } catch (e) {
    if (dialogContext.mounted) Navigator.of(dialogContext).pop();
    if (dialogContext.mounted) {
      ScaffoldMessenger.of(dialogContext).showSnackBar(
        SnackBar(
          content: Text('Failed to create club: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}


  Widget _buildNoCredentialsMessage() {
    return Center(
      child: Card(
        color: Colors.white,
        elevation: 10,
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
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
                'Please go to Settings and enter your API credentials to access social features.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    elevation: 5),
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const SettingsPage()));
                },
                child: const Text('Go to Settings'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      centerTitle: true,
      elevation: 0,
      title: const Text(
        'Social',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: Colors.blue,
      actions: [
        PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'settings') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            } else if (value == 'signout') {
              final authService = AuthService();
              authService.signOut(context);
            }
          },
          icon: const Icon(Icons.more_vert, color: Colors.white, size: 24),
          color: Colors.white,
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'settings',
              child: Row(
                children: [
                  const Icon(Icons.settings, color: Colors.black),
                  const SizedBox(width: 8),
                  const Text('Settings', style: TextStyle(color: Colors.black)),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'signout',
              child: Row(
                children: [
                  const Icon(Icons.logout, color: Colors.black),
                  const SizedBox(width: 8),
                  const Text('Sign Out', style: TextStyle(color: Colors.black)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
