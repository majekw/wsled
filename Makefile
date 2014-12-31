# for Arduino Pro mini

#assembler
ASM	:= avra

compile: wsled.hex


wsled:
wsled.hex: wsled.asm Makefile
	$(ASM) wsled.asm -l wsled.lst


install: wsled.hex
	avrdude -patmega328p -carduino -P/dev/ttyUSB3 -b57600 -D -Uflash:w:wsled.hex:i

.PHONY: clean

clean:
	rm -vf *.hex *.epp *.obj *.lst *.cof *.bin *.inc.*

