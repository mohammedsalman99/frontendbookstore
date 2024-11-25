import 'package:flutter/material.dart';
import 'package:frontend/service/fetchAuthorInfo.dart';
import 'package:frontend/service/fetchAuthorBooks.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:frontend/screens/Details/detailpage.dart';

class AuthorInfoScreen extends StatelessWidget {
  final String authorId;
  final AuthorService _authorService = AuthorService();
  final BookService _bookService = BookService();

  AuthorInfoScreen({Key? key, required this.authorId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Author Info',
          style: TextStyle(
            fontFamily: 'SF-Pro-Text',
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _authorService.fetchAuthorInfo(authorId),
        builder: (context, authorSnapshot) {
          if (authorSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (authorSnapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${authorSnapshot.error}',
                style: const TextStyle(
                  fontFamily: 'SF-Pro-Text',
                  fontWeight: FontWeight.w400,
                  fontSize: 14,
                ),
              ),
            );
          } else if (!authorSnapshot.hasData) {
            return const Center(
              child: Text(
                'No author info found.',
                style: TextStyle(
                  fontFamily: 'SF-Pro-Text',
                  fontWeight: FontWeight.w400,
                  fontSize: 14,
                ),
              ),
            );
          } else {
            final author = authorSnapshot.data!;

            // Fetch author books and calculate average rating
            return FutureBuilder<List<dynamic>>(
              future: _bookService.fetchAuthorBooks(authorId),
              builder: (context, bookSnapshot) {
                if (bookSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (bookSnapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading books: ${bookSnapshot.error}',
                      style: const TextStyle(
                        fontFamily: 'SF-Pro-Text',
                        fontWeight: FontWeight.w400,
                        fontSize: 14,
                      ),
                    ),
                  );
                } else if (!bookSnapshot.hasData || bookSnapshot.data!.isEmpty) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildAuthorProfile(author, 0.0), // No books -> Rating 0.0
                      const SizedBox(height: 16),
                      const Center(
                        child: Text(
                          'No books found for this author.',
                          style: TextStyle(
                            fontFamily: 'SF-Pro-Text',
                            fontWeight: FontWeight.w400,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  );
                } else {
                  final books = bookSnapshot.data!;
                  final averageRating = _calculateAverageRating(books);

                  return SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildAuthorProfile(author, averageRating),
                          const SizedBox(height: 24),
                          _buildAuthorBio(author['bio']),
                          const SizedBox(height: 24),
                          _buildAuthorBooks(context, books),
                        ],
                      ),
                    ),
                  );
                }
              },
            );
          }
        },
      ),
    );
  }

  Widget _buildAuthorProfile(Map<String, dynamic> author, double averageRating) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.pink[50],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 40,
            backgroundImage: NetworkImage(author['profilePicture'] ?? ''),
            onBackgroundImageError: (_, __) {},
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  author['fullName'] ?? 'Unknown Author',
                  style: const TextStyle(
                    fontFamily: 'SF-Pro-Text',
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      averageRating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontFamily: 'SF-Pro-Text',
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _socialIcon(FontAwesomeIcons.facebook, Colors.blue,
                        author['socialLinks']?['facebook']),
                    _socialIcon(FontAwesomeIcons.instagram, Colors.pink,
                        author['socialLinks']?['instagram']),
                    _socialIcon(FontAwesomeIcons.linkedin, Colors.blueAccent,
                        author['socialLinks']?['linkedin']),
                    _socialIcon(FontAwesomeIcons.globe, Colors.orange,
                        author['socialLinks']?['website']),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthorBio(String? bio) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'About the Author',
          style: TextStyle(
            fontFamily: 'SF-Pro-Text',
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          bio ?? 'No biography available.',
          style: const TextStyle(
            fontFamily: 'SF-Pro-Text',
            fontWeight: FontWeight.w400,
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildAuthorBooks(BuildContext context, List<dynamic> books) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Author Books',
          style: TextStyle(
            fontFamily: 'SF-Pro-Text',
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: books.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.7,
          ),
          itemBuilder: (context, index) {
            final book = books[index];
            return _bookCard(
              context,
              book['_id'],
              book['title'] ?? 'Untitled',
              book['image'] ?? '',
              book['authors'] ?? [], // Updated: Pass authors list
              book['price'],
              book['rating'],
            );
          },
        ),
      ],
    );
  }

  Widget _socialIcon(IconData icon, Color color, String? url) {
    return IconButton(
      icon: Icon(icon, color: color, size: 20),
      onPressed: () {
        if (url != null) _launchUrl(url);
      },
    );
  }

  Widget _bookCard(
      BuildContext context,
      String bookId,
      String title,
      String imageUrl,
      List<dynamic> authors, // Updated: Accept multiple authors
      dynamic price,
      dynamic rating,
      ) {
    final double displayPrice = (price is int ? price.toDouble() : price) ?? 0.0;
    final double displayRating = (rating is int ? rating.toDouble() : rating) ?? 0.0;

    // Combine all authors into a single string
    String authorsText = authors.isNotEmpty
        ? authors.map((author) => author['fullName']).join(', ')
        : 'Unknown Author';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailPage(bookId: bookId),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                imageUrl,
                height: 90,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 100,
                    color: Colors.grey[200],
                    child: const Icon(Icons.broken_image, color: Colors.grey),
                  );
                },
              ),
            ),
            const SizedBox(height: 7),
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'SF-Pro-Text',
                fontWeight: FontWeight.bold,
                fontSize: 11,
                color: Colors.black,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              'By $authorsText', // Updated: Display all authors
              style: const TextStyle(
                fontFamily: 'SF-Pro-Text',
                fontWeight: FontWeight.w400,
                fontSize: 9,
                color: Colors.grey,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 7),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  displayPrice == 0 ? 'Free' : '₹ ${displayPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontFamily: 'SF-Pro-Text',
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    color: Colors.red,
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 14),
                    const SizedBox(width: 2),
                    Text(
                      displayRating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontFamily: 'SF-Pro-Text',
                        fontWeight: FontWeight.w500,
                        fontSize: 11,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }


  void _launchUrl(String? url) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $url';
    }
  }
}

double _calculateAverageRating(List<dynamic> books) {
  if (books.isEmpty) return 0.0;

  double totalRating = 0.0;
  int count = 0;

  for (var book in books) {
    if (book['rating'] != null) {
      totalRating +=
      (book['rating'] is int ? book['rating'].toDouble() : book['rating']);
      count++;
    }
  }

  return count > 0 ? totalRating / count : 0.0;
}
