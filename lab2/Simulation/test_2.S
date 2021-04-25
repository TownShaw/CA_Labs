# Test cases for MIPS 5-Stage pipeline

#.data
#    .word 0,1,2,3,0x80000000,0x80000100,0x100,5,0

_start:
    add x9, x0, x0     # $t1 = 0
    j _test0

_test0:
    addi x10, x0, 1      # $t2 = 1
    addi x10, x10, 1      # $t2 = 2
    add x10, x10, x10      # $t2 = 4
    addi x10, x10, -4     # $t2 = 0
    beq x10, x0, _next0   # if $t2 == $0: $t1++, go next testcase, else: go fail
    j _fail
_next0:
    addi x9, x9, 1      # $t1++
    j _test1

_test1:
    addi x0, x0, 4      # $0 += 4
    lw x10, 4(x0)       # $t2 = MEM[1]
    lw x11, 8(x0)       # $t3 = MEM[2]
    add x12, x10, x11     
    sw x12, 0(x0)       # MEM[0] = $t4
    lw x13, 0(x0)       # $t5 = MEM[0]
    lw x14, 12(x0)      # $t6 = MEM[3]
    beq x13, x14, _next1
    j _fail
	
_next1:
    addi x9, x9, 1
    j _success

_fail:
    j _fail

_success: 
    j _success   # if success: $t1 == 2