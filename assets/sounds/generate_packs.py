"""Offline Relay cue synthesis. Run with Python; writes only beneath this script's directory.
No downloads, API keys or external sound libraries. Existing Glass/Pulse/Soft Tick navigation cues are retained.
"""
from pathlib import Path
import math,random,struct,wave
BASE=Path(__file__).resolve().parent
RATE=44100
PITCH={'left':2100,'right':1960,'source':2220,'category':2080,'settings':2380,'move':2050,'confirm':2520,'back':1740}
def save(path,signal,min_ms=120):
    mono=[0]*88+[round(max(-.95,min(.95,s))*32767) for s in signal]
    mono+=[0]*max(0,round(RATE*min_ms/1000)-len(mono));mono[-1]=0
    stereo=[v for s in mono for v in (s,s)];path.parent.mkdir(parents=True,exist_ok=True)
    with wave.open(str(path),'wb') as w:w.setparams((2,2,RATE,len(mono),'NONE','not compressed'));w.writeframes(struct.pack('<'+'h'*len(stereo),*stereo))
def env(t,d,decay=55):return min(1,t/.002)*math.exp(-t*decay)*min(1,max(0,(d-t)/.006))
def quad_saw(t,f):
    # Four detuned, phase-spread saw voices. A falling harmonic cutoff rounds the transient.
    result=0
    for cents,phase in zip((-10,-3,3,10),(.07,.29,.53,.81)):
        hz=f*2**(cents/1200)
        for h in range(1,11):result+=math.sin(2*math.pi*(hz*t+phase)*h)/h*math.exp(-h*(.12+t*13))
    return result/6
for name,f in PITCH.items():
    d=.065;save(BASE/'synth'/(name+'.wav'),[.18*env(i/RATE,d,52)*quad_saw(i/RATE,f*.36) for i in range(round(d*RATE))])
for pack in ('','synth','pulse','glass'):
    for action in ('play-focus','launch'):
        d=.095 if action=='play-focus' else .190
        signal=[]
        for i in range(round(d*RATE)):
            t=i/RATE
            if action=='play-focus':tone=math.sin(2*math.pi*440*t)+.48*math.sin(2*math.pi*660*t)
            else:
                f=440 if t<.045 else 660 if t<.09 else 880
                tone=math.sin(2*math.pi*f*t)+.22*math.sin(2*math.pi*f*2*t)
            if pack=='synth':tone=.7*tone+.7*quad_saw(t,440 if action=='play-focus' else 660)
            elif pack=='glass':tone+=.30*math.sin(2*math.pi*1214*t)
            elif pack=='pulse':tone=.75*tone+.18*math.sin(2*math.pi*220*t)
            signal.append(.10*env(t,d,24 if action=='play-focus' else 15)*tone)
        save(BASE/pack/(action+'.wav'),signal,120 if action=='play-focus' else 240)
for kind,d in [('swish',.24),('whoosh',.34),('signal',.26)]:
    rng=random.Random(1927);low=0;signal=[]
    for i in range(round(d*RATE)):
        t=i/RATE;u=t/d;noise=rng.uniform(-1,1);cut=.045+.30*math.sin(math.pi*u)**2
        low+=cut*(noise-low)
        pulse=math.sin(math.pi*u)**2
        if kind=='swish':v=(noise-low)*.085*pulse
        elif kind=='whoosh':v=low*.19*pulse
        else:v=(low*.07+math.sin(2*math.pi*(280*t+1700*t*t))*.04)*pulse
        signal.append(v)
    save(BASE/'transition'/(kind+'.wav'),signal,320 if kind!='whoosh' else 420)
print('Synth quad-saw ticks, distinct Play cues and three transition swishes regenerated.')
