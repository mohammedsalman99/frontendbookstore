import 'package:flutter/material.dart';
import 'package:frontend/service/authors_service.dart';
import 'package:frontend/screens/authors_details/author_info.dart';
import 'package:frontend/service/searchservice.dart';

class AuthorsScreen extends StatelessWidget {
  final AuthorService _authorService = AuthorService();
  final SearchService _searchService = SearchService();

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
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black),
            onPressed: () {
              showSearch(
                context: context,
                delegate: AuthorSearchDelegate(_searchService),
              );
            },
          ),
        ],
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
                return authorCard(context, author);
              },
            );
          }
        },
      ),
    );
  }

  Widget authorCard(BuildContext context, dynamic author) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AuthorInfoScreen(authorId: author['_id']),
          ),
        );
      },
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundImage: NetworkImage(author['profilePicture']),
            onBackgroundImageError: (error, stackTrace) {},
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
  }
}

class AuthorSearchDelegate extends SearchDelegate<String> {
  final SearchService _searchService;

  AuthorSearchDelegate(this._searchService);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return FutureBuilder(
      future: _searchService.search(query),
      builder: (context, AsyncSnapshot<Map<String, dynamic>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return Center(
            child: Text('No results found'),
          );
        }

        final authors = snapshot.data!['authors']['data'] as List<dynamic>;

        return authors.isEmpty
            ? Center(
          child: Text('No authors found'),
        )
            : GridView.builder(
          padding: const EdgeInsets.all(8.0),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8.0,
            mainAxisSpacing: 8.0,
          ),
          itemCount: authors.length,
          itemBuilder: (context, index) {
            final author = authors[index];
            return authorCard(context, author);
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return Center(
        child: Text('Search for authors by name'),
      );
    }
    return buildResults(context);
  }

  Widget authorCard(BuildContext context, dynamic author) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AuthorInfoScreen(authorId: author['_id']),
          ),
        );
      },
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundImage: NetworkImage(author['profilePicture']),
            onBackgroundImageError: (error, stackTrace) {},
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
  }
}
