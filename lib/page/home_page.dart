import 'package:alist/entity/file_list_resp_entity.dart';
import 'package:alist/net/dio_utils.dart';
import 'package:alist/page/video_player_page.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class HomePage extends StatefulWidget {
  final String path;

  const HomePage({super.key, required this.path});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  FileListRespEntity? data;
  final CancelToken _cancelToken = CancelToken();

  @override
  void initState() {
    super.initState();
    loadData();
  }

  @override
  void reassemble() {
    super.reassemble();
    if (null == data) {
      loadData();
    }
  }

  void loadData() {
    var body = {
      "path": widget.path,
      "password": "",
      "page": 1,
      "per_page": 0,
      "refresh": false
    };
    DioUtils.instance.requestNetwork<FileListRespEntity>(Method.post, "fs/list",
        cancelToken: _cancelToken, params: body, onSuccess: (data) {
      setState(() {
        this.data = data;
      });
    }, onError: (code, msg) {
      print(msg);
    });
  }

  @override
  void dispose() {
    super.dispose();
    _cancelToken.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final files = data?.content ?? [];
    return Scaffold(
      appBar: AppBar(
        title: const Text("文件列表"),
      ),
      body: ListView.builder(
        itemCount: files.length,
        itemBuilder: (context, index) {
          var file = files[index];
          var displayName = file.name;
          if (file.isDir) {
            displayName = "$displayName(文件夹)";
          }
          return ListTile(
            title: Text(displayName),
            subtitle: Text(file.modified),
            onTap: () {
              onFileTap(file, context);
            },
          );
        },
      ),
    );
  }

  void onFileTap(FileListRespContent file, BuildContext context) {
    if (file.isDir) {
      var path = '';
      if (widget.path == '/') {
        path = "/${file.name}";
      } else {
        path = "${widget.path}/${file.name}";
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => HomePage(path: path),
        ),
      );
    } else if (file.name.endsWith(".mp4")) {
      var path = '';
      if (widget.path == '/') {
        path = "/${file.name}";
      } else {
        path = "${widget.path}/${file.name}";
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VideoPage(path: path),
        ),
      );
    }
  }
}
