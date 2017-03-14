; -------------------------------------------------------------
; kernel library for C
; functions:
;	clear()  - clear screan
;	put_str(str, color, pos) 
;   put_char(char, color, pos)
;	get_char()  -- return char
;	get_time()  -- return BCD-coded time
; -------------------------------------------------------------



public _memcopy
_memcopy proc
	push ax
	push cx
	push ds
	push es
	
	mov  ax, ds
	mov  es, ax
	mov  bp, sp
	;len/dest_offset/dest_base/ori_offset/ori_base/ip/ax/cx/ds/es
	mov  ax, word ptr [bp+5*2]
	mov  ds, ax
	mov  di, word ptr [bp+6*2]
	
	mov  ax, word ptr [bp+7*2]
	mov  es, ax
	mov  si, word ptr [bp+8*2]
	
	mov  cx, word ptr [bp+9*2]
cpyloop:
	mov  ax, ds:[di]
	mov  es:[si], ax
	inc  di
	inc  si
	loop cpyloop
	
	pop es
	pop ds
	pop cx
	pop ax
	ret
_memcopy endp

public _run_file
_run_file proc
	push ax
	push bx
	push cx
	push dx
	push ds
	push si
	push di
	push bp
	push es
	push sp
	
	mov ax, cs
	mov ds, ax
	
	mov bp, sp
	mov ax, word ptr [bp+11*2]
	mov ds:[BaseOfPrg], ax
	mov ax, word ptr [bp+12*2]
	mov ds:[OffsetOfPrg], ax
	
	mov  bx, offset dgroup:OffsetOfPrg	
	call dword ptr [bx]
	
	pop sp
	pop es
	pop bp
	pop di
	pop si
	pop ds
	pop dx
	pop cx
	pop bx
	pop ax
	
	ret
_run_file endp

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

public _put_char
_put_char proc
	push es
	push bx
	push ax
	mov  ax, 0B800h
	mov  es, ax
	mov  bp, sp
	mov  al, byte ptr [bp+4*2]  ; /pos/color/word/ip/es/bx/ax
	mov  ah, byte ptr [bp+5*2]
	mov  bx, word ptr [bp+6*2]
	mov  es:[bx], ax
	pop  ax
	pop  bx
	pop  es
	ret
_put_char endp

public _get_char
_get_char proc
	xor ax, ax
	int 16h
	ret 
_get_char endp

public _get_time
_get_time proc
	push cx
	mov  ah, 2
	int  1aH
	mov  ax, cx
	pop cx
	ret
_get_time endp


public _fopen						; /offset/base/file_name/ip
_fopen proc

	mov bp, sp
	
	mov ax, word ptr [bp+4]			; 设置准备放入的基地址
	mov ds:[BaseOfPrg], ax
	mov ax, word ptr [bp+6]			; 设置准备放入的偏移量
	mov ds:[OffsetOfPrg], ax
	
	; 软盘复位
	xor	ah, ah
	xor	dl, dl
	int 13h
	
	; 下面根目录寻找目标文件
	mov	ds:[wSectorNo], SectorNoOfRootDirectory 	; 给表示当前扇区号的
													; 变量wSectorNo赋初值为根目录区的首扇区号（=19）
	mov  ds:[wRootDirSizeForLoop], RootDirSectors	; 重新设置循环次数
LABEL_SEARCH_IN_ROOT_DIR_BEGIN:
	cmp	ds:[wRootDirSizeForLoop], 0		; 判断根目录区是否已读完
	jz	LABEL_NO_EXEC					;若读完则表示未找到目标文件
	dec	ds:[wRootDirSizeForLoop]		; 递减变量wRootDirSizeForLoop的值
										; 调用读扇区函数读入一个根目录扇区到装载区
	
	mov	ax, ds:[BaseOfPrg]
	mov	es, ax						; ES <- BaseOfFile
	mov	bx, ds:[OffsetOfPrg]		; BX <- OffsetOfFile
	mov	ax, ds:[wSectorNo]			; AX <- 根目录中的当前扇区号
	mov	cl, 1						; 只读一个扇区

	
	call	ReadSector			; 调用读扇区函数

	mov	si, word ptr [bp+2]		; DS:SI -> file name
	
	mov	di, ds:[OffsetOfPrg]	; ES:DI -> BaseOfExec:0100
	
	cld							; 清除DF标志位
								; 置比较字符串时的方向为左/上[索引增加]
	mov	dx, 10h					; 循环次数=16（每个扇区有16个文件条目：512/32=16）
LABEL_SEARCH_FOR_EXEC:
	cmp	dx, 0								; 循环次数控制
	jz LABEL_GOTO_NEXT_SECTOR_IN_ROOT_DIR 	; 若已读完一扇区
	dec	dx							    	; 就跳到下一扇区
	mov	cx, 11				; 初始循环次数为11
LABEL_CMP_FILENAME:
	cmp	cx, 0
	jz	LABEL_FILENAME_FOUND; 如果比较了11个字符都相等，表示找到
	dec	cx					; 递减循环次数值
	lodsb					; DS:SI -> AL（装入字符串字节）
	cmp	al, es:[di]			; 比较字符串的当前字符
	
	jz	LABEL_GO_ON
	jmp	LABEL_DIFFERENT		; 只要发现不一样的字符就表明本DirectoryEntry
							; 不是我们要找的文件
LABEL_GO_ON:
	inc	di					; 递增DI
	jmp	LABEL_CMP_FILENAME	; 继续循环

LABEL_DIFFERENT:
	and	di, 0FFE0h			; DI &= E0为了让它指向本条目开头（低5位清零）
							; FFE0h = 1111111111100000（低5位=32=目录条目大小）
	add	di, 20h				; DI += 20h 下一个目录条目
	
	mov	si, word ptr [bp+2]			; SI指向装载文件名串的起始地址
	jmp	LABEL_SEARCH_FOR_EXEC; 转到循环开始处

LABEL_GOTO_NEXT_SECTOR_IN_ROOT_DIR:
	add	ds:[wSectorNo], 1 	; 递增当前扇区号
	jmp	LABEL_SEARCH_IN_ROOT_DIR_BEGIN

LABEL_NO_EXEC:
	mov  ax, 0
	ret

LABEL_FILENAME_FOUND:	; 找到文件后便来到这里继续
	; 计算文件的起始扇区号
	mov	ax, RootDirSectors	; AX=根目录占用的扇区数
	and	di, 0FFE0h		; DI -> 当前条目的开始地址
	add	di, 1Ah			; DI -> 文件的首扇区号在条目中的偏移地址
	mov cx, es:[di]		; CX=文件的首扇区号
	push cx				; 保存此扇区在FAT中的序号
	add	cx, ax			; CX=文件的相对起始扇区号+根目录占用的扇区数
	add	cx, DeltaSectorNo	; CL <- 文件的起始扇区号(0-based)
	mov	ax, ds:[BaseOfPrg]
	mov	es, ax				; ES <- BaseOfFile
	mov	bx, ds:[OffsetOfPrg]; BX <- OffsetOfFile
	mov	ax, cx				; AX <- 起始扇区号

LABEL_GOON_LOADING_FILE:
							; 此处不输出读取信息
	mov		cl, 1			; 1个扇区
	call	ReadSector		; 读扇区

	; 计算文件的下一扇区号
	pop ax
	call	GetFATEntry		; 获取FAT项中的下一簇号
	cmp	ax, 0FF8h			; 是否是文件最后簇
	jae	LABEL_FILE_LOADED	; ≥FF8h时跳转，否则读下一个簇
	push ax					; 保存扇区在FAT中的序号
	mov	dx, RootDirSectors	; DX = 根目录扇区数 = 14
	add	ax, dx				; 扇区序号 + 根目录扇区数
	add	ax, DeltaSectorNo	; AX = 要读的数据扇区地址
	add	bx, BPB_BytsPerSec  ; BX+512指向装载程序区的下一个扇区地址
	jmp	LABEL_GOON_LOADING_FILE
	
LABEL_FILE_LOADED:
; **********************************************************************
	mov ax, 1
	ret
; **********************************************************************



	
;-----------------------------------------------------------------------
;			函数：ReadSector
;			ax为Sector开始的序号，将cl个sector读入es:bx中
;-----------------------------------------------------------------------
;		方法：
;			设扇区号为 x:
;                      	      ┌ 柱面号 = y >> 1
;	       x           ┌ 商 y ┤
;	 -------------- => ┤      └ 磁头号 = y & 1
;	  每磁道扇区数     │
;                      └ 余 z => 起始扇区号 = z + 1
;---------------------------------------------------------------------
ReadSector:
	push bp			; 保存BP
	mov bp, sp		; 让BP=SP
	sub	sp, 2 		; 辟出两个字节的堆栈区域保存要读的扇区数: byte [bp-2]
	mov	byte [bp-2], cl	; 压CL入栈（保存表示读入扇区数的传递参数）
	push bx			; 保存BX
	
	mov	bl, BPB_SecPerTrk	; BL=18（磁道扇区数）为除数
	div	bl			; AX/BL，商y在AL中、余数z在AH中
	
	inc	ah			; z ++（因磁盘的起始扇区号为1）
	mov	cl, ah		; CL <- 起始扇区号
	mov	dh, al		; DH <- y
	
	shr	al, 1		; y >> 1 （等价于y/BPB_NumHeads，软盘有2个磁头）
	mov	ch, al		; CH <- 柱面号
	and	dh, 1		; DH & 1 = 磁头号
	pop	bx			; 恢复BX
	
	; 至此，"柱面号、起始扇区、磁头号"已全部得到
	mov	dl, ds:[BS_DrvNum]	; 驱动器号（0表示软盘A）
	
.GoOnReading: ; 使用磁盘中断读入扇区
	mov	ah, 2				; 功能号（读扇区）
	mov	al, byte [bp-2]		; 读AL个扇区
	int	13h				; 磁盘服务BIOS调用
	
	jc	.GoOnReading	; 如果读取错误，CF会被置为1，
						; 这时就不停地读，直到正确为止
	add	sp, 2			; 栈指针+2
	pop	bp				; 恢复BP

	ret
;----------------------------------------------------------------------------


;----------------------------------------------------------------------------
; 函数名：GetFATEntry
;----------------------------------------------------------------------------
; 作用：找到序号为AX的扇区在FAT中的条目，结果放在AX中。需要注意的
;     是，中间需要读FAT的扇区到ES:BX处，所以函数一开始保存了ES和BX
;---------------------------------------------------------------------------
GetFATEntry:
	push es			; 保存ES、BX和AX（入栈）
	push bx
	push ax
; 设置读入的FAT扇区写入的基地址
	mov ax, ds:[BaseOfPrg]	;BaseOfFile
	sub	ax, 0100h	; 在BaseOfFile后面留出4K空间用于存放FAT
	mov	es, ax		
; 判断FAT项的奇偶
	pop	ax			; 取出FAT项序号（出栈）
	mov	ds:[bOdd], 0; 初始化奇偶变量值为0（偶）
	mov	bx, 3		; AX*1.5 = (AX*3)/2
	mul	bx			; DX:AX = AX * 3（AX*BX 的结果值放入DX:AX中）
	mov	bx, 2		; BX = 2（除数）	
	div	bx			; DX:AX / 2 => AX <- 商、DX <- 余数
	cmp	dx, 0		; 余数 = 0（偶数）？
	jz LABEL_EVEN	; 偶数跳转
	mov	ds:[bOdd], 1	; 奇数
LABEL_EVEN:		; 偶数
	; 现在AX中是FAT项在FAT中的偏移量，下面来
	; 计算FAT项在哪个扇区中(FAT占用不止一个扇区)
	xor	dx, dx		; DX=0	
	mov	bx, BPB_BytsPerSec	; BX=512
	div	bx			; DX:AX / 512
		  			; AX <- 商 (FAT项所在的扇区相对于FAT的扇区号)
		  			; DX <- 余数 (FAT项在扇区内的偏移)
	push dx			; 保存余数（入栈）
	mov bx, 0 		; BX <- 0 于是，ES:BX = 8000h:0
	add	ax, SectorNoOfFAT1 ; 此句之后的AX就是FAT项所在的扇区号
	mov	cl, 2			; 读取FAT项所在的扇区，一次读两个，避免在边界
	call	ReadSector	; 发生错误, 因为一个 FAT项可能跨越两个扇区
	pop	dx			; DX= FAT项在扇区内的偏移（出栈）
	add	bx, dx		; BX= FAT项在扇区内的偏移
	mov	ax, es:[bx]	; AX= FAT项值
	cmp	ds:[bOdd], 1	; 是否为奇数项？
	jnz	LABEL_EVEN_2	; 偶数跳转
	shr	ax, 4			; 奇数：右移4位（取高12位）
LABEL_EVEN_2:			; 偶数
	and	ax, 0FFFh		; 取低12位
LABEL_GET_FAT_ENRY_OK:
	pop	bx			; 恢复ES、BX（出栈）
	pop	es
	ret
;----------------------------------------------------------------------------
;==============================================================
;变量
wRootDirSizeForLoop	dw	RootDirSectors	; 根目录区剩余扇区数
										; 初始化为14，在循环中会递减至零
										
OffsetOfPrg			dw	0	; 偏移量
BaseOfPrg			dw	0	; 基地址

wSectorNo			dw	0	; 当前扇区号，初始化为0，在循环中会递增
bOdd				db	0	; 奇数还是偶数FAT项
;==============================================================	

_fopen endp


;============================================================

	BPB_BytsPerSec	equ 512			; 每扇区字节数
	BPB_SecPerClus	equ 1			; 每簇多少扇区
	BPB_RsvdSecCnt	equ 1			; Boot 记录占用多少扇区
	BPB_NumFATs		equ 2			; 共有多少 FAT 表
	BPB_SecPerTrk	equ 18			; 每磁道扇区数
	BS_DrvNum		equ 0			; 中断 13 的驱动器号

RootDirSectors			equ 14		; 根目录占用空间
SectorNoOfRootDirectory	equ	19		; Root DIrectory的第一个扇区号
SectorNoOfFAT1			equ	1		; FAT1 的第一个扇区号 = BPB_RsvdSecCnt
DeltaSectorNo			equ	17		; DeltaSectorNo = BPB_RsvdSecCnt + (BPB_NumFATs * FATSz) - 2
									; 文件的开始Sector号 = DirEntry中的开始Sector号 + 根目录占用Sector数目 + DeltaSectorNo
;============================================================	
	
	
	
public _load_sector    			; /S/H/C/Offset/Base/ip/es/bx/ax/
_load_sector proc		
	push es
	push bx
	push ax
	
	mov  bp, sp
	mov  ax, word ptr [bp+4*2]
	mov  es, ax
	
	mov  ax, word ptr [bp+5*2]
	mov  bx, ax

	
	mov ah,2                 ; 功能号，ah为0时为软硬盘控制器复位
    mov al,1                 ; 需要读入扇区数目
    mov dl,0                 ; 需要进行读操作的驱动器号，软盘为0，硬盘和U盘为80H
    mov dh,byte ptr [bp+6*2] ; 需读的磁头号，起始编号为0
    mov ch,byte ptr [bp+7*2] ; 需读柱面号，起始编号为0
    mov cl,byte ptr [bp+8*2] ; 低五位表示起始扇区号，起始编号为1，
	int 13h
	
	pop  ax
	pop  bx
	pop  es
	ret
_load_sector endp

