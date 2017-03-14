

public _set_timer
_set_timer proc
	push ax
	push ds
	push es
	
	cli
	mov al, 34h
	out 43h, al
	mov ax, 59660
	out 40h, al
	mov al, ah
	out 40h, al
	xor ax, ax
	mov es, ax
	
	;save time int
	mov ax, es:[20h]
	mov ds:[time_offset_save], ax
	mov ax, es:[22h]
	mov ds:[time_base_save], ax
	
	;save keyboard int
	mov ax, es:[24h]
	mov ds:[kb_offset_save], ax
	mov ax, es:[26h]
	mov ds:[kb_base_save], ax
	
	mov ax, offset timer
	mov es:[20h], ax
	mov ax, cs
	mov es:[22h], ax
	
	mov ax, offset kb_int
	mov es:[24h], ax
	mov ax, cs
	mov es:[26h], ax
	
	xor ax, ax
	mov ds:[kb_count], al
	
	sti
	
	
	pop es
	pop ds
	pop ax	
	ret
	
_set_timer endp


recover_timer:
	cli
	
	push ax
	push es
	push ds
	
	
	xor ax, ax
	mov es, ax
	mov ax, ds:[time_offset_save]
	mov es:[20h], ax
	mov ax, ds:[time_base_save]
	mov es:[22h], ax
	
	mov ax, ds:[kb_offset_save]
	mov es:[24h], ax
	mov ax, ds:[kb_base_save]
	mov es:[26h], ax
	
	
	pop ds
	pop es
	pop ax
	
	sti
	
	ret

	
	time_offset_save	dw 0
	time_base_save		dw 0

	kb_offset_save 		dw 0
	kb_base_save		dw 0
	
Finite dw 0	
timer:
;*****************************************
;*                Save                   *
; ****************************************
	cli
	
	push ds
	push ax
	
	mov ax, cs
	mov ds, ax
	
    cmp word ptr[_Program_Num],0
	jnz Save
	jmp No_Progress
Save:
	inc word ptr[Finite]
	mov al, ds:[kb_count]
	cmp al, 5
	ja  Finished
	cmp word ptr[Finite],10000
	jnz Lee
Finished:
	call recover_timer
    mov word ptr[_CurrentPCBno],0
	mov word ptr[Finite],0
	mov word ptr[_Program_Num],0
	mov word ptr[_Segment],2000h
	jmp Pre
Lee:
	pop ax
	pop ds

    push ss
	push ax
	push bx
	push cx
	push dx
	push sp
	push bp
	push si
	push di
	push ds
	push es


	mov ax,cs
	mov ds, ax
	mov es, ax

	call near ptr _Save_Process
	call near ptr _Schedule 
	
Pre:
	mov ax, cs
	mov ds, ax
	mov es, ax
	
	call near ptr _Current_Process
	mov bp, ax

	mov ss,word ptr ds:[bp+0]         
	mov sp,word ptr ds:[bp+12] 

	cmp word ptr ds:[bp+28],0 
	jnz No_First_Time

;*****************************************
;*                Restart                *
; ****************************************
Restart:
    call near ptr _special
	
	push word ptr ds:[bp+26]
	push word ptr ds:[bp+24]
	push word ptr ds:[bp+22]
	
	push word ptr ds:[bp+2]
	push word ptr ds:[bp+4]
	push word ptr ds:[bp+6]
	push word ptr ds:[bp+8]
	push word ptr ds:[bp+10]
	push word ptr ds:[bp+14]
	push word ptr ds:[bp+16]
	push word ptr ds:[bp+18]
	push word ptr ds:[bp+20]

	pop ax
	pop cx
	pop dx
	pop bx
	pop bp
	pop si
	pop di
	pop ds
	pop es


	push ax         
	mov al,20h
	out 20h,al
	out 0A0h,al
	pop ax
	
	sti
	iret

No_First_Time:	
	add sp,16 
	jmp Restart
	
No_Progress:
	
	pop ax
	pop ds
	
	push ax         
	mov al,20h
	out 20h,al
	out 0A0h,al
	pop ax
	
	sti
	
	iret
	
;---------------------------------------------------------
; 键盘中断程序
	kb_count db 0
kb_int:
	cli
	
	push ax
	push ds
	
	mov ax, cs
	mov ds, ax
	
	in al, 64h		; state
	in al, 60h		; 缓冲区
	
	inc ds:[kb_count]
	
kb_rtn:
	mov al, 20h
	out 20h, al
	out 0A0h, al
	
	pop ds
	pop ax
	
	sti
	iret