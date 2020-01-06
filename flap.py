# This code runs a simplified version of Flappy Bird
# on an emulated 8x8 LED grid

# Usage: 
# Emulator located at: https://trinket.io/sense-hat
# Copy this code into the window
# Click 'Stop' then 'Run' at the top
# Click on the emulated hardware
# Use arrow keys to dodge red pipes with your green dot

# current bugs:
# 1. previous game's Astronaut position flashes green on first joystick movement
# 2. collision detection is very iffy



from sense_hat import SenseHat
import time
from random import randint

s = SenseHat()          

B = (0, 0, 255)         # Background color (blue)
P = (255, 0, 0)         # Pipe color (red)
A = (0, 255, 0)         # Astronaut's color (green)

gameOver = False        # used for game loop condition

# creates 8 lists of 8 (blue) background pixels
matrix = [[B for col in range(8)] for row in range(8)]

# global vars for initial Astronaut coordinates
x = 0
y = 0


# Converts matrix from 8 lists of 8 pixels, into an array of 64 pixels
# (set_pixels requires this format)
def flatten(matrix):
  f = []
  for row in matrix:
    for pixel in row:
      f.append(pixel)
  return f
 
# Creates a solid pipe in the last column (last pixel of every row), then randomly 
# generates a 3 pixel gap in the Pipe
def genPipes(matrix):
  for row in matrix:
    row[-1] = P
  gap = randint(0,2)
  matrix[gap][-1], matrix[gap + 1][-1], matrix[gap + 2][-1] = B, B, B
  return matrix
  
# moves every pixel to the left one, then creates a new blue column on the right
def movePipes(matrix):
  for row in matrix:
    for i in range(7):
      row[i] = row[i+1]
    row[-1] = B
  return matrix

def drawAstronaut(event):
  global x, y, matrix           # allows function to change global vars
  s.set_pixel(x,y,B)            # erases astronauts previous location to prevent location to prevent doubling
  
  # logic for Astronaut movement, with boundary checks
  if event.action == 'pressed':         # IMPORTANT: skipping <--THIS line leads to doubled inputs, because    
    if event.direction == "up" and y > 0:   # event.action == 'released' with event.direction == 'up'  
      y -= 1                                    # would also execute <--THIS line of code
    elif event.direction == "down" and y < 7:
      y += 1
    elif event.direction == "left" and x > 0:
      x -= 1
    elif event.direction == "right" and x < 7:
      x += 1

  s.set_pixel(x,y,A)          # draw Astronaut in new, moved position
  checkCollision(matrix)      # check if Astronaut has hit Pipe
  
  
# if Astronaut is on a Pipe, lose game
def checkCollision(matrix):   
  global gameOver         # allows setting of global var gameOver
  if matrix[y][x] == P:
    gameOver = True

# whenever the joystick is moved, call drawAstronaut
s.stick.direction_any = drawAstronaut


# "infinite" game loop
while not gameOver: 
  matrix = genPipes(matrix)         # create Pipes in matrix
  checkCollision(matrix)            # check collisions
  for i in range(4):                # this loop breaks every 4 cycles to create new Pipe (above)
    s.set_pixels(flatten(matrix))   # draw game
    s.set_pixel(x,y,A)              # draw Astronaut
    matrix = movePipes(matrix)      # shift game
    checkCollision(matrix)          # check collisions
    if gameOver:                    
      break
    time.sleep(1)                   # wait 1 second
    
# scrolling text when the game ends
s.show_message('GAME OVER')
