import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fastnews/views/login_page.dart';
import 'package:fastnews/services/news_service.dart';

class ProfilePage extends StatefulWidget {
  final String? token;

  const ProfilePage({Key? key, this.token}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final NewsService _newsService = NewsService();
  late Future<Map<String, dynamic>> _userArticles;
  bool _isAddingArticle = false;
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _categoryController = TextEditingController();
  final _contentController = TextEditingController();
  final _imageUrlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.token != null) {
      _userArticles = _newsService.getUserArticles(widget.token!);
    }
  }

  void _handleLogout() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Logging out...')),
    );

    Future.delayed(const Duration(seconds: 1), () {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
        (Route<dynamic> route) => false,
      );
    });
  }

  void _showAddArticleForm() {
    setState(() {
      _isAddingArticle = true;
    });
  }

  void _cancelAddArticle() {
    setState(() {
      _isAddingArticle = false;
      _titleController.clear();
      _categoryController.clear();
      _contentController.clear();
      _imageUrlController.clear();
    });
  }

  Future<void> _submitArticle() async {
    if (_formKey.currentState!.validate() && widget.token != null) {
      try {
        final articleData = {
          'title': _titleController.text,
          'category': _categoryController.text,
          'content': _contentController.text,
          'imageUrl': _imageUrlController.text,
          'readTime': '5 min',
          'tags': ['news'],
        };

        await _newsService.createArticle(articleData, widget.token!);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Article created successfully!')),
        );

        setState(() {
          _isAddingArticle = false;
          _userArticles = _newsService.getUserArticles(widget.token!);
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create article: $e')),
        );
      }
    }
  }

  Future<void> _deleteArticle(String articleId) async {
    try {
      final success = await _newsService.deleteArticle(articleId, widget.token!);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Article deleted successfully!')),
        );
        setState(() {
          _userArticles = _newsService.getUserArticles(widget.token!);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete article: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryBlue = Theme.of(context).colorScheme.primary;
    final Color errorColor = Theme.of(context).colorScheme.error;

    return Column(
      children: [
        AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          title: Text(
            'Profile',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.add, color: Colors.grey),
              onPressed: _showAddArticleForm,
            ),
            const SizedBox(width: 8),
          ],
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: _isAddingArticle
                ? _buildAddArticleForm()
                : Column(
                    children: [
                      // User Info Section
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: AssetImage('assets/images/avatar_placeholder.png'),
                        onBackgroundImageError: (exception, stackTrace) {
                          print('Error loading avatar image');
                        },
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Muhamad Rezky Alfarizy',
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Editor',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: primaryBlue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Joined 2025',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // My Articles Section
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'My Articles',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Articles List
                      Expanded(
                        child: widget.token == null
                            ? Center(child: Text('Please login to view your articles'))
                            : FutureBuilder<Map<String, dynamic>>(
                                future: _userArticles,
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return Center(child: CircularProgressIndicator());
                                  } else if (snapshot.hasError) {
                                    return Center(child: Text('Error: ${snapshot.error}'));
                                  } else if (!snapshot.hasData || snapshot.data!['data']['articles'].isEmpty) {
                                    return Center(child: Text('No articles found'));
                                  }

                                  final articles = snapshot.data!['data']['articles'] as List;

                                  return ListView.builder(
                                    itemCount: articles.length,
                                    itemBuilder: (context, index) {
                                      final article = articles[index];
                                      return _buildArticleItem(article);
                                    },
                                  );
                                },
                              ),
                      ),

                      // Log Out Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _handleLogout,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: errorColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Log Out',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddArticleForm() {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _categoryController,
              decoration: InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a category';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _imageUrlController,
              decoration: InputDecoration(
                labelText: 'Image URL',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _contentController,
              decoration: InputDecoration(
                labelText: 'Content',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter content';
                }
                return null;
              },
            ),
            SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _cancelAddArticle,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                    ),
                    child: Text('Cancel'),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _submitArticle,
                    child: Text('Submit'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArticleItem(Map<String, dynamic> article) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    article['title'] ?? 'No title',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.edit, color: Colors.blue),
                  onPressed: () {
                    // Implement edit functionality
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Edit article: ${article['title']}')),
                    );
                  },
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    _deleteArticle(article['id']);
                  },
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              article['category'] ?? 'General',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 8),
            if (article['imageUrl'] != null)
              Image.network(
                article['imageUrl'],
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 150,
                    color: Colors.grey[200],
                    child: Center(child: Text('No image')),
                  );
                },
              ),
            SizedBox(height: 8),
            Text(
              article['content']?.length > 100
                  ? '${article['content'].substring(0, 100)}...'
                  : article['content'] ?? 'No content',
            ),
          ],
        ),
      ),
    );
  }
}