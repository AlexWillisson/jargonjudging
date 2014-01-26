#! /usr/bin/env python

import pygame, time, sys, random, os

if False:
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
    global text, xpos, ypos, judging, judges, redx, SCALE, screen, vlla, stext 
    vlla_xpos

    screen.fill ((0, 0, 0))
    vlla.fill ((0, 0, 0))

    if judging:
        for idx in range (len (judges)):
            if judges[idx]:
                screen.blit (pygame.transform.scale (redx,
                                                     (20 * SCALE, 26 * SCALE)),
                             (idx * 20 * SCALE, 0))
                vlla.blit (redx, (idx * 20, 0))
    else:
        screen.blit (text, (xpos, ypos))
        vlla.blit (stext, (vlla_xpos, 0))

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
    global judging, text, round_start, xpos, ypos, judges, stext, vlla_xpos

    judging = False
    judges = [0, 0, 0]
    round_start = time.time ()
    word = fetch_word ()
    text = font.render (word, 0, (255, 255, 255))
    stext = sfont.render (word, 0, (255, 255, 255))

    vlla_xpos = 60
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
sfont = pygame.font.Font ("/usr/share/fonts/opentype/freefont/FreeSansBold.otf",
                          26)
xpos = WIDTH
ypos = HEIGHT / 2

scroll_rate = 100 * (WIDTH / 60)
vlla_scroll_rate = 100
repeat = 0
judging = False
feedfile = "feed.png"

judges = [0, 0, 0]

redx = pygame.image.load ("x.png")

next_word ()
round_start = time.time ()

vlla = pygame.Surface ((60, 26))

while True:
    t = framestep - (time.time () - last_time)
    if t > 0:
        time.sleep (t)

    now = time.time ()

    dt = now - last_time

    if not judging:
        vlla_xpos -= vlla_scroll_rate * dt

        if vlla_xpos + stext.get_width () < 0:
            if repeat == 0:
                vlla_xpos = 60
                repeat = 1
            else:
                vlla_xpos = 60
                repeat = 0
                judging = True

        if SCROLL:
            xpos -= scroll_rate * dt

            if xpos + text.get_width () < 0:
                xpos = WIDTH

    process_input ()

    draw ()

    if os.path.getatime (feedfile) > os.path.getmtime (feedfile):
        pygame.image.save (vlla, feedfile)

    last_time = time.time ()
