import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mock_http_overrides/mock_http_overrides.dart';
import 'package:test_screenshot/test_screenshot.dart';

void main() async {
  testWidgets('Should show placeholder images', (tester) async {
    HttpOverrides.global = MockHttpOverrides();
    await tester.loadFonts();
    await tester.runAsync(() async {
      await tester.pumpWidget(
        Screenshotter(
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Below is a network image'),
                    Icon(Icons.home),
                    Image.network(
                      'https://images.pexels.com/photos/1805164/pexels-photo-1805164.jpeg',
                      height: 300,
                      width: 300,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    });
    await tester.renderImages();
    await tester.screenshot();
  });
}
