# YearnFinance - GaugeFactory.sol

```solidity
// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "./interfaces/IGauge.sol";
import "./interfaces/IExtraReward.sol";
import "./interfaces/IGaugeFactory.sol";

/** @title  GaugeFactory
    @notice Creates Gauge and ExtraReward
    @dev Uses clone to create new contracts
 */
contract GaugeFactory is IGaugeFactory {
    address public immutable deployedGauge;

    event GaugeCreated(address indexed gauge);
    event ExtraRewardCreated(address indexed extraReward);

    constructor(address _deployedGauge) {
        deployedGauge = _deployedGauge;
    }

    /** @notice Create a new reward Gauge clone
        @param _vault the vault address.
        @param _owner owner
        @return gauge address
    */
    function createGauge(
        address _vault,
        address _owner
    ) external override returns (address) {
        address newGauge = _clone(deployedGauge);
        emit GaugeCreated(newGauge);
        IGauge(newGauge).initialize(_vault, _owner);

        return newGauge;
    }

    function _clone(address _source) internal returns (address result) {
        bytes20 targetBytes = bytes20(_source);
        assembly {
            let clone := mload(0x40)
            mstore(
                clone,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            mstore(add(clone, 0x14), targetBytes)
            mstore(
                add(clone, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
            result := create(0, clone, 0x37)
        }
    }
}
```


## Riassunto
> Le due stringhe esadecimali sono parti **hard-coded** del bytecode di creazione e del bytecode “runtime” di un **proxy minimale** conforme a EIP-1167. La prima (`3d602d80600a3d3981f3363d3d373d3d3d363d73…`) è il **creation code** che, in fase di deploy, copia il runtime in memoria; la seconda (`…5af43d82803e903d91602b57fd5bf3…`) è il **runtime code** vero e proprio, che intercetta tutte le chiamate e le inoltra via `DELEGATECALL` all’implementazione. Questi blocchi uniti con l’indirizzo target generano il proxy leggero che punta al contratto master.

---

Di seguito la spiegazione delle due costanti esadecimali che compaiono nel metodo `_clone` della **GaugeFactory**, tratte dal pattern EIP-1167 (Minimal Proxy):

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
