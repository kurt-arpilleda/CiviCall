import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:civicall/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

const String _gNewsApiKey = '4207a1b830797cb04e34826e968fb159';
const String _gNewsBaseUrl = 'https://gnews.io/api/v4';

class NewsArticle {
  final String title;
  final String description;
  final String content;
  final String url;
  final String imageUrl;
  final String publishedAt;
  final String sourceName;
  final String sourceUrl;

  NewsArticle({
    required this.title,
    required this.description,
    required this.content,
    required this.url,
    required this.imageUrl,
    required this.publishedAt,
    required this.sourceName,
    required this.sourceUrl,
  });

  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    return NewsArticle(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      content: json['content'] ?? '',
      url: json['url'] ?? '',
      imageUrl: json['image'] ?? '',
      publishedAt: json['publishedAt'] ?? '',
      sourceName: json['source']?['name'] ?? '',
      sourceUrl: json['source']?['url'] ?? '',
    );
  }
}

enum _FetchMode { topHeadlines, search }

class NewsCategory {
  final String label;
  final String topicOrQuery;
  final IconData icon;
  final Color color;
  final _FetchMode mode;

  const NewsCategory({
    required this.label,
    required this.topicOrQuery,
    required this.icon,
    required this.color,
    required this.mode,
  });
}

const List<NewsCategory> _categories = [
  NewsCategory(
    label: 'Top News',
    topicOrQuery: 'nation',
    icon: Icons.public_rounded,
    color: AppTheme.redPink,
    mode: _FetchMode.topHeadlines,
  ),
  NewsCategory(
    label: 'Government',
    topicOrQuery: 'politics',
    icon: Icons.account_balance_rounded,
    color: Color(0xFF1565C0),
    mode: _FetchMode.topHeadlines,
  ),
  NewsCategory(
    label: 'World',
    topicOrQuery: 'world',
    icon: Icons.language_rounded,
    color: Color(0xFF2E7D5E),
    mode: _FetchMode.topHeadlines,
  ),
  NewsCategory(
    label: 'Community',
    topicOrQuery: 'Philippines community barangay volunteers',
    icon: Icons.people_rounded,
    color: Color(0xFF6A1B9A),
    mode: _FetchMode.search,
  ),
  NewsCategory(
    label: 'Environment',
    topicOrQuery: 'environment',
    icon: Icons.eco_rounded,
    color: Color(0xFF00695C),
    mode: _FetchMode.topHeadlines,
  ),
  NewsCategory(
    label: 'Education',
    topicOrQuery: 'Philippines education students',
    icon: Icons.school_rounded,
    color: Color(0xFFE65100),
    mode: _FetchMode.search,
  ),
  NewsCategory(
    label: 'Health',
    topicOrQuery: 'health',
    icon: Icons.health_and_safety_rounded,
    color: Color(0xFFAD1457),
    mode: _FetchMode.topHeadlines,
  ),
  NewsCategory(
    label: 'Technology',
    topicOrQuery: 'technology',
    icon: Icons.computer_rounded,
    color: Color(0xFF283593),
    mode: _FetchMode.topHeadlines,
  ),
];

class NewsArticlesScreen extends StatefulWidget {
  const NewsArticlesScreen({Key? key}) : super(key: key);

  @override
  State<NewsArticlesScreen> createState() => _NewsArticlesScreenState();
}

class _NewsArticlesScreenState extends State<NewsArticlesScreen>
    with TickerProviderStateMixin {
  int _selectedCategoryIndex = 0;
  List<NewsArticle> _articles = [];
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';
  final ScrollController _scrollController = ScrollController();
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _fetchNews();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _fetchNews() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _articles = [];
      });
    }
    _fadeController.reset();

    final category = _categories[_selectedCategoryIndex];

    Uri uri;
    if (category.mode == _FetchMode.topHeadlines) {
      uri = Uri.parse(
        '$_gNewsBaseUrl/top-headlines?topic=${category.topicOrQuery}&lang=en&max=10&apikey=$_gNewsApiKey',
      );
    } else {
      final encodedQuery = Uri.encodeComponent(category.topicOrQuery);
      uri = Uri.parse(
        '$_gNewsBaseUrl/search?q=$encodedQuery&lang=en&max=10&sortby=publishedAt&apikey=$_gNewsApiKey',
      );
    }

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> rawArticles = data['articles'] ?? [];
        final parsed = rawArticles
            .map((a) => NewsArticle.fromJson(a as Map<String, dynamic>))
            .where((a) => a.title.isNotEmpty && a.title != '[Removed]')
            .toList();
        if (mounted) {
          setState(() {
            _articles = parsed;
            _isLoading = false;
          });
          _fadeController.forward();
        }
      } else if (response.statusCode == 403) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _hasError = true;
            _errorMessage = 'API key invalid or quota exceeded. Please try again later.';
          });
        }
      } else if (response.statusCode == 429) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _hasError = true;
            _errorMessage = 'Too many requests. Please wait a moment and try again.';
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _hasError = true;
            _errorMessage = 'Failed to load news (${response.statusCode}). Please try again.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'No internet connection. Please check your network and retry.';
        });
      }
    }
  }

  void _onCategorySelected(int index) {
    if (_selectedCategoryIndex == index) return;
    setState(() => _selectedCategoryIndex = index);
    _fetchNews();
  }

  String _formatDate(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate).toLocal();
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final ampm = dt.hour >= 12 ? 'PM' : 'AM';
      final min = dt.minute.toString().padLeft(2, '0');
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year} · $hour:$min $ampm';
    } catch (_) {
      return isoDate;
    }
  }

  Future<void> _openArticle(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildSliverAppBar(innerBoxIsScrolled),
        ],
        body: Column(
          children: [
            _buildCategoryBar(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(bool innerBoxIsScrolled) {
    return SliverAppBar(
      expandedHeight: 130,
      floating: false,
      pinned: true,
      backgroundColor: AppTheme.redPink,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFD53A47), Color(0xFFB71C1C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.newspaper_rounded,
                          color: AppTheme.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'CiviNews',
                        style: TextStyle(
                          color: AppTheme.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Stay informed on civic happenings in the Philippines',
                    style: TextStyle(
                      color: AppTheme.white.withOpacity(0.8),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        title: innerBoxIsScrolled
            ? const Text(
          'CiviNews',
          style: TextStyle(
            color: AppTheme.white,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        )
            : null,
        centerTitle: true,
      ),
    );
  }

  Widget _buildCategoryBar() {
    return Container(
      color: AppTheme.white,
      child: Column(
        children: [
          SizedBox(
            height: 52,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = _selectedCategoryIndex == index;
                return GestureDetector(
                  onTap: () => _onCategorySelected(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? cat.color
                          : cat.color.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          cat.icon,
                          size: 14,
                          color: isSelected ? AppTheme.white : cat.color,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          cat.label,
                          style: TextStyle(
                            color: isSelected ? AppTheme.white : cat.color,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: AppTheme.darkGray.withOpacity(0.07),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return _buildSkeletonList();
    if (_hasError) return _buildErrorState();
    if (_articles.isEmpty) return _buildEmptyState();

    return FadeTransition(
      opacity: _fadeAnimation,
      child: RefreshIndicator(
        color: AppTheme.redPink,
        onRefresh: _fetchNews,
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          itemCount: _articles.length,
          itemBuilder: (context, index) {
            if (index == 0) {
              return _buildFeaturedCard(_articles[0]);
            }
            return _buildArticleCard(_articles[index]);
          },
        ),
      ),
    );
  }

  Widget _buildFeaturedCard(NewsArticle article) {
    final cat = _categories[_selectedCategoryIndex];
    return GestureDetector(
      onTap: () => _openArticle(article.url),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.darkGray.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(20)),
              child: article.imageUrl.isNotEmpty
                  ? Image.network(
                article.imageUrl,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    _buildImagePlaceholder(200, cat),
              )
                  : _buildImagePlaceholder(200, cat),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: cat.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(cat.icon, size: 11, color: cat.color),
                            const SizedBox(width: 4),
                            Text(
                              cat.label,
                              style: TextStyle(
                                color: cat.color,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3E0),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Featured',
                          style: TextStyle(
                            color: Color(0xFFE65100),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    article.title,
                    style: const TextStyle(
                      color: AppTheme.darkGray,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (article.description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      article.description,
                      style: TextStyle(
                        color: AppTheme.darkGray.withOpacity(0.6),
                        fontSize: 13,
                        height: 1.5,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.source_rounded,
                        size: 13,
                        color: AppTheme.darkGray.withOpacity(0.4),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          article.sourceName,
                          style: TextStyle(
                            color: AppTheme.darkGray.withOpacity(0.5),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.access_time_rounded,
                        size: 12,
                        color: AppTheme.darkGray.withOpacity(0.4),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        _formatDate(article.publishedAt),
                        style: TextStyle(
                          color: AppTheme.darkGray.withOpacity(0.4),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArticleCard(NewsArticle article) {
    final cat = _categories[_selectedCategoryIndex];
    return GestureDetector(
      onTap: () => _openArticle(article.url),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.darkGray.withOpacity(0.06),
              blurRadius: 14,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: article.imageUrl.isNotEmpty
                  ? Image.network(
                article.imageUrl,
                width: 88,
                height: 88,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    _buildImagePlaceholder(88, cat, width: 88),
              )
                  : _buildImagePlaceholder(88, cat, width: 88),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(cat.icon, size: 11, color: cat.color),
                      const SizedBox(width: 4),
                      Text(
                        cat.label,
                        style: TextStyle(
                          color: cat.color,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    article.title,
                    style: const TextStyle(
                      color: AppTheme.darkGray,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          article.sourceName,
                          style: TextStyle(
                            color: AppTheme.darkGray.withOpacity(0.45),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _formatDate(article.publishedAt),
                    style: TextStyle(
                      color: AppTheme.darkGray.withOpacity(0.35),
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.darkGray.withOpacity(0.2),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder(double height, NewsCategory cat,
      {double? width}) {
    return Container(
      width: width ?? double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: cat.color.withOpacity(0.08),
        borderRadius: width != null ? BorderRadius.circular(12) : null,
      ),
      child: Icon(
        cat.icon,
        color: cat.color.withOpacity(0.3),
        size: height * 0.35,
      ),
    );
  }

  Widget _buildSkeletonList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: 6,
      itemBuilder: (context, index) {
        if (index == 0) return _buildFeaturedSkeleton();
        return _buildCardSkeleton();
      },
    );
  }

  Widget _buildFeaturedSkeleton() {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.darkGray.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SkeletonPulse(
            width: double.infinity,
            height: 200,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SkeletonPulse(width: 80, height: 24, borderRadius: BorderRadius.circular(6)),
                const SizedBox(height: 10),
                _SkeletonPulse(width: double.infinity, height: 16, borderRadius: BorderRadius.circular(6)),
                const SizedBox(height: 6),
                _SkeletonPulse(width: double.infinity, height: 16, borderRadius: BorderRadius.circular(6)),
                const SizedBox(height: 6),
                _SkeletonPulse(width: 200, height: 16, borderRadius: BorderRadius.circular(6)),
                const SizedBox(height: 12),
                _SkeletonPulse(width: 140, height: 12, borderRadius: BorderRadius.circular(6)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardSkeleton() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.darkGray.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SkeletonPulse(
            width: 88,
            height: 88,
            borderRadius: BorderRadius.circular(12),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SkeletonPulse(width: 60, height: 12, borderRadius: BorderRadius.circular(5)),
                const SizedBox(height: 8),
                _SkeletonPulse(width: double.infinity, height: 14, borderRadius: BorderRadius.circular(5)),
                const SizedBox(height: 5),
                _SkeletonPulse(width: double.infinity, height: 14, borderRadius: BorderRadius.circular(5)),
                const SizedBox(height: 5),
                _SkeletonPulse(width: 130, height: 14, borderRadius: BorderRadius.circular(5)),
                const SizedBox(height: 10),
                _SkeletonPulse(width: 100, height: 11, borderRadius: BorderRadius.circular(5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.redPink.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                color: AppTheme.redPink,
                size: 38,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Couldn\'t Load News',
              style: TextStyle(
                color: AppTheme.darkGray,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              style: TextStyle(
                color: AppTheme.darkGray.withOpacity(0.5),
                fontSize: 13.5,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchNews,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.redPink,
                foregroundColor: AppTheme.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.redPink.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.newspaper_rounded,
              color: AppTheme.redPink.withOpacity(0.5),
              size: 38,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No articles found',
            style: TextStyle(
              color: AppTheme.darkGray.withOpacity(0.5),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _fetchNews,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Refresh'),
            style: TextButton.styleFrom(foregroundColor: AppTheme.redPink),
          ),
        ],
      ),
    );
  }
}

class _SkeletonPulse extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius borderRadius;

  const _SkeletonPulse({
    required this.width,
    required this.height,
    required this.borderRadius,
  });

  @override
  State<_SkeletonPulse> createState() => _SkeletonPulseState();
}

class _SkeletonPulseState extends State<_SkeletonPulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.35, end: 0.85).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, __) => Opacity(
        opacity: _animation.value,
        child: Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: widget.borderRadius,
          ),
        ),
      ),
    );
  }
}