import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' show Random;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:neat_periodic_task/neat_periodic_task.dart';

import 'package:photo_view/photo_view.dart';
import 'package:path_provider/path_provider.dart';
import 'package:network_to_file_image/network_to_file_image.dart';

import 'package:screen/screen.dart';

int version = 5115;

// Url of public folder in Mailru cloud
String mailru_url='https://cloud.mail.ru/public/NNNN/VVVVVVVVV';
String image_path='/_n0n-eXiStEnT';
String tmp_img_filename='netizen_pics.jpg';

String mailru_base='https://cloud.mail.ru/public/';

var randomizer; 

String real_url='https://img.imgsmail.ru/cloud/img/share.jpg';

List<String> pic_list =  [];

int xrnd_number=0;

File tmpFile;

get_filelist() async {

    List<String> directory_page;
    RegExp pic_regexp1 = new RegExp(r"weblink.*jpe?g", caseSensitive: false);
    RegExp pic_regexp2 = new RegExp(r'"weblink": "(.*)",', caseSensitive: false);

    Set<String> pic_set =  {};

    final response = await http.get(mailru_url);
    LineSplitter ls = new LineSplitter();
    directory_page = ls.convert(response.body);

    for (var i=0; i<directory_page.length; i++) {
        if (pic_regexp1.hasMatch(directory_page[i])) {
            var match = pic_regexp2.firstMatch(directory_page[i]);
            if (match != null) {
                pic_set.add(match.group(1));
            }
        }
    }

    pic_list = pic_set.toList();
}

get_real_pic_url(String urlpath) async {

    List<String> pic_page;
    RegExp weblink_regexp = new RegExp(r"weblink_get", caseSensitive: false);
    RegExp url_regexp = new RegExp(r'"url": "(.*)"', caseSensitive: false);

    String pub_url=mailru_base+urlpath;

    final response = await http.get(pub_url);
    LineSplitter ls = new LineSplitter();
    pic_page = ls.convert(response.body);

    bool start_flag=false;

    for (var i=0; i<pic_page.length; i++) {
        if (weblink_regexp.hasMatch(pic_page[i])) {
            start_flag=true;
        }
        if (start_flag==true) {
            if (url_regexp.hasMatch(pic_page[i])) {
                var match = url_regexp.firstMatch(pic_page[i]);
                if (match != null) {
                    String storage_url=match.group(1);
                    real_url=storage_url+"/"+urlpath;
                    return;
                }
            }
        }
    }
}


next_pic() async {

    tmpFile=new File(image_path);
    if(tmpFile.existsSync()) {
        tmpFile.deleteSync();
    }
    tmpFile=new File(image_path);

//    await get_filelist();
    xrnd_number=randomizer.nextInt(pic_list.length);
    String pic_urlpath=pic_list[xrnd_number];
    await get_real_pic_url(pic_urlpath);

    Screen.keepOn(true);
}

void main() {

  randomizer = new Random();

  get_filelist();

  final scheduler = NeatPeriodicTaskScheduler(
  interval: Duration(seconds: 180),
  name: 'netizen_pics',
  timeout: Duration(seconds: 30),
  task: () async => get_filelist(),
  minCycle: Duration(seconds: 30),
  );
  scheduler.start();

  runApp(MyApp());
}


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Netizen pics $version',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: MyHomePage(title: 'Netizen pics $version'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}




class _MyHomePageState extends State<MyHomePage> {
  Timer _refreshtimer;

  @override
  void initState() async {
    super.initState();

     Directory tempDir=await getApplicationDocumentsDirectory();
     String tempPath=tempDir.path;
     image_path=tempPath + '/' + tmp_img_filename;
     tmpFile=new File(image_path);

    _refreshtimer=Timer.periodic(Duration(seconds: 90),(Timer t) {
       setState(() {
         next_pic();
       });
    });
  }

  void _forceChangePic()  {

    setState(() {
      next_pic();
    });
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      body: new Center(
        child: PhotoView(
                 imageProvider: NetworkToFileImage(
                     url: real_url, 
                     file: tmpFile)
             )),
      floatingActionButton: new FloatingActionButton(
        onPressed: _forceChangePic,
        child: new Icon(Icons.add_a_photo),
      ),
    );
  }
}
