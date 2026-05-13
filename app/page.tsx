'use client';

import { useState, useEffect, useCallback } from 'react';

const POLY_API = '/api/proxy';
const NVIDIA_URL = 'https://integrate.api.nvidia.com/v1/chat/completions';

interface Market {
  conditionId: string;
  question: string;
  description: string;
  outcomePrices: string[];
  volume: string;
  market_slug: string;
  end_date_iso: string;
}

function getKey(): string {
  if (typeof window === 'undefined') return '';
  return localStorage.getItem('nvidia_key') || '';
}

function setKey(k: string) { localStorage.setItem('nvidia_key', k); }

export default function Home() {
  const [markets, setMarkets] = useState<Market[]>([]);
  const [loading, setLoading] = useState(true);
  const [selected, setSelected] = useState<Market | null>(null);
  const [analysis, setAnalysis] = useState<string>('');
  const [analyzing, setAnalyzing] = useState(false);
  const [apiKey, setApiKeyRaw] = useState('');
  const [showKeyInput, setShowKeyInput] = useState(!getKey());
  const [model, setModel] = useState('deepseek-ai/deepseek-v4-flash');
  const [error, setError] = useState('');

  const setApiKey = (k: string) => { setApiKeyRaw(k); setKey(k); };

  useEffect(() => {
    setApiKeyRaw(getKey());
    fetch(POLY_API + '?limit=100')
      .then(r => r.json())
      .then(d => { setMarkets(Array.isArray(d) ? d : d.data || []); setLoading(false); })
      .catch(() => setLoading(false));
  }, []);

  const doAnalyze = useCallback(async () => {
    if (!apiKey || !selected) return;
    setAnalyzing(true); setAnalysis(''); setError('');
    try {
      const marketData = {
        title: selected.question,
        probability: parseFloat(selected.outcomePrices?.[0] || '0') * 100,
        volume: selected.volume,
        source: 'Polymarket',
      };
      const res = await fetch(NVIDIA_URL, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${apiKey}` },
        body: JSON.stringify({
          model,
          messages: [
            { role: 'system', content: 'You are a prediction market analyst. Return JSON only.' },
            { role: 'user', content: `Analyze this prediction market. Return JSON: prediction_take, confidence_score (0-100), explanation, bias ("bullish"/"bearish"/"neutral"), narrative_summary\n\nMarket: ${JSON.stringify(marketData)}` },
          ],
          temperature: 0.7, max_tokens: 4096,
        }),
      });
      if (!res.ok) { const t = await res.text(); throw new Error(`API error: ${res.status} — ${t.slice(0, 200)}`); }
      const data = await res.json();
      setAnalysis(data.choices?.[0]?.message?.content || 'No analysis returned');
    } catch (e: any) { setError(e.message); }
    setAnalyzing(false);
  }, [apiKey, selected, model]);

  return (
    <div style={{ minHeight: '100vh', background: '#0D0D0D' }}>
      {/* Header */}
      <header style={{ borderBottom: '1px solid #2A2A2A', padding: '0 16px', height: 52, display: 'flex', alignItems: 'center', justifyContent: 'space-between', maxWidth: 1280, margin: '0 auto' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <span style={{ fontFamily: 'monospace', fontSize: 16, fontWeight: 700, color: '#00D4AA', letterSpacing: '-0.03em' }}>⌭ MKT_INTEL Lite</span>
          <span style={{ fontSize: 10, color: '#555', padding: '2px 4px', border: '1px solid #2A2A2A', fontFamily: 'monospace' }}>PUBLIC</span>
        </div>
        <button
          onClick={() => setShowKeyInput(!showKeyInput)}
          style={{ background: 'transparent', border: '1px solid #333', color: '#AAA', padding: '4px 12px', fontSize: 11, cursor: 'pointer', fontFamily: 'monospace' }}
        >
          {apiKey ? '🔑 KEY SET' : '⚙️ SET API KEY'}
        </button>
      </header>

      {/* API Key Panel */}
      {showKeyInput && <ApiKeySetup apiKey={apiKey} setApiKey={setApiKey} model={model} setModel={setModel} onClose={() => setShowKeyInput(false)} />}

      {/* Content */}
      <main style={{ maxWidth: 1280, margin: '0 auto', padding: 16, display: 'grid', gridTemplateColumns: selected ? '1fr 1fr' : '1fr', gap: 16 }}>
        {/* Market List */}
        <div>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 12 }}>
            <h2 style={{ fontSize: 13, fontWeight: 600, textTransform: 'uppercase', letterSpacing: '0.05em', color: '#828282', margin: 0, fontFamily: 'monospace' }}>
              Markets <span style={{ color: '#555', fontSize: 11 }}>({markets.length})</span>
            </h2>
            {loading && <span style={{ color: '#555', fontSize: 11, fontFamily: 'monospace' }}>loading...</span>}
          </div>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 1 }}>
            {markets.filter(m => !m.question?.startsWith('arch')).slice(0, 50).map((m) => (
              <div
                key={m.conditionId}
                onClick={() => setSelected(m)}
                style={{
                  padding: '10px 12px',
                  background: selected?.conditionId === m.conditionId ? '#1A1A1A' : '#141414',
                  border: selected?.conditionId === m.conditionId ? '1px solid #00D4AA' : '1px solid #2A2A2A',
                  cursor: 'pointer', transition: 'all 150ms',
                }}
                onMouseEnter={e => { if (selected?.conditionId !== m.conditionId) e.currentTarget.style.borderColor = '#444'; }}
                onMouseLeave={e => { if (selected?.conditionId !== m.conditionId) e.currentTarget.style.borderColor = '#2A2A2A'; }}
              >
                <div style={{ fontSize: 13, color: '#FFF', marginBottom: 4, display: '-webkit-box', WebkitLineClamp: 2, WebkitBoxOrient: 'vertical', overflow: 'hidden' }}>
                  {m.question}
                </div>
                <div style={{ display: 'flex', gap: 16, fontSize: 12 }}>
                  <span style={{ fontFamily: 'monospace', color: '#00D4AA', fontWeight: 600 }}>
                    {parseFloat(m.outcomePrices?.[0] || '0') * 100}%
                  </span>
                  <span style={{ color: '#555', fontFamily: 'monospace' }}>
                    ${(parseFloat(m.volume || '0') / 1000).toFixed(0)}K
                  </span>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Analysis Panel */}
        {selected && (
          <div>
            <div style={{ background: '#141414', border: '1px solid #2A2A2A', padding: 16 }}>
              <h3 style={{ fontSize: 14, fontWeight: 600, color: '#FFF', margin: '0 0 8px' }}>{selected.question}</h3>
              <div style={{ display: 'flex', gap: 16, marginBottom: 12, fontSize: 12, fontFamily: 'monospace' }}>
                <span>Prob: <span style={{ color: '#00D4AA', fontWeight: 600 }}>{(parseFloat(selected.outcomePrices?.[0] || '0') * 100).toFixed(1)}%</span></span>
                <span>Vol: <span style={{ color: '#AAA' }}>${(parseFloat(selected.volume || '0') / 1000).toFixed(0)}K</span></span>
              </div>

              {!apiKey ? (
                <div style={{ padding: 12, border: '1px solid #FFB80033', background: '#FFB80008', fontSize: 12, color: '#FFB800', textAlign: 'center' }}>
                  Set your NVIDIA API key above ⬆ to analyze markets
                </div>
              ) : (
                <button
                  onClick={doAnalyze}
                  disabled={analyzing}
                  style={{
                    width: '100%', padding: '8px 0',
                    background: analyzing ? '#1A1A1A' : '#00D4AA',
                    color: analyzing ? '#555' : '#0D0D0D',
                    border: 'none', cursor: analyzing ? 'default' : 'pointer',
                    fontWeight: 600, fontSize: 12, fontFamily: 'monospace',
                  }}
                >
                  {analyzing ? 'ANALYZING...' : '▶ ANALYZE THIS MARKET'}
                </button>
              )}

              {error && (
                <div style={{ marginTop: 12, padding: 12, border: '1px solid #FF475744', background: '#FF475708', fontSize: 12, color: '#FF4757', fontFamily: 'monospace' }}>
                  {error}
                </div>
              )}

              {analysis && !error && (
                <div style={{ marginTop: 12 }}>
                  <pre style={{ fontFamily: 'monospace', fontSize: 12, color: '#AAA', whiteSpace: 'pre-wrap', margin: 0, lineHeight: 1.5 }}>
                    {(() => {
                      try { return JSON.stringify(JSON.parse(analysis), null, 2); } catch { return analysis; }
                    })()}
                  </pre>
                </div>
              )}
            </div>


          </div>
        )}
      </main>
    </div>
  );
}

// ══════════════════════════════════════════════════════
// API Key Setup Panel
// ══════════════════════════════════════════════════════
function ApiKeySetup({ apiKey, setApiKey, model, setModel, onClose }: {
  apiKey: string; setApiKey: (k: string) => void; model: string; setModel: (m: string) => void; onClose: () => void;
}) {
  const models = [
    'deepseek-ai/deepseek-v4-flash',
    'deepseek-ai/deepseek-r1',
    'meta/llama-3.1-8b-instruct',
    'mistralai/mistral-7b-instruct-v0.3',
  ];

  return (
    <div style={{
      background: '#141414', borderBottom: '1px solid #2A2A2A',
      padding: '16px', maxWidth: 1280, margin: '0 auto',
    }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 12 }}>
        <h3 style={{ margin: 0, fontSize: 12, fontWeight: 600, color: '#00D4AA', fontFamily: 'monospace', textTransform: 'uppercase', letterSpacing: '0.05em' }}>
          🔑 NVIDIA Build API Setup
        </h3>
        <button onClick={onClose} style={{ background: 'none', border: 'none', color: '#555', cursor: 'pointer', fontSize: 14 }}>✕</button>
      </div>

      {/* Key input */}
      <div style={{ marginBottom: 12 }}>
        <label style={{ fontSize: 11, color: '#828282', display: 'block', marginBottom: 4, fontFamily: 'monospace' }}>NVIDIA API Key</label>
        <input
          type="password"
          value={apiKey}
          onChange={e => setApiKey(e.target.value)}
          placeholder="nvapi-..."
          style={{
            width: '100%', padding: '6px 10px', fontSize: 12,
            background: '#0D0D0D', border: '1px solid #2A2A2A', color: '#FFF',
            fontFamily: 'monospace', outline: 'none',
          }}
        />
      </div>

      {/* Model selector */}
      <div style={{ marginBottom: 16 }}>
        <label style={{ fontSize: 11, color: '#828282', display: 'block', marginBottom: 4, fontFamily: 'monospace' }}>Model</label>
        <select
          value={model}
          onChange={e => setModel(e.target.value)}
          style={{
            width: '100%', padding: '6px 10px', fontSize: 12,
            background: '#0D0D0D', border: '1px solid #2A2A2A', color: '#FFF',
            fontFamily: 'monospace', outline: 'none',
          }}
        >
          {models.map(m => <option key={m} value={m}>{m}</option>)}
        </select>
      </div>

      {/* Instructions */}
      <details>
        <summary style={{ fontSize: 11, color: '#828282', cursor: 'pointer', fontFamily: 'monospace' }}>
          How to get a free NVIDIA API key
        </summary>
        <div style={{ marginTop: 8, padding: 12, background: '#0D0D0D', border: '1px solid #2A2A2A', fontSize: 12, color: '#AAA', lineHeight: 1.6 }}>
          <ol style={{ margin: 0, paddingLeft: 20 }}>
            <li>Go to <a href="https://build.nvidia.com" target="_blank" rel="noopener noreferrer" style={{ color: '#00D4AA' }}>build.nvidia.com</a></li>
            <li>Click <strong>Login</strong> → sign up for free</li>
            <li>Once logged in, click your avatar → <strong>Personal API Keys</strong></li>
            <li>Click <strong>Generate API Key</strong> → copy the key</li>
            <li>Paste it above (stored in your browser, never sent anywhere else)</li>
          </ol>
          <p style={{ margin: '8px 0 0', color: '#828282' }}>
            💡 NVIDIA gives <strong>free credits</strong> to new accounts — enough for hundreds of analyses.
            The key never leaves your browser; it's stored in localStorage.
          </p>
        </div>
      </details>
    </div>
  );
}
