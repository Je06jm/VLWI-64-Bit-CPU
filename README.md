# VLWI CPU
This CPU is designed to be a small 64 bit microprocessor for embedded applications. Unlike many other microprocessors, all code is ran from external memory. This is a single processor that is not pipelined.

## Features
* 64 bit ALU
  * Addition w/ carry
  * Subtraction w/ carry
  * Multiplication
  * Division
  * Modules
  * Shift left w/ carry
  * Shift right w/ carry
  * XOr
  * Or
  * And
  * Not
  * Bit set
  * Bit reset
  * Compare
* 64 bit FPU
  * Addition
  * Subtraction
  * Multiplication
  * Division
  * Double to integer
  * Integer to double
  * Compare
* System and user modes
* External interrupt
* 48 bit memory address space (32 without paging)
* 48 bit device address space (with paging only)

## Instructions
### Instruction word
<table>
<tr>
    <th>Bit 63</th>
    <th>Bit 62</th>
    <th>Bits 61-58</th>
    <th>Bits 57-54</th>
    <th>Bit 53</th>
    <th>Bits 52-50</th>
    <th>Bits 49-46</th>
    <th>Bits 45-44</th>
    <th>Bits 43-39</th>
    <th>Bits 38-34</th>
    <th>Bits 33-29</th>
    <th>Bits 28-13</th>
    <th>Bits 12-8</th>
    <th>Bit 7</th>
    <th>Bit 6</th>
    <th>Bit 5</th>
    <th>Bit 4</th>
    <th>Bit 3</th>
    <th>Bit 2</th>
    <th>Bit 1</th>
    <th>Bit 0</th>
</tr>
<tr>
    <th>Move bits 62-0 to Reg</th>
    <th>ALU use carry</th>
    <th>ALU function</th>
    <th>FPU function</th>
    <th>Accumulator override (Set accumulator to reg1)</th>
    <th>Bus function</th>
    <th>Control function</th>
    <th>Stack function</th>
    <th>ALU Arg</th>
    <th>FPU Arg</th>
    <th>Bus Arg</th>
    <th>Control Arg</th>
    <th>Stack Arg</th>
    <th>Conditional Z</th>
    <th>Conditional ~Z</th>
    <th>Conditional N</th>
    <th>Conditional ~N</th>
    <th>Conditional C</th>
    <th>Conditional ~C</th>
    <th>Conditional O</th>
    <th>Conditional ~O</th>
</tr>
</table>

### ALU Functions
<table>
<tr>
    <th>0x0</th>
    <th>NOP</th>
</tr>
<tr>
    <th>0x1</th>
    <th>Add</th>
</tr>
<tr>
    <th>0x2</th>
    <th>Subtract</th>
</tr>
<tr>
    <th>0x3</th>
    <th>Multiply</th>
</tr>
<tr>
    <th>0x4</th>
    <th>Divide</th>
</tr>
<tr>
    <th>0x5</th>
    <th>Modules</th>
</tr>
<tr>
    <th>0x6</th>
    <th>Shift left</th>
</tr>
<tr>
    <th>0x7</th>
    <th>Shift right</th>
</tr>
<tr>
    <th>0x8</th>
    <th>Compare</th>
</tr>
<tr>
    <th>0x9</th>
    <th>Reserved</th>
</tr>
<tr>
    <th>0xa</th>
    <th>XOr</th>
</tr>
<tr>
    <th>0xb</th>
    <th>And</th>
</tr>
<tr>
    <th>0xc</th>
    <th>Or</th>
</tr>
<tr>
    <th>0xd</th>
    <th>Not</th>
</tr>
<tr>
    <th>0xe</th>
    <th>Bit Set</th>
</tr>
<tr>
    <th>0xf</th>
    <th>Bit Reset</th>
</tr>
</table>

Every ALU function applies to R0. If an additional data is needed,
then it uses registers. The additional register is selected using ALU arg.

### FPU Functions
<table>
<tr>
    <th>0x0</th>
    <th>NOP</th>
</tr>
<tr>
    <th>0x1</th>
    <th>Convert int from R0 to double in R1</th>
</tr>
<tr>
    <th>0x2</th>
    <th>Convert double from R1 to int in R0</th>
</tr>
<tr>
    <th>0x3</th>
    <th>Add</th>
</tr>
<tr>
    <th>0x4</th>
    <th>Subtract</th>
</tr>
<tr>
    <th>0x5</th>
    <th>Multiply</th>
</tr>
<tr>
    <th>0x6</th>
    <th>Division</th>
</tr>
<tr>
    <th>0x7</th>
    <th>Compare</th>
</tr>
<tr>
    <th>0x8</th>
    <th>Generate flags</th>
</th>
<tr>
    <th>0x9</th>
    <th>Reserved</th>
</tr>
<tr>
    <th>0xa</th>
    <th>Reserved</th>
</tr>
<tr>
    <th>0xb</th>
    <th>Reserved</th>
</tr>
<tr>
    <th>0xc</th>
    <th>Reserved</th>
</tr>
<tr>
    <th>0xd</th>
    <th>Reserved</th>
</tr>
<tr>
    <th>0xe</th>
    <th>Reserved</th>
</tr>
<tr>
    <th>0xf</th>
    <th>Reserved</th>
</tr>
</table>

Every FPU function applies to R1. If an additional data is needed,
then it uses registers. The additional register is selected using FPU arg.

\*NOTE\* FPU compare will not set or reset C or O flags.

\*NOTE\* FPU generate flags will set Z if R1 is zero, N if R1 is negative, C if R1 is Inf, and O if R1 is NaN.

### Bus Function
<table>
<tr>
    <th>0x0</th>
    <th>NOP</th>
</tr>
<tr>
    <th>0x1</th>
    <th>Move register to accumulator
</tr>
<tr>
    <th>0x2</th>
    <th>Move accumulator to register</th>
</tr>
<tr>
    <th>0x3</th>
    <th>Load accumulator</th>
</tr>
    <th>0x4</th>
    <th>Store accumulator</th>
</tr>
<tr>
    <th>0x5</th>
    <th>Swap accumulator with register</th>
</tr>
<tr>
    <th>0x6</th>
    <th>Reserved</th>
</tr>
<tr>
    <th>0x7</th>
    <th>Reserved</th>
</tr>
</table>

Every Bus function applies to R0. If an additional data is needed,
then it uses registers. The additional register is selected using Bus arg.

If bit 53(Accumulator override), then all bus functions applies to R1 instead of R0.

### Control Function
<table>
<tr>
    <th>0x0</th>
    <th>NOP</th>
</tr>
<tr>
    <th>0x1</th>
    <th>Move flags to R0</th>
</tr>
<tr>
    <th>0x2</th>
    <th>Move R0 to flags</th>
</tr>
<tr>
    <th>0x3</th>
    <th>Move stack to R0</th>
</tr>
<tr>
    <th>0x4</th>
    <th>Move R0 to stack</th>
</tr>
<tr>
    <th>0x5</th>
    <th>Move ip to R0</th>
</tr>
<tr>
    <th>0x6</th>
    <th>Move R0 to ip</th>
</tr>
<tr>
    <th>0x7</th>
    <th>Move cpu control register(R0) into R1</th>
</tr>
<tr>
    <th>0x8</th>
    <th>Move R1 into cpu control register(R0)</th>
</tr>
<tr>
    <th>0x9</th>
    <th>Call to system</th>
</tr>
<tr>
    <th>0xa</th>
    <th>Return to user</th>
</tr>
<tr>
    <th>0xb</th>
    <th>Jump relative</th>
</tr>
<tr>
    <th>0xc</th>
    <th>Jump absolute</th>
</tr>
<tr>
    <th>0xd</th>
    <th>Call absolute</th>
</tr>
<tr>
    <th>0xe</th>
    <th>Return</th>
</tr>
<tr>
    <th>0xf</th>
    <th>Reserved</th>
</tr>
</table>

Every Control function applies to R0. If an additional data is needed,
then it uses registers. The additional register is selected using Control arg.

### Stack Function
<table>
<tr>
    <th>0x0</th>
    <th>NOP</th>
</tr>
<tr>
    <th>0x1</th>
    <th>Push register</th>
</tr>
<tr>
    <th>0x2</th>
    <th>Pop register</th>
</tr>
<tr>
    <th>0x3</th>
    <th>Reserved</th>
</tr>
</table>

### Conditionals
<table>
<tr>
    <th>Bit 7</th>
    <th>Execute only if Z is set</th>
</tr>
<tr>
    <th>Bit 6</th>
    <th>Execute only if Z is reset</th>
</tr>
<tr>
    <th>Bit 5</th>
    <th>Execute only if N is set</th>
</tr>
<tr>
    <th>Bit 4</th>
    <th>Execute only if N is reset</th>
</tr>
<tr>
    <th>Bit 3</th>
    <th>Execute only if C is set</th>
</tr>
<tr>
    <th>Bit 2</th>
    <th>Execute only if C is reset</th>
</tr>
<tr>
    <th>Bit 1</th>
    <th>Execute only if O is set</th>
</tr>
<tr>
    <th>Bit 0</th>
    <th>Execute only if O is reset</th>
</tr>
</table>

## Paging
Each page is describe in a table with 1024 entries, starting at the page table base control register. Every page is 4 MiBs. The cpu uses page at index base + ip[31:26] * 4

Page
<table>
<tr>
    <th>Bits 31-6</th>
    <th>Bits 7-4</th>
    <th>Bit 3</th>
    <th>Bit 2</th>
    <th>Bit 1</th>
    <th>Bit 0</th>
</tr>
<tr>
    <th>Tag</th>
    <th>Reserved</th>
    <th>Free</th>
    <th>User</th>
    <th>Device</th>
    <th>Present</th>
</tr>
</table>

## Control Registers
<table>
<tr>
    <th>Page Table Base</th>
    <th>0</th>
</tr>
<tr>
    <th>Interrupt Handler</th>
    <th>1</th>
</tr>
<tr>
    <th>Invalid Instruction Handler</th>
    <th>2</th>
</tr>
<tr>
    <th>ALU Divided by 0 Handler</th>
    <th>3</th>
</tr>
<tr>
    <th>Page is System Handler</th>
    <th>4</th>
</tr>
<tr>
    <th>Page is Not Present Handler</th>
    <th>5</th>
</tr>
</table>