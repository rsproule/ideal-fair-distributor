pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import 'hardhat/console.sol';

import "@openzeppelin/contracts/access/Ownable.sol"; //https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol

contract PreferenceMaximizer is Ownable {
  uint constant MAX_INT =  2**256 - 1;
  uint public totalCommitments = 0;
  uint totalReveals = 0;
  // need to edit this before deploying with number of NFTs there are
  uint constant expectedAgents = 4;
  uint[expectedAgents][expectedAgents] public preferenceMatrix;
  uint[expectedAgents] public optimalSolution;

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
        optimalSolution[i] = whitelist.length + 1;
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
    require(makeCommitment(preferences, secret) == commitment.commitment, "Commitment does not match");
    // lock in this preference
    // commitment.preferences = preferences;
    _commitments[msg.sender] = PreferenceCommitment(msg.sender, commitment.commitment, preferences);
    // might as well store this stuff in the format the optimizer prefers, tho theoretically if we 
    // cared about gas this should totally happen in the offchain function
    for (uint i = 0; i < preferences.length; i++) {
      preferenceMatrix[totalReveals][i] = preferences[i];     
    }

    totalReveals += 1;
  }

  /// @notice this function is readonly, once all commit reveal is done. 
  function commitOptimalSolution() public {
    require(totalReveals == expectedAgents, "Missing reveals.");
    require(optimalSolution[0] == expectedAgents + 1, "Optimal solution already found.");
    uint[] memory s = calculateOptimalMatching();
    // just copy this array into storage
    for (uint i = 0; i < expectedAgents; i++) {
      optimalSolution[i] = s[i];
    }
  }


  /// @notice this is a pure readonly function meant to be a helper for 
  /// generating ur commitment
  function makeCommitment(uint[] calldata preferences, bytes32 secret) public view returns (bytes32) {
    require(preferences.length == expectedAgents, "Incorrect length of preferences");
    return keccak256(abi.encodePacked(msg.sender, preferences, secret)); 

  }
  
  function indexOf(uint[] memory array, uint target, uint start) private pure returns (uint) {
    for (uint i = start; i < array.length; i++) {
      if (array[i] == target) {
        return i;
      }
    }    
    return array.length + 1;
  }

  function initArrayNoCollisions(uint length) pure private returns (uint[] memory) {
    uint[] memory solution = new uint[](length); 
    for (uint i = 0; i < length; i++) {
      solution[i] = length + 1; // length plus 1 will never be a valid index in the array, cant use -1, uint
    }
    return solution;
  }

  function getMinIgnoreIndices(uint[4] storage array, uint index) private view returns(uint min) {
    min = MAX_INT;
    for (uint i = 0; i < array.length; i++) {
      if (array[i] < min && i != index) {
        min = array[i];
      }
    }
  }

  function calculateOptimalMatching() public view returns(uint[] memory) {
    // get the pref matrix in memory 
    uint[expectedAgents][expectedAgents] storage prefMatrix = preferenceMatrix;
    // // convert this to solidity
    // unfortunately this inits soltion with all 0s, which is not gonna work
    uint[] memory solution = initArrayNoCollisions(expectedAgents);
  
    for (uint i = 0; i < prefMatrix.length; i++) {
      uint minSum =  MAX_INT;
      uint minSumIndex = prefMatrix.length;
      for (uint j = 0; j < prefMatrix[i].length; j++) {
        if (indexOf(solution, j, 0) <= prefMatrix[i].length) continue;
        uint sum = prefMatrix[i][j];
        for (uint ii = i; ii < prefMatrix.length; ii++) {
          if (ii != i) {
            sum += getMinIgnoreIndices(prefMatrix[ii], j);
          }
        }
        if (sum < minSum) {
          minSum = sum;
          minSumIndex = j;
        }
      }
      solution[i] = minSumIndex;
    }

    return solution;
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
