import { expect } from "chai";
import { network } from "hardhat";

const { ethers, networkHelpers } = await network.connect();

describe("Gameplay Integration", function () {
  async function deployFullGameFixture() {
    const [owner, user1, user2, colonyManager, tournamentSystem] = await ethers.getSigners();
    
    // Deploy token
    const token = await ethers.deployContract("HoneyDewToken");
    
    // Deploy AntNFT
    const antNFT = await ethers.deployContract("AntNFT");
    
    // Set up authorized contracts
    // @ts-expect-error - setColonyManager exists at runtime
    await antNFT.connect(owner).setColonyManager(colonyManager.address);
    // @ts-expect-error - setTournamentSystem exists at runtime
    await antNFT.connect(owner).setTournamentSystem(tournamentSystem.address);
    
    // Fund users for breeding
    await networkHelpers.setBalance(user1.address, ethers.parseEther("10"));
    await networkHelpers.setBalance(user2.address, ethers.parseEther("10"));
    
    return { token, antNFT, owner, user1, user2, colonyManager, tournamentSystem };
  }

  describe("Complete Player Journey", function () {
    it("User should mint starter ants, breed, level up, and stake", async function () {
      const { antNFT, user1, colonyManager } = await networkHelpers.loadFixture(deployFullGameFixture);
      
      // Step 1: Mint starter ants
      // @ts-expect-error - mintStarterAnts exists at runtime
      await antNFT.connect(user1).mintStarterAnts();
      expect(await antNFT.balanceOf(user1.address)).to.equal(3n);
      
      // Step 2: Breed ants
      const breedingCost = await antNFT.BREEDING_COST();
      // @ts-expect-error - breedAnts exists at runtime
      await antNFT.connect(user1).breedAnts(1, 2, { value: breedingCost });
      expect(await antNFT.balanceOf(user1.address)).to.equal(4n);
      
      // Step 3: Add experience
      // @ts-expect-error - addExperience exists at runtime
      await antNFT.connect(colonyManager).addExperience(4, 100);
      
      // Step 4: Level up
      // @ts-expect-error - levelUp exists at runtime
      await antNFT.connect(user1).levelUp(4);
      const details = await antNFT.getAntDetails(4);
      expect(details[1]).to.equal(2n); // level is at index 1
      
      // Step 5: Stake ant
      // @ts-expect-error - setStaked exists at runtime
      await antNFT.connect(colonyManager).setStaked(4, true);
      expect(await antNFT.isStaked(4)).to.be.true;
      
      // Step 6: Get owned ants list

      const ownerAnts = await antNFT.getOwnerAnts(user1.address);
      expect(ownerAnts).to.include(4n);
    });
  });

  describe("Breeding Economics", function () {
    it("Breeding fees are distributed correctly", async function () {
      const { antNFT, user1 } = await networkHelpers.loadFixture(deployFullGameFixture);
      
      // @ts-expect-error - mintStarterAnts exists at runtime
      await antNFT.connect(user1).mintStarterAnts();
      
      const balanceBefore = await ethers.provider.getBalance(user1.address);
      const breedingCost = await antNFT.BREEDING_COST();
      
      // @ts-expect-error - breedAnts exists at runtime
      const tx = await antNFT.connect(user1).breedAnts(1, 2, { value: breedingCost });
      const receipt = await tx.wait();
      
      const gasUsed = receipt!.gasUsed;
      const feeData = await ethers.provider.getFeeData();
      const gasPrice = feeData.gasPrice!;
      const gasCost = gasUsed * gasPrice;
      
      const balanceAfter = await ethers.provider.getBalance(user1.address);
      
      const expectedSpent = breedingCost + gasCost;
      const actualSpent = balanceBefore - balanceAfter;
      
      expect(actualSpent).to.be.closeTo(expectedSpent, ethers.parseEther("0.001"));
    });
  });

  describe("Token Integration", function () {
    it("Should mint tokens and convert to AVAX", async function () {
      const { token, owner, user1 } = await networkHelpers.loadFixture(deployFullGameFixture);
      
      const mintAmount = ethers.parseEther("5000");
      // @ts-expect-error - mintReward exists at runtime
      await token.connect(owner).mintReward(user1.address, mintAmount);
      
      const convertAmount = ethers.parseEther("1000");
      const balanceBefore = await ethers.provider.getBalance(user1.address);
      
      // @ts-expect-error - convertToAVAX exists at runtime
      await token.connect(user1).convertToAVAX(convertAmount);
      
      const balanceAfter = await ethers.provider.getBalance(user1.address);
      expect(balanceAfter).to.be.gt(balanceBefore);
      
      expect(await token.balanceOf(user1.address)).to.equal(mintAmount - convertAmount);
    });
  });
});