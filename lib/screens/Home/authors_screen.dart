import 'package:flutter/material.dart';
import 'package:frontend/service/authors_service.dart';
import 'package:frontend/screens/authors_details/author_info.dart'; 

class AuthorsScreen extends StatelessWidget {
  final AuthorService _authorService = AuthorService(); 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, 
      appBar: AppBar(
        title: const Text(
          'Authors',
          style: TextStyle(
            fontSize: 18,
            fontFamily: 'SF-Pro-Text', 
            fontWeight: FontWeight.w700, 
          ),
        ),
        backgroundColor: Colors.white, 
        foregroundColor: Colors.black, 
        elevation: 0, 
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _authorService.fetchAuthors(), 
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(
                  fontFamily: 'SF-Pro-Text', 
                  fontWeight: FontWeight.w400, 
                  fontSize: 14,
                ),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No authors found.',
                style: TextStyle(
                  fontFamily: 'SF-Pro-Text', 
                  fontWeight: FontWeight.w300, 
                  fontSize: 14,
                ),
              ),
            );
          } else {
            final authors = snapshot.data!;
            return GridView.builder(
              padding: const EdgeInsets.all(8.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8.0,
                mainAxisSpacing: 8.0,
              ),
              itemCount: authors.length,
              itemBuilder: (context, index) {
                final author = authors[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            AuthorInfoScreen(authorId: author['_id']),
                      ),
                    );
                  },
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundImage: NetworkImage(author['profilePicture']),
                        onBackgroundImageError: (error, stackTrace) {
                        },
                      ),
                      const SizedBox(height: 8),
                      Text(
                        author['fullName'],
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'SF-Pro-Text', 
                          fontWeight: FontWeight.w500, 
                          fontSize: 10,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
