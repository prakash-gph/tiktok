import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tiktok/share_videos/share_service.dart';
import 'package:tiktok/share_vieos/share_videos.models.dart';

class InternalShareSheet extends StatefulWidget {
  final String videoId;
  final String videoUrl;
  final String thumbnailUrl;
  final String description;
  final String senderId;
  final String senderName;
  final String senderImage;

  const InternalShareSheet({
    super.key,
    required this.videoId,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.description,
    required this.senderId,
    required this.senderName,
    required this.senderImage,
  });

  @override
  State<InternalShareSheet> createState() => _InternalShareSheetState();
}

class _InternalShareSheetState extends State<InternalShareSheet> {
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _selectedUserIds = <String>{};
  List<DocumentSnapshot> _allFollowers = [];
  List<DocumentSnapshot> _filteredUsers = [];
  bool _isLoading = true;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _loadFollowers();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), _filterUsers);
  }

  Future<void> _loadFollowers() async {
    // ... (your existing _loadFollowers logic remains unchanged)
    try {
      setState(() => _isLoading = true);

      final followersSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.senderId)
          .collection('followers')
          .get();

      final followerIds = followersSnap.docs.map((e) => e.id).toList();
      if (followerIds.isEmpty) {
        if (mounted) {
          setState(() {
            _allFollowers = [];
            _filteredUsers = [];
            _isLoading = false;
          });
        }
        return;
      }

      final List<DocumentSnapshot> users = [];
      for (int i = 0; i < followerIds.length; i += 10, i += 10) {
        final batch = followerIds.sublist(
          i,
          i + 10 > followerIds.length ? followerIds.length : i + 10,
        );
        final batchSnap = await FirebaseFirestore.instance
            .collection('users')
            .where(FieldPath.documentId, whereIn: batch)
            .get();
        users.addAll(batchSnap.docs);
      }

      if (mounted) {
        setState(() {
          _allFollowers = users;
          _filteredUsers = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        Get.snackbar(
          "Error",
          "Failed to load followers",
          backgroundColor: Colors.red,
        );
        setState(() => _isLoading = false);
      }
    }
  }

  void _filterUsers() {
    final query = _searchController.text.toLowerCase().trim();
    if (query.isEmpty) {
      setState(() => _filteredUsers = _allFollowers);
      return;
    }

    setState(() {
      _filteredUsers = _allFollowers.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final name = (data['name'] as String?)?.toLowerCase() ?? '';
        final username = (data['username'] as String?)?.toLowerCase() ?? '';
        return name.contains(query) || username.contains(query);
      }).toList();
    });
  }

  Future<void> _shareToSocial(String platform) async {
    final text = "${widget.description}\n${widget.videoUrl}";
    await Share.share(text, subject: 'Check out this video!');

    await shareVideoAndTrack(widget.videoId, widget.senderId);
    Get.snackbar(
      "Shared",
      "Shared to $platform",
      backgroundColor: Colors.green,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  Future<void> _sendToSelected() async {
    if (_selectedUserIds.isEmpty) return;

    Navigator.pop(context);

    await ShareService().shareVideoToUsers(
      videoId: widget.videoId,
      videoUrl: widget.videoUrl,
      thumbnailUrl: widget.thumbnailUrl,
      description: widget.description,
      senderId: widget.senderId,
      senderName: widget.senderName,
      senderImage: widget.senderImage,
      receiverIds: _selectedUserIds.toList(),
    );

    await shareVideoAndTrack(widget.videoId, widget.senderId);

    if (!mounted) return;

    Get.snackbar(
      "Success",
      "Video sent to ${_selectedUserIds.length} user${_selectedUserIds.length > 1 ? 's' : ''}!",
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Adaptive colors
    final backgroundColor = isDark ? const Color(0xFF121212) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.grey[400] : Colors.grey[600];
    final hintColor = isDark ? Colors.grey[500] : Colors.grey[600];
    final borderColor = isDark ? Colors.grey[800] : Colors.grey[300];
    Colors.blueAccent.withOpacity(isDark ? 0.2 : 0.1);
    final chipBgColor = Colors.blueAccent.withOpacity(isDark ? 0.2 : 0.15);

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header + Drag Handle
          Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[600] : Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.close, color: textColor),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          "Share Video",
                          style: TextStyle(
                            color: textColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _selectedUserIds.isEmpty
                          ? null
                          : _sendToSelected,
                      child: Text(
                        "Send",
                        style: TextStyle(
                          color: _selectedUserIds.isEmpty
                              ? Colors.grey
                              : Colors.blueAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Social Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                _SocialButton(
                  icon: Icons.more_horiz,
                  label: "More",
                  isDark: isDark,
                  onTap: () => _shareToSocial("Other"),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: borderColor),

          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                hintText: "Search followers...",
                hintStyle: TextStyle(color: hintColor),
                prefixIcon: Icon(Icons.search, color: hintColor),
                filled: true,
                fillColor: isDark ? Colors.grey[850] : Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),

          // Selected Count Chip
          if (_selectedUserIds.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Chip(
                  backgroundColor: chipBgColor,
                  label: Text(
                    "${_selectedUserIds.length} selected",
                    style: const TextStyle(color: Colors.blueAccent),
                  ),
                ),
              ),
            ),

          // Users List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredUsers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: isDark ? Colors.grey[600] : Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchController.text.isEmpty
                              ? "No followers yet"
                              : "No users found",
                          style: TextStyle(color: subtitleColor, fontSize: 16),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: _filteredUsers.length,
                    itemBuilder: (context, index) {
                      final doc = _filteredUsers[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final userId = doc.id;
                      final name = data['name'] ?? 'Unknown User';
                      final username = data['username'] ?? '';
                      final imageUrl = data['image'] as String?;

                      final isSelected = _selectedUserIds.contains(userId);

                      return UserTile(
                        userId: userId,
                        name: name,
                        username: username,
                        imageUrl: imageUrl,
                        isSelected: isSelected,
                        isDark: isDark,
                        onToggle: () {
                          setState(() {
                            if (isSelected) {
                              _selectedUserIds.remove(userId);
                            } else {
                              _selectedUserIds.add(userId);
                            }
                          });
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// Updated Social Button with theme support
class _SocialButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final VoidCallback onTap;

  const _SocialButton({
    required this.icon,
    required this.label,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
            child: Icon(
              icon,
              color: isDark ? Colors.white : Colors.black87,
              size: 28,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black54,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

// Updated UserTile with full theme support
class UserTile extends StatelessWidget {
  final String userId;
  final String name;
  final String? username;
  final String? imageUrl;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onToggle;

  const UserTile({
    super.key,
    required this.userId,
    required this.name,
    this.username,
    this.imageUrl,
    required this.isSelected,
    required this.isDark,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.grey[400] : Colors.grey[600];

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: Colors.grey[300],
        backgroundImage: imageUrl != null && imageUrl!.isNotEmpty
            ? NetworkImage(imageUrl!)
            : null,
        child: imageUrl == null || imageUrl!.isEmpty
            ? Icon(
                Icons.person,
                color: isDark ? Colors.grey[600] : Colors.grey[700],
              )
            : null,
      ),
      title: Text(
        name,
        style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
      ),
      subtitle: username != null && username!.isNotEmpty
          ? Text('@$username', style: TextStyle(color: subtitleColor))
          : null,
      trailing: Checkbox(
        value: isSelected,
        activeColor: Colors.blueAccent,
        side: BorderSide(color: isDark ? Colors.grey[600]! : Colors.grey[400]!),
        onChanged: (_) => onToggle(),
      ),
      selected: isSelected,
      selectedTileColor: Colors.blueAccent.withOpacity(isDark ? 0.2 : 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: onToggle,
    );
  }
}
