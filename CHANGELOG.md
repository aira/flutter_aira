# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
