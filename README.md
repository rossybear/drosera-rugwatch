# Rugwatch — Drosera Trap for On-Chain Anomaly Detection

This repository implements **Rugwatch**, a Drosera trap and operator integration designed to monitor token / liquidity anomalies on an EVM chain, detect slippage events or other suspicious behavior, and respond accordingly.

---

## 📜 What the Trap Does

- **Monitors price movement dynamics** (e.g. via Uniswap V3 pool ticks or similar data sources) each block.
- Implements a **threshold-based detection mechanism**: if the change in price (or related metric) between successive observations exceeds a configured limit, the trap “fires.”
- When triggered, it sends a **response call** (e.g. an `alert` function) via a response contract, allowing further tooling (alerts, scripts, protective actions) to run.
- It runs continuously via a Drosera operator node, which collects data, invokes the trap’s `shouldRespond(...)`, and applies any needed updates.

In short: Rugwatch is your “watchtower” on-chain, programmed to sound the alarm when unexpected or extreme movements occur.

---

## 🧩 Architecture & Components

### 1. Trap Contract (`rugwatch`)
- Deployed to the target chain.
- Implements Drosera's required interface (e.g. `collect()`, `shouldRespond(...)`) so the operator can query and evaluate it.
- Contains parameters (thresholds, intervals, addresses) governing detection logic.

### 2. Operator Node (Drosera)
- Runs the `drosera-operator node` command.
- Registers the operator (if not already) on-chain.
- Maintains a local DB, connects to P2P network, and subscribes to block events.
- Each block:
  - Calls `collect()` on traps to get fresh data.
  - Passes collected data points to `shouldRespond(...)`.
  - If `true`, invokes the response contract’s function defined in `drosera.toml`.

### 3. Response Contract
- A companion Solidity contract (for example: `alert(address, ...)`).
- The trap’s configuration points to this contract and a specific function.
- When the trap fires, the operator sends a transaction to that contract to execute the alert logic.

### 4. Configuration (`drosera.toml`, `.env`, systemd / Docker)
- `drosera.toml` defines one or more traps, thresholds, data sources, and response configuration.
- `.env` or environment variables supply private keys and RPC endpoints.
- systemd or Docker setups ensure the operator runs persistently.

---

## ⚙️ How the Detection Works (Details)

1. **Data Collection**  
   The operator node calls `collect()` on the trap contract, which returns a quantitative metric — for instance, a Uniswap V3 pool’s current tick, encoded in a uint256.

2. **Observation Window**  
   The trap is configured with a `required_observations` parameter (commonly `2` or more), meaning it needs multiple consecutive data points to evaluate.

3. **Threshold Comparison**  
   The trap’s logic iterates over pairs of successive observations and computes the **absolute difference**.  
   If the difference ≥ `tickThreshold` (a preset limit), then a trigger is declared.

4. **Trigger & Response**  
   If `shouldRespond(...) == true`, the operator builds and sends a transaction to the response contract’s function specified in `drosera.toml`. This could be an `alert(...)`, or possibly more complex logic (pausing contracts, notifying external systems, etc.).

5. **Updates & Reconfiguration**  
   You can change thresholds, response addresses, or trap parameters by re-applying via `drosera apply`, which updates on-chain trap config. The operator picks up that change in subsequent blocks.

---

## 🧰 Usage & Deployment Summary

1. Clone this repo:
   ```bash
   git clone https://github.com/rossybear/drosera-rugwatch.git
   cd drosera-rugwatch
