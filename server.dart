/**
 * Simple websocket echo chamber that handles multiple clients.
 * Also doubles as an http file server
 */

import 'dart:io';
import 'package:http_server/http_server.dart';
import 'package:path/path.dart';


List<WebSocket> clients = new List<WebSocket>();

void handleMessage(var message) {
  broadcastMessage(message.toString());
}


void handleWebSocket(WebSocket socket) {
  clients.add(socket);
  socket.listen(handleMessage);
  print("Client connected.");
}


void broadcastMessage(String message) {
  for (int i = clients.length - 1; i >= 0; i--) {
    WebSocket client = clients[i];
    if (client != null && client.readyState == WebSocket.OPEN) {
      client.add(message);
    } else {
      print("Client disconnected.");
      clients.removeAt(i);
    }
  }
}


void main() {

  //int port = 80;
  //String addr = '129.105.185.186';
  int port = 8088;
  String addr = 'localhost';

  var pathToBuild = join(dirname(Platform.script.toFilePath()), ".");

  var staticFiles = new VirtualDirectory(pathToBuild);
  staticFiles.allowDirectoryListing = true;
  staticFiles.followLinks = true;

  //HttpServer.bind(InternetAddress.LOOPBACK_IP_V4, 8080);

  HttpServer.bind(addr, port)
    .then((HttpServer server) {

      print('Listening on $addr:$port');

      server.listen((HttpRequest request) {
        if (request.uri.path == '/ws') {
          WebSocketTransformer.upgrade(request).then(handleWebSocket);
        } else {
          staticFiles.serveRequest(request);
        }
      });
  });
}


