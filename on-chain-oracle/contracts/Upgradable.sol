pragma solidity >=0.6.6;

import "./library/Ownable.sol";
import "./interfaces/IUpgradable.sol";

contract Upgradable is Ownable, IUpgradable {
    address public oracle;

    constructor (address oracleAddress) public {
        oracle = oracleAddress;
    }

    function getOracleAddress() public override(IUpgradable) returns (address) {
        return oracle;
    }

    function upgradeOracleAddress (address newOracle) public onlyOwner {
        oracle = newOracle;
    }
}
