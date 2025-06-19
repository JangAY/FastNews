import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/bookmark_service.dart';

class BookmarksPage extends StatefulWidget {
  const BookmarksPage({Key? key}) : super(key: key);

  @override
  State<BookmarksPage> createState() => _BookmarksPageState();
}

class _BookmarksPageState extends State<BookmarksPage> {
  late Future<List<Map<String, dynamic>>> _bookmarkedArticles;

  @override
  void initState() {
    super.initState();
    _bookmarkedArticles = BookmarkService.getBookmarks();
  }

  void _refreshBookmarks() {
    setState(() {
      _bookmarkedArticles = BookmarkService.getBookmarks();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Bookmarks',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            centerTitle: true,
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _bookmarkedArticles,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error loading bookmarks'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Text(
                      'No bookmarks yet',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
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
                      onRemove: () {
                        BookmarkService.removeBookmark(article['articleId']);
                        _refreshBookmarks();
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BookmarkItem extends StatelessWidget {
  final Map<String, dynamic> article;
  final VoidCallback onRemove;

  const _BookmarkItem({
    required this.article,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
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
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}