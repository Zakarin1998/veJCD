# Technical Report: Building a DeFi LP Farming DApp for JCD, SCHAP, and HAY Using Curve, Yearn, and StakeDAO

This report outlines the development of a decentralized application (DApp) to enhance liquidity provision (LP) farming for the **JCD** (J Chan Dollar), **SCHAP** (AshleighCoin), and **HAY** (HayCoin) tokens by leveraging Curve Finance’s gauge and bribe system, Yearn Finance’s open-source strategies, and StakeDAO’s infrastructure. The goal is to create a minimal viable product (MVP) that incentivizes liquidity providers (LPs) through optimized yield farming, automated reinvestment of Curve emissions, and a custom frontend inspired by macarena.finance. The report analyzes the macarena.finance codebase, details the necessary components, and provides a step-by-step plan for implementation, focusing on open-source tools and libraries.

---

## 1. Project Overview

**Objective:** Build a DApp that:

* Deploys and manages Curve pools for JCD, SCHAP, HAY, and their pairs (e.g., JCD/ETH, SCHAP/ETH, JCD/SCHAP).
* Integrates Yearn’s strategies for automated LP farming (e.g., reinvesting Curve emissions into LP positions, similar to yvBOOST or dYFI/WETH).
* Uses StakeDAO for gauge voting and bribe collection to maximize LP returns.
* Provides a user-friendly frontend for depositing, swapping, and claiming rewards, inspired by macarena.finance.

**Tokens:**

* **JCD:** `0x0Ed024d39d55e486573EE32e583bC37Eb5A6271f`, 19,860,225 supply, Solidity 0.4.18.
* **SCHAP:** `0x3638c9e50437F00Ae53a649697F288ba68888cC1`, 7,000 supply, Solidity 0.4.25.
* **HAY:** `0xfA3E941D1F6B7b10eD84A0C211bfA8aeE907965e`, 1,000,000 supply, Solidity 0.4.25.

**Why Curve, Yearn, and StakeDAO?**

* **Curve Finance:** Provides stablecoin and low-slippage pools, with gauges and bribes to direct \$CRV emissions, increasing LP yields (Curve Wars, Mirror).
* **Yearn Finance:** Offers open-source vault strategies for automated yield optimization, such as reinvesting \$CRV rewards into LP positions (Yearn Vaults).
* **StakeDAO:** Simplifies gauge voting and bribe collection, maximizing returns for LPs (StakeDAO Overview).

**MVP Goals:**

1. Deploy Curve pools and gauges for JCD, SCHAP, HAY.
2. Implement Yearn-style strategies for reinvesting emissions.
3. Use StakeDAO for bribe aggregation.
4. Build a frontend based on macarena.finance for user interaction.

---

## 2. Analysis of macarena.finance

The macarena.finance codebase is a React-based frontend for Yearn vaults, providing a user interface for vault interactions. The file `pages/[chainID]/vault/[address].tsx` is a key component, rendering a vault’s details, strategies, and deposit functionality. Below is an analysis of this file and its relevance to the project.

### 2.1 File: `pages/[chainID]/vault/[address].tsx`

**Purpose:** Displays a specific vault’s overview, including TVL, price, strategies, and a deposit interface.

**Key Components:**

* **OverviewCard:** Shows vault metadata (e.g., TVL, price).
* **ChartCard:** Displays historical performance charts.
* **DepositCard:** Allows users to deposit tokens into the vault.
* **Strategies Section:** Lists vault strategies with descriptions and addresses.

**Libraries and Hooks:**

* **React/Next.js:** For dynamic routing and server-side rendering.
* **@yearn-finance/web-lib:** Provides utilities like `useWeb3`, `useChainID`, `yToast`, `parseMarkdown`, and components like `AddressWithActions`.
* **useYearn:** Custom hook to access vault data from Yearn’s context.

**Internal Details:**

* **Dynamic Routing:** Uses Next.js routing (`[chainID]/[address]`) to fetch vault data based on the chain ID and vault address.
* **Chain Safety:** Checks if the user’s connected chain matches the vault’s chain, displaying a toast warning if mismatched.
* **Vault Data:** Fetches vault details (e.g., strategies, TVL) from the vaults array in the Yearn context.
* **Strategy Rendering:** Maps over `currentVault.strategies` to display each strategy’s name, address, and description, parsed as markdown.

**Relevance:**

* The file is a template for displaying pool/vault data, which can be adapted to show Curve pool details (e.g., gauge weights, bribe rewards).
* The `DepositCard` can be modified for LP deposits into Curve pools.
* The chain safety logic is useful for ensuring users interact with the correct network (e.g., Ethereum for JCD).

### 2.2 Other Relevant Files (Assumed from macarena.finance)

* **Context (`contexts/useYearn.tsx`):** Manages vault data, likely fetching from Yearn’s subgraph or contracts.
* **Components (`components/vault/*.tsx`):** Reusable UI elements like `OverviewCard`, `ChartCard`, `DepositCard`.
* **Utils (`utils/*.ts`):** Helpers like `toAddress`, `parseMarkdown`.
* **Config (`lib/utils/web3/chains.ts`):** Chain configurations (e.g., Ethereum, Polygon).

These files provide a foundation for building a custom frontend, with components that can be repurposed for Curve pool interactions.

---

## 3. Technical Plan for the MVP

The MVP will consist of a **backend** (smart contracts for pools and strategies) and a **frontend** (inspired by macarena.finance). Below is a detailed plan.

### 3.1 Backend: Smart Contracts

#### 3.1.1 Curve Pool and Gauge Setup

**Objective:** Deploy Curve pools for JCD, SCHAP, HAY, and set up gauges for \$CRV emissions.

**Steps:**

1. **Deploy Pools:**

   * Use Curve’s StableSwap or CryptoSwap contracts to create pools (e.g., JCD/ETH, SCHAP/ETH).
   * Configure parameters: fee (0.04%), A parameter (e.g., 100).
2. **Add Gauges:**

   * Request Curve DAO to add gauges via governance vote or use StakeDAO’s gauge proxy.
3. **Bribe Setup:**

   * Deploy bribe contracts via bribe.crv.finance or Votium to incentivize veCRV holders.

**Libraries:**

* **Curve Contracts:** Curve Contract GitHub.
* **OpenZeppelin:** For ERC-20 interfaces and safe math.
* **Hardhat/Foundry:** For deployment and testing.

**Example Solidity:**

```solidity
import "@curvefi/curve-contract/contracts/pools/StableSwap.sol";

contract JCDPool is StableSwap {
    constructor(
        address _owner,
        address[2] memory _coins, // JCD, ETH
        uint256 _A,
        uint256 _fee
    ) StableSwap(_owner, _coins, _A, _fee) {}
}
```

#### 3.1.2 Yearn Strategies

**Objective:** Create Yearn-style vaults to automate LP farming and reinvest \$CRV emissions.

**Steps:**

1. **Vault Deployment:**

   * Fork Yearn V2 vault contracts.
   * Configure vaults to accept LP tokens from Curve pools.
2. **Strategy Development:**

   * Implement strategies to stake LP tokens in Curve gauges and reinvest \$CRV rewards.
3. **Integration with StakeDAO:**

   * Delegate voting power to StakeDAO and use `sdCRV` to maximize APR.

**Libraries:**

* **Yearn SDK**
* **Uniswap V3 SDK**
* **Chainlink**

**Example Solidity:**

```solidity
import "@yearn/yearn-vaults/contracts/BaseStrategy.sol";

contract JCDLPStrategy is BaseStrategy {
    address public curveGauge;
    address public crvToken;

    constructor(address _vault, address _gauge, address _crv) BaseStrategy(_vault) {
        curveGauge = _gauge;
        crvToken = _crv;
    }

    function harvest() external override {
        // Claim $CRV from gauge
        ICurveGauge(curveGauge).claim_rewards(address(this));
        // Swap $CRV to JCD/ETH LP via Uniswap
        // Restake LP tokens in gauge
    }
}
```

#### 3.1.3 Deployment Scripts

**Objective:** Automate pool and vault deployment.

**Tools:** Hardhat, Foundry

**Example Hardhat (JavaScript):**

```javascript
// deploy_pool.js
const hre = require("hardhat");

async function main() {
    const JCDPool = await hre.ethers.getContractFactory("JCDPool");
    const pool = await JCDPool.deploy(
        "0xOwnerAddress",
        ["0xJCDAddress", "0xETHAddress"],
        100,      // A parameter
        4000000   // 0.04% fee
    );
    await pool.deployed();
    console.log("Pool deployed to:", pool.address);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
```

### 3.2 Frontend: Custom DApp

#### 3.2.1 Forking macarena.finance

**Objective:** Adapt macarena.finance’s frontend for Curve pool and vault interactions.

**Modifications:**

* **Replace Vault Data:** Use Curve’s subgraph to fetch pool data (TVL, gauge weights).
* **Customize Components:**

  * `OverviewCard`: Show pool TVL, APR, bribe rewards.
  * `ChartCard`: Display pool volume and \$CRV emissions.
  * `DepositCard`: Allow LP token deposits.
* **Add Bribe Section:** Display bribes and voting options via StakeDAO’s API.

**Libraries:** React/Next.js, @yearn-finance/web-lib, ethers.js, Web3Modal, The Graph

**Example Modified `Vault.tsx`:**

```tsx
import React, { useEffect, useState } from 'react';
import { useWeb3 } from '@yearn-finance/web-lib/contexts/useWeb3';
import { ethers } from 'ethers';
import { CurvePool } from 'components/CurvePoolCard';

function PoolPage() {
    const { chainID } = useWeb3();
    const [poolData, setPoolData] = useState(null);

    useEffect(() => {
        async function fetchPool() {
            const provider = new ethers.providers.Web3Provider(window.ethereum);
            const poolContract = new ethers.Contract("0xPoolAddress", CurveABI, provider);
            const tvl = await poolContract.get_virtual_price();
            setPoolData({ tvl, chainID });
        }
        fetchPool();
    }, [chainID]);

    return (
        <div>
            <CurvePool poolData={poolData} />
            {/* Add deposit, bribe, and voting components */}
        </div>
    );
}

export default PoolPage;
```

#### 3.2.2 Integration with StakeDAO

**Objective:** Allow users to vote on gauges and claim bribes via StakeDAO.

**Steps:**

1. Fetch bribe data using StakeDAO’s API.
2. Integrate with Votium for bribe distribution.
3. Add a `BribeCard` component for voting and rewards.

### 3.3 Testing and Security

* **Testing:**

  * Unit Tests: Mocha/Chai
  * Integration Tests: Foundry
  * Frontend Tests: Jest
* **Security:**

  * Static Analysis: Slither
  * Audit: Quantstamp / Trail of Bits
  * Bug Bounty: Immunefi

**Known Risks:**

* JCD’s Solidity 0.4.18 lacks modern protections.
* Low-liquidity Curve pools can be manipulated.

### 3.4 Deployment

* **Testnet:** Sepolia
* **Mainnet:** Ethereum (post-audit)
* **CI/CD:** GitHub Actions

---

## 4. Open-Source Resources and Examples

* **Curve Finance:**

  * StableSwap contracts
  * Factory scripts
  * Subgraph
* **Yearn Finance:**

  * Vaults & Strategies
  * SDK & UI
* **StakeDAO:**

  * Contracts & Docs
* **Others:** Uniswap V3 SDK, OpenZeppelin, The Graph

---

## 5. Community Engagement

* **GitHub:** Create a public repo with documentation.
* **X (@marmostock):** Share milestones.
* **Collaborations:** Engage @ashleigshap and @haydenzadams.
* **Blog/Video:** Tutorials on Medium/YouTube.

---

## 6. Conclusion

By leveraging Curve’s gauge and bribe system, Yearn’s vault strategies, and StakeDAO’s voting infrastructure, you can create a robust DApp for JCD, SCHAP, and HAY LP farming. The macarena.finance frontend provides a solid foundation, requiring modifications to support Curve pools and StakeDAO integration. Using open-source tools like Hardhat, Foundry, and the Yearn SDK, you can efficiently develop an MVP. Prioritize security with audits and community engagement to ensure success.

For further details or code snippets, let me know!



# veJCD - JCDRewardPool

Here’s a detailed walkthrough and analysis of the JCD Reward Pool contract, covering its core mechanisms, data flows, and some observations about potential edge-cases and gas considerations.

## 1. Overall Purpose

The `JCD Reward Pool` contract collects incoming JCD tokens (“rewards”) and distributes them pro rata to veJCD (vote-escrowed JCD) holders over weekly epochs.  It:

1. **Accumulates** tokens via `burn(...)` (anyone can send rewards in).
2. **Checkpoints** total incoming tokens per week (`_checkpoint_token`).
3. **Checkpoints** total veJCD supply per week (`_checkpoint_total_supply`).
4. **Allows users** to `claim(...)` their share based on their historical veJCD balances.
5. **Optionally relocks** claimed tokens back into the veJCD contract.

---

## 2. Key Storage & Constants

* **Epoch length**: `WEEK = 7 * 86400`.
* **Checkpoint deadline**: `TOKEN_CHECKPOINT_DEADLINE = 86400` (1 day).
* **Immutable refs**:

  * `JCD`: the ERC-20 token being distributed.
  * `VEJCD`: the voting-escrow contract interface.
* **Time cursors**:

  * `start_time`: first week-aligned epoch when distributions begin.
  * `time_cursor`: last timestamp up to which total-supply was checkpointed.
  * `time_cursor_of[user]`: last week timestamp the user claimed through.
* **Accounting maps**:

  * `tokens_per_week[week_timestamp]`: tokens allocated to each week.
  * `ve_supply[week_timestamp]`: total veJCD supply at each week.

---

## 3. Token Checkpointing (`_checkpoint_token`)

Triggered in two ways:

1. **Externally** via `checkpoint_token()` (requires >1 day since last).
2. **Lazily** within `burn()` and `claim()` if deadline passed.

Logic:

* Compute new `to_distribute = current_balance - token_last_balance`.
* Walk through weeks from `last_token_time` in up to 40 iterations:

  * For each full or partial week slice, allocate pro rata share of `to_distribute` into `tokens_per_week`.
* Update `last_token_time` to `block.timestamp` and `token_last_balance`.

**Observations:**

* **40-week loop bound**: safe against out-of-gas if time gaps are small; but if someone delays >40 weeks of distributions in one go, unallocated tokens past the 40th week would be missed.
* **Precision**: uses integer math; sums of slices always equal `to_distribute` (barring rounding), so no tokens lost.
* **Deadline**: external calls only allowed if >1 day since last checkpoint, preventing griefing via too-frequent checkpoints.

---

## 4. veJCD Supply Checkpointing (`_checkpoint_total_supply`)

Called:

1. **Externally** via `checkpoint_total_supply()`.
2. **Lazily** by the first `claim()` in a new week.

Logic:

* Starting at `time_cursor`, iterate up to 40 weeks until current week.
* For each week-timestamp `t`:

  * Query `VEJCD.find_epoch_by_timestamp(VEJCD.address, t)` to get the epoch index.
  * Fetch the historical `Point` (bias, slope, ts) from `point_history`.
  * Compute remaining locked mass at time `t` as `max(bias − slope*(t − ts), 0)`.
  * Store into `ve_supply[t]`.
* Advance `time_cursor` by weeks processed.

**Observations:**

* **Dependency on external contract**: must trust that `VEJCD`’s `point_history` and `find_epoch_by_timestamp` work as intended.
* **40-week cap**: similarly bounds gas but could truncate supply history if uncalled for many weeks.
* **Non-reentrancy**: checkpoint itself is internal, but if `claim()` triggers it, reentrancy is guarded by `'lock'`.

---

## 5. Claim Flow

### 5.1 `_claim(addr, last_token_time)`

* Get user’s maximum epoch index. If zero (never locked), returns 0.
* Initialize `week_cursor`:

  * If first claim: align from user’s first lock timestamp.
  * Else resume from stored `time_cursor_of[addr]`.
* Clamp `week_cursor` to `start_time`.
* Loop up to 50 weeks:

  * Stop if `week_cursor ≥ last_token_time`.
  * Query user’s veJCD balance at that week: `VEJCD.balanceOf(addr, week_cursor)`.
  * Accumulate share = `balance_of * tokens_per_week[week_cursor] / ve_supply[week_cursor]`.
  * Advance `week_cursor += WEEK`.
* Update `time_cursor_of[addr]` to new cursor; emit `Claimed`.

### 5.2 `claim(user, relock)`

* If needed, run total-supply checkpoint.
* If deadline passed, run token checkpoint.
* Align `last_token_time` to week boundary.
* Call `_claim(...)`.
* If `relock` is true and permitted, `approve` & call `modify_lock` to add claimed tokens into veJCD; else transfer out.
* Deduct `amount` from `token_last_balance`.

**Observations:**

* **Gas**: each claim iterates up to 50 on-chain historical balance reads; heavy for users with long lock histories.
* **Partial claims**: if user has >50 weeks unclaimed, they must call multiple times.
* **Relock permissions**: users can delegate relock rights via `toggle_allowed_to_relock`.

---

## 6. Reward Ingestion (`burn`)

* Pulls in up to `amount` JCD from caller (via allowance).
* Emits `RewardReceived`.
* If > 1 day since last token checkpoint, triggers one.

**Observation:**
Naming `burn` is semantic—no tokens are burnt; they are held for distribution.

---

## 7. Access Controls & Safety

* **No admin role**: fully permissionless.
* **Reentrancy**: only `claim` uses `@nonreentrant('lock')`; other external calls are simple transfers/checkpoints.
* **Loop bounds**: hard-coded 40/50 iterations cap, preventing unbounded gas usage but potentially skipping epochs if not called often.
* **Rounding**: integer division may yield dust; unallocated dust remains in contract until later distributions.

---

## 8. Potential Edge-Cases & Recommendations

1. **Skipped Weeks**
   If nobody calls checkpoints for >40 weeks, distributions beyond the 40th week are never allocated.
   *Mitigation*: increase loop bound or implement a while-loop with gas checks.

2. **Accumulated Dust**
   Rounding in per-week slicing and per-user shares leaves small remainders. Over time, unclaimed dust could build.
   *Mitigation*: track and carry over remainders explicitly.

3. **User History Depth**
   Long-time holders may require multiple transactions to sweep all rewards due to the 50-week claim cap.
   *Mitigation*: allow dynamic per-call epochs or batching via off-chain tooling.

4. **Timestamp Alignment**
   All operations align to week multiples; if `start_time` isn’t human-aligned (e.g., not midnight UTC Monday), weeks may be offset.
   *Mitigation*: document chosen epoch anchor clearly.

5. **Checkpoint Gas Costs**
   Frequent checkpointing (token vs. supply) could be costly. Consider scheduling via keepers or off-chain bots.

---

**Conclusion**
The contract implements a tried-and-tested ve-style reward mechanism, carefully balancing gas limits with correctness via bounded loops. Its permissionless design ensures decentralization, but operators and users should monitor checkpoint freshness and be prepared for multi-tx claims if rewards build up over many epochs.
