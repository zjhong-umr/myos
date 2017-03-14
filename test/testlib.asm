
public _get_one
_get_one proc
	mov ax, 1
	ret
_get_one endp

public _fork
_fork proc
	mov ax, 4
	int 37h
	ret
_fork endp

public _wait0
_wait0 proc
	mov ax, 5
	int 37h
	ret
_wait0 endp

public _exit
_exit proc
	mov ax, 6
	int 37h
	ret
_exit endp

public _clear
_clear proc
	push dx
	push cx
	push bx
	push ax
	mov  ax, 0600H
	mov  bx, 0700H
	mov  cx, 0
	mov  dx, 0184fH
	int  10H	
	pop  ax
	pop  bx
	pop  cx
	pop  dx
	ret
_clear endp

public _put_str
_put_str proc
	push bp
	push dx
	push cx
	push bx
	push ax
	push es
	mov  ax, ds
	mov  es, ax
	mov  bp, sp
	mov  si, word ptr [bp+7*2]  ;/pos/color/len/str/ip/bp/dx/cx/bx/ax/es
	xor  cx, cx
	mov  cx, word ptr [bp+8*2]
	mov  bx, word ptr [bp+9*2]
	mov  dx, word ptr [bp+10*2]
	mov  ax, si
	mov  bp, ax
	mov  ax, 1301h
	int  10h
	pop  es
	pop  ax
	pop  bx
	pop  cx
	pop  dx
	pop  bp
	ret
_put_str endp