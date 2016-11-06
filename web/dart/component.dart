/*
 * Tangible Spark
 */
part of TangibleSpark;



/**
 * A base class for all electrical components. A component is
 * any element that can be connected in a circuit.
 */
class Component {


  /** Unique component ID */
  String id = "";

  /** Type of the component (e.g. resistor) */
  String type = 'Resistor';

  /** Left TopCode for this component */
  TopCode leftCode = new TopCode();
  TopCode rightCode = new TopCode();

  /** Connectors for this component */
  Connector leftJoint; //"start" in virtual code
  Connector rightJoint; //"end" in virtual code

  /** Is this component visible to the camera? */
  bool visible = false;

  /** direction determines the direction of current flow, 0, -1, or 1 */
  num direction = 0;

  double resistance;
  double current = 0.0;
  double voltageDrop;


  Component(Map definition) {
    id = definition['id'];
    type = definition['type'];
    leftCode.code = definition['left-code'];
    rightCode.code = definition['right-code'];
    resistance = definition['resistance'];
    voltageDrop = definition['voltageDrop'];
    leftJoint = new Connector(this);
    rightJoint = new Connector(this); 
  }


  bool isConnectedTo(Component other) {
    return (leftJoint.isConnectedTo(other) || rightJoint.isConnectedTo(other));
  }

  
/**
 * See if this component is visible to the camera by matching left or right 
 * topcode (or both).
 */
  void locate(List<TopCode> codes) {

    visible = false;

    bool foundLeft = false;
    bool foundRight = false;


    for (TopCode top in codes) {
      if (top.code == leftCode.code) {
        _initLocation(top, leftCode, rightCode);
        foundLeft = true;
        top.matched = true;
      }
      else if (top.code == rightCode.code) {
        _initLocation(top, rightCode, leftCode);
        foundRight = true;
        top.matched = true;
      }
    }

    // if we didnt' find both codes, we estimate the position of 
    // the opposite code based on the position of the first code
    if (foundLeft && !foundRight) {
      _copyTo(leftCode, rightCode, 3);
    }
    else if (foundRight && !foundLeft) {
      _copyTo(rightCode, leftCode, -3);
    }

    // fine tune orientations of the left and right code 
    if (foundLeft && foundRight) {
      num between = rightCode.angleBetween(leftCode);
      leftCode.orientation = between;
      rightCode.orientation = between;
    }

    // set connector positions
    {
      leftJoint.x = leftCode.targetX(-1, 0);
      leftJoint.y = leftCode.targetY(-1, 0);
      leftJoint.radius = leftCode.radius / 1.5;
      leftJoint.clear();
      rightJoint.x = rightCode.targetX(1, 0);
      rightJoint.y = rightCode.targetY(1, 0);
      rightJoint.radius = rightCode.radius / 1.5;
      rightJoint.clear();
    }
  }    


/**
 * Try to connect to this component if they aren't already connected
 */  
  bool connect(Component other) {

    // already connected!
    if (isConnectedTo(other)) return true;

    // try all four combinations for connections
    if (rightJoint.connect(other.rightJoint)) return true;
    if (rightJoint.connect(other.leftJoint)) return true;
    if (leftJoint.connect(other.rightJoint)) return true;
    if (leftJoint.connect(other.leftJoint)) return true;

    return false;
  }

  Map toJSON() {
    Map json = new Map();
    json["id"] = this.id;
    json["type"] = this.type;
    json["leftJoint"] = {
      "x" : this.leftJoint.x,
      "y" : this.leftJoint.y
    };
    json["rightJoint"] = {
      "x" : this.rightJoint.x,
      "y" : this.rightJoint.y
    };
    json["resistance"] = this.resistance;
    return json;
  }
  
  void _initLocation(TopCode found, TopCode match, TopCode opposite) {

    // copy pose from the found topcode -- smoothing to prevent jitters
    // the unit size is unlikely to change much with a fixed camera position
    // so we weight that heavily in favor of the average from past frames
    match.unit = match.unit * 0.9 + found.unit * 0.1;

    // the orientation gets smoothed later by finding the angle between the left and right codes
    match.orientation = match.orientation * 0.5 + found.orientation * 0.5;

    // the position is pretty jittery, but we can't assume that it will 
    // stay as fixed as the unit
    match.x = match.x * 0.5 + found.x * 0.5;
    match.y = match.y * 0.5 + found.y * 0.5;

    // we've found at least one topcode, so this component is visible
    visible = true; 

    // mark the original topcode so that we don't use it again
    found.code = -1;
  }


  void _copyTo(TopCode src, TopCode opposite, num dx) {
    opposite.x = opposite.x * 0.8 + src.targetX(dx, 0) * 0.2;
    opposite.y = opposite.y * 0.8 + src.targetY(dx, 0) * 0.2;
    opposite.orientation = src.orientation;
    opposite.unit = src.unit;
  }

  
  void draw(CanvasRenderingContext2D ctx) {
    leftCode.draw(ctx);
    rightCode.draw(ctx);
    leftJoint.draw(ctx);
    rightJoint.draw(ctx);
  }
  
}  
