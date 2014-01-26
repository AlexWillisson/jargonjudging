#! /usr/bin/env python

import pygame, time, sys, random, os

WIDTH = 60
HEIGHT = 26

def draw ():
    global text, xpos, judging, judges, redx

    screen.fill ((0, 0, 0))

    if judging:
#        screen.blit (judge110, (0, 0))
        for idx in range (len (judges)):
            if judges[idx]:
                screen.blit (redx, (idx * 20, 0))
    else:
        screen.blit (text, (xpos, 0))


    pygame.display.flip ()

def process_input ():
    global paused, judges

    for event in pygame.event.get ():
        if event.type == pygame.QUIT:
            pygame.quit ()
            sys.exit ()
        elif event.type == pygame.KEYDOWN:
            if event.key == pygame.K_ESCAPE:
                pygame.quit ()
                sys.exit ()
        elif event.type == pygame.KEYUP:
            if event.key == pygame.K_p:
                paused ^= True
            elif event.key == pygame.K_SPACE:
                next_word ()
            elif event.key == pygame.K_LEFT:
                judges[0] ^= 1
            elif event.key == pygame.K_UP:
                judges[1] ^= 1
            elif event.key == pygame.K_RIGHT:
                judges[2] ^= 1

def fetch_word ():
    global nouns

    idx = int (random.random () * 2000)
    
    return nouns[idx]
        
def next_word ():
    global judging, text

    judging = False
    text = font.render (fetch_word (), 0, (255, 255, 255))

f = open ("nouns", "r")
contents = f.read ()
lines = contents.split ("\n")
nouns = []
for l in lines:
    if len (l) > 0:
        nouns.append (l)

pygame.init ()
screen = pygame.display.set_mode ((WIDTH, HEIGHT))
pygame.display.set_caption ("technobabble taboo")

fps = 60
framestep = 1.0 / fps

last_time = time.time ()

paused = True

font = pygame.font.Font ("/usr/share/fonts/opentype/freefont/FreeSansBold.otf",
                         26)
xpos = 60

scroll_rate = 100
repeat = 0
judging = False
feedfile = "feed.png"

judges = [0, 0, 0]

judge110 = pygame.image.load ("judge110.png")
redx = pygame.image.load ("x.png")

text = font.render (fetch_word (), 0, (255, 255, 255))

while True:
    t = framestep - (time.time () - last_time)
    if t > 0:
        time.sleep (t)

    dt = time.time () - last_time

    if not judging:
        xpos -= scroll_rate * dt

        if xpos + text.get_width () < 0:
            if repeat == 0:
                xpos = 60
                repeat = 1
            else:
                xpos = 60
                repeat = 0
                judging = True

    process_input ()

    draw ()

    if os.path.getatime (feedfile) > os.path.getmtime (feedfile):
        pygame.image.save (screen, feedfile)

    last_time = time.time ()
