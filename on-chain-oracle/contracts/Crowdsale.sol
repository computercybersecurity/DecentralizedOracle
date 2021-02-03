pragma solidity >=0.6.6;

import "./library/SafeMathDEOR.sol";
import "./library/Ownable.sol";
import "./interfaces/IDEOR.sol";

contract Crowdsale is Ownable {
    using SafeMathDEOR for uint256;

	/* if the funding goal is not reached, investors may withdraw their funds */
	uint256 public fundingGoal = 2000 * (10**18);
	/* the maximum amount of tokens to be sold */
	uint256 public maxGoal = 20000000 * (10**10);
	/* how much has been raised by crowdale (in ETH) */
	uint256 public amountRaised;
	/* the start date of the crowdsale */
	uint256 public start = 1488294000;
	/* there are different prices in different time intervals */
	uint256 public deadline = 1490112000;
	/* the address of the token contract */
	IDEOR public tokenReward;
	/* the balances (in ETH) of all investors */
	mapping(address => uint256) public balanceOf;
	address[] private investors;
	/* indicated if the funding goal has been reached. */
	bool fundingGoalReached = false;
	/* indicates if the crowdsale has been closed already */
	bool crowdsaleClosed = false;
	/* notifying transfers and the success of the crowdsale*/
	event GoalReached(address beneficiary, uint256 amountRaised);
	event SetStartTime(uint256 time);
	event SetDeadline(uint256 time);
	event FundTransfer(address backer, uint256 amount, bool isContribution, uint256 amountRaised);

    /*  initialization, set the token address */
    constructor(address token) public {
        tokenReward = IDEOR(token);
    }

    /* invest by sending ether to the contract. */
    receive () external payable {
		if(msg.sender != owner) //do not trigger investment if the multisig wallet is returning the funds
        	invest();
		else revert();
    }

	function setStartTime(uint256 time) public onlyOwner {
		start = time;
		emit SetStartTime(time);
	}

	function setDeadline(uint256 time) public onlyOwner {
		deadline = time;
		emit SetDeadline(time);
	}

    /* make an investment
    *  only callable if the crowdsale started and hasn't been closed already and the maxGoal wasn't reached yet.
    *  the current token price is looked up and the corresponding number of tokens is transfered to the receiver.
    *  the sent value is directly forwarded to a safe multisig wallet.
    *  this method allows to purchase tokens in behalf of another address.*/
    function invest() public payable {
    	uint256 amount = msg.value;
		require(crowdsaleClosed == false && now >= start, "Crowdsale is closed");

		if (balanceOf[msg.sender] == 0) {
			investors.push(msg.sender);
		}

		balanceOf[msg.sender] = balanceOf[msg.sender].add(amount);
		amountRaised = amountRaised.add(amount);

        emit FundTransfer(msg.sender, amount, true, amountRaised);
    }

    modifier afterDeadline() { if (now >= deadline) _; }

    /* allows the funders to withdraw their funds if the goal has not been reached.
	*  only works after funds have been returned from the multisig wallet. */
	function finalizeICO() public onlyOwner afterDeadline {
		require(crowdsaleClosed == false && now >= start, "Crowdsale is closed");
		uint256 price = maxGoal.div(amountRaised);
		uint256 totalEth = 0;
		for (uint256 i = 0 ; i < investors.length ; i ++) {
			uint256 numTokens = price.mul(balanceOf[investors[i]]);
			if (tokenReward.transferFrom(owner, investors[i], numTokens)) {
				totalEth = totalEth.add(balanceOf[investors[i]]);
				balanceOf[investors[i]] = 0;
			}
		}
        if (totalEth >= fundingGoal) {
            fundingGoalReached = true;
            GoalReached(owner, totalEth);
        }
        crowdsaleClosed = true;
    }
}