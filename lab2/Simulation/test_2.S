# Test cases for MIPS 5-Stage pipeline

#.data
#    .word 0,1,2,3,0x80000000,0x80000100,0x100,5,0

_start:
0    add x9, x0, x0     # $t1 = 0
4    j _test0

_test0:
8    addi x10, x0, 1      # $t2 = 1
12    addi x10, x10, 1      # $t2 = 2
16    add x10, x10, x10      # $t2 = 4
20    addi x10, x10, -4     # $t2 = 0
24    beq x10, x0, _next0   # if $t2 == $0: $t1++, go next testcase, else: go fail
28    j _fail
_next0:
32    addi x9, x9, 1      # $t1++
36    j _test1

_test1:
40    addi x0, x0, 4      # $0 += 4
44    lw x10, 4(x0)       # $t2 = MEM[1]
48    lw x11, 8(x0)       # $t3 = MEM[2]
52    add x12, x10, x11     
56    sw x12, 0(x0)       # MEM[0] = $t4
60    lw x13, 0(x0)       # $t5 = MEM[0]
64    lw x14, 12(x0)      # $t6 = MEM[3]
68    beq x13, x14, _next1
72    j _fail
	
_next1:
76    addi x9, x9, 1
80    j _success

_fail:
    j _fail

_success: 
    j _success   # if success: $t1 == 2