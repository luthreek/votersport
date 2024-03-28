// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract VoterBankPari is Pausable, AccessControl, ReentrancyGuard {
    using SafeERC20 for IERC20;

    error InvalidAmount();
    error EventMissMath();
    error InvalidStatus();
    error NotOperator();
    error NotOwner();

    event MoneyReceived(address indexed _from, uint256 _amount);

    constructor(address _token, address operator, address owner) {
        _grantRole(DEFAULT_ADMIN_ROLE, owner);
        _grantRole(OPERATOR_ROLE, operator);
        token = _token;
    }

    address token;

    struct Player {
        uint256 eventId;
        address playerAdress;
        uint256 betAmount;
    }

    enum Status {
        OPEN,
        CLOSED,
        DRAW
    }

    Status public status;
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    mapping(uint256 => Player) public playerBet;
    mapping(uint256 => uint256) public bankAmount;
    mapping(uint256 => Status) public pariStatus;

    function pause() public {
        _validateIsOwner();
        _pause();
    }

    function unpause() public {
        _validateIsOwner();
        _unpause();
    }

    function setBet(uint256 _eventId, uint256 betId, address _playerAdress, uint256 _betAmount)
        public
        whenNotPaused
        nonReentrant
    {
        if (pariStatus[_eventId] != Status.OPEN) revert InvalidStatus();
        playerBet[betId] = Player({eventId: _eventId, playerAdress: _playerAdress, betAmount: _betAmount});

        bankAmount[_eventId] += _betAmount;

        IERC20(token).safeTransferFrom(_playerAdress, address(this), _betAmount);
    }

    function takeBetPrize(uint256 _eventId, uint256 betId, uint256 _reward) public whenNotPaused nonReentrant {
        _validateIsOperator();
        if (pariStatus[_eventId] != Status.CLOSED) revert InvalidStatus();
        if (playerBet[betId].eventId != _eventId) revert EventMissMath();
        if (_reward > bankAmount[_eventId]) revert InvalidAmount();
        address player = playerBet[betId].playerAdress;
        delete playerBet[betId];
        bankAmount[_eventId] -= _reward;
        IERC20(token).transfer(player, _reward);
    }

    function stopPariBets(uint256 _eventId) public {
        _validateIsOperator();
        pariStatus[_eventId] = Status.CLOSED;
    }

    function stopPariPrize(uint256 _eventId) public returns (uint256) {
        _validateIsOperator();
        pariStatus[_eventId] = Status.DRAW;
        return bankAmount[_eventId];
    }

    function transferFees(address _to, uint256[] calldata _eventIds) public {
        _validateIsOwner();
        uint256 fees = 0;
        for (uint256 i = 0; i < _eventIds.length;) {
            if (pariStatus[_eventIds[i]] == Status.DRAW) {
                fees = bankAmount[_eventIds[i]];
                delete bankAmount[_eventIds[i]];
            }
            unchecked {
                i++;
            }
        }
        if (fees > IERC20(token).balanceOf(address(this)) || fees == 0) revert InvalidAmount();
        IERC20(token).transfer(_to, fees);
    }

    function getBalance() public view returns (uint256) {
        return IERC20(token).balanceOf(address(this));
    }

    function _validateIsOperator() private view {
        if (!hasRole(OPERATOR_ROLE, msg.sender)) revert NotOperator();
    }

    function _validateIsOwner() private view {
        if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) revert NotOwner();
    }

    fallback() external payable {}

    receive() external payable {
        emit MoneyReceived(msg.sender, msg.value);
    }
}
