import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_advanced_networkimage/flutter_advanced_networkimage.dart';
import 'package:flutter_advanced_networkimage/zoomable_widget.dart';
import 'package:flutter_advanced_networkimage/transition_to_image.dart';
import 'package:flutter_custom_tabs/flutter_custom_tabs.dart';

import 'package:simplexkcd/xkcd.dart';

class ViewerPage extends StatefulWidget {
  final Xkcd xkcd;

  ViewerPage({Key key, @required this.xkcd}) : super(key: key);

  @override
  _ViewerPageState createState() => _ViewerPageState(xkcd: xkcd);
}

class _ViewerPageState extends State<ViewerPage> {
  final Xkcd xkcd;
  final _scaffoldKey = new GlobalKey<ScaffoldState>();
  VoidCallback _showBottomSheetCallback;

  _ViewerPageState({@required this.xkcd});

  @override
  void initState() {
    super.initState();
    _showBottomSheetCallback = _showBottomSheet;
  }

  String getAltString(String alt) {
    var encoded = latin1.encode(alt);
    return utf8.decode(encoded);
  } 

  void _showBottomSheet() {
    setState(() { // disable the button
      _showBottomSheetCallback = null;
    });
    _scaffoldKey.currentState.showBottomSheet<void>((BuildContext context) {
      return Container(
        height: 350.0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                xkcd.safeTitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22.0
                ),
              ),
            ),
            new Padding(
              padding: EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
              child: Text(
                getAltString(xkcd.alt),
                textAlign: TextAlign.center,
              ),
            ),
            new ListTile(
              leading: new Icon(Icons.lightbulb_outline),
              title: new Text('Explain This'),
              onTap: () { _launchExplainer(context); },          
            ),
          ],
        ),
      );
    }).closed.whenComplete(() {
      if (mounted) {
        setState(() {
          _showBottomSheetCallback = _showBottomSheet;
        });
      }
    });
  }

  _launchExplainer(BuildContext context) async {
    try {
      if (xkcd != null) {
        String url = 'https://www.explainxkcd.com/wiki/index.php/${xkcd.number}';
        await launch(
          url,
          option: CustomTabsOption(
            toolbarColor: Theme.of(context).primaryColor,
            enableDefaultShare: true,
            enableUrlBarHiding: true,
            showPageTitle: true,
            animation: new CustomTabsAnimation.slideIn()
          )
        );
      }
    } catch (e) {
      debugPrint(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(xkcd.safeTitle),
        backgroundColor: Colors.black,
      ),
      body: GestureDetector(
        onTap: _showBottomSheetCallback,
        child: Container(
          color: Colors.black,
          child: ZoomableWidget(
            maxScale: 3.0,
            minScale: 0.3,
            panLimit: 3.0,
            child: Container(
              child: TransitionToImage(
                AdvancedNetworkImage(xkcd.img, timeoutDuration: Duration(minutes: 1)),
                placeholder: CircularProgressIndicator()
              ),
            )
          ),
        )
      )
    );
  }
}