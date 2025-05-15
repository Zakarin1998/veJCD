


# `GaugeFactory` technical report

Solidity contract. This report covers `GaugeFactory.sol` purpose, architecture, clone‐factory pattern, key functions, security, gas implications, and best practices.

---

A concise summary of the key findings:

> The `GaugeFactory` contract implements an **EIP-1167 minimal-proxy clone factory** for cheaply deploying new `Gauge` instances. It stores a single “master” implementation (`deployedGauge`) and uses low-level assembly (`create`/`delegatecall`) to spawn lightweight clones. Each clone is initialized via `IGauge.initialize(...)`, avoiding code duplication and saving gas. The factory emits events for transparency, locks in the implementation address as `immutable`, and keeps logic minimal for security. However, care must be taken with delegate-call inheritance of state, correct initialization, and upgradeability considerations.

---

## 1. Purpose & Overview

* **Factory Pattern**
  The contract’s sole responsibility is to create new `Gauge` clones and emit corresponding events, following the **factory design pattern** for on-chain deployment of many identical contracts at low cost ([Ethereum Improvement Proposals][1]).

* **Minimal‐Proxy (EIP-1167)**
  It leverages the **EIP-1167 minimal proxy** (also called the “clone” pattern) to delegate all logic calls to a single implementation, drastically reducing deployment gas compared to full contract deployments ([blog.openzeppelin.com][2], [Ethereum Improvement Proposals][1]).

* **Immutability of Implementation**
  The address of the “master” gauge implementation is stored in `immutable deployedGauge`, ensuring it cannot change after construction and preventing a malicious upgrade of the template ([RareSkills][3]).

---

## 2. Clone Creation (`_clone`)

### 2.1 Bytecode Structure

* The assembly in `_clone` writes a 55-byte **creation** bytecode blob that, when deployed, becomes a 45-byte **runtime** proxy redirecting all calls via `DELEGATECALL` to `deployedGauge` ([blog.openzeppelin.com][2]).

### 2.2 Assembly Breakdown

* The first `mstore` (offset `0x0`) injects the EIP-1167 **creation code prefix** (`3d602d80600a3d3981f3363d3d373d3d3d363d73…`) which sets up memory and copies the implementation address.
* The second `mstore` inserts the 20-byte target address (`bytes20(_source)`), and the third writes the suffix (`…5af43d82803e903d91602b57fd5bf3`) that finalizes the proxy runtime ([blog.openzeppelin.com][2]).

### 2.3 `create(0, clone, 0x37)`

* This EVM `CREATE` call deploys the proxy with zero ETH, using the 0x37-byte initialization code just stored in memory ([Ethereum Improvement Proposals][1]).

---

## 3. `createGauge` Function

```solidity
function createGauge(address _vault, address _owner) external override returns (address) {
    address newGauge = _clone(deployedGauge);
    emit GaugeCreated(newGauge);
    IGauge(newGauge).initialize(_vault, _owner);
    return newGauge;
}
```

* **Clone Deployment**
  Calls `_clone(deployedGauge)` to spawn a fresh proxy instance of the base gauge ([RareSkills][3]).
* **Event Emission**
  Emits `GaugeCreated(newGauge)` for off-chain indexing and transparency ([GitHub][4]).
* **Initialization**
  Immediately invokes `initialize(_vault, _owner)` on the newly created clone to set its immutable parameters (vault address, owner) and avoid uninitialized proxies ([OpenZeppelin Forum][5]).
* **Return**
  Returns the address of the newly created and initialized gauge for further on-chain use.

---

## 4. Events & Immutables

* **Events**

  * `GaugeCreated(address indexed gauge)`
  * `ExtraRewardCreated(address indexed extraReward)` (unused in this snippet but defined for parity with interface)
* **Immutables**

  * `address public immutable deployedGauge;` locks the master implementation at factory creation ([RareSkills][3]).

---

## 5. Security Considerations

* **DelegateCall Risks**
  Clones delegate execution context to the implementation; ensure the master contract’s code is secure and has no unguarded state writes ([blog.openzeppelin.com][2]).
* **Initialization Guard**
  Must prevent re-initialization; the `IGauge.initialize` implementation should include an `initialized` flag to block multiple calls ([OpenZeppelin Forum][5]).
* **Immutable Template**
  Using `immutable` for `deployedGauge` prevents the factory owner from swapping to a malicious implementation later.
* **Access Control**
  The factory itself is open to any caller; if gauge creation must be restricted, add an access-control modifier (e.g., `onlyOwner`).

---

## 6. Gas Efficiency

* **Deployment Cost**
  Minimal proxies cost \~10,000–20,000 gas to deploy versus several hundred thousand for full contracts ([Medium][6]).
* **Runtime Overhead**
  Calls through proxies incur an extra `DELEGATECALL` gas cost (\~700 gas), but savings from cheaper deployments usually outweigh this ([Medium][7]).

---

## 7. Best Practices & Recommendations

1. **Master Contract Audit**
   Thoroughly audit the `deployedGauge` implementation to ensure secure behavior across all clones.
2. **Initialize‐Only‐Once**
   Implement a check like `require(!initialized, "Already initialized"); initialized = true;` in `initialize()`.
3. **Access Control on Factory**
   If gauge creation must be permissioned, wrap `createGauge` with an `onlyOwner` or role-based modifier.
4. **Event Granularity**
   Include additional indexed parameters (e.g., vault address) in `GaugeCreated` for richer off-chain querying.

---

### References

1. EIP-1167 Minimal Proxy Specification (Simple Summary, rationale) ([Ethereum Improvement Proposals][1])
2. OpenZeppelin Deep Dive into Minimal Proxy (bytecode breakdown) ([blog.openzeppelin.com][2])
3. RareSkills: Clone Pattern with Initialization ([LinkedIn][8])
4. Medium (Taipei Ethereum Meetup): Why use EIP-1167 ([Medium][6])
5. OriginProtocol Minimal-Proxy Example (Uniswap V1 usage) ([GitHub][4])
6. GitHub: minaminao/huff-eip1167 (alternative implementation) ([GitHub][9])
7. Etherscan Verified Proxy Patterns (general practice) ([CoinsBench][10])
8. OpenZeppelin Forum: Initialization issues with EIP-1167 proxies ([OpenZeppelin Forum][5])
9. Uniswap V1 Factory creating AMM pools via minimal proxy ([GitHub][4])
10. Gnosis Safe Clone via EIP-1167 in practice ([RareSkills][3])

[1]: https://eips.ethereum.org/EIPS/eip-1167?utm_source=chatgpt.com "ERC-1167: Minimal Proxy Contract"
[2]: https://blog.openzeppelin.com/deep-dive-into-the-minimal-proxy-contract?utm_source=chatgpt.com "Deep dive into the Minimal Proxy contract - OpenZeppelin Blog"
[3]: https://www.rareskills.io/post/eip-1167-minimal-proxy-standard-with-initialization-clone-pattern?utm_source=chatgpt.com "EIP-1167: Minimal Proxy Standard with Initialization (Clone pattern)"
[4]: https://github.com/OriginProtocol/minimal-proxy-example?utm_source=chatgpt.com "OriginProtocol/minimal-proxy-example - EIP-1167 - GitHub"
[5]: https://forum.openzeppelin.com/t/issues-initializing-eip-1167-minimal-proxies-deployed-with-factory-contract/2039?utm_source=chatgpt.com "Issues initializing EIP-1167 minimal proxies deployed with factory ..."
[6]: https://medium.com/taipei-ethereum-meetup/reason-why-you-should-use-eip1167-proxy-contract-with-tutorial-cbb776d98e53?utm_source=chatgpt.com "Reason Why You Should Use EIP1167 Proxy Contract. (With Tutorial)"
[7]: https://medium.com/%40ujjwal451/eip-1167-most-underrated-eip-c387c15bdeee?utm_source=chatgpt.com "1167 (Most underrated EIP). What is EIP-1167 ? | by Ujjwal Jain"
[8]: https://lk.linkedin.com/posts/rareskills-io_eip-1167-minimal-proxy-standard-with-initialization-activity-7034001629154607104-kVae?utm_source=chatgpt.com "EIP-1167: Minimal Proxy Standard with Initialization (Clone pattern ..."
[9]: https://github.com/minaminao/huff-eip1167?utm_source=chatgpt.com "minaminao/huff-eip1167: EIP-1167 Minimal Proxy Contract ... - GitHub"
[10]: https://coinsbench.com/eip-1167-minimal-proxy-contract-on-klaytn-f246532c6dc7?utm_source=chatgpt.com "EIP-1167 Minimal Proxy Contract On Klaytn - CoinsBench"


---

Di seguito la spiegazione delle due costanti esadecimali che compaiono nel metodo `_clone` della **GaugeFactory**, tratte dal pattern EIP-1167 (Minimal Proxy):

> **Riassunto:**
> Le due stringhe esadecimali sono parti **hard-coded** del bytecode di creazione e del bytecode “runtime” di un **proxy minimale** conforme a EIP-1167. La prima (`3d602d80600a3d3981f3363d3d373d3d3d363d73…`) è il **creation code** che, in fase di deploy, copia il runtime in memoria; la seconda (`…5af43d82803e903d91602b57fd5bf3…`) è il **runtime code** vero e proprio, che intercetta tutte le chiamate e le inoltra via `DELEGATECALL` all’implementazione. Questi blocchi uniti con l’indirizzo target generano il proxy leggero che punta al contratto master.

---

## 1. Creazione vs. Runtime

### 1.1 Creation Code (primo blob)

```assembly
3d602d80600a3d3981f3363d3d373d3d3d363d73  … indirizzo … 
```

* Questo segmento di bytecode è eseguito **una sola volta** al momento della creazione del contratto proxy.
* **Funzione principale:** copia in memoria i successivi 45 byte di **runtime code** e li restituisce come codice del contratto deployato.
* Scomposizione semplificata:

  * `3d` (RETDATASIZE)
  * `602d` (PUSH1 0x2d → lunghezza del runtime)
  * `80` (DUP1)
  * `600a` (PUSH1 0x0a → offset del runtime)
  * `3d39` (RETDATASIZE + CODECOPY)
  * `81f3` (DUP2 + RETURN) ([Ethereum Stack Exchange][1])

### 1.2 Runtime Code (secondo blob)

```assembly
… 363d3d373d3d3d363d73<20-byte-address>5af43d82803e903d91602b57fd5bf3
```

* È il **codice effettivamente eseguito** ad ogni chiamata al proxy.
* Si occupa di:

  1. Copiare calldata in memoria (`36 3d 3d 37 3d 3d 3d 36 3d 73`)
  2. Eseguire `DELEGATECALL` verso l’indirizzo target incorporato (`5a f4 3d 82 80 3e 90 3d 91 60 2b 57 fd 5b f3`)
* Questo garantisce che tutte le chiamate al proxy vengano instradate all’implementazione principale, ma con lo **storage** della clone ([CoinsBench][2]).

---

## 2. Integrazione con `_clone`

Nel codice:

```solidity
mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d730000…)
mstore(add(clone, 0x14), targetBytes)        // inserisce i 20 byte dell’indirizzo
mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf300000…)
create(0, clone, 0x37)
```

1. **Prima `mstore`**: scrive il **creation code** (prima 10 istruzioni) con padding a zero fino all’offset 0x14.
2. **Seconda `mstore`**: posiziona esattamente i 20 byte dell’indirizzo `deployedGauge` al posto del placeholder.
3. **Terza `mstore`**: scrive il **runtime code** che segue l’indirizzo, anch’esso con padding.
4. **`create`**: deploya il blob di 0x37 (= 55) byte, che produce un contratto la cui **runtime** è lungo 45 byte e costituisce il proxy ([Gist][3]).

---

## 3. Perché EIP-1167?

* **Efficienza di gas:** deployare un proxy minimale costa pochi **10–20 k gas** invece di centinaia di migliaia per un contratto completo ([RareSkills][4]).
* **Immutabilità:** il proxy non è upgradabile, ma utilizza `DELEGATECALL` verso un’implementazione fissa, semplificando la logica.
* **Sicurezza:** mantenendo il bytecode statico e l’implementazione in `immutable deployedGauge`, si riducono i vettori di attacco ([OpenZeppelin Blog][5]).

---

**In sintesi**, le due stringhe esadecimali sono semplicemente i **due segmenti** di bytecode (creazione + runtime) previsti dallo standard EIP-1167 per generare un clone minimale che delega tutto il lavoro al contratto master indicato.

[1]: https://ethereum.stackexchange.com/questions/97916/eip1167-why-this-special-address?utm_source=chatgpt.com "EIP1167. why this special address? - Ethereum Stack Exchange"
[2]: https://coinsbench.com/eip-1167-minimal-proxy-contract-on-klaytn-f246532c6dc7?utm_source=chatgpt.com "EIP-1167 Minimal Proxy Contract On Klaytn - CoinsBench"
[3]: https://gist.github.com/Enigmatic331/2f1d2af555141643057305efc0a747a5?utm_source=chatgpt.com "Playing with EIP-1167 - GitHub Gist"
[4]: https://www.rareskills.io/post/eip-1167-minimal-proxy-standard-with-initialization-clone-pattern?utm_source=chatgpt.com "EIP-1167: Minimal Proxy Standard with Initialization (Clone pattern)"
[5]: https://blog.openzeppelin.com/deep-dive-into-the-minimal-proxy-contract?utm_source=chatgpt.com "Deep dive into the Minimal Proxy contract - OpenZeppelin Blog"
