// js_helper_web.dart
import 'dart:js' as js;

void playWebBeep() {
  try {
    js.context.callMethod('eval', ["""
      (function() {
        try {
          var ctx = new (window.AudioContext || window.webkitAudioContext)();
          
          // E5 (659.25 Hz) and G5 (783.99 Hz) for a bright, premium cafe chime
          var osc1 = ctx.createOscillator();
          var osc2 = ctx.createOscillator();
          var gain = ctx.createGain();
          
          osc1.type = 'sine';
          osc2.type = 'sine';
          
          osc1.frequency.setValueAtTime(659.25, ctx.currentTime); 
          osc2.frequency.setValueAtTime(783.99, ctx.currentTime + 0.12); // Plays 120ms later
          
          gain.gain.setValueAtTime(0.12, ctx.currentTime);
          gain.gain.setValueAtTime(0.12, ctx.currentTime + 0.12);
          gain.gain.exponentialRampToValueAtTime(0.005, ctx.currentTime + 0.45); // Smooth fade
          
          osc1.connect(gain);
          osc2.connect(gain);
          gain.connect(ctx.destination);
          
          osc1.start();
          osc1.stop(ctx.currentTime + 0.18);
          
          osc2.start(ctx.currentTime + 0.12);
          osc2.stop(ctx.currentTime + 0.45);
          
          // Vibrate if supported
          if (navigator.vibrate) {
            try {
              navigator.vibrate([150, 100, 150]); // Double-vibe matching the double-chime!
            } catch (vErr) {
              // Ignore blocked vibrate due to lack of user gesture
            }
          }
        } catch (e) {
          console.log('AudioContext error: ', e);
        }
      })();
    """]);
  } catch (e) {
    // ignore
  }
}
