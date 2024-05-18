import 'package:evoltsoft_2/ProfileScreen/Profile_Screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'ChargingStationCard.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:stylish_bottom_bar/stylish_bottom_bar.dart';


class ChargingStationDetails extends StatefulWidget {
  const ChargingStationDetails({super.key});

  @override
  State<ChargingStationDetails> createState() => _ChargingStationDetailsState();
}

class _ChargingStationDetailsState extends State<ChargingStationDetails> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();
  String searchQuery = "";
  File? _profileImage;
  int _currentIndex = 0;

  Stream<QuerySnapshot> _fetchStationDetails() {
    return _firestore.collection('station').snapshots();
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    if (index == 4) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => UserProfileScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          SizedBox(height: 53),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by place name...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
                contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 20),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _fetchStationDetails(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error fetching data'));
                } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('No data available'));
                } else {
                  final filteredDocs = snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final placeName = (data['place_name'] as String?)?.toLowerCase() ?? '';
                    return placeName.contains(searchQuery);
                  }).toList();

                  return ListView(
                    padding: const EdgeInsets.all(8.0),
                    children: filteredDocs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return ChargingStationCard(data: data);
                    }).toList(),
                  );
                }
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: StylishBottomBar(
        option: BubbleBarOptions(
          iconSize: 30,
          bubbleFillStyle: BubbleFillStyle.fill,
          opacity: 0.3,
        ),
        items: [
          BottomBarItem(
            icon: Icon(Icons.explore),
            title: Text('Explore'),
            selectedColor: Colors.blue,
          ),
          BottomBarItem(
            icon: Icon(Icons.payment),
            title: Text('Payments'),
            selectedColor: Colors.blue,
          ),
          BottomBarItem(
            icon: Icon(Icons.qr_code_scanner),
            title: Text('Scan'),
            selectedColor: Colors.blue,
          ),
          BottomBarItem(
            icon: Icon(Icons.notifications),
            title: Text('Notifications'),
            selectedColor: Colors.blue,
          ),
          BottomBarItem(
            icon: Icon(Icons.person),
            title: Text('Profile'),
            selectedColor: Colors.blue,
          ),
        ],
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
