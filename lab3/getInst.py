def convert_Hex(Hex_char: str):
    if len(Hex_char) != 1:
        print("convert_Hex() Must get only one Hex_char!")
    if Hex_char == '0':
        return '0000'
    elif Hex_char == '1':
        return '0001'
    elif Hex_char == '2':
        return '0010'
    elif Hex_char == '3':
        return '0011'
    elif Hex_char == '4':
        return '0100'
    elif Hex_char == '5':
        return '0101'
    elif Hex_char == '6':
        return '0110'
    elif Hex_char == '7':
        return '0111'
    elif Hex_char == '8':
        return '1000'
    elif Hex_char == '9':
        return '1001'
    elif Hex_char == 'a' or Hex_char == 'A':
        return '1010'
    elif Hex_char == 'b' or Hex_char == 'B':
        return '1011'
    elif Hex_char == 'c' or Hex_char == 'C':
        return '1100'
    elif Hex_char == 'd' or Hex_char == 'D':
        return '1101'
    elif Hex_char == 'e' or Hex_char == 'E':
        return '1110'
    elif Hex_char == 'f' or Hex_char == 'F':
        return '1111'
    else:
        print("convert_Hex() Input Error!")



def Hex_to_Inst(Hex_Inst: str):
    Binary_Inst = ''
    for i in range(len(Hex_Inst)):
        Binary_Inst += convert_Hex(Hex_Inst[i])
    return Binary_Inst

while (True):
    hex = input("input Inst (Hex format): ")
    Binary_Inst = Hex_to_Inst(hex)
    if len(Binary_Inst) != 32:
        continue
    Instruction = ''
    Instruction += Binary_Inst[0:7] + ' ' + Binary_Inst[7:12] + ' ' + Binary_Inst[12:17] + ' ' + Binary_Inst[17:20] + ' ' + Binary_Inst[20:25] + ' ' + Binary_Inst[25:32]
    print(Instruction)