import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import 'package:tiktok/authentication/login_screen.dart';
import 'package:tiktok/authentication/user.dart';
import 'package:tiktok/chats/screens/chat_screen.dart';
import 'package:tiktok/follow_service/follow_service.dart';
import 'package:tiktok/for_you/save_videos/saved_video_grid.dart';
import 'package:tiktok/profile/edit_profile_screen.dart';
import 'package:tiktok/profile/follow_list_screen.dart';
import 'package:tiktok/profile/profile_video_playscreen.dart';
import 'package:tiktok/profile/profile_videos_grid_items.dart';
import 'package:tiktok/theme/theme.dart';
import 'package:tiktok/upload_videos/video.dart';
import 'package:tiktok/videos_upload/screens/camera_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;
  final bool isCurrentUser;

  const ProfileScreen({
    super.key,
    required this.userId,
    this.isCurrentUser = false,
  });

  @override
  // ignore: library_private_types_in_public_api
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FollowService _followService = FollowService();
  final ImagePicker imagePicker = ImagePicker();
  bool _isFollowLoading = false;
  AppUser? _user;
  bool _isLoading = true;
  int _followerCount = 0;
  int _followingCount = 0;
  int _videoCount = 0;
  bool _isFollowing = false;
  final List<String> _profileTabs = ['Videos', 'Saved'];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _checkIfFollowing();
  }

  void _shareProfile() {
    if (_user == null) return;

    final profileUrl = "https://tiktok.com/user/${widget.userId}";
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
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
          'TikTok v1.7.20\n\nA Flutter-based short video sharing application inspired by TikTok. Create, share, and discover amazing content!',
          style: TextStyle(
            color: Theme.of(
              context,
            ).textTheme.bodyLarge?.color?.withOpacity(0.7),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Colors.red)),
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

    try {
      if (_isFollowing) {
        _followService.unfollowUser(widget.userId);
        _followerCount = (_followerCount - 1).clamp(0, 999999);
      } else {
        _followService.followUser(widget.userId);
        _followerCount += 1;
      }

      setState(() {
        _isFollowing = !_isFollowing;
      });
    } catch (e) {
      debugPrint("Follow error: $e");
    }
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
                Navigator.pop(sheetContext);
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
      await _firestore.collection('videos').doc(videoId).delete();

      if (videoUrl.isNotEmpty) {
        await FirebaseStorage.instance.refFromURL(videoUrl).delete();
      }

      if (thumbUrl.isNotEmpty) {
        await FirebaseStorage.instance.refFromURL(thumbUrl).delete();
      }
    } catch (e) {
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

  // void _openChat() async {
  //   final currentUserId = _auth.currentUser!.uid;
  //   final otherUserId = widget.userId;

  //   final chatId = currentUserId.compareTo(otherUserId) < 0
  //       ? "$currentUserId-$otherUserId"
  //       : "$otherUserId-$currentUserId";

  //   final chatRef = _firestore.collection("chats").doc(chatId);

  //   Navigator.push(
  //     context,
  //     MaterialPageRoute(
  //       builder: (_) => ChatScreen(
  //         chatId: chatId,
  //         otherUserId: otherUserId,
  //         otherUserName: _user?.name ?? "User",
  //         otherUserPhoto: _user?.image ?? "",
  //       ),
  //     ),
  //   );

  //   Future.microtask(() async {
  //     final currentUserDoc = await _firestore
  //         .collection("users")
  //         .doc(currentUserId)
  //         .get();
  //     final otherUserDoc = await _firestore
  //         .collection("users")
  //         .doc(otherUserId)
  //         .get();

  //     final currentData = currentUserDoc.data() ?? {};
  //     final otherData = otherUserDoc.data() ?? {};

  //     final exists = await chatRef.get();

  //     if (!exists.exists) {
  //       await chatRef.set({
  //         "chatId": chatId,
  //         "participants": [currentUserId, otherUserId],
  //         "lastMessage": "",
  //         "lastTimestamp": FieldValue.serverTimestamp(),
  //       });
  //     }

  //     await chatRef.update({
  //       "user1": {
  //         "uid": currentUserId,
  //         "name": currentData["name"] ?? "",
  //         "image": currentData["image"] ?? "",
  //       },
  //       "user2": {
  //         "uid": otherUserId,
  //         "name": otherData["name"] ?? "",
  //         "image": otherData["image"] ?? "",
  //       },
  //       "lastTimestamp": FieldValue.serverTimestamp(),
  //     });
  //   });
  // }

  void _openChat() async {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    final otherUserId = widget.userId;

    // Consistent chat ID format: smallerId_largerId (with underscore)
    final chatId = currentUserId.compareTo(otherUserId) < 0
        ? "${currentUserId}_$otherUserId"
        : "${otherUserId}_$currentUserId";

    // Navigate immediately (don't wait for Firestore)
    Get.to(
      () => ChatScreen(
        chatId: chatId,
        otherUserId: otherUserId,
        otherUserName: _user?.name ?? "User",
        otherUserPhoto: _user?.image ?? "",
      ),
    );

    // Create or update chat document in background (fire-and-forget)
    //final chatRef = FirebaseFirestore.instance.collection('chats').doc(chatId);

    // try {
    //   final chatSnapshot = await chatRef.get();

    //   if (!chatSnapshot.exists) {
    //     await chatRef.set({
    //       'participants': [currentUserId, otherUserId],
    //       'lastMessage': 'Say hi!',
    //       'lastMessageTime': FieldValue.serverTimestamp(),
    //       'lastMessageType': 'text',
    //     }, SetOptions(merge: true));
    //   } else {
    //     // Just update timestamp so chat appears at top
    //     await chatRef.update({'lastMessageTime': FieldValue.serverTimestamp()});
    //   }
    // } catch (e) {
    //   debugPrint("Chat init error: $e");
    //   // Don't block UI even if this fails
    // }
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
                    const SizedBox(height: 8),
                    _buildProfileStats(),
                    const SizedBox(height: 16),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).dividerColor,
                        width: 1,
                      ),
                    ),
                    child: ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: _user!.image ?? '',
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[300],
                          child: Center(
                            child: CircularProgressIndicator(
                              color: Colors.red,
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[300],
                          child: Icon(
                            Icons.person,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black,
                            size: 30,
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
                        width: 24,
                        height: 24,
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
                            size: 12,
                            color: Colors.white,
                          ),
                          onPressed: _navigateToEditProfile,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _user!.name ?? "User",
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '@${_user!.name?.replaceAll(' ', '').toLowerCase() ?? "user"}',
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).textTheme.bodyLarge?.color?.withOpacity(0.6),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_user!.bio != null && _user!.bio!.isNotEmpty)
                      Text(
                        _user!.bio!,
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).textTheme.bodyLarge?.color?.withOpacity(0.7),
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileStats() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            label: 'Videos',
            value: formatNumber(_videoCount),
            onTap: null,
          ),

          _buildStatItem(
            label: 'Followers',
            value: formatNumber(_followerCount),
            onTap: _navigateToFollowers,
          ),

          _buildStatItem(
            label: 'Following',
            value: formatNumber(_followingCount),
            onTap: _navigateToFollowing,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required VoidCallback? onTap,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final buttonHeight = 37.0;
    final borderRadius = BorderRadius.circular(6);

    Widget buildButton({
      required String text,
      required VoidCallback onTap,
      required Color bg,
      required Color fg,
      FontWeight fw = FontWeight.w600,
    }) {
      return Container(
        height: buttonHeight,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: borderRadius,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: borderRadius,
            onTap: onTap,
            child: Center(
              child: Text(
                text,
                style: TextStyle(
                  color: fg,
                  fontSize: 15,
                  fontWeight: fw,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        ),
      );
    }

    // ---------- CURRENT USER ----------
    if (widget.isCurrentUser) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Row(
          children: [
            Expanded(
              child: buildButton(
                text: "Edit Profile",
                onTap: _navigateToEditProfile,
                bg: isDark
                    ? Color.fromARGB(255, 71, 70, 70)
                    : Color.fromARGB(255, 231, 230, 230),
                fg: isDark
                    ? const Color.fromARGB(255, 255, 255, 255)
                    : Colors.black,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: buildButton(
                text: "Share",
                onTap: _shareProfile,
                bg: isDark
                    ? Color.fromARGB(255, 71, 70, 70)
                    : Color.fromARGB(255, 231, 230, 230),
                fg: isDark
                    ? const Color.fromARGB(255, 255, 255, 255)
                    : Colors.black,
              ),
            ),
          ],
        ),
      );
    }

    // ---------- OTHER USER PROFILE ----------

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Row(
        children: [
          // Follow button (bigger)
          Expanded(
            flex: 2,
            child: buildButton(
              text: _isFollowing ? "Following" : "Follow",
              onTap: _toggleFollow,
              bg: _isFollowing
                  ? isDark
                        ? Color.fromARGB(255, 71, 70, 70)
                        : Colors.grey.shade200
                  : const Color.fromARGB(255, 255, 43, 43),
              fg: _isFollowing
                  ? isDark
                        ? Colors.grey.shade200
                        : Colors.black
                  : Colors.grey.shade200,
              fw: FontWeight.w700,
            ),
          ),

          const SizedBox(width: 12),

          // Message button
          Expanded(
            flex: 1,
            child: buildButton(
              text: "Message",
              onTap: _openChat,
              bg: isDark
                  ? Color.fromARGB(255, 71, 70, 70)
                  : Color.fromARGB(255, 231, 230, 230),
              fg: isDark
                  ? const Color.fromARGB(255, 255, 255, 255)
                  : Colors.black,
            ),
          ),

          const SizedBox(width: 12),

          // Share button
          Expanded(
            flex: 1,
            child: buildButton(
              text: "Share",
              onTap: _shareProfile,
              bg: isDark
                  ? Color.fromARGB(255, 71, 70, 70)
                  : Color.fromARGB(255, 231, 230, 230),
              fg: isDark
                  ? const Color.fromARGB(255, 255, 255, 255)
                  : Colors.black,
            ),
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
          .orderBy('publishedDateTime', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color.fromARGB(255, 255, 36, 20),
            ),
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
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CameraScreen(),
                        ),
                      );
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
            videoId: doc.id,
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
            views: data['views'],
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
                Get.to(
                  () => ProfileVideoFeedScreen(
                    videos: videos,
                    initialIndex: index,
                  ),
                );
              },
              child: VideoGridItem(
                videoId: "${video.videoId}",
                thumbnailUrl: "${video.thumbnailUrl}",
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSavedVideos() {
    if (!widget.isCurrentUser) {
      return Center(
        child: Text(
          "Saved videos are private",
          style: TextStyle(
            color: Theme.of(
              context,
            ).textTheme.bodyLarge?.color?.withOpacity(0.6),
            fontSize: 16,
          ),
        ),
      );
    }

    return SavedVideoGrid();
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

String formatNumber(int number) {
  if (number >= 1000000000) {
    return "${(number / 1000000000).toStringAsFixed(1)}B";
  } else if (number >= 1000000) {
    return "${(number / 1000000).toStringAsFixed(1)}M";
  } else if (number >= 1000) {
    return "${(number / 1000).toStringAsFixed(1)}K";
  } else {
    return number.toString();
  }
}
