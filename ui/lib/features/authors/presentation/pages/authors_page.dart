import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../data/author_provider.dart';
import '../../../../core/widgets/global_loader.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/author.dart';
import '../../../../Book/book_store.dart';
import '../../../menu/presentation/pages/menu_page.dart';
import '../../../../theme/theme_service.dart';
import '../../../../l10n/language_service.dart';

class AuthorsPage extends StatefulWidget {
  const AuthorsPage({super.key});

  @override
  State<AuthorsPage> createState() => _AuthorsPageState();
}

class _AuthorsPageState extends State<AuthorsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        context.read<AuthorProvider>().fetchAuthors());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeService, LanguageService>(
      builder: (context, themeService, langService, child) {
        final isDark = themeService.isDarkMode;
        final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA);

        return Scaffold(
          backgroundColor: bgColor,
          drawer: const SideMenuDrawer(),
          body: Consumer<AuthorProvider>(
            builder: (context, provider, child) {
              final filteredAuthors = provider.authors
                  .where((a) => a.name.toLowerCase().contains(_searchQuery.toLowerCase()))
                  .toList();

              return RefreshIndicator(
                onRefresh: () => provider.fetchAuthors(),
                color: AppColors.primary,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  slivers: [
                  _buildSliverAppBar(context, isDark, langService, provider),
                  if (provider.isLoading)
                    const SliverFillRemaining(
                      child: Center(
                        child: GlobalLoader(),
                      ),
                    )
                  else if (provider.error.isNotEmpty)
                    SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 60, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(provider.error, style: TextStyle(color: isDark ? Colors.white70 : Colors.grey[600])),
                            TextButton(
                              onPressed: () => provider.fetchAuthors(),
                              child: Text(langService.translate('try_again'), style: const TextStyle(color: AppColors.primary)),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (filteredAuthors.isEmpty)
                    SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off_rounded, size: 80, color: isDark ? Colors.white10 : Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isEmpty ? langService.translate('no_authors_found') : langService.translate('no_match_for').replaceFirst('%s', _searchQuery),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white38 : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.85,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _buildAuthorCard(filteredAuthors[index], isDark, langService),
                          childCount: filteredAuthors.length,
                        ),
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 50)),
                ],
              ),
            );
            },
          ),
        );
      },
    );
  }

  Widget _buildSliverAppBar(BuildContext context, bool isDark, LanguageService langService, AuthorProvider provider) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 140,
      backgroundColor: AppColors.primary,
      elevation: 0,
      automaticallyImplyLeading: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
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
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
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
                      const SizedBox(width: 10),
                      Text(
                        langService.translate('authors'),
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
                              hintText: langService.translate('search_authors'),
                              hintStyle: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
                              border: InputBorder.none,
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
                      langService.translate('authors_list'),
                      style: const TextStyle(
                        color: AppColors.accentYellow,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _searchQuery.isEmpty 
                        ? langService.translate('total_authors').replaceFirst('%s', provider.authors.length.toString())
                        : langService.translate('found_authors').replaceFirst('%s', provider.authors.where((a) => a.name.toLowerCase().contains(_searchQuery.toLowerCase())).length.toString()),
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

  Widget _buildAuthorCard(Author author, bool isDark, LanguageService langService) {
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final primaryTextColor = isDark ? Colors.white : AppColors.onBackground;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BookStorePage(initialAuthorId: author.id),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Hero(
              tag: 'author-${author.id}',
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(isDark ? 0.1 : 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: author.profileImageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: author.profileImageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100]),
                          errorWidget: (context, url, error) => _buildDefaultAvatar(author.name),
                        )
                      : _buildDefaultAvatar(author.name),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                author.name,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: primaryTextColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              langService.translate('author_role'),
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white38 : Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar(String name) {
    return Container(
      color: AppColors.primary.withOpacity(0.1),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : "?",
          style: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
            fontSize: 28,
          ),
        ),
      ),
    );
  }
}
