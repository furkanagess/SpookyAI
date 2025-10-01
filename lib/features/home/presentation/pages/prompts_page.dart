import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/premium_service.dart';
import '../../../../core/theme/app_metrics.dart';
import '../../../../core/widgets/token_display_widget.dart';
import '../../data/models/prompt_category.dart';
import '../../data/models/user_prompt.dart';
import '../../data/services/prompt_service.dart';
import '../../data/services/user_prompt_service.dart';
import '../widgets/add_prompt_dialog.dart';
import 'purchase_page.dart';

class PromptsPage extends StatefulWidget {
  final Function(String)? onPromptSelected;

  const PromptsPage({super.key, this.onPromptSelected});

  @override
  State<PromptsPage> createState() => _PromptsPageState();
}

class _PromptsPageState extends State<PromptsPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  List<PromptItem> _searchResults = [];
  List<UserPrompt> _userPromptSearchResults = [];
  List<UserPrompt> _userPrompts = [];
  bool _isSearching = false;
  bool _isPremium = false;
  StreamSubscription<bool>? _premiumStatusSubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length:
          PromptService.getAllCategories().length +
          2, // +1 for Popular, +1 for My Prompts
      vsync: this,
    );
    _loadUserPrompts();
    _loadPremiumStatus();
    _listenToPremiumStatusChanges();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload premium status when returning to this page
    _loadPremiumStatus();
  }

  Future<void> _loadUserPrompts() async {
    final userPrompts = await UserPromptService.getUserPrompts();
    if (mounted) {
      setState(() {
        _userPrompts = userPrompts;
      });
    }
  }

  Future<void> _loadPremiumStatus() async {
    try {
      final isPremium = await PremiumService.isPremiumUser();
      if (mounted) {
        setState(() {
          _isPremium = isPremium;
        });
        print('PromptsPage: Premium status updated - isPremium: $isPremium');
      }
    } catch (e) {
      print('PromptsPage: Error loading premium status: $e');
      if (mounted) {
        setState(() {
          _isPremium = false;
        });
      }
    }
  }

  void _listenToPremiumStatusChanges() {
    _premiumStatusSubscription = PremiumService.premiumStatusStream.listen(
      (isPremium) {
        if (mounted) {
          setState(() {
            _isPremium = isPremium;
          });
          print(
            'PromptsPage: Premium status changed via stream - isPremium: $isPremium',
          );
        }
      },
      onError: (error) {
        print('PromptsPage: Error listening to premium status: $error');
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _premiumStatusSubscription?.cancel();
    super.dispose();
  }

  void _onSearch(String query) async {
    setState(() {
      _isSearching = query.isNotEmpty;
    });

    if (_isSearching) {
      final builtInResults = PromptService.searchPrompts(query);
      final userResults = await UserPromptService.searchUserPrompts(query);

      if (mounted) {
        setState(() {
          _searchResults = builtInResults;
          _userPromptSearchResults = userResults;
        });
      }
    }
  }

  bool _isPromptPremium(PromptItem prompt) {
    // Make every other prompt premium (50% premium)
    // Use prompt title hash to determine if it's premium
    final hash = prompt.title.hashCode;
    return hash.abs() % 2 == 1; // Every second prompt is premium
  }

  void _onPromptTap(PromptItem prompt) async {
    // Check if prompt is premium and user is not premium
    if (_isPromptPremium(prompt) && !_isPremium) {
      _showPremiumRequiredDialog();
      return;
    }

    if (widget.onPromptSelected != null) {
      widget.onPromptSelected!(prompt.prompt);
    } else {
      // Show prompt details or copy to clipboard
      _showPromptDialog(prompt);
    }
  }

  void _onUserPromptTap(UserPrompt prompt) async {
    // Update usage count
    await UserPromptService.updatePromptUsage(prompt.id);

    if (widget.onPromptSelected != null) {
      widget.onPromptSelected!(prompt.prompt);
    } else {
      // Show prompt details or copy to clipboard
      _showUserPromptDialog(prompt);
    }
  }

  void _showPromptDialog(PromptItem prompt) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1D162B),
        title: Text(
          prompt.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                prompt.prompt,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Close',
              style: TextStyle(color: Color(0xFF8C7BA6)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _onPromptTap(prompt);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6A00),
              foregroundColor: Colors.white,
            ),
            child: const Text('Use Prompt'),
          ),
        ],
      ),
    );
  }

  void _showUserPromptDialog(UserPrompt prompt) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1D162B),
        title: Row(
          children: [
            Expanded(
              child: Text(
                prompt.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Color(0xFF8C7BA6)),
              onSelected: (value) async {
                if (value == 'edit') {
                  Navigator.of(context).pop();
                  _showAddPromptDialog(existingPrompt: prompt);
                } else if (value == 'delete') {
                  Navigator.of(context).pop();
                  _deleteUserPrompt(prompt);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, color: Color(0xFF8C7BA6), size: 16),
                      SizedBox(width: 8),
                      Text('Edit', style: TextStyle(color: Color(0xFF8C7BA6))),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red, size: 16),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                prompt.prompt,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    'Used ${prompt.usageCount} times',
                    style: const TextStyle(
                      color: Color(0xFF8C7BA6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Close',
              style: TextStyle(color: Color(0xFF8C7BA6)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _onUserPromptTap(prompt);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6A00),
              foregroundColor: Colors.white,
            ),
            child: const Text('Use Prompt'),
          ),
        ],
      ),
    );
  }

  void _showAddPromptDialog({UserPrompt? existingPrompt}) {
    showDialog(
      context: context,
      builder: (context) => AddPromptDialog(
        existingPrompt: existingPrompt,
        onPromptSaved: (savedPrompt) {
          _loadUserPrompts();
        },
      ),
    );
  }

  void _showPremiumRequiredDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1D162B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6A00), Color(0xFFFF8A00)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.star, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'Upgrade to Premium',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6A00).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFFF6A00).withOpacity(0.3),
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Premium Benefits:',
                    style: TextStyle(
                      color: Color(0xFFFF6A00),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• Access to all premium prompts',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  Text(
                    '• Daily spin wheel for free tokens',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  Text(
                    '• Higher token rewards',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  Text(
                    '• Exclusive premium-only features',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF8C7BA6),
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              // Navigate to purchase page and wait for return
              await Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const PurchasePage()));
              // Premium status will be updated automatically via stream
              // No need to manually reload
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6A00),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Upgrade Now'),
          ),
        ],
      ),
    );
  }

  void _deleteUserPrompt(UserPrompt prompt) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1D162B),
        title: const Text(
          'Delete Prompt',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to delete "${prompt.title}"? This action cannot be undone.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF8C7BA6)),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final success = await UserPromptService.deleteUserPrompt(
                prompt.id,
              );
              if (success && mounted) {
                _loadUserPrompts();
                NotificationService.success(
                  context,
                  message: NotificationService.promptDeleted,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                Icons.lightbulb_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Prompt Library',
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
          IconButton(
            onPressed: () => _showAddPromptDialog(),
            icon: const Icon(Icons.add, color: Colors.white),
            tooltip: 'Add Custom Prompt',
          ),
          TokenDisplayWidget(
            onTap: () async {
              await Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const PurchasePage()));
              // Premium status will be updated automatically via stream
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Column(
            children: [
              // Search Bar
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1D162B),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearch,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Search prompts...',
                    hintStyle: TextStyle(
                      color: Color(0xFF8C7BA6),
                      fontSize: 16,
                    ),
                    border: InputBorder.none,
                    prefixIcon: Icon(Icons.search, color: Color(0xFF8C7BA6)),
                  ),
                ),
              ),
              // Tab Bar
              Container(
                height: 50,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  indicatorColor: const Color(0xFFFF6A00),
                  indicatorWeight: 3,
                  labelColor: Colors.white,
                  unselectedLabelColor: const Color(0xFF8C7BA6),
                  labelStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                  tabs: [
                    const Tab(text: 'Popular'),
                    const Tab(text: 'My Prompts'),
                    ...PromptService.getAllCategories().map(
                      (category) => Tab(text: category.name),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: _isSearching ? _buildSearchResults() : _buildTabContent(),
    );
  }

  Widget _buildSearchResults() {
    final totalResults =
        _searchResults.length + _userPromptSearchResults.length;

    if (totalResults == 0) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Color(0xFF8C7BA6)),
            SizedBox(height: 16),
            Text(
              'No prompts found',
              style: TextStyle(
                color: Color(0xFF8C7BA6),
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Try different keywords',
              style: TextStyle(color: Color(0xFF8C7BA6), fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: totalResults,
      itemBuilder: (context, index) {
        if (index < _searchResults.length) {
          final prompt = _searchResults[index];
          return _buildPromptCard(prompt);
        } else {
          final userPrompt =
              _userPromptSearchResults[index - _searchResults.length];
          return _buildUserPromptCard(userPrompt);
        }
      },
    );
  }

  Widget _buildTabContent() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildPopularPrompts(),
        _buildMyPrompts(),
        ...PromptService.getAllCategories().map(
          (category) => _buildCategoryContent(category),
        ),
      ],
    );
  }

  Widget _buildPopularPrompts() {
    final popularPrompts = PromptService.getPopularPrompts();
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: popularPrompts.length,
      itemBuilder: (context, index) {
        final prompt = popularPrompts[index];
        return _buildPromptCard(prompt);
      },
    );
  }

  Widget _buildMyPrompts() {
    if (_userPrompts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF1D162B),
                borderRadius: BorderRadius.circular(40),
                border: Border.all(
                  color: const Color(0xFF8C7BA6).withOpacity(0.3),
                ),
              ),
              child: const Icon(
                Icons.lightbulb_outline,
                size: 40,
                color: Color(0xFF8C7BA6),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Custom Prompts Yet',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create your first custom prompt\nand it will appear here',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF8C7BA6),
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showAddPromptDialog(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6A00),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              icon: const Icon(Icons.add, size: 20),
              label: const Text(
                'Add First Prompt',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _userPrompts.length,
      itemBuilder: (context, index) {
        final prompt = _userPrompts[index];
        return _buildUserPromptCard(prompt);
      },
    );
  }

  Widget _buildCategoryContent(PromptCategory category) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: category.prompts.length,
      itemBuilder: (context, index) {
        final prompt = category.prompts[index];
        return _buildPromptCard(prompt);
      },
    );
  }

  Widget _buildPromptCard(PromptItem prompt) {
    final isPremiumPrompt = _isPromptPremium(prompt);
    final isLocked = isPremiumPrompt && !_isPremium;

    // Debug print for premium status
    print(
      'PromptsPage: Building prompt card - Title: ${prompt.title}, isPremiumPrompt: $isPremiumPrompt, _isPremium: $_isPremium, isLocked: $isLocked',
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1D162B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Stack(
        children: [
          InkWell(
            onTap: () => _onPromptTap(prompt),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF6A00), Color(0xFF9C27B0)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.auto_fix_high,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              prompt.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Row(
                              children: [
                                if (prompt.isPopular)
                                  Container(
                                    margin: const EdgeInsets.only(right: 6),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFFFF6A00,
                                      ).withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'Popular',
                                      style: TextStyle(
                                        color: Color(0xFFFF6A00),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                if (_isPromptPremium(prompt))
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFFFF6A00),
                                          Color(0xFFFF8A00),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.star,
                                          color: Colors.white,
                                          size: 10,
                                        ),
                                        SizedBox(width: 2),
                                        Text(
                                          'Premium',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
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
                      const Icon(
                        Icons.arrow_forward_ios,
                        color: Color(0xFF8C7BA6),
                        size: 16,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    prompt.prompt,
                    style: TextStyle(
                      color: isLocked
                          ? const Color(0xFF8C7BA6).withOpacity(0.3)
                          : const Color(0xFF8C7BA6),
                      fontSize: 14,
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),

          // Lock overlay for premium prompts (partial overlay)
          if (isLocked)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0F0B1A).withOpacity(0.7),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFFF6A00).withOpacity(0.3),
                  ),
                ),
                child: Stack(
                  children: [
                    // Semi-transparent overlay for the content area
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F0B1A).withOpacity(0.6),
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    // Lock icon and message at the center (clickable)
                    Center(
                      child: GestureDetector(
                        onTap: _showPremiumRequiredDialog,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1D162B).withOpacity(0.9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFFF6A00).withOpacity(0.5),
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFFF6A00),
                                      Color(0xFFFF8A00),
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.lock,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Premium Content',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Tap to upgrade',
                                style: TextStyle(
                                  color: Color(0xFF8C7BA6),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUserPromptCard(UserPrompt prompt) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1D162B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: InkWell(
        onTap: () => _onUserPromptTap(prompt),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF9C27B0), Color(0xFFFF6A00)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          prompt.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Used ${prompt.usageCount} times',
                          style: const TextStyle(
                            color: Color(0xFF8C7BA6),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(
                      Icons.more_vert,
                      color: Color(0xFF8C7BA6),
                      size: 20,
                    ),
                    onSelected: (value) async {
                      if (value == 'edit') {
                        _showAddPromptDialog(existingPrompt: prompt);
                      } else if (value == 'delete') {
                        _deleteUserPrompt(prompt);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(
                              Icons.edit,
                              color: Color(0xFF8C7BA6),
                              size: 16,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Edit',
                              style: TextStyle(color: Color(0xFF8C7BA6)),
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red, size: 16),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                prompt.prompt,
                style: const TextStyle(
                  color: Color(0xFF8C7BA6),
                  fontSize: 14,
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
