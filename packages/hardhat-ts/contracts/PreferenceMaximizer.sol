pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import 'hardhat/console.sol';

import "@openzeppelin/contracts/access/Ownable.sol"; //https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol

contract PreferenceMaximizer is Ownable {
  uint totalCommitments = 0;
  uint totalReveals = 0;
  uint expectedAgents;
  Phase currentPhase = Phase.Commit;
  enum Phase {
    Commit, 
    Reveal
  }
  mapping(address => bool) _whitelist;  
  mapping(address => PreferenceCommitment) _commitments;
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
    expectedAgents = whitelist.length;
  }

  /// @notice this needs to be done via a commit reveal scheme, otherwise people
  /// gain an unfair advantage over the system by knowing what others prefer 
  function commitPreference(bytes32 preferenceCommitment) public {
    require(_whitelist[msg.sender], "Sender not in the whitelist");
    _whitelist[msg.sender] = false; // you can only submit once
    totalCommitments += 1;
    _commitments[msg.sender] = PreferenceCommitment(msg.sender, preferenceCommitment, new uint[](expectedAgents));
    emit Commit(msg.sender, preferenceCommitment);
    
    if (totalCommitments == expectedAgents) {
      currentPhase = Phase.Reveal;
    }
  }

  function revealPreference(uint[] calldata preferences, bytes32 secret) public {
    require(totalCommitments == expectedAgents, "Not in reveal phase yet, missing commitments");

    PreferenceCommitment storage commitment = _commitments[msg.sender];

    // assert these are correct 
    require(keccak256(abi.encodePacked(msg.sender, preferences, secret)) == commitment.commitment, "Commitment does not match");
    // lock in this preference
    commitment.preferences = preferences;
    
  }

  /// @notice this function is readonly, once all commit reveal is done. 
  function optimalSolution() public {
    require(totalReveals == expectedAgents, "Missing reveals.");


  }
  

  function calculateOptimalMatching() public {
    // why do this in a smart contract, is there there any reason that 
  }
}
