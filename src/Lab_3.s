.section .text
.align 2
.globl _start


// -------------------------------------------------------------------------------------
// Name:        Lab_3.S
// Purpose:     This code has 2 parts: the first part is to create a simple counter
//              subroutine that increments from 0x00 to 0xFF, wraps to 0 and continues
//              counting.  There is a 100us delay between the display of the count. 
//		The second part is a reflex meter that will measure how fast
//              a user responds to an event accurate to a 10th of a millisecond.
//              Initially, all LED's are off and after a random amount of time
//              (between 2 and 10 seconds), one LED turns on (LED_6) and then the user
//		presses pushbutton S1.  The press of the button will be monitored by
//		using "polling".
//
// Author:      Julius Olajos
// -------------------------------------------------------------------------------------


_start:

// -------------------------------------------------------------------------------------
// GPIO Control Registers Memory Mapping

    .equ GPIO_BASE_CTRL_ADDR, 0x10012000    // Base address for the GPIO control registers
    .equ GPIO_OUTPUT_EN,      0x08          // address offset for enabling GPIO outputs
    .equ GPIO_OUTPUT_VAL,     0x0C          // Address offset for writing to GPIO outputs
    .equ GPIO_OUTPUT_XOR,     0x40          // Address offset for GPIO Outputs XOR
    .equ GPIO_INPUT_VAL,      0x00          // Address offset for reading GPIO inputs
    .equ GPIO_INPUT_EN,       0x04          // address offset for enabling GPIO inputs
    .equ GPIO_PUE,            0x10          // address offset for internal GPIO pull-up resistor

// -------------------------------------------------------------------------------------
// 8 LEDS, 7 Segment LED Display Pins Register Address Mapping

    .equ GPIO_7SEGLED_PINS,   0x0000023F      // Seven Segment LED Display Pins (7)
    .equ GPIO_LEDBAR_PINS,    0x00FC0C00      // LED Bar Pins (8)
    .equ GPIO_ALL_LED_PINS,   0x00FC0E3F      // All LED Pins (15)
    .equ GPIO_LEDBAR_LED_1,   0x00000800      // LEDBAR LED1

// -------------------------------------------------------------------------------------
// Pushbuttons SW(x) Register Address Mapping

    .equ GPIO_SW_1,           0x00001000      // SW1 pushbutton (bit 12)
    .equ GPIO_SW_2,           0x00002000      // SW2 Pushbutton (bit 13)
    .equ GPIO_ALL_PBS,        0x00003000      // All Pushbutton Pins (bits 12, 13)

// Initialize the GPIO control registers
// -------------------------------------------------------------------------------------

    li t0, GPIO_BASE_CTRL_ADDR          // Load Base Address for GPIO Control Registers
    li t1, GPIO_ALL_LED_PINS            // Load GPIO Register to set GPIO_OUTPUT_EN and GPIO_OUTPUT_XOR registers for all GPIO LED Pins
    sw t1, GPIO_OUTPUT_EN(t0)           // Enable outputs on all GPIO LED Pins
    li t2, 0xFF03F1C0
    sw t2, GPIO_OUTPUT_VAL(t0)          // Set all LED pins to zero to turn off all LEDS.
    li t1, GPIO_SW_1                    // Load GPIO Register to set GPIO_INPUT_EN for input pins
    li t2, GPIO_SW_2
    or t1, t1, t2
    sw t1, GPIO_INPUT_EN(t0)            // Enable inputs on all Pushbutton pins

// -------------------------------------------------------------------------------------

// CONVENTIONS
// Use t3 as a temporary variable for counters and small operations
// a7 - Random number
// a6 - LED value
// a5 - specified delay


INITIAL:
// Initialize random number generator
 	li a7, 0xABCD                   // Initializes register a7 to a 16-bit non-zero value and NOTHING else can write to a7 !!!!

COUNTER:
//   --------------- Place your code here for the 00 - FF counter here ---------------
    li t4, 0
    loop_counter: 
    li t3, 0xFF // 0xFF
        beq t4, t3, COUNTER  
        jal ra, DELAY_100MS
        jal ra, RandomNum // Keep calling random no generator to make the generation more random
        mv a6, t4 
        jal ra, LED_CHANGE // Show current counter value on the LED
        // Poll for sw_2
        li t1, GPIO_SW_2
        lw t5, GPIO_INPUT_VAL(t0)
        and t5, t5, t1
        beqz t5, END_COUNTER
        addi t4, t4, 1
    j loop_counter
    END_COUNTER:
    sw t2, GPIO_OUTPUT_VAL(t0) // Set LEDs to 0 at the start of the reflex meter
// -------------------------------------------------------------------------------------

jal ra, RandomNum

jal ra, DELAY_NS // Random delay
li a6, 0x40 // Turn LED 6 on(0X40 = 0100 0000 in the LED representation)
jal ra, LED_CHANGE
// monitor
li s3, 0 // Reaction time counter
li t1, GPIO_SW_1 // Switch 1 mask
MONITOR_LOOP:
    addi s3, s3, 1 
    lw s7, GPIO_INPUT_VAL(t0) // Poll for switch 1
    and s7, s7, t1
    beqz s7, MONITOR_END
    jal ra, DELAY_100US 

j MONITOR_LOOP
MONITOR_END:
sw t2, GPIO_OUTPUT_VAL(t0) // Reset LEDs

// Display reaction time
DISP_REACTION_TIME:
mv s7, s3 // Temporarily store reaction time

li t5, 4
REACT_TIME_LOOP:
    andi a6, s7, 0xFF // Extract least significant 8-bits
    jal ra, LED_CHANGE
    jal ra, DELAY_2S

    srli s7, s7, 8 // Go to next 8 bits.
    addi t5, t5, -1
    beqz t5, END_REACT_TIME_LOOP
    j REACT_TIME_LOOP
    END_REACT_TIME_LOOP:
    jal DELAY_3S // Total delay of 5s after sequence ends.
    j DISP_REACTION_TIME

RandomNum:
     addi sp, sp, -16
     sw ra, 12(sp)


     li s4, 0x8000		     // Load upper 20 bits
     and t1, a7, s4  		     // Mask to lower 16 bits
     li s4, 0x2000  		     // Load upper 20 bits
     and t3, a7, s4  		     // Mask to lower 16 bits


     slli t3, t3, 2
     xor t3, t1, t3
     li s4, 0x1000  		     // Load upper 20 bits
     and t1, a7, s4		     // Mask to lower 16 bits

     slli t1, t1, 3
     xor t3, t3, t1
     andi t1, a7, 0x0400
     slli t1, t1, 5
     xor t3, t3, t1
     srli t3, t3, 15
     slli a7, a7, 1
     or a7, a7, t3		     // Register a7 holds the random number

     lw ra, 12(sp)
     addi sp, sp, 16
     ret

LED_CHANGE:
    addi sp, sp, -16
    sw ra, 12(sp)

    andi t3, a6, 0x3 // Extract first two bits of the 8-bit number
    sub a6, a6, t3 // Remove those 2 bits
    slli a6, a6, 16 // Shift the remaining six bits to their mapped positions
    slli t3, t3, 10 // Shift the first 2 bits to their mapped positions
    add a6, a6, t3 // Add them again
    sw a6, GPIO_OUTPUT_VAL(t0) // Store

    lw ra, 12(sp)
    addi sp, sp, 16
    ret

DELAY_100US:
     addi sp, sp, -16
     sw ra, 12(sp)

    li t3, 533 
    loop_100us:
        beqz t3, endloop_100us
        addi t3, t3, -1
    j loop_100us
    endloop_100us:

     lw ra, 12(sp)
     addi sp, sp, 16
     ret

DELAY_100MS:
    addi sp, sp, -16
    sw ra, 12(sp)

    li t3, 533333
    loop_100ms:
        beqz t3, endloop_100ms
        addi t3, t3, -1
    j loop_100ms
    endloop_100ms:

    lw ra, 12(sp)
    addi sp, sp, 16
    ret

DELAY_2S:
    addi sp, sp, -16
    sw ra, 12(sp)

    li t3, 10666667
    loop_2s:
        beqz t3, endloop_2s
        addi t3, t3, -1
    j loop_2s
    endloop_2s:

    lw ra, 12(sp)
    addi sp, sp, 16
    ret

DELAY_3S:
    addi sp, sp, -16
    sw ra, 12(sp)

    li t3, 16000000 
    loop_3s:
        beqz t3, endloop_3s
        addi t3, t3, -1
    j loop_3s
    endloop_3s:

    lw ra, 12(sp)
    addi sp, sp, 16
    ret

DELAY_NS: 
    addi sp, sp, -16
    sw ra, 12(sp)

    // a7 -> [20k, 100k]
    andi a0, a7, 0x7F
    li t5, 630
    mul a0, a0, t5 // Scale to 0-80010

    li t5, 0x4e20 // Add 20,000
    add a0, t5, a0

    loop_ns: // Call 100us delay that many times
        beqz a0, endloop_ns
        addi a0, a0, -1
        jal ra, DELAY_100US
    j loop_ns
    endloop_ns: 

    lw ra, 12(sp)
    addi sp, sp, 16
    ret

// POST LAB QUESTIONS:
// Q1:::
// 8bits: 255 (25.5ms)
// 16bits: 6,553.6ms
// 24bits: 1,677,721.5ms
// 32bits: 4,294,967,295ms

// Q2:::
// Average human  reaction times, determined from various studies fall between
// 200-400ms with a standard deviation of 30-150ms. So a 16-bit representation
// is more than enough to measure human reaction times. 
// Linked Study of Reaction times: https://pmc.ncbi.nlm.nih.gov/articles/PMC4374455/

// Q3:::
// For random delay, we extract 7 bits from the (pseudo) randomly generated number.
// This corresponds to a decimal representation of 0-127. We linearly scaled this
// range by multiplying by 630 and adding 20,000. The resulting range is [0-100,010].
// Finally we call our 100us delay subrouting x times, where x is the scaled value
// in our final range. The 100us loop uses 3 instructions and has 533 iterations. 
// If the clock cycle is 16MHz, then we are taking 533 * 3 / 16,000,000 = 99.9375us.
// This gives us an error of 0.0625us, which we can multiply by the maximum, 100010,
// to get a 6250.625us = 0.006250625s error. This is well within the 5% margin; thus,
// our implementation is sound. 