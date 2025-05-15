## 🧾 **Report Tecnico – Redemption.vy**

Ecco un **report tecnico** del contratto `Redemption.vy`, che descrive la sua architettura, logica principale, funzionalità, e sicurezza.

---

**Versione:** Vyper `0.3.7`
**Funzione Principale:** Gestione della **redenzione di dJCD per JCD** utilizzando ETH
**Contesto d’Uso:** Sistema di stablecoin basato su collateralizzazione, sconto dinamico e controllo tramite governance.

---

### ✅ **Obiettivi del Contratto**

* Consentire agli utenti di **riscattare dJCD** in cambio di **JCD** pagando in **ETH**.
* Regolare il **prezzo di conversione** tramite un **sistema dinamico di sconto**.
* Raccogliere gli ETH in un indirizzo di **payee**.
* Offrire funzionalità di **governance** e **controllo di emergenza** (kill-switch, ramp scaling).

---

## 🔩 Componenti Principali

### 🪙 **Token Coinvolti**

| Token   | Interfaccia | Ruolo                                        |
| ------- | ----------- | -------------------------------------------- |
| `dJCD`  | `IDJCD`     | Token da bruciare per riscattare JCD         |
| `JCD`   | `ERC20`     | Token riscattato, da tenere in riserva       |
| `veJCD` | `ERC20`     | Token per il calcolo del rapporto di staking |
| `ETH`   | Nativo      | Usato per pagare la redenzione               |

---

### 🔗 **Oracolo Prezzo**

* **Interface:** `AggregatorV3Interface`
* **Funzione:** Determina il prezzo di JCD in ETH.
* **Protezione:** Richiede che il dato sia recente (entro 1 ora).

---

## 📊 **Funzionalità Chiave**

### `redeem(amount: uint256, recipient: address)`

* Redime `dJCD` in `JCD` usando `ETH`.
* Verifica lo slittamento massimo (`±0.3%`) tra prezzo oracolo e ETH fornito.
* Brucia `dJCD`, trasferisce `JCD`, e inoltra ETH al `payee`.

---

### 📉 `discount()`: Calcolo dello Sconto

**Formula:**

```
discount = 1 / (1 + 10 * e^(4.7 * (s * x - 1)))
dove:
  x = veJCD_supply / JCD_supply
  s = scaling_factor (modulabile nel tempo)
```

Questo schema consente di:

* Incentivare il lock di JCD in `veJCD`.
* Ridurre il prezzo effettivo di redenzione quando `veJCD/JCD` è basso.

---

## 🧮 **Meccanismo di Scaling Dinamico**

### Variabili:

* `packed_scaling_factor`: contiene in un unico `uint256` 4 valori:

  * `start`, `end`: timestamp d’inizio/fine ramp
  * `old`, `new`: valori iniziale e finale di scaling

### Funzioni correlate:

* `start_ramp`: inizia un ramp-up/down del fattore di scaling.
* `stop_ramp`: blocca la rampa.
* `_scaling_factor()`: calcola il valore interpolato del fattore di scala.

---

### 🧠 `exp()` – Esponenziale Naturale

Implementazione avanzata dell'esponenziale naturale `e^x` tramite:

* Approccio per segmenti con valori precalcolati (`A0–A11`)
* Taylor series per il resto.
* Ottimizzato per precisione con `20` decimali temporanei.

---

## ⚙️ **Governance e Sicurezza**

### Controllo di Proprietà (Ownable 2-Step)

* `owner`: attuale proprietario
* `pending_owner`: candidato nuovo proprietario
* `transfer_ownership`, `accept_ownership`: processo sicuro in due fasi

### `kill()`: Kill-switch

* Disattiva il contratto (non è più possibile riscattare).
* Recupera tutto il `JCD` al proprietario.
* Attivabile solo da `owner`.

### `sweep(token: address)`

* Permette al proprietario di recuperare token o ETH bloccati.
* `JCD` è protetto (non recuperabile se contratto non è "killed").

---

## 🔐 Sicurezza

| Feature            | Protezione                        |
| ------------------ | --------------------------------- |
| Slippage           | ±0.3% toleranza                   |
| Oracolo            | Validità entro 1 ora              |
| Protocolli Ownable | Accesso limitato a `owner`        |
| dJCD Burn          | Richiesto prima del riscatto      |
| Protezione kill    | Blocco irrevocabile del contratto |

---

## 📉 Rischi e Considerazioni

* **Oracolo:** Dipendenza forte da `PRICE_FEED`; manipolazioni possono causare perdite.
* **Discount Curve:** Parametrizzazione errata del `scaling_factor` può incentivare comportamenti speculativi.
* **Kill-switch:** Se attivato in modo malevolo o erroneo, blocca completamente le operazioni.

---

## 📌 Conclusione

`Redemption.vy` è un contratto solido e ben strutturato per il riscatto di una stablecoin, con:

* Prezzo dinamico basato sulla partecipazione in staking (`veJCD`).
* Protezioni anti-slippage, controllo del proprietario e meccanismi di emergenza.
* Ottimizzazione numerica per operazioni complesse come `e^x`.

---

Se desideri, posso prepararti:

* Una **analisi dei gas cost** per ogni funzione,
* Una **serie di test unitari** (in `pytest`),
* Oppure una **simulazione dell’andamento dello sconto** al variare del rapporto `veJCD/JCD`.

Fammi sapere!
