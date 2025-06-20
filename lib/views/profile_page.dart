import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fastnews/views/login_page.dart';
import 'package:fastnews/services/news_service.dart';
import 'package:fastnews/services/auth_service.dart';
import 'add_article_page.dart';
import 'edit_article_page.dart';
// Impor untuk manajemen tema
import 'package:provider/provider.dart';
import '../services/theme_provider.dart';

class ProfilePage extends StatefulWidget {
  final String token;

  const ProfilePage({Key? key, required this.token}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final NewsService _newsService = NewsService();
  final AuthService _authService = AuthService();
  
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final data = await _authService.getUserData();
    if (mounted) {
      setState(() {
        _userData = data;
      });
    }
  }

  void _handleLogout() async {
    await _authService.logout();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
        (Route<dynamic> route) => false,
      );
    }
  }
  
  void _navigateAndRefreshAdd() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddArticlePage(token: widget.token)),
    ).then((_) {
      setState(() {});
    });
  }

  void _navigateAndRefreshEdit(Map<String, dynamic> article) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditArticlePage(token: widget.token, article: article)),
    ).then((_) {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    // Akses theme provider
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      // AppBar sekarang akan mengikuti tema dari main.dart
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Profile', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: _navigateAndRefreshAdd,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 60,
              backgroundImage: NetworkImage(_userData?['avatar'] ?? 'https://via.placeholder.com/150'),
              backgroundColor: Colors.grey[200],
            ),
            const SizedBox(height: 16),
            Text(
              _userData?['name'] ?? 'Loading...',
              style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              _userData?['title'] ?? 'User',
              style: GoogleFonts.poppins(fontSize: 14, color: Theme.of(context).primaryColor),
            ),
            const SizedBox(height: 32),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'My Articles',
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<Map<String, dynamic>>(
                future: _newsService.getUserArticles(widget.token),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: Could not load articles'));
                  } else if (!snapshot.hasData || (snapshot.data!['data']['articles'] as List).isEmpty) {
                    return Center(child: Text('You have not created any articles yet.'));
                  }
                  
                  final articles = snapshot.data!['data']['articles'] as List;
                  return ListView.builder(
                    itemCount: articles.length,
                    itemBuilder: (context, index) {
                      final article = articles[index];
                      return Card(
                        // Card akan otomatis menyesuaikan warna dengan tema
                        margin: EdgeInsets.only(bottom: 16),
                        child: ListTile(
                          title: Text(article['title'], style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                          subtitle: Text(article['category'], style: GoogleFonts.poppins()),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit, color: Theme.of(context).colorScheme.secondary),
                                onPressed: () => _navigateAndRefreshEdit(article),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red[400]),
                                onPressed: () async {
                                  final bool? confirmed = await showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text('Delete Article'),
                                      content: Text('Are you sure you want to delete this article?'),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel')),
                                        TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Delete')),
                                      ],
                                    ),
                                  );

                                  if (confirmed == true) {
                                    try {
                                      await _newsService.deleteArticle(article['id'], widget.token);
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Article deleted")));
                                      setState(() {}); // Refresh list
                                    } catch(e) {
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to delete article")));
                                    }
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // OPSI UNTUK MENGUBAH TEMA
            Card(
              margin: const EdgeInsets.only(bottom: 16.0),
              child: SwitchListTile(
                title: Text(
                  'Dark Mode',
                  style: GoogleFonts.poppins(),
                ),
                value: themeProvider.isDarkMode,
                onChanged: (value) {
                  themeProvider.setDarkTheme(value);
                },
                secondary: Icon(
                  themeProvider.isDarkMode ? Icons.nightlight_round : Icons.wb_sunny,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ),
            
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _handleLogout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[400], 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                ),
                child: Text(
                  'Log Out',
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}