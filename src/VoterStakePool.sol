// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract VoterStakePool is Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Math for uint256;

    struct Stake {
        uint256 amount;
        uint256 startTime;
        uint256 profitPercentage;
    }

    error InvalidAmount();

    mapping(address => Stake) public stakes;

    // Адрес токена для стейкинга
    address public token;
    uint256 public stakingDuration;
    uint256 public profitPercentage;

    event Staked(address indexed staker, uint256 amount);
    event Unstaked(address indexed staker, uint256 amount, uint256 profit);

    constructor(address _token, uint256 _stakingDuration, uint256 _profitPercentage, address _owner) Ownable(_owner) {
        token = _token;
        stakingDuration = _stakingDuration;
        profitPercentage = _profitPercentage;
    }

    /// @notice Функция стейкинга: переводит токены от стейкера на контракт
    function stake(uint256 _amount) external nonReentrant whenNotPaused {
        require(_amount > 0, "Invalid Amount");
        require(stakes[msg.sender].amount == 0, "Already staked");
        // Переводим токены от стейкера на адрес контракта
        IERC20(token).safeTransferFrom(msg.sender, address(this), _amount);
        stakes[msg.sender] = Stake(_amount, block.timestamp, profitPercentage);
        emit Staked(msg.sender, _amount);
    }

    /// @notice Функция анстейкинга: возвращает стейкеру токены с прибылью, если прошёл период стейкинга
    function unstake() external nonReentrant whenNotPaused {
        require(stakes[msg.sender].amount > 0, "No stake");
        require(block.timestamp >= stakes[msg.sender].startTime + stakingDuration, "Staking duration not passed");

        uint256 stakedAmount = stakes[msg.sender].amount;
        delete stakes[msg.sender];

        uint256 profit = stakedAmount * profitPercentage / 100;
        uint256 totalAmount = stakedAmount + profit;
        uint256 tokenBalance = IERC20(token).balanceOf(address(this));
        uint256 amountToReturn = totalAmount > tokenBalance ? tokenBalance : totalAmount;
        // Переводим токены обратно стейкеру
        IERC20(token).safeTransfer(msg.sender, amountToReturn);
        emit Unstaked(msg.sender, stakedAmount, profit);
    }

    function changeProfitPercentage(uint256 _newProfitPercentage) external onlyOwner {
        require(_newProfitPercentage <= 100, "Profit percentage must be less than or equal to 100");
        profitPercentage = _newProfitPercentage;
    }

    function SwitchPaused() external onlyOwner {
        if (paused()) {
            _unpause();
        } else {
            _pause();
        }
    }

    function getStake(address _address) external view returns (uint256, uint256, uint256) {
        return (stakes[_address].amount, stakes[_address].startTime, stakes[_address].profitPercentage);
    }
}
