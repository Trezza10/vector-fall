"""Generate original, deterministic mono PCM cues for VECTORFALL. No external assets."""
import math, random, wave, struct
from pathlib import Path
RATE = 22050
random.seed(241)
# duration, start/end frequency, noise mix
CUES = {
 'shot': (.075, 1100, 240, .22), 'hit': (.09, 320, 90, .55),
 'crit': (.18, 1450, 620, .15), 'kill': (.32, 440, 60, .5),
 'poison': (.19, 180, 410, .3), 'burn': (.16, 340, 90, .75),
 'status': (.15, 720, 1200, .12), 'pickup': (.3, 650, 1500, .03),
 'recharge': (.18, 680, 1050, .02), 'dash': (.22, 800, 110, .8),
 'move': (.055, 160, 100, .35), 'respawn': (.4, 180, 900, .12),
 'ui': (.075, 920, 1250, .02), 'pause': (.16, 600, 300, .03),
 'resume': (.16, 300, 600, .03), 'reset': (.25, 1000, 350, .05),
 'wall': (.07, 140, 60, .6),
}
for name, (duration, start, end, noise) in CUES.items():
 samples = []; phase = 0.; smooth = 0.
 for i in range(int(duration * RATE)):
  t = i / RATE; u = t / duration
  freq = start * ((end/start) ** u)
  if name in ('pickup', 'recharge', 'respawn'):
   freq *= [1, 1.25, 1.5, 2][min(3, int(u * 4))]
  phase += 2 * math.pi * freq / RATE
  smooth = .55 * smooth + .45 * random.uniform(-1, 1)
  tone = math.sin(phase) + .18 * math.sin(phase * 2)
  envelope = min(1, t/.006) * (1-u)**1.6 * min(1, (duration-t)/.012)
  value = .6 * envelope * ((1-noise)*tone + noise*smooth)
  samples.append(struct.pack('<h', int(max(-1, min(1, value)) * 32767)))
 with wave.open(str(Path('assets/audio') / (name+'.wav')), 'wb') as out:
  out.setparams((1, 2, RATE, 0, 'NONE', 'not compressed')); out.writeframes(b''.join(samples))
