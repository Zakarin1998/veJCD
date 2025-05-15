# VotingJCD, RewardPool and CustomStrategies

## Panoramica del Progetto

Per creare un'applicazione DeFi che incentivi il farming di liquidità, si può partire da un pool personalizzato per JCD/ETH usando i template di Curve, come plain-2.json, e deployarlo con Hardhat o Foundry. Offrire ricompense in JCD ai fornitori di liquidità (LP) per incentivarli. Forkare macarena.finance macarena.finance GitHub per il frontend, modificandolo per interagire con i contratti personalizzati. Usare StakeDAO per gestire la liquidità e i voti, e considerare Yearn per strategie avanzate.

### Processo per l'MVP

- **Deploy del Pool**: Utilizzare i contratti open-source di Curve per creare un pool JCD/ETH, testarlo localmente e deployarlo su mainnet.  
- **Sistema di Ricompense**: Implementare un contratto per distribuire ricompense in JCD, ispirandosi a Curve.  
- **Frontend**: Modificare macarena.finance per mostrare dettagli del pool, depositi e ricompense.  
- **Integrazione con StakeDAO**: Usare i liquid lockers di StakeDAO per gestire veJCD, se implementato.  

### Considerazioni Future

Per integrare il sistema ufficiale di Curve, sarà necessario acquisire veCRV, proporre un nuovo pool attraverso la governance di Curve Curve DAO, e ottenere l'approvazione della comunità, un processo che potrebbe richiedere tempo.

## Rapporto Tecnico: Sviluppo di un'Applicazione DeFi per LP Farming con Curve, Yearn e StakeDAO

Questo rapporto fornisce un'analisi dettagliata e professionale per sviluppare un'applicazione DeFi che incentivi il farming di liquidità per i token JCD, SCHAP e HAY, sfruttando le infrastrutture di Curve Finance, Yearn Finance e StakeDAO. Il piano include la creazione di un pool personalizzato, un sistema di ricompense, un token di governance e un frontend personalizzato, con un occhio all'integrazione futura con il sistema ufficiale di Curve.

### 1. Contesto e Obiettivi

L'ecosistema comprende tre token ERC-20:

- **JCD (J Chan Dollar)**: Indirizzo `0x0Ed024d39d55e486573EE32e583bC37Eb5A6271f`, supply totale 19,860,225, Solidity 0.4.18.  
- **SCHAP**: Indirizzo `0x3638c9e50437F00Ae53a649697F288ba68888cC1`, supply totale 7,000, Solidity 0.4.25.  
- **HAY**: Indirizzo `0xfA3E941D1F6B7b10eD84A0C211bfA8aeE907965e`, supply totale 1,000,000, Solidity 0.4.25.  

L'obiettivo è creare un'applicazione DeFi che:

- Incentivi i fornitori di liquidità (LP) per i token JCD, SCHAP e HAY.  
- Utilizzi il sistema di gauge e bribe di Curve per massimizzare le ricompense.  
- Sia costruita su infrastrutture open-source come Curve, Yearn e StakeDAO.  
- Offra un frontend user-friendly per depositi, swap e claim delle ricompense.  

La sfida principale è che JCD non è attualmente su Curve, quindi è necessario un processo di governance per aggiungere un nuovo pool o creare un pool personalizzato per l'MVP.

### 2. Analisi delle Infrastrutture

#### Curve Finance

- Offre pool di liquidità con bassi slippage per stablecoin e token con bassa volatilità, come sBTC o renBTC.  
- Il sistema di gauge e bribe permette ai detentori di veCRV di votare per le ricompense dei pool e offrire incentivi aggiuntivi.

Per aggiungere un nuovo pool (es. JCD/ETH), è necessario:

- Avere veCRV (CRV lockato per il voto).  
- Proporre il nuovo pool attraverso la governance di Curve Curve DAO.  
- Attendere l'approvazione della comunità.

**Alternative**: Deployare un pool personalizzato utilizzando i contratti open-source di Curve, come i template in pool-templates Curve Contracts.

#### Yearn Finance

- Fornisce vault per ottimizzare il yield farming, inclusi pool di Uniswap V2/V3.  
- È possibile creare un vault per il pool JCD/ETH su Uniswap DexScreener JCD.  
- Yearn ha anche il token veYFI, che può essere forkato per creare veJCD veYFI GitHub.

#### StakeDAO

- Specializzato in liquid staking e governance.  
- Offre liquid lockers per token di governance, che possono essere usati per creare veJCD StakeDAO Docs.  
- Può essere integrato per gestire i voti sui gauge e le ricompense.

### 3. Analisi di macarena.finance

L'interfaccia di macarena.finance, basata su Yearn's web library, è un frontend React/Next.js per interagire con i vault di Yearn. Il file `pages/[chainID]/vault/[address].tsx` mostra i dettagli di un vault, inclusi:

- **OverviewCard**: Mostra TVL, prezzo e altri metadati.  
- **ChartCard**: Visualizza grafici storici.  
- **DepositCard**: Permette depositi nei vault.  
- **Sezione Strategie**: Elenca le strategie del vault con descrizioni e indirizzi.

**Librerie Utilizzate**:

- `@yearn-finance/web-lib`: Per utilità Web3 come `useWeb3`, `useChainID`, `yToast`.  
- `useYearn`: Hook personalizzato per accedere ai dati dei vault.

**Dettagli Interni**:

- Routing dinamico con Next.js per fetchare dati in base a chainID e indirizzo.  
- Controllo della catena: Mostra un avviso se la catena del vault non corrisponde a quella dell'utente.  
- Rendering delle strategie: Mappa le strategie del vault per mostrare nome, indirizzo e descrizione.

**Rilevanza per il Progetto**:

- Può essere adattato per mostrare dettagli dei pool Curve personalizzati.  
- Il `DepositCard` può essere modificato per depositi nei pool.  
- La logica di sicurezza della catena è utile per garantire interazioni corrette.

**Altri file rilevanti includono**:

- `Context (contexts/useYearn.tsx)`: Gestisce i dati dei vault, probabilmente tramite subgraph o contratti.  
- `Componenti (components/vault/*.tsx)`: Elementi UI riutilizzabili.  
- `Utils (utils/*.ts)`: Aiuti come `toAddress`, `parseMarkdown`.

### 4. Piano per l'MVP

#### Deployare un Pool Personalizzato

- Utilizzare i template di Curve (es. plain-2.json) per creare un pool con JCD e ETH.  
- Deployare il contratto del pool utilizzando Hardhat o Foundry.  
- Esempio: Usare il contratto StableSwap di Curve come base.

**Passaggi**:

```bash
# Clonare il repository di Curve
# Configurare pooldata.json con i token JCD e ETH
brownie run deploy --network mainnet-fork -I
brownie run deploy --network mainnet
```

#### Implementare un Sistema di Ricompense

Creare un contratto per distribuire ricompense in JCD ai fornitori di liquidità. Inspirarsi al sistema di distribuzione di CRV su Curve, forkando il contratto LiquidityGauge.

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

#### Creare un Token di Governance (veJCD)

Forkare il contratto veYFI di Yearn veYFI GitHub. Adattarlo per JCD, permettendo ai detentori di lockare JCD per ottenere veJCD.

```solidity
contract veJCD is ERC20 {
    // Logica per lockare JCD e ottenere veJCD
}
```

#### Sviluppare il Frontend

* Forkare macarena.finance macarena.finance GitHub.
* Modificare l'interfaccia per interagire con il pool personalizzato e i contratti di ricompense.
* Aggiungere componenti per:

  * Depositare e ritirare liquidità.
  * Visualizzare le ricompense e i dettagli del pool.
  * Votare con veJCD (se implementato).

**Esempio**: Modificare `vault/[address].tsx` per mostrare i dettagli del pool personalizzato.

#### Integrare StakeDAO

Utilizzare i liquid lockers di StakeDAO per gestire veJCD StakeDAO Docs. Permettere ai detentori di JCD di lockare i token per ottenere veJCD senza dover gestire direttamente il contratto veJCD.

### 5. Considerazioni sulla Governance

#### Aggiunta del Pool su Curve

* Acquisire CRV e lockarlo per ottenere veCRV.
* Proporre il nuovo pool attraverso la governance di Curve Curve DAO.

**Esempio**: Creare una proposta per aggiungere un pool JCD/ETH, specificando i token, il tipo di pool e i parametri. Richiede un quorum del 15% per l'approvazione.

#### Governance Interna

* Utilizzare veJCD per permettere ai detentori di votare su proposte interne (es. cambiamenti nei parametri del pool).
* Implementare un sistema semplice di governance con Aragon o un contratto DAO personalizzato.

### 6. Risorse Open-Source

* **Curve Contracts**: Curve Contract GitHub per i template dei pool.
* **Yearn veYFI**: veYFI GitHub per il contratto veToken.
* **StakeDAO**: StakeDAO Docs per i liquid lockers.
* **macarena.finance**: macarena.finance GitHub per il frontend.

### 7. Tabelle Riepilogative

#### Componente | Descrizione | Risorse Open-Source

| Componente            | Descrizione                                                                      | Risorse Open-Source     |
| --------------------- | -------------------------------------------------------------------------------- | ----------------------- |
| Pool Personalizzato   | Deployare un pool JCD/ETH usando template Curve, tipo plain-2                    | Curve Contracts         |
| Sistema di Ricompense | Contratto per distribuire JCD ai LP, ispirato a Curve                            | Fork di LiquidityGauge  |
| Token di Governance   | Forkare veYFI per creare veJCD, usato per governance e boost                     | veYFI GitHub            |
| Frontend              | Forkare macarena.finance, modificare per interagire con contratti personalizzati | macarena.finance GitHub |
| Integrazione StakeDAO | Usare liquid lockers per gestire veJCD                                           | StakeDAO Docs           |

#### Passaggio | Azioni | Strumenti

| Passaggio                   | Azioni                                                               | Strumenti                               |
| --------------------------- | -------------------------------------------------------------------- | --------------------------------------- |
| Deploy Pool                 | Configurare pooldata.json, testare con Brownie, deployare su mainnet | Hardhat, Foundry, Brownie               |
| Deploy Contratto Ricompense | Creare e deployare contratto per distribuire JCD                     | Solidity, Hardhat                       |
| Deploy veJCD                | Forkare veYFI, adattare per JCD, deployare                           | Solidity, veYFI GitHub                  |
| Sviluppare Frontend         | Forkare macarena.finance, modificare componenti                      | React, Next.js, macarena.finance GitHub |
| Integrazione StakeDAO       | Configurare liquid lockers per veJCD                                 | StakeDAO Docs                           |

### 8. Conclusione

Per l'MVP, è consigliabile:

* Deployare un pool personalizzato utilizzando i contratti open-source di Curve.
* Implementare un sistema di ricompense con JCD.
* Creare veJCD per la governance e i boost.
* Forkare macarena.finance per il frontend.
* Integrare StakeDAO per la gestione dei liquid lockers.

In futuro, si può lavorare per aggiungere il pool a Curve attraverso la governance, permettendo l'accesso al sistema ufficiale di gauge e bribe. Questo approccio combina la rapidità dello sviluppo dell'MVP con la flessibilità delle infrastrutture open-source, garantendo un prodotto funzionante che può essere scalato nel tempo.

---

### Key Citations

* Curve Contract GitHub for pool templates
* veYFI GitHub for veToken contract
* StakeDAO Docs for liquid lockers
* macarena.finance GitHub for frontend
* Curve DAO for governance proposals
* DexScreener JCD for Uniswap pool
* Etherscan JCD token contract
* Etherscan SCHAP token contract
* Etherscan HAY token contract

---

## Curve Finance JCD/HAY/WETH TriCrypto

Ecco un percorso passo-passo per deployare via script una pool **tricrypto** JCD/HAY/WETH su Curve, sfruttando librerie JavaScript/TypeScript open-source (in particolare `@curvefi/api`).

Nel primo esempio useremo **Ethers.js** come provider e signer; in un secondo esempio vedremo come parametrizzare la pool in funzione dei prezzi minimi di LP su Uniswap.

### Sommario delle attività principali

1. **Prerequisiti**: Node.js, chiavi private, RPC URL e indirizzi token. ([GitHub][1])
2. **Installazione**: aggiungere `@curvefi/api` e `ethers` al progetto. ([GitHub][1])
3. **Script di deploy**: chiamata a `tricryptoFactory.deployPool(...)` con nome, simbolo, array di token, parametri di curva (A, γ, fees, etc.). ([GitHub][1], [docs.curve.fi][2])
4. **Parametri della pool**: scelta di valori ragionevoli per `A`, `gamma`, `fee`, `mid_fee`, `out_fee`, `allowed_extra_profit`, `withdrawal_fee`, `fee_gamma`, `adjustment_step`, `admin_fee`, e `ma_half_time`. ([GitHub][3])
5. **Verifica**: recupero dell’indirizzo della pool appena creata e testing locale via chiamate `getSeedAmounts` e `depositAndStake`. ([GitHub][1])
6. **Prossimi passi**: integrazione Yearn, gauge e bribe su Curve DAO. ([resources.curve.fi][4])

---

### 1. Prerequisiti

* **Node.js & npm** installati (v16+ consigliato).
* **RPC URL** di Ethereum (Mainnet o testnet).
* **Chiave privata** di un account con fondi per pagare gas.
* **Indirizzi token**:

  * JCD: `0x0Ed024d39d55e486573EE32e583bC37Eb5A6271f` ([OSL][5])
  * HAY: `0xfA3E941D1F6B7b10eD84A0C211bfA8aeE907965e` ([OSL][5])
  * WETH: `0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2` ([GitHub][1])

---

### 2. Installazione delle dipendenze

```bash
npm install @curvefi/api ethers dotenv
```

* `@curvefi/api`: wrapper per chiamate a factory e pool Curve ([GitHub][1])
* `ethers`: interazione con Ethereum RPC ([GitHub][1])
* `dotenv`: caricamento variabili d’ambiente (RPC\_URL, PRIVATE\_KEY)

---

### 3. Script di deploy (TypeScript)

```ts
import { ethers } from 'ethers';
import curve from '@curvefi/api';
import * as dotenv from 'dotenv';
dotenv.config();

async function main() {
  // 1. Inizializza provider e signer
  const provider = new ethers.providers.JsonRpcProvider(process.env.RPC_URL);
  const signer = new ethers.Wallet(process.env.PRIVATE_KEY!, provider);

  // 2. Inizializza Curve API
  await curve.init('JsonRpc', { provider, signer }, { gasPrice: 0 });

  // 3. Definisci token e parametri pool
  const coins = [
    '0x0Ed024d39d55e486573EE32e583bC37Eb5A6271f', // JCD
    '0xfA3E941D1F6B7b10eD84A0C211bfA8aeE907965e', // HAY
    '0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2'  // WETH
  ];

  // Parametri ottimizzati per memecoin (esempio)
  const A = 400000;            // Ampiezza di curva :contentReference[oaicite:11]{index=11}
  const gamma = 0.0000725;     // Fattore di smoothing :contentReference[oaicite:12]{index=12}
  const midFee = 0.25;         // Fee interna (bps) :contentReference[oaicite:13]{index=13}
  const outFee = 0.45;         // Fee di output (bps) :contentReference[oaicite:14]{index=14}
  const allowedExtraProfit = 0.000002; // Extra profit cap :contentReference[oaicite:15]{index=15}
  const feeGamma = 0.00023;    // Gamma per fees :contentReference[oaicite:16]{index=16}
  const adjustmentStep = 0.000146; // Step di aggiustamento :contentReference[oaicite:17]{index=17}
  const adminFee = 600;        // Fee per amministratori (bps) :contentReference[oaicite:18]{index=18}
  const maHalfTime = [1700, 27000]; // Parametri moving average :contentReference[oaicite:19]{index=19}

  // 4. Deploy via tricryptoFactory
  console.log('Deploying JCD/HAY/WETH tricrypto pool...');
  const tx = await curve.tricryptoFactory.deployPool(
    'JCD-HAY-WETH Tricrypto',  // Nome della pool
    'jhw3CRV',                 // Simbolo
    coins,
    A,
    gamma,
    midFee,
    outFee,
    allowedExtraProfit,
    feeGamma,
    adjustmentStep,
    adminFee,
    maHalfTime
  );

  const receipt = await tx.wait();
  const poolAddress = await curve.tricryptoFactory.getDeployedPoolAddress(tx);
  console.log('Pool deployed at:', poolAddress);
}

main().catch(console.error);
```

* **`deployPool`** genera la pool sulla factory tricrypto di Curve ([GitHub][1], [docs.curve.fi][2])
* **Parametri** scelti in base alla volatilità elevata di memecoin ([GitHub][3])

---

### 4. Verifica e seed

Subito dopo il deploy, puoi ottenere gli importi seed raccomandati e fare un primo deposito + staking:

```ts
const poolId = await curve.tricryptoFactory.fetchRecentlyDeployedPool(poolAddress);
const pool = curve.getPool(poolId);

// Calcola importi iniziali per rapporto di prezzo
const seedAmounts = await pool.getSeedAmounts(1);  // ratio=1 per semplificare
console.log('Seed amounts:', seedAmounts);

// Deposita e stake
await pool.depositAndStake(seedAmounts);
console.log('Deposit & stake completed');
```

* `getSeedAmounts` restituisce valori nella stessa unità (es. JCD, HAY, WETH) ([GitHub][1])

---

### 5. Prossimi passi

* **Gauge & Bribe**: aggiungere pool a Curve DAO e creare gauge tramite [Curve Resources](https://resources.curve.fi/reward-gauges/creating-a-pool-gauge/) ([resources.curve.fi][4])
* **Integrazione Yearn**: creare vault Yearn attorno alla pool appena deployata (es. fork di `vault` template).
* **Admin UI**: costruire un pannello React/Next.js che invochi questi script via API (es. endpoint `/deploy`) e mostri status e log.

Questo workflow ti permette di deployare in pochi minuti una pool **JCD/HAY/WETH** ottimizzata per memecoin, interamente via script, pronta per l’integrazione con Yearn Finance e la governance Curve.

[1]: https://github.com/curvefi/curve-js?utm_source=chatgpt.com "curvefi/curve-js - GitHub"
[2]: https://docs.curve.fi/cryptoswap-exchange/cryptoswap/pools/crypto-pool/?utm_source=chatgpt.com "Crypto Pool - exchange - Curve Technical Docs"
[3]: https://github.com/curvefi/tricrypto-ng?utm_source=chatgpt.com "curvefi/tricrypto-ng: Automatic Market Maker (AMM) for ... - GitHub"
[4]: https://resources.curve.fi/reward-gauges/creating-a-pool-gauge/?utm_source=chatgpt.com "Creating a pool gauge - Curve Resources"
[5]: https://osl.com/academy/article/what-is-curve-finance-and-liquidity-pool-in-defi?utm_source=chatgpt.com "What Is Curve Finance and Liquidity Pool in DeFi? - OSL"
