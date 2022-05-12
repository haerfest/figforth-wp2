all: figforth.ex

figforth.ex: conprtio.asm discio.asm figforth.asm
	@uz80as -t z80 figforth.asm figforth.ex figforth.lst

clean:
	@rm -f *.lst *.ex
