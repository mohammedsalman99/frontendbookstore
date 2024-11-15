import 'package:flutter/material.dart';
import 'package:frontend/home.dart';
import 'package:google_fonts/google_fonts.dart';

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
    },
    {
      "title": "Improves the Ability to Focus",
      "description": "Reading is one of the few activities that requires your undivided attention.",
    },
    {
      "title": "All we need is books",
      "description": "Reading a variety of topics can make you a more knowledgeable person.",
    },
  ];

  void _nextPage() {
    if (_currentPage < onboardingData.length - 1) {
      _pageController.nextPage(duration: Duration(milliseconds: 300), curve: Curves.ease);
    } else {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => HomeScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                pageIndex: index,
                currentPage: _currentPage,
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
          SizedBox(height: 20),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 40.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    if (_currentPage < onboardingData.length - 1) {
                      _pageController.jumpToPage(onboardingData.length - 1);
                    } else {
                      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => HomeScreen()));
                    }
                  },
                  child: Text(
                    _currentPage == onboardingData.length - 1 ? "" : "Skip",
                    style: TextStyle(color: Colors.green),
                  ),
                ),
                ElevatedButton(
                  onPressed: _nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
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
          SizedBox(height: 20),
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
        color: _currentPage == index ? Colors.green : Colors.grey,
        borderRadius: BorderRadius.circular(5),
      ),
    );
  }
}

// OnboardingPage widget definition with Google Fonts
class OnboardingPage extends StatelessWidget {
  final String title;
  final String description;
  final int pageIndex;
  final int currentPage;

  const OnboardingPage({
    Key? key,
    required this.title,
    required this.description,
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
            width: isVisible ? 200 : 100,
            height: isVisible ? 200 : 100,
            decoration: BoxDecoration(
              color: isVisible ? Colors.greenAccent : Colors.grey,
              borderRadius: BorderRadius.circular(isVisible ? 100 : 10),
            ),
          ),
          SizedBox(height: 30),
          AnimatedOpacity(
            opacity: isVisible ? 1.0 : 0.0,
            duration: Duration(milliseconds: 500),
            child: Text(
              title,
              style: GoogleFonts.lato( // Updated font style for the title
                textStyle: TextStyle(
                  fontSize: 24,
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
              style: GoogleFonts.openSans( // Updated font style for the description
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
