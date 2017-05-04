import 'dart:io';

//final HOST = "10.102.3.124";
final PORT = 8000;


String circuitJSON = '{ "circuit" : [ "component1", "component2" ] }';


void main() {
  HttpServer.bind(InternetAddress.ANY_IP_V4, PORT).then((server) {

    server.listen((HttpRequest request) {
      switch (request.method) {
        case "GET":
          handleGet(request);
          break;
        case "POST":
          handlePost(request);
          break;
        default:
          handleGet(request);
      }
    });

    // print("Listening for GET and POST on $HOST:$PORT");
    print("Listening for GET and POST on $PORT");
  });
}


void handleGet(HttpRequest req) {
  HttpResponse res = req.response;
  addCorsHeaders(res);
  res.headers.add(HttpHeaders.CONTENT_TYPE, "application/json");
  res.write(circuitJSON);
  res.close();
}


void handlePost(HttpRequest req) {
  HttpResponse res = req.response;

  addCorsHeaders(res);
  req.listen((List<int> buffer) {
    StringBuffer sb = new StringBuffer();
    for (int i in buffer) sb.writeCharCode(i);
    print(sb.toString());
    circuitJSON = sb.toString();
    
    res.write('{ "status" : "success" }');
    res.close();
  });
}


void addCorsHeaders(HttpResponse res) {
  res.headers.add("Access-Control-Allow-Origin", "*");
  res.headers.add("Access-Control-Allow-Methods", "POST, GET, OPTIONS");
  res.headers.add("Access-Control-Allow-Headers", "Origin, X-Requested-With, Content-Type, Accept");
}

