
import 'apod_object.dart';
import 'package:sqflite/sqflite.dart';

final String tableName = "favorite_images";

class FavoriteProvider {
  static Database dbInstance;

  Future<Database> get db async {
    if (dbInstance == null){
      dbInstance = await initDB();
    }
    return dbInstance;
 }

  initDB() async{
    var databasesPath = await getDatabasesPath();
    String path = '$databasesPath/Apod.db';
    var db = await openDatabase(path, version: 1,
            onCreate: (Database db, int version) async {
          await db.execute( "CREATE TABLE ${tableName} (copyright TEXT, date TEXT, hdurl TEXT, url TEXT, title TEXT, explanation TEXT, CONSTRAINT constraint_name UNIQUE (date))");
        });
    return db;
  }

  Future<ApodImage> insert(ApodImage apodImage) async {
    var dbConnection = await db;
    try {
      await dbConnection.transaction((txn) async {
        String sqlQuery = 'INSERT INTO ${tableName}(copyright, date, hdurl, url, title, explanation) VALUES("${apodImage.copyright}", "${apodImage.date}", "${apodImage.hdurl}", "${apodImage.url}", "${apodImage.title}", "${apodImage.explanation}")';
        await txn.rawInsert(sqlQuery);
      });
      return apodImage;
    } catch (e){
      return apodImage;
    }
  }

  Future<Null> delete(String date) async {
    var dbConnection = await db;
    await dbConnection.transaction((txn) async {
      String sqlQuery = 'DELETE FROM ${tableName} WHERE date = "${date}"';
      await txn.rawDelete(sqlQuery);
    });
  }

  Future <Null> getImageFromDate(String date) async {
    try {
      var dbConnection = await db;
      await dbConnection.transaction((txn) async {
      String sqlQuery = 'SELECT * FROM ${tableName} WHERE date = "${date}"';
      var data = await txn.rawQuery(sqlQuery);
      return ApodImage(
          copyright: data[0]['copyright'],
          date: data[0]['date'],
          hdurl: data[0]['hdurl'],
          url: data[0]['url'],
          title: data[0]['title'],
          explanation: data[0]['explanation']
          );
        }
      );
    } catch (e) {
      return null;
    }
  }

  Future <bool> isExist(String date) async {
    try {
      var data;
      var dbConnection = await db;
      await dbConnection.transaction((txn) async {
      String sqlQuery = 'SELECT * FROM ${tableName} WHERE date = "${date}"';
      data = await txn.rawQuery(sqlQuery);
        }
      );
      if (data.length == 0) {
        return false;
      } else if (data == null){
        return false;
      } else {
        return true;
      }
    } catch (e) {
      return false;
    }
  }

  Future<List> getFavoriteImages() async {
    var dbConnection = await db;
    String sqlQuery = "SELECT * FROM ${tableName}";
    List<Map> favoriteImages = await dbConnection.rawQuery(sqlQuery);
    List <ApodImage> apodImageList = new List();
    if (favoriteImages.length > 0) {
      for(int i=0; i < favoriteImages.length; i++){
        apodImageList.add(
          ApodImage(
            copyright: favoriteImages[i]['copyright'],
            date: favoriteImages[i]['date'],
            hdurl: favoriteImages[i]['hdurl'],
            url: favoriteImages[i]['url'],
            title: favoriteImages[i]['title'],
            explanation: favoriteImages[i]['explanation']
          )
        );
      }

      return apodImageList;
    }
    return null;
  }

  Future<List> getFavoriteImagesDate() async {
    var dbConnection = await db;
    String sqlQuery = "SELECT date FROM ${tableName}";
    List<Map> favoriteImages = await dbConnection.rawQuery(sqlQuery);
    List <String> favoriteImagesDate = new List();
    if (favoriteImages.length > 0) {
      for(int i=0; i < favoriteImages.length; i++){
        favoriteImagesDate.add(
            favoriteImages[i]['date'],
          );
      }
    return favoriteImagesDate;
    }
    return null;
  }

  Future close() async => dbInstance.close();
}
