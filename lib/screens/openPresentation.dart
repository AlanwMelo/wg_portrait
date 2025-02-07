import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:portrait/classes/usableFilesForList.dart';
import 'package:portrait/db/dbManager.dart';
import 'package:portrait/screens/slideShow.dart';
import 'package:sqflite/sqflite.dart';

class OpenPresentation extends StatefulWidget {
  final String presentationName;
  final Database openDB;

  const OpenPresentation(
      {Key? key, required this.presentationName, required this.openDB})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _OpenPresentationState(openDB);
}

class _OpenPresentationState extends State<OpenPresentation> {
  final Database openDB;

  _OpenPresentationState(this.openDB);

  late String displayName;
  List presentationItems = [];
  List<UsableFilesForList> slideshowItems = [];
  bool loadingItems = false;

  MyDbManager dbManager = MyDbManager();

  @override
  void initState() {
    _getPresentationFiles();
    displayName = widget.presentationName;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: _appBar(),
        body: Container(
          child: GridView.builder(
              shrinkWrap: true,
              itemCount: presentationItems.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                childAspectRatio: 1,
                crossAxisSpacing: 1,
                mainAxisSpacing: 1,
                crossAxisCount:
                    (MediaQuery.of(context).size.width / 120).round(),
              ),
              itemBuilder: (BuildContext context, int itemIndex) {
                return GestureDetector(
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => SlideShow(
                                    slideShowList: slideshowItems,
                                    startIndex: itemIndex,
                                  )));
                    },
                    child: Stack(fit: StackFit.expand, children: [
                      Image.file(presentationItems[itemIndex][1],
                          fit: BoxFit.cover, cacheWidth: 100, height: 100)
                      /*_ImageBuilder(
                              image: presentationItems[itemIndex][1])*/
                      ,
                      Container(
                          child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                            presentationItems[itemIndex][0].fileType == 'video'
                                ? Row(
                                    children: [
                                      Container(
                                        margin:
                                            EdgeInsets.only(left: 6, bottom: 6),
                                        child: Icon(Icons.play_circle_fill,
                                            size: 15, color: Colors.white),
                                      ),
                                    ],
                                  )
                                : Container(),
                            presentationItems[itemIndex][0].specialIMG == 'true'
                                ? Row(
                                    children: [
                                      Container(
                                          margin: EdgeInsets.only(
                                              left: 6, bottom: 6),
                                          child: Image.asset(
                                              "lib/assets/icons/360-graus.png",
                                              color: Colors.white,
                                              height: 15)),
                                    ],
                                  )
                                : Container(),
                            Container(
                                color: Colors.black.withOpacity(0.3),
                                height: 20,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                          margin: EdgeInsets.only(left: 4),
                                          child: presentationItems[itemIndex][0]
                                                      .fileName
                                                      .length >=
                                                  14
                                              ? Text(
                                                  presentationItems[itemIndex]
                                                          [0]
                                                      .fileName,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                      color: Colors.white),
                                                )
                                              : Text(
                                                  presentationItems[itemIndex]
                                                          [0]
                                                      .fileName,
                                                  style: TextStyle(
                                                      color: Colors.white))),
                                    )
                                  ],
                                ))
                          ]))
                    ]));
              }),
        ));
  }

  _appBar() {
    return AppBar(
      centerTitle: true,
      title: GestureDetector(onTap: () async {}, child: Text(displayName)),
      elevation: 0,
    );
  }

  _getPresentationFiles() async {
    loadingItems = !loadingItems;
    setState(() {});
    var result =
        await dbManager.readFromPresentation(widget.presentationName, openDB);

    for (var element in result) {
      UsableFilesForList usableFile = UsableFilesForList(
          element['FilePath'],
          element['FileName'],
          element['ThumbPath'],
          element['FileType'],
          element['VideoDuration'],
          element['FileOrientation'],
          element['SpecialIMG'],
          element['Created']);

      File thumbFile = File(element['ThumbPath']);

      slideshowItems.add(usableFile);
      slideshowItems.sort((a, b) => a.createdDate.compareTo(b.createdDate));

      presentationItems.add([usableFile, thumbFile]);
      presentationItems
          .sort((a, b) => a[0].createdDate.compareTo(b[0].createdDate));
      setState(() {});
    }
    loadingItems = !loadingItems;
  }
}

class _ImageBuilder extends StatefulWidget {
  final File image;

  const _ImageBuilder({Key? key, required this.image}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ImageBuilderState(image);
}

/// Carrega primeiro uma imagem de qualidade ruim e somente depois uma com qualidade boa para poupar memória
class _ImageBuilderState extends State<_ImageBuilder> {
  final File image;

  _ImageBuilderState(this.image);

  late Widget child;

  @override
  void initState() {
    child = Container(
        key: UniqueKey(),
        height: 150,
        width: 150,
        child:
            Image.file(image, fit: BoxFit.cover, cacheWidth: 60, height: 60));
    _fullImageLoader();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 2000),
      child: child,
      switchInCurve: Curves.ease,
    );
  }

  _fullImageLoader() async {
    await Future.delayed(Duration(seconds: 1));
    child = Container(
        key: UniqueKey(),
        height: 150,
        width: 150,
        child:
            Image.file(image, fit: BoxFit.cover, cacheWidth: 200, height: 200));

    /// Checa se o widget esta montado antes de chamar o setstate
    if (this.mounted) {
      setState(() {});
    }
  }
}
