import 'dart:async';

import 'package:flutter/foundation.dart';
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

  final FocusNode _messageFocusNode = FocusNode();

  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _clientIdController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _messagingReceiveKeyController = TextEditingController();
  final TextEditingController _messagingSendKeyController = TextEditingController();
  final TextEditingController _tokenController = TextEditingController();
  final TextEditingController _userIdController = TextEditingController();

  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  late final Future<void> _rendererInitialized;

  MediaStream? _localStream;
  PlatformClient? _platformClient;
  Room? _room;

  bool get _isInCall => _room != null;

  bool get _isMessagingEnabled =>
      _messagingSendKeyController.text.isNotEmpty && _messagingReceiveKeyController.text.isNotEmpty;

  @override
  void initState() {
    super.initState();

    // During development, you can set these here instead of through the UI to iterate faster.
    _apiKeyController.text = '';
    _clientIdController.text = '';
    _messagingReceiveKeyController.text = '';
    _messagingSendKeyController.text = '';
    _tokenController.text = '';
    _userIdController.text = '';

    _rendererInitialized = _remoteRenderer.initialize();
  }

  @override
  void dispose() {
    _remoteRenderer.dispose();

    _messageFocusNode.dispose();

    _apiKeyController.dispose();
    _clientIdController.dispose();
    _messageController.dispose();
    _messagingReceiveKeyController.dispose();
    _messagingSendKeyController.dispose();
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
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: LayoutBuilder(builder: (BuildContext context, BoxConstraints viewportConstraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 640 - 32,
                  minHeight: viewportConstraints.maxHeight - 32,
                ),
                child: IntrinsicHeight(
                  child: _isInCall ? _inCallWidget : _callSetupWidget,
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget get _inCallWidget {
    return Column(
      children: <Widget>[
        Visibility(
          visible: false,
          child: RTCVideoView(_remoteRenderer),
        ),
        Visibility(
          visible: _isMessagingEnabled,
          child: _messagingWidget,
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _hangUp,
          style: ElevatedButton.styleFrom(primary: Theme.of(context).errorColor),
          child: const Text('End Call'),
        ),
      ],
    );
  }

  Widget get _messagingWidget {
    return Row(
      children: <Widget>[
        Expanded(
          child: TextFormField(
            controller: _messageController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Message',
            ),
            // Enable/disable the send button on change.
            onChanged: (_) => setState(() {}),
            onFieldSubmitted: (_) => _sendMessage(),
            textInputAction: TextInputAction.send,
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.send),
          onPressed: _messageController.text.isEmpty ? null : _sendMessage,
          tooltip: 'Send',
        ),
      ],
    );
  }

  void _sendMessage() async {
    _room!.sendMessage(_messageController.text);

    setState(() => _messageController.clear());

    _messageFocusNode.requestFocus();
  }

  Widget get _callSetupWidget {
    return Form(
      key: _formKey,
      child: Column(
        children: <Widget>[
          TextFormField(
            controller: _clientIdController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              // Announce validation errors (https://github.com/flutter/flutter/issues/99715).
              helperText: kIsWeb ? ' ' : null,
              labelText: 'Client ID',
            ),
            validator: (String? value) {
              if (value == null || value.isEmpty) {
                return 'A client ID is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _apiKeyController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              // Announce validation errors (https://github.com/flutter/flutter/issues/99715).
              helperText: kIsWeb ? ' ' : null,
              labelText: 'API Key',
            ),
            validator: (String? value) {
              if (value == null || value.isEmpty) {
                return 'An API key is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _userIdController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              // Announce validation errors (https://github.com/flutter/flutter/issues/99715).
              helperText: kIsWeb ? ' ' : null,
              labelText: 'User ID',
            ),
            validator: (String? value) {
              if (value == null || value.isEmpty) {
                return 'A user ID is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _tokenController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              // Announce validation errors (https://github.com/flutter/flutter/issues/99715).
              helperText: kIsWeb ? ' ' : null,
              labelText: 'Token',
            ),
            validator: (String? value) {
              if (value == null || value.isEmpty) {
                return 'A token is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _messagingSendKeyController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Messaging Send Key (Optional)',
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _messagingReceiveKeyController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Messaging Receive Key (Optional)',
            ),
            enabled: !_isInCall,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _callAira,
            style: ElevatedButton.styleFrom(primary: Theme.of(context).primaryColor),
            child: const Text('Call an Aira Agent'),
          ),
        ],
      ),
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
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
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
      PlatformMessagingKeys? messagingKeys;
      if (_isMessagingEnabled) {
        messagingKeys = PlatformMessagingKeys(_messagingSendKeyController.text, _messagingReceiveKeyController.text);
      }
      _platformClient = PlatformClient(PlatformClientConfig(
        PlatformEnvironment.dev,
        _apiKeyController.text,
        _clientIdController.text,
        messagingKeys,
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
      if (_isMessagingEnabled) {
        _room!.messageStream.listen((Message message) {
          if (message.isRemote) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Agent: ${message.text}'),
            ));
          }
        });
      }

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
