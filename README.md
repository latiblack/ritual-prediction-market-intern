# 🔮 Prediction Market Intelligence

**Browse, analyze, and deploy prediction markets — in your browser or on-chain.** One codebase. Two deployment targets.

---

## What It Does

Fetches live markets from Polymarket, analyzes them with AI, and lets you run the whole pipeline on-chain via Ritual Chain precompiles. The web app is the interface; the Solidity contracts are the on-chain engine.

## Quick Start

### Web App (browser-based)

```bash
npm install
npm run dev
```

Get a free NVIDIA API key at [build.nvidia.com](https://build.nvidia.com) → paste it in the app → analyze markets.

### On-Chain (Ritual Chain)

Deploy the contracts to Ritual Chain — anyone with testnet RITUAL from the [faucet](https://faucet.ritual.net) can run the same pipeline inside TEE-verified transactions.

**Prerequisites:** [Foundry](https://book.getfoundry.sh/getting-started/installation)

```bash
cd contracts
cp .env.example .env   # add your PRIVATE_KEY, HTTP_EXECUTOR, LLM_EXECUTOR

# Deploy
forge script script/Deploy.s.sol:DeployFetcher \
  --rpc-url $RITUAL_RPC_URL --broadcast -vvvv

# Fund the RitualWallet
cast send <ADDRESS> "deposit()" --value 0.1ether \
  --rpc-url $RITUAL_RPC_URL --private-key $PRIVATE_KEY

# Fetch markets on-chain
cast send <ADDRESS> "fetchMarkets(uint256)" 10 \
  --rpc-url $RITUAL_RPC_URL --private-key $PRIVATE_KEY

# Read the result
cast call <ADDRESS> "getLastResult()(uint16,string,bytes)" \
  --rpc-url $RITUAL_RPC_URL
```

### Deploy Web App to Vercel

[![Deploy with Vercel](https://vercel.com/button)](https://vercel.com/new/clone?repository-url=https://github.com/latiblack/ritual-prediction-market-intern)

No env vars needed — the Polymarket CORS proxy at `/api/proxy` works out of the box.

---

## Architecture

```
Frontend (browser)
├── Polymarket CLOB API  ──→  /api/proxy (Vercel)  ──→  Market List
└── NVIDIA NIM API       ──→  AI Analysis (browser-side, key in localStorage)

Contracts (on-chain)
├── MarketFetcher   →  HTTP precompile (0x0801) → fetches Polymarket data on-chain
└── MarketAnalyzer  →  HTTP + LLM precompiles   → fetches + analyzes on-chain
```

## How the Contracts Work

1. Your transaction calls the **HTTP precompile (0x0801)** with a Polymarket API URL
2. Ritual's block builder creates a commitment; a TEE executor performs the HTTP call off-chain
3. The result is settled back into your transaction via fulfilled replay
4. The same flow works for the **LLM precompile (0x0802)** — on-chain AI inference

## Ritual Chain Resources

| Resource | Link |
|----------|------|
| Faucet | https://faucet.ritual.net |
| RPC | `https://rpc.ritualfoundation.org` |
| Explorer | https://explorer.ritualfoundation.org |
| Chain ID | `1979` |

## API Keys

| Key | Where | Required for |
|-----|-------|-------------|
| NVIDIA NIM | [build.nvidia.com](https://build.nvidia.com) (free tier) | Web app analysis |
| RITUAL testnet | [Faucet](https://faucet.ritual.net) (free) | Contract deployment |
| PRIVATE_KEY | Your wallet | Contract deployment |

## License

MIT
