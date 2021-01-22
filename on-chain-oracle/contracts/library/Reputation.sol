pragma solidity >=0.4.21 <0.6.0;

/**
 * @title Library for common oracle reputation
 * @dev 
 */
import "./SafeMath.sol";

library Reputation {
    using SafeMath for uint256;
    struct reputation {
        address addr;
        uint256 totalAssignedRequest;        //total number of past requests that an oracle has agreed to, both fulfilled and unfulfileed
        uint256 totalCompletedRequest;       //total number of past requests that an oracle has fulfileed
        uint256 totalAcceptedRequest;        //total number of requests that have been accepted
        uint256 totalResponseTime;           //total seconds of response time
        uint256 lastActiveTime;              //last active time of the oracle as second
        uint256 score;                       //reputation score
    }

    function calculateScore(reputation memory self) internal pure returns (uint256) {
        uint256 x = (self.totalAcceptedRequest.mul(100)).div(self.totalAssignedRequest);
        uint256 b = self.totalCompletedRequest.log_2();
        if (b > 16) {
            b = 16;
        }
        uint256 res = (x.mul(b) * 9).div(1600) + 1;
        return res;
    }

    function activityValidate(reputation memory self) internal view returns (uint256) {
        uint256 ACTIVE_EXPIRY_TIME = 1 days;
        return block.timestamp.sub(self.lastActiveTime) < ACTIVE_EXPIRY_TIME ? 1 : 0;
    }
}