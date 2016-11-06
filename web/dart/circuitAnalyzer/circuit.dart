
part of TangibleSpark;
/**
 *  circuit class implements a circuit analyzer based on Kirchhoff’s circuit laws
 *  to calculate the currents and voltage drops of each component. 
 *  The circuit analyzer runs every time that a change is introduced to the
circuit, which then updates and stores the new variables of each component. 
*/


class Circuit {
/* ------------------------
  Class variables
 * ------------------------ */
  List<Component> components;
  List<Connector> connectors;

  List<Edge> edges;
  List<Node> nodes;
  List<Loop> loops;
  num numCG = 0;
  num time;
  Matrix solution;
  //List<Battery> burntBatteries;
  //num maxCurrent = 20;



/* ------------------------
  Constructor
 * ------------------------ */

  Circuit() {
    // components = new List<Component>();
    // connectors = new List<Connector>();

    // nodes = new List<Node>();
    // edges = new List<Edge>();
    
  }

/* ------------------------
  Initiating the Circuit 
 * ------------------------ */
  void init() {
    components = new List<Component>();
    connectors = new List<Connector>();

    nodes = new List<Node>();
    edges = new List<Edge>();

    
    findCircuitComponents();
    for (Connector cp in this.connectors) {
      cp.adjustedPos = false;
      // print(cp.parent.id);
      // print(cp.node.adjacents.length);
      // print(cp.node.isCollapsed());
      // print(cp.attached.length);
    }
    print(nodes.length);
    makeCircuitConnections();
    print("solving the circuit");
    print(nodes.length);
    solve();
    sendData();
    spark.exportJSON();
  }

  void findCircuitComponents(){
    for (Component c in spark.components){
      if (c.visible) {
        this.addNewComponent(c);
        this.connectors.add(c.leftJoint);
        this.connectors.add(c.rightJoint);
      }
    }
  }

  void makeCircuitConnections(){
    for (Connector cp in this.connectors) {
      print("component:" + cp.parent.id);
      if (cp.isConnected()) {
        if (!cp.node.isCollapsed()) {
          collapseNode(cp, cp.attached[0]);
        }
        if (!cp.adjustedPos) adjustPosition(cp);
      }
    }
  }

  void addNewComponent( Component c) {
    this.components.add(c);
    addNewBranch(c);
  }

  void adjustPosition(Connector cp) {
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
  
/* ------------------------
  Solving the Circuit Methods
 * ------------------------ */
  /** solve the circuit, update the components' variables and send the JSON data to the server
   */  
  void solve() {
    resetGraph();
    findSpanningForest();
    var backEdges = edges.where((e) => e.label == 'back'); //note: backEdges is a "lazy" iterable
    for (Edge b in backEdges) {
       loops.add(findLoop(b));
    }
    
    KirchhoffSolver circuitSolver = new KirchhoffSolver(this);

    solution = circuitSolver.ApplySolver();
    for (int i=0; i < loops.length; i++) {
      loops[i].current = solution.get(i,0);
    }
    
    updateComponents();    
  }


  /** reset the graph to be revisited
   */  
  void resetGraph() {
    loops = new List<Loop>();
    for (Node n in nodes) {
      n.visited = false;
      n.parent = null;
      n.discoverTime = 0;
    }
    for (Edge e in edges) {
      e.loops = new List<Loop>();
      e.label = null;
    }
  }
   
  /** update the circuit variables of each component using the above solution. 
   */  
  void updateComponents () {
    for (Edge e in this.edges) {
      Component c = e.component;
      c.current = 0.0;
      for (Loop l in e.loops) {
        c.current += l.current;
      }
      c.direction = 0;
      if (c.current != 0) {
        c.direction = e.direction * c.current.sign;
      }
      c.current = c.current.abs();
      //if ( c.current > 0 ) { c.direction = 1; } // flow of electrons from start to end
      //else if ( c.current < 0 ) { c.direction = -1; } // flow of electrons from end to start
      //else { c.direction = 0; }
      
      if (c.type != "Battery")
       { c.voltageDrop = c.resistance * c.current; }
      // if (c.type == "Bulb") {
      //   if (c.current != 0.0 && !(c as Bulb).isOn) (c as Bulb).turnOn();
      //   if (c.current == 0.0 && (c as Bulb).isOn) (c as Bulb).turnOff();
      // }
      // if (c is Battery && c.current > maxCurrent) { // a short circuit
      //   (c as Battery).burn(); 
      //   burntBatteries.add(c as Battery);        
      // }
    }
  }
  
  /** create JSON data and send the string to the server
   * this method is called in one of these occurances:
   * 1. called by circuit.solve method, when a change in graph
   * 2. called by circuit.addNewBranch method, when a new component is added
   * 3. called by component.touchUp method, when componets are dragged OR components are deleted
   * 4. called by controlpoint.touchup method, when components are dragged or wire is extended
   * 5. called by marker.touchup method
   */
  void sendData() {
   
    
    //var myObj = new JsArray();
    var myObj = [];
    //findConnectedComponents();
    var c, connectionArray, rowArray;
    for (Edge e in this.edges) {
      c = e.component;
      connectionArray = createConnectionArray(c); 
      rowArray = [];
      for (int j = 0; j < connectionArray.length; j++) {
        if (connectionArray[j] == null) {connectionArray[j] = 0;}
        rowArray.add({
          j.toString(): connectionArray[j]
          
        });
      }

      //var offsetX = 680;
      //var offsetY = 320;
      var offsetX = 619;
      var offsetY = 334;
      var scaleFactor = 2.0;

      
      var compObj = {   'type': c.type,
                        'voltageDrop': c.voltageDrop,
                        'current': c.current,
                        'resistance': c.resistance,
                        'startX': scaleFactor*(c.leftJoint.x - offsetX),
                        'startY':scaleFactor*(c.leftJoint.y - offsetY),
                        'endX': scaleFactor*(c.rightJoint.x - offsetX),
                        'endY': scaleFactor*(c.rightJoint.y - offsetY),
                        'direction': c.direction,
                        'connection': rowArray,
                        'graphLabel': e.nodes[0].graphLabel
                        };
      
        myObj.add(compObj);


    }
    //print(JSON.encode(myObj));
    
    
    //JsObject.jsify() constructor convert a JSON-like Dart object to a JS object
    myObj = new JsObject.jsify(myObj);
    
    
    // send data to parse
    print("send data");
    //print(JSON.encode(myObj));
    // call the "doDeleteParse method on myObj (the code is in sendData.js)
    var sendParse = new JsObject(context['sendParse'],[myObj]); // instantiate a JS "deleteParse" object
    sendParse.callMethod('doUpdateParse'); // call its method "doUpdateParse"
    //sendParse.callMethod('doUpdateParse');
  }
  
  /** called to create the array of codes for the component connections status
  @param c    component
  @return     List<int>: -1 -> diagonal (cj is c)
  *                       0 -> not connected with cj
  *                       1 -> s is connected to cj's s
  *                       2 -> e is connected to cj's e
  *                       3 -> s is connected to cj's e
  *                       4 -> e is connected to cj's s 
  */  
  
  List<int> createConnectionArray( Component c ) {
    
    var array = new List(this.components.length); // creates an array of 0 with a fixed length of # of components
    int index = this.components.indexOf(c);
    array[index] = -1;
    List<Connector> sList = c.leftJoint.attached;
    for (Connector cp in sList) {
      var c2 = cp.parent;
      if (c2.leftJoint == cp) {
        array[this.components.indexOf(c2)] = 1;
      }
      else {
        array[this.components.indexOf(c2)] = 3;
      }
    }
    List<Connector> eList = c.rightJoint.attached;
    for (Connector cp in eList) {
      var c2 = cp.parent;
      if (c2.rightJoint == cp) {
        array[this.components.indexOf(c2)] = 2;
      }
      else {
        array[this.components.indexOf(c2)] = 4;
      }
    }
    return array;
        
  }
/* ------------------------
  Reflecting the touch changes into the circuit graph representation
 * ------------------------ */  
  /** called when a new component is added
  @param c    component
  @return     void
  */
  
  void addNewBranch (Component c) {
    Node n1 = new Node();
    c.leftJoint.node = n1;
    Node n2 = new Node();
    c.rightJoint.node = n2;
    Edge e = new Edge(n1, n2);
    e.component = c;
    
    nodes.add(n1);
    nodes.add(n2);
    edges.add(e);
    
    n1.adjacents.add(n2);
    n2.adjacents.add(n1);
    findSpanningForest();    
  }
  
  /** remove a branch. For now, a branch can be removed only when it is disconnected.
  @param b    branch to be removed
  @return     void
  */

  void removeBranch (Component c) {
    Node n1 = c.leftJoint.node;
    Node n2 = c.rightJoint.node;
    Edge e = getEdge(n1, n2); 
    this.nodes.remove(n1);
    this.nodes.remove(n2);
    this.edges.remove(e);
    findSpanningForest();
    //sendData(); // no need to call it here, send data is done in the touchup function    
  }
 
  
  /** when two nodes are connected, unite the nodes into one joint node and then remove the old node.
  @param dragged    first cp whose node is going to be collapsed
  @param other    second cp whose node is going to be collapsed
  @return     void
  */
  
  void collapseNode( Connector dragged, Connector other ) {
    Node old1 = dragged.node;
    Node old2 = other.node;
    Node newNode = new Node();
    newNode.adjacents.addAll(old1.adjacents);
    newNode.adjacents.addAll(old2.adjacents);
    //newNode.isCollapsed = true;
   
    
    dragged.node = newNode;
    other.node = newNode;
    // for (Connector cp in dragged.attached) {
    //   cp.node = newNode;
    // }
    
    for (Node n in old1.adjacents) {
      Edge e = getEdge(old1, n);
      if ( e.nodes[0] == old1 ) { e.nodes[0] = newNode; }
      else { e.nodes[1] = newNode; }
      n.adjacents.remove(old1);
      n.adjacents.add(newNode);
    }
    
    for (Node n in old2.adjacents) {
      Edge e = getEdge(old2, n);
      if ( e.nodes[0] == old2 ) { e.nodes[0] = newNode; }
      else { e.nodes[1] = newNode; }
      n.adjacents.remove(old2);
      n.adjacents.add(newNode);
    }
    
    nodes.remove(old1);
    nodes.remove(old2);
    nodes.add(newNode);
    
    //burntBatteries = new List<Battery>();
    //this.solve();
    /* remove the burnt batteries from the graph */
//    for (Battery bb in burntBatteries) {
//      Node n1 = bb.leftJoint.node;
//      Node n2 = bb.rightJoint.node;
//      Edge e = getEdge(n1, n2); 
//      this.edges.remove(e);
//      n1.adjacents.remove(n2);
//      n2.adjacents.remove(n1);     
//    }
    // if (!burntBatteries.isEmpty) {
    //   this.solve();
    // }
    
    //Sounds.playSound("ping");

  }
  
  /** split one node into two nodes and then remove the joint node
  @param cp    the component's control point that is going to be split
  @return     void
  */
  
  void splitNode (Connector dragged, Connector other) {
    Node newNode = new Node();
    dragged.node = newNode;
    other.node.adjacents.remove(dragged.myConjoint.node);
    newNode.adjacents.add(dragged.myConjoint.node);
    dragged.myConjoint.node.adjacents.add(newNode);
    dragged.myConjoint.node.adjacents.remove(other.node);
    Edge e = getEdge(other.node, dragged.myConjoint.node);
    if (e.nodes[0] == dragged.myConjoint.node) e.nodes[1] = newNode;
    else e.nodes[0] = newNode; 
    
    nodes.add(newNode);
    this.solve();
    
  }
/* ------------------------
  Graph Methods
 * ------------------------ */  
  /** find the edge for the two given nodes. The edge must exist otherwise it gives an error 
   @param list of edges
   @param first node
   @param second node
   @return edge
   */
  Edge getEdge(Node n1, Node n2) {
    return this.edges.singleWhere((e) => (e.nodes.contains(n1) && e.nodes.contains(n2)));
  }
  
  /** Depth-first search for finding a spanning forest of the circuit graph
  @param  nodes
  @return 
  */
  void findSpanningForest () {
    for (Edge e in this.edges) {
      e.label = 'back';
    }
    for (Node n in this.nodes) {
      n.visited = false;
      n.discoverTime = 0;
      n.parent = null;
    }
    this.numCG = 0;
    time = 0;
    for (Node n in this.nodes) {
      if (!n.visited) {      
        DFSVisit(n);
        this.numCG++;
      }
    }
  }
  
  void DFSVisit(Node u) {
    u.graphLabel = this.numCG;
    u.visited = true;
    u.discoverTime = time++;
    for (Node v in u.adjacents) {
      if (!v.visited) {
        getEdge(u, v).label = 'tree'; // mark edge as a tree edge
        v.parent = u;
        v.visited = true; 
        DFSVisit(v);
      }
    }
  }
  
  /** Given the back edge, find the corresponding loop 
  @param  Edge back edge
  @return Loop one loop containing the back edge
  */  
  Loop findLoop(Edge b) {
    Loop l = new Loop();
    Node start = b.nodes[0];
    Node end = b.nodes[1];
    b.direction = -1;
    if (start.discoverTime < end.discoverTime) {
      start = b.nodes[1];
      end = b.nodes[0];
      b.direction = 1;
    }     
    while (start != end) {
      Edge e = getEdge(start, start.parent);
      // this is for deciding the direction of edge for later calculations of current.
      if (e.nodes[0] == start) {
        e.direction = 1;
      } else {
        e.direction = -1;
      }
      l.path.add(e);
      e.loops.add(l);
      start = start.parent;     
    }
    l.path.add(b);
    b.loops.add(l);
    return l;
  }
  
  void printGraph() {
    var obj = [];
    var s;
    for (Node n in nodes) {
      var p = n.parent;
        s = {
             'node': nodes.indexOf(n),
             'number of adjacents': n.adjacents.length,
             'visited': n.visited,
             'discover time': n.discoverTime,
             'parent': (n.parent == null ? 'null' : nodes.indexOf(n.parent)),
             'CG label': n.graphLabel

        };
    obj.add(s);
  }

    for (Edge e in edges){
        s = {
             //'loop': i,
             'edge label': e.label,
             'first': nodes.indexOf(e.nodes[0]),
             'second': nodes.indexOf(e.nodes[1]),
             'component': e.component.type
        };
      obj.add(s);
    }
  //}
    //print(JSON.encode(obj));
  }
}
/** ------------------------
  Loop Class: it creates a path in the form of list of nodes
 * ------------------------ */
class Loop {
  num current;
  List<Edge> path;
  
  Loop () {
    path = new List<Edge>();
    current = 0;
  }
}



/** ------------------------
  Edge Class
 * ------------------------ */
class Edge {
  List<Node> nodes;
  String label; // label is either 'tree' or 'back'
  List<Loop> loops;
  Component component;
  num direction = 0;
  
  Edge (Node first, Node second)
  {
    nodes = [first, second];
    loops = new List<Loop>();
    label = null;
  }
}
/** ------------------------
  Node Class
 * ------------------------ */
class Node{ 
  num graphLabel; //this label indicated what connected graph this node belongs to.
  bool visited; 
  num discoverTime;
  Node parent;
  List<Node> adjacents;
  //bool isCollapsed = false;

  Node() {
    adjacents = new List<Node>();
    visited = false;
    parent = null;
  }
  
  bool get isVisited => visited;

  /* new function for tangible code */
  bool isCollapsed() {
    return adjacents.length > 1; // each node always have 1 adjacent from its parent. If more than that then it's connected
  }
}