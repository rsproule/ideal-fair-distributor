import { Contract, Signer } from "ethers";
import { ethers } from "hardhat";
import { SignerWithAddress } from "hardhat-deploy-ethers/signers";
import { randomBytes } from "crypto";


describe("Commit-Reveal-Preferences", async () => {
  let prefMaximizerContract: Contract;

  beforeEach(async () => {
    // deploy the contract
    const whitelist: SignerWithAddress[] = await ethers.getSigners();
    const PreferenceMaximizer = await ethers.getContractFactory("PreferenceMaximizer")
    prefMaximizerContract = await PreferenceMaximizer.deploy(whitelist.map(a => a.address));
    
  })
  it("Should commit a preference list", async () => {
    
    const preferences = [1, 2, 3, 4]
    const secret = ""
  })

  it("should generate a commitment byte array from preference set and secret", async () => {
    const preferences = [1, 2, 3, 4];
    // const random = new Uint8Array(32);
    const random = randomBytes(32)
    const salt = "0x" + Array.from(random).map(b => b.toString(16).padStart(2, "0")).join("");

    const commit = await prefMaximizerContract.makeCommitment(preferences, salt);
    console.log(commit);
    
    //  submit the commitment
    let res = await prefMaximizerContract.commitPreference(commit);

    console.log(res);

    let commitments = await prefMaximizerContract._commitments(res.from);
    console.log(commitments.commit)
    
  })
})

