/*
 * Tangible Spark
 */

 // About to commit false changes

library TangibleSpark;

import 'dart:html';
import 'dart:math';
import 'dart:async';
import 'dart:convert';
import 'dart:js';

part 'component.dart';
part 'connector.dart';
part 'scanner.dart';
part 'topcode.dart';
part 'utils.dart';

part 'circuitAnalyzer/circuit.dart';
part 'circuitAnalyzer/Matrix.dart';
part 'circuitAnalyzer/LUDecomposition.dart';
part 'circuitAnalyzer/QRDecomposition.dart';
part 'circuitAnalyzer/KVLSolver.dart';


// IMPORTANT! This has to match js/video.js
const VIDEO_WIDTH = 1280; //1920; // 1280; // 800
const VIDEO_HEIGHT = 720; // 1080; // 720; // 600

Spark spark;

void main() {
  spark = new Spark();

  /* added a button to run the circuit.solve() code everytime that is clicked */
  ButtonElement button = document.querySelector("#analyzer-button");
  if (button != null) button.onClick.listen((evt) => spark.circuit.init());
}


class Spark {
  
  /* <canvas> tag drawing context */
  CanvasRenderingContext2D ctx;

  /* this is going to find all of our physical components */
  Scanner scanner;

  /* we need this to do the computer vision work */
  VideoElement video = null;

  Timer timer;
  Timer refreshTimer;

  List<Component> components = new List<Component>();
  /* not using this list of connecters, as the circuit has its own list */
  //List<Connector> connectors = new List<Connector>();

  Circuit circuit = new Circuit();


  
  Spark() {
    /* init pubnub for sending data to parse */
    context.callMethod('initPubnub', []);

    CanvasElement canvas = querySelector("#video-canvas");
    ctx = canvas.getContext("2d");
    scanner = new Scanner();
    video = querySelector("#video-stream");
    video.autoplay = true;
    video.onPlay.listen((e) {
      timer = new Timer.periodic(const Duration(milliseconds : 120), refreshCanvas);
      /* refresh timer is added to reload the page and prevent the crashing problem */
      refreshTimer = new Timer.periodic(const Duration(seconds : 60), refreshPage);
    });

    // initialize our components
    List clist = JSON.decode(querySelector('#components-definition').innerHtml);
    for (var def in clist) {
      components.add(new Component(def));
    }
  }


/**
 * Stop the video stream.
 *  Note: it's possible to stop the video from dart, but we probably won't need this...
 */
  void stopVideo() {
    video.pause();
    if (timer != null) timer.cancel();
  }

/*
 * Called every t=45 seconds 
 */
  void refreshPage(Timer refreshTimer) {
    refreshTimer.cancel();
    window.location.reload();
  }

/*
 * Called (1000/timer = 8) frames a second while the camera is on
 */
  void refreshCanvas(Timer timer) {

    // javascript will change this class name as a signal to dart to stop scanning
    if (video.className == "stopped") {
      timer.cancel();
      print("stopping scan");
      return;
    }


    // draw a frame from the video stream onto the canvas (flipped horizontally)
    ctx.save();
    {
      ctx.translate(video.videoWidth, 0);
      ctx.scale(-1, 1);
      ctx.drawImage(video, 0, 0);
    }
    ctx.restore();


    // grab a bitmap from the canvas
    ImageData id = ctx.getImageData(0, 0, video.videoWidth, video.videoHeight);
    List<TopCode> codes = scanner.scan(id, ctx);

    //if ( codes.length > 0 ) print(codes[0].radius);
    List<TopCode> filteredCodes = new List<TopCode>();
    for (TopCode top in codes) {
      //print(top.radius);
      // if (top.radius >= 16 && top.radius <= 17.5) {
      //   filteredCodes.add(top);
      // }
      //else print("this is a big code");
    }
    //if (codes.length != filteredCodes.length) {print("detected some big codes");}
    //print(filteredCodes.length);

    // first find visible components
    for (Component c in components) {
      c.locate(codes);
    }

    // next connect components
    //connectors.clear();
    for (int i=0; i<components.length; i++) {
      for (int j=i+1; j<components.length; j++) {
        if (components[i].visible && components[j].visible){
          components[i].connect(components[j]);
        }
      }
    }
    for (Component c in components) {
      if (c.visible) {
        // connectors.add(c.leftJoint);
        // connectors.add(c.rightJoint);
        // //print(c.leftJoint.adjustedPos);
        // //print(c.rightJoint.adjustedPos);
        // if (!c.leftJoint.adjustedPos) adjustPosition(c.leftJoint);
        // if (!c.rightJoint.adjustedPos) adjustPosition(c.rightJoint);
        c.draw(ctx);
      }
    }

    //exportJSON();
  }

  void exportJSON(){
    List componentJSON = new List();
    List connectorJSON = new List();

    for (Component c in components){
      if (c.visible) {
        componentJSON.add(c.toJSON());
        connectorJSON.addAll(c.leftJoint.toJSON());
        connectorJSON.addAll(c.rightJoint.toJSON());
      }
    }
    //print(JSON.encode(componentJSON));
    print(JSON.encode(connectorJSON));
    //print("hello world!");
  }

  void adjustPosition(Connector cp) {
    print("adjusting position");
   // List<num> xcor = new List<num>();
   // List<num> ycor = new List<num>();
   // xcor.add(cp.x);
   // ycor.add(cp.y);
   num xcor = cp.x;
   num ycor = cp.y;
   for (Connector cp2 in cp.attached) {
    xcor += cp2.x;
    ycor += cp2.y;
   }
   xcor /= (cp.attached.length + 1);
   ycor /= (cp.attached.length + 1);
   cp.x = xcor;
   cp.y =ycor;
   cp.adjustedPos = true;
  for (Connector cp2 in cp.attached) {
    cp2.x = xcor;
    cp2.y = ycor;
    cp2.adjustedPos = true;
   }
   
   //print(cp.x);
  }
  

}
  