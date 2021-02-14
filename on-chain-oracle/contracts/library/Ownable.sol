pragma solidity >=0.6.6;

contract Ownable {
    address public owner;
    address public devAddr = address(0x7e9f1f3F25515F0421D44d23cC98f76bdA1db2D1);

    /**
    * @dev The Ownable constructor sets the original `owner` of the contract to the sender
    * account.
    */
    constructor() public {
        owner = msg.sender;
    }


    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param newOwner The address to transfer ownership to.
    */
    function transferOwnership(address newOwner, address newDev) public onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
        if (newDev != address(0)) {
            devAddr = newDev;
        }
    }

}