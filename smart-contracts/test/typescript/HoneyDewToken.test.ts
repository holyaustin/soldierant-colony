import { expect } from "chai";
import hre from "hardhat";
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { HoneyDewToken } from "../typechain-types";

describe("HoneyDewToken", function () {
  // Fixture to deploy the contract (as shown in the guide)
  async function deployHoneyDewTokenFixture() {
    // Get signers using hre.ethers (correct way from guide)
    const [owner, user1, user2] = await hre.ethers.getSigners();
    
    // Deploy contract
    const HoneyDewTokenFactory = await hre.ethers.getContractFactory("HoneyDewToken");
    const honeyDewToken = await HoneyDewTokenFactory.deploy();
    await honeyDewToken.waitForDeployment();
    
    return { honeyDewToken, owner, user1, user2 };
  }

  describe("Deployment", function () {
    it("Should set the right owner", async function () {
      const { honeyDewToken, owner } = await loadFixture(deployHoneyDewTokenFixture);
      expect(await honeyDewToken.owner()).to.equal(owner.address);
    });

    it("Should have correct name and symbol", async function () {
      const { honeyDewToken } = await loadFixture(deployHoneyDewTokenFixture);
      expect(await honeyDewToken.name()).to.equal("HoneyDew Token");
      expect(await honeyDewToken.symbol()).to.equal("SHNY");
    });

    it("Should have correct max supply", async function () {
      const { honeyDewToken } = await loadFixture(deployHoneyDewTokenFixture);
      const maxSupply = await honeyDewToken.MAX_SUPPLY();
      expect(maxSupply).to.equal(hre.ethers.parseEther("50000000"));
    });

    it("Should mint all tokens to contract", async function () {
      const { honeyDewToken } = await loadFixture(deployHoneyDewTokenFixture);
      const contractAddress = await honeyDewToken.getAddress();
      const contractBalance = await honeyDewToken.balanceOf(contractAddress);
      expect(contractBalance).to.equal(hre.ethers.parseEther("50000000"));
    });
  });

  describe("Emission", function () {
    it("Should emit daily tokens correctly", async function () {
      const { honeyDewToken } = await loadFixture(deployHoneyDewTokenFixture);
      
      // Use network.provider as shown in the guide
      await hre.network.provider.send("evm_increaseTime", [86400]);
      await hre.network.provider.send("evm_mine", []);
      
      await honeyDewToken.emitDailyTokens();
      
      const emittedSupply = await honeyDewToken.emittedSupply();
      expect(emittedSupply).to.equal(hre.ethers.parseEther("34000"));
    });

    it("Should not emit before 24 hours", async function () {
      const { honeyDewToken } = await loadFixture(deployHoneyDewTokenFixture);
      
      // Using .to.be.revertedWith as shown in the guide
      await expect(
        honeyDewToken.emitDailyTokens()
      ).to.be.revertedWith("Emission too frequent");
    });

    it("Should get correct daily emission for year 1", async function () {
      const { honeyDewToken } = await loadFixture(deployHoneyDewTokenFixture);
      const dailyEmission = await honeyDewToken.getCurrentDailyEmission();
      expect(dailyEmission).to.equal(hre.ethers.parseEther("34000"));
    });
  });

  describe("Conversion", function () {
    // Nested fixture as shown in the guide
    async function deployWithMintedTokensFixture() {
      const { honeyDewToken, owner, user1, user2 } = await deployHoneyDewTokenFixture();
      
      // Mint some tokens to user1
      await honeyDewToken.connect(owner).mintReward(user1.address, hre.ethers.parseEther("10000"));
      
      return { honeyDewToken, owner, user1, user2 };
    }

    it("Should convert SHNY to AVAX correctly", async function () {
      const { honeyDewToken, user1 } = await loadFixture(deployWithMintedTokensFixture);
      
      const amount = hre.ethers.parseEther("1000");
      const initialAvaxBalance = await hre.ethers.provider.getBalance(user1.address);
      
      const tx = await honeyDewToken.connect(user1).convertToAVAX(amount);
      await tx.wait();
      
      const finalAvaxBalance = await hre.ethers.provider.getBalance(user1.address);
      const avaxReceived = finalAvaxBalance - initialAvaxBalance;
      
      // Using .to.be.closeTo as shown in the guide
      expect(avaxReceived).to.be.closeTo(hre.ethers.parseEther("0.009"), hre.ethers.parseEther("0.0001"));
    });

    it("Should enforce daily limit", async function () {
      const { honeyDewToken, user1 } = await loadFixture(deployWithMintedTokensFixture);
      
      const amount = hre.ethers.parseEther("6000");
      
      await expect(
        honeyDewToken.connect(user1).convertToAVAX(amount)
      ).to.be.revertedWith("Daily limit exceeded");
    });

    it("Should reset daily limit after 24 hours", async function () {
      const { honeyDewToken, user1 } = await loadFixture(deployWithMintedTokensFixture);
      
      const amount = hre.ethers.parseEther("4000");
      
      await honeyDewToken.connect(user1).convertToAVAX(amount);
      
      await hre.network.provider.send("evm_increaseTime", [86400]);
      await hre.network.provider.send("evm_mine", []);
      
      await honeyDewToken.connect(user1).convertToAVAX(amount);
    });
  });

  describe("Minting", function () {
    it("Should allow owner to mint rewards", async function () {
      const { honeyDewToken, owner, user1 } = await loadFixture(deployHoneyDewTokenFixture);
      
      const amount = hre.ethers.parseEther("1000");
      await honeyDewToken.connect(owner).mintReward(user1.address, amount);
      
      expect(await honeyDewToken.balanceOf(user1.address)).to.equal(amount);
    });

    it("Should not allow non-owner to mint", async function () {
      const { honeyDewToken, user1 } = await loadFixture(deployHoneyDewTokenFixture);
      
      const amount = hre.ethers.parseEther("1000");
      
      await expect(
        honeyDewToken.connect(user1).mintReward(user1.address, amount)
      ).to.be.revertedWith("Ownable: caller is not the owner");
    });
  });
});