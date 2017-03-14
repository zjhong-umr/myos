
extrn _test_main:near

_text segment byte public 'CODE'
assume cs:_text
dgroup group _TEXT,_DATA,_BSS
	org 100h
start:
	mov  ax, cs
	mov  es, ax
	mov  ds, ax

	call near ptr _test_main
	jmp $
	
	include testlib.asm
_text ends

_data segment word public 'DATA'

_data ends

_bss segment word public 'BSS'
_bss ends	

end start