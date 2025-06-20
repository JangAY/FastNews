import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/bookmark_service.dart';
import '../services/news_service.dart';
import 'article_detail_page.dart'; // Asumsikan kita punya halaman detail

class BookmarksPage extends StatefulWidget {
  const BookmarksPage({Key? key}) : super(key: key);

  @override
  State<BookmarksPage> createState() => _BookmarksPageState();
}

class _BookmarksPageState extends State<BookmarksPage> {
  late Future<List<Map<String, dynamic>>> _bookmarkedArticles;
  final NewsService _newsService = NewsService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
  }

  void _loadBookmarks() {
    setState(() {
      _bookmarkedArticles = BookmarkService.getBookmarks();
    });
  }

  Future<void> _refreshBookmarks() async {
    setState(() {
      _isLoading = true;
    });
    await Future.delayed(const Duration(milliseconds: 500));
    _loadBookmarks();
    setState(() {
      _isLoading = false;
    });
  }

  void _navigateToArticleDetail(Map<String, dynamic> article) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ArticleDetailPage(article: article),
      ),
    );
  }

  Future<void> _confirmRemoveBookmark(String articleId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove Bookmark', style: GoogleFonts.poppins()),
        content: Text('Are you sure you want to remove this bookmark?', 
                     style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Remove', style: GoogleFonts.poppins(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await BookmarkService.removeBookmark(articleId);
      _refreshBookmarks();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bookmark removed', style: GoogleFonts.poppins()),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Bookmarks',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.black),
            onPressed: _refreshBookmarks,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshBookmarks,
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _bookmarkedArticles,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error loading bookmarks',
                        style: GoogleFonts.poppins(color: Colors.red),
                      ),
                    );
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.bookmark_border, size: 64, color: Colors.grey[400]),
                          SizedBox(height: 16),
                          Text(
                            'No bookmarks yet',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Save articles to read later',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final bookmarks = snapshot.data!;
                  return ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: bookmarks.length,
                    itemBuilder: (context, index) {
                      final article = bookmarks[index];
                      return _BookmarkItem(
                        article: article,
                        onRemove: () => _confirmRemoveBookmark(article['articleId']),
                        onTap: () => _navigateToArticleDetail(article),
                      );
                    },
                  );
                },
              ),
            ),
    );
  }
}

class _BookmarkItem extends StatelessWidget {
  final Map<String, dynamic> article;
  final VoidCallback onRemove;
  final VoidCallback onTap;

  const _BookmarkItem({
    required this.article,
    required this.onRemove,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        margin: EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                article['imageUrl'] ?? 'https://via.placeholder.com/150',
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
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        article['category'] ?? 'General',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Color(0xFF6B73FF),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.bookmark, color: Colors.red),
                        onPressed: onRemove,
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    article['title'] ?? 'No title',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8),
                  Text(
                    article['date'] ?? 'Unknown date',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    article['description'] ?? 'No description',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
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