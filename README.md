# 🔮 ritual-prediction-market-intern

**Browse Polymarket prediction markets and analyze them with LLMs — zero backend required.** Built as a stepping stone to deploying on [Ritual Chain](https://ritual.net), the AI-native L1.

Your browser talks directly to NVIDIA's LLM API. The only serverless function is a thin proxy to bypass Polymarket's CORS restrictions. No database, no auth, no backend to maintain.

---

## ✨ Features

- Live market list from Polymarket (CLOB API)
- AI-powered analysis with configurable models (DeepSeek V4 Flash, Llama 3.1, Mistral, R1)
- GPU-accelerated inference via NVIDIA NIM
- Zero backend — API key stays in your browser's `localStorage`
- Built-in instructions panel for getting your free NVIDIA API key
- Roadmap panel showing the Ritual Chain deployment path

## 🧱 Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | Next.js 16 (App Router) + Tailwind CSS v4 |
| Market data | Polymarket CLOB API (via Vercel function proxy) |
| AI inference | NVIDIA NIM API (directly from browser) |
| On-chain target | Ritual Chain — LLM precompile, Sovereign Agent |

## 🚀 Quick Start

### 1. Clone & install

```bash
git clone https://github.com/latiblack/ritual-prediction-market-intern.git
cd ritual-prediction-market-intern
npm install
```

### 2. Get an NVIDIA API key

1. Go to **[build.nvidia.com](https://build.nvidia.com/explore/llama)**
2. Sign up or log in
3. Click **Get API Key** — a free tier key is available immediately
4. Copy the key (starts with `nvapi-`)

### 3. Polymarket API proxy setup (required)

Polymarket's API blocks browser CORS, so you need a tiny Vercel proxy:

**Option A — Use the `/api/proxy` route (already set up):**

The repo includes `app/api/proxy/route.ts` — a thin proxy that forwards to `clob.polymarket.com`. Works on Vercel and in local dev.

**Option B — Test locally (bypass CORS in dev):**

Just run `npm run dev` — the proxy works locally too via Next.js route handlers. No extra config needed.

### 4. Run

```bash
npm run dev
```

Open `http://localhost:3000`, paste your NVIDIA key in the settings panel, and start analyzing markets.

## 🌐 Deploy to Vercel

The easiest way to get everything working (including the Polymarket CORS proxy):

[![Deploy with Vercel](https://vercel.com/button)](https://vercel.com/new/clone?repository-url=https://github.com/latiblack/ritual-prediction-market-intern)

Or CLI:
```bash
npm i -g vercel
vercel deploy
```

No environment variables needed — the app is self-contained.

## ⛓️ Ritual Chain Roadmap

This app is designed to evolve into a fully on-chain prediction market agent on Ritual Chain:

1. **Current:** Browser-based analysis using NVIDIA NIM (direct API calls)
2. **Next:** Migrate AI inference on-chain using Ritual's **LLM precompile**
3. **Future:** Deploy a **Sovereign Agent** that autonomously monitors markets and submits predictions

Ritual Chain features this app will use:
- **LLM precompile** — on-chain inference for market analysis
- **Sovereign Agent** — persistent autonomous agent lifecycle
- **HTTP precompile** — fetch real-time market data from Polymarket
- **Scheduler precompile** — periodic re-evaluation of positions

## 🔑 API Keys

| Key | Where to get it | Required? |
|-----|----------------|-----------|
| NVIDIA NIM | [build.nvidia.com](https://build.nvidia.com/explore/llama) (free tier) | Yes, for analysis |
| Polymarket | None needed — data is public via CLOB API | No |
| Ritual Chain | None yet — testnet is free | For on-chain deployment |

## 📁 Project Structure

```
app/
├── api/proxy/route.ts        # Polymarket CORS proxy (Vercel route handler)
├── layout.tsx                # Root layout
├── page.tsx                  # Main app page
└── globals.css               # Tailwind imports
```

## 📄 License

MIT
