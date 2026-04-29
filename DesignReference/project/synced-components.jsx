// Synced — shared design-system primitives

const SYN = {
  bg: '#0A0A0A',
  surface: '#161618',
  surfaceHi: '#1F1F23',
  border: '#2A2A2E',
  borderHi: '#2A2A2E',
  text: '#FFFFFF',
  textDim: '#8E8E93',
  textFaint: '#5A5A60',
  cyan: '#00E5FF',
  cyanGlow: 'rgba(0,229,255,0.20)',
  cyanSoft: 'rgba(0,229,255,0.10)',
  red: '#FF453A',
  amber: '#FFB020',
  green: '#30D158',
};

// Inter font alternate via system; SF Pro stack
const SYN_FONT = '-apple-system, "SF Pro Text", "SF Pro", system-ui, sans-serif';
const SYN_DISPLAY = '-apple-system, "SF Pro Display", "SF Pro", system-ui, sans-serif';
const SYN_MONO = '"SF Mono", ui-monospace, Menlo, monospace';

// ─── Wordmark ──────────────────────────────────────────────────────
function SyncedMark({ size = 36, glow = true }) {
  return (
    <div style={{
      display: 'inline-flex', alignItems: 'center', gap: size * 0.32,
    }}>
      {/* Custom 'pulse' icon — concentric arcs suggesting sync rings */}
      <svg width={size * 1.05} height={size * 1.05} viewBox="0 0 40 40" style={{
        filter: glow ? 'drop-shadow(0 0 14px rgba(0,229,255,.55))' : 'none',
      }}>
        <circle cx="20" cy="20" r="3.2" fill={SYN.cyan} />
        <path d="M20 8 a12 12 0 0 1 12 12" stroke={SYN.cyan} strokeWidth="2.4" strokeLinecap="round" fill="none" opacity="0.95"/>
        <path d="M20 32 a12 12 0 0 1 -12 -12" stroke={SYN.cyan} strokeWidth="2.4" strokeLinecap="round" fill="none" opacity="0.95"/>
        <path d="M14 4.6 a16 16 0 0 1 21.4 9" stroke={SYN.cyan} strokeWidth="1.6" strokeLinecap="round" fill="none" opacity="0.45"/>
        <path d="M26 35.4 a16 16 0 0 1 -21.4 -9" stroke={SYN.cyan} strokeWidth="1.6" strokeLinecap="round" fill="none" opacity="0.45"/>
      </svg>
      <span style={{
        fontFamily: SYN_DISPLAY,
        fontWeight: 700,
        fontSize: size,
        letterSpacing: '-0.04em',
        color: '#fff',
      }}>synced<span style={{ color: SYN.cyan }}>.</span></span>
    </div>
  );
}

// ─── Buttons ───────────────────────────────────────────────────────
function PrimaryButton({ children, onClick, disabled, style, glow = true }) {
  return (
    <button
      onClick={disabled ? undefined : onClick}
      disabled={disabled}
      style={{
        width: '100%',
        height: 56,
        borderRadius: 14,
        border: 'none',
        background: disabled ? 'rgba(0,229,255,0.18)' : SYN.cyan,
        color: disabled ? 'rgba(10,10,10,0.45)' : '#0A0A0A',
        fontFamily: SYN_FONT,
        fontWeight: 600,
        fontSize: 16,
        letterSpacing: '-0.01em',
        cursor: disabled ? 'not-allowed' : 'pointer',
        boxShadow: disabled || !glow ? 'none' : '0 0 0 1px rgba(0,229,255,0.4), 0 8px 32px rgba(0,229,255,0.35)',
        transition: 'transform 120ms ease, box-shadow 200ms ease, background 200ms ease',
        ...style,
      }}
      onMouseDown={e => !disabled && (e.currentTarget.style.transform = 'scale(0.985)')}
      onMouseUp={e => !disabled && (e.currentTarget.style.transform = 'scale(1)')}
      onMouseLeave={e => !disabled && (e.currentTarget.style.transform = 'scale(1)')}
    >
      {children}
    </button>
  );
}

function SecondaryButton({ children, onClick, style }) {
  return (
    <button
      onClick={onClick}
      style={{
        width: '100%',
        height: 56,
        borderRadius: 14,
        border: `1px solid ${SYN.border}`,
        background: 'transparent',
        color: SYN.text,
        fontFamily: SYN_FONT,
        fontWeight: 500,
        fontSize: 16,
        letterSpacing: '-0.01em',
        cursor: 'pointer',
        transition: 'background 160ms ease, border-color 160ms ease',
        ...style,
      }}
      onMouseEnter={e => (e.currentTarget.style.background = 'rgba(255,255,255,0.04)')}
      onMouseLeave={e => (e.currentTarget.style.background = 'transparent')}
    >
      {children}
    </button>
  );
}

function TextLink({ children, onClick, style }) {
  return (
    <button
      onClick={onClick}
      style={{
        background: 'none', border: 'none',
        color: SYN.textDim,
        fontFamily: SYN_FONT,
        fontWeight: 500, fontSize: 15,
        letterSpacing: '-0.01em',
        cursor: 'pointer',
        padding: '12px 16px',
        ...style,
      }}
    >
      {children}
    </button>
  );
}

// ─── Text Input ────────────────────────────────────────────────────
function TextInput({ label, value, onChange, placeholder, type = 'text', autoFocus, inputMode, maxLength }) {
  const [focused, setFocused] = React.useState(false);
  return (
    <label style={{ display: 'block', width: '100%' }}>
      <div style={{
        fontFamily: SYN_FONT,
        fontSize: 12,
        fontWeight: 600,
        letterSpacing: '0.08em',
        textTransform: 'uppercase',
        color: focused ? SYN.cyan : SYN.textFaint,
        marginBottom: 8,
        transition: 'color 200ms ease',
      }}>{label}</div>
      <div style={{
        position: 'relative',
        height: 56,
        borderRadius: 14,
        background: SYN.surface,
        border: `1px solid ${focused ? SYN.cyan : SYN.border}`,
        boxShadow: focused ? `0 0 0 4px ${SYN.cyanSoft}` : 'none',
        transition: 'border-color 200ms ease, box-shadow 200ms ease',
      }}>
        <input
          type={type}
          value={value}
          onChange={e => onChange(e.target.value)}
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
            fontSize: 17,
            fontWeight: 500,
            color: SYN.text,
            letterSpacing: '-0.01em',
            boxSizing: 'border-box',
          }}
        />
      </div>
    </label>
  );
}

// ─── Selectable card ───────────────────────────────────────────────
function SelectCard({ icon, title, sub, selected, onClick }) {
  return (
    <button
      onClick={onClick}
      style={{
        width: '100%',
        textAlign: 'left',
        background: selected ? 'rgba(0,229,255,0.06)' : SYN.surface,
        border: `1.5px solid ${selected ? SYN.cyan : SYN.border}`,
        borderRadius: 18,
        padding: '18px 20px',
        cursor: 'pointer',
        display: 'flex', alignItems: 'center', gap: 16,
        boxShadow: selected ? `0 0 0 4px ${SYN.cyanSoft}, 0 0 24px rgba(0,229,255,0.18)` : 'none',
        transition: 'all 200ms cubic-bezier(.2,.7,.2,1)',
        fontFamily: SYN_FONT,
        color: SYN.text,
      }}
    >
      <div style={{
        width: 44, height: 44, borderRadius: 12,
        background: selected ? 'rgba(0,229,255,0.12)' : 'rgba(255,255,255,0.04)',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        flexShrink: 0,
        transition: 'background 200ms ease',
      }}>
        {icon}
      </div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{
          fontWeight: 600, fontSize: 17, letterSpacing: '-0.01em',
          color: SYN.text,
        }}>{title}</div>
        <div style={{
          fontWeight: 400, fontSize: 13,
          color: SYN.textDim, marginTop: 2,
        }}>{sub}</div>
      </div>
      <div style={{
        width: 22, height: 22, borderRadius: '50%',
        border: `1.5px solid ${selected ? SYN.cyan : 'rgba(255,255,255,0.18)'}`,
        background: selected ? SYN.cyan : 'transparent',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        flexShrink: 0,
        transition: 'all 180ms ease',
      }}>
        {selected && (
          <svg width="12" height="12" viewBox="0 0 12 12">
            <path d="M2.5 6.2 L5 8.6 L9.5 3.6" stroke="#0a0a0a" strokeWidth="2" fill="none" strokeLinecap="round" strokeLinejoin="round"/>
          </svg>
        )}
      </div>
    </button>
  );
}

// ─── Slider (custom, large hit-target) ─────────────────────────────
function SyncedSlider({ value, min, max, step = 1, onChange }) {
  const trackRef = React.useRef(null);
  const [dragging, setDragging] = React.useState(false);

  const pct = ((value - min) / (max - min)) * 100;

  const setFromX = React.useCallback((clientX) => {
    const el = trackRef.current; if (!el) return;
    const r = el.getBoundingClientRect();
    const ratio = Math.min(1, Math.max(0, (clientX - r.left) / r.width));
    const raw = min + ratio * (max - min);
    const snapped = Math.round(raw / step) * step;
    onChange(Math.min(max, Math.max(min, +snapped.toFixed(3))));
  }, [min, max, step, onChange]);

  React.useEffect(() => {
    if (!dragging) return;
    const move = (e) => {
      const x = e.touches ? e.touches[0].clientX : e.clientX;
      setFromX(x);
    };
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

  // Tick marks
  const ticks = [];
  const tickCount = Math.round((max - min) / step);
  if (tickCount <= 14) {
    for (let i = 0; i <= tickCount; i++) {
      const t = (i / tickCount) * 100;
      ticks.push(t);
    }
  }

  return (
    <div
      ref={trackRef}
      onMouseDown={(e) => { setDragging(true); setFromX(e.clientX); }}
      onTouchStart={(e) => { setDragging(true); setFromX(e.touches[0].clientX); }}
      style={{
        position: 'relative',
        height: 56,
        display: 'flex', alignItems: 'center',
        cursor: 'pointer',
        touchAction: 'none',
      }}
    >
      {/* Track */}
      <div style={{
        position: 'absolute', left: 0, right: 0, height: 6,
        background: 'rgba(255,255,255,0.07)',
        borderRadius: 999,
      }}>
        {/* Fill */}
        <div style={{
          position: 'absolute', left: 0, top: 0, bottom: 0,
          width: `${pct}%`,
          background: `linear-gradient(90deg, rgba(0,229,255,0.7), ${SYN.cyan})`,
          borderRadius: 999,
          boxShadow: `0 0 12px ${SYN.cyanGlow}`,
          transition: dragging ? 'none' : 'width 160ms ease',
        }} />
      </div>
      {/* Ticks */}
      {ticks.map((t, i) => (
        <div key={i} style={{
          position: 'absolute', left: `${t}%`,
          width: 2, height: 2, borderRadius: 999,
          background: t <= pct ? 'rgba(10,10,10,0.7)' : 'rgba(255,255,255,0.18)',
          transform: 'translateX(-1px)',
        }} />
      ))}
      {/* Thumb */}
      <div style={{
        position: 'absolute', left: `${pct}%`,
        width: 32, height: 32, borderRadius: '50%',
        background: SYN.cyan,
        border: '4px solid #0a0a0a',
        boxShadow: `0 0 0 1px rgba(0,229,255,0.7), 0 0 24px ${SYN.cyanGlow}`,
        transform: `translateX(-16px) ${dragging ? 'scale(1.15)' : 'scale(1)'}`,
        transition: dragging ? 'transform 80ms ease' : 'transform 160ms ease, left 160ms ease',
        cursor: dragging ? 'grabbing' : 'grab',
      }} />
    </div>
  );
}

// ─── Progress dots ─────────────────────────────────────────────────
// Spec: 7 dots, 6pt each, 8pt spacing, cyan for completed/current,
// #2A2A2E for upcoming.
function ProgressDots({ count, current }) {
  return (
    <div style={{
      display: 'flex', gap: 8, justifyContent: 'center',
    }}>
      {Array.from({ length: count }).map((_, i) => {
        const filled = i <= current;
        return (
          <div key={i} style={{
            width: 6, height: 6,
            borderRadius: '50%',
            background: filled ? SYN.cyan : SYN.border,
            boxShadow: filled && i === current ? `0 0 8px ${SYN.cyanGlow}` : 'none',
            transition: 'background 320ms ease',
          }} />
        );
      })}
    </div>
  );
}

// ─── Tier badge & avatar ───────────────────────────────────────────
const TIER_COLORS = {
  synced:  { ring: SYN.cyan, label: 'SYNCED' },
  apex:    { ring: '#A78BFA', label: 'APEX' },
  ascent:  { ring: '#F59E0B', label: 'ASCENT' },
  base:    { ring: 'rgba(255,255,255,0.4)', label: 'BASE' },
};

function Avatar({ initials, tier = 'base', size = 56 }) {
  const t = TIER_COLORS[tier] || TIER_COLORS.base;
  return (
    <div style={{ position: 'relative', width: size, height: size }}>
      <div style={{
        position: 'absolute', inset: -3,
        borderRadius: '50%',
        border: `2px solid ${t.ring}`,
        boxShadow: tier === 'synced' ? `0 0 14px ${SYN.cyanGlow}` : 'none',
      }} />
      <div style={{
        width: size, height: size, borderRadius: '50%',
        background: 'linear-gradient(135deg, #1f1f1f, #0e0e0e)',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        fontFamily: SYN_DISPLAY, fontWeight: 600, fontSize: size * 0.36,
        color: SYN.text, letterSpacing: '-0.02em',
      }}>{initials}</div>
      <div style={{
        position: 'absolute', bottom: -8, left: '50%', transform: 'translateX(-50%)',
        background: SYN.bg,
        border: `1px solid ${t.ring}`,
        borderRadius: 6,
        padding: '2px 6px',
        fontFamily: SYN_MONO,
        fontSize: 9,
        fontWeight: 600,
        letterSpacing: '0.08em',
        color: t.ring,
        whiteSpace: 'nowrap',
      }}>{t.label}</div>
    </div>
  );
}

// ─── Icon set (line, 24px) ─────────────────────────────────────────
const Icon = {
  Muscle: ({ c = SYN.cyan }) => (
    <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="1.7" strokeLinecap="round" strokeLinejoin="round">
      <path d="M3 12h2M19 12h2M7 9v6M17 9v6M7 12h10"/>
      <rect x="5" y="9" width="2" height="6" rx="1"/>
      <rect x="17" y="9" width="2" height="6" rx="1"/>
    </svg>
  ),
  Strong: ({ c = SYN.cyan }) => (
    <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="1.7" strokeLinecap="round" strokeLinejoin="round">
      <path d="M13 2 L4 14 h6 l-1 8 L20 10 h-6 l1-8 Z"/>
    </svg>
  ),
  Cut: ({ c = SYN.cyan }) => (
    <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="1.7" strokeLinecap="round" strokeLinejoin="round">
      <path d="M12 3 v18 M5 8 l7 -5 l7 5 M8 14 l4 -3 l4 3"/>
    </svg>
  ),
  Consistent: ({ c = SYN.cyan }) => (
    <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="1.7" strokeLinecap="round" strokeLinejoin="round">
      <circle cx="12" cy="12" r="9"/>
      <path d="M12 7 v5 l3 2"/>
    </svg>
  ),
  Bell: ({ c = SYN.cyan, size = 28 }) => (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round">
      <path d="M6 8a6 6 0 0 1 12 0c0 7 3 8 3 8H3s3-1 3-8"/>
      <path d="M10 20a2 2 0 0 0 4 0"/>
    </svg>
  ),
  Users: ({ c = SYN.cyan, size = 28 }) => (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round">
      <circle cx="9" cy="8" r="3.2"/>
      <path d="M3 20c.7-3.4 3.2-5 6-5s5.3 1.6 6 5"/>
      <circle cx="17" cy="9" r="2.6"/>
      <path d="M15 14c2.5 0 5 1.4 5.6 4.5"/>
    </svg>
  ),
  Check: ({ c = '#0a0a0a', size = 16 }) => (
    <svg width={size} height={size} viewBox="0 0 16 16">
      <path d="M3 8.2 L6.5 11.5 L13 4.8" stroke={c} strokeWidth="2.2" fill="none" strokeLinecap="round" strokeLinejoin="round"/>
    </svg>
  ),
  ArrowLeft: ({ c = '#fff', size = 22 }) => (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M15 6 l-6 6 l6 6"/>
    </svg>
  ),
};

// Export to window
Object.assign(window, {
  SYN, SYN_FONT, SYN_DISPLAY, SYN_MONO,
  SyncedMark, PrimaryButton, SecondaryButton, TextLink,
  TextInput, SelectCard, SyncedSlider, ProgressDots,
  Avatar, Icon, TIER_COLORS,
});
