import 'dart:developer';
import 'dart:io';

import 'package:permission_handler/permission_handler.dart';
import 'package:portrait/classes/fileProcessor.dart';
import 'package:portrait/streams/syncingStream.dart';
import 'package:portrait/db/dbManager.dart';
import 'package:sqflite/sqflite.dart';

import 'directoryManager.dart';

class SyncFiles {
  final SyncingStream syncingStreamClass;
  final Database openDB;

  SyncFiles(this.syncingStreamClass, this.openDB);

  MyDbManager dbManager = MyDbManager();

  syncDirectories(Function(String) dirSynced) async {
    await Permission.storage
        .request()
        .isGranted
        .whenComplete(() {});
    if (await Permission.storage
        .request()
        .isGranted) {
      syncingStreamClass.streamControllerSink.add('start');
      syncingStreamClass.streamControllerSink.add('Syncing directories list');
      await DirectoryManager()
          .getDirectoriesWithImagesAndVideos((answer) async {
        for (var element in answer) {
          dirSynced(element);
        }
        dirSynced('done');
      });
    }
  }

  syncFiles(List<Directory> directories, Function(String) answer) async {
    if (directories.isNotEmpty) {
      syncingStreamClass.streamControllerSink.add('start');
      directories.sort(
              (a, b) =>
              b
                  .statSync()
                  .modified
                  .compareTo(a
                  .statSync()
                  .modified));

      try {
        for (var directory in directories) {
          String dirName =
          directory.path.substring(0, directory.path.lastIndexOf('/'));
          dirName = dirName.substring(dirName.lastIndexOf('/') + 1);

          syncingStreamClass.streamControllerSink.add('Syncing $dirName');
          await FileProcessor().generateLocalInfo(directory.path, openDB);
          answer(directory.path);
        }
      } catch (e) {
        log(e.toString());
      }
      syncingStreamClass.streamControllerSink.add('stop');
    } else {}
    syncingStreamClass.streamControllerSink.add('stop');
    return true;
  }
}
