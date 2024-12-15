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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor, // Dynamic background
      appBar: AppBar(
        title: Text(
          'Author Info',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        foregroundColor: Theme.of(context).iconTheme.color, // Dynamic icon color
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
                style: Theme.of(context).textTheme.bodyMedium, // Dynamic text style
              ),
            );
          } else if (!authorSnapshot.hasData) {
            return Center(
              child: Text(
                'No author info found.',
                style: Theme.of(context).textTheme.bodyMedium, // Dynamic text style
              ),
            );
          } else {
            final author = authorSnapshot.data!;
            return FutureBuilder<List<dynamic>>(
              future: _bookService.fetchAuthorBooks(authorId),
              builder: (context, bookSnapshot) {
                if (bookSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (bookSnapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading books: ${bookSnapshot.error}',
                      style: Theme.of(context).textTheme.bodyMedium, // Dynamic text style
                    ),
                  );
                } else if (!bookSnapshot.hasData || bookSnapshot.data!.isEmpty) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildAuthorProfile(context, author, 0.0),
                      const SizedBox(height: 16),
                      Center(
                        child: Text(
                          'No books found for this author.',
                          style: Theme.of(context).textTheme.bodyMedium, // Dynamic text style
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
                          _buildAuthorProfile(context, author, averageRating),
                          const SizedBox(height: 24),
                          _buildAuthorBio(context, author['bio']),
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

  Widget _buildAuthorProfile(BuildContext context, Map<String, dynamic> author, double averageRating) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor, // Dynamic card color
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
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      averageRating.toStringAsFixed(1),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
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

  Widget _buildAuthorBio(BuildContext context, String? bio) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'About the Author',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          bio ?? 'No biography available.',
          style: Theme.of(context).textTheme.bodyMedium, // Dynamic text style
        ),
      ],
    );
  }

  Widget _buildAuthorBooks(BuildContext context, List<dynamic> books) {
    // Filter books to include only those authored by the selected author
    final filteredBooks = books.where((book) {
      return book['authors'].any((author) => author['_id'] == authorId);
    }).toList();

    if (filteredBooks.isEmpty) {
      return Center(
        child: Text(
          'No books found for this author.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w400,
            fontSize: 14,
          ), // Dynamic text style
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Author Books',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ), // Dynamic text style
        ),
        const SizedBox(height: 16),
        GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: filteredBooks.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.7,
          ),
          itemBuilder: (context, index) {
            final book = filteredBooks[index];
            return _bookCard(
              context,
              book['_id'],
              book['title'] ?? 'Untitled',
              book['image'] ?? '',
              book['authors'] ?? [],
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
      List<dynamic> authors, 
      dynamic price,
      dynamic rating,
      ) {
    final double displayPrice = (price is int ? price.toDouble() : price) ?? 0.0;
    final double displayRating = (rating is int ? rating.toDouble() : rating) ?? 0.0;

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
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[800]
              : Colors.white, // Dynamic background color
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.black.withOpacity(0.4)
                  : Colors.black.withOpacity(0.1), // Adjust shadow intensity
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
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[700]
                        : Colors.grey[200], // Adjust error background color
                    child: Icon(
                      Icons.broken_image,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.grey, // Adjust icon color
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 7),
            Text(
              title,
              style: TextStyle(
                fontFamily: 'SF-Pro-Text',
                fontWeight: FontWeight.bold,
                fontSize: 11,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black, // Dynamic text color
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              'By $authorsText',
              style: TextStyle(
                fontFamily: 'SF-Pro-Text',
                fontWeight: FontWeight.w400,
                fontSize: 9,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[400]
                    : Colors.grey, // Dynamic text color
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
                  style: TextStyle(
                    fontFamily: 'SF-Pro-Text',
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.green
                        : Colors.red, // Dynamic price color
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 14),
                    const SizedBox(width: 2),
                    Text(
                      displayRating.toStringAsFixed(1),
                      style: TextStyle(
                        fontFamily: 'SF-Pro-Text',
                        fontWeight: FontWeight.w500,
                        fontSize: 11,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white70
                            : Colors.black, // Dynamic rating text color
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
