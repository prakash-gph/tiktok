// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:tiktok/follow_service/follow_service.dart';
// import 'package:tiktok/profile/profile_screen.dart';
// import 'package:tiktok/search/recent_search_service.dart';
// import 'package:tiktok/search/search_service.dart';

// class SearchScreen extends StatefulWidget {
//   const SearchScreen({Key? key}) : super(key: key);

//   @override
//   _SearchScreenState createState() => _SearchScreenState();
// }

// class _SearchScreenState extends State<SearchScreen>
//     with SingleTickerProviderStateMixin {
//   final TextEditingController _searchController = TextEditingController();
//   final FocusNode _searchFocusNode = FocusNode();
//   final RecentSearchService _recentSearchService = RecentSearchService();
//   final SearchService _searchService = SearchService();
//   final FollowService _followService = FollowService();

//   String _searchQuery = '';
//   bool _showRecentSearches = true;
//   List<String> _recentSearches = [];
//   int _selectedTabIndex = 0;
//   late AnimationController _animationController;
//   late Animation<double> _fadeAnimation;

//   // Mock trending topics
//   final List<Map<String, dynamic>> _trendingTopics = [
//     {'title': 'FlutterDev', 'views': '5.4M', 'trending': true},
//     {'title': 'Coding', 'views': '12.2M', 'trending': true},
//     {'title': 'Recipe', 'views': '8.7M', 'trending': false},
//     {'title': 'Workout', 'views': '15.1M', 'trending': true},
//     {'title': 'Travel', 'views': '20.3M', 'trending': false},
//   ];

//   final List<String> _searchTabs = ['Top', 'Users', 'Sounds', 'Hashtags'];

//   @override
//   void initState() {
//     super.initState();

//     _animationController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 300),
//     );

//     _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
//       CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
//     );

//     _animationController.forward();

//     _searchController.addListener(() {
//       setState(() {
//         _searchQuery = _searchController.text;
//         _showRecentSearches = _searchQuery.isEmpty;
//       });
//     });

//     _loadRecentSearches();
//   }

//   void _loadRecentSearches() async {
//     final searches = await _recentSearchService.getRecentSearches();
//     setState(() {
//       _recentSearches = searches;
//     });
//   }

//   void _saveSearchTerm(String searchTerm) {
//     if (searchTerm.trim().isNotEmpty) {
//       _recentSearchService.saveSearchTerm(searchTerm);
//       _loadRecentSearches();
//     }
//   }

//   void _removeSearchTerm(String searchTerm) {
//     _recentSearchService.removeSearchTerm(searchTerm);
//     _loadRecentSearches();
//   }

//   void _clearAllRecentSearches() async {
//     await _recentSearchService.clearAllRecentSearches();
//     _loadRecentSearches();
//   }

//   @override
//   void dispose() {
//     _animationController.dispose();
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
//         elevation: 0,
//         automaticallyImplyLeading: false,
//         title: _buildSearchBar(),
//       ),
//       body: FadeTransition(
//         opacity: _fadeAnimation,
//         child: _showRecentSearches
//             ? _buildRecentSearches()
//             : _buildSearchResults(),
//       ),
//     );
//   }

//   Widget _buildSearchBar() {
//     return Container(
//       height: 45,
//       decoration: BoxDecoration(
//         color: Colors.grey[900],
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: TextField(
//         controller: _searchController,
//         focusNode: _searchFocusNode,
//         style: GoogleFonts.roboto(color: Colors.white, fontSize: 16),
//         decoration: InputDecoration(
//           prefixIcon: Icon(Icons.search, color: Colors.grey[400], size: 24),
//           hintText: 'Search accounts',
//           hintStyle: GoogleFonts.roboto(color: Colors.grey[400], fontSize: 16),
//           border: InputBorder.none,
//           contentPadding: const EdgeInsets.symmetric(vertical: 12),
//         ),
//         cursorColor: Colors.red,
//         onSubmitted: (value) {
//           if (value.isNotEmpty) {
//             _saveSearchTerm(value);
//           }
//         },
//       ),
//     );
//   }

//   Widget _buildRecentSearches() {
//     return CustomScrollView(
//       slivers: [
//         // Recent searches section
//         if (_recentSearches.isNotEmpty) ...[
//           SliverToBoxAdapter(
//             child: Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text(
//                     'Recent Searches',
//                     style: GoogleFonts.roboto(
//                       color: Colors.white,
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   GestureDetector(
//                     onTap: _clearAllRecentSearches,
//                     child: Text(
//                       'Clear all',
//                       style: GoogleFonts.roboto(
//                         color: Colors.red,
//                         fontSize: 14,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//           SliverList(
//             delegate: SliverChildBuilderDelegate((context, index) {
//               return _buildRecentSearchItem(_recentSearches[index]);
//             }, childCount: _recentSearches.length),
//           ),
//           const SliverToBoxAdapter(child: SizedBox(height: 16)),
//         ],

//         // Trending topics section
//         SliverToBoxAdapter(
//           child: Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//             child: Text(
//               'Trending Now',
//               style: GoogleFonts.roboto(
//                 color: Colors.white,
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ),
//         ),
//         SliverList(
//           delegate: SliverChildBuilderDelegate((context, index) {
//             return _buildTrendingTopicItem(_trendingTopics[index]);
//           }, childCount: _trendingTopics.length),
//         ),
//       ],
//     );
//   }

//   Widget _buildRecentSearchItem(String search) {
//     return Dismissible(
//       key: Key(search),
//       background: Container(
//         color: Colors.red,
//         alignment: Alignment.centerRight,
//         padding: const EdgeInsets.only(right: 20),
//         child: const Icon(Icons.delete, color: Colors.white),
//       ),
//       onDismissed: (direction) {
//         _removeSearchTerm(search);
//       },
//       child: ListTile(
//         contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//         leading: Container(
//           width: 40,
//           height: 40,
//           decoration: BoxDecoration(
//             color: Colors.grey[800],
//             shape: BoxShape.circle,
//           ),
//           child: Icon(Icons.history, color: Colors.grey[400], size: 20),
//         ),
//         title: Text(
//           search,
//           style: GoogleFonts.roboto(color: Colors.white, fontSize: 16),
//         ),
//         trailing: IconButton(
//           icon: Icon(Icons.close, color: Colors.grey[400], size: 20),
//           onPressed: () => _removeSearchTerm(search),
//         ),
//         onTap: () {
//           _searchController.text = search;
//           _searchFocusNode.unfocus();
//           _saveSearchTerm(search);
//         },
//       ),
//     );
//   }

//   Widget _buildTrendingTopicItem(Map<String, dynamic> topic) {
//     final isTrending = topic['trending'] as bool;

//     return ListTile(
//       contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//       leading: Container(
//         width: 50,
//         height: 50,
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             colors: isTrending
//                 ? [Colors.red, Colors.pink]
//                 : [Colors.grey[800]!, Colors.grey[700]!],
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//           ),
//           borderRadius: BorderRadius.circular(10),
//         ),
//         child: Icon(
//           isTrending ? Icons.trending_up : Icons.tag,
//           color: Colors.white,
//           size: 24,
//         ),
//       ),
//       title: Text(
//         '#${topic['title']}',
//         style: GoogleFonts.roboto(
//           color: Colors.white,
//           fontSize: 16,
//           fontWeight: FontWeight.w600,
//         ),
//       ),
//       subtitle: Text(
//         '${topic['views']} views',
//         style: GoogleFonts.roboto(color: Colors.grey[400], fontSize: 14),
//       ),
//       trailing: isTrending
//           ? Container(
//               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//               decoration: BoxDecoration(
//                 // ignore: deprecated_member_use
//                 color: Colors.red.withOpacity(0.2),
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: Text(
//                 'Trending',
//                 style: GoogleFonts.roboto(
//                   color: Colors.red,
//                   fontSize: 12,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             )
//           : null,
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
//         // Tab bar
//         Container(
//           height: 46,
//           decoration: BoxDecoration(
//             color: Colors.grey[900],
//             borderRadius: BorderRadius.circular(12),
//             boxShadow: [
//               BoxShadow(
//                 // ignore: deprecated_member_use
//                 color: Colors.black.withOpacity(0.1),
//                 blurRadius: 4,
//                 offset: const Offset(0, 2),
//               ),
//             ],
//           ),
//           margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
//                     horizontal: 20,
//                     vertical: 10,
//                   ),
//                   margin: const EdgeInsets.all(4),
//                   decoration: BoxDecoration(
//                     color: _selectedTabIndex == index
//                         ? Colors.red
//                         : Colors.transparent,
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: Text(
//                     _searchTabs[index],
//                     style: GoogleFonts.roboto(
//                       color: _selectedTabIndex == index
//                           ? Colors.white
//                           : Colors.grey[400],
//                       fontWeight: FontWeight.w600,
//                       fontSize: 14,
//                     ),
//                   ),
//                 ),
//               );
//             },
//           ),
//         ),

//         // Results
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
//       padding: const EdgeInsets.symmetric(vertical: 8),
//       children: [
//         // Users section
//         Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//           child: Text(
//             'Accounts',
//             style: GoogleFonts.roboto(
//               color: Colors.white,
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ),
//         StreamBuilder<QuerySnapshot>(
//           stream: _searchService.searchUsers(_searchQuery),
//           builder: (context, snapshot) {
//             if (snapshot.connectionState == ConnectionState.waiting) {
//               return _buildLoadingIndicator();
//             }

//             if (snapshot.hasError) {
//               return _buildErrorWidget('Error: ${snapshot.error}');
//             }

//             if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//               return _buildEmptyState('No users found');
//             }

//             final users = snapshot.data!.docs.take(3).toList();

//             return Column(
//               children: users.map((user) {
//                 final data = user.data() as Map<String, dynamic>;
//                 return _buildUserListItem(user.id, data);
//               }).toList(),
//             );
//           },
//         ),

//         // Videos section
//         Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
//           child: Text(
//             'Videos',
//             style: GoogleFonts.roboto(
//               color: Colors.white,
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ),
//         StreamBuilder<QuerySnapshot>(
//           stream: _searchService.searchVideos(_searchQuery),
//           builder: (context, snapshot) {
//             if (snapshot.connectionState == ConnectionState.waiting) {
//               return _buildLoadingIndicator();
//             }

//             if (snapshot.hasError) {
//               return _buildErrorWidget('Error: ${snapshot.error}');
//             }

//             if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//               return _buildEmptyState('No videos found');
//             }

//             final videos = snapshot.data!.docs.take(3).toList();

//             return Column(
//               children: videos.map((video) {
//                 final data = video.data() as Map<String, dynamic>;
//                 return _buildVideoListItem(video.id, data);
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
//           return _buildLoadingIndicator();
//         }

//         if (snapshot.hasError) {
//           return _buildErrorWidget('Error: ${snapshot.error}');
//         }

//         if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//           return _buildEmptyState('No users found for "$_searchQuery"');
//         }

//         return ListView.builder(
//           padding: const EdgeInsets.symmetric(vertical: 8),
//           itemCount: snapshot.data!.docs.length,
//           itemBuilder: (context, index) {
//             final user = snapshot.data!.docs[index];
//             final data = user.data() as Map<String, dynamic>;
//             return _buildUserListItem(user.id, data);
//           },
//         );
//       },
//     );
//   }

//   Widget _buildUserListItem(String userId, Map<String, dynamic> userData) {
//     return FutureBuilder<bool>(
//       future: _followService.isFollowing(userId),
//       builder: (context, snapshot) {
//         final isFollowing = snapshot.data ?? false;

//         return Container(
//           margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//           decoration: BoxDecoration(
//             color: Colors.grey[900],
//             borderRadius: BorderRadius.circular(16),
//             boxShadow: [
//               BoxShadow(
//                 // ignore: deprecated_member_use
//                 color: Colors.black.withOpacity(0.2),
//                 blurRadius: 6,
//                 offset: const Offset(0, 3),
//               ),
//             ],
//           ),
//           child: Material(
//             color: Colors.transparent,
//             child: InkWell(
//               borderRadius: BorderRadius.circular(16),
//               onTap: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (context) =>
//                         ProfileScreen(userId: userId, isCurrentUser: false),
//                   ),
//                 );
//               },
//               child: Padding(
//                 padding: const EdgeInsets.all(12),
//                 child: Row(
//                   children: [
//                     // Profile Avatar
//                     Stack(
//                       children: [
//                         CircleAvatar(
//                           radius: 28,
//                           backgroundImage: CachedNetworkImageProvider(
//                             userData['image'] ?? "",
//                           ),
//                         ),
//                         // Online indicator (optional)
//                         if (userData['isOnline'] == true)
//                           Positioned(
//                             bottom: 0,
//                             right: 0,
//                             child: Container(
//                               width: 14,
//                               height: 14,
//                               decoration: BoxDecoration(
//                                 color: Colors.green,
//                                 shape: BoxShape.circle,
//                                 border: Border.all(
//                                   color: Colors.grey[900]!,
//                                   width: 2,
//                                 ),
//                               ),
//                             ),
//                           ),
//                       ],
//                     ),
//                     const SizedBox(width: 16),

//                     // User Info
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             userData['name'] ?? "",
//                             style: GoogleFonts.roboto(
//                               color: Colors.white,
//                               fontSize: 16,
//                               fontWeight: FontWeight.w600,
//                             ),
//                             maxLines: 1,
//                             overflow: TextOverflow.ellipsis,
//                           ),
//                           const SizedBox(height: 4),
//                           FutureBuilder(
//                             future: _followService.getFollowersCount(userId),
//                             builder: (context, snapshot) {
//                               final followers = snapshot.data ?? 0;
//                               return Text(
//                                 '$followers followers',
//                                 style: GoogleFonts.roboto(
//                                   color: Colors.grey[400],
//                                   fontSize: 14,
//                                 ),
//                               );
//                             },
//                           ),
//                           if (userData['bio'] != null &&
//                               userData['bio'].isNotEmpty)
//                             Column(
//                               children: [
//                                 const SizedBox(height: 6),
//                                 Text(
//                                   userData['bio'],
//                                   style: GoogleFonts.roboto(
//                                     color: Colors.grey[500],
//                                     fontSize: 13,
//                                   ),
//                                   maxLines: 1,
//                                   overflow: TextOverflow.ellipsis,
//                                 ),
//                               ],
//                             ),
//                         ],
//                       ),
//                     ),

//                     // Follow Button
//                     _buildFollowButton(userId, isFollowing),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }

//   // Enhanced Follow Button with better UI
//   Widget _buildFollowButton(String userId, bool isFollowing) {
//     return Container(
//       margin: const EdgeInsets.only(left: 8),
//       child: Material(
//         color: Colors.transparent,
//         child: InkWell(
//           borderRadius: BorderRadius.circular(20),
//           onTap: () {
//             if (isFollowing) {
//               _followService.unfollowUser(userId);
//             } else {
//               _followService.followUser(userId);
//             }
//             setState(() {});
//           },
//           child: Container(
//             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//             decoration: BoxDecoration(
//               color: isFollowing ? Colors.grey[700] : Colors.red,
//               borderRadius: BorderRadius.circular(20),
//               border: isFollowing
//                   ? Border.all(color: Colors.grey[500]!, width: 1)
//                   : null,
//             ),
//             child: Text(
//               isFollowing ? 'Following' : 'Follow',
//               style: GoogleFonts.roboto(
//                 color: Colors.white,
//                 fontSize: 14,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildVideoListItem(String videoId, Map<String, dynamic> videoData) {
//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       decoration: BoxDecoration(
//         color: Colors.grey[900],
//         borderRadius: BorderRadius.circular(16),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.stretch,
//         children: [
//           ClipRRect(
//             borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
//             child: CachedNetworkImage(
//               imageUrl: videoData['thumbnailUrl'] ?? "",
//               height: 200,
//               fit: BoxFit.cover,
//               placeholder: (context, url) => Container(
//                 color: Colors.grey[800],
//                 child: Center(
//                   child: CircularProgressIndicator(color: Colors.red),
//                 ),
//               ),
//               errorWidget: (context, url, error) => Container(
//                 color: Colors.grey[800],
//                 height: 200,
//                 child: Icon(Icons.error, color: Colors.grey[400]),
//               ),
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.all(12),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   videoData['description'] ?? "",
//                   style: GoogleFonts.roboto(
//                     color: Colors.white,
//                     fontSize: 16,
//                     fontWeight: FontWeight.w500,
//                   ),
//                   maxLines: 2,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//                 const SizedBox(height: 8),
//                 Row(
//                   children: [
//                     Icon(
//                       Icons.remove_red_eye,
//                       color: Colors.grey[400],
//                       size: 16,
//                     ),
//                     const SizedBox(width: 4),
//                     Text(
//                       '${_formatViews(videoData['views'])} views',
//                       style: GoogleFonts.roboto(
//                         color: Colors.grey[400],
//                         fontSize: 14,
//                       ),
//                     ),
//                     const SizedBox(width: 16),
//                     Icon(Icons.favorite, color: Colors.grey[400], size: 16),
//                     const SizedBox(width: 4),
//                     Text(
//                       '${_formatViews(videoData['likes'])} likes',
//                       style: GoogleFonts.roboto(
//                         color: Colors.grey[400],
//                         fontSize: 14,
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildSoundResults() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(Icons.music_note, color: Colors.grey[400], size: 64),
//           const SizedBox(height: 16),
//           Text(
//             'No sounds found for "$_searchQuery"',
//             style: GoogleFonts.roboto(color: Colors.grey[400], fontSize: 16),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildHashtagResults() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(Icons.tag, color: Colors.grey[400], size: 64),
//           const SizedBox(height: 16),
//           Text(
//             'No hashtags found for "$_searchQuery"',
//             style: GoogleFonts.roboto(color: Colors.grey[400], fontSize: 16),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildLoadingIndicator() {
//     return Center(child: CircularProgressIndicator(color: Colors.red));
//   }

//   Widget _buildErrorWidget(String message) {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(Icons.error_outline, color: Colors.red, size: 48),
//           const SizedBox(height: 16),
//           Text(
//             message,
//             style: GoogleFonts.roboto(color: Colors.white, fontSize: 16),
//             textAlign: TextAlign.center,
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildEmptyState(String message) {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(Icons.search_off, color: Colors.grey[400], size: 48),
//           const SizedBox(height: 16),
//           Text(
//             message,
//             style: GoogleFonts.roboto(color: Colors.grey[400], fontSize: 16),
//           ),
//         ],
//       ),
//     );
//   }

//   String _formatViews(dynamic views) {
//     if (views == null) return '0';

//     final intValue = views is int ? views : int.tryParse(views.toString()) ?? 0;

//     if (intValue < 1000) return intValue.toString();
//     if (intValue < 1000000) return '${(intValue / 1000).toStringAsFixed(1)}K';
//     return '${(intValue / 1000000).toStringAsFixed(1)}M';
//   }
// }

// add theme ------------------>

import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tiktok/follow_service/follow_service.dart';
import 'package:tiktok/profile/profile_screen.dart';
import 'package:tiktok/search/recent_search_service.dart';
import 'package:tiktok/search/search_service.dart';
import 'package:tiktok/theme/theme.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final RecentSearchService _recentSearchService = RecentSearchService();
  final SearchService _searchService = SearchService();
  final FollowService _followService = FollowService();

  String _searchQuery = '';
  bool _showRecentSearches = true;
  List<String> _recentSearches = [];
  int _selectedTabIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Mock trending topics
  final List<Map<String, dynamic>> _trendingTopics = [
    {'title': 'FlutterDev', 'views': '5.4M', 'trending': true},
    {'title': 'Coding', 'views': '12.2M', 'trending': true},
    {'title': 'Recipe', 'views': '8.7M', 'trending': false},
    {'title': 'Workout', 'views': '15.1M', 'trending': true},
    {'title': 'Travel', 'views': '20.3M', 'trending': false},
  ];

  final List<String> _searchTabs = ['Top', 'Users'];

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
        _showRecentSearches = _searchQuery.isEmpty;
      });
    });

    _loadRecentSearches();
  }

  void _loadRecentSearches() async {
    final searches = await _recentSearchService.getRecentSearches();
    setState(() {
      _recentSearches = searches;
    });
  }

  void _saveSearchTerm(String searchTerm) {
    if (searchTerm.trim().isNotEmpty) {
      _recentSearchService.saveSearchTerm(searchTerm);
      _loadRecentSearches();
    }
  }

  void _removeSearchTerm(String searchTerm) {
    _recentSearchService.removeSearchTerm(searchTerm);
    _loadRecentSearches();
  }

  void _clearAllRecentSearches() async {
    await _recentSearchService.clearAllRecentSearches();
    _loadRecentSearches();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: _buildSearchBar(context),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: _showRecentSearches
            ? _buildRecentSearches(context)
            : _buildSearchResults(context),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      height: 45,
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[900]
            : Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        style: GoogleFonts.roboto(
          color: Theme.of(context).textTheme.bodyLarge?.color,
          fontSize: 16,
        ),
        decoration: InputDecoration(
          prefixIcon: Icon(
            Icons.search,
            color: Theme.of(
              context,
            ).textTheme.bodyLarge?.color?.withOpacity(0.6),
            size: 24,
          ),
          hintText: 'Search accounts',
          hintStyle: GoogleFonts.roboto(
            color: Theme.of(
              context,
            ).textTheme.bodyLarge?.color?.withOpacity(0.6),
            fontSize: 16,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
        cursorColor: Colors.red,
        onSubmitted: (value) {
          if (value.isNotEmpty) {
            _saveSearchTerm(value);
          }
        },
      ),
    );
  }

  Widget _buildRecentSearches(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // Recent searches section
        if (_recentSearches.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Searches',
                    style: GoogleFonts.roboto(
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  GestureDetector(
                    onTap: _clearAllRecentSearches,
                    child: Text(
                      'Clear all',
                      style: GoogleFonts.roboto(
                        color: Colors.red,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              return _buildRecentSearchItem(_recentSearches[index], context);
            }, childCount: _recentSearches.length),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],

        // Trending topics section
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Trending Now',
              style: GoogleFonts.roboto(
                color: Theme.of(context).textTheme.bodyLarge?.color,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            return _buildTrendingTopicItem(_trendingTopics[index], context);
          }, childCount: _trendingTopics.length),
        ),
      ],
    );
  }

  Widget _buildRecentSearchItem(String search, BuildContext context) {
    return Dismissible(
      key: Key(search),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        _removeSearchTerm(search);
      },
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[800]
                : Colors.grey[300],
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.history,
            color: Theme.of(
              context,
            ).textTheme.bodyLarge?.color?.withOpacity(0.6),
            size: 20,
          ),
        ),
        title: Text(
          search,
          style: GoogleFonts.roboto(
            color: Theme.of(context).textTheme.bodyLarge?.color,
            fontSize: 16,
          ),
        ),
        trailing: IconButton(
          icon: Icon(
            Icons.close,
            color: Theme.of(
              context,
            ).textTheme.bodyLarge?.color?.withOpacity(0.6),
            size: 20,
          ),
          onPressed: () => _removeSearchTerm(search),
        ),
        onTap: () {
          _searchController.text = search;
          _searchFocusNode.unfocus();
          _saveSearchTerm(search);
        },
      ),
    );
  }

  Widget _buildTrendingTopicItem(
    Map<String, dynamic> topic,
    BuildContext context,
  ) {
    final isTrending = topic['trending'] as bool;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      leading: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isTrending
                ? [Colors.red, Colors.pink]
                : [
                    Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[800]!
                        : Colors.grey[300]!,
                    Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[700]!
                        : Colors.grey[400]!,
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          isTrending ? Icons.trending_up : Icons.tag,
          color: Colors.white,
          size: 24,
        ),
      ),
      title: Text(
        '#${topic['title']}',
        style: GoogleFonts.roboto(
          color: Theme.of(context).textTheme.bodyLarge?.color,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        '${topic['views']} views',
        style: GoogleFonts.roboto(
          color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.6),
          fontSize: 14,
        ),
      ),
      trailing: isTrending
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Trending',
                style: GoogleFonts.roboto(
                  color: Colors.red,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
      onTap: () {
        final searchTerm = topic['title'] ?? '';
        _searchController.text = searchTerm;
        _searchFocusNode.unfocus();
        _saveSearchTerm(searchTerm);
      },
    );
  }

  Widget _buildSearchResults(BuildContext context) {
    return Column(
      children: [
        // Tab bar
        Container(
          height: 46,
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[900]
                : Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
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
                    horizontal: 78,
                    vertical: 10,
                  ),
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: _selectedTabIndex == index
                        ? Colors.red
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _searchTabs[index],
                    style: GoogleFonts.roboto(
                      color: _selectedTabIndex == index
                          ? Colors.white
                          : Theme.of(
                              context,
                            ).textTheme.bodyLarge?.color?.withOpacity(0.6),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Results
        Expanded(child: _buildSearchResultsByTab(context)),
      ],
    );
  }

  Widget _buildSearchResultsByTab(BuildContext context) {
    switch (_selectedTabIndex) {
      case 0: // Top
        return _buildTopResults(context);
      case 1: // Users
        return _buildUserResults(context);
      case 2: // Sounds
        return _buildSoundResults(context);
      case 3: // Hashtags
        return _buildHashtagResults(context);
      default:
        return Container();
    }
  }

  Widget _buildTopResults(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        // Users section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Accounts',
            style: GoogleFonts.roboto(
              color: Theme.of(context).textTheme.bodyLarge?.color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        StreamBuilder<QuerySnapshot>(
          stream: _searchService.searchUsers(_searchQuery),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingIndicator();
            }

            if (snapshot.hasError) {
              return _buildErrorWidget('Error: ${snapshot.error}', context);
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return _buildEmptyState('No users found', context);
            }

            final users = snapshot.data!.docs.take(3).toList();

            return Column(
              children: users.map((user) {
                final data = user.data() as Map<String, dynamic>;
                return _buildUserListItem(user.id, data, context);
              }).toList(),
            );
          },
        ),

        // Videos section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Text(
            'Videos',
            style: GoogleFonts.roboto(
              color: Theme.of(context).textTheme.bodyLarge?.color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        StreamBuilder<QuerySnapshot>(
          stream: _searchService.searchVideos(_searchQuery),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingIndicator();
            }

            if (snapshot.hasError) {
              return _buildErrorWidget('Error: ${snapshot.error}', context);
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return _buildEmptyState('No videos found', context);
            }

            final videos = snapshot.data!.docs.take(3).toList();

            return Column(
              children: videos.map((video) {
                final data = video.data() as Map<String, dynamic>;
                return _buildVideoListItem(video.id, data, context);
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildUserResults(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _searchService.searchUsers(_searchQuery),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingIndicator();
        }

        if (snapshot.hasError) {
          return _buildErrorWidget('Error: ${snapshot.error}', context);
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState(
            'No users found for "$_searchQuery"',
            context,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final user = snapshot.data!.docs[index];
            final data = user.data() as Map<String, dynamic>;
            return _buildUserListItem(user.id, data, context);
          },
        );
      },
    );
  }

  Widget _buildUserListItem(
    String userId,
    Map<String, dynamic> userData,
    BuildContext context,
  ) {
    return FutureBuilder<bool>(
      future: _followService.isFollowing(userId),
      builder: (context, snapshot) {
        final isFollowing = snapshot.data ?? false;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[900]
                : Colors.grey[100],
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ProfileScreen(userId: userId, isCurrentUser: false),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    // Profile Avatar
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundImage: CachedNetworkImageProvider(
                            userData['image'] ?? "",
                          ),
                        ),
                        // Online indicator (optional)
                        if (userData['isOnline'] == true)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color:
                                      Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.grey[900]!
                                      : Colors.grey[100]!,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 16),

                    // User Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userData['name'] ?? "",
                            style: GoogleFonts.roboto(
                              color: Theme.of(
                                context,
                              ).textTheme.bodyLarge?.color,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          FutureBuilder(
                            future: _followService.getFollowersCount(userId),
                            builder: (context, snapshot) {
                              final followers = snapshot.data ?? 0;
                              return Text(
                                '$followers followers',
                                style: GoogleFonts.roboto(
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.color
                                      ?.withOpacity(0.6),
                                  fontSize: 14,
                                ),
                              );
                            },
                          ),
                          if (userData['bio'] != null &&
                              userData['bio'].isNotEmpty)
                            Column(
                              children: [
                                const SizedBox(height: 6),
                                Text(
                                  userData['bio'],
                                  style: GoogleFonts.roboto(
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.color
                                        ?.withOpacity(0.5),
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),

                    // Follow Button
                    _buildFollowButton(userId, isFollowing, context),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFollowButton(
    String userId,
    bool isFollowing,
    BuildContext context,
  ) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            if (isFollowing) {
              _followService.unfollowUser(userId);
            } else {
              _followService.followUser(userId);
            }
            setState(() {});
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isFollowing
                  ? (Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[700]
                        : Colors.grey[300])
                  : Colors.red,
              borderRadius: BorderRadius.circular(20),
              border: isFollowing
                  ? Border.all(
                      color:
                          Theme.of(
                            context,
                          ).textTheme.bodyLarge?.color?.withOpacity(0.3) ??
                          Colors.grey,
                      width: 1,
                    )
                  : null,
            ),
            child: Text(
              isFollowing ? 'Following' : 'Follow',
              style: GoogleFonts.roboto(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVideoListItem(
    String videoId,
    Map<String, dynamic> videoData,
    BuildContext context,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[900]
            : Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: CachedNetworkImage(
              imageUrl: videoData['thumbnailUrl'] ?? "",
              height: 200,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[800]
                    : Colors.grey[300],
                child: Center(
                  child: CircularProgressIndicator(color: Colors.red),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[800]
                    : Colors.grey[300],
                height: 200,
                child: Icon(
                  Icons.error,
                  color: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.color?.withOpacity(0.5),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  videoData['description'] ?? "",
                  style: GoogleFonts.roboto(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.remove_red_eye,
                      color: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.color?.withOpacity(0.5),
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${_formatViews(videoData['views'])} views',
                      style: GoogleFonts.roboto(
                        color: Theme.of(
                          context,
                        ).textTheme.bodyLarge?.color?.withOpacity(0.5),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.favorite,
                      color: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.color?.withOpacity(0.5),
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${_formatViews(videoData['likes'])} likes',
                      style: GoogleFonts.roboto(
                        color: Theme.of(
                          context,
                        ).textTheme.bodyLarge?.color?.withOpacity(0.5),
                        fontSize: 14,
                      ),
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

  Widget _buildSoundResults(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.music_note,
            color: Theme.of(
              context,
            ).textTheme.bodyLarge?.color?.withOpacity(0.5),
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            'No sounds found for "$_searchQuery"',
            style: GoogleFonts.roboto(
              color: Theme.of(
                context,
              ).textTheme.bodyLarge?.color?.withOpacity(0.5),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHashtagResults(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.tag,
            color: Theme.of(
              context,
            ).textTheme.bodyLarge?.color?.withOpacity(0.5),
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            'No hashtags found for "$_searchQuery"',
            style: GoogleFonts.roboto(
              color: Theme.of(
                context,
              ).textTheme.bodyLarge?.color?.withOpacity(0.5),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(child: CircularProgressIndicator(color: Colors.red));
  }

  Widget _buildErrorWidget(String message, BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.roboto(
              color: Theme.of(context).textTheme.bodyLarge?.color,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message, BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            color: Theme.of(
              context,
            ).textTheme.bodyLarge?.color?.withOpacity(0.5),
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.roboto(
              color: Theme.of(
                context,
              ).textTheme.bodyLarge?.color?.withOpacity(0.5),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  String _formatViews(dynamic views) {
    if (views == null) return '0';

    final intValue = views is int ? views : int.tryParse(views.toString()) ?? 0;

    if (intValue < 1000) return intValue.toString();
    if (intValue < 1000000) return '${(intValue / 1000).toStringAsFixed(1)}K';
    return '${(intValue / 1000000).toStringAsFixed(1)}M';
  }
}
