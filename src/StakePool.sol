// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol"
import "@openzeppelin/contracts//utils/Pausable.sol"
contract TokenStaking is SafeERC20,Ownable2Step,Pausable{
    using Math for uint256;
    struct Stake {
        uint256 amount;
        uint256 startTime;
        uint256 profitPercentage; // Percentage of profit for the stake
    }

    mapping(address => Stake) public stakes;

    IERC20 public token;
    uint256 public stakingDuration;
    uint256 profitPercentage;

    event Staked(address indexed staker, uint256 amount);
    event Unstaked(address indexed staker, uint256 amount, uint256 profit);

    constructor(IERC20 _token, uint256 _stakingDuration,uint256 _profitPercentage) {
        token = _token;
        stakingDuration = _stakingDuration;
        profitPercentage=_profitPercentage;
    }

    function stake(uint256 _amount) external whenNotPaused{
        require(_amount > 0, "Amount must be greater than 0");
        require(stakes[msg.sender].amount == 0, "Already staked");
        require(_profitPercentage <= 100, "Profit percentage must be less than or equal to 100");
        stakes[msg.sender] = Stake(_amount, block.timestamp, _profitPercentage);
        require(safeTransferFrom(token,msg.sender, address(this), _amount), "Transfer failed");

        
        emit Staked(msg.sender, _amount);
    }

    function unstake() external whenNotPaused {
        require(stakes[msg.sender].amount > 0, "No stake");
        require(block.timestamp >= stakes[msg.sender].startTime.add(stakingDuration), "Staking duration not passed");

        uint256 stakedAmount = stakes[msg.sender].amount;
        delete stakes[msg.sender];

        uint256 profit = stakedAmount.mul(profitPercentage).div(100);

        uint256 totalAmount = stakedAmount.add(profit);
        uint256 tokenBalance = token.balanceOf(address(this));
        uint256 amountToReturn = totalAmount > tokenBalance ? tokenBalance : totalAmount;

        require(safeTransfer(token,msg.sender, amountToReturn), "Transfer failed");

        emit Unstaked(msg.sender, stakedAmount, profit);
    }
    function changeProfitPercentage(uint256 _newProfitPercentage) external onlyOwner {
        require(_newProfitPercentage <= 100, "Profit percentage must be less than or equal to 100");
        profitPercentage = _newProfitPercentage;
    }
    function _pause() internal virtual override onlyOwner {
        _paused = (!_paused);
    }
    function getStake(address _address) external view returns (uint256, uint256, uint256) whenNotPaused {
        return (stakes[_address].amount, stakes[_address].startTime, stakes[_address].profitPercentage);
    }
}