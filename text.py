#! /usr/bin/env python

import pygame, time, sys, random, os

if True:
    SCALE = 1
    WIDTH = 60
    HEIGHT = 26
    FONTSIZE = 26
    SCROLL = True
else:
    SCALE = 30
    WIDTH = 60 * SCALE
    HEIGHT = 26 * SCALE
    FONTSIZE = 240
    SCROLL = False

def draw ():
    global text, xpos, ypos, judging, judges, redx, SCALE

    screen.fill ((0, 0, 0))

    if judging:
        for idx in range (len (judges)):
            if judges[idx]:
                screen.blit (pygame.transform.scale (redx,
                                                     (20 * SCALE, 26 * SCALE)),
                             (idx * 20 * SCALE, 0))
    else:
        screen.blit (text, (xpos, ypos))

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
    global judging, text, round_start, xpos, ypos, judges

    judging = False
    judges = [0, 0, 0]
    round_start = time.time ()
    text = font.render (fetch_word (), 0, (255, 255, 255))

    if SCROLL:
        xpos = WIDTH
        ypos = (HEIGHT / 2) - (text.get_height() / 2)
    else:
        xpos = (WIDTH / 2) - (text.get_width () / 2)
        ypos = (HEIGHT / 2) - (text.get_height() / 2)

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
                         FONTSIZE)
xpos = WIDTH
ypos = HEIGHT / 2

scroll_rate = 100 * (WIDTH / 60)
repeat = 0
judging = False
feedfile = "feed.png"

judges = [0, 0, 0]

redx = pygame.image.load ("x.png")

next_word ()
round_start = time.time ()

while True:
    t = framestep - (time.time () - last_time)
    if t > 0:
        time.sleep (t)

    now = time.time ()

    dt = now - last_time

    if not judging:
        if SCROLL:
            xpos -= scroll_rate * dt

            if xpos + text.get_width () < 0:
                if repeat == 0:
                    xpos = WIDTH
                    repeat = 1
                else:
                    xpos = WIDTH
                    repeat = 0
                    judging = True
        else:
            if now - round_start > 3:
                judging = True

    process_input ()

    draw ()

    if os.path.getatime (feedfile) > os.path.getmtime (feedfile):
        pygame.image.save (screen, feedfile)

    last_time = time.time ()
