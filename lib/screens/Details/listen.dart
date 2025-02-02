import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart'; // For shared preferences

class ListenPage extends StatefulWidget {
  final String bookId;

  const ListenPage({Key? key, required this.bookId}) : super(key: key);

  @override
  _ListenPageState createState() => _ListenPageState();
}

class _ListenPageState extends State<ListenPage> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isLoading = false;
  bool _isAudioReady = false;
  bool _isPlaying = false;
  Duration _audioDuration = Duration.zero;
  Duration _currentPosition = Duration.zero;
  String? _cachedAudioUrl;

  @override
  void initState() {
    super.initState();
    fetchAndCacheAudio();

    _audioPlayer.durationStream.listen((duration) {
      if (duration != null) {
        setState(() {
          _audioDuration = duration;
        });
      }
    });

    _audioPlayer.positionStream.listen((position) {
      setState(() {
        _currentPosition = position;
      });
    });
  }

  /// Retrieve the token from SharedPreferences
  Future<String?> getUserToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> fetchAndCacheAudio() async {
    setState(() {
      _isLoading = true;
    });

    final url =
        'https://readme-backend-zdiq.onrender.com/api/v1/summary/books/${widget.bookId}/summary/audio';

    print("Fetching audio from URL: $url");

    try {
      // Fetch the token dynamically
      final userToken = await getUserToken();
      if (userToken == null) {
        print("Authentication token is missing");
        _showError("Authentication failed. Please log in again.");
        setState(() {
          _isLoading = false;
        });
        return;
      }

      print("Using token: $userToken");

      if (_cachedAudioUrl != null) {
        print("Using cached audio URL: $_cachedAudioUrl");
        await _audioPlayer.setAudioSource(
          AudioSource.uri(
            Uri.parse(_cachedAudioUrl!),
            headers: {
              'Authorization': 'Bearer $userToken',
            },
          ),
        );
        setState(() {
          _isAudioReady = true;
          _isLoading = false;
        });
        print("Audio loaded from cache");
        return;
      }

      print("Making GET request to fetch audio");
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $userToken',
        },
      );

      print("Response status code: ${response.statusCode}");
      print("Response headers: ${response.headers}");
      print("Response body: ${response.body}");

      if (response.statusCode == 200 && response.headers['content-type'] == 'audio/mpeg') {
        print("Audio successfully fetched from server");

        setState(() {
          _cachedAudioUrl = url;
        });

        await _audioPlayer.setAudioSource(
          AudioSource.uri(
            Uri.parse(url),
            headers: {
              'Authorization': 'Bearer $userToken',
            },
          ),
        );

        setState(() {
          _isAudioReady = true;
        });
        print("Audio successfully loaded into the player");
      } else if (response.statusCode == 401) {
        print("Authentication failed: Invalid or expired token");
        _showError("Authentication failed. Please log in again.");
      } else {
        print("Unexpected response: ${response.statusCode} - ${response.body}");
        throw Exception("Unexpected content type or audio not available");
      }
    } catch (e) {
      print("Error occurred during fetch: $e");
      _showError("An error occurred: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
      print("Fetch operation completed");
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Widget _buildPlaybackControls() {
    return StreamBuilder<PlayerState>(
      stream: _audioPlayer.playerStateStream,
      builder: (context, snapshot) {
        final playerState = snapshot.data;
        final isPlaying = playerState?.playing ?? false;
        final processingState = playerState?.processingState;

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            StreamBuilder<Duration>(
              stream: _audioPlayer.positionStream,
              builder: (context, snapshot) {
                final currentPosition = snapshot.data ?? Duration.zero;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${currentPosition.inMinutes}:${(currentPosition.inSeconds % 60).toString().padLeft(2, '0')}",
                        style: TextStyle(color: Color(0xFF5AA5B1), fontSize: 14),
                      ),
                      Text(
                        "${_audioDuration.inMinutes}:${(_audioDuration.inSeconds % 60).toString().padLeft(2, '0')}",
                        style: TextStyle(color: Color(0xFF5AA5B1), fontSize: 14),
                      ),
                    ],
                  ),
                );
              },
            ),

            StreamBuilder<Duration>(
              stream: _audioPlayer.positionStream,
              builder: (context, snapshot) {
                final currentPosition = snapshot.data ?? Duration.zero;
                return Slider(
                  activeColor: Color(0xFF5AA5B1),
                  inactiveColor: Colors.grey,
                  thumbColor: Color(0xFF5AA5B1),
                  value: currentPosition.inSeconds.toDouble(),
                  max: _audioDuration.inSeconds.toDouble(),
                  onChanged: (value) async {
                    final position = Duration(seconds: value.toInt());
                    await _audioPlayer.seek(position);
                  },
                );
              },
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(Icons.replay_10),
                  color: Color(0xFF5AA5B1),
                  iconSize: 36,
                  onPressed: _isAudioReady
                      ? () async {
                    final newPosition =
                        _currentPosition - Duration(seconds: 10);
                    await _audioPlayer.seek(
                        newPosition < Duration.zero ? Duration.zero : newPosition);
                  }
                      : null,
                ),

                GestureDetector(
                  onTap: _isAudioReady
                      ? () async {
                    if (processingState == ProcessingState.completed) {
                      await _audioPlayer.seek(Duration.zero);
                      await _audioPlayer.play();
                    } else if (isPlaying) {
                      await _audioPlayer.pause();
                    } else {
                      await _audioPlayer.play();
                    }
                  }
                      : null,
                  child: Container(
                    height: 80,
                    width: 80,
                    decoration: BoxDecoration(
                      color: Color(0xFF5AA5B1),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF5AA5B1).withOpacity(0.6),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      (processingState == ProcessingState.completed || !isPlaying)
                          ? Icons.play_arrow
                          : Icons.pause,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                ),

                IconButton(
                  icon: Icon(Icons.forward_10),
                  color: Color(0xFF5AA5B1),
                  iconSize: 36,
                  onPressed: _isAudioReady
                      ? () async {
                    final newPosition = _currentPosition + Duration(seconds: 10);
                    await _audioPlayer.seek(newPosition > _audioDuration
                        ? _audioDuration
                        : newPosition);
                  }
                      : null,
                ),
              ],
            ),
          ],
        );
      },
    );
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          "Listening to Summary",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: _isLoading
              ? Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Color(0xFF5AA5B1),
                strokeWidth: 4,
              ),
              SizedBox(height: 20),
            ],
          )
              : _isAudioReady
              ? Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: Duration(milliseconds: 800),
                height: 220,
                width: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Color(0xFF5AA5B1),
                      Color(0xFF5AA5B1).withOpacity(0.7)
                    ],
                    center: Alignment.center,
                    radius: 0.8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF5AA5B1).withOpacity(0.6),
                      blurRadius: 25,
                      spreadRadius: 5,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.library_books,
                  color: Colors.white,
                  size: 120,
                ),
              ),
              SizedBox(height: 24),
              Text(
                "Audio Summary Ready",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5AA5B1),
                ),
              ),

              SizedBox(height: 30),
              _buildPlaybackControls(),
            ],
          )
              : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.redAccent,
                size: 120,
              ),
              SizedBox(height: 16),
              Text(
                "Audio Not Available",
                style: TextStyle(
                  color: Color(0xFF5AA5B1),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                "Please try again later.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF5AA5B1),
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF5AA5B1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                onPressed: () {
                  fetchAndCacheAudio();
                },
                child: Text(
                  "Retry",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
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