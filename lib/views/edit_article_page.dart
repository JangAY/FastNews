// edit_article_page.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/news_service.dart';

class EditArticlePage extends StatefulWidget {
  final String token;
  final Map<String, dynamic> article; // Pass the article data

  const EditArticlePage({Key? key, required this.token, required this.article}) : super(key: key);

  @override
  State<EditArticlePage> createState() => _EditArticlePageState();
}

class _EditArticlePageState extends State<EditArticlePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  // HAPUS: _categoryController tidak diperlukan lagi
  // late TextEditingController _categoryController; 
  late TextEditingController _contentController;
  late TextEditingController _imageUrlController;
  late TextEditingController _tagsController;

  // Variabel state untuk dropdown
  String? _selectedCategory;
  
  // Daftar kategori yang sama dengan halaman tambah
  final List<String> _categories = [
    'Technology',
    'Sports',
    'Health',
    'Business',
    'Entertainment',
    'Politics',
    'Science'
  ];

  final NewsService _newsService = NewsService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing article data
    _titleController = TextEditingController(text: widget.article['title']);
    _contentController = TextEditingController(text: widget.article['content']);
    _imageUrlController = TextEditingController(text: widget.article['imageUrl']);
    _tagsController = TextEditingController(text: (widget.article['tags'] as List?)?.join(', '));
    
    // UBAH: Inisialisasi nilai untuk dropdown, bukan controller
    _selectedCategory = widget.article['category'];
    // Validasi tambahan jika kategori dari data lama tidak ada di list baru
    if (!_categories.contains(_selectedCategory)) {
      _selectedCategory = null;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    // HAPUS: dispose untuk _categoryController
    // _categoryController.dispose();
    _contentController.dispose();
    _imageUrlController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _submitArticleUpdate() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final articleData = {
        'title': _titleController.text,
        // UBAH: Gunakan nilai dari _selectedCategory
        'category': _selectedCategory, 
        'content': _contentController.text,
        'imageUrl': _imageUrlController.text,
        'readTime': widget.article['readTime'] ?? '5 min', // Keep existing or default
        'isTrending': widget.article['isTrending'] ?? false, // Keep existing value
        'tags': _tagsController.text.split(',').map((e) => e.trim()).toList(),
      };

      await _newsService.updateArticle(widget.article['id'], articleData, widget.token);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Article updated successfully!')),
      );

      Navigator.pop(context, true); // Go back to profile page with success status
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update article: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(color: Colors.black),
        title: Text(
          'Edit Article',
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // PERBAIKAN: Widget DropdownButtonFormField untuk Kategori
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                hint: Text('Select a category'),
                items: _categories.map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedCategory = newValue;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a category';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _imageUrlController,
                keyboardType: TextInputType.url,
                decoration: InputDecoration(
                  labelText: 'Image URL',
                  hintText: 'https://example.com/image.jpg',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an image URL';
                  }
                   if (!Uri.tryParse(value)!.isAbsolute) {
                    return 'Please enter a valid URL';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _tagsController,
                decoration: InputDecoration(
                  labelText: 'Tags',
                  hintText: 'tech, ai, news (comma-separated)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter at least one tag';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _contentController,
                decoration: InputDecoration(
                  labelText: 'Content',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                maxLines: 8,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the article content';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitArticleUpdate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF6B73FF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Update Article',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}