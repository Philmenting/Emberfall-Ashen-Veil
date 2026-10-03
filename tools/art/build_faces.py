"""Continuous original Nyra head, fitted eyelids and anatomical lip surfaces.

Called by build_characters.py. Geometry uses that author's Y-up source space.
No downloaded head, scanned likeness or external mesh is used.
"""
import math


def build(a, part='Body'):
    pi = math.pi
    profiles = [
        (1.650,.022,.030,-.031), (1.674,.047,.048,-.026),
        (1.701,.072,.070,-.013), (1.732,.086,.088,-.008),
        (1.768,.103,.101,-.012), (1.800,.106,.107,-.010),
        (1.833,.103,.109,-.008), (1.866,.102,.104,-.003),
        (1.900,.094,.092,.004), (1.930,.071,.069,.013),
        (1.951,.026,.026,.016), (1.957,.001,.001,.016),
    ]

    def contour(y):
        i = next((i for i in range(len(profiles)-1) if y <= profiles[i+1][0]),len(profiles)-2)
        lo, hi = profiles[i],profiles[i+1]
        t = max(0,min(1,(y-lo[0])/(hi[0]-lo[0])))
        # Shared derivatives across rows avoid horizontal jaw/forehead bands.
        before=profiles[max(0,i-1)]; after=profiles[min(len(profiles)-1,i+2)]
        span=hi[0]-lo[0]
        values=[]
        for k in range(1,4):
            m0=(hi[k]-before[k])/(hi[0]-before[0])*span
            m1=(after[k]-lo[k])/(after[0]-lo[0])*span
            values.append((2*t**3-3*t*t+1)*lo[k]+(t**3-2*t*t+t)*m0+(-2*t**3+3*t*t)*hi[k]+(t**3-t*t)*m1)
        return values

    def gaussian(x,y,cx,cy,sx,sy):
        return math.exp(-.5*(((x-cx)/sx)**2+((y-cy)/sy)**2))

    vertices, faces = [], []
    rows, columns = 48, 72
    for row in range(rows+1):
        y=1.650+(1.957-1.650)*row/rows
        rx,rz,dz=contour(y)
        for col in range(columns):
            angle=2*pi*col/columns
            x=rx*math.sin(angle)
            z=rz*math.cos(angle)+dz
            front=max(0,-math.cos(angle))**5
            relief=0
            # Nasal bridge, rounded tip, alar wings and shallow philtrum.
            relief-=.025*gaussian(x,y,0,1.812,.014,.037)
            relief-=.034*gaussian(x,y,0,1.777,.016,.012)
            relief+=.003*gaussian(x,y,0,1.750,.005,.010)
            relief-=.008*gaussian(x,y,0,1.734,.027,.016)
            relief-=.008*gaussian(x,y,0,1.689,.032,.012)
            for side in [-1,1]:
                relief-=.011*gaussian(x,y,side*.017,1.771,.009,.008)
                # Orbital recess under a brow; cheekbone transitions into jaw.
                relief+=.015*gaussian(x,y,side*.046,1.821,.023,.012)
                relief-=.006*gaussian(x,y,side*.049,1.844,.028,.009)
                relief-=.013*gaussian(x,y,side*.064,1.790,.028,.018)
                relief+=.004*gaussian(x,y,side*.049,1.746,.016,.020)
            vertices.append((x,y,z+relief*front))
    for row in range(rows):
        for col in range(columns):
            nxt=(col+1)%columns
            faces.append((row*columns+col,row*columns+nxt,(row+1)*columns+nxt,(row+1)*columns+col))
    faces.append(tuple(reversed(range(columns))))
    a.mesh(part,'skin',vertices,faces,True)
    a.loft(part,'skin',[(1.54,.052,.056,.002),(1.62,.055,.060,.001),(1.69,.055,.058,-.003)],sides=32)
    for side in [-1,1]:
        a.ellipsoid(part,'skin',(side*.105,1.798,.007),(.014,.031,.019),24,14)
        a.tube(part,'lip',[(side*.113,1.813,-.001),(side*.117,1.799,-.005),(side*.112,1.784,-.005)],.0018,7,3)
        # Sclera is an almond patch curved over a globe, bounded by skin lids.
        eye_x,eye_y=side*.047,1.821
        ev,ef=[],[]
        for row in range(9):
            v=row/8
            for col in range(25):
                u=col/24
                x=(u-.5)*.046
                arch=math.sin(pi*u)**.85
                y=eye_y+(.0075*(1-v)-.0058*v)*arch+side*x*.045
                z=-.122-.008*arch*math.sin(pi*v)-.002*arch
                ev.append((eye_x+x,y,z))
        for row in range(8):
            for col in range(24):
                k=row*25+col; ef.append((k,k+1,k+26,k+25))
        a.mesh(part,'eye',ev,ef,True)
        for upper in [True,False]:
            lid=[]
            for j in range(17):
                u=j/16; x=(u-.5)*.046; arch=math.sin(pi*u)**.85
                lid.append((eye_x+x,eye_y+(.0081 if upper else -.0066)*arch+side*x*.045,-.1235-.002*arch))
            a.tube(part,'skin',lid,.0026 if upper else .0020,8,1)
        a.ellipsoid(part,'iris',(eye_x,eye_y,-.1303),(.0058,.0058,.0015),24,12)
        a.ellipsoid(part,'dark',(eye_x,eye_y,-.1318),(.0023,.0028,.0007),20,10)
        # Tiny wet catchlight; no heavy black cartoon outline or white eye bead.
        a.ellipsoid(part,'eye',(eye_x-.0014,eye_y+.0017,-.1324),(.00075,.0008,.0004),10,6)
        a.tube(part,'hair_shadow',[(side*.023,1.846,-.126),(side*.046,1.850,-.121),(side*.073,1.842,-.104)], [.0022,.0031,.0011],8,5)
        a.ellipsoid(part,'lip',(side*.014,1.768,-.145),(.0033,.0017,.0015),16,8)
    # Two fitted lip surfaces with a shallow cupid's bow and a restrained seam.
    for upper in [True,False]:
        lv,lf=[],[]
        for row in range(7):
            v=row/6
            for col in range(33):
                t=col/32; x=(t-.5)*.061
                fullness=math.sin(pi*t)**.7
                seam=1.733+ .0008*math.cos(2*pi*t)
                bow=(.0026+.0018*math.sin(2*pi*t)**2)*fullness
                y=seam+(bow if upper else -.005*fullness)*v
                z=-.113-.013*fullness-.0025*math.sin(pi*v)*fullness
                lv.append((x,y,z))
        for row in range(6):
            for col in range(32):
                k=row*33+col
                face=(k,k+1,k+34,k+33)
                lf.append(tuple(reversed(face)) if upper else face)
        a.mesh(part,'lip',lv,lf,True)
    a.tube(part,'lip_shadow',[(-.029,1.733,-.115),(-.014,1.733,-.124),(0,1.734,-.1265),(.014,1.733,-.124),(.029,1.733,-.115)],.00085,7,4)
    # Silver cranial cap with swept narrow locks, not a woven material.
    a.drape(part,'hair_shadow',1.949,1.756,.070,.115,.069,.112,arc=pi*1.63,folds=15,offset=(0,0,.016))
    a.ellipsoid(part,'hair',(0,1.931,.017),(.105,.035,.096),48,18)
    for i in range(23):
        angle=-pi*.79+i*pi*1.58/22
        a.tube(part,'hair',[(math.sin(angle)*.025,1.963,math.cos(angle)*.032+.017),
            (math.sin(angle)*.105,1.926,math.cos(angle)*.105+.017),
            (math.sin(angle)*.118,1.824,math.cos(angle)*.115+.026)], [.008,.009,.0017],7,6)
    for side in [-1,1]:
        for strand in range(4):
            a.tube(part,'hair',[(side*(.004+strand*.005),1.959,-.043),
                (side*(.049+strand*.012),1.927,-.091+strand*.006),
                (side*(.103+strand*.004),1.859,-.052+strand*.010)], [.008,.008,.0015],7,6)
        braid='HairL' if side<0 else 'HairR'
        a.tube(braid,'hair_shadow',[(side*.114,1.832,.034),(side*.137,1.67,.042),(side*.129,1.495,.057)],[.017,.017,.006],9,5)
        for strand in range(3):
            path=[]
            for j in range(20):
                t=j/19; angle=t*2*pi*4+strand*2*pi/3
                path.append((side*(.114+.023*math.sin(t*pi))+.009*math.cos(angle),1.832-.337*t,.034+.023*t+.010*math.sin(angle)))
            a.tube(braid,'hair',path,[.006,.005,.002],6,2)
        a.ring(braid,'gold',(side*.13,1.515,.057),.015,.014,.004)
