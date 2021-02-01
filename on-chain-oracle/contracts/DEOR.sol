pragma solidity >=0.6.6;

import "./library/SafeMathDEOR.sol";
import "./library/Ownable.sol";
import "./interfaces/IDEOR.sol";

contract DEOR is IDEOR, Ownable {

    using SafeMathDEOR for uint256;

    mapping(address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    string public constant name = "DEOR";
    string public constant symbol = "DEOR";
    uint256 public constant decimals = 10;
    uint256 public totalSupply;
    uint256 public maxSupply = 100000000 * (10**decimals);
    bool public mintingFinished = false;
    bool public burned = false;
	uint256 public startTime = 1488294000;

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
        uint256 amount = maxSupply.sub(totalSupply);
        if (amount > _amount) amount = _amount;
        else this.finishMinting();
        totalSupply = totalSupply.add(amount);
        balances[_to] = balances[_to].add(amount);
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

    /* to be called when ICO is closed, burns the remaining tokens but the owners share (50 000 000) and the ones reserved
    *  for the bounty program (10 000 000).
    *  anybody may burn the tokens after ICO ended, but only once (in case the owner holds more tokens in the future).
    *  this ensures that the owner will not posses a majority of the tokens. */
    function burn() external override(IDEOR) {
    	//if tokens have not been burned already and the ICO ended
    	if(!burned && now > startTime){
    		uint difference = balances[owner].sub(5000000 * (10**decimals));//checked for overflow above
    		balances[owner] = 5000000 * (10**decimals);
    		totalSupply = totalSupply.sub(difference);
    		burned = true;
    		Burned(difference);
    	}
    }
}