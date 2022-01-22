pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import 'hardhat/console.sol';

import "@openzeppelin/contracts/access/Ownable.sol"; //https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol

contract PreferenceMaximizer is Ownable {
  uint totalCommitments = 0;
  uint totalReveals = 0;
  // need to edit this before deploying with number of NFTs there are
  uint constant expectedAgents = 4;
  uint[expectedAgents][expectedAgents] preferenceMatrix;

  Phase currentPhase = Phase.Commit;
  enum Phase {
    Commit, 
    Reveal
  }
  mapping(address => bool) _whitelist;  
  mapping(address => PreferenceCommitment) public _commitments;
  event Commit(address sender, bytes32 commitment);

  struct PreferenceCommitment {
    address committer;
    bytes32 commitment;
    uint[] preferences;
  }

  constructor(address[] memory whitelist) onlyOwner {
    for (uint i = 0; i < whitelist.length; i++) {
        _whitelist[whitelist[i]] = true;
    }
  }

  /// @notice this needs to be done via a commit reveal scheme, otherwise people
  /// gain an unfair advantage over the system by knowing what others prefer 
  function commitPreference(bytes32 preferenceCommitment) public {
    require(_whitelist[msg.sender], "Sender not in the whitelist");
    _whitelist[msg.sender] = false; // you can only submit once
    totalCommitments += 1;
    _commitments[msg.sender] = PreferenceCommitment(msg.sender, preferenceCommitment, new uint[](expectedAgents));
    emit Commit(msg.sender, preferenceCommitment);
  }

  function revealPreference(uint[] calldata preferences, bytes32 secret) public {
    require(totalCommitments == expectedAgents, "Not in reveal phase yet, missing commitments");

    PreferenceCommitment storage commitment = _commitments[msg.sender];

    // assert the commitment matches this input
    require(keccak256(abi.encodePacked(msg.sender, preferences, secret)) == commitment.commitment, "Commitment does not match");
    // lock in this preference
    commitment.preferences = preferences;

    // might as well store this stuff in the format the optimizer prefers, tho theoretically if we 
    // cared about gas this should totally happen in the offchain function
    for (uint i = 0; i < preferences.length; i++) {
      preferenceMatrix[totalReveals][i] = preferences[i];     
    }

    totalReveals += 1;
  }

  /// @notice this function is readonly, once all commit reveal is done. 
  function optimalSolution() public returns (uint[] memory){
    require(totalReveals == expectedAgents, "Missing reveals.");
    return calculateOptimalMatching(); 
  }


  /// @notice this is a pure readonly function meant to be a helper for 
  /// generating ur commitment
  function makeCommitment(uint[] calldata preferences, bytes32 secret) public view returns (bytes32){
    require(preferences.length == expectedAgents, "Incorrect length of preferences");
    return keccak256(abi.encodePacked(msg.sender, preferences, secret)); 

  }
  

  function calculateOptimalMatching() public returns(uint[] memory) {
    // // convert this to solidity
    // uint solution = [];
    // for (var i = 0; i < preferenceMatrix.length; i++) {
    //   let minSum = Infinity;
    //   let minSumIndex = -1;
    //   for (var j = 0; j < preferenceMatrix[i].length; j++) {
    //     if (solution.indexOf(j) !== -1) {
    //       continue;
    //     }
    //     let sum = preferenceMatrix[i][j];
    //     for (var ii = i; ii < preferenceMatrix.length; ii++) {
    //       if (ii != i) {
    //         let seenAndCurrentIndices = [j];
    //         sum += getMinIgnoreIndices(preferenceMatrix[ii], seenAndCurrentIndices);
    //       }
    //     }
    //     if (sum < minSum) {
    //       minSum = sum;
    //       minSumIndex = j;
    //     }
    //   }
    //   solution.push(minSumIndex);
    // }
    // return solution;

  }
}
