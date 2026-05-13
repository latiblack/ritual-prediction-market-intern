# 🔮 Prediction Market Intelligence

**Browse Polymarket prediction markets and analyze them with AI — zero backend required.** Your browser talks directly to NVIDIA's LLM API. Also includes deployable Solidity contracts for [Ritual Chain](https://ritual.net).

---

## 🧱 Project Structure

```
├── app/              # Next.js frontend (standalone)
├── contracts/        # Solidity contracts for Ritual Chain
└── README.md
```

---

# 🖥️ Frontend — Polymarket Analyzer

A zero-backend prediction market analyzer. No database, no auth, nothing to maintain.

### Features

- Live market feed from Polymarket CLOB API
- AI analysis via NVIDIA NIM (DeepSeek V4 Flash, Llama 3.1, Mistral, R1)
- API key stays in your browser's `localStorage`
- Built-in instructions to get a free NVIDIA API key

### Quick Start

```bash
npm install
npm run dev
```

Open `http://localhost:3000`, paste your NVIDIA key, analyze markets.

### Deploy to Vercel

[![Deploy with Vercel](https://vercel.com/button)](https://vercel.com/new/clone?repository-url=https://github.com/latiblack/ritual-prediction-market-intern)

No env vars needed. The Polymarket CORS proxy at `/api/proxy` works out of the box.

---

# ⛓️ Contracts — Ritual Chain

Deploy on-chain prediction market contracts to **Ritual Chain** (Chain ID: 1979). Uses Ritual's **HTTP precompile (0x0801)** to fetch live Polymarket data and **LLM precompile (0x0802)** for on-chain analysis — all inside TEE-verified transactions.

Anyone with testnet RITUAL from the [Ritual faucet](https://faucet.ritual.net) can deploy and use these contracts.

### Contracts

| Contract | Description |
|----------|-------------|
| `MarketFetcher` | Calls HTTP precompile to fetch Polymarket markets on-chain |
| `MarketAnalyzer` | Fetches market data + analyzes it via LLM precompile |

### Prerequisites

```bash
# Install Foundry (if not already installed)
curl -L https://foundry.paradigm.xyz | bash && foundryup
```

### Deploy

```bash
cd contracts

# 1. Copy and fill in env vars
cp .env.example .env
# Edit .env: PRIVATE_KEY, RPC_URL, HTTP_EXECUTOR, LLM_EXECUTOR

# 2. Find executors from TEEServiceRegistry
cast call 0x9644e8562cE0Fe12b4deeC4163c064A8862Bf47F \
  "getServicesByCapability(uint8,bool)((address,address,uint8,bytes,bytes,bytes32,uint8),bool,bytes32[])" \
  0 true --rpc-url $RITUAL_RPC_URL

# 3. Deploy MarketFetcher
forge script script/Deploy.s.sol:DeployFetcher \
  --rpc-url $RITUAL_RPC_URL \
  --broadcast -vvvv

# 4. Deposit RITUAL into RitualWallet
cast send <DEPLOYED_ADDRESS> "deposit()" \
  --value 0.1ether \
  --rpc-url $RITUAL_RPC_URL \
  --private-key $PRIVATE_KEY

# 5. Fetch Polymarket markets on-chain
cast send <DEPLOYED_ADDRESS> "fetchMarkets(uint256)" 10 \
  --rpc-url $RITUAL_RPC_URL \
  --private-key $PRIVATE_KEY

# 6. Read the result
cast call <DEPLOYED_ADDRESS> "getLastResult()(uint16,string,bytes)" \
  --rpc-url $RITUAL_RPC_URL
```

### How It Works

1. Your contract calls the **HTTP precompile (0x0801)** with a URL to the Polymarket CLOB API
2. Ritual's block builder creates a commitment and a TEE executor performs the HTTP call off-chain
3. The result is settled back on-chain in the same transaction via fulfilled replay
4. You read the result from the contract's state

The same flow applies for LLM analysis — your contract calls the **LLM precompile (0x0802)** with a prompt, and a TEE executor runs inference then settles the result.

### Ritual Chain Resources

| Resource | Link |
|----------|------|
| Faucet | https://faucet.ritual.net |
| RPC | `https://rpc.ritualfoundation.org` |
| Explorer | https://explorer.ritualfoundation.org |
| Chain ID | `1979` |

---

# 🔑 API Keys

| Key | Where | Required for |
|-----|-------|-------------|
| NVIDIA NIM | [build.nvidia.com](https://build.nvidia.com) (free tier) | Frontend analysis |
| RITUAL testnet | [Faucet](https://faucet.ritual.net) (free) | Contract deployment |
| PRIVATE_KEY | Your wallet (0x-prefixed) | Contract deployment |

---

# 📄 License

MIT
