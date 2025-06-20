import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/bookmark_service.dart';
import '../services/news_service.dart';

class ArticleDetailPage extends StatefulWidget {
  final Map<String, dynamic> article;

  const ArticleDetailPage({Key? key, required this.article}) : super(key: key);

  @override
  State<ArticleDetailPage> createState() => _ArticleDetailPageState();
}

class _ArticleDetailPageState extends State<ArticleDetailPage> {
  late bool _isBookmarked;
  final NewsService _newsService = NewsService();
  bool _isLoadingRelated = false;
  List<dynamic> _relatedArticles = [];

  @override
  void initState() {
    super.initState();
    _isBookmarked = false;
    _checkBookmarkStatus();
    _loadRelatedArticles();
  }

  Future<void> _checkBookmarkStatus() async {
    final isBookmarked = await BookmarkService.isArticleBookmarked(widget.article['id']);
    setState(() {
      _isBookmarked = isBookmarked;
    });
  }

  Future<void> _loadRelatedArticles() async {
    setState(() {
      _isLoadingRelated = true;
    });
    
    try {
      final response = await _newsService.fetchArticles(
        category: widget.article['category'],
        limit: 3,
      );
      setState(() {
        _relatedArticles = response['data']['articles']
            .where((article) => article['id'] != widget.article['id'])
            .toList();
        _isLoadingRelated = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingRelated = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load related articles'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _toggleBookmark() async {
    if (_isBookmarked) {
      await BookmarkService.removeBookmark(widget.article['id']);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Removed from bookmarks'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      await BookmarkService.saveBookmark(
        articleId: widget.article['id'],
        title: widget.article['title'],
        imageUrl: widget.article['imageUrl'],
        category: widget.article['category'],
        date: widget.article['publishedAt'],
        description: widget.article['content'] ?? widget.article['description'] ?? '',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added to bookmarks'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    setState(() {
      _isBookmarked = !_isBookmarked;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  Image.network(
                    widget.article['imageUrl'] ?? 'https://via.placeholder.com/150',
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[200],
                        child: Center(child: Icon(Icons.image, size: 50, color: Colors.grey)),
                      );
                    },
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.7),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            pinned: true,
            actions: [
              IconButton(
                icon: Icon(_isBookmarked ? Icons.bookmark : Icons.bookmark_border),
                onPressed: _toggleBookmark,
              ),
              IconButton(
                icon: Icon(Icons.share),
                onPressed: () {
                  // Implement share functionality
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Share article'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category Chip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Color(0xFF6B73FF).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.article['category'] ?? 'General',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF6B73FF),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Title
                  Text(
                    widget.article['title'] ?? 'No title',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Author and Date
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundImage: NetworkImage(
                          widget.article['author']?['avatar'] ?? 'https://via.placeholder.com/50'),
                        backgroundColor: Colors.grey[200],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.article['author']?['name'] ?? 'Unknown Author',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              widget.article['publishedAt'] ?? 'Unknown date',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (widget.article['isVerified'] ?? true)
                        Icon(
                          Icons.check_circle,
                          color: Color(0xFF6B73FF),
                          size: 18,
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Content
                  Text(
                    widget.article['content'] ?? 'No content available',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      height: 1.6,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Related Articles Section
                  Text(
                    'Related Articles',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          
          // Related Articles List
          if (_isLoadingRelated)
            SliverToBoxAdapter(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_relatedArticles.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: Center(
                  child: Text(
                    'No related articles found',
                    style: GoogleFonts.poppins(color: Colors.grey[600]),
                  ),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final article = _relatedArticles[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ArticleDetailPage(article: article),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  article['imageUrl'] ?? 'https://via.placeholder.com/150',
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 80,
                                      height: 80,
                                      color: Colors.grey[200],
                                      child: Center(child: Icon(Icons.image, color: Colors.grey)),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      article['title'] ?? 'No title',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      article['publishedAt'] ?? 'Unknown date',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
                childCount: _relatedArticles.length,
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _toggleBookmark,
        backgroundColor: Color(0xFF6B73FF),
        child: Icon(
          _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
          color: Colors.white,
        ),
      ),
    );
  }
}