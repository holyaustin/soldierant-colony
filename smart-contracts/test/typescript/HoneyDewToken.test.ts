import { expect } from "chai";
import { network } from "hardhat";

const { ethers, networkHelpers } = await network.connect();

describe("HoneyDewToken", function () {
  async function deployTokenFixture() {
    const [owner, user1, user2] = await ethers.getSigners();
    
    // This returns a contract with all methods at runtime
    const token = await ethers.deployContract("HoneyDewToken");
    
    return { token, owner, user1, user2 };
  }

  describe("Deployment", function () {
    it("Should set the correct name and symbol", async function () {
      const { token } = await networkHelpers.loadFixture(deployTokenFixture);
      expect(await token.name()).to.equal("HoneyDew Token");
      expect(await token.symbol()).to.equal("SHNY");
    });

    it("Should have correct max supply", async function () {
      const { token } = await networkHelpers.loadFixture(deployTokenFixture);
      const maxSupply = await token.MAX_SUPPLY();
      expect(maxSupply).to.equal(ethers.parseEther("50000000"));
    });

    it("Should mint all tokens to contract", async function () {
      const { token } = await networkHelpers.loadFixture(deployTokenFixture);
      const contractAddress = await token.getAddress();
      const balance = await token.balanceOf(contractAddress);
      expect(balance).to.equal(ethers.parseEther("50000000"));
    });
  });

  describe("Emission", function () {
    it("Should emit daily tokens after 24 hours", async function () {
      const { token } = await networkHelpers.loadFixture(deployTokenFixture);
      
      await networkHelpers.time.increase(86400);
      await networkHelpers.mine();
      
      await token.emitDailyTokens();
      
      const emittedSupply = await token.emittedSupply();
      expect(emittedSupply).to.equal(ethers.parseEther("34000"));
    });

    it("Should not emit before 24 hours", async function () {
      const { token } = await networkHelpers.loadFixture(deployTokenFixture);
      
      await expect(token.emitDailyTokens()).to.be.revertedWith("Emission too frequent");
    });

    it("Should get correct daily emission for year 1", async function () {
      const { token } = await networkHelpers.loadFixture(deployTokenFixture);
      const dailyEmission = await token.getCurrentDailyEmission();
      expect(dailyEmission).to.equal(ethers.parseEther("34000"));
    });
  });

  describe("Minting", function () {
    it("Should allow owner to mint rewards", async function () {
      const { token, owner, user1 } = await networkHelpers.loadFixture(deployTokenFixture);
      
      const amount = ethers.parseEther("1000");
      
      // These methods exist at runtime - TypeScript errors are expected and safe to ignore
      // @ts-expect-error - mintReward exists at runtime
      await token.connect(owner).mintReward(user1.address, amount);
      
      expect(await token.balanceOf(user1.address)).to.equal(amount);
    });

    it("Should not allow non-owner to mint", async function () {
      const { token, user1 } = await networkHelpers.loadFixture(deployTokenFixture);
      
      const amount = ethers.parseEther("1000");
      
      await expect(
        // @ts-expect-error - mintReward exists at runtime
        token.connect(user1).mintReward(user1.address, amount)
      ).to.be.revertedWith("Ownable: caller is not the owner");
    });
  });

  describe("Conversion", function () {
    async function deployWithMintedFixture() {
      const base = await deployTokenFixture();
      
      const mintAmount = ethers.parseEther("10000");
      // @ts-expect-error - mintReward exists at runtime
      await base.token.connect(base.owner).mintReward(base.user1.address, mintAmount);
      
      return base;
    }

    it("Should convert SHNY to AVAX correctly", async function () {
      const { token, user1 } = await networkHelpers.loadFixture(deployWithMintedFixture);
      
      const amount = ethers.parseEther("1000");
      const initialBalance = await ethers.provider.getBalance(user1.address);
      // @ts-expect-error - mintReward exists at runtime
      await token.connect(user1).convertToAVAX(amount);
      
      const finalBalance = await ethers.provider.getBalance(user1.address);
      const received = finalBalance - initialBalance;
      
      const expectedAmount = ethers.parseEther("0.009");
      expect(received).to.be.closeTo(expectedAmount, ethers.parseEther("0.0001"));
    });

    it("Should enforce daily limit", async function () {
      const { token, user1 } = await networkHelpers.loadFixture(deployWithMintedFixture);
      
      const amount = ethers.parseEther("6000");
      
      await expect(
        // @ts-expect-error - mintReward exists at runtime
        token.connect(user1).convertToAVAX(amount)
      ).to.be.revertedWith("Daily limit exceeded");
    });

    it("Should reset daily limit after 24 hours", async function () {
      const { token, user1 } = await networkHelpers.loadFixture(deployWithMintedFixture);
      
      const amount = ethers.parseEther("4000");
      // @ts-expect-error - mintReward exists at runtime
      await token.connect(user1).convertToAVAX(amount);
      
      await networkHelpers.time.increase(86400);
      await networkHelpers.mine();
      // @ts-expect-error - mintReward exists at runtime
      await token.connect(user1).convertToAVAX(amount);
    });

    it("Should emit ConvertedToAVAX event", async function () {
      const { token, user1 } = await networkHelpers.loadFixture(deployWithMintedFixture);
      
      const amount = ethers.parseEther("1000");
      // @ts-expect-error - mintReward exists at runtime
      await expect(token.connect(user1).convertToAVAX(amount))
        .to.emit(token, "ConvertedToAVAX")
        .withArgs(user1.address, amount, ethers.parseEther("0.009"), ethers.parseEther("0.001"));
    });
  });
});