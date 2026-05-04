# VGA Controller with Pong

## Overview
A VGA controller implemented in VHDL on a Xilinx Spartan-3E FPGA that renders a playable Pong game on a 640x480 resolution 60 Hz display. The controller generates VGA synchronization signals and drives RGB output to allow the rendering of both static and dynamic components of the Pong game.

## Requirements
### Hardware
- Xilinx Spartan-3E XCS500E FPGA
- 640x480 Resolution 60 Hz VGA Monitor
### Software 
- Xilinx ISE 12.4

## How It works
The VGA controller is a digital circuit responsible for producing synchronization signals and pixel clock required to display images on a monitor. It coordinates these signals on an active display region, enabling the display of images in real time. Graphics are produced by drawing each pixel onto the screen sequentially, refreshing the whole screen line-by-line and frame-by-frame. 

To display an image on a monitor, the VGA controller must drive a pixel clock that determines how fast the pixels are written to the screen, based on the display resolution and refresh rate. The FPGA operates on an onboard clock, independent of any display standard, requiring a pixel clock of the right frequency to drive a VGA display derived from the FPGA clock. This is achieved through a clock divider, which divides the onboard clock down to the required pixel clock frequency. 

The

## Architecture

## Results
