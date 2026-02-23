import { expect } from "chai";
import hre from "hardhat";
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import { AntNFT } from "../typechain-types";

describe("AntNFT", function () {
  // Fixture to deploy the contract
  async function deployAntNFTFixture() {
    const [owner, user1, user2] = await hre.ethers.getSigners();
    
    const AntNFTFactory = await hre.ethers.getContractFactory("AntNFT");
    const antNFT = await AntNFTFactory.deploy();
    await antNFT.waitForDeployment();
    
    return { antNFT, owner, user1, user2 };
  }

  describe("Starter Ants", function () {
    it("Should mint starter ants for new players", async function () {
      const { antNFT, user1 } = await loadFixture(deployAntNFTFixture);
      
      await antNFT.connect(user1).mintStarterAnts();
      
      expect(await antNFT.balanceOf(user1.address)).to.equal(3);
      expect(await antNFT.hasClaimedStarterAnts(user1.address)).to.be.true;
    });

    it("Should not allow claiming starter ants twice", async function () {
      const { antNFT, user1 } = await loadFixture(deployAntNFTFixture);
      
      await antNFT.connect(user1).mintStarterAnts();
      
      await expect(
        antNFT.connect(user1).mintStarterAnts()
      ).to.be.revertedWith("Already claimed starter ants");
    });

    it("Should mark starter ants as soulbound", async function () {
      const { antNFT, user1 } = await loadFixture(deployAntNFTFixture);
      
      await antNFT.connect(user1).mintStarterAnts();
      const tokenId = 1; // First token (starts from 1)
      
      const details = await antNFT.getAntDetails(tokenId);
      expect(details.isSoulbound).to.be.true;
    });

    it("Should not allow transfer of soulbound ants", async function () {
      const { antNFT, user1, user2 } = await loadFixture(deployAntNFTFixture);
      
      await antNFT.connect(user1).mintStarterAnts();
      const tokenId = 1;
      
      await expect(
        antNFT.connect(user1).transferFrom(user1.address, user2.address, tokenId)
      ).to.be.revertedWith("Soulbound tokens cannot be transferred");
    });
  });

  describe("Breeding", function () {
    async function deployWithStarterAntsFixture() {
      const { antNFT, owner, user1, user2 } = await deployAntNFTFixture();
      
      // Mint starter ants for breeding
      await antNFT.connect(user1).mintStarterAnts();
      
      return { antNFT, owner, user1, user2 };
    }

    it("Should breed two ants correctly", async function () {
      const { antNFT, user1 } = await loadFixture(deployWithStarterAntsFixture);
      
      const breedingCost = await antNFT.BREEDING_COST();
      
      await antNFT.connect(user1).breedAnts(1, 2, { value: breedingCost });
      
      expect(await antNFT.balanceOf(user1.address)).to.equal(4); // 3 starters + 1 new
    });

    it("Should require sufficient AVAX", async function () {
      const { antNFT, user1 } = await loadFixture(deployWithStarterAntsFixture);
      
      await expect(
        antNFT.connect(user1).breedAnts(1, 2, { value: 0 })
      ).to.be.revertedWith("Insufficient AVAX");
    });

    it("Should enforce breeding cooldown", async function () {
      const { antNFT, user1 } = await loadFixture(deployWithStarterAntsFixture);
      
      const breedingCost = await antNFT.BREEDING_COST();
      
      await antNFT.connect(user1).breedAnts(1, 2, { value: breedingCost });
      
      await expect(
        antNFT.connect(user1).breedAnts(1, 2, { value: breedingCost })
      ).to.be.revertedWith("Parent1 breeding cooldown");
    });

    it("Should not allow breeding same ant", async function () {
      const { antNFT, user1 } = await loadFixture(deployWithStarterAntsFixture);
      
      const breedingCost = await antNFT.BREEDING_COST();
      
      await expect(
        antNFT.connect(user1).breedAnts(1, 1, { value: breedingCost })
      ).to.be.revertedWith("Cannot breed same ant");
    });
  });

  describe("Leveling", function () {
    async function deployWithStarterAntsFixture() {
      const { antNFT, owner, user1, user2 } = await deployAntNFTFixture();
      
      await antNFT.connect(user1).mintStarterAnts();
      
      return { antNFT, owner, user1, user2 };
    }

    it("Should level up ant with sufficient experience", async function () {
      const { antNFT, user1, owner } = await loadFixture(deployWithStarterAntsFixture);
      
      // Add experience (as owner for testing)
      await antNFT.connect(owner).addExperience(1, 100); // Level 1 needs 100 XP
      
      await antNFT.connect(user1).levelUp(1);
      
      const details = await antNFT.getAntDetails(1);
      expect(details.level).to.equal(2);
    });

    it("Should not level up with insufficient experience", async function () {
      const { antNFT, user1 } = await loadFixture(deployWithStarterAntsFixture);
      
      await expect(
        antNFT.connect(user1).levelUp(1)
      ).to.be.revertedWith("Insufficient experience");
    });

    it("Should not level up beyond max level", async function () {
      const { antNFT, user1, owner } = await loadFixture(deployWithStarterAntsFixture);
      const maxLevel = await antNFT.MAX_LEVEL();
      
      // Add enough experience to reach max level
      for (let i = 1; i < Number(maxLevel); i++) {
        await antNFT.connect(owner).addExperience(1, 100 * (i ** 2));
        await antNFT.connect(user1).levelUp(1);
      }
      
      await expect(
        antNFT.connect(user1).levelUp(1)
      ).to.be.revertedWith("Already max level");
    });
  });

  describe("Staking", function () {
    async function deployWithStarterAntsFixture() {
      const { antNFT, owner, user1, user2 } = await deployAntNFTFixture();
      
      await antNFT.connect(user1).mintStarterAnts();
      
      return { antNFT, owner, user1, user2 };
    }

    it("Should set staked status correctly", async function () {
      const { antNFT, user1, owner } = await loadFixture(deployWithStarterAntsFixture);
      
      await antNFT.connect(owner).setStaked(1, true);
      
      const details = await antNFT.getAntDetails(1);
      expect(details.isStaked).to.be.true;
    });

    it("Should prevent staked ants from breeding", async function () {
      const { antNFT, user1, owner } = await loadFixture(deployWithStarterAntsFixture);
      
      await antNFT.connect(owner).setStaked(1, true);
      const breedingCost = await antNFT.BREEDING_COST();
      
      await expect(
        antNFT.connect(user1).breedAnts(1, 2, { value: breedingCost })
      ).to.be.revertedWith("Ant is staked");
    });
  });
});