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


To display an image on a monitor, the VGA controller must drive a pixel clock that determines how fast the pixels are written to the screen, based on the display resolution and refresh rate. The FPGA operates on an onboard clock, independent of any display standard, requiring a pixel clock of the right frequency to drive a VGA display derived from the FPGA clock. To find the required pixel clock frequency we use the following formula:

$$Pixel\ Clock = Total\ Pixels\ per\ Frame \times Refresh\ Rate$$
$$800 \times 525 \times 60 = 25,200,000 Hz \approx 25\ MHz$$

Where the total pixel count represents every pixel the controller must clock through in a single frame, including both the active display and blanking regions, multiplied by the refresh rate, which provides the number of pixels that must be driven per second. As the Spartan-3E runs at 50 MHz, this is achieved through a clock divider, which divides the onboard clock by toggling on every rising edge of the 50 MHz FPGA clock, producing a 25 MHz pixel clock. 


## Architecture

## Results
