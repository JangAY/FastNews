import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fastnews/views/login_page.dart';
import 'package:fastnews/services/news_service.dart';
import 'package:fastnews/services/auth_service.dart';

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
    setState(() {
      _userData = data;
    });
  }

  void _handleLogout() async {
    await _authService.logout();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
      (Route<dynamic> route) => false,
    );
  }
  
  // Placeholder for future implementation
  void _showAddArticleForm() {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Add article functionality coming soon!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('Profile', style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.w600)),
        centerTitle: true,
         actions: [
            IconButton(
              icon: const Icon(Icons.add, color: Colors.grey),
              onPressed: _showAddArticleForm,
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
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!['data']['articles'].isEmpty) {
                    return Center(child: Text('You have not created any articles.'));
                  }
                  
                  final articles = snapshot.data!['data']['articles'] as List;
                  return ListView.builder(
                    itemCount: articles.length,
                    itemBuilder: (context, index) {
                      final article = articles[index];
                      return Card(
                        margin: EdgeInsets.only(bottom: 16),
                        child: ListTile(
                          title: Text(article['title']),
                          subtitle: Text(article['category']),
                          trailing: IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              // Optimistic delete
                              setState(() {
                                (articles).removeAt(index);
                              });
                              try {
                                await _newsService.deleteArticle(article['id'], widget.token);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Article deleted"))
                                );
                              } catch(e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Failed to delete article"))
                                );
                                // Re-fetch on error
                                setState((){});
                              }
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _handleLogout,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red[400]),
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