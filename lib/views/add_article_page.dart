import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/news_service.dart';

class AddArticlePage extends StatefulWidget {
  final String token;
  const AddArticlePage({Key? key, required this.token}) : super(key: key);

  @override
  State<AddArticlePage> createState() => _AddArticlePageState();
}

class _AddArticlePageState extends State<AddArticlePage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  // HAPUS: _categoryController tidak diperlukan lagi
  // final _categoryController = TextEditingController(); 
  final _contentController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _tagsController = TextEditingController();

  // Variabel untuk menyimpan nilai dropdown yang dipilih
  String? _selectedCategory;

  // Daftar kategori yang akan ditampilkan di dropdown
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
  void dispose() {
    _titleController.dispose();
    // HAPUS: dispose untuk _categoryController
    // _categoryController.dispose(); 
    _contentController.dispose();
    _imageUrlController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _submitArticle() async {
    // Validasi form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Siapkan data artikel dari controller
      final articleData = {
        'title': _titleController.text,
        // UBAH: Gunakan nilai dari _selectedCategory
        'category': _selectedCategory, 
        'content': _contentController.text,
        'imageUrl': _imageUrlController.text,
        // API membutuhkan field ini, kita berikan nilai default
        'readTime': '5 min',
        'isTrending': false,
        'tags': _tagsController.text.split(',').map((e) => e.trim()).toList(),
      };

      // Panggil service untuk membuat artikel
      await _newsService.createArticle(articleData, widget.token);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Article created successfully!')),
      );

      // Kembali ke halaman sebelumnya (profile page)
      Navigator.pop(context, true); // Kirim 'true' untuk refresh di profile page

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create article: $e')),
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
          'Add New Article',
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
              // Title Field
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
              
              // Image URL Field
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
              
              // Tags Field
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

              // Content Field
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

              // Submit Button
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitArticle,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF6B73FF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Submit Article',
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