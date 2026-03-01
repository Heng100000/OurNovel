import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:http/http.dart' as http;
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/widgets/global_loader.dart';
import '../../../menu/presentation/pages/menu_page.dart';
import '../../../../theme/theme_service.dart';
import '../../../../core/services/realtime_service.dart';
import '../../../../l10n/language_service.dart';
import '../../../../core/models/news_announcement.dart';
import '../../../home/data/news_service.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  String _selectedCategory = 'all';
  List<NewsAnnouncement> _newsAnnouncements = [];
  bool _isLoading = true;
  final NewsService _newsService = NewsService();
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchNews();
    RealtimeService().addListener(_onRealtimeUpdate);
  }

  void _onRealtimeUpdate() {
    if (mounted) {
      _fetchNews();
    }
  }

  @override
  void dispose() {
    RealtimeService().removeListener(_onRealtimeUpdate);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchNews() async {
    final news = await _newsService.getNewsAnnouncements();
    if (mounted) {
      setState(() {
        _newsAnnouncements = news;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeService, LanguageService>(
      builder: (context, themeService, langService, child) {
        final isDark = themeService.isDarkMode;
        final bgColor = isDark ? const Color(0xFF121212) : AppColors.background;
        
        final List<Map<String, dynamic>> categories = [
          {'key': 'all', 'name': langService.translate('view_all'), 'icon': Icons.all_inclusive, 'color': AppColors.primary},
          {'key': 'Sales', 'name': langService.translate('sales'), 'icon': Icons.percent, 'color': const Color(0xFFF2994A)},
          {'key': 'Promotion', 'name': langService.translate('promotion'), 'icon': Icons.campaign, 'color': const Color(0xFF9B51E0)},
          {'key': 'General', 'name': langService.translate('general'), 'icon': Icons.notifications, 'color': const Color(0xFFBB6BD9)},
        ];

        final filteredAnnouncements = _newsAnnouncements.where((item) {
          if (_selectedCategory != 'all' && item.typeNews != _selectedCategory) {
            return false;
          }
          if (_searchQuery.isNotEmpty) {
            final title = item.title.toLowerCase();
            final desc = item.description.toLowerCase();
            final query = _searchQuery.toLowerCase();
            return title.contains(query) || desc.contains(query);
          }
          return true;
        }).toList();

        return Scaffold(
          backgroundColor: bgColor,
          drawer: const SideMenuDrawer(),
          body: RefreshIndicator(
            onRefresh: _fetchNews,
            color: AppColors.primary,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
              _buildSliverHeader(context, filteredAnnouncements, isDark, langService),
              
              SliverToBoxAdapter(
                child: _buildCategoryFilters(categories, isDark),
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 40),
                sliver: _isLoading
                    ? const SliverToBoxAdapter(
                        child: Center(child: GlobalLoader(size: 40)),
                      )
                    : filteredAnnouncements.isEmpty
                        ? SliverToBoxAdapter(
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(40.0),
                                child: Text(
                                  langService.translate('no_notifications'),
                                  style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
                                ),
                              ),
                            ),
                          )
                        : SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final item = filteredAnnouncements[index];
                                return _CoolNotificationCard(
                                  data: {
                                    'title': item.title,
                                    'date': item.createdAt != null
                                        ? DateFormat('yyyy-MM-dd h:mm a').format(item.createdAt!)
                                        : '',
                                    'message': item.description,
                                    'image': item.imageUrl,
                                    'isUnread': false,
                                    'category': item.typeNews ?? 'General',
                                    'id': item.id,
                                  },
                                  isNetworkImage: true,
                                  isDark: isDark,
                                );
                              },
                              childCount: filteredAnnouncements.length,
                            ),
                    ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSliverHeader(BuildContext context, List<NewsAnnouncement> filteredAnnouncements, bool isDark, LanguageService langService) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 130,
      backgroundColor: AppColors.primary,
      elevation: 0,
      automaticallyImplyLeading: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(35),
          bottomRight: Radius.circular(35),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark 
                ? [const Color(0xFF1A2410), const Color(0xFF2D3A1D)] 
                : [AppColors.primary, AppColors.primaryLight],
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(35),
              bottomRight: Radius.circular(35),
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                top: -20,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              
              Padding(
                padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 10, left: 10, right: 10),
                child: Row(
                  children: [
                    if (!_isSearching) ...[
                      Builder(
                        builder: (context) => IconButton(
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.menu, color: Colors.white, size: 22),
                          ),
                          onPressed: () => Scaffold.of(context).openDrawer(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        langService.translate('notifications'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => setState(() => _isSearching = true),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                            ),
                          child: const Icon(Icons.search, color: Colors.white, size: 22),
                        ),
                      ),
                    ] else ...[
                      Expanded(
                        child: Container(
                          height: 45,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: TextField(
                            controller: _searchController,
                            autofocus: true,
                            style: const TextStyle(color: Colors.white, fontSize: 16),
                            decoration: InputDecoration(
                              hintText: langService.translate('search_notifications'),
                              hintStyle: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
                              border: AppColors.background == Colors.transparent ? InputBorder.none : InputBorder.none,
                              prefixIcon: const Icon(Icons.search, color: Colors.white70, size: 20),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                                onPressed: () {
                                  setState(() {
                                    _isSearching = false;
                                    _searchController.clear();
                                    _searchQuery = '';
                                  });
                                },
                              ),
                              contentPadding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            onChanged: (value) {
                              setState(() {
                                _searchQuery = value;
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              Positioned(
                bottom: 15,
                left: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      langService.translate('latest_news'),
                      style: const TextStyle(
                        color: AppColors.accentYellow,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _searchQuery.isEmpty 
                        ? langService.translate('you_have_notifications').replaceFirst('%s', _newsAnnouncements.length.toString())
                        : langService.translate('found_results').replaceFirst('%s', filteredAnnouncements.length.toString()),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilters(List<Map<String, dynamic>> categories, bool isDark) {
    return Container(
      height: 50,
      margin: const EdgeInsets.only(top: 20, bottom: 5),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = _selectedCategory == cat['key'];
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = cat['key']),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: isSelected ? AppColors.primary.withOpacity(0.3) : Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: isSelected ? Colors.transparent : (isDark ? Colors.white10 : Colors.grey.shade100),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    cat['icon'],
                    color: isSelected ? Colors.white : cat['color'],
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    cat['name'],
                    style: TextStyle(
                      color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.grey[600]),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CoolNotificationCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isNetworkImage;
  final bool isDark;

  const _CoolNotificationCard({required this.data, this.isNetworkImage = false, required this.isDark});

  @override
  Widget build(BuildContext context) {
    bool isUnread = data['isUnread'] ?? false;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF1F2937);
    final secondaryTextColor = isDark ? Colors.white70 : Colors.grey[600];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isUnread ? AppColors.primary.withOpacity(0.1) : (isDark ? Colors.white10 : Colors.grey[100]),
                          shape: BoxShape.circle,
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/novel_book_logo.jpg',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.notifications_active_outlined,
                              color: isUnread ? AppColors.primary : (isDark ? Colors.white38 : Colors.grey[400]),
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                      if (isUnread)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                              border: Border.all(color: cardColor, width: 2),
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Category Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getCategoryColor(data['category'] ?? 'General').withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                (data['category'] ?? 'General').toString().toUpperCase(),
                                style: TextStyle(
                                  color: _getCategoryColor(data['category'] ?? 'General'),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            Icon(Icons.more_horiz, color: isDark ? Colors.white38 : Colors.grey, size: 20),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          data['title'],
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: primaryTextColor,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          data['date'],
                          style: TextStyle(
                            color: isDark ? Colors.white30 : Colors.grey[400],
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          data['message'],
                          style: TextStyle(
                            color: secondaryTextColor,
                            fontSize: 13,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (data['image'] != null)
              Container(
                margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                width: double.infinity,
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: isNetworkImage
                      ? CachedNetworkImage(
                          imageUrl: data['image'],
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: isDark ? Colors.white10 : Colors.grey[200],
                            child: const Center(child: GlobalLoader(size: 20)),
                          ),
                          errorWidget: (context, url, error) => const Icon(Icons.error),
                        )
                      : Image.asset(
                          data['image'],
                          fit: BoxFit.cover,
                        ),
                ),
              ),
            
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.02) : Colors.grey[50]!.withOpacity(0.5),
                border: Border(top: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade100)),
              ),
              child: Row(
                children: [
                  _buildActionButton(Icons.remove_red_eye_outlined, "View"),
                  const SizedBox(width: 16),
                  _buildActionButton(
                    Icons.share_outlined, 
                    "Share", 
                    onTap: () async {
                      final title = data['title'] ?? '';
                      final message = data['message'] ?? '';
                      final id = data['id'];
                      
                      // Construct the public web URL for sharing
                      // We use the base URL without the /api suffix
                      final webBaseUrl = ApiConstants.baseUrl.replaceAll('/api', '');
                      final shareUrl = '$webBaseUrl/news/$id';

                      // Share the link with a message
                      // This will allow social media platforms to scrape OG tags for a rich preview
                      Share.share('$title\n\n$shareUrl');
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Sales':
        return const Color(0xFFF2994A);
      case 'Promotion':
        return const Color(0xFF9B51E0);
      case 'General':
        return const Color(0xFFBB6BD9);
      default:
        return AppColors.primary;
    }
  }

  Widget _buildActionButton(IconData icon, String label, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isDark ? Colors.white30 : Colors.grey[400]),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isDark ? Colors.white38 : Colors.grey[500],
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
