import { expect } from "chai";
import { network } from "hardhat";

const { ethers, networkHelpers } = await network.connect();

describe("AntNFT", function () {
  async function deployAntNFTFixture() {
    const [owner, user1, user2, colonyManager, tournamentSystem] = await ethers.getSigners();
    
    const antNFT = await ethers.deployContract("AntNFT");
    
    // Set authorized contracts
    // @ts-expect-error - setColonyManager exists at runtime
    await antNFT.connect(owner).setColonyManager(colonyManager.address);
    // @ts-expect-error - setTournamentSystem exists at runtime
    await antNFT.connect(owner).setTournamentSystem(tournamentSystem.address);
    
    // Fund users for breeding
    await networkHelpers.setBalance(user1.address, ethers.parseEther("10"));
    
    return { antNFT, owner, user1, user2, colonyManager, tournamentSystem };
  }

  describe("Starter Ants", function () {
    it("Should mint starter ants for new players", async function () {
      const { antNFT, user1 } = await networkHelpers.loadFixture(deployAntNFTFixture);
      
      // @ts-expect-error - mintStarterAnts exists at runtime
      await expect(antNFT.connect(user1).mintStarterAnts())
        .to.emit(antNFT, "AntMinted")
        .withArgs(user1.address, 1, (value: bigint) => value > 0n, true);
      
      expect(await antNFT.balanceOf(user1.address)).to.equal(3n);
      expect(await antNFT.hasClaimedStarterAnts(user1.address)).to.be.true;
    });

    it("Should not allow claiming starter ants twice", async function () {
      const { antNFT, user1 } = await networkHelpers.loadFixture(deployAntNFTFixture);
      
      // @ts-expect-error - mintStarterAnts exists at runtime
      await antNFT.connect(user1).mintStarterAnts();
      
     
      await expect(
         // @ts-expect-error - mintStarterAnts exists at runtime
        antNFT.connect(user1).mintStarterAnts()
      ).to.be.revertedWithCustomError(antNFT, "AlreadyClaimed");
    });

    it("Should mark starter ants as soulbound", async function () {
      const { antNFT, user1 } = await networkHelpers.loadFixture(deployAntNFTFixture);
      
      // @ts-expect-error - mintStarterAnts exists at runtime
      await antNFT.connect(user1).mintStarterAnts();
      
      const details = await antNFT.getAntDetails(1);
      expect(details[6]).to.be.true; // soulbound is the 7th element (index 6)
    });

    it("Should not allow transfer of soulbound ants", async function () {
      const { antNFT, user1, user2 } = await networkHelpers.loadFixture(deployAntNFTFixture);
      
      // @ts-expect-error - mintStarterAnts exists at runtime
      await antNFT.connect(user1).mintStarterAnts();
      
      await expect(
         // @ts-expect-error - mintStarterAnts exists at runtime
        antNFT.connect(user1).transferFrom(user1.address, user2.address, 1)
      ).to.be.revertedWith("Soulbound");
    });
  });

  describe("Breeding", function () {
    async function deployWithStarterAntsFixture() {
      const base = await deployAntNFTFixture();
      // @ts-expect-error - mintStarterAnts exists at runtime
      await base.antNFT.connect(base.user1).mintStarterAnts();
      return base;
    }

    it("Should breed two ants correctly", async function () {
      const { antNFT, user1 } = await networkHelpers.loadFixture(deployWithStarterAntsFixture);
      
      const breedingCost = await antNFT.BREEDING_COST();
      
      // @ts-expect-error - breedAnts exists at runtime
      await expect(antNFT.connect(user1).breedAnts(1, 2, { value: breedingCost }))
        .to.emit(antNFT, "AntBred")
        .withArgs(user1.address, 1, 2, 4);
      
      expect(await antNFT.balanceOf(user1.address)).to.equal(4n);
    });

    it("Should require sufficient AVAX", async function () {
      const { antNFT, user1 } = await networkHelpers.loadFixture(deployWithStarterAntsFixture);
      
     
      await expect(
         // @ts-expect-error - mintStarterAnts exists at runtime
        antNFT.connect(user1).breedAnts(1, 2, { value: 0 })
      ).to.be.revertedWithCustomError(antNFT, "InsufficientPayment");
    });

    it("Should enforce breeding cooldown", async function () {
      const { antNFT, user1 } = await networkHelpers.loadFixture(deployWithStarterAntsFixture);
      
      const breedingCost = await antNFT.BREEDING_COST();
      
      // @ts-expect-error - breedAnts exists at runtime
      await antNFT.connect(user1).breedAnts(1, 2, { value: breedingCost });
      
    
      await expect(
         // @ts-expect-error - mintStarterAnts exists at runtime
        antNFT.connect(user1).breedAnts(1, 2, { value: breedingCost })
      ).to.be.revertedWithCustomError(antNFT, "BreedingCooldownActive");
      
      await networkHelpers.time.increase(7 * 24 * 60 * 60);
      await networkHelpers.mine();
      
      // @ts-expect-error - breedAnts exists at runtime
      await antNFT.connect(user1).breedAnts(1, 2, { value: breedingCost });
    });

    it("Should not allow breeding same ant", async function () {
      const { antNFT, user1 } = await networkHelpers.loadFixture(deployWithStarterAntsFixture);
      
      const breedingCost = await antNFT.BREEDING_COST();
      
      
      await expect(
         // @ts-expect-error - mintStarterAnts exists at runtime
        antNFT.connect(user1).breedAnts(1, 1, { value: breedingCost })
      ).to.be.revertedWithCustomError(antNFT, "NotOwner");
    });
  });

  describe("Leveling", function () {
    async function deployWithStarterAntsFixture() {
      const base = await deployAntNFTFixture();
      // @ts-expect-error - mintStarterAnts exists at runtime
      await base.antNFT.connect(base.user1).mintStarterAnts();
      return base;
    }

    it("Should level up ant with sufficient experience", async function () {
      const { antNFT, user1, colonyManager } = await networkHelpers.loadFixture(deployWithStarterAntsFixture);
      
      // @ts-expect-error - addExperience exists at runtime
      await antNFT.connect(colonyManager).addExperience(1, 100);
      
      // @ts-expect-error - levelUp exists at runtime
      await expect(antNFT.connect(user1).levelUp(1))
        .to.emit(antNFT, "AntLeveledUp")
        .withArgs(1, 2);
      
      const details = await antNFT.getAntDetails(1);
      expect(details[1]).to.equal(2n); // level is the 2nd element (index 1)
    });

    it("Should not level up with insufficient experience", async function () {
      const { antNFT, user1 } = await networkHelpers.loadFixture(deployWithStarterAntsFixture);
      
     
      await expect(
         // @ts-expect-error - mintStarterAnts exists at runtime
        antNFT.connect(user1).levelUp(1)
      ).to.be.revertedWithCustomError(antNFT, "InsufficientXP");
    });

    it("Should not level up staked ant", async function () {
      const { antNFT, user1, colonyManager } = await networkHelpers.loadFixture(deployWithStarterAntsFixture);
      
      // @ts-expect-error - setStaked exists at runtime
      await antNFT.connect(colonyManager).setStaked(1, true);
      // @ts-expect-error - addExperience exists at runtime
      await antNFT.connect(colonyManager).addExperience(1, 100);
      
    
      await expect(
         // @ts-expect-error - mintStarterAnts exists at runtime
        antNFT.connect(user1).levelUp(1)
      ).to.be.revertedWithCustomError(antNFT, "AntStaked");
    });
  });

  describe("Staking", function () {
    async function deployWithStarterAntsFixture() {
      const base = await deployAntNFTFixture();
      // @ts-expect-error - mintStarterAnts exists at runtime
      await base.antNFT.connect(base.user1).mintStarterAnts();
      return base;
    }

    it("Should set staked status correctly", async function () {
      const { antNFT, colonyManager, user1 } = await networkHelpers.loadFixture(deployWithStarterAntsFixture);
      
      // @ts-expect-error - setStaked exists at runtime
      await expect(antNFT.connect(colonyManager).setStaked(1, true))
        .to.emit(antNFT, "AntStaked")
        .withArgs(1, user1.address);
      
      expect(await antNFT.isStaked(1)).to.be.true;
    });

    it("Should only allow authorized addresses to stake", async function () {
      const { antNFT, user1 } = await networkHelpers.loadFixture(deployWithStarterAntsFixture);
      
      await expect(
         // @ts-expect-error - mintStarterAnts exists at runtime
        antNFT.connect(user1).setStaked(1, true)
      ).to.be.revertedWithCustomError(antNFT, "Unauthorized");
    });
  });

  describe("Burning", function () {
    async function deployWithStarterAntsFixture() {
      const base = await deployAntNFTFixture();
      // @ts-expect-error - mintStarterAnts exists at runtime
      await base.antNFT.connect(base.user1).mintStarterAnts();
      return base;
    }

    it("Should burn ant", async function () {
      const { antNFT, colonyManager, user1 } = await networkHelpers.loadFixture(deployWithStarterAntsFixture);
      
      // @ts-expect-error - burn exists at runtime
      await antNFT.connect(colonyManager).burn(1);
      
      expect(await antNFT.balanceOf(user1.address)).to.equal(2n);
      
      await expect(antNFT.getAntDetails(1)).to.be.revertedWithCustomError(antNFT, "AntNotFound");
    });

    it("Should only allow authorized addresses to burn", async function () {
      const { antNFT, user1 } = await networkHelpers.loadFixture(deployWithStarterAntsFixture);
      
   
      await expect(
         // @ts-expect-error - mintStarterAnts exists at runtime
        antNFT.connect(user1).burn(1)
      ).to.be.revertedWithCustomError(antNFT, "Unauthorized");
    });
  });

  describe("View Functions", function () {
    async function deployWithStarterAntsFixture() {
      const base = await deployAntNFTFixture();
      // @ts-expect-error - mintStarterAnts exists at runtime
      await base.antNFT.connect(base.user1).mintStarterAnts();
      return base;
    }

    it("Should return owner ants", async function () {
      const { antNFT, user1 } = await networkHelpers.loadFixture(deployWithStarterAntsFixture);
      

      const ownerAnts = await antNFT.getOwnerAnts(user1.address);
      expect(ownerAnts).to.have.lengthOf(3);
      expect(ownerAnts[0]).to.equal(1n);
      expect(ownerAnts[1]).to.equal(2n);
      expect(ownerAnts[2]).to.equal(3n);
    });

    it("Should return ant power", async function () {
      const { antNFT } = await networkHelpers.loadFixture(deployWithStarterAntsFixture);
      
  
      const power = await antNFT.getAntPower(1);
      expect(power).to.be.gt(0n);
    });
  });
});