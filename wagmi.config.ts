import { defineConfig } from "@wagmi/cli";
import { foundry } from "@wagmi/cli/plugins";

import latestRun from "./broadcast/Deploy.s.sol/84531/deploy-latest.json";

/**
 * We get contract addresses from our latest Base mainnet deployments.
 * Because of CREATE2, all except EphemeralNotes are deterministic.
 */
const deployments = Object.fromEntries(
    latestRun.transactions
    .filter((t) => t.transactionType === "CREATE2")
    .map((r) => [r.contractName, r.contractAddress as `0x${string}`])
);

export default defineConfig({
  out: "ts/generated.ts",
  plugins: [
    foundry({
      project: ".",
      deployments,
      include: ["BundleBulker.sol/*", "Daimo*.sol/*"],
    }),
  ],
});
