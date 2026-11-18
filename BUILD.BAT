@echo off
nasm -f bin TECL.ASM -o TECL.COM
nasm -f bin POLL_T.ASM -o POLL_T.COM
nasm -f bin LPT_1.ASM -o LPT_1.COM
nasm -f bin MULTI_ST.ASM -o MULTI_ST.COM
nasm -f bin ISR_KB.ASM -o ISR_KB.COM
nasm -f bin MASK_KB.ASM -o MASK_KB.COM
nasm -f bin ISR_CHAIN.ASM -o ISR_CHAIN.COM
nasm -f bin ISR_TIME.ASM -o ISR_TIME.COM
dir *.COM

