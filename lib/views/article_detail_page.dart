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
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Removed from bookmarks')));
      } else {
        await _bookmarkService.saveBookmark(widget.article['id'], widget.token);
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Added to bookmarks')));
      }
    } catch (e) {
      // Revert on failure
      setState(() {
        _isBookmarked = currentStatus;
      });
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update bookmark')));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Scaffold sekarang akan menggunakan warna dari tema global
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            stretch: true,
            expandedHeight: 300,
            pinned: true,
            // Membuat AppBar transparan agar gradien terlihat
            backgroundColor: Colors.transparent, 
            // Memastikan ikon (back, bookmark, share) berwarna putih agar kontras
            foregroundColor: Colors.white, 
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    widget.article['imageUrl'] ?? 'https://via.placeholder.com/150',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      // Menggunakan warna adaptif untuk placeholder gambar
                      color: Theme.of(context).dividerColor,
                      child: Icon(Icons.image_not_supported, color: Theme.of(context).iconTheme.color?.withOpacity(0.5)),
                    ),
                  ),
                  // Menambahkan lapisan gradien gelap untuk meningkatkan kontras ikon AppBar
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black54,
                          Colors.transparent,
                        ],
                        stops: [0.0, 0.4],
                      ),
                    ),
                  ),
                ],
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
                      // Menggunakan warna primer dari tema
                      color: Theme.of(context).primaryColor,
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
                            style: GoogleFonts.poppins(
                              // Menggunakan warna teks sekunder dari tema
                              color: Theme.of(context).textTheme.bodySmall?.color
                            ),
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