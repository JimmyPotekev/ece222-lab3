# ece222-lab3
This project was developed by Jimmy Potekev and Aditya as part of ECE-222 Lab 3. It is written in RISC-V assembly and demonstrates GPIO control, polling, delays, and pseudo-random number generation.

Features

Counter Mode:

Counts from 0x00 to 0xFF on an 8-LED bar.

Wraps back to zero and continues.

Includes a 100 ms delay between increments.

Reflex Timer Mode:

After a random delay (2–10 seconds), a trigger LED turns on.

User presses SW1 pushbutton as fast as possible.

Reaction time is measured with 0.1 ms resolution and displayed across the 8-LED bar in segments.

Technical Details

GPIO control used for LEDs and pushbuttons.

Pseudo-random generator based on bitwise operations to vary start delay.

Polling used for pushbutton input detection.

Delay routines implemented for 100 µs, 100 ms, 2 s, 3 s, and variable ranges.

Reaction times are displayed sequentially on the LED bar with hold delays for readability.
