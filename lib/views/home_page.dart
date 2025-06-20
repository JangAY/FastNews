import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/news_service.dart';
import '../services/bookmark_service.dart';
import 'search_page.dart';
import 'bookmarks_page.dart';
import 'profile_page.dart';
import 'article_detail_page.dart';

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
      backgroundColor: Colors.white,
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
        selectedItemColor: Color(0xFF6B73FF),
        unselectedItemColor: Colors.grey,
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
      setState(() {
        _allArticles = response['data']['articles'];
        _applyCategoryFilter(_selectedCategory);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load articles: $e')),
      );
    }
  }

  Future<void> _refreshArticles() async {
    setState(() {
      _isRefreshing = true;
      _currentPage = 1;
    });
    await _loadInitialArticles();
    setState(() {
      _isRefreshing = false;
    });
  }

  void _scrollListener() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      _loadMoreArticles();
    }
  }

  Future<void> _loadMoreArticles() async {
    if (_isLoadingMore) return;
    setState(() => _isLoadingMore = true);

    _currentPage++;
    try {
      final response = await _newsService.fetchArticles(page: _currentPage, category: _selectedCategory == 'All' ? null : _selectedCategory);
      setState(() {
        _allArticles.addAll(response['data']['articles']);
        _applyCategoryFilter(_selectedCategory);
      });
    } catch (e) {
      // Handle error
    } finally {
      setState(() => _isLoadingMore = false);
    }
  }
  
  void _applyCategoryFilter(String category) {
    setState(() {
      _selectedCategory = category;
      if (category == 'All') {
        _filteredArticles = _allArticles;
      } else {
        _filteredArticles = _allArticles.where((article) => 
          article['category']?.toLowerCase() == category.toLowerCase()
        ).toList();
      }
    });
  }

  Future<void> _toggleBookmark(Map<String, dynamic> article) async {
    try {
      final isBookmarked = await _bookmarkService.isArticleBookmarked(article['id'], widget.token);

      if (isBookmarked) {
        await _bookmarkService.removeBookmark(article['id'], widget.token);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Bookmark removed')));
      } else {
        await _bookmarkService.saveBookmark(article['id'], widget.token);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Article bookmarked')));
      }
      setState(() {}); // Rebuild to update bookmark icon
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: ${e.toString()}')));
    }
  }

  void _navigateToArticleDetail(Map<String, dynamic> article) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ArticleDetailPage(article: article, token: widget.token),
      ),
    ).then((_) => setState((){})); // Refresh on return
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refreshArticles,
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            backgroundColor: Colors.white,
            elevation: 0,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 20),
                Text(
                  'FastNews',
                  style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                Text(
                  'Kabar Terkini, Dari Kami untuk Negeri',
                  style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
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
                  Text('Trending news', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 280,
              child: FutureBuilder<Map<String, dynamic>>(
                future: _trendingArticles,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError || !snapshot.hasData || snapshot.data!['data']['articles'].isEmpty) {
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
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text('Latest News', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 50,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final category = _categories[index];
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: FilterChip(
                            label: Text(category),
                            selected: _selectedCategory == category,
                            onSelected: (selected) => _applyCategoryFilter(category),
                            selectedColor: Color(0xFF6B73FF),
                            labelStyle: GoogleFonts.poppins(
                              color: _selectedCategory == category ? Colors.white : Colors.black87,
                            ),
                          ),
                        );
                      },
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
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
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
              child: _isLoadingMore ? Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator()),
              ) : SizedBox(),
            ),
        ],
      ),
    );
  }
}

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
                    style: GoogleFonts.poppins(color: Color(0xFF6B73FF), fontWeight: FontWeight.w500),
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
                    widget.article['content']?.substring(0, 100) ?? 'No description',
                    style: GoogleFonts.poppins(color: Colors.grey[600]),
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
                        style: GoogleFonts.poppins(color: Colors.grey[500]),
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