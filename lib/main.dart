import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_swiper/flutter_swiper.dart';
import 'package:flutter_advanced_networkimage/flutter_advanced_networkimage.dart';
import 'package:flutter_advanced_networkimage/zoomable_widget.dart';
import 'package:flutter_advanced_networkimage/transition_to_image.dart';
import 'package:firebase_admob/firebase_admob.dart';

import 'package:simplexkcd/xkcd.dart';
import 'package:simplexkcd/viewer.dart';

void main() => runApp(MaterialApp(
  title: 'Simple xkcd',
  home: MyApp(),
  theme: new ThemeData(
    pageTransitionsTheme: PageTransitionsTheme(
      builders: <TargetPlatform, PageTransitionsBuilder>{
        TargetPlatform.android: CupertinoPageTransitionsBuilder()
      }
    )
  ),
));

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  BannerAd _bannerAd;
  static final MobileAdTargetingInfo targetingInfo = MobileAdTargetingInfo(
    testDevices: <String>['48c1da960104', '035ADE0AF3F9B8BA1A5041774B1F8C67']
  );
  BannerAd createBannerAd() {
    return BannerAd(
      adUnitId: 'ca-app-pub-4056098139575656/2494997759',
      targetingInfo: targetingInfo,
      size: AdSize.smartBanner
    );
  }

  List<Xkcd> xkcdObjects = [];
  Xkcd generatedRandomComic;
  int currentIndex = 0;
  int currentNumber = 2;
  int currentTab = 0;

  static Xkcd parseXkcd(String responseBody) {
    return Xkcd.fromJson(json.decode(responseBody));
  }

  Future<Xkcd> fetchLatest() async {
    final response = await http.get('http://xkcd.com/info.0.json');

    return compute(parseXkcd, response.body);
  }

  Future<Xkcd> fetchPrevious(int number) async {
    final response = await http.get('http://xkcd.com/$number/info.0.json');

    return compute(parseXkcd, response.body);
  }

  void _onIndexChanged(int number) {
    if (number > currentIndex) {
      if (xkcdObjects.length == number) {
        setState(() { currentIndex = number; });
        fetchPrevious(xkcdObjects[number - 1].number - 1).then((onValue) {
          if (mounted) {
            setState(() {
              xkcdObjects.add(onValue);
              currentNumber = currentNumber + 1;
            });
          }
        });
      }
    }
  }

  void _onComicTap(int index, context) {
    Xkcd getComic = xkcdObjects[index];
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ViewerPage(xkcd: getComic))
    );
  }

  Widget getBody() {
    if (currentTab == 0) {
      return Swiper(
        itemBuilder: (BuildContext context, int index){
          if (xkcdObjects.length > 0 && (xkcdObjects.length > index)) {
            return Container(
              child: TransitionToImage(
                AdvancedNetworkImage(xkcdObjects[index].img, timeoutDuration: Duration(minutes: 1)),
                placeholder: CircularProgressIndicator()
              ),
            );
          } else {
            return Center(child: new CircularProgressIndicator());
          }
        },
        loop: false,
        onIndexChanged: _onIndexChanged,
        itemCount: currentNumber,
        onTap: (index) {
          _onComicTap(index, context);
        },
      );
    } else {
      return Stack(
        fit: StackFit.expand,
        children: <Widget>[
          getRandomComic(),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.only(bottom: 60.0),
              child: FloatingActionButton(
                onPressed: () {
                  setState(() {
                    generatedRandomComic = null;                    
                  });
                },
                tooltip: 'Generate',
                child: Icon(Icons.shuffle),
              ),
            )
          )
        ],
      );
    }
  }

  Widget getRandomComic() {
    Xkcd latestComic = xkcdObjects[0];
    if (generatedRandomComic != null) {
      return ZoomableWidget(
        maxScale: 3.0,
        minScale: 0.3,
        panLimit: 3.0,
        child: Container(
          child: TransitionToImage(
            AdvancedNetworkImage(generatedRandomComic.img, timeoutDuration: Duration(minutes: 1)),
            placeholder: CircularProgressIndicator()
          ),
        )
      );
    } else {
      _generateRandom(latestComic);
      return Center(child: Text('Hold up...'),);
    }
  }

  void _generateRandom(Xkcd latest) {
    var rng = new Random();
    int generatedNumber = rng.nextInt(latest.number);
    fetchPrevious(generatedNumber).then((onValue) {
      setState(() {
        generatedRandomComic = onValue;      
      });
    });
  }

  void _onBottomTabTapped(int index) {
    setState(() {
      currentTab = index;
    });
  }

  @override
  void dispose() {
    _bannerAd.dispose();
    super.dispose();
  }

  @override
  void initState() {
    fetchLatest().then((onValue) {
      if (this.mounted) {
        setState(() { 
          xkcdObjects.add(onValue);
          currentNumber = currentNumber + 1;
        });
      }
    });
    super.initState();

    FirebaseAdMob.instance.initialize(appId: 'ca-app-pub-4056098139575656~6402453173');
    // _bannerAd = createBannerAd()..load()..show(anchorType: AnchorType.bottom, anchorOffset: 55.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Simple xkcd'),
      ),
      body: getBody(),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), title: Text('Home')),
          BottomNavigationBarItem(icon: Icon(Icons.shuffle), title: Text('Random'))
        ],
        currentIndex: currentTab,
        onTap: _onBottomTabTapped,
      ),
    );
  }
}