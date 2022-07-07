`ifndef INSTRUCTIONS
`define INSTRUCTIONS

typedef enum logic[3:0] {
    ALU_NOP,
    ALU_ADD,
    ALU_SUB,
    ALU_MUL,
    ALU_DIV,
    ALU_MOD,
    ALU_RESERVED0,
    ALU_RESERVED1,
    ALU_ROL,
    ALU_ROR,
    ALU_XOR,
    ALU_AND,
    ALU_OR,
    ALU_NOT,
    ALU_BSET,
    ALU_BRESET
} ALUInstruction;

typedef enum logic[3:0] {
    FPU_NOP,
    FPU_INT_TO_FLOAT,
    FPU_FLOAT_TO_INT,
    FPU_ADD,
    FPU_SUB,
    FPU_MUL,
    FPU_DIV,
    FPU_SQRT,
    FPU_CMP
} FPUInstruction;

typedef enum logic[2:0] {
    DATA_NOP,
    DATA_REG_TO_ACCU,
    DATA_ACCU_TO_REG,
    DATA_LOAD,
    DATA_STORE,
    DATA_GATHER,
    DATA_SCATTER,
    DATA_SWAP
} DataInstruction;

typedef enum logic[3:0] {
    CONTROL_NOP,
    CONTROL_FLAG_TO_REG0,
    CONTROL_REG0_TO_FLAG,
    CONTROL_STACK_TO_REG0,
    CONTROL_REG0_TO_STACK,
    CONTROL_IP_TO_REG0,
    CONTROL_REG0_TO_IP,
    CONTROL_CPU_TO_REG1,
    CONTROL_REG1_TO_CPU,
    CONTROL_CALL_SYS,
    CONTROL_RET_USER,
    CONTROL_JUMP_REL,
    CONTROL_JUMP_ABS,
    CONTROL_CALL,
    CONTROL_RETURN
} ControlInstruction;

typedef enum logic[1:0] {
    STACK_NOP,
    STACK_PUSH,
    STACK_POP
} StackInstruction;

typedef logic[4:0] Arg;

typedef struct packed {
    logic z;
    logic nz;
    logic n;
    logic nn;
    logic c;
    logic nc;
    logic o;
    logic no;
} Conditionals;

typedef struct packed {
    logic move_bits;
    logic alu_use_carry;
    ALUInstruction alu;
    FPUInstruction fpu;
    logic accu_override;
    DataInstruction data;
    ControlInstruction control;
    StackInstruction stack;
    Arg arg_alu;
    Arg arg_fpu;
    Arg arg_bus;
    Arg arg_control;
    Arg arg_stack;
    logic reserved;
    Conditionals conditionals;
} Instruction;

`endif