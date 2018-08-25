#include <stdlib.h>
#include <stdio.h>

#define CHAR_SIZE 1

extern char WorldLength;
extern char WorldWidth;
extern char *CORS;
extern void resume();
extern void updateRegister();
extern char* array_element_address(char *array_start, int element_size, int array_width, int x, int y);

void handleCell(int routineId){
	char *temp[9];
	int i, j, x, y, temp2, k=0, counter=0;
	char currState, nextState;
	int length = (int) WorldLength;
	int width = (int) WorldWidth;
	routineId = routineId - 2;
	y = routineId%width;
	temp2 = routineId - y;
	x = temp2/width;
	for (i=x-1; i<x+2; i++){
		for (j=y-1; j<y+2; j++){
			/*Get the cell address and all of is neighbors*/
			int fixedRow = i%((int)length);
			int fixedColumn = j%((int)width);
			if (fixedRow<0)
				fixedRow+=length;
			if (fixedColumn<0)
				fixedColumn+=width;
			temp[k] = array_element_address(CORS, CHAR_SIZE, width, fixedRow, fixedColumn);
			k++;
		}
	}
	while(1){
		counter = 0;
		for (k=0; k<9; k++){
		       if(x%2==0) /* odd line */
		       {
			if (k!=4 && k!=2 && k!= 8 && *temp[k]!=0){
				/*Count living negihbors*/
				counter++;
			}
			}
			else  /*even line*/
			{
			  if (k!=4 && k!=0 && k!= 6 && *temp[k]!=0){
				/*Count living negihbors*/
				counter++;
			  }
			}
		}
		currState = *temp[4];
		if (currState>0){
			/*The cell is alive*/
			if (counter==3 || counter==4){
				/*The cell stays alive*/
					nextState = 1;
			}
			else{
				/*The cell is going to die*/
				nextState = 0;
			  
			}
		}
		else{
			/*The cell is dead*/
			if (counter==2)
			{
				/*The cell is uprising*/
				nextState = 1;
			}
			else
			{
				/*The cell stays dead*/
				nextState = 0;
			}
		}
		updateRegister();
		resume();
		*temp[4] = nextState;
		updateRegister();
		resume();
	}
}