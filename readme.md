Instructions:<br>
<br>
Setup:<br>
In `Makefile`, set the CA65 and CL65 variables to the binary locations in the CC65 toolchain (usually /cc65/bin/)<br>
Ensure python3 is installed and set the PY variable in the Makefile if necessary<br>
Ensure GNU Make is installed<br>
<br>
To create the installer BAS file:
1. Write your 6502 assembly in temp.asm<br>
2. Run `make`<br>
3. Copy the resultant BASIC code and paste it into xvic (VIC-20 emulator), or type it in on hardware (this step is necessary to tokenize the file)
<br>
To run:<br>
Create a wrapper BASIC program such as:<br>
```
10 for a=7552to7566
20 read b:poke a,b:next a
30 data 173,4,144,201,118,176,3,76,128,29,238,15,144,96,0
40 print "hello world"
50 sys7552
60 goto 40
```
In this example, SYS7552 will wait for vblank and increment the bg color register.
