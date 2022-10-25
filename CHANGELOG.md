# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### [0.0.27] - 2022-10-25
### Added
- `PlatformClient.getCallHistory`, `PlatformClient.getUsage` and
  `PlatformClient.pauseSecondaryUser`(#49).
- `PlatformClient.registerPushToken` (#50).

### Changed
- **BREAKING:** `PlatformClient.getSharedPhotos` now returns a `Paged<Photo>` instead of a
  `PhotosPage` (#49).
- **BREAKING:** `PlatformClient.saveFeedback` now accepts a single `SessionFeedback` instead of
  individual `Feedback` objects (#49).

### Removed
- **BREAKING:** `PhotosPage` (#49).

## [0.0.26] - 2022-09-27
### Added
- `PlatformClient.getSharedPhotos` and `PlatformClient.deleteSharedPhotos` (#48).

### Fixed
- Handle non-JSON responses from Platform (#47).

## [0.0.25] - 2022-09-14
### Fixed
- "null" pre-call message (#45).
- "null" last name (#46).

## [0.0.24] - 2022-09-13
### Added
- `PlatformClient.getUser` (#39).

### Changed
- Throttle `Room.updateLocation` (#44).

## [0.0.23] - 2022-09-09
### Added
- `RECONNECT` support (#41).

### Fixed
- Mute and un-mute stop working on Android (#42).

## [0.0.22] - 2022-09-08
### Changed
- Updated for Flutter 3.3.

## [0.0.21] - 2022-08-17
### Fixed
- HTTP 403 error for URLs returned by `MessagingClient.getFileUrl` (#37).

## [0.0.20] - 2022-08-16
### Added
- `Room.isAudioMuted`, `Room.isVideoMuted`, `Room.isPresentationMuted`, `Room.setPresentationMuted`,
  and `Room.setPrivacyMode` (#35).

### Changed
- **BREAKING:** The `Room` now manages its mute states separately from the `MediaStreamTrack`s (#35).
  Previously, to join a `Room` with the audio muted, you would do this before calling `Room.join`:

   ```dart
   _localMediaStream.getAudioTracks()[0].enabled = false;
   ```

   Now, you will do this:

   ```dart
   _room.setAudioMuted(true);
   ```

### Removed
- **BREAKING:** `Room.messageStream` and `Room.sendMessage` (#33).

## [0.0.19] - 2022-08-11
### Added
- Device context to `loginWithCredentials` (#31).

## [0.0.18] - 2022-08-10
### Fixed
- "Oops" error when calling from Android app (#29).

## [0.0.17] - 2022-08-09
### Changed
- Migrate from PubNub Access Manager v2 to
  [v3](https://www.pubnub.com/docs/resources/migration-guides/pam-v3-migration#differences-between-v2-and-v3) (#25).

### Fixed
- `createServiceRequest` fails when messaging is not supported (#27).

## [0.0.16] - 2022-08-08
### Changed
- A video track is no longer required when joining a room (#23).
- **BREAKING:** `Room.setVideoMuted(bool)` only affects the active video track
  (either the display or camera track). If the active video track is changed
  (e.g. using `Room.stopPresenting()` or `Room.replaceStream(MediaStream)`), the
  new track video will not automatically inherit the previous mute state (#23).

## [0.0.15] - 2022-08-02
### Added
- **BREAKING:** `RoomHandler.takePhoto` must now be implemented by clients (#22).
  In its simplest form, this can return a frame from the video track like this:

   ```dart
   @override
   Future<ByteBuffer> takePhoto() async {
     return _localStream!.getVideoTracks()[0].captureFrame();
   }
   ```

- Device ID and model to service request `context` (#20).

### Changed
- Use MQTT QoS level 1 for critical messages (#21).

## [0.0.14] - 2022-07-27
### Changed
- **BREAKING:** The `PlatformClientConfig` constructor now uses named parameters
  instead of positional parameters to make it easier to add configuration
  options in the future.
- Configurable device ID (#19).

## [0.0.13] - 2022-07-19
### Changed
- Support sending and receiving files (#13).

## [0.0.12] - 2022-07-15
### Changed
- Support sending location updates (#16).

## [0.0.11] - 2022-07-14
### Changed
- `flutter pub upgrade` and `pod update` (#17).

## [0.0.10] - 2022-07-14
### Changed
- Client verification codes (#14).

## [0.0.9] - 2022-06-09
### Added
- `PlatformClient.createAccount` and `PlatformClient.loginWithCredentials` (#12).

### Removed
- **BREAKING:** `PlatformClient.loginWithPhone` and `PlatformClient.loginWithEmail` (#12).

## [0.0.8] - 2022-06-02
### Fixed
- MediaStreamTrack has been disposed (#11).

## [0.0.7] - 2022-06-02
### Added
- `Room.replaceStream` (#10).

## [0.0.6] - 2022-05-17
### Changed
- Feedback version 2 (#8).

## [0.0.5] - 2022-05-06
### Added
- Low-res photo support (#7).

### Fixed
- Unawaited futures (#6).

## [0.0.4] - 2022-05-04
### Fixed
- Service request is not cancelled when disconnecting ungracefully (#5).

## [0.0.3] - 2022-04-29
### Changed
- MQTT keep alive and QoS (#4).

## [0.0.2] - 2022-04-26
### Added
- Messaging support (#3).

## [0.0.1] - 2022-03-28
### Added
- Initial release.
