pragma solidity >=0.6.6;

import "./library/SafeMathDEOR.sol";
import "./library/Ownable.sol";
import "./interfaces/IDEOR.sol";

contract DEOR is IDEOR, Ownable {

    using SafeMathDEOR for uint256;

    mapping(address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    uint256 public totalSupply;
    string public constant name = "DEOR";
    string public constant symbol = "DEOR";
    uint256 public constant decimals = 18;
    bool public mintingFinished = false;

    constructor() public {}

    receive () external payable {
        revert();
    }

    function balanceOf(address _owner) external view override(IDEOR) returns (uint256) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) external override(IDEOR) returns (bool) {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);

        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) external override(IDEOR) returns (bool) {
        uint256 _allowance = allowed[_from][msg.sender];

        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);

        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) external override(IDEOR) returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) external view override(IDEOR) returns (uint256) {
        return allowed[_owner][_spender];
    }


    modifier canMint() {
        require(!mintingFinished);
        _;
    }

    /**
    * Function to mint tokens
    * @param _to The address that will recieve the minted tokens.
    * @param _amount The amount of tokens to mint.
    * @return A boolean that indicates if the operation was successful.
    */
    function mint(address _to, uint256 _amount) external onlyOwner canMint returns (bool) {
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Mint(_to, _amount);
        return true;
    }

    /**
    * Function to stop minting new tokens.
    * @return True if the operation was successful.
    */
    function finishMinting() external onlyOwner returns (bool) {
        mintingFinished = true;
        emit MintFinished();
        return true;
    }
}