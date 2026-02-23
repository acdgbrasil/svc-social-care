#!/usr/bin/env bun
import { $ } from "bun";

const rootDir = Bun.fileURLToPath(new URL("../../", import.meta.url)).replace(
  /[\\/]+$/,
  "",
);
const outDir = process.env.CONTRACTS_OUT_DIR ?? `${rootDir}/.contracts`;
const tmpDir = process.env.CONTRACTS_TMP_DIR ?? `${rootDir}/.contracts-tmp`;
const contractsRef =
  process.env.CONTRACTS_REF ?? "ghcr.io/acdgbrasil/contracts:v1.0.0";
const localContractsDir = process.env.CONTRACTS_LOCAL_DIR;

function fail(message: string): never {
  console.error(message);
  process.exit(1);
}

async function ensureExists(path: string, hint: string): Promise<void> {
  const check = await $`ls ${path}`.nothrow().quiet();
  if (check.exitCode !== 0) {
    fail(hint);
  }
}

async function main(): Promise<void> {
  await $`rm -rf ${outDir} ${tmpDir}`;
  await $`mkdir -p ${outDir} ${tmpDir}`;

  if (localContractsDir) {
    console.log(`Using local contracts from: ${localContractsDir}`);

    await ensureExists(
      localContractsDir,
      `Local contracts directory not found: ${localContractsDir}`,
    );

    const requiredEntries = ["README.md", "services", "shared"];
    for (const entry of requiredEntries) {
      const source = `${localContractsDir}/${entry}`;
      await ensureExists(
        source,
        `Expected local contracts entry not found: ${source}`,
      );
      await $`cp -R ${source} ${outDir}/${entry}`;
    }
  } else {
    if (!Bun.which("oras")) {
      fail("oras CLI not found. Install ORAS or set CONTRACTS_LOCAL_DIR.");
    }

    console.log(`Pulling contracts artifact: ${contractsRef}`);
    await $`oras pull ${contractsRef} --output ${tmpDir}`;

    const bundlePath = (
      await $`find ${tmpDir} -type f -name "contracts-*.tgz" | sort | head -n 1`.text()
    ).trim();

    if (!bundlePath) {
      fail("No contracts bundle (*.tgz) found in pulled artifact.");
    }

    await $`tar -xzf ${bundlePath} -C ${outDir}`;
  }

  const specPath = `${outDir}/services/social-care/openapi/openapi.yaml`;
  await ensureExists(specPath, `Expected spec not found: ${specPath}`);

  console.log(`Contracts ready at: ${outDir}`);
}

await main();
