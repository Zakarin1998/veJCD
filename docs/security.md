
# Report Security Smart Contract Oracle Price

Below è un’analisi di sicurezza focalizzata sul rischio di **manipolazione del prezzo mediante oracoli** nei contratti Yearn (e simili), e su come un attaccante potrebbe “svuotare” reward o destabilizzare il sistema.

> **Sintesi dei punti chiave:**
>
> 1. **Dipendenza dagli oracoli** (Chainlink, Uniswap-TWAP, The Graph) espone i contratti a **flash-loan** o **single-block attacks** che alterano temporaneamente i prezzi on-chain, permettendo riscatti o claims a valori falsati ([Banca del Canada][1], [Cryptology ePrint Archive][2]).
> 2. Protocolli come Yearn spesso usano **share-price** calcolati on-chain (rapporto totale asset/total shares); simili meccanismi sono vulnerabili a manipolazioni della **liquidity pool** sottostante ([Cointelegraph][3], [101 Blockchains][4]).
> 3. Un fork che replichi la logica di Yearn (pool, gauge, redeem) può subire gravi perdite se l’oracolo è manomesso: aumentando istantaneamente il prezzo, un attaccante potrebbe **riscattare token con sconti eccessivi**, drenando riserve o reward ([CoinDesk][5], [Medium][6]).
> 4. **Mitigazioni**: usare oracoli **time-weighted** (TWAP multi-block), **medians** di più feed, **circuit breakers**, e meccanismi di **fallback** in caso di anomalie di prezzo ([Banca del Canada][1], [Cryptology ePrint Archive][2]).

---

## 1. Vettori di Attacco con Oracoli

### 1.1 Flash-Loan e Single-Block Manipulation

* **Flash-loan**: un attaccante può prendere in prestito grandi somme, spostare il prezzo in una pool (ad es. Uniswap), e forzare l’oracolo on-chain a restituire quel valore manipolato **nello stesso blocco** ([Cointelegraph][3], [Cryptology ePrint Archive][2]).
* **Single-block Attack**: come descritto in ProMutator, anche un singolo blocco è sufficiente perché l’oracolo riporti il prezzo contraffatto, consentendo l’exploit immediato senza preavviso ([Cryptology ePrint Archive][2]).

### 1.2 Pool-Based Oracle Manipulation

* Oracoli basati su pool (es. ratio reserve/token) sono soggetti a **“donation”** o depositi massivi e ritiro, falsando il rapporto riserve/token e quindi il prezzo usato dal contratto ([Banca del Canada][1]).

---

## 2. Impatto sui Contratti Yearn-Like

### 2.1 Redemption e Reinvestimenti

Contratti come `Redemption.vy` (calcolo di `eth_required` e `discount()`) si affidano a Chainlink:

```python
price = PRICE_FEED.latestRoundData()  # netto prezzo JCD/ETH
```

Se l’oracolo è manipolato, `eth_required` può scendere drasticamente, permettendo riscatti economici e drenando JCD da riserve ([Banca del Canada][1]).

### 2.2 Share-Price Vaults

I vault Yearn usano:

```
pricePerShare = totalAssets / totalSupply
```

Se `totalAssets` è calcolato su pool manipolato (es. Uniswap), un attaccante può **mintare** o **burnare** vault shares al valore errato e rubare valori reali ([101 Blockchains][4]).

### 2.3 Gauge Rewards

I gauge reward distribution può essere forzata da manipolazioni di prezzo:

* Aumento artificiale del prezzo del token gauge → boost temporanei → accumulo reward ingiustificato → “svuotamento” dei reward pool ([CoinDesk][5], [Medium][6]).

---

## 3. Esempi di Attacchi Real-World

| Protocollo             | Metodo                         | Perdite                        |
| ---------------------- | ------------------------------ | ------------------------------ |
| KiloEx (apr 2025)      | Oracle Manipulation multireti  | \$7 M     ([CoinDesk][5])      |
| Inverse Finance (2022) | Flash-loan su LP oracle        | \$1.2 M   ([Cointelegraph][3]) |
| Vesper (2021)          | Oracle single-block su Uniswap | \~\$1 M    ([Medium][6])       |

---

## 4. Mitigazioni e Best Practices

1. **Oracoli Time-Weighted (TWAP) Multi-Block**

   * Calcolare medie su N blocchi (es. 30–60) per ridurre l’efficacia di manipulazioni instantanee ([Cryptology ePrint Archive][2]).

2. **Aggregazione di Feed (Median/Aggregator)**

   * Usare mediane tra più oracoli (Chainlink, Band, custom) per filtrare outlier ([Banca del Canada][1]).

3. **Circuit Breakers & Fallback**

   * Se variazione > X% in breve tempo, bloccare funzioni critiche o ricorrere a valore su fallback oracolo non on-chain ([101 Blockchains][4]).

4. **Access Control e Whitelisting**

   * Limitare chi può richiamare funzioni sensibili (riscatti, claims) durante anomalie di prezzo.

5. **Monitoraggio On-Chain**

   * Script off-chain per rilevare improvvisi spike di prezzo e inviare transazioni di emergency shutdown.

---

## 5. Raccomandazioni per il Security Audit

* **Revisione Oracoli**: Verificare che tutti i feed usati (Chainlink, Uniswap-TWAP, The Graph) implementino filtri anti-manipolazione e fallback.
* **Test di Stress**: Simulare flash-loan e single-block attacks in testnet per validare le contromisure.
* **Código Init**: Assicurarsi che non esistano initialization-reentry paths che permettano di bypassare check di prezzo.
* **Threshold Tuning**: Definire soglie di slippage e variazione massima (es. ±0.3% è spesso troppo stretto se l’oracolo non ha TWAP multi-block).

Con queste misure, anche un eventuale fork “alla Yearn” potrà resistere a manipolazioni di prezzo e a tentativi di svuotamento dei reward pool.

[1]: https://www.bankofcanada.ca/wp-content/uploads/2024/07/sdp2024-10.pdf?utm_source=chatgpt.com "[PDF] Analysis of DeFi Oracles - Bank of Canada"
[2]: https://eprint.iacr.org/2022/445.pdf?utm_source=chatgpt.com "[PDF] TWAP Oracle Attacks: Easier Done than Said?"
[3]: https://cointelegraph.com/news/inverse-finance-exploited-again-for-1-2m-in-flashloan-oracle-attack?utm_source=chatgpt.com "Inverse Finance exploited again for $1.2M in flash loan oracle attack"
[4]: https://101blockchains.com/most-common-smart-contract-vulnerabilities/?utm_source=chatgpt.com "Most Common Smart Contract Vulnerabilities And How to Mitigate ..."
[5]: https://www.coindesk.com/markets/2025/04/15/dex-kiloex-loses-usd7m-in-apparent-oracle-manipulation-attack?utm_source=chatgpt.com "KiloEx Loses $7M in Apparent Oracle Manipulation Attack - CoinDesk"
[6]: https://medium.com/beaver-smartcontract-security/defi-security-lecture-7-price-oracle-manipulation-d716cdeaaf77?utm_source=chatgpt.com "DeFi Security Lecture 7 —Price Oracle Manipulation - Medium"
