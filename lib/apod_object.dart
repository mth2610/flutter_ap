import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

Future<ApodImage> getImageFromNasa(DateTime input_date) async {
  var formatter = new DateFormat('yyyy-MM-dd');
  String date = formatter.format(input_date);

  String url = 'https://api.nasa.gov/planetary/apod?api_key=DEMO_KEY&date=${date}';
  final response = await http.get(url);
  if (response.statusCode == 200) {
    // If the call to the server was successful, parse the JSON
    return ApodImage.fromJson(json.decode(response.body));
  } else {
    // If that call was not successful, throw an error.
    throw Exception('Failed to load image');
  }
}

Future<ApodImage> getImageFromFireBase(DateTime input_date) async {
  var formatter = new DateFormat('yyyy-MM-dd');
  String date = formatter.format(input_date);
  var data = await Firestore.instance.collection('images').where('date', isEqualTo: date).getDocuments();

  if (data.documents != []) {
    return ApodImage(
        copyright: data.documents[0]['copyright'],
        date: data.documents[0]['date'],
        hdurl: data.documents[0]['hdurl'],
        url: data.documents[0]['url'],
        title: data.documents[0]['title'],
        explanation: data.documents[0]['explanation']
       );
  } else {
    // If that call was not successful, throw an error.
    throw Exception('Failed to load image');
  }
}

class ApodImage {
   String copyright;
  final String date;
  final String hdurl;
  final String url;
  final String title;
  final String explanation;

  ApodImage({this.copyright, this.date, this.hdurl, this.url, this.title, this.explanation});

  factory ApodImage.fromJson(Map<String, dynamic> json) {
    return ApodImage(
      copyright: json['copyright'],
      date: json['date'],
      hdurl: json['hdurl'],
      url: json['url'],
      title: json['title'],
      explanation: json['explanation']
    );
  }

  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{
      copyright: copyright,
      date: date,
      hdurl: hdurl,
      url: url,
      title: title,
      explanation: explanation
    };
    return map;
  }
}
