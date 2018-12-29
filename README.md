# C-assembly-combination
Simulating a variant of Conway's Game of Life.
In the variant to be implemented in this code, every organism is a cell in a grid made of hexagonal close-packed disks, so it has 6 neighbors. The LIFE board is toroidal.

The program begins by reading the initial state configuration of the organisms managed by the co-routines, the number of generations to run, and the printing frequency (in steps).

The program initializes an appropriate mechanism, and control is then passed to a scheduler co-routine which decides the appropriate scheduling for the co-routines. The states of the organisms are managed by the co-routines: each co-routine is responsible for one organism (a cell in the array).

The cell organisms change according to the following rules: if the cell is currently alive, then it will remain alive in the next generation if and only if exactly 3 or 4 of its neighbors are currently alive. Otherwise it dies. A dead cell remains dead in the next generation, unless it has exactly 2 living neighbors, in which case we say that an organism is born here.

A specialized co-routine called the printer prints the organism states for all the cells as a two dimensional hexagonal grid.


Happy new year