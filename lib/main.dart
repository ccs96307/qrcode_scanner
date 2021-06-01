import 'dart:io';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:url_launcher/url_launcher.dart';

// Main
void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: QRViewPage(),
    ),
  );
}

// Main page
class QRViewPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _QRViewPageState();
}

// _QRViewPage
class _QRViewPageState extends State<QRViewPage> {
  // Init
  Barcode? result;
  bool _resultExist = false;
  QRViewController? controller;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');

  // Zoom
  double _zoomValue = 1.0;

  // Regex
  // final RegExp smsFormat = RegExp("[smsto|SMSTO]");

  // Color settings
  Color _backgroundColor = Colors.white;
  Color _qrCodeBorderColor = Colors.white;
  Color _slideActiveBarColor = Colors.grey.shade800;
  Color _slideDeactiveBarColor = Colors.grey;
  Color _buttonUnclickedColor = Colors.white;
  Color _buttonClickedColor = Colors.grey.shade800;
  Color _buttonBorderColor = Colors.grey.shade800;
  Color _iconUnclickedColor = Colors.grey.shade800;
  Color _iconClickedColor = Colors.white;
  bool _flash = false;
  bool _rotation = false;

  // In order to get hot reload to work we need to pause the camera if the platform
  // is android, or resume the camera if the platform is iOS.
  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller!.pauseCamera();
    }
    controller!.resumeCamera();
  }

  @override
  Widget build(BuildContext context) {
    // Hide status bar
    // SystemChrome.setEnabledSystemUIOverlays([]);

    return Scaffold(
      body: Column(
        children: <Widget>[
          Expanded(flex: 7, child: _buildQrView(context)),
          Expanded(
            flex: 1,
            child: Container(
              color: _backgroundColor,
              child: Column(
                children: <Widget>[
                  SizedBox(
                    height: 10.0,
                  ),
                  // Expanded(
                  //   flex: 1,
                  //   child: Container(
                  //     color: Colors.white,
                  //     child: _resultExist
                  //         ? Text("${result!.code}")
                  //         : Text("No Data")
                  //   ),
                  // ),
                  Expanded(
                    flex: 1,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30.0),
                            ),
                            primary: _flash ? _buttonClickedColor : _buttonUnclickedColor,
                            onPrimary: Colors.white,
                            side: BorderSide(
                              width: 1.0,
                              color: _buttonBorderColor,
                            ),
                          ),
                          child: Icon(
                            Icons.lightbulb_outline,
                            color: _flash ? _iconClickedColor : _iconUnclickedColor,
                          ),
                          onPressed: () async {
                            await controller?.toggleFlash();
                            setState(() {
                              _flash = !_flash;
                            });
                          },
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30.0),
                            ),
                            primary: _rotation ? _buttonClickedColor : _buttonUnclickedColor,
                            onPrimary: Colors.white,
                            side: BorderSide(
                              width: 1.0,
                              color: _buttonBorderColor,
                            ),
                          ),
                          child: Icon(
                            Icons.rotate_90_degrees_ccw,
                            color: _rotation ? _iconClickedColor : _iconUnclickedColor,
                          ),
                          onPressed: () async {
                            await controller?.flipCamera();
                            setState(() {
                              _rotation = !_rotation;
                            });
                          },
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30.0),
                            ),
                            primary: _buttonUnclickedColor,
                            onPrimary: Colors.white,
                            side: BorderSide(
                              width: 1.0,
                              color: _buttonBorderColor,
                            ),
                          ),
                          child: Icon(
                            Icons.info_outline,
                            color: _iconUnclickedColor,
                          ),
                          onPressed: () {
                            setState(() async {
                              showAlertDialog(
                                context,
                                "QR Code Scanner v1.0.0",
                                "Copyright © 2021 Clay.\nall rights reserved.\n\nMore info: clay-atlas.com",
                              );
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Slider(
                        value: _zoomValue,
                        min: 0.1,
                        max: 2.0,
                        divisions: 6,
                        activeColor: _slideActiveBarColor,
                        inactiveColor: _slideDeactiveBarColor,
                        label: ((_zoomValue*10).toInt()/10).toDouble().toString(),
                        onChanged: (double value) {
                          setState(() {
                            _zoomValue = value;
                          });
                        }
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildQrView(BuildContext context) {
    // For this example we check how width or tall the device is and change the scanArea and overlay accordingly.
    var scanArea = (MediaQuery.of(context).size.width < 400 ||
        MediaQuery.of(context).size.height < 400)
        ? MediaQuery.of(context).size.width/(3.0-_zoomValue)
        : MediaQuery.of(context).size.width/(3.0-_zoomValue);
    // To ensure the Scanner view is properly sizes after rotation
    // we need to listen for Flutter SizeChanged notification and update controller
    return QRView(
      key: qrKey,
      onQRViewCreated: _onQRViewCreated,
      overlay: QrScannerOverlayShape(
          borderColor: _qrCodeBorderColor,
          borderRadius: 10,
          borderLength: 30,
          borderWidth: 10,
          cutOutSize: scanArea),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });
    controller.scannedDataStream.listen((scanData) {
      setState(() {
        result = scanData;
        _resultExist = true;
        _launchURL();
      });
    });
  }

  void _launchURL() async {
    String openData = result!.code;
    String openDataKeyword = openData.length > 5
          ? openData.substring(0, 5)
          : "00000";

    if (openDataKeyword == "smsto" || openDataKeyword == "SMSTO") {
      List<String> items = openData.split(':');
      openData = "sms:" + items[1] + "?body=" + items[2];
    }

    await canLaunch(openData)
        ? await launch(openData)
        // : await showToastMessage(openData);
        : throw "Could not launch $openData";
  }


  showToastMessage(String openData) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text("Could not launch $openData"),
    ));
  }


  // Show AlertDialog
  showAlertDialog(BuildContext context, String title, String content) {
    // Init
    AlertDialog dialog = AlertDialog(
      title: Text(
        title,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Text(
        content,
        style: TextStyle(
          color: Colors.white,
          // fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: _slideActiveBarColor.withOpacity(0.8),
      shape: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      actions: [
        Center(
          child: SizedBox(
            width: double.infinity, // <-- match_parent
            child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                  primary: _slideActiveBarColor.withOpacity(0.8),
                  onPrimary: Colors.white,
                  side: BorderSide(
                    width: 1.0,
                    color: Colors.grey,
                  ),
                ),

                child: Text(
                  "OK",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                }),
          ),
        ),
      ],
    );

    // Show the dialog (showDialog() => showGeneralDialog())
    showGeneralDialog(
      barrierColor: Colors.black.withOpacity(0.6),
      context: context,
      pageBuilder: (context, anim1, anim2) {
        return Wrap();
      },
      barrierDismissible: false,
      transitionBuilder: (context, anim1, anim2, child) {
        return Transform(
          transform: Matrix4.translationValues(
            0.0,
            (1.0 - Curves.ease.transform(anim1.value)) * 100,
            0.0,
          ),
          child: Opacity(
            opacity: Curves.easeInOutQuad.transform(anim1.value),
            child: dialog,
          ),
        );
      },
      transitionDuration: Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}