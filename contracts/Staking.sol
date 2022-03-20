//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract Staking is ERC20, Ownable {

    uint private tokenBuyPrice; // Price of 1 token in wei
    uint private constant REWARD_FACTOR = 100; // 1 percent is same as divide by 100
    mapping(address => uint) private stakes;
    mapping(address => uint ) private timeOfStake;
    mapping (address => uint) private weeklyReward;


    constructor (uint _tokenBuyPrice) ERC20("StakingERC20", "STK"){
        tokenBuyPrice = _tokenBuyPrice;
        _mint(msg.sender, 1000 * 10 ** decimals());
    }

    function modifyTokenBuyPrice(uint newPrice) public onlyOwner {
        tokenBuyPrice = newPrice;
    }

    function buyToken(address receiver) public payable {
        require(msg.value > 0, "You didn't provide any value");
        require(valueIsMultipleOfTokenBuyPrice(msg.value), "Value should be a multiple of token price in wei");
        _mint(receiver, msg.value / tokenBuyPrice);

        withdrawPayment();
    }

    function decreaseStake(uint reduceBy) public returns (bool) {
        require(stakes[msg.sender] >= reduceBy, "Insufficient Stake");
        uint newStake = stakes[msg.sender] - reduceBy;
        require(stakeIsMultipleOfRewardFactor(newStake), "Stake in units should be a multiple of 100");

        updateStake(newStake);

        return ERC20(address(this)).transfer(msg.sender, reduceBy);
    }

    function increaseStake(uint increaseBy) public returns (bool) {
        require(balanceOf(msg.sender) >= increaseBy, "Insufficient Balance");
        uint newStake = stakes[msg.sender] + increaseBy;
        require(stakeIsMultipleOfRewardFactor(newStake), string(abi.encodePacked("Stake should be a multiple of ", REWARD_FACTOR)));

        updateStake(newStake);

        return transfer(address(this), increaseBy);
    }

    function claimReward() public returns (bool){
        require(canClaimReward(), "You can't claim reward now");

        ERC20(address(this)).transfer(msg.sender, weeklyReward[msg.sender]);
        timeOfStake[msg.sender] = block.timestamp;

        return true;
    }

    function getBalances() public view returns (uint, uint, uint) {
        return (stakes[msg.sender], balanceOf(msg.sender), canClaimReward() ? weeklyReward[msg.sender] : 0);
    }

    function withdrawPayment() internal {
        (bool sent, bytes memory data) = payable(owner()).call{value: msg.value}("");
        require(sent, "Failed to send Ether");
    }

    function valueIsMultipleOfTokenBuyPrice(uint value) internal view returns (bool){
        return value % tokenBuyPrice == 0;
    }

    function stakeIsMultipleOfRewardFactor(uint toStake) internal pure returns (bool) {
        return toStake % REWARD_FACTOR == 0;
    }

    // Reward can be claimed on the seventh day and only once on that day
    function canClaimReward() internal view returns (bool) {
        return  block.timestamp >= timeOfStake[msg.sender] + 7 days; 
    }

    function updateStake(uint newStake) internal {
        stakes[msg.sender] = newStake;
        weeklyReward[msg.sender] = newStake / REWARD_FACTOR;
        timeOfStake[msg.sender] = block.timestamp;
    }
    
}