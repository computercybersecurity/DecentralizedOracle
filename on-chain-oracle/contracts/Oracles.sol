// pragma solidity >=0.4.21 <0.6.0;
pragma solidity >=0.6.6;

import "./interfaces/IOracles.sol";
import "./library/Ownable.sol";

contract Oracles is Ownable, IOracles {

  uint private totalOracleCount = 2000; // Hardcoded oracle count
  mapping(address => reputation) public oracles;        // Reputation of oracles
  address[] public oracleAddresses;      // Saved active oracle addresses

  constructor () public {
  }

  function newOracle (string memory name, address addr, uint256 requestFee) public override(IOracles)
  {
    require(oracleAddresses.length < totalOracleCount, "oracle overflow");
    require(oracles[addr].addr == address(0), "already exists");

    oracles[addr].name = name;
    oracles[addr].addr = addr;
    oracles[addr].lastActiveTime = now;
    oracles[addr].penalty = requestFee;
    oracleAddresses.push(addr);
  }

  function getOracleCount () public override(IOracles) returns (uint256)
  {
    return oracleAddresses.length;
  }

  function isOracleAvailable (address addr) public override(IOracles) returns (bool)
  {
    return oracles[addr].addr == address(0);
  }

  function getOracleByIndex (uint256 idx) public override(IOracles) returns (address)
  {
    return oracleAddresses[idx];
  }

  function increaseOracleAssigned (address addr, uint256 penalty) public override(IOracles)
  {
    oracles[addr].totalAssignedRequest ++;
    oracles[addr].penalty = penalty;
  }

  function increaseOracleCompleted (address addr, uint256 responseTime) public override(IOracles)
  {
    oracles[addr].totalCompletedRequest ++;
    oracles[addr].totalResponseTime = oracles[addr].totalResponseTime + responseTime;
  }

  function increaseOracleAccepted (address addr, uint256 earned) public override(IOracles)
  {
    oracles[addr].totalAcceptedRequest ++;
    oracles[addr].totalEarned = oracles[addr].totalEarned + earned;
  }

  function getOracleLastActiveTime (address addr) public override(IOracles) returns (uint256)
  {
    return oracles[addr].lastActiveTime;
  }

  function updateOracleLastActiveTime (address addr) public override(IOracles)
  {
    oracles[addr].lastActiveTime = now;
  }

  function getOracleReputation (address addr) public view returns (string memory, uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
    reputation memory p = oracles[addr];
    return (p.name, p.totalAssignedRequest, p.totalCompletedRequest, p.totalAcceptedRequest, p.totalResponseTime, p.lastActiveTime, p.penalty, p.totalEarned);
  }

  function removeOracleByAddress (address addr) public onlyOwner
  {
    for (uint i = 0; i < oracleAddresses.length ; i ++) {
      if (oracleAddresses[i] == addr) {
        oracleAddresses[i] = oracleAddresses[oracleAddresses.length - 1];
        delete oracleAddresses[oracleAddresses.length - 1];
        oracleAddresses.pop();

        oracles[addr].addr = address(0);      // Reset reputation of oracle to zero
        break;
      }
    }
  }
}
