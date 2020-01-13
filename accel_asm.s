@
@ File:			    accel_asm.s
@ Programmer:		Trent Thompson
@ Date:			    November 14, 2019
@ Description:		This file contains the Assembly code needed to implement the LED accelerometer game.
@



@ Data declaration section
.data

LEDaddress:   .word 0x48001014
currentLed:   .word 0x00000000
winningLed:   .word 0x00000000
winningTime:  .word 0x00000000
currentTime:  .word 0x00000000
windelay:     .word 0xFFFFF



@@ Function Header Block
  .code   16              @ This directive selects the instruction set being generated.
                          @ The value 16 selects Thumb, with the value 32 selecting ARM.
  .text                   @ Tell the assembler that the upcoming section is to be considered
                          @ assembly language instructions - Code section (text -> ROM)



@ Constants
.equ postitiveThreshold, 15
.equ negativeThreshold, -15
.equ allLightsOff, 0x0008
.equ allLightsOn, 0xFF00
.equ noLight, -1
.equ accelAddress, 0x32
.equ xAxis, 0x29
.equ yAxis, 0x2B





@ Function Header Block
  .align  2               @ Code alignment - 2^n alignment (n=2)
                          @ This causes the assembler to use 4 byte alignment
  .syntax unified         @ Sets the instruction set to the new unified ARM + THUMB
                          @ instructions. The default is divided (separate instruction sets)
  .global setup_game      @ Make the symbol name for the function visible to the linker
  .code   16              @ 16bit THUMB code (BOTH .code and .thumb_func are required)
  .thumb_func             @ Specifies that the following symbol is the name of a THUMB
                          @ encoded function. Necessary for interlinking between ARM and THUMB code.
  .type   setup_game, %function   @ Declares that the symbol is a function (not strictly required)

@ Function Declaration :  void setup_game(int winTime, int winningLed)
@
@ Input: r0: winningtime: the winning time in milliseconds
@        r1: winningLed: The target LED
@ Returns: void
@
setup_game:
  @ Push registers used
  push {lr}

  @ Load the address of the winningTime into r2
  ldr r2, =winningTime

  @ Store the value of the winningTime passed in at r0
  str r0, [r2]

  @ Load the address of the winningLed into r2
  ldr r2, =winningLed

  @ Store the value of the winningLed passed in at r1
  str r1, [r2]

  @ Put 0 into r0 to initialize the currentTime
  mov r0, #0

  @ Load the address of the currentTime into r2
  ldr r1, =currentTime

  @ Initialize the currentTime as 0
  str r0, [r1]

  @ Move noLight (-1) into r0
  mov r0, noLight

  @ Load the address of the currentLed into r1
  ldr r1, =currentLed

  @ Initialize the currentLed as -1, to say that no lights are lit
  str r0, [r1]

  @ Load the address of
  ldr r1, =LEDaddress

  @ Load the address of the lights into r1
  ldr r1, [r1]

  @ Move the value for allLightsOff (0x0008) into r0
  mov r0, allLightsOff

  @ Give the value to turn all the lights off to the lights
  strh r0, [r1]

  @ Pop registers used
  pop {lr}

  @ Return
  bx lr

  .size   setup_game, .-setup_game    @@ - symbol size (not req)





@@ Function Header Block
  .align  2               @ Code alignment - 2^n alignment (n=2)
                          @ This causes the assembler to use 4 byte alignment
  .syntax unified         @ Sets the instruction set to the new unified ARM + THUMB
                          @ instructions. The default is divided (separate instruction sets)
  .global determine_light @ Make the symbol name for the function visible to the linker
  .code   16              @ 16bit THUMB code (BOTH .code and .thumb_func are required)
  .thumb_func             @ Specifies that the following symbol is the name of a THUMB
                          @ encoded function. Necessary for interlinking between ARM and THUMB code.
  .type   determine_light, %function   @ Declares that the symbol is a function (not strictly required)

@ Function Declaration :  void determine_light(void)
@
@ Input:   void
@ Returns: void
@
determine_light:
  @ Push registers used
  push {r4-r7, lr}

  @ Load the address of the currentLed into r6
  ldr r6, =currentLed

  @ Load the value of the currentLed into r7 for the comparison to follow
  ldr r7, [r6]

  @ Move the address of the accelerometer into r0
  mov r0, accelAddress

  @ Move the address for the y axis into r1
  mov r1, yAxis

  @ Check the current state of the yAxis
  bl COMPASSACCELERO_IO_Read

  @ Sign-extend the result of checking the yAxis
  sxtb r0, r0

  @ Store the result in r4
  mov r4, r0

  @ Move the address of the accelerometer into r0
  mov r0, accelAddress

  @ Move the address for the x axis into r1
  mov r1, xAxis

  @ Check the current state of the yAxis
  bl COMPASSACCELERO_IO_Read

  @ Sign-extend the result of checking the xAxis
  sxtb r0, r0

  @ Store result in r5
  mov r5, r0

  @ Compare the yAxis to the postitiveThreshold
  cmp r5, postitiveThreshold

  @ Branch if the yAxis reading is greater than the postitiveThreshold
  BGT lighttop

  @ Compare the yAxis to the negativeThreshold
  CMP r5, negativeThreshold

  @ Branch if the yAxis reading is less than the negativeThreshold
  BLT lightbottom

  @ Compare the xAxis to the postitiveThreshold
  cmp r4, postitiveThreshold

  @ Branch if the xAxis reading is greater than the postitiveThreshold
  BGT lightleft

  @ Compare the xAxis to the negativeThreshold
  cmp r4, negativeThreshold

  @ Branch if the xAxis reading is less than the negativeThreshold
  BLT lightright

  @ If none of the other branch conditions have been met, we can skip over out decision structure for the lights
  b skiplight

@ Responsible for the top 3 lights (0, 1, 2)
lighttop:
  @ Compare the xAxis to the negativeThreshold
  cmp r4, negativeThreshold

  @ Branch if the xAxis reading is less than the negativeThreshold
  blt topright

  @ Compare the xAxis to the postitiveThreshold
  cmp r4, postitiveThreshold

  @ Branch if the xAxis reading is greater than the postitiveThreshold
  bgt topleft

  @ Otherwise, we have to light up the very top light (0)
  @ Move the value for the top light into r0
  mov r0, #0

  @ Branch to the led lighting section
  b light

@ Sets the top right light (2)
topright:
  @ Move the value for the topright light (2) into r0
  mov r0, #2

  @ Branch to the led lighting section
  b light

@ Sets the top left right (1)
topleft:
  @ Move the value for the topleft light (1) into r0
  mov r0, #1

  @ Branch to the led lighting section
  b light

@ Responsible for the bottom 3 lights (5, 6, 7)
lightbottom:
  @ Compare the xAxis to the postitiveThreshold
  cmp r4, postitiveThreshold

  @ Branch if the xAxis reading is greater than the postitiveThreshold
  bgt bottomleft

  @ Compare the xAxis to the negativeThreshold
  cmp r4, negativeThreshold

  @ Branch if the xAxis reading is less than the negativeThreshold
  blt bottomright

  @ Otherwise, we have to light up the very bottom light (7)
  @ Move the value for the bottom light into r0
  mov r0, #7

  @ Branch to the led lighting section
  b light

@ Sets the bottom left light (5)
bottomleft:
  @ Move the value for the bottomleft light (5) into r0
  mov r0, #5

  @ Branch to the led lighting section
  b light

@ Sets the bottom right light (6)
bottomright:
  @ Move the value for the bottomright light (6) into r0
  mov r0, #6

  @ Branch to the led lighting section
  b light

@ Sets the left light (3)
lightleft:
  @ Move the value for the bottomright light (4) into r0
  mov r0, #3

  @ Branch to the led lighting section
  b light

@ Sets the right light (4)
lightright:
  @ Move the value for the bottomright light (4) into r0
  mov r0, #4

  @ Branch to the led lighting section
  b light

@ Lights up the right led based on the above decision structure
light:
  @ Store the value of the led as the new value for the currentLed
  str r0, [r6]

  @ Turn on the correct led based on the above decision structure
  bl BSP_LED_On

@ Label for if we want to skip turning on any LED's
skiplight:

  @ Load the new value of the currentLed into r0
  ldr r0, [r6]

  @ Compare the new value of the currentLed to the old value of the currentLed which was stored in r7 above
  cmp r0, r7

  @ If the old and new values of currentLed don't match, we must turn off the previous led
  BNE turnoff

  @ Otherwise we can skip turning off the LED altogether
  b skipturnoff

@ Turns off the previous led
turnoff:
  @ Compare the currentLed value to check if there are no lights lit yet (-1)
  cmp r0, noLight

  @ If no lights are lit yet, we want to skip turning off and Lights
  beq skipturnoff

  @ Otherwise move the old value of the currentLed into r0
  mov r0, r7

  @ Call to turn off the previous LED
  bl BSP_LED_Off

@ Label for if we want to skip turning off any led's
skipturnoff:

  @ Pop registers used
  pop {r4-r7, lr}

  @return
  bx lr

  .size   determine_light, .-determine_light    @@ - symbol size (not req)





@@ Function Header Block
  .align  2               @ Code alignment - 2^n alignment (n=2)
                          @ This causes the assembler to use 4 byte alignment
  .syntax unified         @ Sets the instruction set to the new unified ARM + THUMB
                          @ instructions. The default is divided (separate instruction sets)
  .global win_stopwatch @ Make the symbol name for the function visible to the linker
  .code   16              @ 16bit THUMB code (BOTH .code and .thumb_func are required)
  .thumb_func             @ Specifies that the following symbol is the name of a THUMB
                          @ encoded function. Necessary for interlinking between ARM and THUMB code.
  .type   win_stopwatch, %function   @ Declares that the symbol is a function (not strictly required)

@ Function Declaration :  void win_stopwatch(void)
@
@ Input:   void
@ Returns: int: 0 If the game should continue to run, 1 if the lights should blink
@
win_stopwatch:
  @ Push registers used
  push {lr}

  @ Load the address of the currentLed into r1
  ldr r1, =currentLed

  @ Load the value of the currentLed into r0
  ldr r0, [r1]

  @ Load the address of the currentLed into r2
  ldr r2, =winningLed

  @ Load the value of the currentLed into r1
  ldr r1, [r2]

  @ Compare the led that is currently lit up to the winningLed
  cmp r0, r1

  @ If the values are the same, branch to increment the currentTime counter
  BEQ increment

  @ Otherwise branch to reset the currentTime coutner
  b reset

@ Label for incrementing the current time counter
increment:
  @ Load the address of the currentTime into r1
  ldr r1, =currentTime

  @ Load the value of the currentTime into r0
  ldr r0, [r1]

  @ Add 1 to the currentTime register
  add r0, r0, #1

  @ Store the new value for the currentTime counter
  str r0, [r1]

  @ Branch to check if the user has won the game
  b checkwin

@ Label for resetting the currentTime counter
reset:
  @ Load the address of the currentTime into r1
  ldr r1, =currentTime

  @ Load the value of the currentTime into r0
  ldr r0, [r1]

  @ Move 0 into r0
  mov r0, #0

  @ Store r0 (value 0) as the new value for the currentTime
  str r0, [r1]

  @ Branch to return that the game needs to continue
  b returncontinue

@ Checks if the game needs to be stopped due to the user winning
checkwin:
  @ Load r2 with the address of the winningTime
  ldr r2, =winningTime

  @ Load r1 with the value of the winningTime
  ldr r1, [r2]

  @ Compare r0 (which currently holds the currentTime value) to the winningTime
  cmp r0, r1

  @ If the currentTime equals the winningTime, branch to return theat the user has won
  BEQ returnwin

  @ Otherwise branch to return that the game needs to continue
  b returncontinue

@ Label for returning 1 on a win
returnwin:
  @ Move the value 1 into r0
  mov r0, #1

  @ Pop registers used
  pop {lr}

  @return
  bx lr

@ Label for returning 0 to continue
returncontinue:
  @ Move the value 0 into r0
  mov r0, #0

  @ Pop registers used
  pop {lr}

  @return
  bx lr

  .size   win_stopwatch, .-win_stopwatch    @@ - symbol size (not req)






@@ Function Header Block
  .align  2               @ Code alignment - 2^n alignment (n=2)
                          @ This causes the assembler to use 4 byte alignment
  .syntax unified         @ Sets the instruction set to the new unified ARM + THUMB
                          @ instructions. The default is divided (separate instruction sets)
  .global determine_outcome @ Make the symbol name for the function visible to the linker
  .code   16              @ 16bit THUMB code (BOTH .code and .thumb_func are required)
  .thumb_func             @ Specifies that the following symbol is the name of a THUMB
                          @ encoded function. Necessary for interlinking between ARM and THUMB code.
  .type   determine_outcome, %function   @ Declares that the symbol is a function (not strictly required)

@ Function Declaration :  void determine_outcome(void)
@
@ Input:   void
@ Returns: void
@
determine_outcome:
  @ Push registers used
  push {r4, r5, lr}

  @ Load the address of the currentLed into r1
  ldr r1, =currentLed

  @ Load the value of the currentLed into r0
  ldr r0, [r1]

  @ Turn off the currentLed
  bl BSP_LED_Off

  @ Load the address of the winningTime into r1
  ldr r1, =winningTime

  @ Load the value of the winningTime into r0
  ldr r0, [r1]

  @ Load the address of the currentTime into r2
  ldr r2, =currentTime

  @ Load the value of the currentTime into r1
  ldr r1, [r2]

  @ Compare the winningTime to the currentTime
  cmp r0, r1

  @ If the currentTime equals the winningTime, the user is a winner
  beq winner

  @ Otherwise the user has lost
  b loser

@ When the user is a winner
winner:
  @ Setup r4 as a counter to turn the lights on and off
  mov r4, #1

@ Loop label for the win
winloop:
  @ Load the address of the label for the LED GPIO into r5
  ldr r5, =LEDaddress

  @ Load the address of the LED GPIO into r5
  ldr r5, [r5]

  @ Get the current light reading from the LED GPIO as a halfword into r0
  ldrh r0, [r5]

  @ Use the bitwise or to set the bit at allLightsOn(0xFF00)
  orr r0, r0, allLightsOn

  @ Write the half word back to the memory address for the GPIO
  strh r0, [r5]

  @ Load the address of the windelay into r1
  ldr r1, =windelay

  @ Load the value of the windelay into r0
  ldr r0, [r1]

  @ Call the busy delay function
  bl busy_delay

  @ Move the value for allLightsOff (0x0008) into r0
  mov r0, allLightsOff

  @ Store the halfword back to the memory address for the GPIO
  strh r0, [r5]

  @ Load the address of the windelay into r1
  ldr r1, =windelay

  @ Load the value of the windelay into r0
  ldr r0, [r1]

  @ Call the busy delay function
  bl busy_delay

  @ Subtract 1 from the counter register
  sub r4, r4, #1

  @ Compare the counter register to 0
  cmp r4, #0

  @ If the counter is greater than or equal to 0, branch to the win loop to flicker the LED again
  bge winloop

  @ Skip over the loss section of the code
  b skiploss

@ When the user is a loser
loser:
  @ Load the address of the winningLed into r1
  ldr r1, =winningLed

  @ Load the value of the winningLed into e0
  ldr r0, [r1]

  @ Turn on the winningLed, indicating a loss
  bl BSP_LED_On

@ Label for skipping the loss section of the code
skiploss:

  @ pop registers used
  pop {r4, r5, lr}

  @return
  bx lr

  .size   determine_outcome, .-determine_outcome    @@ - symbol size (not req)





@ Function Declaration : int busy_delay(int cycles)
@
@ Input: r0 (i.e. r0 holds number of cycles to delay)
@ Returns: r0
@
@ 
busy_delay:
   push {r4}
   mov r4, r0
delay_loop:
   subs r4, r4, #1
   bgt delay_loop
   mov r0, #0                      @ Return zero (always successful)
   pop {r4}
   bx lr                           @ Return (Branch eXchange) to the address in the link register (lr)

@ Assembly file ended by single .end directive on its own line
.end
