import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/news_service.dart';
import 'article_detail_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final NewsService _newsService = NewsService();
  final TextEditingController _searchController = TextEditingController();

  // State untuk menyimpan semua berita dan hasil filter
  bool _isLoading = true; // Loading saat pertama kali mengambil semua data
  List<dynamic> _allArticles = []; // Menyimpan semua berita dari API
  List<dynamic> _filteredResults = []; // Menyimpan hasil filter
  String? _error;
  String? _token;

  @override
  void initState() {
    super.initState();
    // 1. Ambil token dan semua artikel saat halaman pertama kali dibuka
    _loadInitialData();
    // Tambahkan listener untuk rebuild UI saat text berubah (untuk show/hide clear button)
    _searchController.addListener(() {
      setState(() {});
    });
  }

  Future<void> _loadInitialData() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');

    try {
      final response = await _newsService.fetchArticles(limit: 100);
      if (mounted) {
        setState(() {
          _allArticles = response['data']['articles'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = "Failed to load news data.";
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterArticles(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredResults = [];
      });
      return;
    }

    final results = _allArticles.where((article) {
      final titleLower = (article['title'] as String? ?? '').toLowerCase();
      final queryLower = query.toLowerCase();
      return titleLower.contains(queryLower);
    }).toList();

    setState(() {
      _filteredResults = results;
    });
  }

  Widget _buildContent() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text(_error!, style: GoogleFonts.poppins()));
    }

    if (_searchController.text.isNotEmpty && _filteredResults.isEmpty) {
      return Center(
          child: Text('No results found for "${_searchController.text}"',
              style: GoogleFonts.poppins()));
    }

    // Tampilkan pesan jika search bar kosong dan belum ada hasil
    if (_searchController.text.isEmpty) {
      return Center(
        child: Text(
          'Search for news by title',
          style: GoogleFonts.poppins(color: Theme.of(context).textTheme.bodySmall?.color),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 16.0),
      itemCount: _filteredResults.length,
      itemBuilder: (context, index) {
        final article = _filteredResults[index];
        return SearchResultItem(
          imageUrl: article['imageUrl'] ?? 'https://via.placeholder.com/150',
          title: article['title'] ?? 'No Title',
          category: article['category'] ?? 'General',
          timeAgo: article['publishedAt'] ?? '',
          onTap: () {
            if (_token != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ArticleDetailPage(article: article, token: _token!),
                ),
              );
            }
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Scaffold dan AppBar sekarang akan menggunakan warna dari tema
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Search News',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                // Menggunakan warna adaptif untuk latar belakang search bar
                color: Theme.of(context).dividerColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                style: GoogleFonts.poppins(fontSize: 14),
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search by news title...',
                  // Menggunakan warna adaptif untuk hint text dan ikon
                  hintStyle: GoogleFonts.poppins(color: Theme.of(context).textTheme.bodySmall?.color),
                  prefixIcon: Icon(Icons.search, color: Theme.of(context).textTheme.bodySmall?.color),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: Theme.of(context).textTheme.bodySmall?.color),
                          onPressed: () {
                            _searchController.clear();
                            _filterArticles('');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                onChanged: (value) {
                  _filterArticles(value);
                },
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }
}

class SearchResultItem extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String category;
  final String timeAgo;
  final VoidCallback onTap;

  const SearchResultItem({
    Key? key,
    required this.imageUrl,
    required this.title,
    required this.category,
    required this.timeAgo,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imageUrl,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 80,
                    height: 80,
                    color: Theme.of(context).dividerColor.withOpacity(0.1),
                    child: Icon(Icons.image_not_supported, size: 30, color: Theme.of(context).dividerColor),
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      // Warna teks judul sekarang adaptif
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$category • $timeAgo',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      // Warna teks subjudul sekarang adaptif
                      color: Theme.of(context).textTheme.bodySmall?.color,
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