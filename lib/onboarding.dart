import 'package:flutter/material.dart';
import 'package:frontend/home.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/auth/login.dart';
import 'screens/auth/signup.dart';


class OnboardingScreen extends StatefulWidget {
  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> onboardingData = [
    {
      "title": "Reading Exercises the Brain",
      "description": "Reading is a workout for your brain that improves memory function.",
      "image": "assets/icons/img1.jpg",
    },
    {
      "title": "Improves the Ability to Focus",
      "description": "Reading is one of the few activities that requires your undivided attention.",
      "image": "assets/icons/img2.jpg",
    },
    {
      "title": "All we need is books",
      "description": "Reading a variety of topics can make you a more knowledgeable person.",
      "image": "assets/icons/img3.jpg",
    },
  ];

  void _nextPage() {
    if (_currentPage < onboardingData.length - 1) {
      _pageController.nextPage(duration: Duration(milliseconds: 300), curve: Curves.ease);
    } else {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => LoginPage()));
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (int page) {
                setState(() {
                  _currentPage = page;
                });
              },
              itemCount: onboardingData.length,
              itemBuilder: (context, index) => OnboardingPage(
                title: onboardingData[index]["title"]!,
                description: onboardingData[index]["description"]!,
                imagePath: onboardingData[index]["image"]!,
                pageIndex: index,
                currentPage: _currentPage,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 10.0),
            child: Text(
              "Step ${_currentPage + 1} of ${onboardingData.length}",
              style: TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              onboardingData.length,
                  (index) => buildDot(index, context),
            ),
          ),
          SizedBox(height: 15),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 30.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => LoginPage()));
                  },
                  child: Text(
                    _currentPage == onboardingData.length - 1 ? "" : "Skip",
                    style: TextStyle(color: Color(0xFF5AA5B1)),
                  ),
                ),

                ElevatedButton(
                  onPressed: _nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF5AA5B1),
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    _currentPage == onboardingData.length - 1 ? "Start Now" : "Next",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 15),
        ],
      ),
    );
  }

  // Dot indicator for the onboarding pages
  Widget buildDot(int index, BuildContext context) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      margin: EdgeInsets.only(right: 5),
      height: 10,
      width: _currentPage == index ? 20 : 10,
      decoration: BoxDecoration(
        color: _currentPage == index ? Color(0xFF5AA5B1) : Colors.grey,
        borderRadius: BorderRadius.circular(5),
      ),
    );
  }
}


class OnboardingPage extends StatelessWidget {
  final String title;
  final String description;
  final String imagePath;
  final int pageIndex;
  final int currentPage;

  const OnboardingPage({
    Key? key,
    required this.title,
    required this.description,
    required this.imagePath,
    required this.pageIndex,
    required this.currentPage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool isVisible = pageIndex == currentPage;

    return Padding(
      padding: EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: Duration(seconds: 1),
            curve: Curves.easeInOut,
            width: isVisible ? 300 : 200,
            height: isVisible ? 300 : 200,
            child: Image.asset(
              imagePath, // Use the imagePath parameter
              fit: BoxFit.contain,
              color: isVisible ? null : Colors.grey,
            ),
          ),
          SizedBox(height: 30),
          AnimatedOpacity(
            opacity: isVisible ? 1.0 : 0.0,
            duration: Duration(milliseconds: 500),
            child: Text(
              title,
              style: GoogleFonts.lato(
                textStyle: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 15),
          AnimatedOpacity(
            opacity: isVisible ? 1.0 : 0.0,
            duration: Duration(milliseconds: 500),
            child: Text(
              description,
              style: GoogleFonts.openSans(
                textStyle: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
