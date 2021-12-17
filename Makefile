CA65=~/Downloads/cc65/bin/ca65
CL65=~/Downloads/cc65/bin/cl65
PY=python3

default:
	${CA65} ./temp.asm --target none --listing ./temp.lst -o ./temp.o
	${CL65} ./temp.o --target none -o ./temp.bin 
	${PY} bin2basic.py temp.bin 
	rm temp.o

clean:
	rm temp 
	rm temp.bin 
	rm temp.lst 
	rm temp.o 
