import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import '../models/station.dart';
import '../services/radio_api.dart';
import '../services/favorites_store.dart';
import '../services/radio_audio_handler.dart';
import '../theme.dart';

class HomeScreen extends StatefulWidget {
  final RadioAudioHandler audioHandler;
  const HomeScreen({super.key, required this.audioHandler});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _api = RadioApi();
  final _favStore = FavoritesStore();
  final _searchController = TextEditingController();

  List<Station> _stations = [];
  List<Station> _favorites = [];
  bool _loading = true;
  bool _viewingFavs = false;
  bool _sortAlpha = false;
  String? _error;
  String _sectionLabel = 'TOP UK STATIONS';
  String _activeChip = 'UK';
  Timer? _searchDebounce;
  double _volume = 0.8;
  bool _muted = false;
  double _preMuteVolume = 0.8;

  Timer? _sleepTicker;
  int _sleepMinutesRemaining = 0;

  static const _countryChips = {
    'UK': 'United Kingdom',
    'Ireland': 'Ireland',
    'USA': 'United States Of America',
    'World': '',
  };

  @override
  void initState() {
    super.initState();
    _restoreState();
    _loadStations(country: _countryChips['UK']);
    widget.audioHandler.volumeStream.listen((v) {
      if (mounted) setState(() => _volume = v);
    });
  }

  Future<void> _restoreState() async {
    final vol = await _favStore.loadLastVolume();
    _volume = vol;
    await widget.audioHandler.setPlayerVolume(vol);
    final last = await _favStore.loadLastStation();
    if (last != null && mounted) {
      setState(() {}); // media item may already be set by handler restoration in future
    }
    _favorites = await _favStore.loadFavorites();
    if (mounted) setState(() {});
  }

  Future<void> _loadStations({String? country, String? query}) async {
    setState(() {
      _loading = true;
      _error = null;
      _viewingFavs = false;
    });
    try {
      final stations = await _api.search(country: country, query: query);
      setState(() {
        _stations = stations;
        _loading = false;
        _sectionLabel = query != null && query.isNotEmpty
            ? 'RESULTS FOR "${query.toUpperCase()}"'
            : (country != null && country.isNotEmpty)
                ? 'TOP ${country.toUpperCase()} STATIONS'
                : 'TOP WORLDWIDE STATIONS';
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = '$e';
      });
    }
  }

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (query.trim().isEmpty) {
        _loadStations(country: _countryChips[_activeChip]);
      } else {
        _loadStations(country: _countryChips[_activeChip], query: query.trim());
      }
    });
  }

  void _onChipTap(String label) {
    setState(() => _activeChip = label);
    if (label == 'Favs') {
      setState(() {
        _viewingFavs = true;
        _stations = _favorites;
        _sectionLabel = 'FAVOURITES';
        _searchController.clear();
      });
    } else {
      _loadStations(country: _countryChips[label], query: _searchController.text.trim());
    }
  }

  Future<void> _playStation(Station station) async {
    await widget.audioHandler.playStation(station);
    await widget.audioHandler.setPlayerVolume(_volume);
    await _favStore.saveLastState(station: station, volume: _volume);
    setState(() {});
  }

  Future<void> _toggleFavorite(Station station) async {
    _favorites = await _favStore.toggleFavorite(station);
    if (_viewingFavs) {
      setState(() => _stations = _favorites);
    } else {
      setState(() {});
    }
  }

  bool _isFavorite(Station s) => _favorites.any((f) => f.stationUuid == s.stationUuid);

  void _onVolumeChanged(double v) {
    setState(() {
      _volume = v;
      _muted = v == 0;
    });
    widget.audioHandler.setPlayerVolume(v);
    _favStore.saveLastState(station: widget.audioHandler.currentStation, volume: v);
  }

  void _toggleMute() {
    if (_muted) {
      _onVolumeChanged(_preMuteVolume > 0 ? _preMuteVolume : 0.8);
    } else {
      _preMuteVolume = _volume;
      _onVolumeChanged(0);
    }
  }

  List<Station> get _displayStations {
    if (!_sortAlpha) return _stations;
    final copy = List<Station>.from(_stations);
    copy.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return copy;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildNowPlaying(),
            _buildControls(),
            _buildSearch(),
            _buildChips(),
            _buildSectionBar(),
            Expanded(child: _buildList()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: const BoxDecoration(
        color: AppColors.panel,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          const Text('Radio',
              style: TextStyle(
                  color: AppColors.gold, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(3)),
            child: const Text('NO ADS', style: TextStyle(color: AppColors.textMuted, fontSize: 9, letterSpacing: 2)),
          ),
          const Spacer(),
          _buildSleepTimerButton(),
        ],
      ),
    );
  }

  Widget _buildSleepTimerButton() {
    final active = _sleepMinutesRemaining > 0;
    return PopupMenuButton<int>(
      onSelected: _onSleepTimerSelected,
      color: AppColors.panel,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: const BorderSide(color: AppColors.border),
      ),
      itemBuilder: (context) => const [
        PopupMenuItem(value: 15, child: Text('15 min', style: TextStyle(color: AppColors.text))),
        PopupMenuItem(value: 30, child: Text('30 min', style: TextStyle(color: AppColors.text))),
        PopupMenuItem(value: 45, child: Text('45 min', style: TextStyle(color: AppColors.text))),
        PopupMenuItem(value: 60, child: Text('60 min', style: TextStyle(color: AppColors.text))),
        PopupMenuItem(value: 0, child: Text('Off', style: TextStyle(color: AppColors.textMuted))),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          border: Border.all(color: active ? AppColors.gold : AppColors.border),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bedtime_outlined, size: 12, color: active ? AppColors.gold : AppColors.textMuted),
            if (active) ...[
              const SizedBox(width: 4),
              Text('${_sleepMinutesRemaining}m',
                  style: const TextStyle(fontSize: 11, color: AppColors.gold)),
            ],
          ],
        ),
      ),
    );
  }

  void _onSleepTimerSelected(int minutes) {
    _sleepTicker?.cancel();
    if (minutes <= 0) {
      setState(() => _sleepMinutesRemaining = 0);
      return;
    }
    setState(() => _sleepMinutesRemaining = minutes);
    _sleepTicker = Timer.periodic(const Duration(minutes: 1), (_) {
      setState(() => _sleepMinutesRemaining--);
      if (_sleepMinutesRemaining <= 0) {
        _sleepTicker?.cancel();
        widget.audioHandler.pause();
      }
    });
  }

  Widget _buildNowPlaying() {
    return StreamBuilder<MediaItem?>(
      stream: widget.audioHandler.mediaItem,
      builder: (context, snapshot) {
        final item = snapshot.data;
        return ValueListenableBuilder<String?>(
          valueListenable: widget.audioHandler.nowPlayingTitle,
          builder: (context, title, _) {
            return StreamBuilder<PlaybackState>(
              stream: widget.audioHandler.playbackState,
              builder: (context, stateSnap) {
                final playing = stateSnap.data?.playing ?? false;
                final processing = stateSnap.data?.processingState ?? AudioProcessingState.idle;
                String status;
                Color statusColor = AppColors.textMuted;
                if (item == null) {
                  status = '—';
                } else if (processing == AudioProcessingState.error) {
                  status = 'Stream unavailable — try another';
                  statusColor = AppColors.error;
                } else if (processing == AudioProcessingState.loading ||
                    processing == AudioProcessingState.buffering) {
                  status = 'Connecting…';
                } else if (playing) {
                  status = title != null ? '● Live · $title' : '● Live';
                  statusColor = AppColors.live;
                } else {
                  status = 'Paused';
                }
                return Container(
                  margin: const EdgeInsets.fromLTRB(14, 10, 14, 6),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.panel,
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item?.title ?? 'No station selected',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: playing ? AppColors.goldLight : AppColors.text,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(status,
                          style: TextStyle(fontSize: 10, letterSpacing: 1, color: statusColor),
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
      child: Row(
        children: [
          StreamBuilder<PlaybackState>(
            stream: widget.audioHandler.playbackState,
            builder: (context, snapshot) {
              final playing = snapshot.data?.playing ?? false;
              final hasStation = widget.audioHandler.currentStation != null;
              return IconButton(
                iconSize: 42,
                icon: Icon(playing ? Icons.pause_circle_outline : Icons.play_circle_outline,
                    color: AppColors.gold),
                onPressed: hasStation
                    ? () {
                        if (playing) {
                          widget.audioHandler.pause();
                        } else {
                          widget.audioHandler.play();
                        }
                      }
                    : null,
              );
            },
          ),
          const SizedBox(width: 6),
          IconButton(
            icon: Icon(_muted ? Icons.volume_off : Icons.volume_up,
                color: _muted ? AppColors.gold : AppColors.textMuted, size: 20),
            onPressed: _toggleMute,
          ),
          Expanded(
            child: Slider(
              value: _volume.clamp(0.0, 1.0),
              onChanged: _onVolumeChanged,
            ),
          ),
          SizedBox(
            width: 36,
            child: Text('${(_volume * 100).round()}%',
                style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
          ),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 4),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        style: const TextStyle(color: AppColors.text, fontSize: 13),
        decoration: InputDecoration(
          hintText: 'Search stations…',
          hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
          prefixIcon: const Icon(Icons.search, color: AppColors.textMuted, size: 18),
          filled: true,
          fillColor: AppColors.panel,
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: AppColors.gold),
          ),
        ),
      ),
    );
  }

  Widget _buildChips() {
    final chips = ['Favs', ...(_countryChips.keys)];
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
      child: Wrap(
        spacing: 6,
        children: chips.map((label) {
          final active = _activeChip == label;
          return GestureDetector(
            onTap: () => _onChipTap(label),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: active ? AppColors.gold.withValues(alpha: 0.1) : AppColors.panel,
                border: Border.all(color: active ? AppColors.gold : AppColors.border),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                label == 'Favs' ? '★ Favs' : label,
                style: TextStyle(
                    fontSize: 10, letterSpacing: 1, color: active ? AppColors.gold : AppColors.textMuted),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSectionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      color: const Color(0xFF161614),
      child: Row(
        children: [
          Expanded(
            child: Text(_sectionLabel,
                style: const TextStyle(fontSize: 9, letterSpacing: 2, color: AppColors.textMuted)),
          ),
          GestureDetector(
            onTap: () => setState(() => _sortAlpha = !_sortAlpha),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: _sortAlpha ? AppColors.gold.withValues(alpha: 0.1) : Colors.transparent,
                border: Border.all(color: _sortAlpha ? AppColors.gold : AppColors.border),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text('A-Z',
                  style: TextStyle(
                      fontSize: 9, color: _sortAlpha ? AppColors.gold : AppColors.textMuted)),
            ),
          ),
          Text('${_stations.length}${_stations.length == 60 ? '+' : ''}',
              style: const TextStyle(fontSize: 9, color: AppColors.textMuted)),
        ],
      ),
    );
  }

  Widget _buildList() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.gold));
    }
    if (_error != null) {
      return Center(
        child: Text('Error: $_error', style: const TextStyle(color: AppColors.textMuted)),
      );
    }
    final list = _displayStations;
    if (list.isEmpty) {
      return Center(
        child: Text(
          _viewingFavs ? 'No favourites yet — star a station' : 'No stations found',
          style: const TextStyle(color: AppColors.textMuted),
        ),
      );
    }
    return StreamBuilder<MediaItem?>(
      stream: widget.audioHandler.mediaItem,
      builder: (context, snapshot) {
        final currentId = snapshot.data?.id;
        return ListView.separated(
          itemCount: list.length,
          separatorBuilder: (_, _) => const Divider(height: 1, color: Color(0xFF1C1C1A)),
          itemBuilder: (context, index) {
            final s = list[index];
            final active = currentId != null &&
                (currentId == s.urlResolved || currentId == s.url);
            final fav = _isFavorite(s);
            return Container(
              decoration: BoxDecoration(
                color: active ? AppColors.gold.withValues(alpha: 0.08) : AppColors.background,
                border: active
                    ? const Border(left: BorderSide(color: AppColors.gold, width: 2))
                    : null,
              ),
              child: ListTile(
                onTap: () => _playStation(s),
                title: Text(s.name,
                    style: TextStyle(
                        fontSize: 13, color: active ? AppColors.goldLight : AppColors.text),
                    overflow: TextOverflow.ellipsis),
                subtitle: Text(s.description,
                    style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                trailing: IconButton(
                  icon: Icon(fav ? Icons.star : Icons.star_border,
                      color: fav ? AppColors.gold : AppColors.textMuted, size: 20),
                  onPressed: () => _toggleFavorite(s),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _sleepTicker?.cancel();
    _searchController.dispose();
    super.dispose();
  }
}
