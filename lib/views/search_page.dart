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
  }

  Future<void> _loadInitialData() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');

    try {
      // Ambil berita dalam jumlah besar (misal: 100) untuk di-filter di sisi klien
      // Sesuaikan limit jika perlu
      final response = await _newsService.fetchArticles(limit: 100);
      setState(() {
        _allArticles = response['data']['articles'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = "Failed to load news data.";
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // 2. Fungsi untuk memfilter berita berdasarkan input pengguna
  void _filterArticles(String query) {
    if (query.isEmpty) {
      // Jika query kosong, kosongkan hasil filter
      setState(() {
        _filteredResults = [];
      });
      return;
    }

    // Lakukan filter pada daftar _allArticles
    final results = _allArticles.where((article) {
      // Ambil judul, pastikan tidak null, dan ubah ke huruf kecil
      final titleLower = (article['title'] as String? ?? '').toLowerCase();
      final queryLower = query.toLowerCase();

      // Kembalikan true jika judul mengandung query
      return titleLower.contains(queryLower);
    }).toList();

    setState(() {
      _filteredResults = results;
    });
  }

  // 3. Widget untuk menampilkan konten berdasarkan state
  Widget _buildContent() {
    // Tampilkan loading indicator saat mengambil semua data
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text(_error!, style: GoogleFonts.poppins()));
    }

    // Setelah data ter-load, tampilkan hasil filter
    if (_searchController.text.isNotEmpty && _filteredResults.isEmpty) {
      return Center(
          child: Text('No results found for "${_searchController.text}"',
              style: GoogleFonts.poppins()));
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 16.0),
      // Gunakan _filteredResults sebagai sumber data
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Search News',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
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
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                style: GoogleFonts.poppins(fontSize: 14),
                autofocus: true, // Otomatis fokus ke search bar
                decoration: InputDecoration(
                  hintText: 'Search by news title...', // <-- Hint text diubah
                  hintStyle: GoogleFonts.poppins(color: Colors.grey[500]),
                  prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: Colors.grey[500]),
                          onPressed: () {
                            _searchController.clear();
                            // Panggil filter dengan string kosong untuk membersihkan hasil
                            _filterArticles('');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                // 4. Gunakan onChanged untuk filter secara real-time saat pengguna mengetik
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

// Widget SearchResultItem tidak perlu diubah
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
                    color: Colors.grey[200],
                    child: const Icon(Icons.image_not_supported, size: 30, color: Colors.grey),
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
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$category • $timeAgo',
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
    );
  }
}