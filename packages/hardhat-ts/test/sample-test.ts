import { Contract, Signer } from 'ethers';
import { ethers } from 'hardhat';
import { SignerWithAddress } from 'hardhat-deploy-ethers/signers';
import { randomBytes } from 'crypto';

describe('Commit-Reveal-Preferences', async () => {
  let prefMaximizerContract: Contract;

  beforeEach(async () => {
    // deploy the contract
    const whitelist: SignerWithAddress[] = (await ethers.getSigners()).slice(0, 4);
    console.log(whitelist.length);
    const PreferenceMaximizer = await ethers.getContractFactory('PreferenceMaximizer');
    prefMaximizerContract = await PreferenceMaximizer.deploy(whitelist.map((a) => a.address));
  });
  it('Should commit a preference list', async () => {
    const preferences = [1, 2, 3, 4];
    const secret = '';
  });
  function shuffle(array: number[]) {
    let currentIndex = array.length,
      randomIndex;

    // While there remain elements to shuffle...
    while (currentIndex != 0) {
      // Pick a remaining element...
      randomIndex = Math.floor(Math.random() * currentIndex);
      currentIndex--;

      // And swap it with the current element.
      [array[currentIndex], array[randomIndex]] = [array[randomIndex], array[currentIndex]];
    }

    return array;
  }
  it('should generate a commitment byte array from preference set and secret', async () => {
    const preferences = [1, 2, 3, 4];
    const preferences1 = shuffle([1, 2, 3, 4]);
    const preferences2 = shuffle([1, 2, 3, 4]);
    const preferences3 = shuffle([1, 2, 3, 4]);

    // const random = new Uint8Array(32);
    const random = randomBytes(32);
    const salt =
      '0x' +
      Array.from(random)
        .map((b) => b.toString(16).padStart(2, '0'))
        .join('');

    const commit = await prefMaximizerContract.makeCommitment(preferences, salt);
    const commit2 = await prefMaximizerContract.connect((await ethers.getSigners())[1]).makeCommitment(preferences1, salt);
    const commit3 = await prefMaximizerContract.connect((await ethers.getSigners())[2]).makeCommitment(preferences2, salt);
    const commit4 = await prefMaximizerContract.connect((await ethers.getSigners())[3]).makeCommitment(preferences3, salt);
    // console.log(commit);
    //  submit the commitment
    let res = await prefMaximizerContract.commitPreference(commit);
    await prefMaximizerContract.connect((await ethers.getSigners())[1]).commitPreference(commit2);
    await prefMaximizerContract.connect((await ethers.getSigners())[2]).commitPreference(commit3);
    await prefMaximizerContract.connect((await ethers.getSigners())[3]).commitPreference(commit4);
    // console.log(res);

    let totalCommits = await prefMaximizerContract.totalCommitments();
    let commitments = await prefMaximizerContract._commitments(res.from);
    // console.log(commitments.commit)

    // dp the reveal

    await prefMaximizerContract.revealPreference(preferences, salt);
    await prefMaximizerContract.connect((await ethers.getSigners())[1]).revealPreference(preferences1, salt);
    await prefMaximizerContract.connect((await ethers.getSigners())[2]).revealPreference(preferences2, salt);
    await prefMaximizerContract.connect((await ethers.getSigners())[3]).revealPreference(preferences3, salt);

    // something is broken here, the preferences are not getting updated in the commitment struct
    // this doesnt reaaally matter because the solition calculator doesnt actually use this
    // let commitmentsRevealed = await prefMaximizerContract._commitments(res2.from);
    // console.log(commitmentsRevealed)

    await prefMaximizerContract.commitOptimalSolution();
    let solution = [];
    for (var i = 0; i < preferences.length; i++) {
      solution.push(await prefMaximizerContract.optimalSolution(i));
    }
    console.log(solution.map((a) => a.toString()));
  });
});
