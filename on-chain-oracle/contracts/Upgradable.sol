pragma solidity >=0.6.6;

import "./library/Ownable.sol";

contract Upgradable is Ownable {
    address public oracle;

    constructor (address oracleAddress) public {
        oracle = oracleAddress;
    }

    function upgradeOracleAddress (address newOracle) public onlyOwner {
        oracle = newOracle;
    }
}
