"""Original 0.47 anatomical bodies and cut garments for Emberfall.

Authored numerical surface profiles, no downloaded/scanned geometry. Coordinates
are the existing Y-up anatomical part spaces; this module never changes rig rests.
The shared Nyra head/hair are deliberately outside this module.
"""
import math

PI=math.pi
TAU=PI*2

def surface(a,part,mat,profiles,sides=20,sub=2,relief=None):
    """Smooth cross sections (y,rx,rz,cx,cz), with anatomical rest-space relief."""
    rings=[]
    for j in range(len(profiles)-1):
        p0=profiles[max(0,j-1)];p1=profiles[j]
        p2=profiles[j+1];p3=profiles[min(len(profiles)-1,j+2)]
        for k in range(sub):
            t=k/sub
            values=[p1[0]+(p2[0]-p1[0])*t]
            for axis in range(1,5):
                values.append(.5*((2*p1[axis])+(-p0[axis]+p2[axis])*t+
                    (2*p0[axis]-5*p1[axis]+4*p2[axis]-p3[axis])*t*t+
                    (-p0[axis]+3*p1[axis]-3*p2[axis]+p3[axis])*t*t*t))
            rings.append(values)
    rings.append(profiles[-1]);vertices=[]
    for y,rx,rz,cx,cz in rings:
        for k in range(sides):
            angle=TAU*k/sides
            x=cx+max(.001,rx)*math.sin(angle)
            z=cz+max(.001,rz)*math.cos(angle)
            if relief: x,z=relief(x,y,z,angle)
            vertices.append((x,y,z))
    faces=[]
    for j in range(len(rings)-1):
        for k in range(sides):
            n=(k+1)%sides
            faces.append((j*sides+k,j*sides+n,(j+1)*sides+n,(j+1)*sides+k))
    faces.extend([tuple(reversed(range(sides))),tuple((len(rings)-1)*sides+k for k in range(sides))])
    return a.mesh(part,mat,vertices,faces)

def gauss(value,center,width):
    return math.exp(-((value-center)/width)**2)

def boot(a,part,armor,nyra):
    # The foot is swept along its actual length: round toe, ball, instep, heel.
    # Its sole stays at the established -0.47 m contact plane.
    width=.92 if nyra else 1.0
    naked=a.ACTIVE_MODEL=='raider'
    material='skin' if naked else 'leather'
    profiles=[(-.251,.005,.006,-.443),(-.239,.038,.020,-.442),
        (-.207,.064,.030,-.438),(-.153,.078,.037,-.433),
        (-.094,.074,.040,-.430),(-.038,.064,.054,-.416),
        (.012,.056,.066,-.402),(.061,.053,.064,-.400),
        (.090,.045,.047,-.418),(.099,.012,.016,-.432)]
    verts=[];cols=20
    for z,rx,ry,cy in profiles:
        for k in range(cols):
            t=TAU*k/cols
            verts.append((math.sin(t)*rx*width,max(-.470,cy+math.cos(t)*ry),z))
    faces=[]
    for j in range(len(profiles)-1):
        for k in range(cols):
            n=(k+1)%cols
            faces.append((j*cols+k,(j+1)*cols+k,(j+1)*cols+n,j*cols+n))
    faces.extend([tuple(range(cols)),tuple(reversed([(len(profiles)-1)*cols+k for k in range(cols)]))])
    a.mesh(part,material,verts,faces)
    surface(a,part,material,[(-.407,.050,.054,0,.015),(-.333,.047,.056,0,.012),
        (-.262,.060,.071,0,.025),(-.177,.076,.077,0,.033),
        (-.098,.074,.067,0,.020),(-.038,.062,.059,0,.009),
        (.022,.058,.058,0,0)],sides=18,sub=2)
    if naked:
        a.strap(part,'bone',[(0,-.045,-.060),(0,-.149,-.051),(0,-.274,-.041)],.013)
        return
    # Long greave planes follow the tibia. A small flared top becomes the knee
    # instead of the previous shiny isolated ball perched on a cylindrical boot.
    a.formed_plate(part,armor,[(-.309,.053,.067,.006),(-.225,.065,.080,.012),
        (-.132,.077,.087,.014),(-.061,.071,.078,.006),
        (-.012,.062,.069,0),(.050,.052,.066,-.005)],arc=PI*1.10,ridge=.008)
    # Thin knee wing and ankle buckle articulate separately from the main plane.
    a.formed_plate(part,'silver',[(.001,.066,.076,-.005),(.047,.056,.073,-.005)],arc=PI*.89,ridge=.006)
    for side in [-1,1]:
        a.strap(part,'leather',[(side*.050,-.301,-.044),(side*.062,-.281,.022),
            (side*.050,-.298,.069)],.018)

def hand(a,part,side,monstrous=False):
    mat='skin' if monstrous else 'leather'
    # Back of hand, metacarpals and thenar pad share one tapered glove surface.
    surface(a,part,mat,[(-.663,.033,.018,0,.025),(-.639,.045,.023,0,.029),
        (-.584,.046,.025,0,.031),(-.543,.037,.023,0,.025),
        (-.525,.029,.023,0,.020)],sides=16,sub=2)
    for finger in range(4):
        y=-.548-finger*.026
        a.tube(part,mat,[(side*.030,y,.029),(side*.044,y-.002,.003),
            (side*.029,y-.005,-.035),(-side*.017,y-.006,-.038),
            (-side*.028,y-.004,-.021)],[.010,.011,.010,.008,.005],7,2)
    a.tube(part,mat,[(-side*.032,-.549,.024),(-side*.051,-.570,.002),
        (-side*.036,-.591,-.034),(side*.006,-.601,-.040)],
        [.017,.016,.012,.007],8,3)
    if not monstrous:
        # A shaped lighter metal/leather backplate keeps the moving hand clear
        # against a dark torso while allowing the actual fingers to enclose grip.
        vertices=[(0,-.586,.070),(-.029,-.620,.052),(.029,-.620,.052),
            (.033,-.580,.058),(.024,-.548,.044),(-.024,-.548,.044),(-.033,-.580,.058)]
        a.mesh(part,'silver',vertices,[(0,i+1,(i+1)%6+1) for i in range(6)])


def limbs(a,armor,cloth,monstrous=False,slender=False,nyra=False):
    w=.87 if slender else (1.05 if a.ACTIVE_MODEL=='bulwark' else .91 if a.ACTIVE_MODEL=='elite' else 1.0)
    for side in [-1,1]:
        arm='ArmL' if side<0 else 'ArmR';leg='LegL' if side<0 else 'LegR';knee='KneeL' if side<0 else 'KneeR'
        def anatomy(x,y,z,angle):
            front=max(0,-math.cos(angle))
            z-=.007*gauss(y,-.17,.11)*front
            z+=.005*gauss(y,-.305,.035)*front
            return x,z
        profiles=[(-.559,.031*w,.034,0,.014),(-.505,.040*w,.039,side*.001,.012),
            (-.436,.054*w,.046,-side*.006,.001),(-.368,.051*w,.047,-side*.009,.005),
            (-.310,.042*w,.044,-side*.010,.016),(-.262,.051*w,.045,-side*.008,.018),
            (-.185,.065*w,.063,-side*.009,.008),(-.093,.077*w,.076,-side*.005,.002),
            (-.022,.089*w,.086,0,.008),(.039,.071*w,.072,0,.010),(.084,.010,.018,-side*.002,.007)]
        surface(a,arm,'skin' if monstrous else cloth,profiles,sides=20,sub=2,relief=anatomy)
        if not monstrous:
            if not nyra and a.ACTIVE_MODEL not in ('guardian_0','guardian_3'):
                a.pauldron(arm,armor,side,.86 if slender else 1.05,2)
            # Single shaped vambrace with wrist flare, rather than a cylinder
            # plus an unrelated ball at the elbow.
            a.formed_plate(arm,armor,[(-.540,.039*w,.048,.012),
                (-.492,.045*w,.053,.007),(-.422,.063*w,.063,.003),
                (-.357,.057*w,.064,.007),(-.292,.046*w,.057,.006)],arc=PI*1.17,ridge=.009)
            a.strap(arm,'gold',[(-.037*w,-.510,.023),(0,-.501,.061),(.037*w,-.510,.023)],.010)
        else:
            # The elbow is a physical bony landmark integrated with tendon skin.
            a.tube(arm,'skin',[(side*.013,-.489,-.027),(side*.018,-.395,-.043),
                (side*.015,-.322,-.027)],[.004,.008,.003],6,3)
        hand(a,arm,side,monstrous)
        surface(a,leg,'skin' if monstrous else cloth,[(-.438,.052*w,.055,0,.002),(-.358,.064*w,.068,0,.004),
            (-.251,.083*w,.086,side*.008,.008),(-.151,.100*w,.107,side*.011,.015),
            (-.058,.112*w,.115,side*.006,.014),(.045,.111*w,.112,0,.004)],sides=18,sub=2)
        boot(a,knee,armor,nyra)

def torso(a,armor,cloth,slender=False,nyra=False):
    w=(.81 if a.ACTIVE_MODEL=='hexer' else .89) if slender else (1.07 if a.ACTIVE_MODEL=='bulwark' else .91 if a.ACTIVE_MODEL=='elite' else 1.0)
    def tailoring(x,y,z,angle):
        front=max(0,-math.cos(angle));back=max(0,math.cos(angle))
        # Sternum/scapula and waist are broad body planes, not uniform barrels.
        z-=.012*gauss(y,1.32,.15)*gauss(x,0,.09)*front
        z+=.009*gauss(y,1.38,.13)*(gauss(x,-.12,.06)+gauss(x,.12,.06))*back
        z-=.012*math.sin(y*29+abs(x)*16)*gauss(y,1.075,.11)*front
        return x,z
    surface(a,'Body',cloth,[(.873,.166*w,.122,0,.006),(.977,.172*w,.130,0,.004),
        (1.072,.175*w,.127,0,0),(1.171,.196*w,.139,0,0),
        (1.283,.236*w,.164,0,.002),(1.385,.257*w,.165,0,.005),
        (1.460,.260*w,.145,0,.011),(1.505,.214*w,.117,0,.013),
        (1.554,.112,.075,0,.007),(1.590,.060,.060,0,.003)],sides=32,sub=2,relief=tailoring)
    # Functional broad belt closes on the waist; no jewelry ring around its rim.
    surface(a,'Body','leather',[(.910,.173*w,.130,0,.006),(.957,.181*w,.137,0,.002),
        (.994,.176*w,.131,0,0)],sides=24,sub=1)
    a.gem('Body',(0,.950,-.144),.025,'ember' if armor=='bronze' else 'soul')
    a.strap('Body','gold',[(-.027,.985,-.143),(-.027,.933,-.146),(.027,.933,-.146),(.027,.985,-.143)],.005)
    if not slender:
        a.cuirass(armor,False)
        surface(a,'Body','leather',[(1.52,.076,.065,0,0),(1.605,.071,.066,0,0),
            (1.706,.060,.059,0,0)],sides=18,sub=2)
        a.fitted_collar(cloth,armor,True)
    else:
        # Raised seam joins the shaped breast/shoulder planes, with one clasp.
        for side in [-1,1]:
            a.strap('Body',cloth,[(side*.14,1.485,-.098),(side*.154,1.326,-.145),
                (side*.088,1.087,-.125)],.014)
        a.tube('Body','bronze',[(0,1.43,-.163),(0,1.367,-.183)],.005,6,2)

def backplate(a,armor,nyra):
    # The normal gameplay view sees +Z: a broad shaped backplate must exist.
    w=.89 if nyra else 1.0
    profiles=[(1.105,.185*w,.139),(1.211,.217*w,.164),
        (1.334,.261*w,.178),(1.432,.270*w,.154),(1.506,.199*w,.111)]
    verts=[];cols=16
    for y,rx,rz in profiles:
        for k in range(cols+1):
            angle=-PI*.56+PI*1.12*k/cols
            verts.append((rx*math.sin(angle),y,rz*math.cos(angle)+.012))
    faces=[]
    for j in range(len(profiles)-1):
        for k in range(cols):
            q=j*(cols+1)+k;faces.append((q,q+1,q+cols+2,q+cols+1))
    obj=a.mesh('Body',armor,verts,faces)
    m=obj.modifiers.new('Forged back plate edge','SOLIDIFY');m.thickness=.008


def cape(a,cloth,regal=False):
    # Dark cloth stays behind the torso, not behind every hand silhouette.
    name=a.ACTIVE_MODEL
    if name=='ranger':
        offset=(-.105,0,0);top_width=.128;end_width=.180;bottom=-.64
    elif name=='arcanist':
        offset=(0,0,0);top_width=.130;end_width=.175;bottom=-.80
    elif name=='vowkeeper':
        offset=(-.035,0,0);top_width=.157;end_width=.205;bottom=-.87
    else:
        offset=(0,0,0);top_width=.188;end_width=.300 if regal else .215;bottom=-1.13 if regal else -.88
    a.tailored_drape('Cape',cloth,.025,bottom,top_width,end_width,.035,.165,
        PI*.96,5,regal,offset=offset,thickness=.008)
    # One sewn oath spine, not three competing metal lines.
    a.strap('Cape','bronze',[(offset[0],-.07,.050),(offset[0],bottom*.65,.144),
        (offset[0],bottom+.08,.215)],.012)
    a.tube('Cape','gold',[(offset[0]-.035,-.115,.055),(offset[0],-.157,.063),
        (offset[0]+.035,-.115,.055)],.005,6,2)


def skirt(a,cloth,long=True):
    # Short tunics expose weight transfer. A caster keeps two long side gores,
    # with a clear front/back slit instead of a dark closed bell around the legs.
    ranger=a.ACTIVE_MODEL=='ranger'
    top=.925;bottom=.65 if ranger else .575
    if long:
        for side in [-1,1]:
            a.coat_panel('Body',cloth,side,.925,.18,.087)
        a.tailored_drape('Body',cloth,top,.16,.166,.262,.125,.183,PI*1.04,5,False,thickness=.007)
    else:
        a.tailored_drape('Body',cloth,top,bottom,.168,.216,.126,.175,PI*1.43,6,False,thickness=.008)
        for side in [-1,1]: a.coat_panel('Body',cloth,side,top,bottom+.03,.076)


def raider_body(a):
    def anatomy(x,y,z,angle):
        front=max(0,-math.cos(angle))**3;back=max(0,math.cos(angle))**3
        # Rib cage is one sculpted chest wall. The paired oblique ridges are
        # embedded relief with intercostal valleys, never pasted-on rods.
        rib=0
        for j in range(5):
            rib+=.015*gauss(y,1.19+j*.046+abs(x)*.22,.013)
        z-=front*(rib*gauss(x,0,.22)+.016*gauss(x,0,.023)*gauss(y,1.31,.19))
        z+=front*.018*gauss(x,0,.11)*gauss(y,1.08,.10)
        z-=front*.014*(gauss(x,.135,.054)+gauss(x,-.135,.054))*gauss(y,1.458,.03)
        z+=back*.008*gauss(x,0,.027)*gauss(y,1.32,.24)
        return x,z
    surface(a,'Body','skin',[(.835,.114,.088,0,.008),(.967,.126,.091,0,.001),
        (1.091,.122,.089,0,0),(1.213,.174,.123,0,.006),
        (1.338,.210,.134,0,.019),(1.435,.240,.126,0,.027),
        (1.490,.247,.110,0,.032),(1.534,.246,.092,0,.032),
        (1.581,.078,.064,0,.024)],sides=40,sub=7,relief=anatomy)
    # A single exposed sternum remnant and broken collarbone show its nature;
    # the rest of the thorax is a coherent weathered anatomical surface.
    a.strap('Body','bone',[(0,1.425,-.132),(0,1.31,-.164),(0,1.21,-.142)],.016)
    for side in [-1,1]:
        a.tube('Body','bone',[(side*.025,1.485,-.080),(side*.098,1.477,-.106),
            (side*.165,1.459,-.081)],[.009,.013,.004],7,3)


def skull(a,part='Body'):
    """Continuous adult cranium, zygomatic arches, orbit recesses and jaw."""
    surface(a,part,'bone',[(1.54,.048,.052,0,.012),(1.63,.046,.050,0,.010),
        (1.707,.046,.049,0,0)],sides=18,sub=2)
    def planes(x,y,z,angle):
        front=max(0,-math.cos(angle))**4
        relief=-.015*gauss(x,0,.015)*gauss(y,1.800,.033)
        for side in [-1,1]:
            relief+=.027*gauss(x,side*.044,.022)*gauss(y,1.814,.023)
            relief-=.012*gauss(x,side*.042,.028)*gauss(y,1.849,.012)
            relief-=.012*gauss(x,side*.077,.020)*gauss(y,1.772,.015)
        relief+=.008*gauss(x,0,.044)*gauss(y,1.736,.015)
        return x,z+relief*front
    surface(a,part,'bone',[(1.667,.033,.044,0,-.024),(1.693,.058,.058,0,-.020),
        (1.722,.069,.064,0,-.016),(1.754,.094,.073,0,-.007),
        (1.787,.105,.087,0,.002),(1.822,.103,.094,0,.009),
        (1.863,.102,.096,0,.014),(1.905,.088,.084,0,.018),
        (1.935,.055,.052,0,.021),(1.954,.003,.005,0,.022)],
        sides=48,sub=3,relief=planes)
    for side in [-1,1]:
        a.ellipsoid(part,'dark',(side*.044,1.813,-.083),(.020,.016,.003),16,8)
        a.gem(part,(side*.044,1.813,-.088),.0045,'soul')
    a.mesh(part,'dark',[(-.009,1.789,-.111),(-.014,1.759,-.088),
        (0,1.753,-.090),(.014,1.759,-.088),(.009,1.789,-.111)],[(4,3,2,1,0)])
    a.tube(part,'dark',[(-.031,1.716,-.073),(0,1.710,-.084),(.031,1.716,-.073)],.0045,6,3)
    for tooth in range(6):
        x=(tooth-2.5)*.009
        a.ellipsoid(part,'bone',(x,1.714,-.084+.013*abs(x)/.027),(.0038,.006,.0032),8,4)
