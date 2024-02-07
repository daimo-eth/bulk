import { defineConfig } from "@wagmi/cli";
import { foundry } from "@wagmi/cli/plugins";

import latestBundle from "./broadcast/Deploy.s.sol/8453/deploy-latest.json";
import latestOp from "./broadcast/Deploy.s.sol/8453/deployPerOpInflator-latest.json";

/**
 * We get contract addresses from our latest Base mainnet deployments.
 * Because of CREATE2, all except EphemeralNotes are deterministic.
 */
const deployments = Object.fromEntries(
    [
      ...latestOp.transactions,
      ...latestBundle.transactions,
    ]
    .filter((t) => t.transactionType === "CREATE2")
    .map((r) => [r.contractName, r.contractAddress as `0x${string}`])
);

export default defineConfig({
  out: "ts/generated.ts",
  plugins: [
    foundry({
      project: ".",
      deployments,
      include: ["BundleBulker.sol/*", "PerOpInflator.sol/*", "Daimo*.sol/*"],
    }),
  ],
});
