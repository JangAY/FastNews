import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/bookmark_service.dart';
import 'article_detail_page.dart';

class BookmarksPage extends StatefulWidget {
  final String token;
  const BookmarksPage({Key? key, required this.token}) : super(key: key);

  @override
  State<BookmarksPage> createState() => _BookmarksPageState();
}

class _BookmarksPageState extends State<BookmarksPage> {
  final BookmarkService _bookmarkService = BookmarkService();
  late Future<List<dynamic>> _bookmarkedArticlesFuture;

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
  }

  void _loadBookmarks() {
    setState(() {
      _bookmarkedArticlesFuture = _bookmarkService.getSavedArticles(widget.token);
    });
  }

  Future<void> _removeBookmark(String articleId) async {
    try {
      await _bookmarkService.removeBookmark(articleId, widget.token);
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Bookmark removed')));
      }
      _loadBookmarks(); // Refresh the list
    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to remove bookmark')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Scaffold dan AppBar sekarang akan menggunakan warna dari tema global
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Bookmarks',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _bookmarkedArticlesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                'No bookmarks yet',
                // Menggunakan warna teks yang adaptif
                style: GoogleFonts.poppins(color: Theme.of(context).textTheme.bodySmall?.color),
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
                onRemove: () => _removeBookmark(article['id']),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ArticleDetailPage(article: article, token: widget.token),
                    ),
                  ).then((_) => _loadBookmarks());
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _BookmarkItem extends StatelessWidget {
  final Map<String, dynamic> article;
  final VoidCallback onRemove;
  final VoidCallback onTap;

  const _BookmarkItem({required this.article, required this.onRemove, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        // Card secara otomatis akan menyesuaikan warna dengan tema
        margin: EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        clipBehavior: Clip.antiAlias, // Menambahkan clipBehavior untuk memastikan gambar mengikuti border radius
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(
              article['imageUrl'] ?? 'https://via.placeholder.com/150',
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
               errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 180,
                    width: double.infinity,
                    color: Theme.of(context).dividerColor.withOpacity(0.1),
                    child: Icon(Icons.image_not_supported, size: 40, color: Theme.of(context).dividerColor),
                  );
                },
            ),
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article['title'] ?? 'No title',
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        article['category'] ?? 'General',
                        // Menggunakan warna primer dari tema
                        style: GoogleFonts.poppins(color: Theme.of(context).primaryColor, fontWeight: FontWeight.w500),
                      ),
                      IconButton(
                        // Menggunakan warna primer tema untuk ikon yang menandakan "tersimpan"
                        icon: Icon(Icons.bookmark, color: Theme.of(context).primaryColor),
                        onPressed: onRemove,
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