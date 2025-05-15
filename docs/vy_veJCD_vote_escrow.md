# veJCD vote-escrow mechanisms
**In brief:** The veYFI (vote-escrow) contract uses a **checkpointing** mechanism to record on-chain state only at discrete weekly “ticks,” rather than every single block or user action.  This design – borrowed from Curve’s VotingEscrow – **caps** how many of those weekly ticks need to be iterated over when computing global state (255 weeks) and per-user state (≈ 522 weeks, i.e. 10 years) to keep gas costs bounded.  **However**, if no one calls the checkpoint for longer than those caps, older history entries will effectively be “dropped,” so **periodic maintenance** (e.g. a keeper or user interaction) is required to keep the full history intact and avoid truncation of voting power or boost calculations.

---

## 1. How checkpointing works

### 1.1 Discrete weekly epochs

* Instead of storing every block’s state, the contract keeps “points” only at weekly boundaries (i.e. multiples of 1 week) in a `point_history` array and per-user `user_point_history` arrays.
* This shrinks the amount of on-chain data and simplifies calculations to a known, limited set of timestamps. ([Ethereum Stack Exchange][1])

### 1.2 Iteration caps

* **Global cap (255):** When updating the global history (`_checkpoint()`), the code loops at most 255 times (≈ 4.9 years of weeks).  If 255 weeks ever pass without someone calling `_checkpoint()`, no further history is added until the next interaction, and vote‐weight computations beyond that will see truncated data. ([Ethereum Stack Exchange][1])
* **Per-user cap (≈ 522):** Each user’s own history is similarly capped around 522 weeks (≈ 10 years), matching the maximum lock duration (users can lock up to 10 years, though only 4 years grant extra veYFI) ([docs.yearn.fi][2], [docs.yearn.fi][3]).

---

## 2. Why cap iterations?

### 2.1 Bounding gas costs

* Iterating over an unbounded array of old/week-by-week entries would eventually make functions like balance queries or checkpoints prohibitively expensive (and thus unaffordable in gas).
* By enforcing a **hard cap** on the number of loop iterations, the contract guarantees that its gas usage stays within predictable limits, even as time marches on. ([Ethereum Stack Exchange][1])

### 2.2 Trade-off: maintenance required

* **Pro:** Gas is kept low for on-chain calls (e.g. deposits, withdrawals, vote weight checks).
* **Con:** If **no one** interacts for longer than the cap (e.g. > 255 weeks globally), older history entries beyond that window are never recorded or are “rolled off,” so calculations will ignore them (effectively resetting votes or boosts back to zero at that point).
* **Solution:** A “keeper” or active user must call a maintenance function (e.g. trigger `_checkpoint()`) **periodically** to slide the window forward and preserve a continuous history. ([Ethereum Stack Exchange][1])

---

## 3. Origins and context

* This pattern comes directly from Curve Finance’s **VotingEscrow\.vy** contract, which uses the same 255-week loop to bound its on-chain history ([GitHub][4]).
* Yearn’s veYFI is based on the **Curve ve-model** and similarly forks that checkpoint logic into its own governance tokenomics ([docs.yearn.fi][3]).
* Auditors (e.g. Electisec) note that this design—while efficient—**requires** active upkeep to prevent vote weights from “breaking” after the cap window passes without interaction ([Electisec][5]).

---

**Bottom line:**
Checkpointing with iteration caps is a **gas-saving** strategy that limits how much history the contract needs to process at once.  It does so by only recording state at weekly intervals and enforcing maximum look-back windows (255 weeks global, ≈ 522 weeks per user).  The trade-off is that if nobody **interacts** for longer than those windows, older data will be truncated—so you need periodic maintenance calls to keep everything up to date.

[1]: https://ethereum.stackexchange.com/questions/143388/what-happens-on-curves-votingescrow-contract-after-5-years?utm_source=chatgpt.com "What happens on curves VotingEscrow contract after 5 years?"
[2]: https://docs.yearn.fi/contributing/governance/veyfi "Specification | Yearn Docs"
[3]: https://docs.yearn.fi/contributing/governance/veYFI-intro?utm_source=chatgpt.com "veYFI Overview - Yearn Docs"
[4]: https://github.com/curvefi/curve-dao-contracts/blob/master/contracts/VotingEscrow.vy?utm_source=chatgpt.com "curve-dao-contracts/contracts/VotingEscrow.vy at master - GitHub"
[5]: https://reports.electisec.com/reports/04-2022-veYFI?utm_source=chatgpt.com "Electisec veYFI Review"
