import 'dart:async';
import 'apod_object.dart';
import 'apod_details.dart';
import 'sqlite_database.dart';
import 'favorite_images.dart';
import 'save_file.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_admob/firebase_admob.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';

const String testDevice = 'E46D8B061991617A79BD4B1467A65D98';

void main() => runApp(
  MaterialApp(
    title: 'Astronomy Images',
    theme: ThemeData(
      primarySwatch: Colors.blue,
      primaryColor: Colors.blueGrey[900],
    ),
    home: ApodApp()
  )
);

Future<DateTime> selectDate(BuildContext context, DateTime date) async {
  final DateTime picked = await showDatePicker(
    context: context,
    initialDate: date,
    firstDate: DateTime(1995, 6, 16),
    lastDate: date.add(Duration(minutes: 1))
  );
  if (picked != null) {
    return picked;
  } else {
    return DateTime.now();
  }
}

class ApodApp extends StatefulWidget {
  @override
  ApodAppState createState() => new ApodAppState();
}

class ApodAppState extends State<ApodApp> {

  static final MobileAdTargetingInfo targetingInfo = MobileAdTargetingInfo(
    testDevices: testDevice != null ? <String>[testDevice] : null,
  );

  BannerAd _bannerAd;

  BannerAd createBannerAd() {
  return BannerAd(
    adUnitId: 'ca-app-pub-7839960170715319/8015225890',
    size: AdSize.smartBanner,
    targetingInfo: targetingInfo,
    listener: (MobileAdEvent event) {
        print("BannerAd event $event");
      },
    );
  }

  @override
  void initState() {
    super.initState();
    FirebaseAdMob.instance.initialize(appId: FirebaseAdMob.testAppId);
    _bannerAd = createBannerAd()..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  DateTime _selectedDate = DateTime.now();
  bool  _isLoading = false;
  static const platform = const MethodChannel('samples.flutter.io/wallpaper');

  @override
  Widget build(BuildContext context) {
    _bannerAd..show();
    return Scaffold(
       appBar: AppBar(
         title: Text("Apod Images"),
         actions: <Widget>[
                    new IconButton(
                       icon: const Icon(Icons.search),
                       onPressed: ()=> _findImageByDateDialog(),
                    ),
                    new IconButton(
                       icon: const Icon(Icons.favorite),
                       onPressed: (){
                         Navigator.push(
                             context,
                             MaterialPageRoute(builder: (context) => FavoriteImages() ),
                           );
                       },
                    ),

         ]
       ),
       body:  ModalProgressHUD(
           child: ApodList(),
           inAsyncCall: _isLoading,
           opacity: 0.5,
           progressIndicator: CircularProgressIndicator(),
         ),
      );
  }

  Future<Null> _findImageByDateDialog() async {
    return showDialog<Null>(
      context: context,
      barrierDismissible: true, // user must tap button!
      builder: (BuildContext context) {
        return FindByDateDialog();
      },
    );
  }
}

class ApodList extends StatefulWidget {
  @override
  ApodListState createState() => new ApodListState();
}

class ApodListState extends State<ApodList> {
  bool  _isLoading = false;
  var present = new DateTime.now();
  var favoriteList = FavoriteProvider().getFavoriteImagesDate();
  var db = FavoriteProvider();

  Widget _buildApodList() {
    return ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemExtent: 300.0,
        itemBuilder: (context, i) {
          // Add a one-pixel-high divider widget before each row in theListView.
          return _buildApodRow(i);
        });
  }

  _buildApodRow(index)  {
      return ApodElement(index: index);
    }

  @override
   Widget build(BuildContext context) {
     return ModalProgressHUD(
         child: _buildApodList(),
         inAsyncCall: _isLoading,
         opacity: 0.5,
         progressIndicator: CircularProgressIndicator(),
       );
   }
 }

class ApodElement extends StatefulWidget {
  final int index;
  const ApodElement({Key key, @required this.index}) : super(key: key);

  @override
  ApodElementState createState() => new ApodElementState();
}

class ApodElementState extends State<ApodElement>{
  var present = new DateTime.now().toUtc().subtract(Duration(hours: 6));
  var db = FavoriteProvider();
  var _isLoading = false;
  var _isSaving = false;

  Future<ApodImage> _getImageFromIndex(index) async {
    var datetime = present.subtract(Duration(days: index));

    try {
      var image = await getImageFromFireBase(datetime);
      return image;
    } catch (e) {
      var image = await getImageFromNasa(datetime);
      return image;
    }
  }

  Widget _builElement(){
    return  Card(
               child: FutureBuilder<ApodImage>(
                 future: _getImageFromIndex(widget.index),
                 builder: (context, snapshot) {
                   if (snapshot.hasData) {
                     return Wrap(
                      //mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Container(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.only(bottom: 8.0),
                                        child: Text(
                                          snapshot.data.copyright != null ? "${snapshot.data.copyright}":"Unknow",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        "${snapshot.data.date}",
                                        style: TextStyle(
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                    icon: FutureBuilder<bool>(
                                      future: db.isExist(snapshot.data.date),
                                      builder: (context, snapshot) {
                                        if (snapshot.data == true){
                                          return Icon(Icons.favorite);
                                        } else {
                                          return Icon(Icons.favorite_border);
                                        }
                                      }
                                    ),
                                    onPressed: () async {
                                      setState(() {
                                        _isLoading = true;
                                      });
                                      var isExist = await db.isExist(snapshot.data.date);
                                      if (isExist == true){
                                         await db.delete(snapshot.data.date);
                                      } else {
                                         await db.insert(snapshot.data);
                                      }
                                      setState(() {
                                        _isLoading = false;
                                      });
                                    },
                                    color: Colors.pinkAccent,
                                 ),
                                 IconButton(
                                     icon: _isSaving ? CircularProgressIndicator() : Icon(Icons.get_app),
                                     onPressed: () async {
                                       setState(() {
                                         _isSaving = true;
                                       });
                                       var imagePath = await saveNetworkImage(snapshot.data.url, DateTime.parse(snapshot.data.date));
                                       setState(() {
                                         _isSaving = false;
                                       });
                                     }
                                   ),
                                 ]
                               ),
                        ),

                        Center(
                          child: GestureDetector(
                            child: FadeInImage.assetNetwork(
                              placeholder: 'assets/loading.gif',
                              image: snapshot.data.url),
                            onTap: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => ApodDetail(apodImage: snapshot.data)),
                                    );
                                  }
                                )
                              ),
                    ],
                   );
                   } else if (snapshot.hasError) {
                     return Text("${snapshot.error}");
                   }
                   // By default, show a loading spinner
                   return Center(
                     child: CircularProgressIndicator()
                   );
                 },
               )
     );
  }

  @override
  Widget build(BuildContext context) {
    return ModalProgressHUD(
              child: _builElement(),
              inAsyncCall: _isLoading,
              opacity: 0.5,
              progressIndicator: CircularProgressIndicator(),
            );
   }
}

class FindByDateDialog extends StatefulWidget{
  @override
  FindByDateDialogState createState() => new FindByDateDialogState();
}

class FindByDateDialogState extends State<FindByDateDialog>{
  var _selectedDate = DateTime.now();
  var _isLoading = false;

  @override
  Widget build(BuildContext context){
    return ModalProgressHUD(
              child: AlertDialog(
                title: Text('Find image by date'),
                content:
                    SingleChildScrollView(
                      child: ListBody(
                        children: <Widget> [
                          Center(
                            child: GestureDetector(
                                child: InputDecorator(
                                  decoration: InputDecoration(
                                    labelText: 'Date',
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      Text('${_selectedDate.year}-${_selectedDate.month}-${_selectedDate.day}',
                                      ),
                                      Icon(Icons.arrow_drop_down),
                                    ],
                                  ),
                                ),
                                onTap: () async {
                                  var newDate = await selectDate(context, _selectedDate);
                                  setState(() {
                                      _selectedDate = newDate;
                                  });
                                },
                              )
                          )
                        ],
                      ),
                    ),
                actions: <Widget>[
                  FlatButton(
                    child: Text('Cancel'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  FlatButton(
                    child: Text('Ok'),
                    onPressed: () async {
                        // Find the Scaffold in the Widget tree and use it to show a SnackBar!
                      var apodData;
                      setState(() {
                        _isLoading = true;
                      });

                      try {
                        apodData = await getImageFromFireBase(_selectedDate);
                      } catch (e) {
                        apodData = await getImageFromNasa(_selectedDate);
                      }

                      if (apodData!= null){
                        Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => ApodDetail(apodImage: apodData)),
                          );
                        setState(() {
                            _isLoading = false;
                          });
                      } else {
                        Navigator.of(context).pop();
                        _isLoading = false;
                      }

                    },
                  ),
                ],
              ),
              inAsyncCall: _isLoading,
              opacity: 0.5,
              progressIndicator: CircularProgressIndicator(),
            );
  }
}
