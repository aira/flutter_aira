import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_aira/flutter_aira.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:logging/logging.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Auto-enable accessibility for our Blind and Low Vision customers (see
  // https://docs.flutter.dev/development/accessibility-and-localization/accessibility#screen-readers).
  RendererBinding.instance!.setSemanticsEnabled(true);

  // Configure logging.
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((record) {
    print('${record.time} | ${record.level.name} | ${record.loggerName} | ${record.message}'); // ignore: avoid_print
    if (record.error != null) {
      print(record.error); // ignore: avoid_print
    }
  });

  runApp(const MaterialApp(
    title: 'Aira Demo',
    home: MyApp(),
  ));
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> implements RoomHandler {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _clientIdController = TextEditingController();
  final TextEditingController _tokenController = TextEditingController();
  final TextEditingController _userIdController = TextEditingController();

  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  late final Future<void> _rendererInitialized;

  MediaStream? _localStream;
  PlatformClient? _platformClient;
  Room? _room;

  bool get _isInCall => _room != null;

  @override
  void initState() {
    super.initState();

    _rendererInitialized = _remoteRenderer.initialize();
  }

  @override
  void dispose() {
    _remoteRenderer.dispose();

    _apiKeyController.dispose();
    _clientIdController.dispose();
    _tokenController.dispose();
    _userIdController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aira Demo'),
      ),
      body: LayoutBuilder(builder: (BuildContext context, BoxConstraints viewportConstraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: viewportConstraints.maxHeight,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    child: TextFormField(
                      controller: _clientIdController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        // Announce validation errors (https://github.com/flutter/flutter/issues/99715).
                        helperText: ' ',
                        labelText: 'Client ID',
                      ),
                      enabled: !_isInCall,
                      validator: (String? value) {
                        if (value == null || value.isEmpty) {
                          return 'A client ID is required';
                        }
                        return null;
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    child: TextFormField(
                      controller: _apiKeyController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        // Announce validation errors (https://github.com/flutter/flutter/issues/99715).
                        helperText: ' ',
                        labelText: 'API Key',
                      ),
                      enabled: !_isInCall,
                      validator: (String? value) {
                        if (value == null || value.isEmpty) {
                          return 'An API key is required';
                        }
                        return null;
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    child: TextFormField(
                        controller: _userIdController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          // Announce validation errors (https://github.com/flutter/flutter/issues/99715).
                          helperText: ' ',
                          labelText: 'User ID',
                        ),
                        enabled: !_isInCall,
                        validator: (String? value) {
                          if (value == null || value.isEmpty) {
                            return 'A user ID is required';
                          }
                          return null;
                        }),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    child: TextFormField(
                      controller: _tokenController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        // Announce validation errors (https://github.com/flutter/flutter/issues/99715).
                        helperText: ' ',
                        labelText: 'Token',
                      ),
                      enabled: !_isInCall,
                      validator: (String? value) {
                        if (value == null || value.isEmpty) {
                          return 'A token is required';
                        }
                        return null;
                      },
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _isInCall ? _hangUp : _callAira,
                    style: ElevatedButton.styleFrom(
                      primary: _isInCall ? Theme.of(context).errorColor : Theme.of(context).primaryColor,
                    ),
                    child: Text(_isInCall ? 'End Call' : 'Call an Aira Agent'),
                  ),
                  Visibility(
                    visible: false,
                    child: RTCVideoView(_remoteRenderer),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  @override
  Future<void> addRemoteStream(MediaStream stream) async {
    await _rendererInitialized;
    _remoteRenderer.srcObject = stream;
  }

  Future<void> _callAira() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      String progressText = 'Calling...';
      StateSetter? progressSetState; // Idea from https://stackoverflow.com/a/62129750.

      // Show the call progress dialog.
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            progressSetState = setState;

            return AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: CircularProgressIndicator(),
                  ),
                  Semantics(
                    liveRegion: true,
                    child: Text(progressText),
                  ),
                ],
              ),
              actions: <Widget>[
                ElevatedButton(
                  onPressed: () async {
                    setState(() => progressText = 'Canceling...');
                    await _hangUp();
                  },
                  style: ElevatedButton.styleFrom(
                    primary: Theme.of(context).errorColor,
                  ),
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        ),
      );

      // Create the [PlatformClient]. Normally, you would do this at startup and expose the client using a [Provider].
      _platformClient = PlatformClient(PlatformClientConfig(
        PlatformEnvironment.dev,
        _apiKeyController.text,
        _clientIdController.text,
      ));

      // Log in.
      await _platformClient!.loginWithToken(_tokenController.text, int.parse(_userIdController.text));

      // Get the local audio and video. Do this before calling, because if access to the media is blocked, why call?
      _localStream = await navigator.mediaDevices.getUserMedia({'audio': true, 'video': true});

      // Call Aira.
      _room = await _platformClient!.createServiceRequest(this);

      // Listen for room updates.
      progressSetState!(() => progressText = 'Waiting for an Aira Agent...');
      _room!.addListener(() {
        if (_room!.serviceRequestState == ServiceRequestState.assigned) {
          progressSetState!(() => progressText = 'Connecting to Agent ${_room!.agentName}...');
        } else if (_room!.serviceRequestState == ServiceRequestState.started) {
          // Close the call progress dialog.
          Navigator.pop(context);

          // Rebuild the UI.
          setState(() {});

          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Connected to Agent ${_room!.agentName}'),
          ));
        } else if (_room!.serviceRequestState == ServiceRequestState.ended) {
          // The call was ended by the Agent or Platform, so hang up.
          _hangUp();

          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Call ended'),
          ));
        }
      });

      // Join the room.
      _room!.join(_localStream!);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString()),
      ));

      // Hang up if there was an error.
      _hangUp();
    }
  }

  Future<void> _hangUp() async {
    _remoteRenderer.srcObject?.getTracks().forEach((MediaStreamTrack track) => track.stop());
    _remoteRenderer.srcObject?.dispose();
    _remoteRenderer.srcObject = null;

    _localStream?.getTracks().forEach((MediaStreamTrack track) => track.stop());
    _localStream?.dispose();
    _localStream = null;

    await _room?.dispose();
    setState(() => _room = null);

    _platformClient?.dispose();
    _platformClient = null;

    // Close the call progress dialog if it's open.
    if (!ModalRoute.of(context)!.isCurrent) {
      Navigator.pop(context);
    }
  }
}
