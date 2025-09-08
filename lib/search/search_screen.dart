// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:tiktok/search/recent_search_service.dart';
// import 'package:tiktok/search/search_service.dart';
// // ignore: unused_import
// import 'package:shared_preferences/shared_preferences.dart';

// class SearchScreen extends StatefulWidget {
//   const SearchScreen({Key? key}) : super(key: key);

//   @override
//   _SearchScreenState createState() => _SearchScreenState();
// }

// class _SearchScreenState extends State<SearchScreen> {
//   final TextEditingController _searchController = TextEditingController();
//   final FocusNode _searchFocusNode = FocusNode();
//   final RecentSearchService _recentSearchService = RecentSearchService();
//   final SearchService _searchService = SearchService();
//   String _searchQuery = '';
//   bool _showRecentSearches = true;
//   List<String> _recentSearches = [];

//   // Mock trending topics
//   final List<Map<String, dynamic>> _trendingTopics = [
//     {'title': 'FlutterDev', 'views': '5.4M'},
//     {'title': 'Coding', 'views': '12.2M'},
//     {'title': 'Recipe', 'views': '8.7M'},
//     {'title': 'Workout', 'views': '15.1M'},
//     {'title': 'Travel', 'views': '20.3M'},
//   ];

//   int _selectedTabIndex = 0;
//   final List<String> _searchTabs = ['Top', 'Users', 'Sounds', 'Hashtags'];

//   @override
//   void initState() {
//     super.initState();
//     _searchController.addListener(() {
//       setState(() {
//         _searchQuery = _searchController.text;
//         _showRecentSearches = _searchQuery.isEmpty;
//       });
//     });

//     _loadRecentSearches();
//   }

//   // Load recent searches from storage
//   void _loadRecentSearches() async {
//     final searches = await _recentSearchService.getRecentSearches();
//     setState(() {
//       _recentSearches = searches;
//     });
//   }

//   // Save a search term
//   void _saveSearchTerm(String searchTerm) {
//     if (searchTerm.trim().isNotEmpty) {
//       _recentSearchService.saveSearchTerm(searchTerm);
//       _loadRecentSearches(); // Reload the list
//     }
//   }

//   // Remove a search term
//   void _removeSearchTerm(String searchTerm) {
//     _recentSearchService.removeSearchTerm(searchTerm);
//     _loadRecentSearches(); // Reload the list
//   }

//   // Clear all recent searches
//   void _clearAllRecentSearches() async {
//     await _recentSearchService.clearAllRecentSearches();
//     _loadRecentSearches(); // Reload the list
//   }

//   @override
//   void dispose() {
//     _searchController.dispose();
//     _searchFocusNode.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       appBar: AppBar(
//         backgroundColor: Colors.black,
//         automaticallyImplyLeading: false,
//         title: _buildSearchBar(),
//       ),
//       body: _showRecentSearches
//           ? _buildRecentSearches()
//           : _buildSearchResults(),
//     );
//   }

//   Widget _buildSearchBar() {
//     return Container(
//       height: 40,
//       decoration: BoxDecoration(
//         color: Colors.grey[900],
//         borderRadius: BorderRadius.circular(8),
//       ),
//       child: TextField(
//         controller: _searchController,
//         focusNode: _searchFocusNode,
//         style: const TextStyle(color: Colors.white),
//         decoration: InputDecoration(
//           prefixIcon: const Icon(Icons.search, color: Colors.grey),
//           hintText: 'Search',
//           hintStyle: const TextStyle(color: Colors.grey),
//           border: InputBorder.none,
//           contentPadding: const EdgeInsets.only(bottom: 10),
//         ),
//         cursorColor: Colors.white,
//         onSubmitted: (value) {
//           if (value.isNotEmpty) {
//             _saveSearchTerm(value);
//           }
//         },
//       ),
//     );
//   }

//   Widget _buildRecentSearches() {
//     return SingleChildScrollView(
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Recent searches section
//           if (_recentSearches.isNotEmpty) ...[
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text(
//                     'Recent Searches',
//                     style: GoogleFonts.roboto(
//                       color: Colors.white,
//                       fontSize: 16,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   TextButton(
//                     onPressed: _clearAllRecentSearches,
//                     child: Text(
//                       'Clear all',
//                       style: GoogleFonts.roboto(
//                         color: Colors.blue,
//                         fontSize: 14,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             ..._recentSearches.map((search) => _buildRecentSearchItem(search)),
//             const SizedBox(height: 16),
//           ],

//           // Trending topics section
//           const Padding(
//             padding: EdgeInsets.all(16),
//             child: Text(
//               'Trending',
//               style: TextStyle(
//                 color: Colors.white,
//                 fontSize: 16,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ),
//           ..._trendingTopics.map((topic) => _buildTrendingTopicItem(topic)),
//         ],
//       ),
//     );
//   }

//   Widget _buildRecentSearchItem(String search) {
//     return ListTile(
//       leading: const Icon(Icons.history, color: Colors.grey),
//       title: Text(search, style: const TextStyle(color: Colors.white)),
//       trailing: IconButton(
//         icon: const Icon(Icons.close, color: Colors.grey, size: 20),
//         onPressed: () {
//           _removeSearchTerm(search);
//         },
//       ),
//       onTap: () {
//         _searchController.text = search;
//         _searchFocusNode.unfocus();
//         _saveSearchTerm(search);
//       },
//     );
//   }

//   Widget _buildTrendingTopicItem(Map<String, dynamic> topic) {
//     return ListTile(
//       leading: const Icon(Icons.trending_up, color: Colors.red),
//       title: Text(
//         '#${topic['title']}',
//         style: const TextStyle(
//           color: Colors.white,
//           fontWeight: FontWeight.bold,
//         ),
//       ),
//       subtitle: Text(
//         '${topic['views']} views',
//         style: const TextStyle(color: Colors.grey),
//       ),
//       onTap: () {
//         final searchTerm = topic['title'] ?? '';
//         _searchController.text = searchTerm;
//         _searchFocusNode.unfocus();
//         _saveSearchTerm(searchTerm);
//       },
//     );
//   }

//   Widget _buildSearchResults() {
//     return Column(
//       children: [
//         Container(
//           height: 40,
//           child: ListView.builder(
//             scrollDirection: Axis.horizontal,
//             itemCount: _searchTabs.length,
//             itemBuilder: (context, index) {
//               return GestureDetector(
//                 onTap: () {
//                   setState(() {
//                     _selectedTabIndex = index;
//                   });
//                 },
//                 child: Container(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 25,
//                     vertical: 6,
//                   ),
//                   margin: const EdgeInsets.all(4),
//                   decoration: BoxDecoration(
//                     color: _selectedTabIndex == index
//                         ? Colors.white.withOpacity(0.2)
//                         : Colors.transparent,
//                     borderRadius: BorderRadius.circular(20),
//                   ),
//                   child: Text(
//                     _searchTabs[index],
//                     style: GoogleFonts.roboto(
//                       color: _selectedTabIndex == index
//                           ? Colors.white
//                           : Colors.grey,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ),
//               );
//             },
//           ),
//         ),
//         Expanded(child: _buildSearchResultsByTab()),
//       ],
//     );
//   }

//   Widget _buildSearchResultsByTab() {
//     switch (_selectedTabIndex) {
//       case 0: // Top
//         return _buildTopResults();
//       case 1: // Users
//         return _buildUserResults();
//       case 2: // Sounds
//         return _buildSoundResults();
//       case 3: // Hashtags
//         return _buildHashtagResults();
//       default:
//         return Container();
//     }
//   }

//   Widget _buildTopResults() {
//     return ListView(
//       children: [
//         // Users section
//         const Padding(
//           padding: EdgeInsets.all(16),
//           child: Text(
//             'Users',
//             style: TextStyle(
//               color: Colors.white,
//               fontSize: 16,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ),
//         StreamBuilder<QuerySnapshot>(
//           stream: _searchService.searchUsers(_searchQuery),
//           builder: (context, snapshot) {
//             if (snapshot.connectionState == ConnectionState.waiting) {
//               return const Center(child: CircularProgressIndicator());
//             }

//             if (snapshot.hasError) {
//               return Center(
//                 child: Text(
//                   'Error: ${snapshot.error}',
//                   style: const TextStyle(color: Colors.white),
//                 ),
//               );
//             }

//             if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//               return const Padding(
//                 padding: EdgeInsets.all(16),
//                 child: Text(
//                   'No users found',
//                   style: TextStyle(color: Colors.grey),
//                 ),
//               );
//             }

//             final users = snapshot.data!.docs.take(3).toList();

//             return Column(
//               children: users.map((user) {
//                 final data = user.data() as Map<String, dynamic>;
//                 return ListTile(
//                   leading: CircleAvatar(
//                     backgroundImage: CachedNetworkImageProvider(
//                       data['image'] ?? "",
//                     ),
//                   ),
//                   title: Text(
//                     data['name'] ?? "",
//                     style: const TextStyle(color: Colors.white),
//                   ),
//                   onTap: () {
//                     _saveSearchTerm(data['name'] ?? "");
//                   },
//                 );
//               }).toList(),
//             );
//           },
//         ),

//         // Videos section
//         const Padding(
//           padding: EdgeInsets.all(16),
//           child: Text(
//             'Videos',
//             style: TextStyle(
//               color: Colors.white,
//               fontSize: 16,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ),
//         StreamBuilder<QuerySnapshot>(
//           stream: _searchService.searchVideos(_searchQuery),
//           builder: (context, snapshot) {
//             if (snapshot.connectionState == ConnectionState.waiting) {
//               return const Center(child: CircularProgressIndicator());
//             }

//             if (snapshot.hasError) {
//               return Center(
//                 child: Text(
//                   'Error: ${snapshot.error}',
//                   style: const TextStyle(color: Colors.white),
//                 ),
//               );
//             }

//             if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//               return const Padding(
//                 padding: EdgeInsets.all(16),
//                 child: Text(
//                   'No videos found',
//                   style: TextStyle(color: Colors.grey),
//                 ),
//               );
//             }

//             final videos = snapshot.data!.docs.take(3).toList();

//             return Column(
//               children: videos.map((video) {
//                 final data = video.data() as Map<String, dynamic>;
//                 return ListTile(
//                   leading: Container(
//                     width: 100,
//                     height: 60,
//                     child: CachedNetworkImage(
//                       imageUrl: data['thumbnailUrl'] ?? "",
//                       fit: BoxFit.cover,
//                     ),
//                   ),
//                   title: Text(
//                     data['caption'] ?? "",
//                     style: const TextStyle(color: Colors.white),
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                   subtitle: Text(
//                     '${_formatViews(data['views'])} views',
//                     style: const TextStyle(color: Colors.grey),
//                   ),
//                   onTap: () {
//                     _saveSearchTerm(_searchQuery);
//                   },
//                 );
//               }).toList(),
//             );
//           },
//         ),
//       ],
//     );
//   }

//   Widget _buildUserResults() {
//     return StreamBuilder<QuerySnapshot>(
//       stream: _searchService.searchUsers(_searchQuery),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const Center(child: CircularProgressIndicator());
//         }

//         if (snapshot.hasError) {
//           return Center(
//             child: Text(
//               'Error: ${snapshot.error}',
//               style: const TextStyle(color: Colors.white),
//             ),
//           );
//         }

//         if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//           return Center(
//             child: Text(
//               'No users found for "$_searchQuery"',
//               style: const TextStyle(color: Colors.grey),
//             ),
//           );
//         }

//         return ListView.builder(
//           itemCount: snapshot.data!.docs.length,
//           itemBuilder: (context, index) {
//             final user = snapshot.data!.docs[index];
//             final data = user.data() as Map<String, dynamic>;

//             return ListTile(
//               leading: CircleAvatar(
//                 backgroundImage: CachedNetworkImageProvider(
//                   data['image'] ?? "",
//                 ),
//               ),
//               title: Text(
//                 data['name'] ?? "",
//                 style: const TextStyle(color: Colors.white),
//               ),
//               onTap: () {
//                 _saveSearchTerm(data['name'] ?? "");
//               },
//             );
//           },
//         );
//       },
//     );
//   }

//   Widget _buildSoundResults() {
//     return Center(
//       child: Text(
//         'Sound results for "$_searchQuery" ',
//         style: const TextStyle(color: Colors.white),
//       ),
//     );
//   }

//   Widget _buildHashtagResults() {
//     return Center(
//       child: Text(
//         'Hashtag results for "$_searchQuery"',
//         style: const TextStyle(color: Colors.white),
//       ),
//     );
//   }

//   String _formatViews(int views) {
//     if (views < 1000) return views.toString();
//     if (views < 1000000) return '${(views / 1000).toStringAsFixed(1)}K';
//     return '${(views / 1000000).toStringAsFixed(1)}M';
//   }
// }

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tiktok/follow_service/follow_service.dart';
import 'package:tiktok/profile/profile_screen.dart';
import 'package:tiktok/search/recent_search_service.dart';
import 'package:tiktok/search/search_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SearchScreen extends StatefulWidget {
  // ignore: use_super_parameters
  const SearchScreen({Key? key}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final RecentSearchService _recentSearchService = RecentSearchService();
  final SearchService _searchService = SearchService();
  final FollowService _followService = FollowService();
  String _searchQuery = '';
  bool _showRecentSearches = true;
  List<String> _recentSearches = [];

  // Mock trending topics
  final List<Map<String, dynamic>> _trendingTopics = [
    {'title': 'FlutterDev', 'views': '5.4M'},
    {'title': 'Coding', 'views': '12.2M'},
    {'title': 'Recipe', 'views': '8.7M'},
    {'title': 'Workout', 'views': '15.1M'},
    {'title': 'Travel', 'views': '20.3M'},
  ];

  int _selectedTabIndex = 0;
  final List<String> _searchTabs = ['Top', 'Users', 'Sounds', 'Hashtags'];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
        _showRecentSearches = _searchQuery.isEmpty;
      });
    });

    _loadRecentSearches();
  }

  // Load recent searches from storage
  void _loadRecentSearches() async {
    final searches = await _recentSearchService.getRecentSearches();
    setState(() {
      _recentSearches = searches;
    });
  }

  // Save a search term
  void _saveSearchTerm(String searchTerm) {
    if (searchTerm.trim().isNotEmpty) {
      _recentSearchService.saveSearchTerm(searchTerm);
      _loadRecentSearches(); // Reload the list
    }
  }

  // Remove a search term
  void _removeSearchTerm(String searchTerm) {
    _recentSearchService.removeSearchTerm(searchTerm);
    _loadRecentSearches(); // Reload the list
  }

  // Clear all recent searches
  void _clearAllRecentSearches() async {
    await _recentSearchService.clearAllRecentSearches();
    _loadRecentSearches(); // Reload the list
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        automaticallyImplyLeading: false,
        title: _buildSearchBar(),
      ),
      body: _showRecentSearches
          ? _buildRecentSearches()
          : _buildSearchResults(),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          hintText: 'Search',
          hintStyle: const TextStyle(color: Colors.grey),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.only(bottom: 10),
        ),
        cursorColor: Colors.white,
        onSubmitted: (value) {
          if (value.isNotEmpty) {
            _saveSearchTerm(value);
          }
        },
      ),
    );
  }

  Widget _buildRecentSearches() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recent searches section
          if (_recentSearches.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Searches',
                    style: GoogleFonts.roboto(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: _clearAllRecentSearches,
                    child: Text(
                      'Clear all',
                      style: GoogleFonts.roboto(
                        color: Colors.blue,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ..._recentSearches.map((search) => _buildRecentSearchItem(search)),
            const SizedBox(height: 16),
          ],

          // Trending topics section
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Trending',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ..._trendingTopics.map((topic) => _buildTrendingTopicItem(topic)),
        ],
      ),
    );
  }

  Widget _buildRecentSearchItem(String search) {
    return ListTile(
      leading: const Icon(Icons.history, color: Colors.grey),
      title: Text(search, style: const TextStyle(color: Colors.white)),
      trailing: IconButton(
        icon: const Icon(Icons.close, color: Colors.grey, size: 20),
        onPressed: () {
          _removeSearchTerm(search);
        },
      ),
      onTap: () {
        _searchController.text = search;
        _searchFocusNode.unfocus();
        _saveSearchTerm(search);
      },
    );
  }

  Widget _buildTrendingTopicItem(Map<String, dynamic> topic) {
    return ListTile(
      leading: const Icon(Icons.trending_up, color: Colors.red),
      title: Text(
        '#${topic['title']}',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        '${topic['views']} views',
        style: const TextStyle(color: Colors.grey),
      ),
      onTap: () {
        final searchTerm = topic['title'] ?? '';
        _searchController.text = searchTerm;
        _searchFocusNode.unfocus();
        _saveSearchTerm(searchTerm);
      },
    );
  }

  Widget _buildSearchResults() {
    return Column(
      children: [
        Container(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _searchTabs.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedTabIndex = index;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 25,
                    vertical: 6,
                  ),
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: _selectedTabIndex == index
                        // ignore: deprecated_member_use
                        ? Colors.white.withOpacity(0.2)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _searchTabs[index],
                    style: GoogleFonts.roboto(
                      color: _selectedTabIndex == index
                          ? Colors.white
                          : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Expanded(child: _buildSearchResultsByTab()),
      ],
    );
  }

  Widget _buildSearchResultsByTab() {
    switch (_selectedTabIndex) {
      case 0: // Top
        return _buildTopResults();
      case 1: // Users
        return _buildUserResults();
      case 2: // Sounds
        return _buildSoundResults();
      case 3: // Hashtags
        return _buildHashtagResults();
      default:
        return Container();
    }
  }

  Widget _buildTopResults() {
    return ListView(
      children: [
        // Users section
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Users',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        StreamBuilder<QuerySnapshot>(
          stream: _searchService.searchUsers(_searchQuery),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.white),
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'No users found',
                  style: TextStyle(color: Colors.grey),
                ),
              );
            }

            final users = snapshot.data!.docs.take(3).toList();

            return Column(
              children: users.map((user) {
                final data = user.data() as Map<String, dynamic>;
                return _buildUserListItem(user.id, data);
              }).toList(),
            );
          },
        ),

        // Videos section
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Videos',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        StreamBuilder<QuerySnapshot>(
          stream: _searchService.searchVideos(_searchQuery),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.white),
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'No videos found',
                  style: TextStyle(color: Colors.grey),
                ),
              );
            }

            final videos = snapshot.data!.docs.take(3).toList();

            return Column(
              children: videos.map((video) {
                final data = video.data() as Map<String, dynamic>;
                return ListTile(
                  // ignore: sized_box_for_whitespace
                  leading: Container(
                    width: 100,
                    height: 60,
                    child: CachedNetworkImage(
                      imageUrl: data['thumbnailUrl'] ?? "",
                      fit: BoxFit.cover,
                    ),
                  ),
                  title: Text(
                    data['caption'] ?? "",
                    style: const TextStyle(color: Colors.white),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${_formatViews(data['views'])} views',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  onTap: () {
                    _saveSearchTerm(_searchQuery);
                  },
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildUserResults() {
    return StreamBuilder<QuerySnapshot>(
      stream: _searchService.searchUsers(_searchQuery),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: const TextStyle(color: Colors.white),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              'No users found for "$_searchQuery"',
              style: const TextStyle(color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final user = snapshot.data!.docs[index];
            final data = user.data() as Map<String, dynamic>;
            return _buildUserListItem(user.id, data);
          },
        );
      },
    );
  }

  Widget _buildUserListItem(String userId, Map<String, dynamic> userData) {
    return FutureBuilder<bool>(
      future: _followService.isFollowing(userId),
      builder: (context, snapshot) {
        final isFollowing = snapshot.data ?? false;

        return ListTile(
          leading: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ProfileScreen(userId: userId, isCurrentUser: false),
                ),
              );
            },
            child: CircleAvatar(
              backgroundImage: CachedNetworkImageProvider(
                userData['image'] ?? "",
              ),
            ),
          ),
          title: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ProfileScreen(userId: userId, isCurrentUser: false),
                ),
              );
            },
            child: Text(
              userData['name'] ?? "",
              style: const TextStyle(color: Colors.white),
            ),
          ),
          subtitle: FutureBuilder(
            future: _followService.getFollowersCount(userId),
            builder: (context, snapshot) {
              final followers = snapshot.data ?? 0;
              return Text(
                '$followers followers',
                style: const TextStyle(color: Colors.grey),
              );
            },
          ),
          trailing: _buildFollowButton(userId, isFollowing),
        );
      },
    );
  }

  Widget _buildFollowButton(String userId, bool isFollowing) {
    return TextButton(
      onPressed: () {
        if (isFollowing) {
          _followService.unfollowUser(userId);
        } else {
          _followService.followUser(userId);
        }
        setState(() {}); // Refresh the UI
      },
      style: TextButton.styleFrom(
        backgroundColor: isFollowing ? Colors.grey[700] : Colors.red,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      child: Text(
        isFollowing ? 'Following' : 'Follow',
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }

  Widget _buildSoundResults() {
    return Center(
      child: Text(
        'Sound results for "$_searchQuery"',
        style: const TextStyle(color: Colors.white),
      ),
    );
  }

  Widget _buildHashtagResults() {
    return Center(
      child: Text(
        'Hashtag results for "$_searchQuery"',
        style: const TextStyle(color: Colors.white),
      ),
    );
  }

  String _formatViews(int views) {
    if (views < 1000) return views.toString();
    if (views < 1000000) return '${(views / 1000).toStringAsFixed(1)}K';
    return '${(views / 1000000).toStringAsFixed(1)}M';
  }
}
