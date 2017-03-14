; -------------------------------------------------------
; INT 37H - my system call

syscalls:
	cli
	push ds
	push es
	
	push ax
	mov ax, cs
	mov ds, ax
	mov es, ax
	pop ax
	
	cmp ax, 0
	jz	jmp_f0
	cmp ax, 1
	jz  jmp_f1
	cmp ax, 2
	jz  jmp_f2
	cmp ax, 3
	jz  jmp_f3
	cmp ax, 4
	jz  jmp_f4
	cmp ax, 5
	jz  jmp_f5
	cmp ax, 6
	jz  jmp_f6
	
jmp_f0:
	jmp show_time
jmp_f1:
	jmp to_upper
jmp_f2:
	jmp reverse
jmp_f3:
	jmp show_ouch	
jmp_f4:
	jmp fork
jmp_f5:
	jmp wait0
jmp_f6:
	jmp exit0

; -----------------------------------------------
; show_time
; bp - display position
	
show_time:
	mov ax, 0B800h
	mov es, ax
	
gettime:			; 利用0x1A中断获取当地时间
	mov ah, 2		; 结果得到CH为hour，CL是minute，且为压缩BCD码
	int 01aH
gethour:			; 将压缩BCD码换成正常数字
	mov bh, 0
minus1:
	cmp ch, 16
	jb  ok1
	sub ch, 16
	inc bh
	jmp minus1
ok1:	
	add bh, 48
	add ch, 48
	
	mov al, bh
	mov ah, 0Bh
	mov es:[bp], ax
	add bp, 2
	inc ah
	mov al, ch
	mov es:[bp], ax
	add bp, 2
	mov ah, 0Fh
	mov al, ':'
	mov es:[bp], ax
	add bp, 2
	dec ah
	
getmin:
	mov bh, 0
minus2:
	cmp cl, 16
	jb  ok2
	sub cl, 16
	inc bh
	jmp minus2
ok2:
	add bh, 48
	add cl, 48
	
	mov al, bh
	mov es:[bp], ax
	add bp, 2
	dec ah
	mov al, cl
	mov es:[bp], ax
	
	jmp rtn

; -------------------------------------------------
; to upper
; es - str,  bp - offset, cx - length	

to_upper:
	mov al, 'a'-1
	mov ah, 'z'+1
	mov bl, 'A'-'a'
loop_upper:
	cmp es:[bp], al
	jna continue
	cmp es:[bp], ah
	jnb continue
	add es:[bp], bl
continue:
	inc bp
	loop loop_upper
	
	jmp rtn

; -------------------------------------------------
; reverse
; es - str,  bp - offset, cx - length	
	
	
reverse:
	mov di, bp
	add di, cx
	dec di
	
	shr cx, 1
	
	cmp cx, 0
	jnz loop_rev
	jmp rtn
loop_rev:
	mov bl, es:[bp]
	mov dl, es:[di]
	mov es:[di], bl
	mov es:[bp], dl
	inc bp
	dec di
	loop loop_rev
	jmp rtn

	
; -------------------------------------------------
; show_ouch
; dh - row, dl - column, bh - color

show_ouch:
	mov ax, 0B800h
	mov es, ax
	
	xor ax, ax
	mov al, dh
	mov dh, 80
	mul dh
	add al, dl
	mov dh, 2
	mul dh
	mov bp, ax
	
	mov bl, 'o'
	mov es:[bp], bx
	add bp, 2
	mov bl, 'u'
	mov es:[bp], bx
	add bp, 2
	mov bl, 'c'
	mov es:[bp], bx
	add bp, 2
	mov bl, 'h'
	mov es:[bp], bx
	add bp, 2
	mov bl, '!'
	mov es:[bp], bx
	add bp, 2
	mov bl, 'o'
	mov es:[bp], bx
	add bp, 2
	mov bl, 'u'
	mov es:[bp], bx
	add bp, 2
	mov bl, 'c'
	mov es:[bp], bx
	add bp, 2
	mov bl, 'h'
	mov es:[bp], bx
	add bp, 2
	mov bl, '!'
	mov es:[bp], bx
	
	jmp rtn

fork:
	; save
	pop es
	pop ds
	
	mov  ax, _CurrentPCBno
	push ss
	push ax
	push bx
	push cx
	push dx
	push sp			;这个sp并不是真正的sp
	push bp
	push si
	push di
	push ds
	push es
	
	mov ax, cs
	mov ds, ax
	mov es, ax
	
	call near ptr _Save_Process
	call near ptr _do_fork

fork_Restart:
	mov ax, cs
	mov ds, ax
	mov es, ax
	
	call near ptr _Current_Process
	mov bp, ax
	
	mov ss,word ptr ds:[bp+0]         
	mov sp,word ptr ds:[bp+12] 

	add sp,16 

;*****************************************
;*                fork_Restart                *
; ****************************************
	
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

	jmp fork_rtn

	
wait0:
	call near ptr _do_wait
	jmp fork_Restart
	
exit0:
	call near ptr _do_exit
	jmp fork_Restart
	
rtn:
	pop es
	pop ds
fork_rtn:
	push ax         
	mov al,20h
	out 20h,al
	out 0A0h,al
	pop ax
	
	sti
	iret


	