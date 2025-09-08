import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tiktok/authentication/login_screen.dart';
import 'package:tiktok/authentication/user.dart';
import 'package:tiktok/follow_service/follow_service.dart';
import 'package:tiktok/profile/edit_profile_screen.dart';
import 'package:tiktok/profile/follow_list_screen.dart';
import 'package:tiktok/profile/profile_video_play_screen.dart';
import 'package:tiktok/profile/profile_videos_grid_items.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;
  final bool isCurrentUser;

  const ProfileScreen({
    Key? key,
    required this.userId,
    this.isCurrentUser = false,
  }) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FollowService _followService = FollowService();
  // ignore: unused_field
  final ImagePicker _imagePicker = ImagePicker();

  AppUser? _user;
  bool _isLoading = true;
  int _followerCount = 0;
  int _followingCount = 0;
  int _videoCount = 0;
  int _totalLikes = 0;
  bool _isFollowing = false;
  int _selectedTabIndex = 0;
  final List<String> _profileTabs = ['Videos', 'Liked', 'Saved'];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _checkIfFollowing();
  }

  Future<void> _loadUserData() async {
    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(widget.userId)
          .get();
      if (userDoc.exists) {
        setState(() {
          _user = AppUser.fromSnap(userDoc);
        });

        // Load additional data
        await _loadFollowerCount();
        await _loadFollowingCount();
        await _loadVideoCount();
        await _loadTotalLikes();

        setState(() => _isLoading = false);
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error loading user data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadFollowerCount() async {
    final snapshot = await _firestore
        .collection('users')
        .doc(widget.userId)
        .collection('followers')
        .get();

    setState(() => _followerCount = snapshot.size);
  }

  Future<void> _loadFollowingCount() async {
    final snapshot = await _firestore
        .collection('users')
        .doc(widget.userId)
        .collection('following')
        .get();

    setState(() => _followingCount = snapshot.size);
  }

  Future<void> _loadVideoCount() async {
    final snapshot = await _firestore
        .collection('videos')
        .where('userId', isEqualTo: widget.userId)
        .get();

    setState(() => _videoCount = snapshot.size);
  }

  Future<void> _loadTotalLikes() async {
    try {
      final snapshot = await _firestore
          .collection('videos')
          .where('userId', isEqualTo: widget.userId)
          .get();

      int total = 0;
      for (var doc in snapshot.docs) {
        total += (doc.data()['likes'] as num? ?? 0).toInt();
      }

      setState(() => _totalLikes = total);
    } catch (e) {
      print('Error loading total likes: $e');
    }
  }

  Future<void> _checkIfFollowing() async {
    if (widget.isCurrentUser) {
      setState(() => _isFollowing = false);
      return;
    }

    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    final doc = await _firestore
        .collection('users')
        .doc(widget.userId)
        .collection('followers')
        .doc(currentUserId)
        .get();

    setState(() => _isFollowing = doc.exists);
  }

  Future<void> _toggleFollow() async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    if (_isFollowing) {
      await _followService.unfollowUser(widget.userId);
    } else {
      await _followService.followUser(widget.userId);
    }

    setState(() => _isFollowing = !_isFollowing);
    _loadFollowerCount(); // Refresh follower count
  }

  Future<void> _logout() async {
    try {
      final bool? confirm = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Logout', style: TextStyle(color: Colors.white)),
            content: Text(
              'Are you sure you want to logout?',
              style: TextStyle(color: Colors.white70),
            ),
            backgroundColor: Colors.grey[900],
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('Cancel', style: TextStyle(color: Colors.white)),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('Logout', style: TextStyle(color: Colors.red)),
              ),
            ],
          );
        },
      );

      if (confirm == true) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return Center(child: CircularProgressIndicator(color: Colors.red));
          },
        );

        await _auth.signOut();

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => LoginScreen()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error during logout: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _playVideoInFullScreen(String videoUrl, String videoId, int likes) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoPlayerScreen(
          videoUrl: videoUrl,
          videoId: videoId,
          likes: likes,
          autoPlay: true,
        ),
      ),
    );
  }

  void _navigateToEditProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            EditProfileScreen(user: _user!, onProfileUpdated: _loadUserData),
      ),
    );
  }

  void _navigateToFollowers() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            FollowListScreen(userId: widget.userId, mode: 'followers'),
      ),
    );
  }

  void _navigateToFollowing() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            FollowListScreen(userId: widget.userId, mode: 'following'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.red)),
      );
    }

    if (_user == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text('User not found', style: TextStyle(color: Colors.white)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text("${_user!.name}", style: TextStyle(color: Colors.white)),
        actions: widget.isCurrentUser
            ? [
                IconButton(
                  icon: Icon(Icons.logout, color: Colors.white),
                  onPressed: _logout,
                ),
              ]
            : null,
      ),
      body: DefaultTabController(
        length: _profileTabs.length,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    _buildProfileHeader(),
                    _buildProfileStats(),
                    _buildActionButtons(),
                    SizedBox(height: 16),
                  ],
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverAppBarDelegate(
                  TabBar(
                    indicatorColor: Colors.white,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.grey,
                    tabs: _profileTabs.map((tab) => Tab(text: tab)).toList(),
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
            children: [
              _buildVideoGrid(),
              _buildLikedVideos(),
              _buildSavedVideos(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: "${_user!.image}",
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[800],
                      child: Center(
                        child: CircularProgressIndicator(color: Colors.red),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[800],
                      child: Icon(Icons.person, color: Colors.white, size: 40),
                    ),
                  ),
                ),
              ),
              if (widget.isCurrentUser)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black, width: 2),
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: Icon(Icons.edit, size: 15, color: Colors.white),
                      onPressed: _navigateToEditProfile,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            "${_user!.name}",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          if ("${_user!.bio}".isNotEmpty)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                "${_user!.bio}",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProfileStats() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(_videoCount.toString(), 'Videos'),
          GestureDetector(
            onTap: _navigateToFollowers,
            child: _buildStatItem(_followerCount.toString(), 'Followers'),
          ),
          GestureDetector(
            onTap: _navigateToFollowing,
            child: _buildStatItem(_followingCount.toString(), 'Following'),
          ),
          _buildStatItem(_totalLikes.toString(), 'Likes'),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildActionButtons() {
    if (widget.isCurrentUser) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _navigateToEditProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[900],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text('Edit Profile'),
              ),
            ),
            SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                // Share profile functionality
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[900],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.all(12),
              ),
              child: Icon(Icons.person_add, size: 20),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: _toggleFollow,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isFollowing ? Colors.grey[800] : Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(_isFollowing ? 'Following' : 'Follow'),
            ),
          ),
          SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              // Message functionality
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[800],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: EdgeInsets.all(12),
            ),
            child: Icon(Icons.message, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('videos')
          .where('userId', isEqualTo: widget.userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator(color: Colors.red));
        }

        if (snapshot.data!.docs.isEmpty) {
          return Container(
            padding: EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.videocam_off, color: Colors.grey, size: 50),
                SizedBox(height: 16),
                Text(
                  'No videos yet',
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                if (widget.isCurrentUser)
                  TextButton(
                    onPressed: () {
                      // Navigate to upload screen
                    },
                    child: Text(
                      'Upload your first video',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
              ],
            ),
          );
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 2,
            mainAxisSpacing: 2,
            childAspectRatio: 0.7,
          ),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final video = snapshot.data!.docs[index];
            final data = video.data() as Map<String, dynamic>;
            final videoUrl = data['videoUrl'] ?? '';
            final thumbnailUrl = data['thumbnailUrl'] ?? '';
            final likes = (data['likes'] as num? ?? 0).toInt();
            final views = (data['views'] as num? ?? 0).toInt();

            return GestureDetector(
              onTap: () {
                _playVideoInFullScreen(videoUrl, video.id, likes);
              },
              child: Stack(
                children: [
                  VideoGridItem(videoId: video.id, thumbnailUrl: thumbnailUrl),
                  Positioned(
                    bottom: 8,
                    left: 8,
                    right: 8,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.play_arrow,
                              color: Colors.white,
                              size: 14,
                            ),
                            SizedBox(width: 4),
                            Text(
                              views.toString(),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.favorite, color: Colors.red, size: 12),
                            SizedBox(width: 4),
                            Text(
                              likes.toString(),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
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
          },
        );
      },
    );
  }

  Widget _buildLikedVideos() {
    // Implement liked videos functionality
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('videos')
          .where('likes', arrayContains: widget.userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator(color: Colors.red));
        }

        if (snapshot.data!.docs.isEmpty) {
          return Container(
            padding: EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.favorite_border, color: Colors.grey, size: 50),
                SizedBox(height: 16),
                Text(
                  'No liked videos yet',
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 2,
            mainAxisSpacing: 2,
            childAspectRatio: 0.7,
          ),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final video = snapshot.data!.docs[index];
            final data = video.data() as Map<String, dynamic>;
            final videoUrl = data['videoUrl'] ?? '';
            final thumbnailUrl = data['thumbnailUrl'] ?? '';
            final likes = (data['likes'] as num? ?? 0).toInt();

            return GestureDetector(
              onTap: () {
                _playVideoInFullScreen(videoUrl, video.id, likes);
              },
              child: Stack(
                children: [
                  VideoGridItem(videoId: video.id, thumbnailUrl: thumbnailUrl),
                  Positioned.fill(
                    child: Container(
                      // ignore: deprecated_member_use
                      color: Colors.black.withOpacity(0.3),
                      child: Center(
                        child: Icon(
                          Icons.favorite,
                          color: Colors.red,
                          size: 30,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSavedVideos() {
    // Implement saved videos functionality
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bookmark_border, color: Colors.grey, size: 50),
          SizedBox(height: 16),
          Text(
            'Saved videos will appear here',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: Colors.black, child: _tabBar);
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
