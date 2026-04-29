// Synced — 12-screen onboarding app

const { useState, useCallback, useEffect } = React;

const TWEAK_DEFAULTS = /*EDITMODE-BEGIN*/{
  "startScreen": 1,
  "deviceTime": "9:41",
  "ambientGlow": true,
  "previewTier": "active"
}/*EDITMODE-END*/;

function App() {
  const [tweaks, setTweak] = useTweaks(TWEAK_DEFAULTS);

  const [step, setStep] = useState(Math.max(1, Math.min(13, +tweaks.startScreen || 1)));
  const [data, setData] = useState({
    firstName: '',
    age: '20',
    goal: null,
    daysPerWeek: 4,
    sleepHours: 7.5,
    diagnostic: null,
  });

  const next = useCallback(() => setStep(s => Math.min(13, s + 1)), []);
  const back = useCallback(() => setStep(s => Math.max(1, s - 1)), []);
  const restart = useCallback(() => {
    setStep(1);
    setData({ firstName: '', age: '20', goal: null, daysPerWeek: 4, sleepHours: 7.5, diagnostic: null });
  }, []);

  const screen = (() => {
    switch (step) {
      case 1:  return <S1Welcome onNext={next} onSignIn={() => {}}/>;
      case 2:  return <S2Value onBack={back} onNext={next}/>;
      case 3:  return <S3Name data={data} setData={setData} onBack={back} onNext={next}/>;
      case 4:  return <S4Age data={data} setData={setData} onBack={back} onNext={next}/>;
      case 5:  return <S5Hook onBack={back} onNext={next}/>;
      case 6:  return <S6Benefits onBack={back} onNext={next}/>;
      case 7:  return <S7Goal data={data} setData={setData} onBack={back} onNext={next}/>;
      case 8:  return <S8Frequency data={data} setData={setData} onBack={back} onNext={next}/>;
      case 9:  return <S9Sleep data={data} setData={setData} onBack={back} onNext={next}/>;
      case 10: return <S10Diagnostic data={data} setData={setData} onBack={back} onNext={next}/>;
      case 11: return <S11Loading onBack={back} onNext={next}/>;
      case 12: return <S12Reveal data={{ ...data, startTier: tweaks.previewTier }} onBack={back} onNext={next}/>;
      case 13: return <SHome data={data} onRestart={restart}/>;
      default: return null;
    }
  })();

  const useKeyboard = step === 3; // keyboard only on first-name input

  return (
    <div style={{ position: 'relative' }} data-screen-label={`${String(step).padStart(2,'0')} ${step === 13 ? 'Home' : 'Onboarding'}`}>
      <IOSDevice width={393} height={852} dark={true} time={tweaks.deviceTime} keyboard={useKeyboard}>
        <div style={{
          position: 'relative', height: '100%',
          display: 'flex', flexDirection: 'column',
          background: SYN.bg, overflow: 'hidden',
        }}>
          <div key={step} style={{ flex: 1, position: 'relative', minHeight: 0 }}>
            {screen}
          </div>
        </div>
      </IOSDevice>

      <TweaksPanel title="Tweaks">
        <TweakSection title="Flow">
          <TweakSelect
            label="Jump to screen"
            value={String(step)}
            onChange={(v) => setStep(+v)}
            options={[
              { label: '1 — Welcome', value: '1' },
              { label: '2 — Value', value: '2' },
              { label: '3 — Name', value: '3' },
              { label: '4 — Age', value: '4' },
              { label: '5 — Hook', value: '5' },
              { label: '6 — Benefits', value: '6' },
              { label: '7 — Goal', value: '7' },
              { label: '8 — Frequency', value: '8' },
              { label: '9 — Sleep', value: '9' },
              { label: '10 — Diagnostic', value: '10' },
              { label: '11 — Loading', value: '11' },
              { label: '12 — Tier reveal', value: '12' },
              { label: '13 — Home', value: '13' },
            ]}
          />
          <TweakButton onClick={restart}>↺ Reset answers</TweakButton>
        </TweakSection>
        <TweakSection title="Tier reveal (Screen 12)">
          <TweakSelect
            label="Preview tier"
            value={tweaks.previewTier || 'active'}
            onChange={(v) => setTweak('previewTier', v)}
            options={[
              { label: 'Cooked (gray)',     value: 'cooked' },
              { label: 'Active (white)',    value: 'active' },
              { label: 'Dialed (green)',    value: 'dialed' },
              { label: 'Locked In (cyan)',  value: 'lockedIn' },
              { label: 'Synced (gradient)', value: 'synced' },
            ]}
          />
        </TweakSection>
        <TweakSection title="Device">
          <TweakText label="Status bar time"
            value={tweaks.deviceTime}
            onChange={(v) => setTweak('deviceTime', v)}/>
        </TweakSection>
      </TweaksPanel>
    </div>
  );
}

ReactDOM.createRoot(document.getElementById('root')).render(<App/>);
