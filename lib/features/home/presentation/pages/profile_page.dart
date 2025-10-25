import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/avatar_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/widgets/token_display_widget.dart';
import '../../../../core/widgets/rewarded_ad_widget.dart';
import '../../../../core/services/saved_images_provider.dart';
import '../../../../core/services/profile_provider.dart';
import '../../../../core/services/version_service.dart';
import '../../../../core/theme/app_metrics.dart';
import '../widgets/image_selection_dialog.dart';
import 'spin_page.dart';
import 'purchase_page.dart';
import 'stats_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    // Load profile data through provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileProvider>().loadProfileData();
    });
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
        );

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _showAvatarSelectionDialog() async {
    final savedImages = context.read<SavedImagesProvider>().images;

    if (savedImages.isEmpty) {
      NotificationService.info(
        context,
        message: 'No generated images found. Create some images first!',
      );
      return;
    }

    // Convert SavedImage list to Map list for dialog
    final imagesForDialog = await Future.wait(
      savedImages.map((image) async {
        final bytes = await context.read<SavedImagesProvider>().getImageBytes(
          image.id,
          image.filePath,
        );
        return {
          'id': image.id,
          'bytes': bytes,
          'prompt': image.prompt,
          'createdAt': image.createdAt,
        };
      }),
    );

    final selectedImage = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => ImageSelectionDialog(
        images: imagesForDialog.where((img) => img['bytes'] != null).toList(),
        title: 'Select Avatar',
        subtitle: 'Choose one of your generated images as profile picture',
      ),
    );

    if (selectedImage != null) {
      await context.read<ProfileProvider>().setAvatarFromImage(selectedImage);
      if (mounted) {
        NotificationService.success(
          context,
          message: 'Avatar updated successfully!',
        );
      }
    }
  }

  Future<void> _showDefaultAvatarDialog() async {
    final defaultAvatars = AvatarService.getDefaultAvatars();
    final currentDefault = await AvatarService.getDefaultAvatar();

    final selectedAvatar = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1D162B),
        title: const Text(
          'Choose Avatar',
          style: TextStyle(color: Colors.white),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: defaultAvatars.length,
            itemBuilder: (context, index) {
              final avatar = defaultAvatars[index];
              final isSelected = avatar['name'] == currentDefault;

              return GestureDetector(
                onTap: () => Navigator.of(context).pop(avatar),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFFF6A00).withOpacity(0.2)
                        : const Color(0xFF2A1F3D),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFFFF6A00)
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        avatar['icon'],
                        style: const TextStyle(fontSize: 32),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        avatar['displayName'],
                        style: TextStyle(
                          color: isSelected
                              ? const Color(0xFFFF6A00)
                              : Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF8C7BA6)),
            ),
          ),
        ],
      ),
    );

    if (selectedAvatar != null) {
      await context.read<ProfileProvider>().setDefaultAvatar(selectedAvatar);
      if (mounted) {
        NotificationService.success(context, message: 'Avatar selected!');
      }
    }
  }

  Future<void> _removeAvatar() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1D162B),
        title: const Text(
          'Remove Avatar',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to remove your custom avatar?',
          style: TextStyle(color: Color(0xFF8C7BA6)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF8C7BA6)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await context.read<ProfileProvider>().removeAvatar();
      if (mounted) {
        NotificationService.success(
          context,
          message: 'Avatar removed successfully!',
        );
      }
    }
  }

  Widget _buildProfileHeader(ProfileProvider provider) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1D162B),
            const Color(0xFF2A1F3D).withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar with modern design
          Stack(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [const Color(0xFFFF6A00), const Color(0xFF9C27B0)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF6A00).withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: provider.currentAvatar != null
                      ? Image.memory(provider.currentAvatar!, fit: BoxFit.cover)
                      : FutureBuilder<String>(
                          future: AvatarService.getDefaultAvatar(),
                          builder: (context, snapshot) {
                            final avatarName = snapshot.data ?? 'ghost';
                            final avatars = AvatarService.getDefaultAvatars();
                            final avatar = avatars.firstWhere(
                              (a) => a['name'] == avatarName,
                              orElse: () => avatars.first,
                            );

                            return Container(
                              color: const Color(0xFF2A1F3D),
                              child: Center(
                                child: Text(
                                  avatar['icon'],
                                  style: const TextStyle(fontSize: 40),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ),
              // Loading overlay
              if (provider.isLoading)
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withOpacity(0.7),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFFF6A00),
                      strokeWidth: 3,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // User info
          GestureDetector(
            onTap: () => _showUsernameEditDialog(provider),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    provider.username,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.edit, color: Colors.white, size: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (provider.isPremium) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF6A00), Color(0xFFFF8A00)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, color: Colors.white, size: 12),
                      SizedBox(width: 4),
                      Text(
                        'PREMIUM',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 20),

          // Avatar actions
          Row(
            children: [
              Expanded(
                child: _buildAvatarActionButton(
                  icon: Icons.image,
                  label: 'From Image',
                  onTap: _showAvatarSelectionDialog,
                  isPrimary: true,
                  provider: provider,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildAvatarActionButton(
                  icon: Icons.emoji_emotions,
                  label: 'Avatar',
                  onTap: _showDefaultAvatarDialog,
                  isPrimary: false,
                  provider: provider,
                ),
              ),
              if (provider.currentAvatar != null) ...[
                const SizedBox(width: 12),
                _buildAvatarActionButton(
                  icon: Icons.delete_outline,
                  label: '',
                  onTap: _removeAvatar,
                  isPrimary: false,
                  isDelete: true,
                  provider: provider,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isPrimary,
    bool isDelete = false,
    required ProfileProvider provider,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: provider.isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: isDelete
                ? Colors.red.withOpacity(0.1)
                : isPrimary
                ? const Color(0xFFFF6A00).withOpacity(0.1)
                : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDelete
                  ? Colors.red.withOpacity(0.3)
                  : isPrimary
                  ? const Color(0xFFFF6A00).withOpacity(0.3)
                  : Colors.white.withOpacity(0.1),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isDelete
                    ? Colors.red
                    : isPrimary
                    ? const Color(0xFFFF6A00)
                    : Colors.white.withOpacity(0.8),
              ),
              if (label.isNotEmpty) ...[
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: isDelete
                        ? Colors.red
                        : isPrimary
                        ? const Color(0xFFFF6A00)
                        : Colors.white.withOpacity(0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Daily reward feature removed

  Widget _buildActionsSection(ProfileProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1D162B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6A00), Color(0xFF9C27B0)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.flash_on,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Quick Actions',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              // Daily reward removed
            ],
          ),
          const SizedBox(height: 20),

          // Rewarded Ad Widget
          const RewardedAdWidget(
            customMessage:
                'Watch ads to earn free tokens for image generation!',
          ),
          const SizedBox(height: 20),

          // Navigation Buttons
          Row(
            children: [
              Expanded(
                child: _buildNavigationButton(
                  icon: Icons.casino,
                  title: 'Spin Wheel',
                  subtitle: 'Try your luck',
                  onTap: () {
                    Navigator.of(context)
                        .push(
                          MaterialPageRoute(builder: (_) => const SpinPage()),
                        )
                        .then((_) {
                          provider.refreshProfileData();
                        });
                  },
                  color: const Color(0xFFFF6A00),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildNavigationButton(
                  icon: Icons.analytics,
                  title: 'Statistics',
                  subtitle: 'View your stats',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const StatsPage()),
                    );
                  },
                  color: const Color(0xFF2196F3),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // _buildDailyRewardButton removed

  Widget _buildNavigationButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: color.withOpacity(0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Icon(
                Icons.arrow_forward,
                color: color.withOpacity(0.6),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showUsernameEditDialog(ProfileProvider provider) async {
    final TextEditingController controller = TextEditingController(
      text: provider.username,
    );

    await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1D162B),
        title: const Text(
          'Edit Username',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter your custom username:',
              style: TextStyle(color: Color(0xFF8C7BA6), fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Enter username...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                filled: true,
                fillColor: const Color(0xFF2A1F3D),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFFF6A00)),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              maxLength: 20,
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF8C7BA6)),
            ),
          ),
          TextButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty && newName != provider.username) {
                await provider.updateUsername(newName);
                Navigator.of(context).pop();
                NotificationService.success(
                  context,
                  message: 'Username updated successfully!',
                );
              } else {
                Navigator.of(context).pop();
              }
            },
            child: const Text(
              'Save',
              style: TextStyle(color: Color(0xFFFF6A00)),
            ),
          ),
        ],
      ),
    );
  }

  // _activatePremiumDemo removed (unused)

  // _deactivatePremiumDemo removed (unused)

  // _openPremiumTesterMenu removed (unused)

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          backgroundColor: const Color(0xFF0F0B1A),
          appBar: AppBar(
            title: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF6A00), Color(0xFF9C27B0)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Profile',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF0F0B1A),
            elevation: 0,
            toolbarHeight: AppMetrics.toolbarHeight,
            actions: [
              // Premium toggle button
              // Container(
              //   margin: const EdgeInsets.only(right: 8),
              //   child: IconButton(
              //     onPressed: _openPremiumTesterMenu,
              //     icon: Icon(
              //       provider.isPremium ? Icons.star : Icons.star_border,
              //       color: provider.isPremium
              //           ? const Color(0xFFFF6A00)
              //           : Colors.white,
              //     ),
              //     tooltip: 'Premium Tester',
              //   ),
              // ),
              TokenDisplayWidget(
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PurchasePage()),
                  );
                },
              ),
            ],
          ),
          body: Stack(
            children: [
              // Background decorations
              Positioned(
                bottom: 40,
                left: 20,
                child: Opacity(
                  opacity: 0.06,
                  child: Text('🕸️', style: TextStyle(fontSize: 80)),
                ),
              ),
              Positioned(
                top: 60,
                right: 20,
                child: Opacity(
                  opacity: 0.04,
                  child: Text('🎃', style: TextStyle(fontSize: 60)),
                ),
              ),
              Positioned(
                top: 120,
                left: 40,
                child: Opacity(
                  opacity: 0.04,
                  child: Text('🕷️', style: TextStyle(fontSize: 50)),
                ),
              ),

              // Main content
              FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: provider.isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFFF6A00),
                          ),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              _buildProfileHeader(provider),
                              const SizedBox(height: 20),
                              _buildActionsSection(provider),
                              const SizedBox(height: 20),
                              _buildVersionInfo(),
                              const SizedBox(height: 20), // Bottom padding
                            ],
                          ),
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVersionInfo() {
    return FutureBuilder<Map<String, String>>(
      future: VersionService.getVersionInfo(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final versionInfo = snapshot.data!;
        final version = versionInfo['version'] ?? '1.1.0';
        final buildNumber = versionInfo['buildNumber'] ?? '15';
        final isDebug = versionInfo['isDebug'] == 'true';
        final platform = versionInfo['platform'] ?? 'SpookyAI';

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1D162B).withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.white.withOpacity(0.7),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Version $version ($buildNumber)',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (isDebug) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: Colors.orange.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'DEBUG',
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'SpookyAI - AI-Powered Halloween Image Generator',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Text(
                'Build $buildNumber • $platform',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 9,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }
}
