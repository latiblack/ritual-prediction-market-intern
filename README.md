# 🔮 ritual-prediction-market-intern

**Prediction market intelligence, built for Ritual Chain.** Browse Polymarket markets and analyze them with AI. Zero backend — runs entirely in your browser.

## What it does

- Fetches live markets from Polymarket API
- Analyzes market sentiment, narratives, and edge with LLMs (NVIDIA NIM)
- Deployable to Ritual Chain for on-chain inference

## Tech Stack

- **Frontend:** Next.js 16 + Tailwind v4
- **Data:** Polymarket CLOB API (via thin Vercel proxy)
- **AI:** NVIDIA NIM API (direct from browser)
- **On-chain target:** Ritual Chain (via Sovereign Agent + LLM precompiles)

## Running Locally

```bash
npm install
npm run dev
```

## Deploy on Vercel

[![Deploy with Vercel](https://vercel.com/button)](https://vercel.com/new/clone?repository-url=https://github.com/latiblack/ritual-prediction-market-intern)

---

Built for [Ritual Chain](https://ritual.net) — the AI-native L1.
