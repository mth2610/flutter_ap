
import 'apod_object.dart';
import 'sqlite_database.dart';
import 'apod_details.dart';
import 'save_file.dart';

import 'package:flutter/material.dart';

Future<List<ApodImage>> fetchFavoriteImages() async {
  var db = FavoriteProvider();
  var dataList = await db.getFavoriteImages();
  return dataList;
}

class FavoriteImages extends StatefulWidget {
  @override
  FavoriteImagesState createState() => new FavoriteImagesState();
}

class FavoriteImagesState extends State<FavoriteImages> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
       appBar: AppBar(
         title: Text("My favorite images"),
       ),
       body: FutureBuilder<List<ApodImage>>(
        future: fetchFavoriteImages(),
        builder: (context, snapshot) {
          if (snapshot.hasError){
            print(snapshot.error);
          }

          return snapshot.hasData && snapshot.data != null
              ? FavortiveImageList(favoriteImages: snapshot.data)
              : Center(child: Text("You have not farvorited any image yet."));
        }
      )
    );
  }
}

class FavortiveImageList extends StatefulWidget {
  final List<ApodImage> favoriteImages;
  const FavortiveImageList({Key key, @required this.favoriteImages}) : super(key: key);

  @override
  FavortiveImageListState createState() => new FavortiveImageListState();
}

class FavortiveImageListState extends State<FavortiveImageList> {

  @override
   Widget build(BuildContext context){
     return ListView.builder(
         padding: const EdgeInsets.all(16.0),
         itemExtent: 250.0,
         itemCount: widget.favoriteImages.length,
         itemBuilder: (context, i) {
           final item = widget.favoriteImages[i];
           return Dismissible(
              key: Key("${item.date}"),
              onDismissed: (direction) async {
                var db = FavoriteProvider();
                await db.delete(item.date);
                setState(() {
                  widget.favoriteImages.removeAt(i);
                });
              },
              child: ApodFavoritedElement(apodImage: item),
            );
         }
       );
   }
}

class ApodFavoritedElement extends StatefulWidget {
  final ApodImage apodImage;
  const ApodFavoritedElement({Key key, @required this.apodImage}) : super(key: key);

  @override
  ApodFavoritedElementState createState() => new ApodFavoritedElementState();
}

class ApodFavoritedElementState extends State<ApodFavoritedElement>{
  var present = new DateTime.now();
  var db = FavoriteProvider();
  var _isSaving = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Wrap(
       children: <Widget>[
         ListTile(
           title: Text(
             widget.apodImage.copyright != '' ? "${widget.apodImage.copyright}":"Unknow",
             style: TextStyle(
               fontWeight: FontWeight.bold,
             )
           ),
           subtitle: Text("${widget.apodImage.date}"),
           trailing:IconButton(
              icon: _isSaving ? CircularProgressIndicator() : Icon(Icons.get_app),
              onPressed: () async {
                setState(() {
                  _isSaving = true;
                });
                var imagePath = await saveNetworkImage(widget.apodImage.url, DateTime.parse(widget.apodImage.date));
                setState(() {
                  _isSaving = false;
                });
              }
            ),
         ),
         Center(
           child: GestureDetector(
             child: FadeInImage.assetNetwork(
               placeholder: 'assets/loading.gif',
               image: "${widget.apodImage.url}"),
               onTap: () {
                   Navigator.push(
                       context,
                       MaterialPageRoute(builder: (context) => ApodDetail(apodImage: widget.apodImage)),
                     );
                   }
                 )
              )
          ],
        )
      );
  }
}
