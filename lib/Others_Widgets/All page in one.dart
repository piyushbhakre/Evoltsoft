import 'package:flutter/material.dart';

class AllInOnePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('All in One'),
      ),
      body: Center(
        child: Text(
          'This is the All in One page',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
