// lib/screens/downloads_screen.dart

import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:mime/mime.dart';
import 'package:open_file/open_file.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<DownloadTask> _tasks = [];
  bool _isLoading = true;
  final Map<String, double> _progressMap = {};

  @override
  void initState() {
    super.initState();
    _initDownloadListener();
    _loadDownloads();
  }

  void _initDownloadListener() {
    FlutterDownloader.registerCallback((id, status, progress) {
      if (mounted) setState(() => _progressMap[id] = progress.toDouble());
    });
  }

  Future<void> _loadDownloads() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final tasks = await FlutterDownloader.loadTasks();
      if (mounted) setState(() => _tasks = tasks ?? []);
    } catch (e, stackTrace) {
      debugPrint('Error loading downloads: $e');
      debugPrint('StackTrace: $stackTrace');
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Failed to load downloads: ${e.toString()}')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _recordActivity(
      String resourceId, String type, int duration, bool completed) async {
    try {
      await _supabase.from('user_activities').insert({
        'user_id': _supabase.auth.currentUser?.id,
        'resource_id': resourceId,
        'activity_type': type,
        'duration_seconds': duration,
        'is_completed': completed,
      });
    } catch (e, stackTrace) {
      debugPrint('Activity recording failed: $e');
      debugPrint('StackTrace: $stackTrace');
    }
  }

  Future<void> _openFile(DownloadTask task) async {
    try {
      if (task.status == DownloadTaskStatus.complete) {
        final filePath =
            '${task.savedDir}${Platform.pathSeparator}${task.filename}';
        final result = await OpenFile.open(filePath);
        final resourceId = task.filename?.split('_')[1] ?? 'unknown';
        await _recordActivity(resourceId, 'download', 0, true);
        if (result.type != ResultType.done && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Could not open file: ${result.message}')));
        }
      }
    } catch (e, stackTrace) {
      debugPrint('Error opening file: $e');
      debugPrint('StackTrace: $stackTrace');
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error opening file: ${e.toString()}')));
    }
  }

  Future<void> _deleteDownload(DownloadTask task) async {
    try {
      await FlutterDownloader.remove(
          taskId: task.taskId, shouldDeleteContent: true);
      await _loadDownloads();
    } catch (e, stackTrace) {
      debugPrint('Error deleting download: $e');
      debugPrint('StackTrace: $stackTrace');
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete: ${e.toString()}')));
    }
  }

  IconData _getFileIcon(String? filename) {
    if (filename == null) return Icons.insert_drive_file;
    final mimeType = lookupMimeType(filename);
    if (mimeType?.startsWith('video/') ?? false) return Icons.video_library;
    if (mimeType?.startsWith('image/') ?? false) return Icons.image;
    if (mimeType?.startsWith('audio/') ?? false) return Icons.audiotrack;
    if (filename.endsWith('.pdf')) return Icons.picture_as_pdf;
    return Icons.insert_drive_file;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Downloads'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadDownloads)
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _tasks.isEmpty
              ? const Center(child: Text('No downloads yet'))
              : ListView.builder(
                  itemCount: _tasks.length,
                  itemBuilder: (context, index) {
                    final task = _tasks[index];
                    final progress =
                        _progressMap[task.taskId] ?? (task.progress).toDouble();
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      child: ListTile(
                        leading: Icon(_getFileIcon(task.filename), size: 32),
                        title: Text(task.filename ?? 'Unknown file',
                            overflow: TextOverflow.ellipsis),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            LinearProgressIndicator(
                                value: progress / 100,
                                backgroundColor: Colors.grey[200],
                                minHeight: 4),
                            const SizedBox(height: 4),
                            Text(
                                '${progress.toStringAsFixed(1)}% • ${_getStatusText(task.status)}',
                                style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (task.status == DownloadTaskStatus.complete)
                              IconButton(
                                  icon: const Icon(Icons.open_in_new),
                                  onPressed: () => _openFile(task)),
                            IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => _deleteDownload(task)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  String _getStatusText(DownloadTaskStatus status) {
    switch (status) {
      case DownloadTaskStatus.complete:
        return 'Completed';
      case DownloadTaskStatus.running:
        return 'Downloading';
      case DownloadTaskStatus.paused:
        return 'Paused';
      case DownloadTaskStatus.failed:
        return 'Failed';
      case DownloadTaskStatus.canceled:
        return 'Canceled';
      case DownloadTaskStatus.enqueued:
        return 'Waiting';
      default:
        return 'Unknown';
    }
  }
}
