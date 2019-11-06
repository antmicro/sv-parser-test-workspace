	.option nopic
	.text
	.align	2
	.globl	_reset
	.type	_reset, @function

_reset:
	xor x0, x0, x0
	la x10, 0xdeadbeef

	# Count from 0 to 10
	la x1, 10
	la x2, 0
1:	addi x2, x2, 1
	bne x1, x2, 1b

	### End simulation ###
	#la x1, 0xa0
	#la x2, 0x55
	#sw x2, 0(x1)

	# Loop forever
1:	j 1b

	.size	_reset, .-_reset
