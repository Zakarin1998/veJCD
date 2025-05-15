## Risposta Diretta

### Punti chiave

* Sembra probabile che si possa creare un'applicazione DeFi per incentivare il farming di liquidità per JCD, SCHAP e HAY usando Curve, Yearn e StakeDAO, ma richiede un processo di governance per aggiungere un pool su Curve.
* Per un MVP rapido, è possibile deployare un pool personalizzato con i contratti open-source di Curve, offrire ricompense in JCD e usare StakeDAO per la gestione.
* La ricerca suggerisce che forkare macarena.finance per il frontend è fattibile, ma richiede modifiche per interagire con i contratti personalizzati.
* L’integrazione con Yearn può essere utile per strategie, ma dipende dalla disponibilità di pool esistenti.

---

## Panoramica del Progetto

Per creare un’applicazione DeFi che incentivi il farming di liquidità, si può partire da un pool personalizzato per JCD/ETH usando i template di Curve (ad es. `plain-2.json`) e deployarlo con Hardhat o Foundry. Offrire ricompense in JCD ai fornitori di liquidità (LP) per incentivarli. Forkare [macarena.finance](https://github.com/yearn/macarena.finance) per il frontend, modificandolo per interagire con i contratti personalizzati. Usare StakeDAO per gestire la liquidità e i voti, e considerare Yearn per strategie avanzate.

### Processo per l’MVP

1. **Deploy del Pool**
   Utilizzare i contratti open-source di Curve per creare un pool JCD/ETH, testarlo localmente e deployarlo su mainnet.

2. **Sistema di Ricompense**
   Implementare un contratto per distribuire ricompense in JCD, ispirandosi a Curve.

3. **Frontend**
   Modificare macarena.finance per mostrare dettagli del pool, depositi e ricompense.

4. **Integrazione con StakeDAO**
   Usare i liquid lockers di StakeDAO per gestire veJCD, se implementato.

---

## Considerazioni Future

Per integrare il sistema ufficiale di Curve, sarà necessario acquisire veCRV, proporre un nuovo pool attraverso la governance di Curve DAO, e ottenere l’approvazione della comunità, un processo che potrebbe richiedere tempo.

---

# Rapporto Tecnico: Sviluppo di un’Applicazione DeFi per LP Farming con Curve, Yearn e StakeDAO

Questo rapporto fornisce un’analisi dettagliata e professionale per sviluppare un’applicazione DeFi che incentivi il farming di liquidità per i token JCD, SCHAP e HAY, sfruttando le infrastrutture di Curve Finance, Yearn Finance e StakeDAO.

---

## 1. Contesto e Obiettivi

**Token ERC-20 coinvolti:**

* **JCD (J Chan Dollar)**

  * Indirizzo: `0x0Ed024d39d55e486573EE32e583bC37Eb5A6271f`
  * Supply totale: 19,860,225
  * Solidity: 0.4.18

* **SCHAP**

  * Indirizzo: `0x3638c9e50437F00Ae53a649697F288ba68888cC1`
  * Supply totale: 7,000
  * Solidity: 0.4.25

* **HAY**

  * Indirizzo: `0xfA3E941D1F6B7b10eD84A0C211bfA8aeE907965e`
  * Supply totale: 1,000,000
  * Solidity: 0.4.25

**Obiettivi del progetto:**

* Incentivare i fornitori di liquidità (LP) per i token JCD, SCHAP e HAY.
* Utilizzare il sistema di gauge e bribe di Curve per massimizzare le ricompense.
* Costruire su infrastrutture open-source come Curve, Yearn e StakeDAO.
* Offrire un frontend user-friendly per depositi, swap e claim delle ricompense.

La sfida principale è che JCD non è attualmente su Curve, quindi è necessario un processo di governance per aggiungere un nuovo pool o creare un pool personalizzato per l’MVP.

---

## 2. Analisi delle Infrastrutture

### Curve Finance

* Pool di liquidità con bassi slippage per stablecoin e token a bassa volatilità.
* Sistema di gauge e bribe che permette ai detentori di veCRV di votare per le ricompense dei pool e offrire incentivi aggiuntivi.
* **Aggiunta di un nuovo pool (es. JCD/ETH):**

  1. Ottenere veCRV (CRV lockato per il voto).
  2. Proporre il pool tramite Curve DAO.
  3. Attendere l’approvazione della comunità.
* **Alternativa per MVP:** deploy personalizzato con i template di Curve ([pool-templates](https://github.com/curvefi/curve-contract/tree/master/pool-templates)).

### Yearn Finance

* Vault per ottimizzare il yield farming, inclusi pool Uniswap V2/V3.
* Possibilità di creare un vault per JCD/ETH su Uniswap.
* Token veYFI che può essere forkato per creare veJCD.

### StakeDAO

* Specializzato in liquid staking e governance.
* Offre liquid lockers per token di governance, utili per creare veJCD.
* Può gestire voti sui gauge e ricompense.

---

## 3. Analisi di macarena.finance

L’interfaccia di macarena.finance è un frontend React/Next.js basato su Yearn’s web-lib per interagire con i vault di Yearn.

* **File chiave:** `pages/[chainID]/vault/[address].tsx`

  * **OverviewCard:** mostra TVL, prezzo e metadati.
  * **ChartCard:** visualizza grafici storici.
  * **DepositCard:** permette depositi nei vault.
  * **Sezione Strategie:** elenca strategie con descrizioni e indirizzi.
* **Librerie:**

  * `@yearn-finance/web-lib` (useWeb3, useChainID, yToast)
  * `useYearn` per dati dei vault.
* **Routing dinamico:** dati basati su `chainID` e `address`.
* **Sicurezza catena:** avvisi se la catena non corrisponde.
* **Rilevanza:** adattabile per pool Curve personalizzati; DepositCard e logica di sicurezza riutilizzabili.

---

## 4. Piano per l’MVP

### 4.1 Deployare un Pool Personalizzato

1. Clonare il repository di Curve Contracts.
2. Configurare `pooldata.json` con JCD e ETH.
3. Testare localmente:

   ```bash
   brownie run deploy --network mainnet-fork -I
   ```
4. Deploy su mainnet:

   ```bash
   brownie run deploy --network mainnet
   ```

### 4.2 Sistema di Ricompense

```solidity
contract JCDRewardDistributor {
    address public pool;
    address public jcdToken;

    constructor(address _pool, address _jcd) {
        pool = _pool;
        jcdToken = _jcd;
    }

    function distributeRewards() external {
        // Logica per distribuire JCD ai LP
    }
}
```

Ispirarsi al contratto `LiquidityGauge` di Curve.

### 4.3 Token di Governance (veJCD)

Forkare il contratto veYFI di Yearn e adattarlo:

```solidity
contract veJCD is ERC20 {
    // Logica per lockare JCD e ottenere veJCD
}
```

Permette di votare su proposte interne e ottenere boost sulle ricompense.

### 4.4 Sviluppare il Frontend

* Fork di macarena.finance.
* Modifiche per interagire con pool e contratti di ricompense.
* Nuovi componenti:

  * Deposit/Withdraw.
  * Visualizzazione ricompense.
  * Votazioni con veJCD.

### 4.5 Integrazione StakeDAO

* Utilizzare i liquid lockers di StakeDAO per veJCD.
* Permettere lock senza gestione diretta del contratto veJCD.

---

## 5. Considerazioni sulla Governance

### Aggiunta del Pool su Curve

1. Acquisire CRV e lockarlo per veCRV.
2. Proporre pool JCD/ETH in Curve DAO.
3. Raggiungere quorum del 15% per l’approvazione.

### Governance Interna

* Usare veJCD per votazioni interne (parametri pool).
* Possibile uso di Aragon o contratto DAO personalizzato.

---

## 6. Risorse Open-Source

* **Curve Contracts:** template dei pool
* **veYFI GitHub:** contratto veToken
* **StakeDAO Docs:** liquid lockers
* **macarena.finance GitHub:** frontend

---

## 7. Tabelle Riepilogative

| Componente                | Descrizione                                                                     | Risorse Open-Source     |
| ------------------------- | ------------------------------------------------------------------------------- | ----------------------- |
| **Pool Personalizzato**   | Deploy pool JCD/ETH (template `plain-2.json`)                                   | Curve Contracts         |
| **Sistema di Ricompense** | Contratto per distribuire JCD ai LP (fork di `LiquidityGauge`)                  | LiquidityGauge          |
| **Token di Governance**   | Fork di veYFI per creare veJCD                                                  | veYFI GitHub            |
| **Frontend**              | Fork di macarena.finance, modifiche per interagire con contratti personalizzati | macarena.finance GitHub |
| **Integrazione StakeDAO** | Liquid lockers per gestire veJCD                                                | StakeDAO Docs           |

---

## 8. Conclusione

Per l’MVP è consigliabile:

1. Deployare un pool personalizzato con i contratti open-source di Curve.
2. Implementare un sistema di ricompense in JCD.
3. Creare veJCD per governance e boost.
4. Forkare macarena.finance per il frontend.
5. Integrare StakeDAO per i liquid lockers.

In futuro, lavorare per aggiungere il pool a Curve tramite governance, abilitando l’accesso ufficiale a gauge e bribe. Questo approccio unisce rapidità di sviluppo e flessibilità, garantendo scalabilità nel tempo.

---

Below is a deep-dive into the `Voting JCD` contract, mirroring the structure of the reward‐pool analysis and highlighting its core mechanisms, data flows, and potential edge cases.

## Executive Summary

The `Voting JCD` (“veJCD”) contract implements a time–weighted voting lock system for JCD tokens, borrowing heavily from the Curve/YFI–style veToken model. Users deposit JCD into time-locked positions (up to 10 years), earning voting power that decays linearly and is capped at a 4-year lock. The contract maintains both per‐user and global historical snapshots (“points”) of bias (voting power) and slope (decay rate), enabling queries of past and present voting balances. Early unlock incurs a penalty (up to 75%), which is routed into a configured reward pool. Critical functions include `modify_lock` (create/extend/reduce locks), `withdraw` (redeem with penalty if early), and numerous viewers (`balanceOf`, `getPriorVotes`, `totalSupplyAt`) that reconstruct voting power by replaying scheduled “slope changes.” Robust checkpointing keeps on‐chain history bounded by iteration caps (255 weeks global, 522 weeks per‐user) to limit gas use, at the cost of requiring periodic maintenance to avoid truncation.

---

## 1. Core Data Structures

### 1.1 LockedBalance & Kink

* **LockedBalance**

  * `amount`: JCD tokens locked
  * `end`: unlock timestamp (rounded down to week)

* **Kink**

  * Temporary structure capturing the point in time when a lock exceeds the 4-year cap
  * Used to schedule “slope” adjustments beyond the maximum voting horizon

### 1.2 Point & Slope Changes

* **Point**

  * `bias` (int128): current voting power
  * `slope` (int128): rate of decay (votes per second)
  * `ts` / `blk`: timestamp and block when snapshot was taken

* **slope\_changes\[user]\[t]**

  * At each weekly boundary `t`, stores signed slope adjustments scheduled by past lock modifications or kinks

### 1.3 Global History

* `point_history[self][epoch]`: records the aggregate (total) `Point` at each weekly checkpoint
* `epoch[self]`: index of the latest global checkpoint
* `supply`: total locked JCD (not voting power)

---

## 2. Lock Creation & Modification (`modify_lock`)

1. **Parameters**

   * `amount`: additional JCD to deposit (may be zero)
   * `unlock_time`: desired new unlock timestamp (must be week‐aligned)
   * `user`: target account (msg.sender if extending own lock; else only deposit)

2. **Rules & Assertions**

   * **New lock**: requires ≥ 1 JCD, unlock\_time > now
   * **Extend (< 4 years)**: only increase end if currently < 4 years remaining
   * **Reduce (> 4 years)**: only decrease end if currently > 4 years remaining
   * Max lock horizon: 10 years (522 weeks)

3. **State Updates**

   * `locked[user]` updated to include new amount/end
   * `supply` increases by `amount`
   * JCD tokens pulled via `transferFrom` if `amount > 0`
   * Emits `Supply` and `ModifyLock` events

4. **Checkpointing**

   * Calls internal `_checkpoint(user, old_lock, new_lock)`, which:

     1. **User‐level**: computes old/new `Point` & `Kink`, schedules local slope changes
     2. **Global**: advances the global history to now via `_checkpoint_global`
     3. **Merge**: adjusts the latest global `Point` by the user’s delta, and writes it

---

## 3. Global Checkpointing (`_checkpoint_global`)

* **Purpose**: Snap the total voting power curve forward in weekly increments up to the current block
* **Mechanism**:

  1. Start from the last global `Point` (bias, slope, ts, blk)
  2. Compute `block_slope = Δblocks/Δtime` to interpolate block numbers at past weeks
  3. Loop up to 255 weeks (∼5 years):

     * For each `t_i = min(prev_week + WEEK, now)`:

       * Decay bias: `bias -= slope * (t_i − last_ts)`
       * Apply scheduled `slope_changes[self][t_i]`
       * Clamp non‐negative
       * Update `blk` by interpolating via `block_slope`
       * Advance epoch, write snapshot if `t_i < now`
       * On final iteration (`t_i == now`), set `blk = block.number` and break
* **Gas Bounding**: 255-week cap prevents unbounded loops but requires regular checkpoints to avoid truncation

---

## 4. Withdrawals & Penalties (`withdraw`)

* **Normal Unlock** (expired lock): full amount returned, no penalty
* **Early Unlock**:

  * Compute `time_left = min(end − now, MAX_LOCK_DURATION)`
  * `penalty_ratio = (time_left / MAX_LOCK_DURATION)` capped at 75%
  * `penalty = amount * penalty_ratio`
  * User receives `amount − penalty`
  * Penalty approved and sent to `REWARD_POOL.burn(penalty)`
* **State Updates**

  * `locked[msg.sender]` zeroed
  * `supply` reduced by full `old_locked.amount`
  * Global/user‐level checkpoint reflecting removal
  * Emits `Withdraw`, `Penalty`, and `Supply` events

---

## 5. Querying Voting Power

### 5.1 Current Balance (`balanceOf`)

* Internally calls `_balanceOf(user, ts)`:

  1. Find the latest user epoch ≤ `ts` via binary‐search `find_epoch_by_timestamp`
  2. Load that `Point`, then call `replay_slope_changes` to walk week by week (up to 522) decaying bias and applying slopes
  3. Return `bias` as voting power

### 5.2 Historical Votes (`getPriorVotes`)

* Given a block height:

  1. Find user epoch by block via `find_epoch_by_block` (binary‐search on `blk`)
  2. Interpolate timestamp at that block between two global snapshots
  3. Replay per‐user slopes to that timestamp

### 5.3 Total Supply Queries

* **`totalSupply(ts)`**: alias for `_balanceOf(self, ts)`
* **`totalSupplyAt(height)`**: uses block‐based interpolation on the global history, then `replay_slope_changes(self, …)`

---

## 6. Edge Cases & Gas Considerations

1. **Loop Bounds**

   * **Global**: 255 iterations (∼5 years)
   * **Per‐user replay**: 522 weeks (10 years)
   * If histories exceed these caps without being checkpointed, queries may undercount beyond the window.

2. **Precision & Rounding**

   * Weekly alignment of locks and slope changes can lead to small timing misalignments; all arithmetic uses integer math, so minimal rounding dust may accrue.

3. **Penalty Curve**

   * Linear from 75% down to 0 over 4 years; after 4 years remaining, slope is zeroed, so no further penalty reduction.

4. **Interoperability**

   * Designed to be compatible with Governor-style voting (via `getPriorVotes`) and Aragon (ERC-20 style `totalSupply`).

5. **Checkpoint Freshness**

   * External callers must regularly invoke `checkpoint()` (or indirectly via `modify_lock`/`withdraw`) to keep the global history up to date and avoid stale vote readings.

---

### Conclusion

The `Voting JCD` contract robustly implements a time-weighted veToken model with full historical snapshots, penalty-driven early exit, and both block- and timestamp-based querying. Its bounded loops and scheduled slope changes carefully trade off gas predictability against the need to capture up to a decade of lock history. Operators and integrators should monitor checkpoint cadence and be wary of the iteration caps when designing front-ends or off-chain tooling.
