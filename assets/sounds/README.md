Relay audio is synthesized locally; no recordings or downloaded sample packs are used.

Run generate_packs.py with Python to regenerate the current Synth ticks, Play-focus/launch cues, and transition sounds. It only writes beside itself. Back up any manual WAV edits first.

Synth uses four detuned saw voices, harmonic damping, and a fast attack/decay envelope. Glass navigation retains sine-based inharmonic bell partials. Pulse navigation retains a rounded electronic doublet. Soft Tick retains the existing dry tick.

Pitch hierarchy: game left is slightly higher than right; category is higher than source; settings ticks are light. Play-focus is a small chord, while activation rises through three notes. Swish uses filtered noise, Whoosh uses lower filtered noise, and Signal Sweep adds a rising oscillator.

All cues use stereo signed 16-bit PCM at 44100 Hz. Short ticks have a minimum 120 ms buffer with quiet padding for Qt playback compatibility. Changing the audible envelope does not require shortening the padded file.

Useful adjustments in the generator: oscillator detune in cents; harmonic count and damping; attack and decay; cue gain; filter coefficient; noise/sine mix. In the UI: select the tick pack and main volume, then select a transition sound and separate transition volume.
