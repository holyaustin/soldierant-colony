# Sample Hardhat 3 Beta Project (`mocha` and `ethers`)

This project showcases a Hardhat 3 Beta project using `mocha` for tests and the `ethers` library for Ethereum interactions.

To learn more about the Hardhat 3 Beta, please visit the [Getting Started guide](https://hardhat.org/docs/getting-started#getting-started-with-hardhat-3). To share your feedback, join our [Hardhat 3 Beta](https://hardhat.org/hardhat3-beta-telegram-group) Telegram group or [open an issue](https://github.com/NomicFoundation/hardhat/issues/new) in our GitHub issue tracker.

## Project Overview

This example project includes:

- A simple Hardhat configuration file.
- Foundry-compatible Solidity unit tests.
- TypeScript integration tests using `mocha` and ethers.js
- Examples demonstrating how to connect to different types of networks, including locally simulating OP mainnet.

## Usage

### Running Tests

To run all the tests in the project, execute the following command:

```shell
npx hardhat test
```

You can also selectively run the Solidity or `mocha` tests:

```shell
npx hardhat test solidity
npx hardhat test mocha
```

### Make a deployment to Sepolia

This project includes an example Ignition module to deploy the contract. You can deploy this module to a locally simulated chain or to Sepolia.

To run the deployment to a local chain:

```shell
npx hardhat ignition deploy ignition/modules/deployAll.ts
```

To run the deployment to Sepolia, you need an account with funds to send the transaction. The provided Hardhat configuration includes a Configuration Variable called `PRIVATE_KEY`, which you can use to set the private key of the account you want to use.

You can set the `PRIVATE_KEY` variable using the `hardhat-keystore` plugin or by setting it as an environment variable.

To set the `PRIVATE_KEY` config variable using `hardhat-keystore`:

```shell
npx hardhat keystore set PRIVATE_KEY
```

After setting the variable, you can run the deployment with the Sepolia network:

```shell
npx hardhat run scripts/deploy-step-by-step.ts --network fuji
npx hardhat ignition deploy ignition/modules/DeployClean.ts --network fuji
npx hardhat ignition deploy ignition/modules/DeployAll.ts --network fuji
# Check balance then deploy
npx hardhat run scripts/check-balance.ts --network fuji && npx hardhat ignition deploy ignition/modules/DeployAll.ts --network fuji
```


5. How to Use
After Deploying to Fuji Testnet:
First, deploy your contracts and note the addresses:

bash
npx hardhat ignition deploy ignition/modules/DeployAll.ts --network fuji
Update the addresses in scripts/verify-contracts.ts with your deployed addresses

Run the verification script:

bash
# Verify all contracts at once
npm run verify:fuji

# Or verify individually
npm run verify:honeydew fuji <CONTRACT_ADDRESS>
npm run verify:antnft fuji <CONTRACT_ADDRESS>
After Deploying to Avalanche Mainnet:
bash
# Verify all contracts at once
npm run verify:mainnet

# Or verify individually
npm run verify:honeydew avalanche <CONTRACT_ADDRESS>
npm run verify:antnft avalanche <CONTRACT_ADDRESS>
6. Direct CLI Verification (Alternative)
You can also verify directly without scripts:

bash
# For Fuji Testnet
npx hardhat verify --network fuji <CONTRACT_ADDRESS>

# For Mainnet
npx hardhat verify --network avalanche <CONTRACT_ADDRESS>

# With constructor arguments (if needed)
npx hardhat verify --network fuji <CONTRACT_ADDRESS> "arg1" 1000



[ DeployClean ] successfully deployed 🚀

Deployed Addresses

DeployClean#HoneyDewToken - 0xF57f5574F215fe487Fdd775738aA622Cb9fd613E
DeployClean#AntNFT - 0x9Dd61625c4A99d83C3d66f049fd322ddBDCD1DD1
DeployClean#ColonyManager - 0xCe9Cf94ee8C33AeeC2C901bE7759a111E09Fe081
DeployClean#TerritoryStaking - 0xECC1FafeE3E1E58e563BE21e4965e2fFe0c4a2f5
DeployClean#TournamentSystem - 0xB0dfacc57e3Eb84d21aAD8ee35FD8bF7ef7fdc32

[ DeployAll ] successfully deployed 🚀

Deployed Addresses

DeployAll#HoneyDewToken - 0xFD945D4F40479106Ef3Bb857E72e2ea5b7d742EB
DeployAll#AntNFT - 0x4158173D4333537e719523dFd0309785B9bBB2FC
DeployAll#ColonyManager - 0x7d6123df397D847539fa597B4D74bD5C3e7B9d54
DeployAll#TerritoryStaking - 0xA27aFFA1e4CB64C415C6707a78f24c7E21D43c6A
DeployAll#TournamentSystem - 0x31602660411B6e83e78dFCCE4e0B6C2446Ac5Fa8

