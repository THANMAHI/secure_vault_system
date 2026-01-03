#!/bin/sh

# 1. Install dependencies
npm install

# 2. Compile contracts
npx hardhat compile

# 3. Start local blockchain in background
npx hardhat node --hostname 0.0.0.0 &

# 4. Wait for blockchain to initialize
sleep 5

# 5. Deploy contracts
npx hardhat run scripts/deploy.js --network localhost

# 6. Keep container running
wait