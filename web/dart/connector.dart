/*
 * Tangible Spark
 */
part of TangibleSpark;



/**
 * A multi-way connector for components.
 */
class Connector {

  num x = 0, y = 0, radius = 0;

  Component parent;

  List<Connector> attached = new List<Connector>();

  /* node associates the corresponding node in the circuit/graph analysis */ 
  Node node = null;  
  Connector(this.parent);


  void clear() {
    attached.clear();
  }

  List toJSON() {
    List json = new List();
    for (Connector other in attached) {
      json.add(
        {
          "from" : parent.id,
          "to" : other.parent.id,
          "type": getJointType(this, other)
        }
      );
    }
    return json;
  }


  bool isRightJoint() {
    return (parent.rightJoint == this);
  }

  bool isLeftJoint() {
    return (parent.leftJoint == this);
  }

  bool isConnected() {
    return attached.isNotEmpty;
  }


  bool isConnectedTo(Component c) {
    return (attached.contains(c.leftJoint) || attached.contains(c.rightJoint));
  }


  bool overlaps(Connector other) {
    return sqrt((other.x - x) * (other.x - x) + (other.y - y) * (other.y - y)) < radius * 2.5;
  }


  bool connect(Connector other) {
    if (other.parent != parent && overlaps(other) && !isConnectedTo(other.parent)) {
      attached.add(other);
      other.attached.add(this);
      return true;
    } else {
      return false;
    }
  }

  int getJointType(Connector a, Connector b) {
    if (!a.attached.contains(b)){
      return 0;
    }
    if (a.isLeftJoint() && b.isLeftJoint()){
      return 1;
    }
    else if (a.isRightJoint() && b.isRightJoint()){
      return 2;
    }
    else if (a.isLeftJoint() && b.isRightJoint()){
      return 3;
    }
    else {
      return 4;
    }
  }
  
  void draw(CanvasRenderingContext2D ctx) {
    ctx.fillStyle = isConnected() ? "rgba(0, 255, 0, 0.5)" : "rgba(255, 0, 0, 0.5)";
    ctx.beginPath();
    ctx.arc(x, y, radius, 0, PI * 2, true);
    ctx.fill();
  }
}  
