figforth: figforth.ex

figforth.img: figforth.com SCREENS.FTH
	@rm -f figforth.img
	@mkfs.cpm -f wbw_fd144 figforth.img
	@cpmcp -f wbw_fd144 figforth.img figforth.com 0:forth.com
	@cpmcp -f wbw_fd144 figforth.img SCREENS.FTH 0:screens.fth

figforth.com: conprtio.asm discio.asm figforth.asm romwbw.asm
	@uz80as -t z80 figforth.asm figforth.com figforth.lst

figforth.ex: conprtio.asm discio.asm figforth.asm
	@uz80as -t z80 --define=WP2 figforth.asm figforth.ex figforth.lst

clean:
	@rm -f *.lst *.img *.com *.ex
