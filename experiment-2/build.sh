#!/bin/bash

rgbasm -o main.o main.asm
rgblink -d -o maze.gb main.o
rgbfix -v -p 0 maze.gb