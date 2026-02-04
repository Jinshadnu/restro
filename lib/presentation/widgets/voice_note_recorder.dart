import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class VoiceNoteRecorder extends StatefulWidget {
  final ValueChanged<File?> onChanged;
  final ValueChanged<bool>? onRecordingChanged;

  const VoiceNoteRecorder({
    super.key,
    required this.onChanged,
    this.onRecordingChanged,
  });

  @override
  State<VoiceNoteRecorder> createState() => _VoiceNoteRecorderState();
}

class _VoiceNoteRecorderState extends State<VoiceNoteRecorder> {
  final _recorder = AudioRecorder();
  final _player = AudioPlayer();

  bool _hasPermission = false;
  bool _isRecording = false;
  bool _isPaused = false;
  bool _isPlaying = false;

  String? _path;

  @override
  void initState() {
    super.initState();
    _init();
    _player.onPlayerStateChanged.listen((state) {
      if (!mounted) return;
      setState(() {
        _isPlaying = state == PlayerState.playing;
      });
    });
  }

  Future<void> _init() async {
    final ok = await _recorder.hasPermission();
    if (!mounted) return;
    setState(() {
      _hasPermission = ok;
    });
  }

  Future<String> _nextPath() async {
    final dir = await getTemporaryDirectory();
    final name = 'voice_note_${DateTime.now().millisecondsSinceEpoch}.m4a';
    return p.join(dir.path, name);
  }

  Future<void> _start() async {
    if (!_hasPermission) {
      await _init();
      if (!_hasPermission) return;
    }

    if (_isPlaying) {
      await _player.stop();
    }

    final path = await _nextPath();
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      ),
      path: path,
    );

    setState(() {
      _path = path;
      _isRecording = true;
      _isPaused = false;
    });

    widget.onRecordingChanged?.call(true);
    widget.onChanged(null);
  }

  Future<void> _pause() async {
    if (!_isRecording || _isPaused) return;
    await _recorder.pause();
    setState(() {
      _isPaused = true;
    });
  }

  Future<void> _resume() async {
    if (!_isRecording || !_isPaused) return;
    await _recorder.resume();
    setState(() {
      _isPaused = false;
    });
  }

  Future<void> _stop() async {
    if (!_isRecording) return;
    final stoppedPath = await _recorder.stop();
    final finalPath = (stoppedPath ?? _path);

    setState(() {
      _isRecording = false;
      _isPaused = false;
      _path = finalPath;
    });

    widget.onRecordingChanged?.call(false);

    if (finalPath == null || finalPath.trim().isEmpty) {
      widget.onChanged(null);
      return;
    }

    final file = File(finalPath);
    if (!await file.exists()) {
      widget.onChanged(null);
      return;
    }

    final len = await file.length();
    if (len <= 0) {
      widget.onChanged(null);
      return;
    }

    widget.onChanged(file);
  }

  Future<void> _play() async {
    if (_path == null || _path!.trim().isEmpty) return;
    await _player.play(DeviceFileSource(_path!));
  }

  Future<void> _pausePlayback() async {
    await _player.pause();
  }

  Future<void> _clear() async {
    if (_isPlaying) await _player.stop();
    if (_isRecording) await _stop();

    final toDelete = _path;

    setState(() {
      _path = null;
      _isRecording = false;
      _isPaused = false;
    });

    widget.onRecordingChanged?.call(false);

    widget.onChanged(null);

    if (toDelete != null) {
      final f = File(toDelete);
      if (await f.exists()) {
        await f.delete();
      }
    }
  }

  @override
  void dispose() {
    _player.dispose();
    _recorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasFile = _path != null && _path!.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed:
                    _isRecording ? (_isPaused ? _resume : _pause) : _start,
                icon: Icon(
                  _isRecording
                      ? (_isPaused ? Icons.play_arrow : Icons.pause)
                      : Icons.mic,
                ),
                label: Text(
                  _isRecording
                      ? (_isPaused ? 'Resume recording' : 'Pause recording')
                      : 'Start recording',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: _isRecording ? _stop : null,
              icon: const Icon(Icons.stop),
              label: const Text('Stop'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed:
                    hasFile ? (_isPlaying ? _pausePlayback : _play) : null,
                icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                label: Text(
                  _isPlaying ? 'Pause preview' : 'Play preview',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: (hasFile || _isRecording) ? _clear : null,
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Remove voice note',
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          !_hasPermission
              ? 'Microphone permission required'
              : (_isRecording
                  ? (_isPaused ? 'Recording paused' : 'Recording...')
                  : (hasFile ? 'Voice note ready' : 'No voice note')),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
