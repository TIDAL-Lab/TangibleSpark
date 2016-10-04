/*
* Spark: Agent-based electrical circuit environment
* Copyright (c) 2013 Elham Beheshti
*
*       Elham Beheshti (beheshti@u.northwestern.edu)
*       Northwestern University, Evanston, IL
*
* This program is free software; you can redistribute it and/or modify
* it under the terms of the GNU General Public License (version 2) as
* published by the Free Software Foundation.
*
* This program is distributed in the hope that it will be useful, but
* WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with this program; if not, write to the Free Software
* Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
*/
part of TangibleSpark;

/** 
 * this class solves the circuit using a "loop current method"
 * in this method, the KVL equations are solved for m - (n-1) independent loops 
 * m is number of edges and n is number of nodes in the graph.
 * Here, the unknowns are m - (n - 1) loop currents
 * In this approach, a DFS can be used to, first, find a spanning tree of the graph and to, second, find a cycle base.
 * A cycle base ia a set of m - (n - 1) cycles that are independet. The set of m - (n - 1) back edges defines a cycle base.
 * The back edges can be found using the DFS method. 
 * The cycles can be then defined by the back edge (i,j) and unique tree edges forming the path from j to i.
 */

/** Get a circuit object and solve the circuit equations. 
@param circuit   
@return solution, a Matrix object that contains the current loops
*/

class KirchhoffSolver {
  /* ------------------------
  Class variables
 * ------------------------ */
  MatrixSystem ms;
  Circuit circuit;
  
/* ------------------------
  Constructor
 * ------------------------ */
  KirchhoffSolver (Circuit circuit) {
    this.circuit = circuit;
    
  }
  
/* ------------------------
  Methods
 * ------------------------ */
  Matrix ApplySolver() {

    EquationSet es = new EquationSet(circuit.loops.length);
    convertLoopsToEquations(es);
    MatrixSystem ms = es.toMatrixSystem();

    /**
     * SOLUTION is a Px1 matrix of loop currents (P = M - (N - 1), # of independent loops)
     * from here, I need to calculate component (branch) currents
     **/
//    print('Matrix A: ${ms.a.getArray()}');
//    print('Matrix B: ${ms.b.getArray()}');
    
    Matrix solution = ms.solve();
    //print('Solution: ${solution.getArray()}');
    //print('Loops: ${circuit.loops.first}');
    //circuit.printGraph();
    return solution;
    
  }
  
  void convertLoopsToEquations(EquationSet es) {
    for (int i=0; i<circuit.loops.length; i++) {
      bool burntFlag = false;
      for (Edge e in circuit.loops[i].path) {
        if (e.component is Battery) {
          if ((e.component as Battery).isBurnt) {burntFlag = true;}
          es.equations[i].rhs += e.component.voltageDrop * e.direction * -1;
        }
        else {
          for (Loop l in e.loops) {
              es.equations[i].coeffs[circuit.loops.indexOf(l)] += e.component.resistance;
          }
        }
      }
      if (burntFlag) {es.equations[i].rhs = 0.0;}
    }
  }
  
}

/*
-------------------------------------------------------------
 equationSet Class
-------------------------------------------------------------
*/
class EquationSet {
  List<Equation> equations;

  EquationSet (int numEquations) {
    equations = new List<Equation>();
    for (int i=0; i<numEquations; i++) {
      equations.add(new Equation(numEquations));
    }
  }
  
  int numEquations() {
    return equations.length;
  }
  Equation equationAt(int i) {
    return equations[i];
  }
  
  MatrixSystem toMatrixSystem() {
    Matrix a = new Matrix( numEquations(), numEquations() );
    Matrix b = new Matrix( numEquations(), 1 );
    for ( int i = 0; i < numEquations(); i++ ) {
      Equation eq = equationAt(i);
      for ( int k = 0; k < eq.numCoefficients(); k++ ) {
        a.set( i, k, eq.coefficientAt(k) );
      }
      b.set( i, 0, eq.rhs );
    }

    return new MatrixSystem( a, b );
  }
  
  String toString() {
    return equations.toString();
  }

}
/*
-------------------------------------------------------------
EQUATION CLASS   
-------------------------------------------------------------   
*/
class Equation {
  List<double> coeffs;
  double rhs;

  Equation( int numCoefficients ) {
    rhs = 0.0;
    coeffs = new List<double>();
    for ( int i = 0; i < numCoefficients; i++ ) {
      coeffs.add( 0.0);
    }
  }
  int numCoefficients() {
    return coeffs.length;
  }

  double coefficientAt( int k ) {
    return coeffs[k];
  }

}

/*
-------------------------------------------------------------
MATRIX SYSTEM CLASS
-------------------------------------------------------------
*/
  class MatrixSystem {
  Matrix a;
  Matrix b;

  MatrixSystem( Matrix a, Matrix b ) {
    this.a = a;
    this.b = b;
  }

  Matrix solve() {
    return a.solve( b );
  }

}
