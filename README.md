# ⌭ MKT_INTEL Lite

**Zero-backend prediction market intelligence.** Browse Polymarket markets and analyze them with AI — no backend, no database, no cron jobs.

Built for **Ritual Chain** deployment. Currently runs off-chain with NVIDIA NIM API for AI analysis.

## Features

- Browse live Polymarket markets (via proxy)
- Analyze any market with DeepSeek v4 Flash (via NVIDIA NIM API)
- Switch between models (DeepSeek R1, Llama 3.1, Mistral)
- No account required — just a free NVIDIA API key
- Keys stored locally in your browser (localStorage)

## Get a Free API Key

1. Go to [build.nvidia.com](https://build.nvidia.com)
2. Sign up for a free account
3. Click your avatar → **Personal API Keys** → **Generate API Key**
4. Paste the key into the app

NVIDIA gives **free credits** to new accounts — enough for hundreds of analyses.

## Deploy

[![Deploy with Vercel](https://vercel.com/button)](https://vercel.com/new/clone?repository-url=https://github.com/latiblack/prediction-market-lite)

One click deploy. No backend to configure. No database to set up.

## Tech Stack

- **Next.js 16** (App Router)
- **Polymarket CLOB API** (proxied through a single serverless function)
- **NVIDIA NIM API** (called directly from browser)
- **Tailwind CSS v4**

## Ritual Chain Roadmap

This is the open-source frontend. On-chain deployment will use:

| Component | Current | Ritual Chain |
|-----------|---------|-------------|
| Data fetching | Serverless proxy | HTTP precompile (0x0801) |
| AI analysis | NVIDIA API (browser) | LLM precompile (0x0802) |
| Scheduling | Manual trigger | Scheduler sys contract (0x56e7) |
| Alerts | — | On-chain condition alerts via Scheduler + HTTP precompile |

## License

MIT
