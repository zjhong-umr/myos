; ------------------------------------------------------------
; kernel.asm  -- TASM
; ------------------------------------------------------------

extrn _commend:near
extrn _check:near

extrn _check:near

extrn _Program_Num:near
extrn _CurrentPCBno:near
extrn _Segment:near
extrn _special:near
extrn _Save_Process:near
extrn _Schedule:near
extrn _Current_Process:near

extrn _do_fork:near
extrn _do_wait:near
extrn _do_exit:near
extrn _check:near

_text segment byte public 'CODE'
assume cs:_text
dgroup group _TEXT,_DATA,_BSS
	org 100h
	
start:
	mov  ax,  cs
	mov  ds,  ax        ; DS = CS
	mov  es,  ax        ; ES = CS
	mov  ss,  ax       	; SS = CS
	mov  sp,  100h
	
	; initialize INT37h
	mov  ax, 0
	mov  es, ax
	mov  ax, cs
	mov  es:[0dch], offset syscalls
	mov  es:[0deh], cs
cmd:
	call near ptr _commend
quit:
	jmp $

	include kliba.asm
	include syscall.asm
	include timer.asm
_text ends

_data segment word public 'DATA'
_data ends

_bss segment word public 'BSS'
_bss ends	

end start