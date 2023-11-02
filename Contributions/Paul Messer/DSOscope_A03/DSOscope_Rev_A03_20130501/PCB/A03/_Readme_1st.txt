
To whom it may concern:

The PCB layouts for the DSOscope Analog Board and the DSOscope CPU Board
are implemented as two layer boards; a top side signal layer and a bottom
side (mostly) GND layer.  However, you will notice that the board layout,
done in FreePCB, has four layers.  The two inner layers (inner 1 and
inner 2) are not real etched layers.

Inner 1 is used as a dummy connection layer to connect GND rats that
FreePCB seems to not recognize as being connected on the GND plane
(bottom) layer.  Nothing needs to be done with this layer's information.
(A more skilled FreePCB routing person may know of a better solution to
this problem?, or what I am doing wrong that causes these phantom
unconnected rats to occur?)

Inner 2 is used as a "wire jumps" layer.  THIS LAYER, WHILE NOT A REAL
ETCHED LAYER, IS NECESSARY!!!  It shows wire jumpers that must be hand
wired on the GND plane side (bottom side) of the PCB**.  For these wire
jumps, I use insulated 30 gauge wire wrap wire.



**Since my high tech fabrication shop (the garage workbench!) only does
  two layer boards. And, since my routing puzzle solving skills leave
  a bit to be desired, I cheat and use wire jumps when stuck with no
  way of getting from here to there!  At least it lets me pretend to
  have a "high tech multilayer fab shop" ;-)  Better skilled routers
  may see ways to route these nets that would eliminate some or all
  of the wires or they may have access to true multilayer fabrication
  and can use the wire jumps layer as a real etch layer (may need DRC
  fixes or trace width widening for power nets before using as an etch
  layer).


Hope you enjoy this project as much as I have and best wishes for a
good build!

Paul
