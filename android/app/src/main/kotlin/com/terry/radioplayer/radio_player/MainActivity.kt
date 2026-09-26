package com.terry.radioplayer.radio_player

import com.ryanheise.audioservice.AudioServiceActivity

// audio_service requires the main activity to extend AudioServiceActivity (which itself
// extends FlutterFragmentActivity) instead of the plain FlutterActivity that `flutter
// create` scaffolds by default — otherwise it can't correctly bind its background service
// to this activity's FlutterEngine (confirmed via a runtime PlatformException, not just
// docs: "Please see the README for instructions").
class MainActivity : AudioServiceActivity()
