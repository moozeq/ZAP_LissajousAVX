.data
	t		real4	0.000000, 0.000001, 0.000002, 0.000003, 0.000004, 0.000005, 0.000006, 0.000007
	ddt		real4	0.000008
	wh4		dword	0
	wh2		dword	0
	wh		dword	0
	pad		dword	0
	conb3	dword	3
	conb54	dword	54
	a		real4	0.0
	b		real4	0.0
	x		qword	0
	y		qword	0
	pi2		real4	6.28318530718
	con1	real4	1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0
	con2	real4	2.0,2.0,2.0,2.0,2.0,2.0,2.0,2.0
	con4	real4	4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0
	con6	real4	6.0,6.0,6.0,6.0,6.0,6.0,6.0,6.0
	con8	real4	8.0,8.0,8.0,8.0,8.0,8.0,8.0,8.0
	con20	real4	20.0,20.0,20.0,20.0,20.0,20.0,20.0,20.0
	con30	real4	30.0,30.0,30.0,30.0,30.0,30.0,30.0,30.0
	con42	real4	42.0,42.0,42.0,42.0,42.0,42.0,42.0,42.0
	con56	real4	56.0,56.0,56.0,56.0,56.0,56.0,56.0,56.0
	con72	real4	72.0,72.0,72.0,72.0,72.0,72.0,72.0,72.0
	con90	real4	90.0,90.0,90.0,90.0,90.0,90.0,90.0,90.0
	con110	real4	110.0,110.0,110.0,110.0,110.0,110.0,110.0,110.0
	con132	real4	132.0,132.0,132.0,132.0,132.0,132.0,132.0,132.0
	con156	real4	156.0,156.0,156.0,156.0,156.0,156.0,156.0,156.0
	con182	real4	182.0,182.0,182.0,182.0,182.0,182.0,182.0,182.0
	con210	real4	210.0,210.0,210.0,210.0,210.0,210.0,210.0,210.0
.code
	public draw
draw proc

;ARGS
;	rcx:		buffer
;	rdx:		width
;	r8:			height
;	xmm3:		a
;	xmm0:		b
;
;VARS
;	r8:		FF000000	mask to preserve put pixels
;
;	ymm0:		x
;	ymm1:		y
;	ymm2:		a
;	ymm3:		b
;	ymm4:		ddt
;	ymm5:		2pi
;	ymm6:		wh4
;	ymm7:		wh2
;	ymm8:		wh
;	ymm9:		t
;	ymm10:		pad
;	ymm11:		const int = 3
;	ymm12:		const int = 54
;	ymm13:		used for calculating sin/cos
;	ymm14:		used for calculating sin/cos
;	ymm15:		x^2/y^2 for mults in sin/cos
;

	push rbp		;prepare stack
	mov rbp, rsp

	mov r11, 3		;3B color depth so need to mul by 3
	mov r10, rdx	;save width in r10
	mov [wh], edx	;width
	cmp rdx, r8		;cmp width w/ height
	jbe widthbe		;jump below/eq with <= height
	mov rdx, r8		;width > height

widthbe:
	shr rdx, 1				;width/height / 2 - offset in bitmap
	mov [wh2], edx
	shr rdx, 1				;width/height / 4 - radius of drawing
	mov [wh4], edx

	movss [a], xmm3			;get a from xmm3, first arg
	movss [b], xmm0			;get b from xmm0

	mov r9, r10				;r9 = width
	and r9, 3H				;r9 = width mod(4) - count padding
	mov [pad], r9d			;pad = padding
	mov r8d, 0FF000000H		;mask to preserve already put pixels
	
	;ymm0 - x
	;ymm1 - y
	vbroadcastss ymm2, a
	vbroadcastss ymm3, b
	vbroadcastss ymm4, ddt
	vbroadcastss ymm5, pi2
	vbroadcastss ymm6, wh4
	vcvtdq2ps ymm6, ymm6
	vbroadcastss ymm7, wh2
	vcvtdq2ps ymm7, ymm7
	vbroadcastss ymm8, wh
	vmovups ymm9, t				;0, dt, 2*ddt, ..., 7*ddt
	vbroadcastss ymm10, pad		;padding
	vbroadcastss ymm11, conb3	;const 3 (3B)
	vbroadcastss ymm12, conb54	;const 54 (header)

start:
	vmulps ymm0, ymm2, ymm9		;x = a * t
	comiss xmm0, xmm5			;x < 2pi
	jb startcos

subcos:
	vsubps ymm0, ymm0, ymm5
	comiss xmm0, xmm5
	jae subcos					;while (x < 2pi) x -= 2pi

startcos:
	vsubps ymm13, ymm13, ymm13		;0
	vaddps ymm13, ymm13, [con1]		;1
	vmulps ymm15, ymm0, ymm0		;x*x
	vdivps ymm14, ymm15, [con2]		;x*x / 2
	vsubps ymm13, ymm13, ymm14		;1 - (..)
	
	vmulps ymm14, ymm14, ymm14		;x4 / 2!
	vdivps ymm14, ymm14, [con6]		;x4 / 4!
	vaddps ymm13, ymm13, ymm14		;1 - (..) + (..)

	vmulps ymm14, ymm14, ymm15		;x6 / 4!
	vdivps ymm14, ymm14, [con30]	;x4 / 6! 
	vsubps ymm13, ymm13, ymm14		;1 - (..) + (..) - (..)

	vmulps ymm14, ymm14, ymm15		;x8 / 6!
	vdivps ymm14, ymm14, [con56]	;x8 / 8! 
	vaddps ymm13, ymm13, ymm14		;1 - (..) + (..) - (..) + (..)

	vmulps ymm14, ymm14, ymm15		;x10 / 8!
	vdivps ymm14, ymm14, [con90]	;x10 / 10! 
	vsubps ymm13, ymm13, ymm14		;1 - (..) + (..) - (..) + (..) - (..)

	vmulps ymm14, ymm14, ymm15		;x12 / 10!
	vdivps ymm14, ymm14, [con132]	;x12 / 12! 
	vaddps ymm13, ymm13, ymm14		;1 - (..) + (..) - (..) + (..) - (..) + (..)

	vmulps ymm14, ymm14, ymm15		;x14 / 12!
	vdivps ymm14, ymm14, [con182]	;x14 / 14! 
	vsubps ymm0, ymm13, ymm14		;1 - (..) + (..) - (..) + (..) - (..) + (..) - (..)

;end cos

	vmulps ymm0, ymm0, ymm6			;wh4 * cos(a * t)
	vaddps ymm0, ymm0, ymm7			;wh4 * cos(a * t) + wh2
	vcvttps2dq ymm0, ymm0			;convert x to int

	vmulps ymm1, ymm3, ymm9			;y = b * t

	comiss xmm1, xmm5
	jb startsin

subsin:
	vsubps ymm1, ymm1, ymm5
	comiss xmm1, xmm5
	jae subsin

startsin:
	vsubps ymm13, ymm13, ymm13		;0
	vaddps ymm13, ymm13, ymm1		;y
	vmulps ymm15, ymm1, ymm1		;y*y
	vmulps ymm14, ymm15, ymm1		;y3
	vdivps ymm14, ymm14, [con6]		;y3/3!
	vsubps ymm13, ymm13, ymm14		;y - (..)

	vmulps ymm14, ymm14, ymm15		;y5/3!
	vdivps ymm14, ymm14, [con20]	;y5/5!
	vaddps ymm13, ymm13, ymm14		;y - (..) + (..)

	vmulps ymm14, ymm14, ymm15		;y7/5!
	vdivps ymm14, ymm14, [con42]	;y7/7!
	vsubps ymm13, ymm13, ymm14		;y - (..) + (..) - (..)

	vmulps ymm14, ymm14, ymm15		;y9/7!
	vdivps ymm14, ymm14, [con72]	;y9/9!
	vaddps ymm13, ymm13, ymm14		;y - (..) + (..) - (..) + (..)

	vmulps ymm14, ymm14, ymm15		;y11/9!
	vdivps ymm14, ymm14, [con110]	;y11/11!
	vsubps ymm13, ymm13, ymm14		;y - (..) + (..) - (..) + (..) - (..)

	vmulps ymm14, ymm14, ymm15		;y13/11!
	vdivps ymm14, ymm14, [con156]	;y13/13!
	vaddps ymm13, ymm13, ymm14		;y - (..) + (..) - (..) + (..) - (..) + (..)

	vmulps ymm14, ymm14, ymm15		;y15/13!
	vdivps ymm14, ymm14, [con210]	;y15/15!
	vsubps ymm1, ymm13, ymm14		;y - (..) + (..) - (..) + (..) - (..) + (..) - (..)

;end sin
	
	vmulps ymm1, ymm1, ymm6			;wh4 * (b * t)
	vaddps ymm1, ymm1, ymm7			;wh4 * (b * t) + wh2
	vcvttps2dq ymm1, ymm1			;convert y to int

	vpmulld ymm13, ymm1, ymm8		;y * width
	vpaddd ymm13, ymm13, ymm0		;y * width + x
	vpmulld ymm13, ymm13, ymm11		;3 * (...)

	vpmulld ymm14, ymm1, ymm10		;y * padding

	vpaddd ymm13, ymm13, ymm14		;3 * (y * width + x) + y * padding
	vpaddd ymm13, ymm13, ymm12		;(...) + 54 - header size

	vextractps eax, xmm13, 0		;eax = first pixel loc
	and [rcx + rax], r8d			;adds three 0x0B and remains previous 0x0 bytes
	vextractps eax, xmm13, 1		;next 3 pixels
	and [rcx + rax], r8d
	vextractps eax, xmm13, 2
	and [rcx + rax], r8d
	vextractps eax, xmm13, 3
	and [rcx + rax], r8d

	vextracti128 xmm13, ymm13, 1	;get high128 bits from ymm13

	vextractps eax, xmm13, 0		;eax = 5th pixel
	and [rcx + rax], r8d			;adds three 0x0B and remains previous 0x0 bytes
	vextractps eax, xmm13, 1		;next 3 pixels
	and [rcx + rax], r8d
	vextractps eax, xmm13, 2
	and [rcx + rax], r8d
	vextractps eax, xmm13, 3
	and [rcx + rax], r8d

	vaddps ymm9, ymm9, ymm4			;t += ddt
	comiss xmm9, xmm5				;compare t and 2pi
	jbe start						;jump if below or equal t <= 2pi
	
	mov rsp, rbp
	pop rbp
	ret
draw endp
end
