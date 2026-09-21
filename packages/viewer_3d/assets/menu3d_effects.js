/*
 * menu3d effects runtime.
 *
 * Plays the parts of an animation spec that <model-viewer> cannot do natively:
 * particle effects, float/sway/pulse, intro motions, and turntable spin on the
 * x or z axis. It finds every <model-viewer> that contains a
 * <script type="application/json" class="menu3d-spec"> block and drives it.
 *
 * Loaded two ways, because Flutter web inserts platform views with innerHTML
 * (where <script> tags never execute):
 *   - web:     a <script> tag in the app's web/index.html, once per page
 *   - mobile:  injected per WebView through ModelViewer.relatedJs
 *
 * The spec has already been validated in Dart, which is the trust boundary.
 * This file still ignores anything it does not recognise, so a newer spec
 * degrades instead of throwing.
 */
(function () {
  'use strict';
  if (window.menu3d) return;

  var reduceMotion =
    window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches;

  // Rough device tier. Scales particle counts and canvas resolution so a
  // budget Android phone keeps its frame rate. 1.0 = high end.
  var tier = (function () {
    var t = 1.0;
    var mem = navigator.deviceMemory;
    var cores = navigator.hardwareConcurrency;
    if (mem && mem <= 2) t = 0.4;
    else if (mem && mem <= 4) t = 0.7;
    if (cores && cores <= 4) t = Math.min(t, 0.7);
    return t;
  })();

  // ------------------------------------------------------------------ easing

  var EASING = {
    linear: function (t) { return t; },
    ease_in: function (t) { return t * t * t; },
    ease_out: function (t) { return 1 - Math.pow(1 - t, 3); },
    ease_in_out: function (t) {
      return t < 0.5 ? 4 * t * t * t : 1 - Math.pow(-2 * t + 2, 3) / 2;
    },
  };

  function easeOutBack(t) {
    var c1 = 1.70158, c3 = c1 + 1;
    return 1 + c3 * Math.pow(t - 1, 3) + c1 * Math.pow(t - 1, 2);
  }

  function clamp01(v) { return v < 0 ? 0 : v > 1 ? 1 : v; }
  function rand(a, b) { return a + Math.random() * (b - a); }

  // --------------------------------------------------------------- anchors

  // Where each anchor sits in the viewer, as fractions of width/height. These
  // are screen-space estimates, not the model's true bounding box; the asset
  // pipeline will later write real anchor points into the GLB (plan 8.5 step 5).
  var ANCHOR = {
    top: { x: 0.5, y: 0.34, w: 0.22 },
    center: { x: 0.5, y: 0.5, w: 0.34 },
    bottom: { x: 0.5, y: 0.7, w: 0.3 },
    rim: { x: 0.5, y: 0.32, w: 0.3 },
    base: { x: 0.5, y: 0.7, w: 0.2 },
  };

  // ---------------------------------------------------------------- effects
  //
  // Each effect: rate (particles/s at intensity 1, tier 1), life (s), spawn()
  // and draw(). Positions are in CSS pixels; the canvas is pre-scaled for DPR.

  var EFFECTS = {
    steam: {
      rate: 14, life: 2.6, blend: 'source-over',
      spawn: function (p, a, w, h) {
        p.x = (a.x + rand(-a.w, a.w) * 0.5) * w;
        p.y = a.y * h;
        p.vx = rand(-6, 6);
        p.vy = rand(-34, -22);
        p.r = rand(8, 14) * (w / 400);
        p.phase = rand(0, 6.28);
      },
      update: function (p, dt, t) {
        p.x += (p.vx + Math.sin(t * 1.7 + p.phase) * 10) * dt;
        p.y += p.vy * dt;
        p.r += dt * 9;
      },
      draw: function (c, p, k, dark) {
        var alpha = Math.sin(Math.PI * k) * (dark ? 0.22 : 0.4);
        var g = c.createRadialGradient(p.x, p.y, 0, p.x, p.y, p.r);
        g.addColorStop(0, 'rgba(255,255,255,' + alpha + ')');
        g.addColorStop(1, 'rgba(255,255,255,0)');
        c.fillStyle = g;
        c.beginPath(); c.arc(p.x, p.y, p.r, 0, 6.2832); c.fill();
      },
    },

    sizzle: {
      rate: 40, life: 0.7, blend: 'lighter',
      spawn: function (p, a, w, h) {
        p.x = (a.x + rand(-a.w, a.w)) * w;
        p.y = a.y * h;
        p.vx = rand(-60, 60);
        p.vy = rand(-150, -70);
        p.r = rand(1, 2.2);
      },
      update: function (p, dt) {
        p.vy += 260 * dt;
        p.x += p.vx * dt;
        p.y += p.vy * dt;
      },
      draw: function (c, p, k) {
        c.fillStyle = 'rgba(255,' + Math.round(200 - 120 * k) + ',60,' + (1 - k) + ')';
        c.beginPath(); c.arc(p.x, p.y, p.r, 0, 6.2832); c.fill();
      },
    },

    droplets: {
      rate: 10, life: 1.3, blend: 'source-over',
      spawn: function (p, a, w, h) {
        var side = Math.random() < 0.5 ? -1 : 1;
        p.x = (a.x + side * a.w * rand(0.6, 1)) * w;
        p.y = a.y * h;
        p.vx = side * rand(20, 55);
        p.vy = rand(-90, -40);
        p.r = rand(1.8, 3.2);
      },
      update: function (p, dt) {
        p.vy += 320 * dt;
        p.x += p.vx * dt;
        p.y += p.vy * dt;
      },
      draw: function (c, p, k) {
        c.fillStyle = 'rgba(190,225,255,' + (0.85 * (1 - k)) + ')';
        c.beginPath(); c.ellipse(p.x, p.y, p.r * 0.8, p.r * 1.2, 0, 0, 6.2832); c.fill();
      },
    },

    drip: {
      rate: 2.5, life: 2.4, blend: 'source-over',
      spawn: function (p, a, w, h) {
        p.x = (a.x + rand(-a.w, a.w)) * w;
        p.y = a.y * h;
        p.vy = 4;
        p.r = rand(2.5, 4);
      },
      update: function (p, dt) {
        p.vy += 22 * dt;
        p.y += p.vy * dt;
      },
      draw: function (c, p, k) {
        var a = Math.sin(Math.PI * k) * 0.7;
        c.fillStyle = 'rgba(255,255,255,' + a + ')';
        c.beginPath(); c.ellipse(p.x, p.y, p.r * 0.6, p.r * 1.6, 0, 0, 6.2832); c.fill();
      },
    },

    sparkle: {
      rate: 6, life: 0.9, blend: 'lighter',
      spawn: function (p, a, w, h) {
        p.x = (a.x + rand(-a.w, a.w)) * w;
        p.y = (a.y + rand(-a.w, a.w) * 0.8) * h;
        p.r = rand(5, 10) * (w / 400);
        p.rot = rand(0, 1.57);
      },
      update: function () {},
      draw: function (c, p, k) {
        var s = Math.sin(Math.PI * k);
        var r = p.r * s;
        c.save();
        c.translate(p.x, p.y);
        c.rotate(p.rot);
        c.fillStyle = 'rgba(255,248,220,' + s + ')';
        c.beginPath();
        for (var i = 0; i < 4; i++) {
          c.rotate(Math.PI / 2);
          c.moveTo(0, -r);
          c.quadraticCurveTo(r * 0.12, -r * 0.12, r * 0.2, 0);
          c.lineTo(0, 0);
        }
        c.fill();
        c.restore();
      },
    },

    bubbles: {
      rate: 18, life: 2.2, blend: 'source-over',
      spawn: function (p, a, w, h) {
        p.x = (a.x + rand(-a.w, a.w) * 0.6) * w;
        p.y = a.y * h;
        p.vy = rand(-70, -40);
        p.r = rand(1.2, 3.4);
        p.phase = rand(0, 6.28);
      },
      update: function (p, dt, t) {
        p.y += p.vy * dt;
        p.x += Math.sin(t * 6 + p.phase) * 12 * dt;
      },
      draw: function (c, p, k) {
        c.strokeStyle = 'rgba(255,255,255,' + (0.8 * (1 - k)) + ')';
        c.lineWidth = 1;
        c.beginPath(); c.arc(p.x, p.y, p.r, 0, 6.2832); c.stroke();
      },
    },

    condensation: {
      rate: 12, life: 3.0, blend: 'lighter',
      spawn: function (p, a, w, h) {
        p.x = (a.x + rand(-a.w, a.w)) * w;
        p.y = (a.y + rand(0, 0.35)) * h;
        p.r = rand(0.8, 1.8);
      },
      update: function () {},
      draw: function (c, p, k) {
        c.fillStyle = 'rgba(230,245,255,' + (Math.sin(Math.PI * k) * 0.7) + ')';
        c.beginPath(); c.arc(p.x, p.y, p.r, 0, 6.2832); c.fill();
      },
    },
  };

  var MAX_PARTICLES_PER_EFFECT = 140;

  // ----------------------------------------------------------------- runner

  function Runner(mv, spec, dark) {
    this.mv = mv;
    this.spec = spec;
    this.dark = dark;
    this.systems = [];
    this.visible = true;
    this.started = false;
    this.t0 = 0;
    this.last = 0;
    this.raf = 0;
    this.frames = 0;
    this.tick = this.tick.bind(this);

    var motion = spec.motion || {};
    this.oneShot = { zoom_in: 1, tilt_reveal: 1, bounce_in: 1 }[motion.type] === 1;

    // Effects are skipped outright under reduced motion. Orbit still works.
    if (!reduceMotion) {
      (spec.effects || []).forEach(function (e) {
        var def = EFFECTS[e.type];
        if (!def) return;
        this.systems.push({
          def: def,
          anchor: ANCHOR[e.anchor] || ANCHOR.center,
          rate: def.rate * (e.intensity == null ? 0.5 : e.intensity) * tier,
          carry: 0,
          ps: [],
        });
      }, this);
    }

    this.buildCanvas();
    this.watch();

    var self = this;
    var begin = function () {
      setTimeout(function () { self.start(); }, Math.max(0, (spec.delay || 0) * 1000));
    };
    if (spec.autoplay === false) {
      mv.addEventListener('pointerdown', begin, { once: true });
    } else {
      begin();
    }
  }

  Runner.prototype.buildCanvas = function () {
    var mv = this.mv;
    if (getComputedStyle(mv).position === 'static') mv.style.position = 'relative';
    var cv = document.createElement('canvas');
    cv.className = 'menu3d-fx';
    cv.style.cssText =
      'position:absolute;inset:0;width:100%;height:100%;pointer-events:none;';
    mv.appendChild(cv);
    this.canvas = cv;
    this.ctx = cv.getContext('2d');
    this.resize();
  };

  Runner.prototype.resize = function () {
    var r = this.mv.getBoundingClientRect();
    // DPR is capped by tier: sharp particles are not worth dropped frames.
    var dpr = Math.min(window.devicePixelRatio || 1, 1 + tier);
    this.w = Math.max(1, r.width);
    this.h = Math.max(1, r.height);
    this.canvas.width = Math.round(this.w * dpr);
    this.canvas.height = Math.round(this.h * dpr);
    this.ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
  };

  Runner.prototype.watch = function () {
    var self = this;
    if (window.ResizeObserver) {
      new ResizeObserver(function () { self.resize(); }).observe(this.mv);
    }
    // Pause entirely when off-screen or in a background tab (plan 8.7).
    if (window.IntersectionObserver) {
      new IntersectionObserver(function (entries) {
        self.visible = entries[entries.length - 1].isIntersecting;
        self.schedule();
      }).observe(this.mv);
    }
    document.addEventListener('visibilitychange', function () { self.schedule(); });
  };

  Runner.prototype.start = function () {
    if (this.started) return;
    this.started = true;
    var m = this.spec.motion || {};
    // A y-axis turntable that waited for autoplay or a tap hands over to
    // model-viewer's native auto-rotate now.
    if (!reduceMotion && m.type === 'turntable' && (m.axis || 'y') === 'y' && m.speed > 0) {
      this.mv.setAttribute('rotation-per-second', m.speed * 360 + 'deg');
      this.mv.setAttribute('auto-rotate', '');
    }
    this.t0 = performance.now();
    this.last = this.t0;
    this.schedule();
  };

  Runner.prototype.schedule = function () {
    if (this.raf || !this.started || !this.visible || document.hidden) return;
    if (!this.needsFrames()) return;
    this.raf = requestAnimationFrame(this.tick);
  };

  Runner.prototype.needsFrames = function () {
    if (reduceMotion) return false;
    var s = this.spec;
    var m = s.motion || {};
    return this.systems.length > 0 ||
      (s.secondary || []).length > 0 ||
      m.type === 'float' || this.oneShot ||
      (m.type === 'turntable' && m.axis && m.axis !== 'y');
  };

  /// How long a non-looping animation runs before settling.
  Runner.prototype.runFor = function () {
    var m = this.spec.motion || {};
    return this.oneShot ? (m.duration || 1.2) : 6;
  };

  Runner.prototype.tick = function (now) {
    this.raf = 0;
    if (!this.mv.isConnected) return;

    var dt = Math.min(0.05, (now - this.last) / 1000);
    this.last = now;
    var t = (now - this.t0) / 1000;
    var spawning = this.spec.loop !== false || t < this.runFor();

    this.applyMotion(t);
    var alive = this.stepEffects(dt, t, spawning);
    this.frames++;

    // Keep going while anything is still moving; otherwise let the GPU idle.
    var moving = this.spec.loop !== false || t < this.runFor() || alive > 0;
    if (moving) this.schedule();
  };

  Runner.prototype.applyMotion = function (t) {
    var s = this.spec, m = s.motion || {}, mv = this.mv;
    var ease = EASING[m.easing] || EASING.linear;
    var dur = m.duration || 1.2;
    var settled = s.loop === false && t >= this.runFor();
    var ty = 0, rot = 0, scale = 1;

    if (m.type === 'float' && !settled) {
      ty += Math.sin(t * 2 * Math.PI / 3.5) * 0.03 * this.h;
    }

    if (m.type === 'turntable' && m.axis && m.axis !== 'y' && !settled) {
      var deg = (t * (m.speed || 0) * 360) % 360;
      mv.setAttribute('orientation',
        m.axis === 'z' ? deg + 'deg 0deg 0deg' : '0deg ' + deg + 'deg 0deg');
    }

    if (this.oneShot) {
      var k = ease(clamp01(t / dur));
      var cam = s.camera || {};
      var fov = cam.fov || 35;
      if (m.type === 'zoom_in') {
        mv.setAttribute('field-of-view', fov * (1.7 - 0.7 * k) + 'deg');
        if (mv.jumpCameraToGoal) mv.jumpCameraToGoal();
      } else if (m.type === 'tilt_reveal') {
        mv.setAttribute('camera-orbit',
          (-50 * (1 - k)) + 'deg ' + (30 + 42 * k) + 'deg auto');
        if (mv.jumpCameraToGoal) mv.jumpCameraToGoal();
      } else if (m.type === 'bounce_in') {
        scale *= t >= dur ? 1 : 0.55 + 0.45 * easeOutBack(clamp01(t / dur));
      }
      // One-shots are intros: they play once even when loop is on.
      if (t >= dur) this.oneShot = false;
    }

    if (!settled) {
      (s.secondary || []).forEach(function (sm) {
        var w = Math.sin(t * 2 * Math.PI / (sm.period || 3));
        var a = sm.amplitude || 0.02;
        if (sm.type === 'float') ty += w * a * this.h;
        else if (sm.type === 'sway') rot += w * a * 60;
        else if (sm.type === 'pulse') scale *= 1 + w * a;
      }, this);
    }

    mv.style.transform = (ty || rot || scale !== 1)
      ? 'translateY(' + ty.toFixed(2) + 'px) rotate(' + rot.toFixed(2) + 'deg) scale(' + scale.toFixed(4) + ')'
      : '';
  };

  Runner.prototype.stepEffects = function (dt, t, spawning) {
    var c = this.ctx, w = this.w, h = this.h, dark = this.dark;
    c.clearRect(0, 0, w, h);
    var alive = 0;
    var cap = Math.round(MAX_PARTICLES_PER_EFFECT * tier);

    for (var i = 0; i < this.systems.length; i++) {
      var sys = this.systems[i], def = sys.def, ps = sys.ps;

      if (spawning) {
        sys.carry += sys.rate * dt;
        while (sys.carry >= 1 && ps.length < cap) {
          sys.carry -= 1;
          var p = { age: 0 };
          def.spawn(p, sys.anchor, w, h);
          ps.push(p);
        }
        if (ps.length >= cap) sys.carry = 0;
      }

      c.globalCompositeOperation = def.blend;
      for (var j = ps.length - 1; j >= 0; j--) {
        var q = ps[j];
        q.age += dt;
        var k = q.age / def.life;
        if (k >= 1) { ps.splice(j, 1); continue; }
        def.update(q, dt, t);
        def.draw(c, q, k, dark);
      }
      alive += ps.length;
    }
    c.globalCompositeOperation = 'source-over';
    return alive;
  };

  // -------------------------------------------------------------- discovery

  function attach(mv) {
    if (mv.__menu3d) return;
    var tag = mv.querySelector('script.menu3d-spec');
    if (!tag) return;
    var spec;
    try { spec = JSON.parse(tag.textContent); } catch (_) { return; }
    if (!spec || typeof spec !== 'object') return;
    mv.__menu3d = new Runner(mv, spec, tag.getAttribute('data-theme') === 'dark');
    mv.dispatchEvent(new CustomEvent('menu3d-ready', { bubbles: true }));
  }

  function scan(node) {
    if (!node || node.nodeType !== 1) return;
    if (node.localName === 'model-viewer') attach(node);
    if (node.querySelectorAll) {
      var found = node.querySelectorAll('model-viewer');
      for (var i = 0; i < found.length; i++) attach(found[i]);
    }
  }

  window.menu3d = {
    version: 1,
    tier: tier,
    reduceMotion: reduceMotion,
    scan: function () { scan(document.documentElement); },
  };

  // Flutter web adds platform views long after load, so watch for them.
  new MutationObserver(function (records) {
    for (var i = 0; i < records.length; i++) {
      var added = records[i].addedNodes;
      for (var j = 0; j < added.length; j++) scan(added[j]);
    }
  }).observe(document.documentElement, { childList: true, subtree: true });

  scan(document.documentElement);
})();
