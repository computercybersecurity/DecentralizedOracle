// pragma solidity >=0.4.21 <0.6.0;
pragma solidity >=0.6.6;

interface IUpgradable {
  function getOracleAddress() external returns (address);
}
