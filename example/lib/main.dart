import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_aira/flutter_aira.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:logging/logging.dart';

SemanticsHandle? semanticsHandle;

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Auto-enable accessibility for our Blind and Low Vision customers (see
  // https://docs.flutter.dev/development/accessibility-and-localization/accessibility#screen-readers).
  semanticsHandle = RendererBinding.instance.ensureSemantics();

  // Configure logging.
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((record) {
    print('${record.time} | ${record.level.name} | ${record.loggerName} | ${record.message}'); // ignore: avoid_print
    if (record.error != null) {
      print(record.error); // ignore: avoid_print
    }
    if (record.stackTrace != null) {
      print(record.stackTrace); // ignore: avoid_print
    }
  });

  runApp(const MaterialApp(
    title: 'Aira Demo',
    home: MyApp(),
  ));
}

enum LoginType { verificationCode, token }

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
  final TextEditingController _verificationCodeController = TextEditingController();

  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  late final Future<void> _rendererInitialized;

  LoginType _loginType = LoginType.verificationCode;
  MediaStream? _localStream;
  PlatformClient? _platformClient;
  User? _user;
  int? _accountId;
  Room? _room;
  bool _isTorchOn = false;

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
    _verificationCodeController.text = '';

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
    _verificationCodeController.dispose();

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
                  child: _body,
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget get _body {
    if (_room != null) {
      return _inCallWidget;
    }
    if (_platformClient != null) {
      return _callSetupWidget;
    }
    return _loginWidget;
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
          style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
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
    _room!.messagingClient!.sendMessage(_messageController.text);

    setState(() => _messageController.clear());

    _messageFocusNode.requestFocus();
  }

  Widget get _callSetupWidget {
    return Column(
      children: <Widget>[
        DropdownButtonFormField<int>(
          decoration: const InputDecoration(hintText: 'Profile'),
          items: _user!.profiles
              .map((e) => DropdownMenuItem<int>(
                    value: e.account.id,
                    child: Row(
                      children: <Widget>[
                        Icon(
                          e.account.type == AccountType.business ? Icons.work : Icons.account_circle,
                          semanticLabel: e.account.type == AccountType.business ? 'Business' : 'Personal',
                        ),
                        const SizedBox(width: 5),
                        Text(e.account.name),
                      ],
                    ),
                  ))
              .toList(growable: false),
          onChanged: (int? newValue) => setState(() => _accountId = newValue),
          value: _accountId,
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _callAira,
          style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary),
          child: const Text('Call an Aira Agent'),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _logout,
          style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
          child: const Text('Logout'),
        ),
      ],
    );
  }

  Widget get _loginWidget {
    return Form(
      key: _formKey,
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: RadioListTile<LoginType>(
                  groupValue: _loginType,
                  onChanged: (LoginType? newValue) => setState(() => _loginType = newValue!),
                  title: const Text('Login with Verification Code', overflow: TextOverflow.ellipsis),
                  value: LoginType.verificationCode,
                ),
              ),
              Expanded(
                child: RadioListTile<LoginType>(
                  groupValue: _loginType,
                  onChanged: (LoginType? newValue) => setState(() => _loginType = newValue!),
                  title: const Text('Login with Token', overflow: TextOverflow.ellipsis),
                  value: LoginType.token,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
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
          ..._loginType == LoginType.verificationCode
              ? <Widget>[
                  TextFormField(
                    controller: _verificationCodeController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      // Announce validation errors (https://github.com/flutter/flutter/issues/99715).
                      helperText: kIsWeb ? ' ' : null,
                      labelText: 'Verification Code',
                    ),
                    validator: (String? value) {
                      if (_loginType == LoginType.verificationCode && (value?.isEmpty ?? true)) {
                        return 'A verification code is required';
                      }
                      return null;
                    },
                  ),
                ]
              : <Widget>[
                  TextFormField(
                    controller: _userIdController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      // Announce validation errors (https://github.com/flutter/flutter/issues/99715).
                      helperText: kIsWeb ? ' ' : null,
                      labelText: 'User ID',
                    ),
                    validator: (String? value) {
                      if (_loginType == LoginType.token && (value?.isEmpty ?? true)) {
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
                      if (_loginType == LoginType.token && (value?.isEmpty ?? true)) {
                        return 'A token is required';
                      }
                      return null;
                    },
                  ),
                ],
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
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _login,
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary),
            child: const Text('Log In'),
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

  @override
  Future<ByteBuffer> takePhoto() async {
    return _localStream!.getVideoTracks()[0].captureFrame();
  }

  @override
  Future<void> toggleFlashlight() async {
    if (kIsWeb) return Future.value(null);

    MediaStream stream = _localStream!;
    _isTorchOn = !_isTorchOn;
    for (MediaStreamTrack track in stream.getVideoTracks()) {
      await track.setTorch(_isTorchOn);
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      // Create the [PlatformClient]. Normally, you would do this at startup and expose the client using a [Provider].
      PlatformMessagingKeys? messagingKeys;
      if (_isMessagingEnabled) {
        messagingKeys = PlatformMessagingKeys(_messagingSendKeyController.text, _messagingReceiveKeyController.text);
      }
      _platformClient = PlatformClient(PlatformClientConfig(
        apiKey: _apiKeyController.text,
        clientId: _clientIdController.text,
        environment: PlatformEnvironment.dev,
        messagingKeys: messagingKeys,
      ));

      // Log in.
      if (_loginType == LoginType.verificationCode) {
        Session session = await _platformClient!.loginWithClientVerificationCode(_verificationCodeController.text);

        // The verification code can only be used once, so switch to logging in with the returned token.
        _loginType = LoginType.token;
        _tokenController.text = session.token;
        _userIdController.text = session.userId.toString();
      } else {
        await _platformClient!.loginWithToken(_tokenController.text, int.parse(_userIdController.text));
      }

      _user = await _platformClient!.getUser();
      _accountId = null;

      setState(() {});
    } catch (e) {
      _showSnackBar(e.toString());

      _platformClient?.dispose();
      _platformClient = null;
    }
  }

  Future<void> _logout() async {
    try {
      _platformClient?.logout();
      _tokenController.clear();
    } catch (e) {
      _showSnackBar(e.toString());
    }

    _platformClient?.dispose();
    setState(() => _platformClient = null);
  }

  Future<void> _callAira() async {
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
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        ),
      );

      // Get the local audio and video. Do this before calling, because if access to the media is blocked, why call?
      _localStream = await navigator.mediaDevices.getUserMedia({'audio': true, 'video': true});

      // Call Aira.
      _room = await _platformClient!.createServiceRequest(this, accountId: _accountId);

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

          _showSnackBar('Connected to Agent ${_room!.agentName}');
        } else if (_room!.serviceRequestState == ServiceRequestState.ended) {
          // The call was ended by the Agent or Platform, so hang up.
          _hangUp();

          _showSnackBar('Call ended');
        }
      });

      if (_isMessagingEnabled) {
        _room!.messagingClient!.messageStream.listen((Message message) {
          if (message.isRemote) {
            _showSnackBar('Agent: ${message.text}');
          }
        });
      }

      _room!.onReconnect = () => _showSnackBar('Reconnecting');
      _room!.onReconnected = () => _showSnackBar('Reconnected');

      // Join the room.
      _room!.join(_localStream!);
    } catch (e) {
      _showSnackBar(e.toString());

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

    // Close the call progress dialog if it's open.
    if (mounted && !ModalRoute.of(context)!.isCurrent) {
      Navigator.pop(context);
    }
  }

  void _showSnackBar(String content) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(content),
    ));
  }
}
