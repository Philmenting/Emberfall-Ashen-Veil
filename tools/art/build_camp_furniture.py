"""Original working camp stations. blender -b -t 2 --python tools/art/build_camp_furniture.py"""
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))
import build_characters as author
import build_landmarks as kit
from build_characters import export, tube, ring, loft, mesh, PALETTE

PALETTE.update({'oak': ('493b30', 0, .89), 'parchment': ('b4a581', 0, .98),
                'ink': ('473b32', 0, .98), 'wax': ('b5a986', 0, .93)})

def forge():
    kit.PARTS = author.PARTS
    # Mortared hearth with a real open firebox, deep soot lining and flue.
    for x in [-.56, .56]:
        for row in range(4):
            for z in [-.30, .27]:
                kit.block('stone',(x,.16+row*.30,z),(.35,.29,.55))
    kit.block('recess',(0,.72,-.54),(.83,1.22,.18))
    kit.block('stone',(0,.10,0),(1.55,.20,1.35))
    kit.block('iron',(0,.40,.10),(1.1,.08,1.0))
    for i in range(7):
        kit.block('dark',((i-3)*.12,.46,.12),(.10,.10,.75))
        tube('Body','ember',[((i-3)*.11,.49,-.16),((i-3)*.11,.51,.35)],.021,7,1)
    for i in range(5):
        a=(i-2)*.15
        tube('Body','ember',[(a,.52,-.10),(a+.045,.64+(i%3)*.085,-.06),(a-.02,.75+(i%2)*.07,-.11)],[.042,.025,.005],9,3)
    for y,w,d in [(1.38,1.63,1.35),(1.64,1.35,1.04),(1.94,1.04,.90),(2.25,.80,.73),(2.60,.77,.71)]:
        kit.block('stone',(0,y,-.04),(w,.29,d))
    kit.block('edge',(0,2.81,-.04),(.94,.12,.88))
    for y in [1.28,2.37]: kit.block('iron',(0,y,.49 if y<2 else .345),(1.45 if y<2 else .80,.065,.045))
    # Anvil: flared feet, waist, hardened face and a tapered forged horn.
    loft('Body','oak',[(0,.39,.32,0),(.10,.42,.34,0),(.55,.35,.30,0),(.59,.34,.30,0)],(1.20,0,.80),12)
    for y in [.12,.45]: ring('Body','iron',(1.20,y,.80),.40,.33,.028)
    loft('Body','iron',[(0,.36,.25,0),(.08,.36,.25,0),(.19,.20,.15,0),(.32,.24,.20,0),(.43,.40,.24,0)],(1.20,.59,.80),8)
    kit.block('silver',(1.18,1.075,.80),(.83,.09,.52))
    tube('Body','iron',[(.82,1.04,.80),(.50,1.04,.80),(.28,1.075,.80)],[.20,.12,.018],12,2)
    # Tongs, hammer, and hanging spare tools make the workstation legible.
    tube('Body','oak',[(1.28,1.14,.63),(1.55,1.14,1.13)],.032,10,1)
    kit.block('iron',(1.57,1.14,1.15),(.25,.12,.15))
    for dx in [-.045,.045]:
        tube('Body','iron',[(.83+dx,1.13,.83),(.99+dx,1.14,1.13),(1.10-dx,1.13,1.25)],.015,7,1)
    for x in [-1.40,-.91]:
        kit.block('oak',(x,.97,-.1),(.085,1.94,.095))
    kit.block('oak',(-1.15,1.69,-.1),(.68,.12,.10))
    for i in range(3):
        x=-1.37+i*.22
        ring('Body','iron',(x,1.68,-.035),.048,.026,.012)
        tube('Body','iron',[(x,1.68,0),(x,.82-i*.06,0)],.018,7,1)
        kit.block('iron',(x,.80-i*.06,0),(.12,.08,.065))
    # Stitched bellows rests against the hearth, with timber compression plates.
    for y in [.42,.66]:
        mesh('Body','oak',[(-.85,y,.63),(-1.62,y,.86),(-1.56,y,1.20),(-.81,y,.76)],[(3,2,1,0)],False)
    for y in [.46,.52,.58,.64]:
        tube('Body','leather',[(-.86,y,.65),(-1.61,y,.88),(-1.56,y,1.18),(-.84,y,.75)],.04,8,1)

def shrine():
    kit.PARTS = author.PARTS
    for y,w,d in [(.07,2.65,1.04),(.19,2.43,.89),(.34,2.23,.75)]:
        kit.block('stone',(0,y,0),(w,.14,d))
    for x in [-1.12,1.12]:
        kit.block('edge',(x,.54,-.12),(.15,.50,.65))
        loft('Body','bronze',[(0,.07,.07,0),(.14,.042,.042,0),(.22,.008,.008,0)],(x,.81,-.12),10)
    # Four empty carved recesses are mounts, never unearned guardian rewards.
    for i in range(4):
        x=-.81+i*.54
        kit.block('recess',(x,.63,-.16),(.42,.36,.15))
        for side in [-1,1]:
            kit.block('edge',(x+side*.217,.64,-.15),(.042,.40,.21))
        kit.block('edge',(x,.85,-.16),(.48,.065,.22))
        kit.block('bronze',(x,.41,.26),(.29,.020,.055))
    kit.block('edge',(0,.93,-.20),(2.35,.095,.35))

def table():
    kit.PARTS = author.PARTS
    # Heavy pegged trestles, cross brace, iron straps, and a five-plank top.
    for x in [-1.05, 1.05]:
        kit.block('oak', (x, .12, 0), (.38, .24, 1.38))
        kit.block('oak', (x, .58, 0), (.24, .90, .76))
        kit.block('oak', (x, 1.01, 0), (.36, .18, 1.46))
        for z in [-.45, .45]:
            tube('Body', 'oak', [(x, .2, z), (x, .89, z*.4)], .07, 8, 1)
        for z in [-.69, .69]:
            kit.block('iron', (x, .14, z), (.40, .11, .038))
    kit.block('oak', (0, .43, 0), (2.30, .16, .18))
    for plank in range(5):
        kit.block('oak', (0, 1.16, (plank-2)*.285), (2.86, .17, .278))
    for x in [-1.32, 1.32]:
        kit.block('iron', (x, 1.165, 0), (.075, .178, 1.46))
        for z in [-.56, 0, .56]:
            loft('Body', 'bronze', [(0, .025, .025, 0), (.02, .019, .019, 0)], (x, 1.26, z), 8)
    # Unrolled map with genuine curled edges and a fine raised route in ink.
    mesh('Body', 'parchment', [(-.72,1.251,-.44),(.64,1.251,-.44),(.64,1.251,.45),(-.72,1.251,.45)], [(3,2,1,0)], False)
    for z in [-.45, .46]:
        tube('Body', 'parchment', [(-.73,1.27,z),(.65,1.27,z)], .035, 12, 1)
    route=[(-.54,1.258,.30),(-.33,1.258,.14),(-.37,1.258,-.11),(-.02,1.258,-.19),(.26,1.258,.08),(.44,1.258,-.28)]
    tube('Body','ink',route,.007,5,1)
    for x,y,z in route:
        ring('Body','ink',(x,y,z),.037,.037,.006)
    # Closed leather folio and visible page block, weighted down beside the map.
    for y,mat,sx,sz in [(1.28,'wine',.47,.61),(1.34,'parchment',.43,.57),(1.40,'wine',.47,.61)]:
        kit.block(mat,(1.0,y,-.13),(sx,.055,sz))
    kit.block('bronze',(1.0,1.434,-.13),(.035,.014,.59))
    # Brass candle dish, stem and an irregular spent candle.
    loft('Body','bronze',[(0,.14,.14,0),(.025,.15,.15,0),(.05,.12,.12,0)],(-1.02,1.25,-.43),20)
    loft('Body','wax',[(0,.055,.055,0),(.25,.052,.053,0),(.28,.04,.046,0)],(-1.02,1.30,-.43),16)
    tube('Body','dark',[(-1.02,1.57,-.43),(-1.01,1.615,-.43)],.007,6,1)
    for z in [.24,.45]:
        tube('Body','bronze',[(.85,1.28,z),(1.14,1.28,z)],.018,8,1)

if __name__ == '__main__':
    export('expedition_table', table)
    export('field_forge', forge)
    export('seal_shrine', shrine)
