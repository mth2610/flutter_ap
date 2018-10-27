import 'dart:async';
import 'dart:io' as Io;
import 'package:image/image.dart';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission/permission.dart';

class SaveFile {
  Future<String> get _localPath async {
    final permissionResult = await Permission.requestPermissions([PermissionName.Storage]);
    final directory = await getExternalStorageDirectory();
    //final directory = await getApplicationDocumentsDirectory();
    // var files = directory.listSync().toList();
    // files.forEach((e) => print(e));
    return directory.path;
  }

  Future<Io.File> getImageFromNetwork(String url) async {

     var cacheManager = await CacheManager.getInstance();
     Io.File file = await cacheManager.getFile(url);
     return file;
   }

   Future<String> saveImage(String url, DateTime datetime) async {

    final file = await getImageFromNetwork(url);
    //retrieve local path for device
    var path = await _localPath;
    Image image = decodeImage(file.readAsBytesSync());

    //Image thumbnail = copyResize(image, 120);

    String imagePath = '$path/ApodImages/${datetime.year}_${datetime.month}_${datetime.day}_apod.png';
    Io.Directory imageDir = new Io.Directory('$path/ApodImages');
    if(!imageDir.existsSync()){
      imageDir.create();
    }
    Io.File imageFile = new Io.File(imagePath);

    if (!imageFile.existsSync()){
      imageFile..writeAsBytes(encodePng(image));
    } else {
      print("File exist");
    }

    // Save the thumbnail as a PNG.
    return imagePath;
  }
}

Future<String> saveNetworkImage(String url, DateTime datetime) {
  try{
     var imagePath = SaveFile().saveImage(url, datetime);
     return(imagePath);
  }
  on Error catch(e){
    print('Error has occured while saving');
  }
}
