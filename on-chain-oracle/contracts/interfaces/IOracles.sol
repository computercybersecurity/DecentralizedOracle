// pragma solidity >=0.4.21 <0.6.0;
pragma solidity >=0.6.6;

interface IOracles {

  struct reputation {
    bytes32 name;
    address addr;
    uint256 totalAssignedRequest;        //total number of past requests that an oracle has agreed to, both fulfilled and unfulfileed
    uint256 totalCompletedRequest;       //total number of past requests that an oracle has fulfileed
    uint256 totalAcceptedRequest;        //total number of requests that have been accepted
    uint256 totalResponseTime;           //total seconds of response time
    uint256 lastActiveTime;              //last active time of the oracle as second
    uint256 totalEarned;                 //total earned
  }

  event NewOracle(address addr);

  function getOracleCount () external returns (uint256);
  function isOracleAvailable (address addr) external returns (bool);
  function getOracleByIndex (uint256 idx) external returns (address);
  function increaseOracleAssigned (address addr) external;
  function increaseOracleCompleted (address addr, uint256 responseTime) external;
  function increaseOracleAccepted (address addr, uint256 earned) external;
  function getOracleLastActiveTime (address addr) external returns (uint256);
  function updateOracleLastActiveTime (address addr) external;
}
