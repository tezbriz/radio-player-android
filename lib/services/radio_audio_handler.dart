import 'package:flutter/foundation.dart';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import '../models/station.dart';

/// Wraps just_audio in audio_service's BaseAudioHandler so playback survives
/// backgrounding (as a proper Android foreground service) and shows up on the
/// lock screen / notification shade with working play-pause-stop controls —
/// the mobile equivalent of the desktop app's MPRIS integration, but native.
class RadioAudioHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer _player = AudioPlayer();
  Station? _currentStation;

  /// Live "now playing" ICY title, e.g. a song title — same idea as the
  /// desktop app's VLC-rc-based now-playing poll, but just_audio parses ICY
  /// metadata natively so no polling/socket work is needed here.
  final ValueNotifier<String?> nowPlayingTitle = ValueNotifier(null);

  RadioAudioHandler() {
    _player.playbackEventStream.listen(_broadcastState, onError: (Object e, StackTrace st) {
      playbackState.add(playbackState.value.copyWith(
        processingState: AudioProcessingState.error,
        playing: false,
      ));
    });

    _player.icyMetadataStream.listen((icy) {
      final title = icy?.info?.title?.trim();
      nowPlayingTitle.value = (title != null && title.isNotEmpty) ? title : null;
      if (_currentStation != null) {
        mediaItem.add(mediaItem.value?.copyWith(
          artist: nowPlayingTitle.value ?? 'Radio',
        ));
      }
    });
  }

  Station? get currentStation => _currentStation;
  Stream<double> get volumeStream => _player.volumeStream;
  double get volume => _player.volume;

  Future<void> playStation(Station station) async {
    _currentStation = station;
    nowPlayingTitle.value = null;

    mediaItem.add(MediaItem(
      id: station.urlResolved.isNotEmpty ? station.urlResolved : station.url,
      title: station.name,
      artist: 'Connecting…',
      artUri: station.favicon.isNotEmpty ? Uri.tryParse(station.favicon) : null,
    ));

    try {
      await _player.setUrl(station.urlResolved.isNotEmpty ? station.urlResolved : station.url);
      await _player.play();
    } catch (e) {
      playbackState.add(playbackState.value.copyWith(
        processingState: AudioProcessingState.error,
        playing: false,
      ));
    }
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() async {
    await _player.stop();
    _currentStation = null;
    nowPlayingTitle.value = null;
    return super.stop();
  }

  Future<void> setPlayerVolume(double volume) => _player.setVolume(volume);

  void _broadcastState(PlaybackEvent event) {
    final playing = _player.playing;
    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.stop,
        playing ? MediaControl.pause : MediaControl.play,
      ],
      systemActions: const {},
      androidCompactActionIndices: const [0, 1],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: playing,
    ));
  }
}
