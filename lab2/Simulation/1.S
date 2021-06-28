lui x1, 1;
auipc x31, 16
addi x2, x0, 2
addi x3, x0, 3
addi x4, x0, 4
addi x5, x0, 5
slli x6, x1, 19;            # x6 = 0x80000000
add x7, x2, x3
add x8, x2, x2
addi x9, x0, -1
add x10, x6, x5
add x11, x1, x1
sub x12, x3, x2
xor x13, x4, x5
slt x14, x6, x5
sltu x15, x6, x5
slli x1, x1, -1
srli x16, x6, 4
srai x17, x6, 4
sll x2, x2, 3
srl x18, x6, x3
sra x19, x6, x3
or x4, x4, x3
and x1, x1, x5
slti x20, x9, 1
sltiu x21, x9, 1
xori x22, x7, 13            # 1101	x7 = 0101
ori x23, x7, 10;            # 1010
andi x24, x7, 8;            # 1000