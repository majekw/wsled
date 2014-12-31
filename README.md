wsled
=====

WS2811 based christmas tree led lamps

Hardware
========

Ingredients:
- 50 chained leds with WS2811 controller
- Arduino Pro Mini board (with AtMega328P @16MHz, 5V)
- power supply: 5V and 3A at least


Connections:

--------+                   +------------------+
        |                   |                  |
 power  [+]-------+-----[raw]                  |
 supply |         |         | Arduino Pro Mini |
 5V/3A  [-]-+-----------[gnd] 16MHz, 5V        |
        |   |     |         | Atmega328        |
--------+   |     |     +[10]                  |
            |     |     |   |                  |
            |     |     |   +------------------+
            |     |     |
        +-[gnd]-[+5V]-[DIN]-+
        |                   |
        |   WS2811 LED #1   |
        |                   |
        +-[gnd]-[+5V]-[DOUT]+
           |      |     |
        +-[gnd]-[+5V]-[DIN]-+
        |                   |
        |   WS2811 LED #2   |
    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


Software
========

It's pure assembler as timings are pretty tight.

You need [AVRA](http://avra.sourceforge.net) to compile it.
If you have 'make' installed, you could just type make.

Also, for uploading code you can use 'make install' assuming that you have
Avrdude in your path and your interface is connected on ttyUSB3 :-)

Look at contents of Makefile if you don't have make.
[Avrdude](http://www.nongnu.org/avrdude/) could be used for burning. It't also
a part of Arduino IDE, so if you have Arduino installed, you have also Avrdude
somewhere:-)

Code
----

There are main components of code:
- buffer for led values: 150 bytes (r,g,b *50)
- function for sending contents of buffer to leds: send_ws2811
- other functions outside main loop which makes funny things to buffer :-)

It's 'one night' project, so don't expect high quality. But send_ws2811 was carefully
checked on osciloscope for corectness of generating waveforms.


AUTHOR
======

This piece of software was written by Marek Wodzinski (me) day before Christmas 2014


License
=======

This christmas tree lights are licensed unded GPL v3 license.
