"""Original sanctuary details. Rebuild with Blender, no external models.

blender -b -t 2 --python tools/art/build_sanctuary.py
Uses the established Y-up mesh/export helpers; never rebuilds character assets.
"""
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))
from build_characters import *

PALETTE.update({
    'stone': ('626b71', 0, .88), 'edge': ('919991', 0, .79),
    'recess': ('242e35', 0, .96),
    'glass': ('71b9ba', 0, .35), 'glass_gold': ('b99b62', 0, .38),
})


def lancet():
    # Three slender lancets with real pointed openings and leaded panes.
    for x in [-.74, 0, .74]:
        top = 3.8 if x == 0 else 3.25
        width = .31
        for side in [-1, 1]:
            tube('Body', 'edge', [(x+side*width, .32, 0),
                 (x+side*width, top-.72, 0), (x+side*width*.72, top-.24, 0),
                 (x, top, 0)], .065, 10, 5)
        points = [(x-width, .36, .04), (x+width, .36, .04),
                  (x+width, top-.72, .04), (x+width*.72, top-.24, .04),
                  (x, top, .04), (x-width*.72, top-.24, .04),
                  (x-width, top-.72, .04)]
        mesh('Body', 'glass', points, [tuple(reversed(range(7)))], False)
        for y in [.8, 1.4, 2.0, 2.6]:
            if y > top-.5: continue
            tube('Body', 'dark', [(x-width, y, -.02), (x, y+.30, -.02),
                 (x+width, y, -.02), (x, y-.30, -.02), (x-width, y, -.02)], .014, 6, 1)
        tube('Body', 'bronze', [(x, .36, -.02), (x, top-.15, -.02)], .018, 6, 1)
        gem('Body', (x, 1.65, -.03), .10, 'glass_gold')
    for x in [-1.22, 1.22]:
        loft('Body', 'stone', [(0,.15,.20,0),(.22,.17,.22,0),
             (.30,.095,.11,0),(3.9,.095,.11,0),(4.1,.14,.17,0)], (x,0,0), 12)
        leaf('Body', 'edge', [(x,4.0,0),(x,4.35,.02),(x,4.55,0)], .10,.07)
    # Trefoil rosette and continuous outer frame.
    for i in range(3):
        a=TAU*i/3
        ring('Body','bronze',(math.sin(a)*.15,3.98+math.cos(a)*.15,-.01),.18,.18,.026,'z')
    for side in [-1,1]:
        tube('Body','stone',[(side*1.22,.20,.13),(side*1.22,3.35,.13),
             (side*.94,3.92,.13),(side*.48,4.33,.13),(0,4.52,.13)], .12,12,6)
    loft('Body','stone',[(0,1.34,.28,0),(.17,1.34,.28,0),(.24,1.27,.24,0)],sides=4)


def intarsia():
    # Flush stone medallion: quiet bronze carving, never emissive danger rings.
    loft('Body','recess',[(0,2.7,2.7,0),(.009,2.7,2.7,0)],sides=96)
    for radius in [2.68,2.46,1.88,.64]:
        ring('Body','bronze',(0,.018,0),radius,radius,.018)
    for i in range(16):
        angle=TAU*i/16
        def p(r,a=angle): return (math.sin(a)*r,.021,math.cos(a)*r)
        tube('Body','edge',[p(.72),p(1.36,angle+.12),p(1.83)],.021,6,4)
        tube('Body','bronze',[p(1.96),p(2.16,angle+.055),p(2.37)],.022,6,3)
        if i%2==0:
            leaf('Body','stone',[p(.13),p(.41,angle+.12),p(.60)],.095,.012)
    for i in range(32):
        angle=TAU*i/32
        tube('Body','bronze',[(math.sin(angle)*2.50,.023,math.cos(angle)*2.50),
             (math.sin(angle+.018)*2.60,.023,math.cos(angle+.018)*2.60)],.012,6,1)


def brazier():
    # Flame position is y=0, matching the existing animated torch shader.
    loft('Body','bronze',[(-1.14,.22,.22,0),(-1.06,.25,.25,0),
         (-.98,.21,.21,0),(-.92,.11,.11,0),(-.30,.08,.08,0),
         (-.22,.16,.16,0),(-.12,.25,.25,0),(0,.29,.29,0),
         (.025,.25,.25,0),(-.07,.16,.16,0)],sides=24)
    for i in range(6):
        a=TAU*i/6
        def p(r,y): return (math.sin(a)*r,y,math.cos(a)*r)
        tube('Body','iron',[p(.13,-.42),p(.31,-.16),p(.30,.12),p(.25,.18)],.025,8,4)
        leaf('Body','gold',[p(.08,-.62),p(.14,-.44),p(.11,-.32)],.035,.018)
    for y,r in [(-1.01,.22),(-.93,.12),(-.28,.12),(-.04,.27)]:
        ring('Body','gold',(0,y,0),r,r,.018)


if __name__ == '__main__':
    export('leaded_lancet',lancet)
    export('sanctuary_intarsia',intarsia)
    export('ceremonial_brazier',brazier)
