const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Secure Vault System", function () {
  let authManager, vault;
  let owner, user, recipient;
  
  before(async function () {
    [owner, user, recipient] = await ethers.getSigners();

    // Deploy Contracts
    const Auth = await ethers.getContractFactory("AuthorizationManager");
    authManager = await Auth.deploy();
    
    const Vault = await ethers.getContractFactory("SecureVault");
    vault = await Vault.deploy(await authManager.getAddress());
    
    // Send 10 ETH to the vault
    await owner.sendTransaction({
        to: await vault.getAddress(),
        value: ethers.parseEther("10.0")
    });
  });

  it("Should allow withdrawal with valid signature", async function () {
    const amount = ethers.parseEther("1.0");
    const nonce = ethers.hexlify(ethers.randomBytes(32)); // Unique ID
    const deadline = Math.floor(Date.now() / 1000) + 3600; // 1 hour from now
    const chainId = (await ethers.provider.getNetwork()).chainId;
    const vaultAddr = await vault.getAddress();

    // 1. Create the data structure to sign (Must match Solidity exactly)
    const domain = {
        name: "SecureVaultAuth",
        version: "1",
        chainId: chainId,
        verifyingContract: await authManager.getAddress()
    };

    const types = {
        Authorization: [
            { name: "vault", type: "address" },
            { name: "recipient", type: "address" },
            { name: "amount", type: "uint256" },
            { name: "nonce", type: "bytes32" },
            { name: "deadline", type: "uint256" }
        ]
    };

    const values = {
        vault: vaultAddr,
        recipient: recipient.address,
        amount: amount,
        nonce: nonce,
        deadline: deadline
    };

    // 2. Sign the data (Off-chain)
    const signature = await owner.signTypedData(domain, types, values);

    // 3. Execute withdrawal (On-chain)
    await expect(vault.connect(user).withdraw(
        recipient.address,
        amount,
        nonce,
        deadline,
        signature
    )).to.changeEtherBalances(
        [vault, recipient],
        [ethers.parseEther("-1.0"), amount]
    );
  });
});