import 'package:evoltsoft_2/Others_Widgets/Show_Loading_Dialogue.dart';
import 'package:evoltsoft_2/Picture_camera/Take_PictureScreen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:file_picker/file_picker.dart';
import 'package:camera/camera.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:evoltsoft_2/Others_Widgets/Map_Screen.dart';

final locationProvider = StateProvider<LatLng?>((ref) => null);

class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen> {
  final TextEditingController placeNameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController timingController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController aboutController = TextEditingController();

  String chargingType = 'Type 1, 50W';
  File? _selectedImage;
  String? _uploadedImageUrl;

  final List<String> chargingTypes = [
    'Type 1, 50W',
    'Type 2, 100W',
  ];

  void _submitData() async {
    final placeName = placeNameController.text;
    final address = addressController.text;
    final timing = timingController.text;
    final amount = amountController.text;
    final about = aboutController.text;
    final location = ref.read(locationProvider);

    if (placeName.isEmpty ||
        address.isEmpty ||
        timing.isEmpty ||
        amount.isEmpty ||
        about.isEmpty ||
        location == null ||
        _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all fields, select a location, and upload an image')),
      );
      return;
    }

    DialogUtils.showLoadingDialog(context);  // Show loading dialog

    await _uploadImage();

    if (_uploadedImageUrl == null) {
      Navigator.of(context).pop(); // Close the loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading image. Please try again.')),
      );
      return;
    }

    final docRef = FirebaseFirestore.instance.collection('station').doc();

    await docRef.set({
      'place_name': placeName,
      'address': address,
      'timing': timing,
      'charging_type': chargingType,
      'amount': amount,
      'location': GeoPoint(location.latitude, location.longitude),
      'about': about,
      'image_url': _uploadedImageUrl,
    });

    Navigator.of(context).pop(); // Close the loading dialog

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Data submitted successfully')),
    );

    // Clear the form
    placeNameController.clear();
    addressController.clear();
    timingController.clear();
    amountController.clear();
    aboutController.clear();
    ref.read(locationProvider.notifier).state = null;
    setState(() {
      _selectedImage = null;
      _uploadedImageUrl = null;
    });
  }

  void _selectLocationOnMap(BuildContext context) async {
    final selectedLocation = await Navigator.of(context).push<LatLng>(
      MaterialPageRoute(builder: (ctx) => MapScreen()),
    );

    if (selectedLocation != null) {
      ref.read(locationProvider.notifier).state = selectedLocation;
    }
  }

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.image);
      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedImage = File(result.files.single.path!);
        });
      }
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<void> _takePhoto() async {
    try {
      final cameras = await availableCameras();
      final firstCamera = cameras.first;
      final result = await Navigator.of(context).push<PickedFile>(
        MaterialPageRoute(
          builder: (context) => TakePictureScreen(camera: firstCamera),
        ),
      );
      if (result != null) {
        setState(() {
          _selectedImage = File(result.path);
        });
      }
    } catch (e) {
      print('Error taking photo: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error taking photo: $e')),
      );
    }
  }

  Future<void> _uploadImage() async {
    if (_selectedImage == null) return;
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('station_images')
          .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

      final uploadTask = storageRef.putFile(_selectedImage!);

      final snapshot = await uploadTask.whenComplete(() {});
      final url = await snapshot.ref.getDownloadURL();
      setState(() {
        _uploadedImageUrl = url;
      });
    } catch (e) {
      print('Error uploading image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading image: $e')),
      );
    }
  }

  void _showImageSourceActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.photo_library),
              title: Text('Gallery'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage();
              },
            ),
            ListTile(
              leading: Icon(Icons.camera_alt),
              title: Text('Camera'),
              onTap: () {
                Navigator.of(context).pop();
                _takePhoto();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedLocation = ref.watch(locationProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Screen'),
        backgroundColor: Colors.lightBlue,
        centerTitle: true,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.lightBlueAccent, Colors.blueAccent],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              SizedBox(height: 20),
              Text(
                'Add Charging Station',
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),
              TextField(
                controller: placeNameController,
                decoration: InputDecoration(
                  labelText: 'Place Name',
                  prefixIcon: Icon(Icons.place),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
              ),
              SizedBox(height: 10),
              TextField(
                controller: addressController,
                decoration: InputDecoration(
                  labelText: 'Address',
                  prefixIcon: Icon(Icons.location_on),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
              ),
              SizedBox(height: 10),
              TextField(
                controller: timingController,
                decoration: InputDecoration(
                  labelText: 'Timing (hours open)',
                  prefixIcon: Icon(Icons.access_time),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
              ),
              SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: chargingType,
                onChanged: (value) {
                  setState(() {
                    chargingType = value!;
                  });
                },
                items: chargingTypes.map((type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                decoration: InputDecoration(
                  labelText: 'Charging Type',
                  prefixIcon: Icon(Icons.electrical_services),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
              ),
              SizedBox(height: 10),
              TextField(
                controller: amountController,
                decoration: InputDecoration(
                  labelText: 'Amount',
                  hintText: 'Amount per hour (in rupees)',
                  prefixIcon: Icon(Icons.attach_money),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 10),
              TextField(
                controller: aboutController,
                decoration: InputDecoration(
                  labelText: 'About',
                  prefixIcon: Icon(Icons.info),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                maxLines: 3,
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _selectLocationOnMap(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.yellowAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  minimumSize: Size(double.infinity, 50), // Match parent width
                ),
                child: Text(selectedLocation == null
                    ? 'Select Location on Map'
                    : 'Location Selected: (${selectedLocation.latitude}, ${selectedLocation.longitude})'),
              ),
              SizedBox(height: 16),
              _selectedImage != null
                  ? Image.file(
                _selectedImage!,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
              )
                  : SizedBox.shrink(),
              ElevatedButton(
                onPressed: () => _showImageSourceActionSheet(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orangeAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  minimumSize: Size(double.infinity, 50), // Match parent width
                ),
                child: Text(_selectedImage == null ? 'Upload Image' : 'Change Image'),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _submitData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.greenAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  minimumSize: Size(double.infinity, 50), // Match parent width
                ),
                child: Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
