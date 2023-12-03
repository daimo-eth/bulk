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


## Quick start

**Proof of concept. In active development.**

```
git clone git@github.com:daimo-eth/bulk --recurse-submodules
foundryup
```

```
forge test
```

