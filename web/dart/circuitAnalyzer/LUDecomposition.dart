/*
 * The LUDecomposition class is imported and modified from Jama (A Java Matrix package)
 * Url: http://math.nist.gov/javanumerics/jama/
*/

part of TangibleSpark;

/** LU Decomposition.
 * For an m-by-n matrix A with m >= n, the LU decomposition is an m-by-n
 * unit lower triangular matrix L, an n-by-n upper triangular matrix U,
 * and a permutation vector piv of length m so that A(piv,:) = L*U.
 * If m < n, then L is m-by-m and U is m-by-n.
 * The LU decompostion with pivoting always exists, even if the matrix is
 * singular, so the constructor will never fail.  The primary use of the
 * LU decomposition is in the solution of square systems of simultaneous
 * linear equations.  This will fail if isNonsingular() returns false.
 * 
 * List of Methods:
 * isNonsingular ()
 * getL ()
 * getU ()
 * getPivot ()
 * getDoublePivot ()
 * det ()
 * solve (Matrix B)
 */
class LUDecomposition {

/* ------------------------
   Class variables
 * ------------------------ */

   /** Array for internal storage of decomposition.
   @serial internal array storage.
   */
  List<List<double>> LU;

   /** Row and column dimensions, and pivot sign.
   @serial column dimension.
   @serial row dimension.
   @serial pivot sign.
   */
   int m, n, pivsign; 

   /** Internal storage of pivot vector.
   @serial pivot vector.
   */
   List<int> piv;

/* ------------------------
   Constructor
 * ------------------------ */

   /** LU Decomposition
       Structure to access L, U and piv.
   @param  A Rectangular matrix
   */

   LUDecomposition (Matrix A) {

   // Use a "left-looking", dot-product, Crout/Doolittle algorithm.

      LU = A.getArrayCopy();
      m = A.getRowDimension();
      n = A.getColumnDimension();
      piv = new List<int>(m);
      for (int i = 0; i < m; i++) {
         piv[i] = i;
      }
      pivsign = 1;
      List<double> LUrowi;
      List<double> LUcolj = new List<double>(m);

      // Outer loop.

      for (int j = 0; j < n; j++) {

         // Make a copy of the j-th column to localize references.

         for (int i = 0; i < m; i++) {
            LUcolj[i] = LU[i][j];
         }

         // Apply previous transformations.

         for (int i = 0; i < m; i++) {
            LUrowi = LU[i];

            // Most of the time is spent in the following dot product.

            int kmax = min(i,j);
            double s = 0.0;
            for (int k = 0; k < kmax; k++) {
               s += LUrowi[k]*LUcolj[k];
            }

            LUrowi[j] = LUcolj[i] -= s;
         }
   
         // Find pivot and exchange if necessary.

         int p = j;
         for (int i = j+1; i < m; i++) {
            if (LUcolj[i].abs() > LUcolj[p].abs()) {
               p = i;
            }
         }
         if (p != j) {
            for (int k = 0; k < n; k++) {
               double t = LU[p][k]; LU[p][k] = LU[j][k]; LU[j][k] = t;
            }
            int k = piv[p]; piv[p] = piv[j]; piv[j] = k;
            pivsign = -pivsign;
         }

         // Compute multipliers.
         
         if (j < m && LU[j][j] != 0.0) {
            for (int i = j+1; i < m; i++) {
               LU[i][j] /= LU[j][j];
            }
         }
      }
   }
   
   /* ------------------------
   Public Methods
 * ------------------------ */

   /** Is the matrix nonsingular?
   @return     true if U, and hence A, is nonsingular.
   */

   bool isNonsingular () {
      for (int j = 0; j < n; j++) {
         if (LU[j][j] == 0)
            return false;
      }
      return true;
   }

   /** Return lower triangular factor
   @return     L
   */

   Matrix getL () {
      Matrix X = new Matrix(m,n);
      List<List<double>> L = X.getArray();
      for (int i = 0; i < m; i++) {
         for (int j = 0; j < n; j++) {
            if (i > j) {
               L[i][j] = LU[i][j];
            } else if (i == j) {
               L[i][j] = 1.0;
            } else {
               L[i][j] = 0.0;
            }
         }
      }
      return X;
   }

   /** Return upper triangular factor
   @return     U
   */

   Matrix getU () {
      Matrix X = new Matrix(n,n);
      List<List<double>> U = X.getArray();
      for (int i = 0; i < n; i++) {
         for (int j = 0; j < n; j++) {
            if (i <= j) {
               U[i][j] = LU[i][j];
            } else {
               U[i][j] = 0.0;
            }
         }
      }
      return X;
   }

   /** Return pivot permutation vector
   @return     piv
   */

   List<int> getPivot () {
      List<int> p = new List<int>(m);
      for (int i = 0; i < m; i++) {
         p[i] = piv[i];
      }
      return p;
   }

   /** Return pivot permutation vector as a one-dimensional double array
   @return     (double) piv
   */

   List<double> getDoublePivot () {
     List<double> vals = new List<double>(m);
      for (int i = 0; i < m; i++) {
         vals[i] = piv[i].toDouble();
      }
      return vals;
   }

   /** Determinant
   @return     det(A)
   @exception  IllegalArgumentException  Matrix must be square
   */

   double det () {
      if (m != n) {
         throw new Exception("Matrix must be square."); // I changed this from "IllegalArgumentException" to "Exception"
      }
      double d = pivsign.toDouble();
      for (int j = 0; j < n; j++) {
         d *= LU[j][j];
      }
      return d;
   }

   /** Solve A*X = B
   @param  B   A Matrix with as many rows as A and any number of columns.
   @return     X so that L*U*X = B(piv,:)
   @exception  IllegalArgumentException Matrix row dimensions must agree.
   @exception  RuntimeException  Matrix is singular.
   */

   Matrix solve (Matrix B) {
      if (B.getRowDimension() != m) {
         throw new Exception("Matrix row dimensions must agree."); // I changed this from "IllegalArgumentException" to "Exception"
      }
      if (!this.isNonsingular()) {
         throw new Exception("Matrix is singular."); // I changed this from "RuntimeException" to "Exception"
      }

      // Copy right hand side with pivoting
      int nx = B.getColumnDimension();
      Matrix Xmat = B.getMatrix3(piv,0,nx-1);
      List<List<double>> X = Xmat.getArray();

      // Solve L*Y = B(piv,:)
      for (int k = 0; k < n; k++) {
         for (int i = k+1; i < n; i++) {
            for (int j = 0; j < nx; j++) {
               X[i][j] -= X[k][j]*LU[i][k];
            }
         }
      }
      // Solve U*X = Y;
      for (int k = n-1; k >= 0; k--) {
         for (int j = 0; j < nx; j++) {
            X[k][j] /= LU[k][k];
         }
         for (int i = 0; i < k; i++) {
            for (int j = 0; j < nx; j++) {
               X[i][j] -= X[k][j]*LU[i][k];
            }
         }
      }
      return Xmat;
   }
  //static final long serialVersionUID = 1;
   
}