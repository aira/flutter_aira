# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.9.1] - 2024-06-24

- Fixes the bug 'Unable to RTCPeerConnection::addCandidate: Error The remote description was null'

## [2.9.0] - 2024-06-20
### Added
- Added new user property `buildAiProgramJoined` to check if a user has joined the BuildAI program. (#126)
- `BuildAI` added to the CallHistory model (#126)
- `updateSessionShareStatus` to update new BuildAi user property (#126)
- `getCallHistorySingleCall` to get call history response for the single session (#126)


## [2.8.0] - 2024-06-19

### Added
- Added new property `aiVerbosity` to `User`
- Added new property `aiLanguageLevel` to `User`
- Added new function `updateAiLanguageLevel` to `PlatformClient`
- Added new function `updateAiVerbosity` to `PlatformClient`


## [2.7.0] - 2024-06-13

### Added
- Added new property `firebaseCustomToken` to `Session`
- Added new function `confirmEmailUpdate` to `PlatformClient`


## [2.6.0] - 2024-05-27

### Added
- Added `TrackKind` to `ParticipantMessage`

### Changed
- Updated [SFUConnection] to add video configs to sdp offer based on track kind


## [2.5.0] - 2024-05-27

### Added
- Added const `PlatformClient.kEmailVerification`
- Added const `PlatformClient.kPhoneVerification`

## [2.4.1] - 2024-05-22

### Changed
Updated the following plugins which is required to use with flutter v3.22.1 (#122)
- connectivity_plus: ^6.0.3 and updated its breaking changes.
- device_info_plus: ^10.1.0
- flutter_webrtc: ^0.10.6
- meta: ^1.12.0
- package_info_plus: ^8.0.0
 
## [2.3.0] - 2024-04-11

### Changed
- Updated the enum class [AgentFeedbackState] to include the new state [AgentFeedbackState.assigned] (#120)
- **BREAKING:** replaced [AgentFeedbackState.inProgress] with [AgentFeedbackState.started] (#120)

## [2.2.0] - 2024-03-08

### Changed
- ### Added Handling Case "LEFT" on `_updateServiceRequestStatus` on transfer calls this, without this version if a transfer occurs in the call it will terminate the call for the explorer (bug) (#119)

## [2.1.2] - 2024-03-06
### Changed
- Updated mqtt's websocket protocol to align with newer version of RabbitMQ. This change is backward compatible. (#118)

## [2.1.1] - 2024-03-01
### Changed
- **BREAKING:** Renamed `authorFullName` to `authorFirstName` (#116)

## [2.1.0] - 2024-02-28
### Added
- `requestAgentValidation` to request agent validation (#114)
- `getChatMessage` to get chat a specific message info (#114)
- Dependency to `collection` has been added (#114) 

### Changed
- **BREAKING:** Replaced `ChatMessageInfo.template` with a new constructor that have all available fields (#114)
- **BREAKING:** Renamed `ChatFeedbackInfo` to `UserFeedbackInfo` (#114)
- **BREAKING:** Removed duplicate `ChatFeedbackInfo` (#114)

## [2.0.2] - 2024-02-22
### Added
- Downgraded Flutter from 3.19.1 to 3.16.9 and `meta` plugin to 1.10.0 (#113)

## [2.0.1] - 2024-02-21
### Added
- Updated `ChatFeedbackInfo` according to changes of the model on the platform.(#112)

## [2.0.0] - 2024-02-17
### Changed
Since Aira now supports call transfers, the `RoomHandler` needs to be able to handle multiple remote streams.
- **BREAKING:** `RoomHandler.addRemoteStream` now requires two parameters (#110)
- **BREAKING:** `RoomHandler` has a new function to implement: `removeRemoteStream` (#110)

## [1.13.2] - 2024-02-16
### Added
- `ChatMessageInfo.template` constructor was added (#109)
- `ChatSessionInfo.template` constructor was added (#109)

## [1.13.1] - 2024-02-15
### Changed
- updated plugin versions for security and compatibility purposes (#108)

## [1.13.0] - 2024-02-13
### Added
- `PlatformClient.getChatSession` to get chat session Info  (#107)

## [1.12.2] - 2024-02-02
### Changed
- Added a safety to give a second chance to transmit video in case the video track wasn't fully initialized at room join time. (#106)
- Added a safety to make sure the participant status is updated properly if we join the room after the Service Request status is set to "started" (#106)
- Added logging to help diagnose issues related to calls started without videos (#106)

## [1.12.1] - 2024-01-29
### Changed
- Updated plugin and pod dependencies for security and compatibility purposes (#104)

## [1.12.0] - 2024-01-10
### Added
- `ChatMessageInfo.ChatFeedbackInfo` to include Explorer feedback (#103)
- `Message.messageId` (#103)
- `PlatformClient.sendChatMessageFeedback` to send user feedback to the AI response (#103)

## [1.11.0] - 2024-01-03
### Added
- `User.aiDailyMessageLimit` to determine how many AI image description requests an Explorer can make per day (#102)

## [1.10.1] - 2023-12-28
### Changed
- Updated plugin and pod dependencies for security and compatibility purposes (#101)

## [1.10.0] - 2023-12-19
### Added
- Aira AI chat APIs (#99).

### Changed
- **BREAKING:** A "start" message -- used by the Agent Dashboard to group messages into "sessions"
  -- is no longer automatically published to the messaging channel every time a service request is
  created. The app can now control when a messaging session starts by publishing a "start" message
  with the new `MessagingClient.sendRawMessage` API.

## [1.9.0] - 2023-12-04
### New
- `User.referralLink` to retrieve the link Explorer which allow Explorer to get reward when friends join the Aira family (#98)
- `PlatformClient.getPropertyValue` to retrieve properties from `UserPropertyName` (#98)

## [1.8.1] - 2023-11-06
### Changed
- Increased the throttling duration to 2 seconds for location updates (#97)

## [1.8.0] - 2023-10-16
### New
- `PlatformDeleteAccountException` is now a possible exception thrown by `platformClient.deleteAccount` to indicate the user deleting his account has a plan subscription which should be resolved before deleting his account. (#96)

## [1.7.0] - 2023-09-27
### New
- `PlatformClient.updateTermsOfServiceAccepted(bool)` to update the Terms of Service status (#91)
- `Room.onConnectionFailed` to update the Room user on any SFU connection failure (#92)
- `PlatformClient.deleteAccount` to enable the Explorers to delete their account (#94)
- `PlatformBusinessLoginRequiredException` to handle cases where an operation requires the user to login with business credentials (#95)

## [1.6.0] - 2023-08-18
### New
- `PlatformClient.getPartialBillingInformation()` to retrieve currently used billing information (partial information) (#89)

## [1.5.2] - 2023-08-17
### Changed
- Updated plugin versions for security and compatibility purposes (#88)

## [1.5.1] - 2023-07-27
### Fixed
- `Room.startPresenting` and `Room.stopPresenting` are now re-creating the outgoing track for mobile to avoid the video pixelation issue (#87)

## [1.5.0] - 2023-07-20
### Changed
- **BREAKING:** `Rating` enum now has a "Excellent" element (#86)

## [1.4.2] - 2023-07-17
### Fixed
- Unified Location Update Throttling to prevent concurrent location update through different routes (#85)

### Changed
- Updated analysis rules (#84)

## [1.4.1] - 2023-07-03
### Fixed
- Reconnection now reestablishes presentation if a presentation was ongoing (#83)

## [1.4.0] - 2023-06-15
### New
- added `Position.toJson` and `Position.fromJson` (#82)
- added `Position.speedFrom` to be able to calculate speed between two coordinates using timestamps (#82)

## [1.3.3] - 2023-06-08
### Fixed
- added Access Offer Type filtering to the call event channel. (#81)

## [1.3.2] - 2023-06-08
### Fixed
- `PlatformClient.inquireForGPSActivatedOffer` is now throttling requests properly. (#80)

## [1.3.1] - 2023-05-19
### Fixed
- The `Room.onAccessOfferChange`'s `onRemainingTime` argument is now set as unlimited (null) when duration_per_call is either null or -1. (#79)

## [1.3.0] - 2023-05-17
### Added
- added `AccessOfferDetails.toJson` to help serialize this information across processes. (#78)

## [1.2.1] - 2023-05-10
### Changed
- Update to flutter 3.10 (#77)

## [1.2.0] - 2023-04-04
### Added
- `RoomHandler.onAccessOfferChange` is now available to get notified of activated Site Offers (#75).
- `PlatformClient.inquireForGPSActivatedOffer` is now available to inquire for available Site Offers when outside of a call (#75).
- `Position` can be now compared using the '==' operator to know if both positions have same longitude, latitude, heading and timestamp (#75).
- `Position.toString` will now show longitude, latitude, heading and timestamp (#75).
- `Position.timeSinceInMs` is now an available convenience to know the amount of time elapsed since `Position.timestamp` and now (#75).
- `Position.distanceFrom` is now an available convenience to know the between two Positions (#75).

## [1.1.1] - 2023-03-31
### Added
- automatic PubNub reconnection when data connection fails or changes (#74).

## [1.1.0] - 2023-03-24
### Added
- automatic WebRTC reconnection when data connection fails or changes (#73).

## [1.0.2] - 2023-03-07
### Fixed
- Camera Switch prevention while in connection queue (#72).

## [1.0.1] - 2023-02-25
### Fixed
- `Accept-Language` header not set on mobile (#71).

## [1.0.0] - 2023-02-14
### Changed
- Debounce reconnects (#68).
- Handle `INCOMING_TRACK_REMOVE` messages (#69).

### Fixed
- Missed service request status messages (#70).

### [0.0.38] - 2023-02-08
### Added
- Added functions to setup ride shares with Lyft: `getLyftAuthorizationUrl`, `sendLyftAuthorizationCode` and `revokeLyftAuthorization` (#67)
- Added `User.linkedAccounts` to provide linked account information (#67)

### Changed
- **BREAKING:** `User.language` is now an immutable list like all other lists (#67)

### [0.0.37] - 2023-01-30
### Fixed
- **BREAKING:** `getAccessOfferSites` doesn't accept null longitude or latitude anymore (#65)

### [0.0.36] - 2023-01-26
### Added
- Added API for MinuteSharing (#64)

### [0.0.35] - 2023-01-24
### Fixed
- Downgrade `intl` from `0.18.0` to `0.17.0`, as the former is incompatible with
  `flutter_localizations`.

### [0.0.34] - 2023-01-24
### Changed
- Bump dependencies.

### [0.0.33] - 2023-01-19
### Removed
- **BREAKING:** `MessagingClient.sendStart` (#61).

### Fixed
- No `start` message sent when call is not started with a message or file (#61).

### [0.0.32] - 2022-12-19
### Added
- Added API for Access Offers (#58)

### [0.0.31] - 2022-11-29
### Added
- Agent remote flashlight handling through: `RoomHandler.toggleFlashlight` (#56)

### [0.0.30] - 2022-11-17
### Added
- `User.languages` and `User.cloneWith` (#54)
- `PlatformClient.updateName`, `PlatformClient.updatePreferredLanguages`,
  `PlatformClient.verifyEmailUpdate`, `PlatformClient.verifyPhoneNumberUpdate` and
  `PlatformClient.confirmPhoneNumberUpdate` (#54).

### [0.0.28] - 2022-11-01
### Added
- `User.email` and `User.phoneNumber` (#52).

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
