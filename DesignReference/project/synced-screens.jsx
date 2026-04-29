// Synced — onboarding screens (12-screen spec)
// All screens render their own header (back arrow + progress bar).
// Screen 1 has no header.

const { useState: useS, useEffect: useE, useRef: useR } = React;

// ─── Layout primitives ─────────────────────────────────────────────
function Shell({ children, ambient = true }) {
  return (
    <div className="screen-fade" style={{
      height: '100%',
      display: 'flex', flexDirection: 'column',
      padding: '0 24px',
      boxSizing: 'border-box',
      background: SYN.bg,
      position: 'relative',
    }}>
      {ambient && (
        <div style={{
          position: 'absolute', inset: 0, pointerEvents: 'none',
          background: 'radial-gradient(120% 50% at 50% 0%, rgba(0,229,255,0.06) 0%, transparent 55%)',
        }}/>
      )}
      <div style={{ position: 'relative', display: 'flex', flexDirection: 'column', height: '100%' }}>
        {children}
      </div>
    </div>
  );
}

function Header({ progress, onBack }) {
  // Sits clear of the dynamic island. Back arrow + glowing progress bar.
  return (
    <div style={{
      paddingTop: 56,
      display: 'flex', alignItems: 'center', gap: 16,
    }}>
      <button onClick={onBack} aria-label="Back" style={{
        width: 24, height: 24, padding: 0,
        background: 'transparent', border: 'none', cursor: 'pointer',
        display: 'flex', alignItems: 'center', justifyContent: 'flex-start',
        flexShrink: 0,
      }}>
        <svg width="24" height="24" viewBox="0 0 24 24" fill="none"
          stroke={SYN.textDim} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
          <path d="M15 6 l-6 6 l6 6"/>
        </svg>
      </button>
      <div style={{
        flex: 1, height: 4, borderRadius: 2,
        background: SYN.border, overflow: 'hidden',
        position: 'relative',
      }}>
        <div style={{
          height: '100%',
          width: `${progress}%`,
          background: 'linear-gradient(90deg, rgba(255,255,255,0.85), #FFFFFF)',
          borderRadius: 2,
          boxShadow: '0 0 10px rgba(255,255,255,0.55), 0 0 18px rgba(0,229,255,0.30)',
          transition: 'width 360ms cubic-bezier(.2,.7,.2,1)',
        }} />
      </div>
    </div>
  );
}

function H1({ children, center, size = 28 }) {
  return (
    <h1 style={{
      margin: 0,
      fontFamily: SYN_DISPLAY,
      fontWeight: 700,
      fontSize: size,
      lineHeight: 1.15,
      letterSpacing: '-0.025em',
      color: SYN.text,
      textAlign: center ? 'center' : 'left',
      textWrap: 'balance',
    }}>{children}</h1>
  );
}

function P({ children, center, size = 15, color = SYN.textDim }) {
  return (
    <p style={{
      margin: 0,
      fontFamily: SYN_FONT,
      fontWeight: 400,
      fontSize: size,
      lineHeight: 1.4,
      letterSpacing: '-0.005em',
      color,
      textAlign: center ? 'center' : 'left',
      textWrap: 'pretty',
    }}>{children}</p>
  );
}

function Label({ children, color = SYN.textFaint }) {
  return (
    <div style={{
      fontFamily: SYN_FONT,
      fontSize: 11,
      fontWeight: 600,
      letterSpacing: '0.08em',
      textTransform: 'uppercase',
      color,
    }}>{children}</div>
  );
}

function Sp({ h }) { return <div style={{ height: h }} />; }
function Flex({ grow = 1 }) { return <div style={{ flex: grow }} />; }

function CTA({ children, onClick, disabled, glow = true }) {
  return (
    <button
      onClick={disabled ? undefined : onClick}
      disabled={disabled}
      style={{
        width: '100%',
        height: 56,
        borderRadius: 14,
        border: 'none',
        background: SYN.cyan,
        color: '#0A0A0A',
        fontFamily: SYN_FONT,
        fontWeight: 600,
        fontSize: 16,
        letterSpacing: '-0.01em',
        cursor: disabled ? 'not-allowed' : 'pointer',
        opacity: disabled ? 0.5 : 1,
        boxShadow: !disabled && glow
          ? '0 0 0 1px rgba(0,229,255,0.45), 0 0 24px rgba(0,229,255,0.45), 0 12px 40px rgba(0,229,255,0.30)'
          : 'none',
        transition: 'opacity 200ms ease, box-shadow 200ms ease, transform 120ms ease',
      }}
      onMouseDown={e => !disabled && (e.currentTarget.style.transform = 'scale(0.985)')}
      onMouseUp={e => !disabled && (e.currentTarget.style.transform = 'scale(1)')}
      onMouseLeave={e => !disabled && (e.currentTarget.style.transform = 'scale(1)')}
    >{children}</button>
  );
}

function BottomCTA({ children }) {
  return <div style={{ paddingBottom: 48 }}>{children}</div>;
}

// ─── Spec inputs ───────────────────────────────────────────────────
function SpecInput({ value, onChange, placeholder, autoFocus, inputMode, maxLength }) {
  const [focused, setFocused] = useS(false);
  return (
    <div style={{
      height: 56,
      borderRadius: 14,
      background: SYN.surface,
      border: `${focused ? 1.5 : 1}px solid ${focused ? SYN.cyan : SYN.border}`,
      boxShadow: focused ? `0 0 0 4px ${SYN.cyanSoft}` : 'none',
      transition: 'border-color 200ms ease, box-shadow 200ms ease',
    }}>
      <input
        type="text"
        value={value}
        onChange={(e) => onChange(e.target.value)}
        placeholder={placeholder}
        autoFocus={autoFocus}
        inputMode={inputMode}
        maxLength={maxLength}
        onFocus={() => setFocused(true)}
        onBlur={() => setFocused(false)}
        style={{
          width: '100%', height: '100%',
          background: 'transparent', border: 'none', outline: 'none',
          padding: '0 18px',
          fontFamily: SYN_FONT,
          fontSize: 16,
          fontWeight: 400,
          color: SYN.text,
          letterSpacing: '-0.01em',
          boxSizing: 'border-box',
        }}
      />
    </div>
  );
}

// ─── Selectable card (spec) ────────────────────────────────────────
function SpecCard({ title, selected, onClick, height = 80 }) {
  return (
    <button
      onClick={onClick}
      style={{
        width: '100%',
        minHeight: height,
        textAlign: 'left',
        background: selected
          ? 'linear-gradient(180deg, rgba(0,229,255,0.10) 0%, rgba(0,229,255,0.04) 100%)'
          : 'linear-gradient(180deg, #1A1A1E 0%, #131316 100%)',
        border: `${selected ? 1.5 : 1}px solid ${selected ? SYN.cyan : SYN.border}`,
        borderRadius: 16,
        padding: '0 20px',
        cursor: 'pointer',
        display: 'flex', alignItems: 'center', gap: 16,
        boxShadow: selected
          ? `0 0 0 4px rgba(0,229,255,0.20), 0 0 28px rgba(0,229,255,0.45), inset 0 1px 0 rgba(255,255,255,0.05)`
          : 'inset 0 1px 0 rgba(255,255,255,0.04), 0 8px 24px rgba(0,0,0,0.30)',
        transition: 'all 220ms cubic-bezier(.2,.7,.2,1)',
      }}>
      <div style={{
        flex: 1, minWidth: 0,
        fontFamily: SYN_DISPLAY,
        fontWeight: 600,
        fontSize: 17,
        letterSpacing: '-0.015em',
        color: SYN.text,
      }}>{title}</div>
      {selected ? (
        <div style={{
          width: 22, height: 22, borderRadius: '50%',
          background: SYN.cyan,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          flexShrink: 0,
          boxShadow: `0 0 12px rgba(0,229,255,0.5)`,
        }}>
          <svg width="13" height="13" viewBox="0 0 13 13">
            <path d="M3 6.6 L5.6 9.3 L10 4" stroke="#0A0A0A" strokeWidth="2.2" fill="none" strokeLinecap="round" strokeLinejoin="round"/>
          </svg>
        </div>
      ) : (
        <svg width="16" height="16" viewBox="0 0 16 16" fill="none" stroke={SYN.textFaint} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
          <path d="M6 3 l5 5 l-5 5"/>
        </svg>
      )}
    </button>
  );
}

// ─── Slider (spec) ─────────────────────────────────────────────────
function SpecSlider({ value, min, max, step, onChange, ticks, tickLabels }) {
  const trackRef = useR(null);
  const [dragging, setDragging] = useS(false);
  const pct = ((value - min) / (max - min)) * 100;
  const tickValues = ticks || [];

  const setFromX = React.useCallback((clientX) => {
    const el = trackRef.current; if (!el) return;
    const r = el.getBoundingClientRect();
    const ratio = Math.min(1, Math.max(0, (clientX - r.left) / r.width));
    const raw = min + ratio * (max - min);
    const snapped = Math.round(raw / step) * step;
    onChange(Math.min(max, Math.max(min, +snapped.toFixed(3))));
  }, [min, max, step, onChange]);

  useE(() => {
    if (!dragging) return;
    const move = (e) => setFromX(e.touches ? e.touches[0].clientX : e.clientX);
    const up = () => setDragging(false);
    window.addEventListener('mousemove', move);
    window.addEventListener('mouseup', up);
    window.addEventListener('touchmove', move, { passive: false });
    window.addEventListener('touchend', up);
    return () => {
      window.removeEventListener('mousemove', move);
      window.removeEventListener('mouseup', up);
      window.removeEventListener('touchmove', move);
      window.removeEventListener('touchend', up);
    };
  }, [dragging, setFromX]);

  return (
    <div
      ref={trackRef}
      onMouseDown={(e) => { setDragging(true); setFromX(e.clientX); }}
      onTouchStart={(e) => { setDragging(true); setFromX(e.touches[0].clientX); }}
      style={{
        position: 'relative', height: 56,
        display: 'flex', alignItems: 'center',
        cursor: 'pointer', touchAction: 'none',
      }}>
      <div style={{
        position: 'absolute', left: 0, right: 0, height: 4,
        background: SYN.border, borderRadius: 999,
      }}>
        <div style={{
          position: 'absolute', left: 0, top: 0, bottom: 0,
          width: `${pct}%`,
          background: `linear-gradient(90deg, ${SYN.cyan} 0%, #7CE8F5 100%)`,
          borderRadius: 999,
          boxShadow: `0 0 10px ${SYN.cyanGlow}, 0 0 20px rgba(0,229,255,0.4)`,
          transition: dragging ? 'none' : 'width 160ms ease',
        }} />
      </div>

      {/* Ticks */}
      {tickValues.map((tv, i) => {
        const tpct = ((tv - min) / (max - min)) * 100;
        const isActive = tv <= value + 0.001;
        const isCurrent = Math.abs(tv - value) < step / 2;
        return (
          <div key={i} style={{
            position: 'absolute', left: `${tpct}%`,
            transform: 'translateX(-50%)',
            display: 'flex', flexDirection: 'column', alignItems: 'center',
            gap: 8, pointerEvents: 'none',
          }}>
            <div style={{
              width: isCurrent ? 0 : 2, height: isCurrent ? 0 : 8,
              borderRadius: 1,
              background: isActive ? SYN.cyan : 'rgba(255,255,255,0.18)',
              boxShadow: isActive ? `0 0 6px ${SYN.cyanGlow}` : 'none',
              transition: 'all 200ms ease',
            }}/>
            {tickLabels && (
              <div style={{
                fontFamily: 'ui-monospace, "SF Mono", Menlo, monospace',
                fontSize: 11, fontWeight: 500,
                color: isCurrent ? SYN.cyan : isActive ? SYN.text : SYN.textFaint,
                letterSpacing: '0.04em',
                textShadow: isCurrent ? '0 0 8px rgba(0,229,255,0.6)' : 'none',
                transition: 'color 200ms ease',
                marginTop: 24,
                position: 'absolute', top: 8,
                whiteSpace: 'nowrap',
              }}>{tickLabels[i]}</div>
            )}
          </div>
        );
      })}

      <div style={{
        position: 'absolute', left: `${pct}%`,
        width: 32, height: 32, borderRadius: '50%',
        background: 'radial-gradient(circle at 35% 30%, #FFFFFF 0%, #E0F8FB 80%)',
        boxShadow: `0 0 0 4px rgba(0,229,255,0.30), 0 0 20px ${SYN.cyanGlow}, 0 0 40px rgba(0,229,255,0.4)`,
        transform: `translateX(-16px) ${dragging ? 'scale(1.1)' : 'scale(1)'}`,
        transition: dragging ? 'transform 80ms ease' : 'transform 160ms ease, left 160ms ease',
        zIndex: 2,
      }} />
    </div>
  );
}

// ───────────────────────────────────────────────────────────────────
// SCREEN 1 — Welcome
// ───────────────────────────────────────────────────────────────────
function S1Welcome({ onNext, onSignIn }) {
  const [phase, setPhase] = React.useState(0);
  React.useEffect(() => {
    const t = setTimeout(() => setPhase(1), 200);
    return () => clearTimeout(t);
  }, []);
  return (
    <Shell ambient={false}>
      <div style={{
        position: 'absolute', inset: 0, pointerEvents: 'none',
        background: 'radial-gradient(120% 60% at 50% 30%, rgba(0,229,255,0.18) 0%, rgba(0,229,255,0.05) 30%, transparent 60%)',
      }}/>
      <div style={{
        position: 'absolute', inset: 0, pointerEvents: 'none',
        background: 'radial-gradient(70% 35% at 50% 30%, transparent 30%, rgba(0,229,255,0.05) 45%, transparent 60%)',
        animation: 'auraPulse 5s ease-in-out infinite',
      }}/>
      <div style={{ position: 'relative', display: 'flex', flexDirection: 'column', height: '100%' }}>
      <Sp h={140} />
      <div style={{
        position: 'relative', display: 'flex', justifyContent: 'center', alignItems: 'center',
        opacity: phase >= 1 ? 1 : 0,
        transform: phase >= 1 ? 'scale(1)' : 'scale(0.92)',
        transition: 'all 800ms cubic-bezier(.2,.7,.2,1)',
      }}>
        <div style={{
          position: 'absolute',
          width: 420, height: 320, borderRadius: '50%',
          background: 'radial-gradient(ellipse at center, rgba(0,229,255,0.22) 0%, rgba(0,229,255,0.10) 28%, rgba(0,229,255,0) 65%)',
          filter: 'blur(8px)', pointerEvents: 'none',
        }} />
        <div style={{ position: 'relative', width: 88, height: 88, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <div style={{
            position: 'absolute', inset: 0, borderRadius: '50%',
            border: `1px solid ${SYN.cyan}`, opacity: 0.35,
            animation: 'pulseRing 2.6s ease-out infinite',
          }} />
          <div style={{
            position: 'absolute', inset: -16, borderRadius: '50%',
            border: `1px solid ${SYN.cyan}`, opacity: 0.18,
            animation: 'pulseRing 2.6s ease-out 1.3s infinite',
          }} />
          <div style={{
            width: 72, height: 72, borderRadius: '50%',
            background: 'radial-gradient(circle, #0e0e0e 0%, #050505 100%)',
            border: `1.5px solid ${SYN.cyan}`,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            boxShadow: `0 0 32px rgba(0,229,255,0.35), inset 0 0 20px rgba(0,229,255,0.18)`,
          }}>
            <div style={{ width: 14, height: 14, borderRadius: '50%', background: SYN.cyan, boxShadow: `0 0 16px ${SYN.cyan}` }} />
          </div>
        </div>
      </div>
      <Sp h={32} />
      <div style={{
        fontFamily: SYN_DISPLAY, fontWeight: 700, fontSize: 56,
        lineHeight: 1, letterSpacing: '-0.04em',
        textAlign: 'center',
        background: `linear-gradient(180deg, #FFFFFF 0%, ${SYN.cyan} 100%)`,
        WebkitBackgroundClip: 'text', backgroundClip: 'text', color: 'transparent',
        filter: 'drop-shadow(0 0 16px rgba(0,229,255,0.45))',
        opacity: phase >= 1 ? 1 : 0,
        transform: phase >= 1 ? 'translateY(0)' : 'translateY(10px)',
        transition: 'all 700ms cubic-bezier(.2,.7,.2,1) 200ms',
      }}>Synced</div>
      <Sp h={16} />
      <div style={{
        fontFamily: SYN_FONT, fontSize: 17, color: SYN.textDim,
        textAlign: 'center', letterSpacing: '-0.005em',
        opacity: phase >= 1 ? 1 : 0,
        transition: 'opacity 700ms ease 400ms',
      }}>Train smarter. Recover harder.</div>
      <Flex/>
      <BottomCTA>
        <CTA onClick={onNext}>Get Started</CTA>
        <Sp h={12}/>
        <button onClick={onSignIn} style={{
          width: '100%', background: 'transparent', border: 'none',
          padding: '8px 0', fontFamily: SYN_FONT, fontWeight: 500, fontSize: 15,
          color: SYN.textDim, cursor: 'pointer', letterSpacing: '-0.01em',
        }}>I already have an account</button>
      </BottomCTA>
      </div>
    </Shell>
  );
}

// ───────────────────────────────────────────────────────────────────
// SCREEN 2 — Quick value explainer (8%)
// ───────────────────────────────────────────────────────────────────
function S2Value({ onBack, onNext }) {
  const items = [
    { icon: <ClockIcon/>,  title: '60 second check-ins', sub: 'Pre-lift and post-lift, two taps each' },
    { icon: <TrendIcon/>,  title: 'Patterns over time',  sub: 'See exactly what fuels your best lifts' },
    { icon: <PeopleIcon/>, title: 'Climb the leaderboard', sub: 'Compete with your gym friends weekly' },
  ];
  const [phase, setPhase] = React.useState(0);
  React.useEffect(() => {
    const t = setTimeout(() => setPhase(1), 200);
    return () => clearTimeout(t);
  }, []);

  return (
    <Shell ambient={false}>
      {/* Top-anchored ambient glow */}
      <div style={{
        position: 'absolute', inset: 0, pointerEvents: 'none',
        background: 'radial-gradient(140% 60% at 50% -10%, rgba(0,229,255,0.18) 0%, rgba(0,229,255,0.05) 25%, transparent 55%)',
      }}/>
      {/* Slow pulsing aura */}
      <div style={{
        position: 'absolute', inset: 0, pointerEvents: 'none',
        background: 'radial-gradient(80% 40% at 50% 8%, transparent 25%, rgba(0,229,255,0.05) 38%, transparent 55%)',
        animation: 'auraPulse 5s ease-in-out infinite',
      }}/>

      <div style={{ position: 'relative', display: 'flex', flexDirection: 'column', height: '100%' }}>
        <Header progress={8} onBack={onBack} />

        <Sp h={32}/>

        {/* Eyebrow tag */}
        <div style={{
          alignSelf: 'center',
          fontFamily: SYN_FONT, fontSize: 11, fontWeight: 600,
          color: SYN.cyan, letterSpacing: '0.18em',
          padding: '6px 14px', borderRadius: 999,
          border: '1px solid rgba(0,229,255,0.35)',
          background: 'rgba(0,229,255,0.06)',
          boxShadow: '0 0 16px rgba(0,229,255,0.25), inset 0 0 12px rgba(0,229,255,0.1)',
          opacity: phase >= 1 ? 1 : 0,
          transform: phase >= 1 ? 'translateY(0)' : 'translateY(8px)',
          transition: 'all 600ms cubic-bezier(.2,.7,.2,1)',
        }}>HOW IT WORKS</div>

        <Sp h={20}/>

        {/* Headline */}
        <div style={{
          fontFamily: SYN_DISPLAY, fontWeight: 700, fontSize: 30,
          color: SYN.text, letterSpacing: '-0.03em', lineHeight: 1.1,
          textAlign: 'center', maxWidth: 320, alignSelf: 'center',
          opacity: phase >= 1 ? 1 : 0,
          transform: phase >= 1 ? 'translateY(0)' : 'translateY(10px)',
          transition: 'all 700ms cubic-bezier(.2,.7,.2,1) 100ms',
        }}>
          Train <span style={{
            background: `linear-gradient(180deg, ${SYN.cyan} 0%, #7CE8F5 100%)`,
            WebkitBackgroundClip: 'text', backgroundClip: 'text', color: 'transparent',
            filter: 'drop-shadow(0 0 12px rgba(0,229,255,0.5))',
          }}>smart</span>. See what works.
        </div>
        <Sp h={10}/>
        <div style={{
          fontFamily: SYN_FONT, fontSize: 15, color: SYN.textDim,
          textAlign: 'center', letterSpacing: '-0.005em',
          opacity: phase >= 1 ? 1 : 0,
          transition: 'opacity 700ms ease 250ms',
        }}>Track inputs, log outputs, find your patterns</div>

        <Sp h={36}/>

        {/* Cards */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
          {items.map((it, i) => (
            <div key={i} style={{
              position: 'relative',
              minHeight: 84,
              background: 'linear-gradient(180deg, #1A1A1E 0%, #131316 100%)',
              border: `1px solid ${SYN.border}`,
              borderRadius: 16,
              padding: '18px 20px',
              display: 'flex', alignItems: 'center', gap: 16,
              boxShadow: '0 1px 0 rgba(255,255,255,0.04) inset, 0 10px 30px rgba(0,0,0,0.45)',
              overflow: 'hidden',
              opacity: phase >= 1 ? 1 : 0,
              transform: phase >= 1 ? 'translateY(0)' : 'translateY(14px)',
              transition: `all 700ms cubic-bezier(.2,.7,.2,1) ${350 + i * 120}ms`,
            }}>
              {/* Left cyan accent stroke */}
              <div style={{
                position: 'absolute', left: 0, top: 12, bottom: 12, width: 2,
                background: `linear-gradient(180deg, transparent 0%, ${SYN.cyan} 50%, transparent 100%)`,
                boxShadow: `0 0 12px ${SYN.cyanGlow}`,
              }}/>
              {/* Subtle radial behind icon */}
              <div style={{
                position: 'relative',
                width: 44, height: 44, flexShrink: 0,
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                borderRadius: 12,
                background: 'radial-gradient(circle at 50% 50%, rgba(0,229,255,0.18) 0%, rgba(0,229,255,0.04) 60%, transparent 100%)',
                border: '1px solid rgba(0,229,255,0.25)',
                boxShadow: 'inset 0 0 12px rgba(0,229,255,0.15), 0 0 14px rgba(0,229,255,0.18)',
              }}>
                <div style={{
                  width: 24, height: 24, color: SYN.cyan,
                  filter: 'drop-shadow(0 0 6px rgba(0,229,255,0.7))',
                }}>{it.icon}</div>
              </div>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{
                  fontFamily: SYN_DISPLAY, fontWeight: 600, fontSize: 17,
                  letterSpacing: '-0.015em', color: SYN.text,
                }}>{it.title}</div>
                <div style={{ height: 4 }} />
                <div style={{
                  fontFamily: SYN_FONT, fontWeight: 400, fontSize: 14,
                  color: SYN.textDim, lineHeight: 1.4,
                }}>{it.sub}</div>
              </div>
              {/* Step number */}
              <div style={{
                fontFamily: 'ui-monospace, "SF Mono", Menlo, monospace',
                fontSize: 11, fontWeight: 600,
                color: 'rgba(0,229,255,0.6)', letterSpacing: '0.1em',
              }}>0{i + 1}</div>
            </div>
          ))}
        </div>

        <Flex/>
        <BottomCTA><CTA onClick={onNext}>Continue</CTA></BottomCTA>
      </div>

      <style>{`
        @keyframes auraPulse {
          0%, 100% { opacity: 0.4; transform: scale(1); }
          50% { opacity: 1; transform: scale(1.1); }
        }
      `}</style>
    </Shell>
  );
}

// ───────────────────────────────────────────────────────────────────
// SCREEN 3 — Username (16%)
// ───────────────────────────────────────────────────────────────────
function S3Name({ data, setData, onBack, onNext }) {
  const [phase, setPhase] = React.useState(0);
  React.useEffect(() => {
    const t = setTimeout(() => setPhase(1), 200);
    return () => clearTimeout(t);
  }, []);

  const raw = data.firstName || '';
  // Allow letters, spaces, hyphens, apostrophes; trim and cap length
  const setName = (v) => setData({ ...data, firstName: v.replace(/[^A-Za-z\u00C0-\u024F'\-\s]/g, '').slice(0, 30) });
  const trimmed = raw.trim();
  const valid = trimmed.length >= 1;

  return (
    <Shell ambient={false}>
      <div style={{
        position: 'absolute', inset: 0, pointerEvents: 'none',
        background: 'radial-gradient(140% 60% at 50% -10%, rgba(0,229,255,0.18) 0%, rgba(0,229,255,0.05) 25%, transparent 55%)',
      }}/>
      <div style={{
        position: 'absolute', inset: 0, pointerEvents: 'none',
        background: 'radial-gradient(80% 40% at 50% 8%, transparent 25%, rgba(0,229,255,0.05) 38%, transparent 55%)',
        animation: 'auraPulse 5s ease-in-out infinite',
      }}/>

      <div style={{ position: 'relative', display: 'flex', flexDirection: 'column', height: '100%' }}>
        <Header progress={16} onBack={onBack}/>

        <Flex grow={0.5}/>

        <div style={{
          alignSelf: 'center',
          fontFamily: SYN_FONT, fontSize: 11, fontWeight: 600,
          color: SYN.cyan, letterSpacing: '0.18em',
          padding: '6px 14px', borderRadius: 999,
          border: '1px solid rgba(0,229,255,0.35)',
          background: 'rgba(0,229,255,0.06)',
          boxShadow: '0 0 16px rgba(0,229,255,0.25), inset 0 0 12px rgba(0,229,255,0.1)',
          opacity: phase >= 1 ? 1 : 0,
          transform: phase >= 1 ? 'translateY(0)' : 'translateY(8px)',
          transition: 'all 600ms cubic-bezier(.2,.7,.2,1)',
        }}>FIRST, INTRODUCE YOURSELF</div>

        <Sp h={20}/>

        <div style={{
          fontFamily: SYN_DISPLAY, fontWeight: 700, fontSize: 30,
          color: SYN.text, letterSpacing: '-0.03em', lineHeight: 1.1,
          textAlign: 'center', maxWidth: 320, alignSelf: 'center',
          opacity: phase >= 1 ? 1 : 0,
          transform: phase >= 1 ? 'translateY(0)' : 'translateY(10px)',
          transition: 'all 700ms cubic-bezier(.2,.7,.2,1) 100ms',
        }}>
          What's your <span style={{
            background: `linear-gradient(180deg, ${SYN.cyan} 0%, #7CE8F5 100%)`,
            WebkitBackgroundClip: 'text', backgroundClip: 'text', color: 'transparent',
            filter: 'drop-shadow(0 0 12px rgba(0,229,255,0.5))',
          }}>first name</span>?
        </div>
        <Sp h={10}/>
        <div style={{
          fontFamily: SYN_FONT, fontSize: 15, color: SYN.textDim,
          textAlign: 'center', letterSpacing: '-0.005em', maxWidth: 280,
          alignSelf: 'center',
          opacity: phase >= 1 ? 1 : 0,
          transition: 'opacity 700ms ease 250ms',
        }}>You can pick a public handle later, when you join the leaderboard</div>

        <Sp h={36}/>

        <div style={{
          opacity: phase >= 1 ? 1 : 0,
          transform: phase >= 1 ? 'translateY(0)' : 'translateY(14px)',
          transition: 'all 700ms cubic-bezier(.2,.7,.2,1) 350ms',
        }}>
          <NameInput value={raw} onChange={setName} valid={valid}/>
        </div>

        <Flex/>
        <BottomCTA><CTA disabled={!valid} onClick={onNext}>Continue</CTA></BottomCTA>
      </div>
    </Shell>
  );
}

// First-name input — single field, capitalized, big & friendly
function NameInput({ value, onChange, valid }) {
  const [focused, setFocused] = React.useState(false);
  const borderColor = valid ? '#22C55E' : focused ? SYN.cyan : SYN.border;
  const glow = valid ? 'rgba(34,197,94,0.22)' : focused ? SYN.cyanSoft : 'transparent';

  return (
    <div style={{
      height: 72,
      borderRadius: 18,
      background: 'linear-gradient(180deg, #1A1A1E 0%, #131316 100%)',
      border: `1.5px solid ${borderColor}`,
      boxShadow: `0 0 0 4px ${glow}, 0 8px 24px rgba(0,0,0,0.35), inset 0 1px 0 rgba(255,255,255,0.04)`,
      display: 'flex', alignItems: 'center',
      padding: '0 22px',
      transition: 'all 200ms cubic-bezier(.2,.7,.2,1)',
      position: 'relative', overflow: 'hidden',
    }}>
      {valid && (
        <div style={{
          position: 'absolute', inset: 0, pointerEvents: 'none',
          background: 'radial-gradient(60% 100% at 0% 50%, rgba(34,197,94,0.08) 0%, transparent 70%)',
        }}/>
      )}
      <input
        type="text"
        value={value}
        onChange={(e) => onChange(e.target.value)}
        placeholder="Alex"
        autoFocus
        autoComplete="given-name"
        autoCapitalize="words"
        spellCheck={false}
        onFocus={() => setFocused(true)}
        onBlur={() => setFocused(false)}
        style={{
          flex: 1, height: '100%',
          background: 'transparent', border: 'none', outline: 'none',
          fontFamily: SYN_DISPLAY,
          fontSize: 26, fontWeight: 600,
          color: SYN.text,
          letterSpacing: '-0.02em',
          padding: 0,
          position: 'relative',
        }}
      />
      {valid && (
        <div style={{
          width: 30, height: 30, borderRadius: '50%',
          background: 'rgba(34,197,94,0.18)',
          border: '1px solid rgba(34,197,94,0.55)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          boxShadow: '0 0 12px rgba(34,197,94,0.35)',
          flexShrink: 0,
        }}>
          <svg width="14" height="14" viewBox="0 0 12 12">
            <path d="M2.5 6.2 L5 8.6 L9.5 3.6" stroke="#22C55E" strokeWidth="2" fill="none" strokeLinecap="round" strokeLinejoin="round"/>
          </svg>
        </div>
      )}
    </div>
  );
}


// ───────────────────────────────────────────────────────────────────
// SCREEN 4 — Age (25%) — vertical scroll picker
// ───────────────────────────────────────────────────────────────────
function S4Age({ data, setData, onBack, onNext }) {
  const age = +data.age || 20;
  const [phase, setPhase] = React.useState(0);
  React.useEffect(() => {
    const t = setTimeout(() => setPhase(1), 200);
    return () => clearTimeout(t);
  }, []);

  const change = (delta) => {
    const next = Math.min(80, Math.max(13, age + delta));
    setData({ ...data, age: String(next) });
  };

  // Wheel + drag
  const ref = useR(null);
  const dragY = useR(null);
  useE(() => {
    const el = ref.current; if (!el) return;
    const onWheel = (e) => {
      e.preventDefault();
      if (Math.abs(e.deltaY) > 2) change(e.deltaY > 0 ? 1 : -1);
    };
    el.addEventListener('wheel', onWheel, { passive: false });
    return () => el.removeEventListener('wheel', onWheel);
  });

  // Cohort logic removed — tag was judgmental ("PEAK BUILDER" etc).
  // Age is still saved to data and used downstream for recovery calibration.

  return (
    <Shell ambient={false}>
      <div style={{
        position: 'absolute', inset: 0, pointerEvents: 'none',
        background: 'radial-gradient(140% 60% at 50% -10%, rgba(0,229,255,0.18) 0%, rgba(0,229,255,0.05) 25%, transparent 55%)',
      }}/>
      <div style={{
        position: 'absolute', inset: 0, pointerEvents: 'none',
        background: 'radial-gradient(80% 40% at 50% 8%, transparent 25%, rgba(0,229,255,0.05) 38%, transparent 55%)',
        animation: 'auraPulse 5s ease-in-out infinite',
      }}/>

      <div style={{ position: 'relative', display: 'flex', flexDirection: 'column', height: '100%' }}>
        <Header progress={25} onBack={onBack}/>

        <Flex grow={0.6}/>

        <div style={{
          alignSelf: 'center',
          fontFamily: SYN_FONT, fontSize: 11, fontWeight: 600,
          color: SYN.cyan, letterSpacing: '0.18em',
          padding: '6px 14px', borderRadius: 999,
          border: '1px solid rgba(0,229,255,0.35)',
          background: 'rgba(0,229,255,0.06)',
          boxShadow: '0 0 16px rgba(0,229,255,0.25), inset 0 0 12px rgba(0,229,255,0.1)',
          opacity: phase >= 1 ? 1 : 0,
          transform: phase >= 1 ? 'translateY(0)' : 'translateY(8px)',
          transition: 'all 600ms cubic-bezier(.2,.7,.2,1)',
        }}>BASELINE CALIBRATION</div>

        <Sp h={20}/>

        <div style={{
          fontFamily: SYN_DISPLAY, fontWeight: 700, fontSize: 30,
          color: SYN.text, letterSpacing: '-0.03em', lineHeight: 1.1,
          textAlign: 'center', maxWidth: 320, alignSelf: 'center',
          opacity: phase >= 1 ? 1 : 0,
          transform: phase >= 1 ? 'translateY(0)' : 'translateY(10px)',
          transition: 'all 700ms cubic-bezier(.2,.7,.2,1) 100ms',
        }}>
          How old <span style={{
            background: `linear-gradient(180deg, ${SYN.cyan} 0%, #7CE8F5 100%)`,
            WebkitBackgroundClip: 'text', backgroundClip: 'text', color: 'transparent',
            filter: 'drop-shadow(0 0 12px rgba(0,229,255,0.5))',
          }}>are you</span>?
        </div>
        <Sp h={10}/>
        <div style={{
          fontFamily: SYN_FONT, fontSize: 15, color: SYN.textDim,
          textAlign: 'center', letterSpacing: '-0.005em',
          opacity: phase >= 1 ? 1 : 0,
          transition: 'opacity 700ms ease 250ms',
        }}>We use this to calibrate your recovery baseline</div>

        <Sp h={48}/>

        {/* Picker container with side gradient masks */}
        <div style={{
          position: 'relative',
          opacity: phase >= 1 ? 1 : 0,
          transform: phase >= 1 ? 'translateY(0)' : 'translateY(14px)',
          transition: 'all 700ms cubic-bezier(.2,.7,.2,1) 350ms',
        }}>
          {/* Top + bottom fade overlays */}
          <div style={{
            position: 'absolute', left: 0, right: 0, top: 0, height: 60, pointerEvents: 'none', zIndex: 2,
            background: `linear-gradient(180deg, ${SYN.bg} 0%, transparent 100%)`,
          }}/>
          <div style={{
            position: 'absolute', left: 0, right: 0, bottom: 0, height: 60, pointerEvents: 'none', zIndex: 2,
            background: `linear-gradient(0deg, ${SYN.bg} 0%, transparent 100%)`,
          }}/>

          <div ref={ref} style={{
            position: 'relative', height: 280,
            display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center',
            userSelect: 'none', cursor: 'ns-resize',
          }}
            onTouchStart={(e) => { dragY.current = e.touches[0].clientY; }}
            onTouchMove={(e) => {
              if (dragY.current == null) return;
              const dy = e.touches[0].clientY - dragY.current;
              if (Math.abs(dy) > 28) { change(dy > 0 ? -1 : 1); dragY.current = e.touches[0].clientY; }
            }}
            onTouchEnd={() => { dragY.current = null; }}
          >
            <div onClick={() => change(-2)} style={ageRowStyle(0.25, 24)}>{age - 2}</div>
            <Sp h={14}/>
            <div onClick={() => change(-1)} style={ageRowStyle(0.55, 32)}>{age - 1}</div>
            <Sp h={14}/>
            <div style={{
              position: 'relative',
              fontFamily: SYN_DISPLAY, fontWeight: 700, fontSize: 80,
              lineHeight: 1, color: SYN.text, letterSpacing: '-0.04em',
              textShadow: '0 0 32px rgba(0,229,255,0.55), 0 0 64px rgba(0,229,255,0.25)',
            }}>
              {age}
              <span style={{
                position: 'absolute', right: -36, top: 16,
                fontFamily: SYN_FONT, fontSize: 13, fontWeight: 500,
                color: SYN.textDim, letterSpacing: '0.05em',
              }}>yrs</span>
            </div>
            <Sp h={14}/>
            <div onClick={() => change(1)} style={ageRowStyle(0.55, 32)}>{age + 1}</div>
            <Sp h={14}/>
            <div onClick={() => change(2)} style={ageRowStyle(0.25, 24)}>{age + 2}</div>
          </div>
        </div>

        <Flex/>
        <BottomCTA><CTA onClick={onNext}>Continue</CTA></BottomCTA>
      </div>
    </Shell>
  );
}
function ageRowStyle(opacity = 0.4, fontSize = 32) {
  return {
    fontFamily: SYN_DISPLAY, fontWeight: 400, fontSize,
    color: SYN.textFaint, letterSpacing: '-0.02em',
    cursor: 'pointer', opacity,
    transition: 'opacity 200ms ease',
  };
}
function hr() {
  return { width: '100%', height: 1, background: SYN.border };
}

// ───────────────────────────────────────────────────────────────────
// SCREEN 5 — Emotional hook (33%)
// ───────────────────────────────────────────────────────────────────
function S5Hook({ onBack, onNext }) {
  const [phase, setPhase] = React.useState(0); // 0: thinking, 1: reveal
  React.useEffect(() => {
    const t = setTimeout(() => setPhase(1), 1400);
    return () => clearTimeout(t);
  }, []);

  return (
    <Shell ambient={false}>
      {/* Layered ambient glows */}
      <div style={{
        position: 'absolute', inset: 0, pointerEvents: 'none',
        background: 'radial-gradient(circle at 50% 38%, rgba(0,229,255,0.22) 0%, rgba(0,229,255,0.08) 22%, transparent 55%)',
      }}/>
      <div style={{
        position: 'absolute', inset: 0, pointerEvents: 'none',
        background: 'radial-gradient(circle at 50% 38%, transparent 28%, rgba(0,229,255,0.04) 40%, transparent 60%)',
        animation: 'pulseSoft 4s ease-in-out infinite',
      }}/>

      {/* Subtle grain / scan lines */}
      <div style={{
        position: 'absolute', inset: 0, pointerEvents: 'none', opacity: 0.06,
        backgroundImage: 'repeating-linear-gradient(180deg, rgba(255,255,255,0.6) 0 1px, transparent 1px 3px)',
        maskImage: 'radial-gradient(circle at 50% 38%, black 0%, transparent 60%)',
        WebkitMaskImage: 'radial-gradient(circle at 50% 38%, black 0%, transparent 60%)',
      }}/>

      <div style={{ position: 'relative', display: 'flex', flexDirection: 'column', height: '100%' }}>
        <Header progress={33} onBack={onBack}/>

        <div style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'flex-start', paddingTop: 56 }}>
          {/* Orb */}
          <div style={{
            position: 'relative', width: 240, height: 240,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}>
            {/* Outer orbiting ring */}
            <div style={{
              position: 'absolute', inset: 0, borderRadius: '50%',
              border: '1px solid rgba(0,229,255,0.18)',
              animation: 'spin 22s linear infinite',
            }}>
              <div style={{
                position: 'absolute', top: -3, left: '50%', width: 6, height: 6, marginLeft: -3,
                borderRadius: '50%', background: SYN.cyan,
                boxShadow: '0 0 12px rgba(0,229,255,0.9)',
              }}/>
            </div>
            {/* Mid ring */}
            <div style={{
              position: 'absolute', inset: 28, borderRadius: '50%',
              border: '1px dashed rgba(0,229,255,0.28)',
              animation: 'spin 14s linear infinite reverse',
            }}/>
            {/* Inner ring with tick marks */}
            <svg viewBox="0 0 200 200" style={{
              position: 'absolute', inset: 50, width: 'calc(100% - 100px)', height: 'calc(100% - 100px)',
              animation: 'spin 30s linear infinite',
            }}>
              <circle cx="100" cy="100" r="98" fill="none" stroke="rgba(0,229,255,0.35)" strokeWidth="1"/>
              {Array.from({ length: 36 }).map((_, i) => (
                <line key={i} x1="100" y1="2" x2="100" y2={i % 3 === 0 ? 12 : 7}
                  stroke="rgba(0,229,255,0.5)" strokeWidth="1"
                  transform={`rotate(${i * 10} 100 100)`}/>
              ))}
            </svg>
            {/* Core */}
            <div style={{
              position: 'relative', width: 96, height: 96, borderRadius: '50%',
              background: 'radial-gradient(circle at 35% 30%, rgba(255,255,255,0.95) 0%, rgba(0,229,255,0.85) 28%, rgba(0,150,180,0.6) 60%, rgba(0,80,100,0.3) 100%)',
              boxShadow: '0 0 60px rgba(0,229,255,0.7), 0 0 120px rgba(0,229,255,0.4), inset 0 0 30px rgba(255,255,255,0.3)',
              animation: 'pulseCore 3s ease-in-out infinite',
            }}>
              <div style={{
                position: 'absolute', top: '18%', left: '22%', width: '32%', height: '24%',
                borderRadius: '50%', background: 'rgba(255,255,255,0.55)', filter: 'blur(6px)',
              }}/>
            </div>
          </div>

          <Sp h={48}/>

          {/* Eyebrow tag */}
          <div style={{
            fontFamily: SYN_FONT, fontSize: 11, fontWeight: 600,
            color: SYN.cyan, letterSpacing: '0.18em',
            padding: '6px 14px', borderRadius: 999,
            border: '1px solid rgba(0,229,255,0.35)',
            background: 'rgba(0,229,255,0.06)',
            boxShadow: '0 0 16px rgba(0,229,255,0.25), inset 0 0 12px rgba(0,229,255,0.1)',
            opacity: phase >= 1 ? 1 : 0,
            transform: phase >= 1 ? 'translateY(0)' : 'translateY(8px)',
            transition: 'all 600ms cubic-bezier(.2,.7,.2,1)',
          }}>YOUR PERSONAL INSIGHT</div>

          <Sp h={20}/>

          {/* Headline */}
          <div style={{ maxWidth: 320, textAlign: 'center', position: 'relative' }}>
            <div style={{
              fontFamily: SYN_DISPLAY, fontWeight: 500, fontSize: 20,
              color: SYN.textDim, letterSpacing: '-0.015em', lineHeight: 1.25,
              opacity: phase >= 1 ? 1 : 0,
              transform: phase >= 1 ? 'translateY(0)' : 'translateY(10px)',
              transition: 'all 700ms cubic-bezier(.2,.7,.2,1) 100ms',
            }}>Imagine knowing exactly</div>
            <Sp h={8}/>
            <div style={{
              fontFamily: SYN_DISPLAY, fontWeight: 700, fontSize: 30,
              color: SYN.text, letterSpacing: '-0.03em', lineHeight: 1.1,
              opacity: phase >= 1 ? 1 : 0,
              transform: phase >= 1 ? 'translateY(0)' : 'translateY(10px)',
              transition: 'all 700ms cubic-bezier(.2,.7,.2,1) 250ms',
            }}>
              why your last <span style={{
                background: `linear-gradient(180deg, ${SYN.cyan} 0%, #7CE8F5 100%)`,
                WebkitBackgroundClip: 'text', backgroundClip: 'text', color: 'transparent',
                textShadow: '0 0 24px rgba(0,229,255,0.4)',
                filter: 'drop-shadow(0 0 12px rgba(0,229,255,0.5))',
              }}>good lift</span> was good.
            </div>
            <Sp h={16}/>
            <div style={{
              fontFamily: SYN_FONT, fontWeight: 400, fontSize: 15,
              color: SYN.textDim, letterSpacing: '-0.005em', lineHeight: 1.4,
              opacity: phase >= 1 ? 1 : 0,
              transition: 'opacity 700ms ease 450ms',
            }}>And being able to do it again, on demand.</div>
          </div>
        </div>

        <BottomCTA><CTA onClick={onNext}>Tell me how</CTA></BottomCTA>
      </div>

      <style>{`
        @keyframes spin { to { transform: rotate(360deg); } }
        @keyframes pulseSoft {
          0%, 100% { opacity: 0.4; transform: scale(1); }
          50% { opacity: 1; transform: scale(1.08); }
        }
        @keyframes pulseCore {
          0%, 100% { box-shadow: 0 0 60px rgba(0,229,255,0.7), 0 0 120px rgba(0,229,255,0.4), inset 0 0 30px rgba(255,255,255,0.3); }
          50% { box-shadow: 0 0 80px rgba(0,229,255,0.9), 0 0 160px rgba(0,229,255,0.55), inset 0 0 40px rgba(255,255,255,0.4); }
        }
      `}</style>
    </Shell>
  );
}

// ───────────────────────────────────────────────────────────────────
// SCREEN 6 — Benefits list (41%)
// ───────────────────────────────────────────────────────────────────
function S6Benefits({ onBack, onNext }) {
  const items = [
    "What sleep amount fuels your heaviest lifts",
    "Which meal timing wrecks your sessions",
    "Your true recovery score, weekly",
    "Where you rank in your gym group",
    "Your tier each Sunday at midnight",
  ];
  const [phase, setPhase] = React.useState(0);
  React.useEffect(() => {
    const t = setTimeout(() => setPhase(1), 200);
    return () => clearTimeout(t);
  }, []);

  return (
    <Shell ambient={false}>
      <div style={{
        position: 'absolute', inset: 0, pointerEvents: 'none',
        background: 'radial-gradient(140% 60% at 50% -10%, rgba(0,229,255,0.18) 0%, rgba(0,229,255,0.05) 25%, transparent 55%)',
      }}/>
      <div style={{
        position: 'absolute', inset: 0, pointerEvents: 'none',
        background: 'radial-gradient(80% 40% at 50% 8%, transparent 25%, rgba(0,229,255,0.05) 38%, transparent 55%)',
        animation: 'auraPulse 5s ease-in-out infinite',
      }}/>
      <div style={{ position: 'relative', display: 'flex', flexDirection: 'column', height: '100%' }}>
        <Header progress={41} onBack={onBack}/>
        <Sp h={32}/>

        <div style={{
          alignSelf: 'center',
          fontFamily: SYN_FONT, fontSize: 11, fontWeight: 600,
          color: SYN.cyan, letterSpacing: '0.18em',
          padding: '6px 14px', borderRadius: 999,
          border: '1px solid rgba(0,229,255,0.35)',
          background: 'rgba(0,229,255,0.06)',
          boxShadow: '0 0 16px rgba(0,229,255,0.25), inset 0 0 12px rgba(0,229,255,0.1)',
          opacity: phase >= 1 ? 1 : 0,
          transform: phase >= 1 ? 'translateY(0)' : 'translateY(8px)',
          transition: 'all 600ms cubic-bezier(.2,.7,.2,1)',
        }}>WEEK 2 UNLOCKS</div>

        <Sp h={20}/>
        <div style={{
          fontFamily: SYN_DISPLAY, fontWeight: 700, fontSize: 30,
          color: SYN.text, letterSpacing: '-0.03em', lineHeight: 1.1,
          textAlign: 'center', maxWidth: 320, alignSelf: 'center',
          opacity: phase >= 1 ? 1 : 0,
          transform: phase >= 1 ? 'translateY(0)' : 'translateY(10px)',
          transition: 'all 700ms cubic-bezier(.2,.7,.2,1) 100ms',
        }}>
          Here's what <span style={{
            background: `linear-gradient(180deg, ${SYN.cyan} 0%, #7CE8F5 100%)`,
            WebkitBackgroundClip: 'text', backgroundClip: 'text', color: 'transparent',
            filter: 'drop-shadow(0 0 12px rgba(0,229,255,0.5))',
          }}>you'll know</span>
        </div>
        <Sp h={10}/>
        <div style={{
          fontFamily: SYN_FONT, fontSize: 15, color: SYN.textDim,
          textAlign: 'center', letterSpacing: '-0.005em',
          opacity: phase >= 1 ? 1 : 0,
          transition: 'opacity 700ms ease 250ms',
        }}>After 2 weeks of check-ins</div>

        <Sp h={36}/>

        <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
          {items.map((t, i) => (
            <div key={i} style={{
              position: 'relative',
              display: 'flex', alignItems: 'center', gap: 16,
              padding: '14px 16px',
              background: 'linear-gradient(180deg, rgba(26,26,30,0.6) 0%, rgba(19,19,22,0.6) 100%)',
              border: `1px solid ${SYN.border}`,
              borderRadius: 14,
              boxShadow: 'inset 0 1px 0 rgba(255,255,255,0.04)',
              opacity: phase >= 1 ? 1 : 0,
              transform: phase >= 1 ? 'translateX(0)' : 'translateX(-12px)',
              transition: `all 600ms cubic-bezier(.2,.7,.2,1) ${320 + i * 90}ms`,
            }}>
              {/* Left cyan accent stroke */}
              <div style={{
                position: 'absolute', left: 0, top: 12, bottom: 12, width: 2,
                background: `linear-gradient(180deg, transparent 0%, ${SYN.cyan} 50%, transparent 100%)`,
                boxShadow: `0 0 10px ${SYN.cyanGlow}`,
              }}/>
              <div style={{
                width: 28, height: 28, borderRadius: '50%',
                background: 'radial-gradient(circle, rgba(0,229,255,0.20) 0%, rgba(0,229,255,0.04) 70%)',
                border: `1px solid ${SYN.cyan}`,
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                flexShrink: 0,
                boxShadow: `0 0 10px ${SYN.cyanGlow}, inset 0 0 8px rgba(0,229,255,0.15)`,
              }}>
                <svg width="14" height="14" viewBox="0 0 12 12">
                  <path d="M2.5 6.2 L5 8.6 L9.5 3.6" stroke={SYN.cyan} strokeWidth="2.2" fill="none" strokeLinecap="round" strokeLinejoin="round"/>
                </svg>
              </div>
              <div style={{
                fontFamily: SYN_FONT, fontWeight: 500, fontSize: 15,
                color: SYN.text, letterSpacing: '-0.01em', lineHeight: 1.35,
              }}>{t}</div>
            </div>
          ))}
        </div>

        <Flex/>
        <BottomCTA><CTA onClick={onNext}>Show me</CTA></BottomCTA>
      </div>
    </Shell>
  );
}

// ───────────────────────────────────────────────────────────────────
// SCREEN 7 — Goal (50%)
// ───────────────────────────────────────────────────────────────────
function S7Goal({ data, setData, onBack, onNext }) {
  const goals = ['Build Muscle', 'Get Stronger', 'Cut Weight', 'Stay Consistent'];
  const [phase, setPhase] = React.useState(0);
  React.useEffect(() => {
    const t = setTimeout(() => setPhase(1), 200);
    return () => clearTimeout(t);
  }, []);
  return (
    <Shell ambient={false}>
      <div style={{
        position: 'absolute', inset: 0, pointerEvents: 'none',
        background: 'radial-gradient(140% 60% at 50% -10%, rgba(0,229,255,0.18) 0%, rgba(0,229,255,0.05) 25%, transparent 55%)',
      }}/>
      <div style={{
        position: 'absolute', inset: 0, pointerEvents: 'none',
        background: 'radial-gradient(80% 40% at 50% 8%, transparent 25%, rgba(0,229,255,0.05) 38%, transparent 55%)',
        animation: 'auraPulse 5s ease-in-out infinite',
      }}/>
      <div style={{ position: 'relative', display: 'flex', flexDirection: 'column', height: '100%' }}>
        <Header progress={50} onBack={onBack}/>
        <Sp h={32}/>
        <div style={{
          alignSelf: 'center',
          fontFamily: SYN_FONT, fontSize: 11, fontWeight: 600,
          color: SYN.cyan, letterSpacing: '0.18em',
          padding: '6px 14px', borderRadius: 999,
          border: '1px solid rgba(0,229,255,0.35)',
          background: 'rgba(0,229,255,0.06)',
          boxShadow: '0 0 16px rgba(0,229,255,0.25), inset 0 0 12px rgba(0,229,255,0.1)',
          opacity: phase >= 1 ? 1 : 0,
          transform: phase >= 1 ? 'translateY(0)' : 'translateY(8px)',
          transition: 'all 600ms cubic-bezier(.2,.7,.2,1)',
        }}>YOUR PRIMARY GOAL</div>

        <Sp h={20}/>
        <div style={{
          fontFamily: SYN_DISPLAY, fontWeight: 700, fontSize: 30,
          color: SYN.text, letterSpacing: '-0.03em', lineHeight: 1.1,
          textAlign: 'center', maxWidth: 320, alignSelf: 'center',
          opacity: phase >= 1 ? 1 : 0,
          transform: phase >= 1 ? 'translateY(0)' : 'translateY(10px)',
          transition: 'all 700ms cubic-bezier(.2,.7,.2,1) 100ms',
        }}>
          What are you <span style={{
            background: `linear-gradient(180deg, ${SYN.cyan} 0%, #7CE8F5 100%)`,
            WebkitBackgroundClip: 'text', backgroundClip: 'text', color: 'transparent',
            filter: 'drop-shadow(0 0 12px rgba(0,229,255,0.5))',
          }}>training</span> for?
        </div>
        <Sp h={10}/>
        <div style={{
          fontFamily: SYN_FONT, fontSize: 15, color: SYN.textDim,
          textAlign: 'center', letterSpacing: '-0.005em',
          opacity: phase >= 1 ? 1 : 0,
          transition: 'opacity 700ms ease 250ms',
        }}>Pick what matters most right now</div>

        <Sp h={36}/>

        <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
          {goals.map((g, i) => (
            <div key={g} style={{
              opacity: phase >= 1 ? 1 : 0,
              transform: phase >= 1 ? 'translateY(0)' : 'translateY(12px)',
              transition: `all 600ms cubic-bezier(.2,.7,.2,1) ${320 + i * 80}ms`,
            }}>
              <SpecCard title={g}
                selected={data.goal === g}
                onClick={() => setData({ ...data, goal: g })}/>
            </div>
          ))}
        </div>
        <Flex/>
        <BottomCTA><CTA disabled={!data.goal} onClick={onNext}>Continue</CTA></BottomCTA>
      </div>
    </Shell>
  );
}

// ───────────────────────────────────────────────────────────────────
// SCREEN 8 — Frequency (58%)
// ───────────────────────────────────────────────────────────────────
function S8Frequency({ data, setData, onBack, onNext }) {
  const v = data.daysPerWeek;
  const [phase, setPhase] = React.useState(0);
  React.useEffect(() => {
    const t = setTimeout(() => setPhase(1), 200);
    return () => clearTimeout(t);
  }, []);
  const tier = v <= 2 ? 'CASUAL' : v <= 4 ? 'COMMITTED' : v <= 5 ? 'SERIOUS' : 'ELITE';
  return (
    <Shell ambient={false}>
      <div style={{
        position: 'absolute', inset: 0, pointerEvents: 'none',
        background: 'radial-gradient(140% 60% at 50% -10%, rgba(0,229,255,0.18) 0%, rgba(0,229,255,0.05) 25%, transparent 55%)',
      }}/>
      <div style={{
        position: 'absolute', inset: 0, pointerEvents: 'none',
        background: 'radial-gradient(80% 40% at 50% 8%, transparent 25%, rgba(0,229,255,0.05) 38%, transparent 55%)',
        animation: 'auraPulse 5s ease-in-out infinite',
      }}/>
      <div style={{ position: 'relative', display: 'flex', flexDirection: 'column', height: '100%' }}>
        <Header progress={58} onBack={onBack}/>
        <Sp h={32}/>
        <div style={{
          alignSelf: 'center',
          fontFamily: SYN_FONT, fontSize: 11, fontWeight: 600,
          color: SYN.cyan, letterSpacing: '0.18em',
          padding: '6px 14px', borderRadius: 999,
          border: '1px solid rgba(0,229,255,0.35)',
          background: 'rgba(0,229,255,0.06)',
          boxShadow: '0 0 16px rgba(0,229,255,0.25), inset 0 0 12px rgba(0,229,255,0.1)',
          opacity: phase >= 1 ? 1 : 0,
          transform: phase >= 1 ? 'translateY(0)' : 'translateY(8px)',
          transition: 'all 600ms cubic-bezier(.2,.7,.2,1)',
        }}>TRAINING VOLUME</div>
        <Sp h={20}/>
        <div style={{
          fontFamily: SYN_DISPLAY, fontWeight: 700, fontSize: 30,
          color: SYN.text, letterSpacing: '-0.03em', lineHeight: 1.1,
          textAlign: 'center', maxWidth: 320, alignSelf: 'center',
          opacity: phase >= 1 ? 1 : 0,
          transform: phase >= 1 ? 'translateY(0)' : 'translateY(10px)',
          transition: 'all 700ms cubic-bezier(.2,.7,.2,1) 100ms',
        }}>
          How often do you <span style={{
            background: `linear-gradient(180deg, ${SYN.cyan} 0%, #7CE8F5 100%)`,
            WebkitBackgroundClip: 'text', backgroundClip: 'text', color: 'transparent',
            filter: 'drop-shadow(0 0 12px rgba(0,229,255,0.5))',
          }}>lift</span>?
        </div>
        <Sp h={10}/>
        <div style={{
          fontFamily: SYN_FONT, fontSize: 15, color: SYN.textDim,
          textAlign: 'center', letterSpacing: '-0.005em',
          opacity: phase >= 1 ? 1 : 0,
          transition: 'opacity 700ms ease 250ms',
        }}>Days per week, on average</div>

        <Sp h={48}/>
        <div style={{
          opacity: phase >= 1 ? 1 : 0,
          transform: phase >= 1 ? 'translateY(0)' : 'translateY(14px)',
          transition: 'all 700ms cubic-bezier(.2,.7,.2,1) 350ms',
        }}>
          <BigNumber value={v}/>
          <Sp h={8}/>
          <div style={{ textAlign: 'center' }}><Label color={SYN.textDim}>DAYS PER WEEK</Label></div>
        </div>
        <Sp h={20}/>
        <div style={{
          alignSelf: 'center',
          fontFamily: 'ui-monospace, "SF Mono", Menlo, monospace',
          fontSize: 11, fontWeight: 600,
          color: SYN.cyan, letterSpacing: '0.18em',
          padding: '6px 12px', borderRadius: 6,
          background: 'rgba(0,229,255,0.05)',
          border: '1px solid rgba(0,229,255,0.2)',
          opacity: phase >= 1 ? 1 : 0,
          transition: 'opacity 700ms ease 500ms',
        }}>{tier}</div>
        <Sp h={32}/>
        <div style={{
          opacity: phase >= 1 ? 1 : 0,
          transition: 'opacity 700ms ease 450ms',
          paddingBottom: 28,
        }}>
          <SpecSlider value={v} min={1} max={7} step={1}
            ticks={[1,2,3,4,5,6,7]}
            tickLabels={['1','2','3','4','5','6','7']}
            onChange={(n) => setData({ ...data, daysPerWeek: n })}/>
        </div>
        <Flex/>
        <BottomCTA><CTA onClick={onNext}>Continue</CTA></BottomCTA>
      </div>
    </Shell>
  );
}

function BigNumber({ value, fractional }) {
  // Optional fractional rendering: integer at 120pt, fraction at 80pt.
  if (typeof value === 'number' && !Number.isInteger(value)) {
    const i = Math.trunc(value);
    const f = (value - i).toFixed(1).slice(1); // ".5"
    return (
      <div style={{ display: 'flex', justifyContent: 'center', alignItems: 'baseline', position: 'relative' }}>
        <div style={{
          position: 'absolute', width: 240, height: 120, borderRadius: '50%',
          background: 'radial-gradient(circle, rgba(0,229,255,0.20), transparent 60%)',
          filter: 'blur(8px)', pointerEvents: 'none',
        }} />
        <span className="mono" style={bigDigit(120)}>{i}</span>
        <span className="mono" style={bigDigit(80)}>{f}</span>
      </div>
    );
  }
  return (
    <div style={{ display: 'flex', justifyContent: 'center', alignItems: 'center', position: 'relative' }}>
      <div style={{
        position: 'absolute', width: 200, height: 120, borderRadius: '50%',
        background: 'radial-gradient(circle, rgba(0,229,255,0.22), transparent 60%)',
        filter: 'blur(8px)', pointerEvents: 'none',
      }} />
      <span className="mono" style={bigDigit(120)}>{value}</span>
    </div>
  );
}
function bigDigit(size) {
  return {
    fontFamily: SYN_MONO, fontWeight: 700, fontSize: size,
    lineHeight: 1, letterSpacing: '-0.04em',
    color: SYN.text,
    textShadow: '0 0 32px rgba(0,229,255,0.45)',
    position: 'relative',
  };
}
function SliderEnds({ left, right }) {
  return (
    <div style={{
      display: 'flex', justifyContent: 'space-between',
      fontFamily: SYN_FONT, fontWeight: 400, fontSize: 13,
      color: SYN.textFaint,
    }}>
      <span>{left}</span><span>{right}</span>
    </div>
  );
}

// ───────────────────────────────────────────────────────────────────
// SCREEN 9 — Sleep (66%)
// ───────────────────────────────────────────────────────────────────
function S9Sleep({ data, setData, onBack, onNext }) {
  const v = data.sleepHours;
  const [phase, setPhase] = React.useState(0);
  React.useEffect(() => {
    const t = setTimeout(() => setPhase(1), 200);
    return () => clearTimeout(t);
  }, []);
  const quality = v < 6 ? 'UNDERSLEPT' : v < 7 ? 'BELOW IDEAL' : v <= 9 ? 'OPTIMAL ZONE' : 'OVERSLEPT';
  return (
    <Shell ambient={false}>
      <div style={{
        position: 'absolute', inset: 0, pointerEvents: 'none',
        background: 'radial-gradient(140% 60% at 50% -10%, rgba(0,229,255,0.18) 0%, rgba(0,229,255,0.05) 25%, transparent 55%)',
      }}/>
      <div style={{
        position: 'absolute', inset: 0, pointerEvents: 'none',
        background: 'radial-gradient(80% 40% at 50% 8%, transparent 25%, rgba(0,229,255,0.05) 38%, transparent 55%)',
        animation: 'auraPulse 5s ease-in-out infinite',
      }}/>
      <div style={{ position: 'relative', display: 'flex', flexDirection: 'column', height: '100%' }}>
        <Header progress={66} onBack={onBack}/>
        <Flex grow={0.5}/>
        <div style={{
          alignSelf: 'center',
          fontFamily: SYN_FONT, fontSize: 11, fontWeight: 600,
          color: SYN.cyan, letterSpacing: '0.18em',
          padding: '6px 14px', borderRadius: 999,
          border: '1px solid rgba(0,229,255,0.35)',
          background: 'rgba(0,229,255,0.06)',
          boxShadow: '0 0 16px rgba(0,229,255,0.25), inset 0 0 12px rgba(0,229,255,0.1)',
          opacity: phase >= 1 ? 1 : 0,
          transform: phase >= 1 ? 'translateY(0)' : 'translateY(8px)',
          transition: 'all 600ms cubic-bezier(.2,.7,.2,1)',
        }}>RECOVERY INPUT</div>
        <Sp h={20}/>
        <div style={{
          fontFamily: SYN_DISPLAY, fontWeight: 700, fontSize: 30,
          color: SYN.text, letterSpacing: '-0.03em', lineHeight: 1.1,
          textAlign: 'center', maxWidth: 320, alignSelf: 'center',
          opacity: phase >= 1 ? 1 : 0,
          transform: phase >= 1 ? 'translateY(0)' : 'translateY(10px)',
          transition: 'all 700ms cubic-bezier(.2,.7,.2,1) 100ms',
        }}>
          How much <span style={{
            background: `linear-gradient(180deg, ${SYN.cyan} 0%, #7CE8F5 100%)`,
            WebkitBackgroundClip: 'text', backgroundClip: 'text', color: 'transparent',
            filter: 'drop-shadow(0 0 12px rgba(0,229,255,0.5))',
          }}>sleep</span> do you get?
        </div>
        <Sp h={10}/>
        <div style={{
          fontFamily: SYN_FONT, fontSize: 15, color: SYN.textDim,
          textAlign: 'center', letterSpacing: '-0.005em',
          opacity: phase >= 1 ? 1 : 0,
          transition: 'opacity 700ms ease 250ms',
        }}>Hours per night, your typical average</div>

        <Sp h={48}/>
        <div style={{
          opacity: phase >= 1 ? 1 : 0,
          transform: phase >= 1 ? 'translateY(0)' : 'translateY(14px)',
          transition: 'all 700ms cubic-bezier(.2,.7,.2,1) 350ms',
        }}>
          <BigNumber value={v}/>
          <Sp h={8}/>
          <div style={{ textAlign: 'center' }}><Label color={SYN.textDim}>HOURS PER NIGHT</Label></div>
        </div>
        <Sp h={20}/>
        <div style={{
          alignSelf: 'center',
          fontFamily: 'ui-monospace, "SF Mono", Menlo, monospace',
          fontSize: 11, fontWeight: 600,
          color: SYN.cyan, letterSpacing: '0.18em',
          padding: '6px 12px', borderRadius: 6,
          background: 'rgba(0,229,255,0.05)',
          border: '1px solid rgba(0,229,255,0.2)',
          opacity: phase >= 1 ? 1 : 0,
          transition: 'opacity 700ms ease 500ms',
        }}>{quality}</div>
        <Sp h={32}/>
        <div style={{
          opacity: phase >= 1 ? 1 : 0,
          transition: 'opacity 700ms ease 450ms',
          paddingBottom: 28,
        }}>
          <SpecSlider value={v} min={4} max={12} step={0.5}
            ticks={[4,6,8,10,12]}
            tickLabels={['4h','6h','8h','10h','12h']}
            onChange={(n) => setData({ ...data, sleepHours: n })}/>
        </div>
        <Flex/>
        <BottomCTA><CTA onClick={onNext}>Continue</CTA></BottomCTA>
      </div>
    </Shell>
  );
}

// ───────────────────────────────────────────────────────────────────
// SCREEN 10 — Diagnostic (75%)
// ───────────────────────────────────────────────────────────────────
function S10Diagnostic({ data, setData, onBack, onNext }) {
  const opts = [
    'Bad sleep the night before',
    'Skipping meals or eating wrong',
    'Mental stress carrying over',
    'Not warming up properly',
    "Honestly not sure yet",
  ];
  const [phase, setPhase] = React.useState(0);
  React.useEffect(() => {
    const t = setTimeout(() => setPhase(1), 200);
    return () => clearTimeout(t);
  }, []);
  return (
    <Shell ambient={false}>
      <div style={{
        position: 'absolute', inset: 0, pointerEvents: 'none',
        background: 'radial-gradient(140% 60% at 50% -10%, rgba(0,229,255,0.18) 0%, rgba(0,229,255,0.05) 25%, transparent 55%)',
      }}/>
      <div style={{
        position: 'absolute', inset: 0, pointerEvents: 'none',
        background: 'radial-gradient(80% 40% at 50% 8%, transparent 25%, rgba(0,229,255,0.05) 38%, transparent 55%)',
        animation: 'auraPulse 5s ease-in-out infinite',
      }}/>
      <div style={{ position: 'relative', display: 'flex', flexDirection: 'column', height: '100%' }}>
        <Header progress={75} onBack={onBack}/>
        <Flex grow={0.5}/>
        <div style={{
          alignSelf: 'center',
          fontFamily: SYN_FONT, fontSize: 11, fontWeight: 600,
          color: SYN.cyan, letterSpacing: '0.18em',
          padding: '6px 14px', borderRadius: 999,
          border: '1px solid rgba(0,229,255,0.35)',
          background: 'rgba(0,229,255,0.06)',
          boxShadow: '0 0 16px rgba(0,229,255,0.25), inset 0 0 12px rgba(0,229,255,0.1)',
          opacity: phase >= 1 ? 1 : 0,
          transform: phase >= 1 ? 'translateY(0)' : 'translateY(8px)',
          transition: 'all 600ms cubic-bezier(.2,.7,.2,1)',
        }}>FRICTION DIAGNOSTIC</div>
        <Sp h={20}/>
        <div style={{
          fontFamily: SYN_DISPLAY, fontWeight: 700, fontSize: 30,
          color: SYN.text, letterSpacing: '-0.03em', lineHeight: 1.1,
          textAlign: 'center', maxWidth: 320, alignSelf: 'center',
          opacity: phase >= 1 ? 1 : 0,
          transform: phase >= 1 ? 'translateY(0)' : 'translateY(10px)',
          transition: 'all 700ms cubic-bezier(.2,.7,.2,1) 100ms',
        }}>
          What makes your <span style={{
            background: `linear-gradient(180deg, ${SYN.cyan} 0%, #7CE8F5 100%)`,
            WebkitBackgroundClip: 'text', backgroundClip: 'text', color: 'transparent',
            filter: 'drop-shadow(0 0 12px rgba(0,229,255,0.5))',
          }}>worst days</span>?
        </div>
        <Sp h={10}/>
        <div style={{
          fontFamily: SYN_FONT, fontSize: 15, color: SYN.textDim,
          textAlign: 'center', letterSpacing: '-0.005em',
          opacity: phase >= 1 ? 1 : 0,
          transition: 'opacity 700ms ease 250ms',
        }}>Pick one to start. We'll learn the rest over time.</div>
        <Sp h={28}/>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
          {opts.map((o, i) => (
            <div key={o} style={{
              opacity: phase >= 1 ? 1 : 0,
              transform: phase >= 1 ? 'translateY(0)' : 'translateY(12px)',
              transition: `all 600ms cubic-bezier(.2,.7,.2,1) ${320 + i * 70}ms`,
            }}>
              <SpecCard title={o} height={64}
                selected={data.diagnostic === o}
                onClick={() => setData({ ...data, diagnostic: o })}/>
            </div>
          ))}
        </div>
        <Flex/>
        <BottomCTA><CTA disabled={!data.diagnostic} onClick={onNext}>Continue</CTA></BottomCTA>
      </div>
    </Shell>
  );
}

// ───────────────────────────────────────────────────────────────────
// SCREEN 11 — Loading (91%)
// ───────────────────────────────────────────────────────────────────
function S11Loading({ onBack, onNext }) {
  const items = [
    'Analyzing your training frequency',
    'Calculating recovery baseline',
    'Building your week 1 plan',
  ];
  const [phase, setPhase] = React.useState(0);
  React.useEffect(() => {
    const t = setTimeout(() => setPhase(1), 200);
    return () => clearTimeout(t);
  }, []);
  return (
    <Shell ambient={false}>
      <div style={{
        position: 'absolute', inset: 0, pointerEvents: 'none',
        background: 'radial-gradient(120% 60% at 50% 35%, rgba(0,229,255,0.20) 0%, rgba(0,229,255,0.06) 30%, transparent 60%)',
      }}/>
      <div style={{
        position: 'absolute', inset: 0, pointerEvents: 'none',
        background: 'radial-gradient(70% 35% at 50% 35%, transparent 30%, rgba(0,229,255,0.06) 45%, transparent 60%)',
        animation: 'auraPulse 5s ease-in-out infinite',
      }}/>
      <div style={{ position: 'relative', display: 'flex', flexDirection: 'column', height: '100%' }}>
        <Header progress={91} onBack={onBack}/>
        <Sp h={32}/>
        <div style={{
          alignSelf: 'center',
          fontFamily: SYN_FONT, fontSize: 11, fontWeight: 600,
          color: SYN.cyan, letterSpacing: '0.18em',
          padding: '6px 14px', borderRadius: 999,
          border: '1px solid rgba(0,229,255,0.35)',
          background: 'rgba(0,229,255,0.06)',
          boxShadow: '0 0 16px rgba(0,229,255,0.25), inset 0 0 12px rgba(0,229,255,0.1)',
          opacity: phase >= 1 ? 1 : 0,
          transform: phase >= 1 ? 'translateY(0)' : 'translateY(8px)',
          transition: 'all 600ms cubic-bezier(.2,.7,.2,1)',
        }}>SYNCING DATA</div>

        <Sp h={40}/>
        <div style={{
          textAlign: 'center',
          fontFamily: SYN_MONO, fontWeight: 700, fontSize: 96,
          letterSpacing: '-0.04em', lineHeight: 1,
          background: `linear-gradient(180deg, #FFFFFF 0%, ${SYN.cyan} 100%)`,
          WebkitBackgroundClip: 'text', backgroundClip: 'text', color: 'transparent',
          filter: 'drop-shadow(0 0 24px rgba(0,229,255,0.55))',
          opacity: phase >= 1 ? 1 : 0,
          transform: phase >= 1 ? 'scale(1)' : 'scale(0.9)',
          transition: 'all 700ms cubic-bezier(.2,.7,.2,1) 100ms',
        }}>91<span style={{ fontSize: 56 }}>%</span></div>
        <Sp h={12}/>
        <div style={{
          textAlign: 'center',
          fontFamily: SYN_DISPLAY, fontWeight: 600, fontSize: 18,
          color: SYN.text, letterSpacing: '-0.015em',
          opacity: phase >= 1 ? 1 : 0,
          transition: 'opacity 700ms ease 250ms',
        }}>Calibrating your tier baseline</div>
        <Sp h={28}/>
        <div style={{
          height: 6, borderRadius: 14, background: SYN.border,
          overflow: 'hidden',
          opacity: phase >= 1 ? 1 : 0,
          transition: 'opacity 700ms ease 350ms',
        }}>
          <div style={{
            width: '91%', height: '100%',
            background: `linear-gradient(90deg, ${SYN.cyan} 0%, #7CE8F5 100%)`,
            boxShadow: `0 0 14px ${SYN.cyan}, 0 0 28px rgba(0,229,255,0.5)`,
            borderRadius: 14,
          }}/>
        </div>
        <Sp h={40}/>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 14, alignItems: 'flex-start' }}>
          {items.map((t, i) => (
            <div key={i} style={{
              display: 'flex', alignItems: 'center', gap: 12,
              opacity: phase >= 1 ? 1 : 0,
              transform: phase >= 1 ? 'translateX(0)' : 'translateX(-12px)',
              transition: `all 600ms cubic-bezier(.2,.7,.2,1) ${450 + i * 100}ms`,
            }}>
              <div style={{
                width: 22, height: 22, borderRadius: '50%',
                background: 'radial-gradient(circle, rgba(0,229,255,0.25) 0%, rgba(0,229,255,0.05) 70%)',
                border: `1px solid ${SYN.cyan}`,
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                flexShrink: 0,
                boxShadow: `0 0 10px ${SYN.cyanGlow}`,
              }}>
                <svg width="12" height="12" viewBox="0 0 12 12">
                  <path d="M2.5 6.2 L5 8.6 L9.5 3.6" stroke={SYN.cyan} strokeWidth="2.2" fill="none" strokeLinecap="round" strokeLinejoin="round"/>
                </svg>
              </div>
              <div style={{
                fontFamily: SYN_FONT, fontWeight: 500, fontSize: 15,
                color: SYN.text, letterSpacing: '-0.01em',
              }}>{t}</div>
            </div>
          ))}
        </div>
        <Flex/>
        <div style={{ paddingBottom: 48 }}>
          <button onClick={onNext} style={{
            width: '100%', background: 'transparent', border: 'none',
            padding: '8px 0', fontFamily: SYN_FONT, fontWeight: 500, fontSize: 13,
            color: SYN.textFaint, cursor: 'pointer', letterSpacing: '0.04em',
            textTransform: 'uppercase',
          }}>Tap to continue (design)</button>
        </div>
      </div>
    </Shell>
  );
}

// ───────────────────────────────────────────────────────────────────
// ─────────────────────────────────────────────────────────────────
// SCREEN 12 — Tier reveal (100%)
// ─────────────────────────────────────────────────────────────────

// Tier system — distinct color + icon per tier
const TIERS = {
  cooked:   { name: 'Cooked',    range: '0 — 19',   color: '#5A5A60', tagline: "Recovery's fried. Take a beat." },
  active:   { name: 'Active',    range: '20 — 49',  color: '#FFFFFF', tagline: "Showing up. Keep stacking weeks." },
  dialed:   { name: 'Dialed',    range: '50 — 79',  color: '#22C55E', tagline: "Sleep, lifts, and recovery aligned." },
  lockedIn: { name: 'Locked In', range: '80 — 94',  color: '#00E5FF', tagline: "Top tier consistency. PR window open." },
  synced:   { name: 'Synced',    range: '95 — 100', color: '#7CE8F5', tagline: "Mind, body, training — fully synced.", gradient: true },
};

// SVG icons per tier — 48px viewbox, stroked
function TierIcon({ kind, color }) {
  const stroke = color === '#FFFFFF' ? '#0B0B0E' : '#FFFFFF';
  const common = { width: 48, height: 48, viewBox: '0 0 48 48', fill: 'none', stroke, strokeWidth: 2.6, strokeLinecap: 'round', strokeLinejoin: 'round' };
  switch (kind) {
    case 'cooked':
      // Downward arrow
      return <svg {...common} style={{ filter: 'drop-shadow(0 0 6px rgba(0,0,0,0.4))' }}>
        <path d="M24 10 L24 36 M12 26 L24 38 L36 26"/>
      </svg>;
    case 'active':
      // Upward arrow (current)
      return <svg {...common} style={{ filter: 'drop-shadow(0 0 4px rgba(0,0,0,0.3))' }}>
        <path d="M24 38 L24 12 M12 22 L24 10 L36 22"/>
      </svg>;
    case 'dialed':
      // Lightning bolt
      return <svg {...common} style={{ filter: 'drop-shadow(0 0 6px rgba(255,255,255,0.5))' }}>
        <path d="M26 6 L12 26 L22 26 L20 42 L36 22 L26 22 Z"/>
      </svg>;
    case 'lockedIn':
      // Crosshair / target
      return <svg {...common} style={{ filter: 'drop-shadow(0 0 6px rgba(255,255,255,0.6))' }}>
        <circle cx="24" cy="24" r="14"/>
        <circle cx="24" cy="24" r="6"/>
        <path d="M24 4 L24 12 M24 36 L24 44 M4 24 L12 24 M36 24 L44 24"/>
      </svg>;
    case 'synced':
      // Infinity symbol
      return <svg {...common} strokeWidth={3} style={{ filter: 'drop-shadow(0 0 8px rgba(255,255,255,0.8))' }}>
        <path d="M14 24 C14 18, 20 14, 24 20 C28 26, 34 30, 34 24 C34 18, 28 14, 24 20 C20 26, 14 30, 14 24 Z"/>
      </svg>;
    default: return null;
  }
}

function S12Reveal({ data, onBack, onNext }) {
  // Tier can be passed via tweaks; default to 'active'
  const tierKey = (data && data.startTier) || 'active';
  const tier = TIERS[tierKey] || TIERS.active;
  const isWhite = tier.color === '#FFFFFF';
  const tierColor = tier.color;
  const tierGlow = isWhite ? 'rgba(255,255,255,0.45)' : tierColor + 'B3'; // semi-transparent

  // Next tier (for the "hit X to reach Y" copy)
  const order = ['cooked', 'active', 'dialed', 'lockedIn', 'synced'];
  const nextKey = order[Math.min(order.length - 1, order.indexOf(tierKey) + 1)];
  const nextTier = TIERS[nextKey];

  const [appear, setAppear] = useS(false);
  const [phase, setPhase] = React.useState(0);
  useE(() => {
    const id = setTimeout(() => setAppear(true), 60);
    const id2 = setTimeout(() => setPhase(1), 800);
    return () => { clearTimeout(id); clearTimeout(id2); };
  }, []);

  // Helpers for ambient color washes
  const ambientHex = isWhite ? 'rgba(255,255,255,' : tierColor.startsWith('#') ? hexToRGBA(tierColor, '') : 'rgba(0,229,255,';

  return (
    <Shell ambient={false}>
      {/* Layered ambient glows — colored to match tier */}
      <div style={{
        position: 'absolute', inset: 0, pointerEvents: 'none',
        background: `radial-gradient(circle at 50% 32%, ${hexToRGBA(tierColor, 0.22)} 0%, ${hexToRGBA(tierColor, 0.08)} 22%, transparent 55%)`,
      }}/>
      <div style={{
        position: 'absolute', inset: 0, pointerEvents: 'none',
        background: `radial-gradient(circle at 50% 32%, transparent 28%, ${hexToRGBA(tierColor, 0.05)} 40%, transparent 60%)`,
        animation: 'pulseSoft 4s ease-in-out infinite',
      }}/>
      <div style={{
        position: 'absolute', inset: 0, pointerEvents: 'none', opacity: 0.05,
        backgroundImage: 'repeating-linear-gradient(180deg, rgba(255,255,255,0.6) 0 1px, transparent 1px 3px)',
        maskImage: 'radial-gradient(circle at 50% 32%, black 0%, transparent 60%)',
        WebkitMaskImage: 'radial-gradient(circle at 50% 32%, black 0%, transparent 60%)',
      }}/>

      <div style={{ position: 'relative', display: 'flex', flexDirection: 'column', height: '100%' }}>
        <Header progress={100} onBack={onBack}/>
        <Sp h={28}/>
        <div style={{
          alignSelf: 'center',
          fontFamily: SYN_FONT, fontSize: 11, fontWeight: 600,
          color: SYN.cyan, letterSpacing: '0.18em',
          padding: '6px 14px', borderRadius: 999,
          border: '1px solid rgba(0,229,255,0.35)',
          background: 'rgba(0,229,255,0.06)',
          boxShadow: '0 0 16px rgba(0,229,255,0.25), inset 0 0 12px rgba(0,229,255,0.1)',
          opacity: appear ? 1 : 0,
          transform: appear ? 'translateY(0)' : 'translateY(8px)',
          transition: 'all 600ms cubic-bezier(.2,.7,.2,1)',
        }}>BASED ON YOUR ANSWERS</div>

        <Sp h={20}/>

        {/* Tier badge — color & icon vary by tier */}
        <div style={{
          alignSelf: 'center',
          position: 'relative', width: 220, height: 220,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>
          {/* Outer orbiting ring */}
          <div style={{
            position: 'absolute', inset: 0, borderRadius: '50%',
            border: `1px solid ${hexToRGBA(tierColor, 0.18)}`,
            animation: 'spin 22s linear infinite',
            opacity: appear ? 1 : 0,
            transition: 'opacity 800ms ease 200ms',
          }}>
            <div style={{
              position: 'absolute', top: -3, left: '50%', width: 6, height: 6, marginLeft: -3,
              borderRadius: '50%', background: tierColor,
              boxShadow: `0 0 12px ${hexToRGBA(tierColor, 0.9)}`,
            }}/>
          </div>
          {/* Mid ring */}
          <div style={{
            position: 'absolute', inset: 24, borderRadius: '50%',
            border: `1px dashed ${hexToRGBA(tierColor, 0.28)}`,
            animation: 'spin 14s linear infinite reverse',
            opacity: appear ? 1 : 0,
            transition: 'opacity 800ms ease 300ms',
          }}/>
          {/* Tick ring */}
          <svg viewBox="0 0 200 200" style={{
            position: 'absolute', inset: 44, width: 'calc(100% - 88px)', height: 'calc(100% - 88px)',
            animation: 'spin 30s linear infinite',
            opacity: appear ? 1 : 0,
            transition: 'opacity 800ms ease 400ms',
          }}>
            <circle cx="100" cy="100" r="98" fill="none" stroke={hexToRGBA(tierColor, 0.35)} strokeWidth="1"/>
            {Array.from({ length: 36 }).map((_, i) => (
              <line key={i} x1="100" y1="2" x2="100" y2={i % 3 === 0 ? 12 : 7}
                stroke={hexToRGBA(tierColor, 0.5)} strokeWidth="1"
                transform={`rotate(${i * 10} 100 100)`}/>
            ))}
          </svg>
          {/* Core badge — colored per tier */}
          <div style={{
            position: 'relative',
            width: 116, height: 116, borderRadius: '50%',
            background: tier.gradient
              ? `radial-gradient(circle at 35% 30%, #FFFFFF 0%, ${SYN.cyan} 35%, #7CE8F5 70%, rgba(0,150,180,0.6) 100%)`
              : isWhite
                ? `radial-gradient(circle at 35% 30%, rgba(255,255,255,1) 0%, rgba(230,232,238,0.95) 40%, rgba(180,184,196,0.8) 80%, rgba(120,124,135,0.6) 100%)`
                : `radial-gradient(circle at 35% 30%, rgba(255,255,255,0.95) 0%, ${tierColor} 28%, ${darken(tierColor, 0.45)} 60%, ${darken(tierColor, 0.7)} 100%)`,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            boxShadow: `0 0 60px ${hexToRGBA(tierColor, 0.7)}, 0 0 120px ${hexToRGBA(tierColor, 0.4)}, inset 0 0 30px rgba(255,255,255,0.3)`,
            animation: appear ? 'pulseCore 3s ease-in-out infinite' : 'none',
            transform: appear ? 'scale(1)' : 'scale(0.2)',
            opacity: appear ? 1 : 0,
            transition: 'transform 800ms cubic-bezier(.2,.8,.2,1), opacity 500ms ease',
          }}>
            <div style={{
              position: 'absolute', top: '18%', left: '22%', width: '32%', height: '24%',
              borderRadius: '50%', background: 'rgba(255,255,255,0.55)', filter: 'blur(6px)',
            }}/>
            <div style={{ position: 'relative' }}>
              <TierIcon kind={tierKey} color={tierColor}/>
            </div>
          </div>
        </div>

        <Sp h={32}/>
        <div style={{
          fontFamily: SYN_DISPLAY, fontWeight: 500, fontSize: 18,
          color: SYN.textDim, letterSpacing: '-0.015em', lineHeight: 1.2,
          textAlign: 'center',
          opacity: phase >= 1 ? 1 : 0,
          transform: phase >= 1 ? 'translateY(0)' : 'translateY(8px)',
          transition: 'all 700ms cubic-bezier(.2,.7,.2,1)',
        }}>Your starting tier is</div>
        <Sp h={6}/>
        <div style={{
          fontFamily: SYN_DISPLAY, fontWeight: 700, fontSize: 48,
          letterSpacing: '-0.04em', lineHeight: 1,
          textAlign: 'center',
          color: tier.gradient ? 'transparent' : tierColor,
          background: tier.gradient
            ? `linear-gradient(180deg, #FFFFFF 0%, ${SYN.cyan} 100%)`
            : 'transparent',
          WebkitBackgroundClip: tier.gradient ? 'text' : 'unset',
          backgroundClip: tier.gradient ? 'text' : 'unset',
          filter: `drop-shadow(0 0 16px ${hexToRGBA(tierColor, 0.55)})`,
          opacity: phase >= 1 ? 1 : 0,
          transform: phase >= 1 ? 'translateY(0)' : 'translateY(10px)',
          transition: 'all 700ms cubic-bezier(.2,.7,.2,1) 100ms',
        }}>{tier.name}</div>
        <Sp h={10}/>
        <div className="mono" style={{
          textAlign: 'center',
          fontFamily: SYN_MONO, fontWeight: 500, fontSize: 12,
          color: tier.gradient ? SYN.cyan : isWhite ? SYN.text : tierColor,
          letterSpacing: '0.18em',
          opacity: phase >= 1 ? 1 : 0,
          transition: 'opacity 700ms ease 250ms',
        }}>{tier.range} SCORE RANGE</div>

        <Sp h={28}/>
        <div style={{
          background: 'linear-gradient(180deg, #1A1A1E 0%, #131316 100%)',
          borderRadius: 16,
          border: `1px solid ${SYN.border}`,
          padding: 20,
          position: 'relative', overflow: 'hidden',
          boxShadow: 'inset 0 1px 0 rgba(255,255,255,0.04), 0 8px 24px rgba(0,0,0,0.3)',
          opacity: phase >= 1 ? 1 : 0,
          transform: phase >= 1 ? 'translateY(0)' : 'translateY(12px)',
          transition: 'all 700ms cubic-bezier(.2,.7,.2,1) 350ms',
        }}>
          <div style={{
            position: 'absolute', left: 0, top: 12, bottom: 12, width: 2,
            background: `linear-gradient(180deg, transparent 0%, ${tierColor} 50%, transparent 100%)`,
            boxShadow: `0 0 10px ${hexToRGBA(tierColor, 0.6)}`,
          }}/>
          <div style={{
            fontFamily: SYN_FONT, fontWeight: 400, fontSize: 14,
            lineHeight: 1.5, color: SYN.textDim, letterSpacing: '-0.005em',
          }}>
            <span style={{ color: isWhite ? SYN.text : tierColor, fontWeight: 600 }}>{tier.name}</span>{' '}
            — {tier.tagline}
            {nextKey !== tierKey && <>{' '}Climb to{' '}
            <span style={{
              fontWeight: 600,
              color: nextTier.color === '#FFFFFF' ? SYN.text : nextTier.color,
            }}>{nextTier.name}</span>{' '}next.</>}
          </div>
        </div>

        <Sp h={16}/>
        <div style={{
          textAlign: 'center',
          fontFamily: SYN_FONT, fontWeight: 400, fontSize: 12,
          color: SYN.textFaint, letterSpacing: '0.04em', textTransform: 'uppercase',
          opacity: phase >= 1 ? 1 : 0,
          transition: 'opacity 700ms ease 500ms',
        }}>Resets every Sunday at midnight</div>

        <Flex/>
        <BottomCTA><CTA onClick={onNext}>Let's go</CTA></BottomCTA>
      </div>
    </Shell>
  );
}

// hex helpers (used for tier colors)
function hexToRGBA(hex, alpha) {
  if (!hex || !hex.startsWith('#')) return hex;
  const h = hex.replace('#', '');
  const r = parseInt(h.substring(0, 2), 16);
  const g = parseInt(h.substring(2, 4), 16);
  const b = parseInt(h.substring(4, 6), 16);
  return `rgba(${r}, ${g}, ${b}, ${alpha})`;
}
function darken(hex, amount) {
  if (!hex || !hex.startsWith('#')) return hex;
  const h = hex.replace('#', '');
  const r = Math.max(0, Math.round(parseInt(h.substring(0, 2), 16) * (1 - amount)));
  const g = Math.max(0, Math.round(parseInt(h.substring(2, 4), 16) * (1 - amount)));
  const b = Math.max(0, Math.round(parseInt(h.substring(4, 6), 16) * (1 - amount)));
  return `rgb(${r}, ${g}, ${b})`;
}

// ───────────────────────────────────────────────────────────────────
// Final dashboard (after Screen 12)
// ───────────────────────────────────────────────────────────────────
function SHome({ data, onRestart }) {
  return (
    <Shell>
      <Sp h={32}/>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <div>
          <Label>MONDAY · APR 26</Label>
          <Sp h={4}/>
          <div style={{
            fontFamily: SYN_DISPLAY, fontWeight: 700, fontSize: 26,
            letterSpacing: '-0.03em', color: SYN.text,
          }}>Hey {(data.firstName || 'lifter').split(' ')[0].trim() || 'lifter'}.</div>
        </div>
      </div>
      <Sp h={24}/>
      <div style={{
        background: SYN.surface, border: `1px solid ${SYN.border}`,
        borderRadius: 16, padding: 20,
        display: 'flex', alignItems: 'center', gap: 16,
      }}>
        <div className="mono" style={{
          fontFamily: SYN_MONO, fontWeight: 700, fontSize: 36, color: SYN.text,
        }}>52</div>
        <div>
          <Label color={SYN.cyan}>READINESS</Label>
          <Sp h={4}/>
          <div style={{ fontFamily: SYN_FONT, color: SYN.textDim, fontSize: 14 }}>Get to 60 by Sunday to climb tiers.</div>
        </div>
      </div>
      <Flex/>
      <BottomCTA>
        <CTA onClick={onRestart}>Replay onboarding</CTA>
      </BottomCTA>
    </Shell>
  );
}

// ─── Icons ─────────────────────────────────────────────────────────
function ClockIcon() {
  return (
    <svg width="32" height="32" viewBox="0 0 32 32" fill="none"
      stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
      <circle cx="16" cy="16" r="11"/>
      <path d="M16 9 v7 l5 3"/>
    </svg>
  );
}
function TrendIcon() {
  return (
    <svg width="32" height="32" viewBox="0 0 32 32" fill="none"
      stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
      <path d="M5 23 L12 16 L17 20 L27 9"/>
      <path d="M21 9 L27 9 L27 15"/>
    </svg>
  );
}
function PeopleIcon() {
  return (
    <svg width="32" height="32" viewBox="0 0 32 32" fill="none"
      stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
      <circle cx="11" cy="11" r="3.4"/>
      <circle cx="21" cy="11" r="3.4"/>
      <path d="M5 24 c1-3.4 3.6-5.4 6-5.4 s5 2 6 5.4"/>
      <path d="M17 18.6 c1.4-1.5 3-2 4-2 c2.4 0 5 2 6 5.4"/>
    </svg>
  );
}

Object.assign(window, {
  S1Welcome, S2Value, S3Name, S4Age, S5Hook, S6Benefits,
  S7Goal, S8Frequency, S9Sleep, S10Diagnostic, S11Loading, S12Reveal,
  SHome,
});
