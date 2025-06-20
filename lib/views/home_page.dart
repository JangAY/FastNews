import 'package:flutter/gestures.dart'; // Impor untuk PointerDeviceKind
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/news_service.dart';
import '../services/bookmark_service.dart';
import 'search_page.dart';
import 'bookmarks_page.dart';
import 'profile_page.dart';
import 'article_detail_page.dart';

// KELAS HELPER UNTUK MENGAKTIFKAN SCROLL DENGAN MOUSE
class MyCustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
      };
}

class HomePage extends StatefulWidget {
  final String token;
  const HomePage({super.key, required this.token});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  late final List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    _widgetOptions = <Widget>[
      _HomePageContent(token: widget.token),
      SearchPage(),
      BookmarksPage(token: widget.token),
      ProfilePage(token: widget.token),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(
            icon: Icon(Icons.bookmark_outline),
            label: 'Bookmarks',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor:
            Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(fontSize: 12),
      ),
    );
  }
}

class _HomePageContent extends StatefulWidget {
  final String token;
  const _HomePageContent({required this.token});
  @override
  __HomePageContentState createState() => __HomePageContentState();
}

class __HomePageContentState extends State<_HomePageContent> {
  final NewsService _newsService = NewsService();
  final BookmarkService _bookmarkService = BookmarkService();
  late Future<Map<String, dynamic>> _trendingArticles;
  List<dynamic> _allArticles = [];
  List<dynamic> _filteredArticles = [];
  int _currentPage = 1;
  bool _isLoadingMore = false;
  bool _isRefreshing = false;
  final ScrollController _scrollController = ScrollController();
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All', 'Technology', 'Business', 'Politics', 'Science', 'Health', 'Sports', 'Entertainment'
  ];

  @override
  void initState() {
    super.initState();
    _trendingArticles = _newsService.fetchTrendingArticles();
    _loadInitialArticles();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialArticles() async {
    try {
      final response = await _newsService.fetchArticles(page: 1);
      if (mounted) {
        setState(() {
          _allArticles = response['data']['articles'];
          _applyCategoryFilter(_selectedCategory);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load articles: $e')),
        );
      }
    }
  }

  Future<void> _refreshArticles() async {
    setState(() {
      _isRefreshing = true;
      _currentPage = 1;
    });
    await _loadInitialArticles();
    if (mounted) {
      setState(() {
        _isRefreshing = false;
      });
    }
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      _loadMoreArticles();
    }
  }

  Future<void> _loadMoreArticles() async {
    if (_isLoadingMore) return;
    setState(() => _isLoadingMore = true);

    _currentPage++;
    try {
      final response = await _newsService.fetchArticles(
          page: _currentPage,
          category: _selectedCategory == 'All' ? null : _selectedCategory);
      if (mounted) {
        setState(() {
          _allArticles.addAll(response['data']['articles']);
          _applyCategoryFilter(_selectedCategory);
        });
      }
    } catch (e) {
      // Handle error
    } finally {
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  void _applyCategoryFilter(String category) {
    setState(() {
      _selectedCategory = category;
      if (category == 'All') {
        _filteredArticles = List.from(_allArticles);
      } else {
        _filteredArticles = _allArticles
            .where((article) =>
                article['category']?.toLowerCase() == category.toLowerCase())
            .toList();
      }
    });
  }

  Future<void> _toggleBookmark(Map<String, dynamic> article) async {
    try {
      final isBookmarked =
          await _bookmarkService.isArticleBookmarked(article['id'], widget.token);

      if (isBookmarked) {
        await _bookmarkService.removeBookmark(article['id'], widget.token);
        if (mounted)
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Bookmark removed')));
      } else {
        await _bookmarkService.saveBookmark(article['id'], widget.token);
        if (mounted)
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Article bookmarked')));
      }
      setState(() {});
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed: ${e.toString()}')));
    }
  }

  void _navigateToArticleDetail(Map<String, dynamic> article) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ArticleDetailPage(article: article, token: widget.token),
      ),
    ).then((_) => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return RefreshIndicator(
      onRefresh: _refreshArticles,
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 20),
                Text(
                  'FastNews',
                  style:
                      GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Kabar Terkini, Dari Kami untuk Negeri',
                  style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Theme.of(context).textTheme.bodySmall?.color),
                ),
              ],
            ),
            toolbarHeight: 100,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Text('Trending news',
                      style: GoogleFonts.poppins(
                          fontSize: 20, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            // MEMBUNGKUS DENGAN SCROLLCONFIGURATION
            child: ScrollConfiguration(
              behavior: MyCustomScrollBehavior(),
              child: SizedBox(
                height: 280,
                child: FutureBuilder<Map<String, dynamic>>(
                  future: _trendingArticles,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError ||
                        !snapshot.hasData ||
                        (snapshot.data!['data']?['articles'] as List?)
                                ?.isEmpty !=
                            false) {
                      return Center(child: Text('No trending articles'));
                    }
                    final articles = snapshot.data!['data']['articles'] as List;
                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.only(left: 24),
                      itemCount: articles.length,
                      itemBuilder: (context, index) {
                        final article = articles[index];
                        return Container(
                          width: 280,
                          margin: EdgeInsets.only(right: 16),
                          child: _TrendingNewsCard(
                            article: article,
                            token: widget.token,
                            onBookmark: () => _toggleBookmark(article),
                            onTap: () => _navigateToArticleDetail(article),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Latest News',
                      style: GoogleFonts.poppins(
                          fontSize: 20, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 16),
                  // MEMBUNGKUS DENGAN SCROLLCONFIGURATION
                  ScrollConfiguration(
                    behavior: MyCustomScrollBehavior(),
                    child: SizedBox(
                      height: 50,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _categories.length,
                        itemBuilder: (context, index) {
                          final category = _categories[index];
                          final isSelected = _selectedCategory == category;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: FilterChip(
                              label: Text(category),
                              selected: isSelected,
                              onSelected: (selected) =>
                                  _applyCategoryFilter(category),
                              selectedColor: Theme.of(context).primaryColor,
                              backgroundColor: isDarkMode
                                  ? Colors.grey[800]
                                  : Colors.grey[200],
                              labelStyle: GoogleFonts.poppins(
                                color: isSelected
                                    ? Colors.white
                                    : Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.color,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          _filteredArticles.isEmpty && !_isRefreshing
              ? SliverFillRemaining(child: Center(child: Text("No articles found")))
              : SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final article = _filteredArticles[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 8),
                        child: _LatestNewsItem(
                          article: article,
                          token: widget.token,
                          onBookmark: () => _toggleBookmark(article),
                          onTap: () => _navigateToArticleDetail(article),
                        ),
                      );
                    },
                    childCount: _filteredArticles.length,
                  ),
                ),
          SliverToBoxAdapter(
            child: _isLoadingMore
                ? Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : SizedBox(),
          ),
        ],
      ),
    );
  }
}

// ... (Widget _TrendingNewsCard dan _LatestNewsItem tetap sama)
class _TrendingNewsCard extends StatefulWidget {
  final Map<String, dynamic> article;
  final String token;
  final VoidCallback onBookmark;
  final VoidCallback onTap;

  const _TrendingNewsCard({required this.article, required this.token, required this.onBookmark, required this.onTap});

  @override
  State<_TrendingNewsCard> createState() => _TrendingNewsCardState();
}

class _TrendingNewsCardState extends State<_TrendingNewsCard> {
  final BookmarkService _bookmarkService = BookmarkService();
  late Future<bool> _isBookmarkedFuture;

  @override
  void initState() {
    super.initState();
    _isBookmarkedFuture = _bookmarkService.isArticleBookmarked(widget.article['id'], widget.token);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 3,
        child: Column(
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                  child: Image.network(
                    widget.article['imageUrl'] ?? 'https://via.placeholder.com/150',
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: FutureBuilder<bool>(
                    future: _isBookmarkedFuture,
                    builder: (context, snapshot) {
                      final isBookmarked = snapshot.data ?? false;
                      return IconButton(
                        icon: Icon(
                          isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                          color: Colors.white,
                          size: 28,
                        ),
                        onPressed: widget.onBookmark,
                      );
                    },
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.article['category'] ?? 'General',
                    // Gunakan warna dari tema
                    style: GoogleFonts.poppins(color: Theme.of(context).primaryColor, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.article['title'] ?? 'No title',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _LatestNewsItem extends StatefulWidget {
  final Map<String, dynamic> article;
  final String token;
  final VoidCallback onBookmark;
  final VoidCallback onTap;

  const _LatestNewsItem({required this.article, required this.token, required this.onBookmark, required this.onTap});

  @override
  State<_LatestNewsItem> createState() => _LatestNewsItemState();
}

class _LatestNewsItemState extends State<_LatestNewsItem> {
  final BookmarkService _bookmarkService = BookmarkService();
  late Future<bool> _isBookmarkedFuture;
  
  @override
  void initState() {
    super.initState();
    _isBookmarkedFuture = _bookmarkService.isArticleBookmarked(widget.article['id'], widget.token);
  }


  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 3,
        margin: EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                  child: Image.network(
                    widget.article['imageUrl'] ?? 'https://via.placeholder.com/150',
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: FutureBuilder<bool>(
                    future: _isBookmarkedFuture,
                    builder: (context, snapshot) {
                      final isBookmarked = snapshot.data ?? false;
                       return IconButton(
                        icon: Icon(
                          isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                          color: Colors.white,
                          size: 28,
                        ),
                        onPressed: widget.onBookmark,
                      );
                    },
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.article['title'] ?? 'No title',
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    // Membatasi panjang konten agar tidak error
                    (widget.article['content'] as String? ?? 'No description').length > 100 
                      ? (widget.article['content'] as String).substring(0, 100) + '...'
                      : widget.article['content'] ?? 'No description',
                    // Menggunakan warna teks sekunder dari tema
                    style: GoogleFonts.poppins(color: Theme.of(context).textTheme.bodySmall?.color),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                       CircleAvatar(
                        radius: 18,
                        backgroundImage: NetworkImage(widget.article['author']?['avatar'] ?? 'https://via.placeholder.com/50'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.article['author']?['name'] ?? 'Unknown',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                        ),
                      ),
                       Text(
                        widget.article['publishedAt'] ?? 'Unknown date',
                        style: GoogleFonts.poppins(color: Theme.of(context).textTheme.bodySmall?.color),
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
}