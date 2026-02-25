import { BaseContract } from "ethers";

declare module "ethers" {
  interface HoneyDewToken extends BaseContract {
    name(): Promise<string>;
    symbol(): Promise<string>;
    MAX_SUPPLY(): Promise<bigint>;
    balanceOf(address: string): Promise<bigint>;
    getAddress(): Promise<string>;
    emitDailyTokens(): Promise<any>;
    emittedSupply(): Promise<bigint>;
    getCurrentDailyEmission(): Promise<bigint>;
    mintReward(to: string, amount: bigint): Promise<any>;
    convertToAVAX(amount: bigint): Promise<any>;
    connect(signer: any): HoneyDewToken;
  }

  interface AntNFT extends BaseContract {
    setColonyManager(address: string): Promise<any>;
    setTournamentSystem(address: string): Promise<any>;
    mintStarterAnts(): Promise<any>;
    mintStarterAntsForPlayer(player: string): Promise<any>;
    breedAnts(parent1: number, parent2: number, overrides?: { value?: bigint }): Promise<any>;
    levelUp(tokenId: number): Promise<any>;
    addExperience(tokenId: number, amount: number): Promise<any>;
    setStaked(tokenId: number, staked: boolean): Promise<any>;
    burn(tokenId: number): Promise<any>;
    balanceOf(owner: string): Promise<bigint>;
    getAntDetails(tokenId: number): Promise<[bigint, bigint, bigint, bigint, bigint, boolean, boolean]>;
    getAntPower(tokenId: number): Promise<bigint>;
    getOwnerAnts(owner: string): Promise<bigint[]>;
    hasClaimedStarterAnts(user: string): Promise<boolean>;
    isStaked(tokenId: number): Promise<boolean>;
    BREEDING_COST(): Promise<bigint>;
    BREEDING_FEE_BPS(): Promise<bigint>;
    connect(signer: any): AntNFT;
  }
}