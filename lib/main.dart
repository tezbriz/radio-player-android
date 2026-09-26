import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'services/radio_audio_handler.dart';
import 'screens/home_screen.dart';
import 'theme.dart';

late RadioAudioHandler audioHandler;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  audioHandler = await AudioService.init(
    builder: () => RadioAudioHandler(),
    config: AudioServiceConfig(
      androidNotificationChannelId: 'com.terry.radioplayer.channel.audio',
      androidNotificationChannelName: 'Radio playback',
      // These two must agree per audio_service's own assertion: ongoing=true requires
      // stopForegroundOnPause=true. We want pausing to keep the foreground service alive
      // (instant resume, no re-buffering), so the notification has to stay swipeable.
      androidNotificationOngoing: false,
      androidStopForegroundOnPause: false,
    ),
  );

  runApp(const RadioApp());
}

class RadioApp extends StatelessWidget {
  const RadioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Radio',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: HomeScreen(audioHandler: audioHandler),
    );
  }
}
