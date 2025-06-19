import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/news_service.dart';
import 'search_page.dart';
import 'bookmarks_page.dart';
import 'profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final NewsService _newsService = NewsService();

  final List<Widget> _widgetOptions = <Widget>[
    _HomePageContent(),
    SearchPage(),
    BookmarksPage(),
    ProfilePage(),
  ];

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
        items: <BottomNavigationBarItem>[
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
  @override
  __HomePageContentState createState() => __HomePageContentState();
}

class __HomePageContentState extends State<_HomePageContent> {
  final NewsService _newsService = NewsService();
  late Future<Map<String, dynamic>> _trendingArticles;
  List<dynamic> _allArticles = [];
  List<dynamic> _filteredArticles = [];
  int _currentPage = 1;
  bool _isLoadingMore = false;
  final ScrollController _scrollController = ScrollController();
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Technology',
    'Business',
    'Politics',
    'Science',
    'Health',
    'Sports',
    'Entertainment'
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
      final response = await _newsService.fetchArticles(page: _currentPage);
      setState(() {
        _allArticles = response['data']['articles'];
        _filteredArticles = _allArticles;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load articles: $e')),
      );
    }
  }

  Future<void> _loadMoreArticles() async {
    if (_isLoadingMore) return;
    
    setState(() {
      _isLoadingMore = true;
    });

    try {
      _currentPage++;
      final response = await _newsService.fetchArticles(page: _currentPage);
      setState(() {
        _allArticles.addAll(response['data']['articles']);
        _applyCategoryFilter(_selectedCategory);
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingMore = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load more articles: $e')),
      );
    }
  }

  void _scrollListener() {
    if (_scrollController.position.pixels == 
        _scrollController.position.maxScrollExtent) {
      _loadMoreArticles();
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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _scrollController,
      child: Padding(
        padding: const EdgeInsets.only(top: 60.0, left: 24.0, right: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'FastNews',
              style: GoogleFonts.poppins(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Kabar Terkini, Dari Kami untuk Negeri',
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),

            // Trending News Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Trending news',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('See all trending news clicked')),
                    );
                  },
                  child: Text(
                    'See all',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Color(0xFF6B73FF),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Horizontal Trending News List
            SizedBox(
              height: 280,
              child: FutureBuilder<Map<String, dynamic>>(
                future: _trendingArticles,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!['data']['articles'].isEmpty) {
                    return Center(child: Text('No trending articles found'));
                  }

                  final articles = snapshot.data!['data']['articles'] as List;

                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: articles.length,
                    itemBuilder: (context, index) {
                      final article = articles[index];
                      return Container(
                        width: 280,
                        margin: EdgeInsets.only(right: 16),
                        child: _TrendingNewsCard(
                          imageUrl: article['imageUrl'] ?? 'https://via.placeholder.com/150',
                          category: article['category'] ?? 'General',
                          title: article['title'] ?? 'No title',
                          date: article['publishedAt'] ?? 'Unknown date',
                          articleId: article['id'],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 32),

            // Latest News Section
            Text(
              'Latest News',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            // Category Filter Chips
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
                      onSelected: (selected) {
                        _applyCategoryFilter(category);
                      },
                      selectedColor: Color(0xFF6B73FF),
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: _selectedCategory == category 
                              ? Colors.transparent 
                              : Colors.grey[300]!,
                        ),
                      ),
                      labelStyle: GoogleFonts.poppins(
                        color: _selectedCategory == category 
                            ? Colors.white 
                            : Colors.black87,
                        fontSize: 14,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Vertical Articles List with infinite scroll
            if (_filteredArticles.isEmpty)
              Center(child: Text('No articles found'))
            else
              Column(
                children: [
                  ..._filteredArticles.map((article) {
                    return _LatestNewsItem(
                      imageUrl: article['imageUrl'] ?? 'https://via.placeholder.com/150',
                      avatarUrl: article['author']?['avatar'] ?? 'https://via.placeholder.com/50',
                      publisherName: article['author']?['name'] ?? 'Unknown',
                      isVerified: true,
                      title: article['title'] ?? 'No title',
                      description: article['content']?.length > 100
                          ? '${article['content'].substring(0, 100)}...'
                          : article['content'] ?? 'No description',
                      category: article['category'] ?? 'General',
                      articleId: article['id'],
                      date: article['publishedAt'] ?? 'Unknown date',
                    );
                  }).toList(),
                  if (_isLoadingMore)
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                ],
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// Trending News Card Widget
class _TrendingNewsCard extends StatelessWidget {
  final String imageUrl;
  final String category;
  final String title;
  final String date;
  final String articleId;

  const _TrendingNewsCard({
    Key? key,
    required this.imageUrl,
    required this.category,
    required this.title,
    required this.date,
    required this.articleId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Opening article: $title')),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 5,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                imageUrl,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 150,
                    color: Colors.grey[200],
                    child: Center(child: Icon(Icons.image, color: Colors.grey)),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Color(0xFF6B73FF).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      category,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF6B73FF),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
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

// Latest News Item Widget
class _LatestNewsItem extends StatelessWidget {
  final String imageUrl;
  final String avatarUrl;
  final String publisherName;
  final bool isVerified;
  final String title;
  final String description;
  final String category;
  final String articleId;
  final String date;

  const _LatestNewsItem({
    Key? key,
    required this.imageUrl,
    required this.avatarUrl,
    required this.publisherName,
    this.isVerified = false,
    required this.title,
    required this.description,
    required this.category,
    required this.articleId,
    required this.date,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Opening article: $title')),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 5,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                imageUrl,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 180,
                    color: Colors.grey[200],
                    child: Center(child: Icon(Icons.image, color: Colors.grey)),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundImage: NetworkImage(avatarUrl),
                        backgroundColor: Colors.grey[200],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  publisherName,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                if (isVerified) ...[
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.check_circle,
                                    color: Color(0xFF6B73FF),
                                    size: 14,
                                  ),
                                ],
                              ],
                            ),
                            Text(
                              date,
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.more_vert, color: Colors.grey[600]),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('More options clicked for $publisherName'),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Color(0xFF6B73FF).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      category,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF6B73FF),
                      ),
                    ),
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