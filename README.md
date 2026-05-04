# VGA Controller with Pong

## Overview
A VGA controller implemented in VHDL on a Xilinx Spartan-3E FPGA that renders a playable Pong game on a 640x480 resolution 60 Hz display. The controller generates VGA synchronization signals and drives RGB output to allow the rendering of both static and dynamic components of the Pong game.

## Requirements
### Hardware
- Xilinx Spartan-3E XCS500E FPGA
- 640x480 Resolution 60 Hz VGA Monitor
### Software 
- Xilinx ISE 12.4

## How It Works
The VGA controller is a digital circuit responsible for producing synchronization signals and pixel clock required to display images on a monitor. It coordinates these signals on an active display region, enabling the display of images in real time. Graphics are produced by drawing each pixel onto the screen sequentially, refreshing the whole screen line-by-line and frame-by-frame. 

The Video Graphics Array (VGA) standard defines the timing parameters needed for a 640x480 resolution display at 60 Hz. Each line and frame starts with the active display region, where pixel data is output to the monitor. After the active display, the front porch creates a short delay before the sync signal, giving the monitor time to prepare. The HSYNC or VSYNC pulse is then sent to the monitor, signaling the end of a line or frame respectively. Following the sync pulses, the back porch is sent, which allows the monitor to stabilize before the next active display. The following timing parameters are defined for a 640x480 resolution display at 60 Hz under the VGA standard: 
| Parameter | Horizontal | Vertical | 
|-----------|------------|----------|
| Active Display | 640 pixels | 480 lines |
| Front Porch | 16 pixels| 10 lines |
| Sync Pulse | 96 pixels | 2 lines |
| Back Porch | 48 pixels | 33 lines |
| **Total** | **800 pixels** | **525 lines** |

<img width="1297" height="836" alt="image" src="https://github.com/user-attachments/assets/0d649c52-3e71-46dd-a51b-0a6ee1ef4511" />

*VGA 640x480 frame layout, the front porches, sync pulses and back porches make up the blanking region, which extends the frame to 800x525*

To display an image on a monitor, the VGA controller must drive a pixel clock that determines how fast the pixels are written to the screen, based on the display resolution and refresh rate. The FPGA operates on an onboard clock, independent of any display standard, requiring a pixel clock of the right frequency to drive a VGA display derived from the FPGA clock. To find the required pixel clock frequency we use the following formula:

$$Pixel\ Clock = Total\ Pixels\ per\ Frame \times Refresh\ Rate$$
$$800 \times 525 \times 60 = 25,200,000 Hz \approx 25\ MHz$$

Where the total pixel count represents every pixel the controller must clock through in a single frame, including both the active display and blanking regions, multiplied by the refresh rate, which provides the number of pixels that must be driven per second. As the Spartan-3E runs at 50 MHz, this is achieved through a clock divider, which divides the onboard clock by toggling on every rising edge of the 50 MHz FPGA clock, producing a 25 MHz pixel clock. 

The game of pong features two types of elements, static and dynamic. Static elements do not move, and are drawn the same every frame, the border and middle dashed line are the only static elements of the Pong game. The dynamic elements in the Pong game are the ball and the two paddles on the right and left side of the screen. Dynamic elements move, requiring extra logic to ensure smooth movement and so they don't behave unexpectedly, like teleporting across the screen or screen tearing. To ensure smooth movement, the dynamic elements must update every frame, which requires them to wait for a frame to complete before updating. This was found using the following calculation: 

$$Input\ Delay\ Tick\ Counter = Pixel\ Clock\ Rate \div Refresh\ Rate$$
$$25 MHz \div 60 Hz = 416,666\ Clock\ Cycles$$

Where the number of clock cycles required per frame are found by dividing the pixel clock rate by the refresh rate. This is then used in a counter, where once the counter reaches 416,666 cycles, a tick signal is set to 1, and the game logic updates, and then reset for the next frame. The paddles are controlled using four switches found on the FPGA, two per paddle, one switch to move the paddle up and one switch to move the paddle down. The specific ball logic and how it interacts with all of the elements in the game can be found in the process diagram in the Architecture section.  

## Architecture
The symbol and block diagrams below show the general architecture of this system. The FPGA provides the switch and clock inputs to the VGA controller, which in turn provides the RGB, h_sync, v_sync and pixel clock signals to the VGA monitor to produce the image. 

<img width="1081" height="1118" alt="image" src="https://github.com/user-attachments/assets/20c2ea85-509f-4b9d-b449-276066f87955" />

*Symbol and block diagrams for the VGA controller, FPGA (with all relevant inputs and outputs) and VGA monitor*

The process diagram below shows the ball logic, including movement, collision detection, and bouncing behaviour. 

<img width="985" height="1113" alt="image" src="https://github.com/user-attachments/assets/2c8fc02a-1082-4189-9e75-9f89a895a32e" />

*Process diagram for the ball logic in the game of Pong*

## Results
Below are images that show the game of pong on the VGA display.

<img width="1056" height="913" alt="image" src="https://github.com/user-attachments/assets/89ba4c56-c946-4d58-bfe8-fa8d1158f893" />

*Pong with the ball in the bottom right corner*

<img width="1107" height="858" alt="image" src="https://github.com/user-attachments/assets/9621638d-e9da-438b-9135-d28f9fa7569f" />

*Pong with the ball about to hit the paddle*

<img width="1028" height="787" alt="image" src="https://github.com/user-attachments/assets/8a15302f-2cd9-47bf-8753-d8e9b7bbc94d" />

*Pong with the ball about to score*

<img width="1120" height="863" alt="image" src="https://github.com/user-attachments/assets/4aa03a99-bc28-41c2-bd1b-d9d1e075e4a9" />

*Pong with the ball after scoring, turning pink and leaving the screen*





