const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying contracts with account:", deployer.address);

  // 1. Deploy Authorization Manager
  const AuthManager = await hre.ethers.getContractFactory("AuthorizationManager");
  const authManager = await AuthManager.deploy();
  await authManager.waitForDeployment();
  const authAddr = await authManager.getAddress();
  console.log("AuthorizationManager deployed to:", authAddr);

  // 2. Deploy Vault (linked to Manager)
  const SecureVault = await hre.ethers.getContractFactory("SecureVault");
  const vault = await SecureVault.deploy(authAddr);
  await vault.waitForDeployment();
  const vaultAddr = await vault.getAddress();
  console.log("SecureVault deployed to:", vaultAddr);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});