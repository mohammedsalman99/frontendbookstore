import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../Details/pdf_viewer_page.dart';

class MyDownloadsPage extends StatefulWidget {
  const MyDownloadsPage({Key? key}) : super(key: key);

  @override
  _MyDownloadsPageState createState() => _MyDownloadsPageState();
}

class _MyDownloadsPageState extends State<MyDownloadsPage> {
  late Box _downloadsBox;
  bool _isSelectionMode = false;
  List<int> _selectedIndexes = [];

  @override
  void initState() {
    super.initState();
    initializeHiveBox();
  }

  Future<void> initializeHiveBox() async {
    try {
      _downloadsBox = Hive.box('downloads');
    } catch (e) {
      print("Error initializing Hive box: $e");
    }
  }

  void toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedIndexes.clear();
      }
    });
  }

  void selectAll() {
    setState(() {
      _selectedIndexes = List.generate(_downloadsBox.length, (index) => index);
    });
  }

  void deleteSelectedItems() {
    setState(() {
      for (var index in _selectedIndexes.reversed) {
        _downloadsBox.deleteAt(index);
      }
      _selectedIndexes.clear();
      _isSelectionMode = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Selected downloads removed successfully!")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Downloads"),
        backgroundColor: const Color(0xFF5AA5B1),
        actions: [
          if (_isSelectionMode) ...[
            IconButton(
              icon: const Icon(Icons.select_all),
              onPressed: selectAll,
              tooltip: "Select All",
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: deleteSelectedItems,
              tooltip: "Delete Selected",
            ),
          ],
          IconButton(
            icon: Icon(_isSelectionMode ? Icons.close : Icons.edit),
            onPressed: toggleSelectionMode,
            tooltip: _isSelectionMode ? "Cancel Selection" : "Edit",
          ),
        ],
      ),
      body: FutureBuilder(
        future: initializeHiveBox(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text("Error: ${snapshot.error}"),
            );
          }

          return ValueListenableBuilder(
            valueListenable: _downloadsBox.listenable(),
            builder: (context, Box box, _) {
              final downloads = box.values.toList();

              if (downloads.isEmpty) {
                return const Center(
                  child: Text(
                    "No downloads yet. Start downloading books!",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                );
              }

              return ListView.builder(
                itemCount: downloads.length,
                padding: const EdgeInsets.all(8),
                itemBuilder: (context, index) {
                  final book = Map<String, dynamic>.from(downloads[index]);
                  final isSelected = _selectedIndexes.contains(index);

                  return Stack(
                    children: [
                      Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 6,
                        color: isSelected ? Colors.teal.shade50 : Colors.white,
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              book['image'],
                              width: 60,
                              height: 90,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.broken_image, size: 60),
                            ),
                          ),
                          title: Text(
                            book['title'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                          subtitle: const Text(
                            "Tap to open or hold to select",
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                          trailing: _isSelectionMode
                              ? Checkbox(
                            value: isSelected,
                            onChanged: (value) {
                              setState(() {
                                if (value == true) {
                                  _selectedIndexes.add(index);
                                } else {
                                  _selectedIndexes.remove(index);
                                }
                              });
                            },
                          )
                              : IconButton(
                            icon: const Icon(Icons.arrow_forward),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      PDFViewerPage(pdfUrl: book['bookLink']),
                                ),
                              );
                            },
                          ),
                          onTap: () {
                            if (_isSelectionMode) {
                              setState(() {
                                if (isSelected) {
                                  _selectedIndexes.remove(index);
                                } else {
                                  _selectedIndexes.add(index);
                                }
                              });
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      PDFViewerPage(pdfUrl: book['bookLink']),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                      if (isSelected && _isSelectionMode)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: _isSelectionMode
          ? FloatingActionButton(
        backgroundColor: Colors.redAccent,
        onPressed: deleteSelectedItems,
        child: const Icon(Icons.delete, color: Colors.white),
      )
          : null,
    );
  }
}
