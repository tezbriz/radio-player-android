/// A radio station, as returned by the radio-browser.info API.
/// Mirrors the fields the desktop app keeps in its favourites JSON, so a
/// favourites export from the desktop app could, in principle, be dropped in.
class Station {
  final String stationUuid;
  final String name;
  final String url;
  final String urlResolved;
  final String favicon;
  final String tags;
  final String country;
  final int bitrate;
  final int votes;

  Station({
    required this.stationUuid,
    required this.name,
    required this.url,
    required this.urlResolved,
    required this.favicon,
    required this.tags,
    required this.country,
    required this.bitrate,
    required this.votes,
  });

  factory Station.fromJson(Map<String, dynamic> json) {
    return Station(
      stationUuid: json['stationuuid'] as String? ?? '',
      name: (json['name'] as String? ?? 'Unknown').trim(),
      url: json['url'] as String? ?? '',
      urlResolved: (json['url_resolved'] as String?)?.trim().isNotEmpty == true
          ? json['url_resolved'] as String
          : (json['url'] as String? ?? ''),
      favicon: json['favicon'] as String? ?? '',
      tags: json['tags'] as String? ?? '',
      country: json['country'] as String? ?? '',
      bitrate: (json['bitrate'] as num?)?.toInt() ?? 0,
      votes: (json['votes'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'stationuuid': stationUuid,
        'name': name,
        'url': url,
        'url_resolved': urlResolved,
        'favicon': favicon,
        'tags': tags,
        'country': country,
        'bitrate': bitrate,
        'votes': votes,
      };

  /// A short "128k · pop" style description line, same idea as the desktop app's row-desc.
  String get description {
    final parts = <String>[];
    if (bitrate > 0) parts.add('${bitrate}k');
    final firstTag = tags.split(',').map((t) => t.trim()).firstWhere(
          (t) => t.isNotEmpty,
          orElse: () => '',
        );
    if (firstTag.isNotEmpty) {
      parts.add(firstTag);
    } else if (country.isNotEmpty) {
      parts.add(country);
    }
    return parts.join(' · ');
  }
}
