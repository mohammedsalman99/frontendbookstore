import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfileScreen> with TickerProviderStateMixin {
  final Color primaryColor = Color(0xFF5AA5B1);
  final Color secondaryColor = Color(0xFF3D7A8A);
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryColor, secondaryColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person, size: 40, color: primaryColor),
                    ),
                    SizedBox(width: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "demo",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          "demoapp@gmail.com",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                    Spacer(),
                    Icon(
                      Icons.more_vert,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TabBar(
                  controller: _tabController,
                  labelColor: Colors.white,
                  unselectedLabelColor: primaryColor,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      colors: [primaryColor, secondaryColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  labelStyle: TextStyle(
                    fontSize: 10, 
                    fontWeight: FontWeight.bold,
                  ),
                  unselectedLabelStyle: TextStyle(
                    fontSize: 9,
                  ),
                  tabs: [
                    Tab(
                      icon: Icon(Icons.book),
                      text: 'Continue',
                    ),
                    Tab(
                      icon: Icon(Icons.subscriptions),
                      text: 'Subscription',
                    ),
                    Tab(
                      icon: Icon(Icons.money),
                      text: 'Rent',
                    ),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildContinueBookTab(),
                    _buildSubscriptionTab(),
                    _buildRentTab(),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContinueBookTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 10, 
        separatorBuilder: (context, index) => SizedBox(width: 10),
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
            },
            child: AnimatedContainer(
              duration: Duration(milliseconds: 300),
              width: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryColor.withOpacity(0.4), secondaryColor.withOpacity(0.4)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.book, color: primaryColor, size: 40),
                  SizedBox(height: 10),
                  Text(
                    "Book $index",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: primaryColor),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSubscriptionTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          Card(
            color: primaryColor.withOpacity(0.1),
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: ListTile(
              leading: Icon(Icons.subscriptions, color: primaryColor),
              title: Text("Subscription Plan A"),
              subtitle: Text("Valid until 31 Dec 2024"),
              trailing: Chip(
                label: Text("Active"),
                backgroundColor: primaryColor,
                labelStyle: TextStyle(color: Colors.white),
              ),
            ),
          ),
          Card(
            color: Colors.red.withOpacity(0.1),
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: ListTile(
              leading: Icon(Icons.subscriptions, color: Colors.red),
              title: Text("Subscription Plan B"),
              subtitle: Text("Expired"),
              trailing: Chip(
                label: Text("Expired"),
                backgroundColor: Colors.red,
                labelStyle: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRentTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: 6, 
        itemBuilder: (context, index) {
          return GestureDetector(
            onLongPress: () {
            },
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 3,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.book, size: 40, color: primaryColor),
                  SizedBox(height: 10),
                  Text(
                    "Rented Book $index",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: primaryColor),
                  ),
                  SizedBox(height: 5),
                  Text(
                    "Due: 01 Dec 2024",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
