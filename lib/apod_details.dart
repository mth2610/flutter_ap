
import 'save_file.dart';
import 'dart:async';
import 'apod_object.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';


const platform = const MethodChannel('samples.flutter.io/wallpaper');
Future<Null> setWallPaper(String path) async {
  try {
    final int result = await platform.invokeMethod('setWallpaper', {'path': path});
    print(result);
    print("successfully set wallpaper");
    //return(result);
  } on PlatformException catch (e) {
    print(e);
    print("cant set wallpaper");
  }
}

class ApodDetail extends StatefulWidget {
  final ApodImage apodImage;
  ApodDetail({Key key, @required this.apodImage}) : super(key: key);

  @override
  ApodDetailState createState() => new ApodDetailState();
}

class ApodDetailState extends State<ApodDetail> {
  bool _setttingWallpaper = false;

  Future<Null> _alertSetWallpaper(ApodImage apodData) async {
    return showDialog<Null>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return SetWallpaperDialog(apodImage: apodData);
      },
    );
  }

  Widget _buildDetail(){
    return ListView(
              children: <Widget>[
                Container(
                    padding: const EdgeInsets.only(
                        top: 16.0,
                        left: 16.0,
                        bottom: 0.0),
                    child: Text("${widget.apodImage.title}",
                            style: TextStyle(fontWeight: FontWeight.bold,
                                              fontSize: 20.0)
                          ),
                ),
                Container(
                    child:ListTile(
                      title: Text(widget.apodImage.copyright != null ? "${widget.apodImage.copyright}":"Unknow"),
                      subtitle: Text('${widget.apodImage.date}'),
                  )
                ),
                Container(
                  padding: const EdgeInsets.all(4.0),
                  child: FadeInImage.assetNetwork(
                            placeholder: 'assets/loading.gif',
                            image: widget.apodImage.url)
                        ),
                Container(
                  padding: const EdgeInsets.all(16.0),
                  child: Text('${widget.apodImage.explanation}')
                ),

              ],

          );
  }

  @override
   Widget build(BuildContext context) {
     return Scaffold(
      appBar: AppBar(
        title: Text("Details"),
        actions: <Widget>[      // Add 3 lines from here...
                  new IconButton(icon: const Icon(Icons.wallpaper),
                  onPressed: ()=>_alertSetWallpaper(widget.apodImage)),
        ]
      ),
      body: ModalProgressHUD(
        child:_buildDetail(),
        inAsyncCall: _setttingWallpaper,
        opacity: 0.5,
        progressIndicator: CircularProgressIndicator(),
        ),
      persistentFooterButtons: <Widget>[
          Container(
            height: 30.0,
          ),
        ],
      );
   }
}

class SetWallpaperDialog extends StatefulWidget{
  final ApodImage apodImage;
  SetWallpaperDialog({Key key, @required this.apodImage}) : super(key: key);

  @override
  SetWallpaperDialogState createState() => new SetWallpaperDialogState();
}

class SetWallpaperDialogState extends State<SetWallpaperDialog>{
  var _isLoading = false;
  var _dialogText = <Widget>[
    Text('Do you want to set this image as wallpaper ?'),
  ];

  @override
  Widget build(BuildContext context){
    return ModalProgressHUD(
        child: AlertDialog(
              title: Text('Set wallpaper'),
              content: SingleChildScrollView(
                child: ListBody(
                  children: _dialogText,
                ),
              ),
              actions: <Widget>[
                FlatButton(
                  child: Text('No'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                FlatButton(
                  child: Text('Yes'),
                  onPressed: () async {
                    // String url = snapshot.data.hdurl;
                    setState(() {
                       _isLoading = true;
                     });
                    var imagePath = await saveNetworkImage(widget.apodImage.url, DateTime.parse(widget.apodImage.date));
                    await setWallPaper(imagePath);
                    setState(() {
                       _isLoading = false;
                     });
                     Navigator.of(context).pop();
                  },
                )
              ],
            ),
        inAsyncCall: _isLoading,
        opacity: 0.5,
        progressIndicator: CircularProgressIndicator(),
      );

  }
}
