## Bulk

**Make compressed 4337 bundles swole again.**

Bulk makes 4337 on L2 cheaper. Bundlers can pass compressed bundles to `BundleBulker`, which decompresses them before calling the 4337 EntryPoint contract. This reduces L1 data usage, the dominant cost of rollup transactions.

For example, here's a single USDC transfer executed as as a one-op bundle.

Before: [**1.6kb**](https://twitter.com/adietrichs/status/1725280716290773117)

After: [**353b**](https://docs.google.com/spreadsheets/d/1rf3AJMmm9BCkBsmQiRq4yP3Zhne9vIW-ib0Dp4QD2Tw/edit)

## Details

Decompression happens via arbitrary contracts that implement `IInflator`. This lets bundlers or individual applications can define their own templates or decompression algorithms. Inflators can be stateful for greater savings.

A bundler supports compression as follows:
- client submits compressed op
- bundler inflates, validates as usual
- bundler submits compressed

**Compression is independent from the security of the contract account being called.** The same userops go to the EntryPoint either way, validation and execution identical--this is just an optimization to use less calldata.

Bulk is intended for use directly by bundlers, eg with API keys--so griefing can be mitigated offchain. The userop mempool remains important for censorship resistance, and apps can continue to submit uncompressed ops to mempool as a fallback if a direct bundler API is unavailable.

## Deployment Details

The deployment address of BundleBulker is `0x000000000091A1F34f51CE866bEd8983dB51a97E`. (deployed using create2 with salt `7cf7a0f0060e1519d0ee3e12e0ee57890f69d7aa693404299a3a779e90cd7921`)

#### Mainnets

|Chain Name|Deployment|
|----------|----------|
|Ethereum|[0x000000000091A1F34f51CE866bEd8983dB51a97E](https://etherscan.io/address/0x000000000091A1F34f51CE866bEd8983dB51a97E)|
|Base|[0x000000000091A1F34f51CE866bEd8983dB51a97E](https://basescan.org/address/0x000000000091a1f34f51ce866bed8983db51a97e)|
|OP Mainnet|[0x000000000091A1F34f51CE866bEd8983dB51a97E](https://optimistic.etherscan.io/address/0x000000000091A1F34f51CE866bEd8983dB51a97E)|
|Polygon|[0x000000000091A1F34f51CE866bEd8983dB51a97E](https://polygonscan.com/address/0x000000000091A1F34f51CE866bEd8983dB51a97E)|
|Gnosis|[0x000000000091A1F34f51CE866bEd8983dB51a97E](https://gnosisscan.io/address/0x000000000091A1F34f51CE866bEd8983dB51a97E)|
|Arbitrum One|[0x000000000091A1F34f51CE866bEd8983dB51a97E](https://arbiscan.io/address/0x000000000091A1F34f51CE866bEd8983dB51a97E)|
|BNB Smart Chain|[0x000000000091A1F34f51CE866bEd8983dB51a97E](https://bscscan.com/address/0x000000000091a1f34f51ce866bed8983db51a97e)|
|opBNB|[0x000000000091A1F34f51CE866bEd8983dB51a97E](https://opbnbscan.com/address/0x000000000091A1F34f51CE866bEd8983dB51a97E)|
|Avalanche|[0x000000000091A1F34f51CE866bEd8983dB51a97E](https://snowtrace.io/address/0x000000000091A1F34f51CE866bEd8983dB51a97E/contract/43114/code)|
|Linea Mainnet|[0x000000000091A1F34f51CE866bEd8983dB51a97E](https://lineascan.build/address/0x000000000091A1F34f51CE866bEd8983dB51a97E)|
|lyra|[0x000000000091A1F34f51CE866bEd8983dB51a97E](https://explorer.lyra.finance/address/0x000000000091A1F34f51CE866bEd8983dB51a97E)|
|Scroll|[0x000000000091A1F34f51CE866bEd8983dB51a97E](https://scrollscan.com/address/0x000000000091A1F34f51CE866bEd8983dB51a97E)|
|Klaytn|[0x000000000091A1F34f51CE866bEd8983dB51a97E](https://klaytnscope.com/account/0x000000000091A1F34f51CE866bEd8983dB51a97E)|
|DFK Chain|[0x000000000091A1F34f51CE866bEd8983dB51a97E](https://subnets.avax.network/c-chain/address/0x000000000091A1F34f51CE866bEd8983dB51a97E)|
|Celo|[0x000000000091A1F34f51CE866bEd8983dB51a97E](https://celoscan.io/address/0x000000000091a1f34f51ce866bed8983db51a97e)|

#### Testnets

|Chain Name|Deployment|
|----------|----------|
|Sepolia|[0x000000000091A1F34f51CE866bEd8983dB51a97E](https://sepolia.etherscan.io/address/0x000000000091A1F34f51CE866bEd8983dB51a97E)|
|Goerli|[0x000000000091A1F34f51CE866bEd8983dB51a97E](https://goerli.etherscan.io/address/0x000000000091A1F34f51CE866bEd8983dB51a97E)|
|Base Sepolia|[0x000000000091A1F34f51CE866bEd8983dB51a97E](https://sepolia.basescan.org/address/0x000000000091A1F34f51CE866bEd8983dB51a97E)|
|Base Goerli|[0x000000000091A1F34f51CE866bEd8983dB51a97E](https://goerli.basescan.org/address/0x000000000091A1F34f51CE866bEd8983dB51a97E)|
|Optimism Goerli|[0x000000000091A1F34f51CE866bEd8983dB51a97E](https://goerli-optimism.etherscan.io/address/0x000000000091A1F34f51CE866bEd8983dB51a97E)|
|Polygon Mumbai|[0x000000000091A1F34f51CE866bEd8983dB51a97E](https://mumbai.polygonscan.com/address/0x000000000091A1F34f51CE866bEd8983dB51a97E)|
|Arbitrum Sepolia|[0x000000000091A1F34f51CE866bEd8983dB51a97E](https://sepolia.arbiscan.io/address/0x000000000091A1F34f51CE866bEd8983dB51a97E)|
|Arbitrum Goerli|[0x000000000091A1F34f51CE866bEd8983dB51a97E](https://goerli.arbiscan.io/address/0x000000000091A1F34f51CE866bEd8983dB51a97E)|
|Binance Smart Chain Testnet|[0x000000000091A1F34f51CE866bEd8983dB51a97E](https://testnet.bscscan.com/address/0x000000000091A1F34f51CE866bEd8983dB51a97E)|
|Avalanche Fuji|[0x000000000091A1F34f51CE866bEd8983dB51a97E](https://testnet.snowtrace.io/address/0x000000000091A1F34f51CE866bEd8983dB51a97E)|
|Scroll Sepolia|[0x000000000091A1F34f51CE866bEd8983dB51a97E](https://sepolia.scrollscan.dev/address/0x000000000091A1F34f51CE866bEd8983dB51a97E)|
|Gnosis Chiado|[0x000000000091A1F34f51CE866bEd8983dB51a97E](https://gnosis-chiado.blockscout.com/address/0x000000000091A1F34f51CE866bEd8983dB51a97E)|
|Linea Goerli Testnet|[0x000000000091A1F34f51CE866bEd8983dB51a97E](https://goerli.lineascan.build/address/0x000000000091A1F34f51CE866bEd8983dB51a97E)|
|Celo Alfajores|[0x000000000091A1F34f51CE866bEd8983dB51a97E](https://explorer.celo.org/alfajores/address/0x000000000091A1F34f51CE866bEd8983dB51a97E)|

## Quick start

**Proof of concept. In active development.**

```
git clone git@github.com:daimo-eth/bulk --recurse-submodules
foundryup
```

```
forge test
```

