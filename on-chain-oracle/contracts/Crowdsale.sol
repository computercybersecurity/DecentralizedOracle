pragma solidity >=0.6.6;

import "./library/SafeMathDEOR.sol";
import "./library/Ownable.sol";
import "./interfaces/IDEOR.sol";

contract Crowdsale is Ownable {
    using SafeMathDEOR for uint256;

	/* if the funding goal is not reached, investors may withdraw their funds */
	uint256 public fundingGoal = 10000000 * (10**10);
	/* the maximum amount of tokens to be sold */
	uint256 public maxGoal = 20000000 * (10**10);
	/* how much has been raised by crowdale (in ETH) */
	uint256 public amountRaised;
	/* the start date of the crowdsale */
	uint256 public start = 1488294000;
	/* the number of tokens already sold */
	uint256 public tokensSold;
	/* there are different prices in different time intervals */
	uint256[4] public deadlines = [1488297600, 1488902400, 1489507200,1490112000];
	uint256[4] public prices = [100000000, 100000000, 100000000, 100000000];
	/* the address of the token contract */
	IDEOR public tokenReward;
	/* the balances (in ETH) of all investors */
	mapping(address => uint256) public balanceOf;
	/* indicated if the funding goal has been reached. */
	bool fundingGoalReached = false;
	/* indicates if the crowdsale has been closed already */
	bool crowdsaleClosed = false;
	/* notifying transfers and the success of the crowdsale*/
	event GoalReached(address beneficiary, uint256 amountRaised);
	event FundTransfer(address backer, uint256 amount, bool isContribution, uint256 amountRaised);

    /*  initialization, set the token address */
    constructor(address token) public {
        tokenReward = IDEOR(token);
    }

    /* invest by sending ether to the contract. */
    receive () external payable {
		if(msg.sender != owner) //do not trigger investment if the multisig wallet is returning the funds
        	invest();
    }

    /* make an investment
    *  only callable if the crowdsale started and hasn't been closed already and the maxGoal wasn't reached yet.
    *  the current token price is looked up and the corresponding number of tokens is transfered to the receiver.
    *  the sent value is directly forwarded to a safe multisig wallet.
    *  this method allows to purchase tokens in behalf of another address.*/
    function invest() public payable {
    	uint256 amount = msg.value;
    	uint256 price = getPrice();
        require(price <= amount, "You should buy at least 1 DEOR");
		uint256 numTokens = amount.div(price);
        require(crowdsaleClosed == false && now >= start && tokensSold.add(numTokens) <= maxGoal, "");

		balanceOf[msg.sender] = balanceOf[msg.sender].add(amount);
		amountRaised = amountRaised.add(amount);
		tokensSold = tokensSold.add(numTokens);

        require(tokenReward.transferFrom(owner, msg.sender, numTokens), "DEOR transaction failed.");

        emit FundTransfer(msg.sender, amount, true, amountRaised);
    }

    function getPrice() private view returns (uint256 price){
        for(uint256 i = 0; i < deadlines.length; i++)
            if(now < deadlines[i])
                return prices[i];
        return prices[prices.length - 1]; //should never be returned, but to be sure to not divide by 0
    }

    modifier afterDeadline() { if (now >= deadlines[deadlines.length-1]) _; }

    /* checks if the goal or time limit has been reached and ends the campaign */
    function checkGoalReached() public onlyOwner afterDeadline {
        if (tokensSold >= fundingGoal){
            fundingGoalReached = true;
            tokenReward.burn(); //burn remaining tokens but 60 000 000
            GoalReached(owner, amountRaised);
        }
        crowdsaleClosed = true;
    }

    /* allows the funders to withdraw their funds if the goal has not been reached.
	*  only works after funds have been returned from the multisig wallet. */
	function safeWithdrawal() public onlyOwner afterDeadline {
		uint256 amount = balanceOf[msg.sender];
		if(owner.balance >= amount){
			balanceOf[msg.sender] = 0;
			if (amount > 0) {
				if (msg.sender.send(amount)) {
					FundTransfer(msg.sender, amount, false, amountRaised);
				} else {
					balanceOf[msg.sender] = amount;
				}
			}
		}
    }
}