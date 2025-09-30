import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import 'package:tiktok/authentication/login_screen.dart';
import 'package:tiktok/authentication/user.dart';
import 'package:tiktok/follow_service/follow_service.dart';
import 'package:tiktok/for_you/for_you_video_screen.dart';
import 'package:tiktok/profile/edit_profile_screen.dart';
import 'package:tiktok/profile/follow_list_screen.dart';
import 'package:tiktok/profile/profile_video_play_screen.dart';
import 'package:tiktok/profile/profile_video_playscreen.dart';
import 'package:tiktok/profile/profile_videos_grid_items.dart';
import 'package:tiktok/theme/theme.dart';
import 'package:tiktok/upload_videos/video.dart';

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
  final ImagePicker imagePicker = ImagePicker();

  AppUser? _user;
  bool _isLoading = true;
  int _followerCount = 0;
  int _followingCount = 0;
  int _videoCount = 0;
  bool _isFollowing = false;
  final List<String> _profileTabs = ['Videos', 'Saved'];
  final bool _isFollowLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _checkIfFollowing();
  }

  void _shareProfile() {
    if (_user == null) return;

    final profileUrl = "https://mytiktokclone.com/user/${widget.userId}";
    final userName = _user!.name ?? 'User';

    Share.share(
      "Check out @$userName's profile on TikTok!\n$profileUrl",
      subject: "Follow @$userName on TikTok",
    );
  }

  void _shareApp() {
    Share.share(
      "Check out this amazing TikTok Clone app! Download it now to create and share short videos.",
      subject: "TikTok App",
    );
  }

  void _showSettingsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true, // Important for handling overflow
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        constraints: BoxConstraints(
          maxHeight:
              MediaQuery.of(context).size.height *
              0.8, // Limit height to 80% of screen
        ),
        child: SingleChildScrollView(
          // Allows scrolling if content overflows
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[600],
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Theme Toggle Item
              _buildThemeToggleItem(),

              _buildSettingsItem(
                icon: Icons.privacy_tip,
                text: 'Account Privacy',
                onTap: () {
                  Navigator.pop(context);
                  _showComingSoonSnackbar('Account Privacy');
                },
              ),

              _buildSettingsItem(
                icon: Icons.share,
                text: 'Share App',
                onTap: () {
                  Navigator.pop(context);
                  _shareApp();
                },
              ),

              _buildSettingsItem(
                icon: Icons.info,
                text: 'About',
                onTap: () {
                  Navigator.pop(context);
                  _showAboutDialog();
                },
              ),

              _buildSettingsItem(
                icon: Icons.policy,
                text: 'Terms and Conditions',
                onTap: () {
                  Navigator.pop(context);
                  _showComingSoonSnackbar('===');
                },
              ),
              _buildSettingsItem(
                icon: Icons.help,
                text: 'Help',
                onTap: () {
                  Navigator.pop(context);
                  _showComingSoonSnackbar('Help');
                },
              ),
              const SizedBox(height: 10),
              _buildSettingsItem(
                icon: Icons.logout,
                text: 'Logout',
                onTap: () {
                  Navigator.pop(context);
                  _logout();
                },
                isLogout: true,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(
          icon,
          color: isLogout ? Colors.red : Theme.of(context).iconTheme.color,
          size: 24,
        ),
        title: Text(
          text,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: isLogout
                ? Colors.red
                : Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        trailing: isLogout
            ? null
            : const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minLeadingWidth: 30,
        dense: true,
      ),
    );
  }

  Widget _buildThemeToggleItem() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return ListTile(
          leading: Icon(
            themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
            color: Theme.of(context).iconTheme.color,
            size: 24,
          ),
          title: Text(
            themeProvider.isDarkMode ? 'Dark Mode' : 'Light Mode',
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyLarge?.color,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          trailing: Switch(
            value: themeProvider.isDarkMode,
            onChanged: (value) {
              themeProvider.toggleTheme();
            },
            activeColor: Colors.red,
            activeTrackColor: Colors.red.withOpacity(0.5),
          ),
          onTap: () {
            themeProvider.toggleTheme();
          },
          contentPadding: const EdgeInsets.symmetric(vertical: 4),
        );
      },
    );
  }

  void _showComingSoonSnackbar(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature feature coming soon!'),
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[800]
            : Colors.grey[300],
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Text(
          'About TikTok',
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge?.color,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'TikTok Clone v1.0.0\n\nA Flutter-based short video sharing application inspired by TikTok. Create, share, and discover amazing content!',
          style: TextStyle(
            color: Theme.of(
              context,
            ).textTheme.bodyLarge?.color?.withOpacity(0.7),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _loadUserData() async {
    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(widget.userId)
          .get();

      if (!mounted) return;

      if (userDoc.exists) {
        setState(() {
          _user = AppUser.fromSnap(userDoc);
        });

        await _loadFollowerCount();
        await _loadFollowingCount();
        await _loadVideoCount();

        if (mounted) {
          setState(() => _isLoading = false);
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadFollowerCount() async {
    final snapshot = await _firestore
        .collection('users')
        .doc(widget.userId)
        .collection('followers')
        .get();
    if (mounted) {
      setState(() => _followerCount = snapshot.size);
    }
  }

  Future<void> _loadFollowingCount() async {
    final snapshot = await _firestore
        .collection('users')
        .doc(widget.userId)
        .collection('following')
        .get();

    if (mounted) {
      setState(() => _followingCount = snapshot.size);
    }
  }

  Future<void> _loadVideoCount() async {
    final snapshot = await _firestore
        .collection('videos')
        .where('userId', isEqualTo: widget.userId)
        .get();
    if (mounted) {
      setState(() => _videoCount = snapshot.size);
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
    _loadFollowerCount();
  }

  Future<void> _logout() async {
    try {
      final bool? confirm = await showDialog(
        context: context,

        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(
              'Logout',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            content: Text(
              'Are you sure you want to logout?',
              style: TextStyle(
                color: Theme.of(
                  context,
                ).textTheme.bodyLarge?.color?.withOpacity(0.7),
              ),
            ),
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          );
        },
      );

      if (confirm == true) {
        showDialog(
          // ignore: use_build_context_synchronously
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.red),
            );
          },
        );

        await _auth.signOut();

        // ignore: use_build_context_synchronously
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error during logout: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showDeleteVideoSheet(
    String videoId,
    String videoUrl,
    String thumbUrl,
  ) async {
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[500],
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Delete Video?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(sheetContext).textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'This action cannot be undone.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(
                  sheetContext,
                ).textTheme.bodyLarge?.color?.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                if (!mounted) return;
                Navigator.pop(sheetContext); // Close sheet first

                await _deleteVideo(videoId, videoUrl, thumbUrl);
              },
              child: const Text(
                'Delete',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.pop(sheetContext),
              child: const Text('Cancel', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteVideo(
    String videoId,
    String videoUrl,
    String thumbUrl,
  ) async {
    if (!mounted) return;

    try {
      // Delete video document
      await _firestore.collection('videos').doc(videoId).delete();

      // Delete video from storage
      if (videoUrl.isNotEmpty) {
        await FirebaseStorage.instance.refFromURL(videoUrl).delete();
      }

      // Delete thumbnail
      if (thumbUrl.isNotEmpty) {
        await FirebaseStorage.instance.refFromURL(thumbUrl).delete();
      }

      // if (!mounted) return;
      // Navigator.of(context, rootNavigator: true).pop(); // Close loading

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Video deleted successfully"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // Close loading
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to delete video: $e"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _navigateToEditProfile() {
    if (_user == null || !mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(
          user: _user!,
          onProfileUpdated: () {
            // Use a slight delay to ensure the edit screen is fully dismissed
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) {
                _loadUserData();
              }
            });
          },
        ),
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
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator(color: Colors.red)),
      );
    }

    if (_user == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: Text(
            'User not found',
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        title: Text(
          _user!.name ?? "User",
          style: TextStyle(
            color: Theme.of(context).appBarTheme.foregroundColor,
          ),
        ),
        actions: widget.isCurrentUser
            ? [
                IconButton(
                  icon: Icon(
                    Icons.settings_outlined,
                    color: Theme.of(context).appBarTheme.foregroundColor,
                  ),
                  onPressed: _showSettingsMenu,
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
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverAppBarDelegate(
                  TabBar(
                    indicatorColor: Theme.of(
                      context,
                    ).tabBarTheme.indicatorColor,
                    labelColor: Theme.of(context).tabBarTheme.labelColor,
                    unselectedLabelColor: Theme.of(
                      context,
                    ).tabBarTheme.unselectedLabelColor,
                    tabs: _profileTabs.map((tab) => Tab(text: tab)).toList(),
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(children: [_buildVideoGrid(), _buildSavedVideos()]),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
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
                  border: Border.all(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: _user!.image ?? '',
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[300],
                      child: Center(
                        child: CircularProgressIndicator(color: Colors.red),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[300],
                      child: Icon(
                        Icons.person,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                        size: 40,
                      ),
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
                      border: Border.all(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        width: 2,
                      ),
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(
                        Icons.edit,
                        size: 15,
                        color: Colors.white,
                      ),
                      onPressed: _navigateToEditProfile,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _user!.name ?? "User",
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyLarge?.color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          if (_user!.bio != null && _user!.bio!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                _user!.bio!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.color?.withOpacity(0.7),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProfileStats() {
    // ignore: no_leading_underscores_for_local_identifiers
    String _formatCount(int count) {
      if (count < 1000) return count.toString();
      if (count < 1000000) return '${(count / 1000).toStringAsFixed(1)}K';
      return '${(count / 1000000).toStringAsFixed(1)}M';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(_formatCount(_videoCount), 'Videos'),
          _buildTappableStatItem(
            _formatCount(_followerCount),
            'Followers',
            _navigateToFollowers,
          ),
          _buildTappableStatItem(
            _formatCount(_followingCount),
            'Following',
            _navigateToFollowing,
          ),
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
            color: Theme.of(context).textTheme.bodyLarge?.color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Theme.of(
              context,
            ).textTheme.bodyLarge?.color?.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildTappableStatItem(
    String value,
    String label,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF7E5555), Color(0xFF541010)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[700]!
                  : Colors.grey[300]!,
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      blurRadius: 4,
                      color: Colors.black,
                      offset: Offset(1, 1),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[200],
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    final buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.grey[900]
          : Colors.grey[200],
      foregroundColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.white
          : Colors.black,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.symmetric(vertical: 12),
    );

    if (widget.isCurrentUser) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _navigateToEditProfile,
                style: buttonStyle,
                child: const Text('Edit Profile'),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _shareProfile,
              style: buttonStyle.copyWith(
                padding: const MaterialStatePropertyAll(EdgeInsets.all(12)),
              ),
              child: const Icon(Icons.share, size: 20),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Expanded(
          //   child: ElevatedButton(
          //     onPressed: _toggleFollow,
          //     style: ElevatedButton.styleFrom(
          //       backgroundColor: _isFollowing
          //           ? (Theme.of(context).brightness == Brightness.dark
          //                 ? Colors.grey[800]
          //                 : const Color.fromARGB(255, 163, 90, 90))
          //           : Colors.red,
          //       foregroundColor: Colors.white,
          //       shape: RoundedRectangleBorder(
          //         borderRadius: BorderRadius.circular(8),
          //       ),
          //       padding: const EdgeInsets.symmetric(vertical: 12),
          //     ),
          //     child: Text(
          //       _isFollowing ? 'Unfollow' : 'Follow',
          //       style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
          //     ),
          //   ),
          // ),
          Expanded(
            child: ElevatedButton(
              onPressed: _isFollowLoading ? null : _toggleFollow,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isFollowing
                    ? (Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[800]
                          : const Color.fromARGB(255, 163, 90, 90))
                    : Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return ScaleTransition(
                    scale: animation,
                    child: FadeTransition(opacity: animation, child: child),
                  );
                },
                child: _isFollowLoading
                    ? const SizedBox(
                        key: ValueKey("loader"),
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        _isFollowing ? 'Unfollow ↓' : 'Follow',
                        key: ValueKey<String>(
                          _isFollowing ? "Unfollow ↓" : "Follow",
                        ),
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 17,
                        ),
                      ),
              ),
            ),
          ),

          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              // Message functionality
              // share  functionality
              _shareProfile();
            },
            style: buttonStyle.copyWith(
              padding: const MaterialStatePropertyAll(EdgeInsets.all(12)),
            ),
            child: const Icon(Icons.share_outlined, size: 20),
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
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.red),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.videocam_off,
                  color: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.color?.withOpacity(0.5),
                  size: 50,
                ),
                const SizedBox(height: 16),
                Text(
                  'No videos yet',
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.color?.withOpacity(0.5),
                  ),
                  textAlign: TextAlign.center,
                ),
                if (widget.isCurrentUser)
                  TextButton(
                    onPressed: () {
                      // Navigate to upload screen
                    },
                    child: const Text(
                      'Upload your first video',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
              ],
            ),
          );
        }

        final videos = snapshot.data!.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return Video(
            videoId: doc.id, // Keep the Firestore document ID here
            videoUrl: data['videoUrl'] ?? '',
            thumbnailUrl: data['thumbnailUrl'] ?? '',
            totalComments: data['totalComments'],
            likesList: data['likesList'],
            totalShares: data['totalShares'],
            userId: data['userId'],
            userName: _user!.name ?? 'User',
            userProfileImage: _user!.image ?? '',
            descriptionTags: data['descriptionTags'],
            artistSongName: data['artistSongName'],
          );
        }).toList();

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 2,
            mainAxisSpacing: 2,
            childAspectRatio: 0.7,
          ),
          itemCount: videos.length,
          itemBuilder: (context, index) {
            final video = videos[index];

            return GestureDetector(
              onLongPress: widget.isCurrentUser
                  ? () => _showDeleteVideoSheet(
                      "${video.videoId}",
                      "${video.videoUrl}",
                      "${video.thumbnailUrl}",
                    )
                  : null,

              onTap: () {
                // Open vertical swipe video feed with GetX
                Get.to(
                  () => ProfileVideoFeedScreen(
                    videos: videos,
                    initialIndex: index,
                  ),
                );
              },
              child: VideoGridItem(
                videoId: "${video.videoId}", // Pass the correct document ID
                thumbnailUrl: "${video.thumbnailUrl}",
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSavedVideos() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bookmark_border,
            color: Theme.of(
              context,
            ).textTheme.bodyLarge?.color?.withOpacity(0.5),
            size: 50,
          ),
          const SizedBox(height: 16),
          Text(
            'Saved videos will appear here',
            style: TextStyle(
              color: Theme.of(
                context,
              ).textTheme.bodyLarge?.color?.withOpacity(0.5),
            ),
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
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
