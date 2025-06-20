import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/bookmark_service.dart';
import '../services/news_service.dart';

class ArticleDetailPage extends StatefulWidget {
  final Map<String, dynamic> article;
  final String token;

  const ArticleDetailPage({Key? key, required this.article, required this.token}) : super(key: key);

  @override
  State<ArticleDetailPage> createState() => _ArticleDetailPageState();
}

class _ArticleDetailPageState extends State<ArticleDetailPage> {
  final BookmarkService _bookmarkService = BookmarkService();
  final NewsService _newsService = NewsService();
  
  late Future<bool> _isBookmarkedFuture;
  bool _isBookmarked = false; // Local state for immediate UI feedback

  @override
  void initState() {
    super.initState();
    _checkBookmarkStatus();
  }

  Future<void> _checkBookmarkStatus() async {
    _isBookmarkedFuture = _bookmarkService.isArticleBookmarked(widget.article['id'], widget.token);
    _isBookmarked = await _isBookmarkedFuture;
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _toggleBookmark() async {
    final currentStatus = _isBookmarked;
    // Optimistic update
    setState(() {
      _isBookmarked = !_isBookmarked;
    });

    try {
      if (currentStatus) {
        await _bookmarkService.removeBookmark(widget.article['id'], widget.token);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Removed from bookmarks')));
      } else {
        await _bookmarkService.saveBookmark(widget.article['id'], widget.token);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Added to bookmarks')));
      }
    } catch (e) {
      // Revert on failure
      setState(() {
        _isBookmarked = currentStatus;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update bookmark')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Image.network(
                widget.article['imageUrl'] ?? 'https://via.placeholder.com/150',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey),
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(_isBookmarked ? Icons.bookmark : Icons.bookmark_border),
                onPressed: _toggleBookmark,
              ),
              IconButton(
                icon: Icon(Icons.share),
                onPressed: () { /* Implement share */ },
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.article['category'] ?? 'General',
                    style: GoogleFonts.poppins(
                      color: Color(0xFF6B73FF),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.article['title'] ?? 'No title',
                    style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundImage: NetworkImage(widget.article['author']?['avatar'] ?? 'https://via.placeholder.com/50'),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.article['author']?['name'] ?? 'Unknown Author',
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            widget.article['publishedAt'] ?? 'Unknown date',
                            style: GoogleFonts.poppins(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    widget.article['content'] ?? 'No content available',
                    style: GoogleFonts.poppins(fontSize: 16, height: 1.6),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}