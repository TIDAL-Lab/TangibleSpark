/*
 * The Matrix class is imported and modified from Jama (A Java Matrix package)
 * Url: http://math.nist.gov/javanumerics/jama/
*/
part of TangibleSpark;

/** This is a Matrix Class that provides the fundamental operations of numerical linear algebra.
 * "get" and "set" provide access to matrix elements.  
 * Several methods implement basic matrix arithmetic, including matrix addition and 
 * multiplication, matrix norms, and element-by-element array operations.
 * Methods for reading and printing matrices are also included.  
 * All the operations in this version of the Matrix Class involve real matrices.
 */

class Matrix {

/* ------------------------
   Class variables
 * ------------------------ */

   /** Array for internal storage of elements.
   @serial internal array storage.
   */
   List<List<double>> A;
   //List<double> row;

   /** Row and column dimensions.
   @serial row dimension.
   @serial column dimension.
   */
   int m, n;

/* ------------------------
   Constructors
 * ------------------------ */

   /** Construct an m-by-n matrix of zeros. 
   @param m    Number of rows.
   @param n    Number of colums.
   */

   Matrix (int m, int n) {
      this.m = m;
      this.n = n;
      A = new List<List<double>>(m);
      A = Generate2DArrayofZeros(A, m, n);
   }
   
   

/* ------------------------
   Public Methods
 * ------------------------ */
   
   /** Get row dimension.
   @return     m, the number of rows.
   */

   int getRowDimension () {
      return m;
   }

   /** Get column dimension.
   @return     n, the number of columns.
   */

   int getColumnDimension () {
      return n;
   }
   
   /** Access the internal two-dimensional array.
   @return     Pointer to the two-dimensional array of matrix elements.
   */

   List<List<double>> getArray () { 
      return A;
   }
   
   /** Copy the internal two-dimensional array.
   @return     Two-dimensional array copy of matrix elements.
   */

   List<List<double>> getArrayCopy () {
     List<List<double>> C = new List<List<double>>(m);
     C = Generate2DArrayofZeros(C, m, n);
      for (int i = 0; i < m; i++) {
         for (int j = 0; j < n; j++) {
            C[i][j] = A[i][j];
         }
      }
      return C;
   }

   /** Get a single element.
   @param i    Row index.
   @param j    Column index.
   @return     A(i,j)
   @exception  ArrayIndexOutOfBoundsException
   */

   double get (int i, int j) {
      return A[i][j];
   }
   
//   /** Get a submatrix.
//   @param i0   Initial row index
//   @param i1   Final row index
//   @param c    Array of column indices.
//   @return     A(i0:i1,c(:))
//   @exception  ArrayIndexOutOfBoundsException Submatrix indices
//   */
//
//   Matrix getMatrix (int i0, int i1, List<int> c) {
//      Matrix X = new Matrix(i1-i0+1,c.length);
//      List<List<double>> B = X.getArray();
//      try {
//         for (int i = i0; i <= i1; i++) {
//            for (int j = 0; j < c.length; j++) {
//               B[i-i0][j] = A[i][c[j]];
//            }
//         }
//      } catch(e) { // NOT SURE ABOUT THIS CODE! DOUBLE-CHECK LATER
//         throw new Exception("Submatrix indices"); // I changed this from "ArrayIndexOutOfBoundsException" to "Exception"
//      }
//      return X;
//   }

   /** Get a submatrix.
   @param r    Array of row indices.
   @param j0   Initial column index
   @param j1   Final column index
   @return     A(r(:),j0:j1)
   @exception  ArrayIndexOutOfBoundsException Submatrix indices
   */

   Matrix getMatrix3 (List<int> r, int j0, int j1) {
      Matrix X = new Matrix(r.length,j1-j0+1);
      List<List<double>> B = X.getArray();
      try {
         for (int i = 0; i < r.length; i++) {
            for (int j = j0; j <= j1; j++) {
               B[i][j-j0] = A[r[i]][j];
            }
         }
      } catch(e) {
         throw new Exception("Submatrix indices"); // I changed this from "ArrayIndexOutOfBoundsException" to "Exception"
      }
      return X;
   }

   
   /** Get a submatrix.
   @param i0   Initial row index
   @param i1   Final row index
   @param j0   Initial column index
   @param j1   Final column index
   @return     A(i0:i1,j0:j1)
   @exception  ArrayIndexOutOfBoundsException Submatrix indices
   */

   Matrix getMatrix4 (int i0, int i1, int j0, int j1) {
      Matrix X = new Matrix(i1-i0+1,j1-j0+1);
      List<List<double>> B = X.getArray();
      try {
         for (int i = i0; i <= i1; i++) {
            for (int j = j0; j <= j1; j++) {
               B[i-i0][j-j0] = A[i][j];
            }
         }
      } catch(e) {
         throw new Exception("Submatrix indices"); // I changed this from "ArrayIndexOutOfBoundsException" to "Exception"
      }
      return X;
   }
   
   /** Set a single element.
   @param i    Row index.
   @param j    Column index.
   @param s    A(i,j).
   @exception  ArrayIndexOutOfBoundsException
   */

   void set (int i, int j, double s) {
      A[i][j] = s;
   }
   
   /** Matrix transpose.
   @return    A'
   */

   Matrix transpose () {
      Matrix X = new Matrix(n,m);
      List<List<double>> C = X.getArray();
      for (int i = 0; i < m; i++) {
         for (int j = 0; j < n; j++) {
            C[j][i] = A[i][j];
         }
      }
      return X;
   }
   
   /** One norm
   @return    maximum column sum. // abs
   */

   double norm1() {
      double f = 0.0;
      for (int j = 0; j < n; j++) {
         double s = 0.0;
         for (int i = 0; i < m; i++) {
            s += A[i][j].abs();
         }
         f = max(f,s);
      }
      return f;
   }

   /** Infinity norm
   @return    maximum row sum. // abs
   */

   double normInf () {
      double f = 0.0;
      for (int i = 0; i < m; i++) {
         double s = 0.0;
         for (int j = 0; j < n; j++) {
            s += A[i][j].abs();
         }
         f = max(f,s);
      }
      return f;
   }
   
   /**  Unary minus
   @return    -A
   */

   Matrix uminus () {
      Matrix X = new Matrix(m,n);
      List<List<double>> C = X.getArray();
      for (int i = 0; i < m; i++) {
         for (int j = 0; j < n; j++) {
            C[i][j] = -A[i][j];
         }
      }
      return X;
   }
   
   /** C = A - B
   @param B    another matrix
   @return     A - B
   */

   Matrix minus (Matrix B) {
      //checkMatrixDimensions(B);
      Matrix X = new Matrix(m,n);
      List<List<double>> C = X.getArray();
      for (int i = 0; i < m; i++) {
         for (int j = 0; j < n; j++) {
            C[i][j] = A[i][j] - B.A[i][j];
         }
      }
      return X;
   }
   
   /** Multiply a matrix by a scalar, C = s*A
   @param s    scalar
   @return     s*A
   */

   Matrix times (double s) {
      Matrix X = new Matrix(m,n);
      List<List<double>> C = X.getArray();
      for (int i = 0; i < m; i++) {
         for (int j = 0; j < n; j++) {
            C[i][j] = s*A[i][j];
         }
      }
      return X;
   }
   
   /** LU Decomposition
   @return     LUDecomposition
   @see LUDecomposition
   */

   LUDecomposition lu () {
      return new LUDecomposition(this);
   }

   /** QR Decomposition
   @return     QRDecomposition
   @see QRDecomposition
   */

   QRDecomposition qr () {
      return new QRDecomposition(this);
   }
   
   /** Solve A*X = B
   @param B    right hand side
   @return     solution if A is square, least squares solution otherwise
   */

   Matrix solve (Matrix B) {
      return (m == n ? (new LUDecomposition(this)).solve(B) :
                       (new QRDecomposition(this)).solve(B));
   }
   
   /** Matrix inverse or pseudoinverse
   @return     inverse(A) if A is square, pseudoinverse otherwise.
   */

   Matrix inverse () {
      return solve(identity(m,m));
   }
   
   double det () {
      return new LUDecomposition(this).det();
   }

   /** Generate identity matrix
   @param m    Number of rows.
   @param n    Number of colums.
   @return     An m-by-n matrix with ones on the diagonal and zeros elsewhere.
   */

   static Matrix identity (int m, int n) {
      Matrix A = new Matrix(m,n);
      List<List<double>> X = A.getArray();
      for (int i = 0; i < m; i++) {
         for (int j = 0; j < n; j++) {
            X[i][j] = (i == j ? 1.0 : 0.0);
         }
      }
      return A;
   }
   
   /* ------------------------
   Private Methods
 * ------------------------ */

   /** Check if size(A) == size(B) **/

   void checkMatrixDimensions (Matrix B) {
      if (B.m != m || B.n != n) {
         throw new Exception("Matrix dimensions must agree."); // I changed this from "IllegalArgumentException" to "Exception"
      }
   }
   
   /* ------------------------
   Additional Methods
 * ------------------------ */
   /** Generate 2D array of Zeros
   @param m    Number of rows.
   @param n    Number of colums.
   @return     A list of list of doubles.
   */
   List<List<double>> Generate2DArrayofZeros(List<List<double>> Z, int m, int n) {
     for (int j = 0; j < Z.length; j++) {
       Z[j] = new List<double>.filled(n, 0.0); // row of length n filled with zeros
     }
     return Z;
   }
   

   
   


   
   
}
