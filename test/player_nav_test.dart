import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joy_tv/screens/player_screen.dart';
import 'package:joy_tv/models/iptv_channel.dart';

void main() {
  testWidgets('PlayerScreen navigation test', (WidgetTester tester) async {
    final channels = [
      IPTVChannel(name: 'Channel 1', url: 'http://example.com/1', number: 1),
      IPTVChannel(name: 'Channel 2', url: 'http://example.com/2', number: 2),
      IPTVChannel(name: 'Channel 3', url: 'http://example.com/3', number: 3),
    ];

    await tester.pumpWidget(MaterialApp(
      home: PlayerScreen(
        channels: channels,
        initialIndex: 0,
      ),
    ));

    // Verify initial state
    expect(find.text('CHANNEL 1'), findsOneWidget);
    expect(find.text('CH 001'), findsOneWidget);

    // Simulate Arrow Up (Next Channel)
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('CHANNEL 2'), findsOneWidget);
    expect(find.text('CH 002'), findsOneWidget);

    // Simulate Arrow Down (Previous Channel)
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('CHANNEL 1'), findsOneWidget);
    expect(find.text('CH 001'), findsOneWidget);
    
    // Simulate Arrow Down again (Wrap to and from start)
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('CHANNEL 3'), findsOneWidget);
    expect(find.text('CH 003'), findsOneWidget);
  });
}
