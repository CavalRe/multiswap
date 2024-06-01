const hre = require("hardhat");

async function main() {
  const pool = await hre.ethers.deployContract(
    "Pool",
    [
      "Mulitswap",
      "β2",
      BigInt(5e17),
      BigInt(1e16),
      process.env.WRAPPED_NATIVE_TOKEN
    ],
    {}
  );

  await pool.waitForDeployment();
  console.log(`Pool deployed to ${pool.target}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
