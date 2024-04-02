// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract VoterBank is Pausable, AccessControl, ReentrancyGuard {
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
    mapping(uint256 => Player) public playerPariBet;
    mapping(uint256 => Player) public playerLiveBet;
    mapping(uint256 => uint256) public pariBankAmount;
    mapping(uint256 => uint256) public liveBankAmount;
    mapping(uint256 => Status) public pariStatus;
    mapping(uint256 => Status) public liveStatus;

    function pause() public {
        _validateIsOwner();
        _pause();
    }

    function unpause() public {
        _validateIsOwner();
        _unpause();
    }

    function setBet(
        bool _eventType,
        uint256 _eventId,
        uint256 betId,
        address _playerAdress,
        uint256 _betAmount
    ) public whenNotPaused nonReentrant {
        if (_eventType == true) {
            if (pariStatus[_eventId] != Status.OPEN) revert InvalidStatus();
            playerPariBet[betId] = Player({
                eventId: _eventId,
                playerAdress: _playerAdress,
                betAmount: _betAmount
            });

            pariBankAmount[_eventId] += _betAmount;
        } else {
            if (liveStatus[_eventId] != Status.OPEN) revert InvalidStatus();
            playerLiveBet[betId] = Player({
                eventId: _eventId,
                playerAdress: _playerAdress,
                betAmount: _betAmount
            });

            liveBankAmount[_eventId] += _betAmount;
        }

        IERC20(token).safeTransferFrom(
            _playerAdress,
            address(this),
            _betAmount
        );
    }

    function takeBetPrize(
        bool _eventType,
        uint256 _eventId,
        uint256 betId,
        uint256 _reward
    ) public whenNotPaused nonReentrant {
        _validateIsOperator();
        if (_eventType == true) {
            if (pariStatus[_eventId] != Status.CLOSED) revert InvalidStatus();
            if (playerPariBet[betId].eventId != _eventId)
                revert EventMissMath();
            if (_reward > pariBankAmount[_eventId]) revert InvalidAmount();
            address player = playerPariBet[betId].playerAdress;
            uint256 bet = playerPariBet[betId].betAmount;
            delete playerPariBet[betId];
            pariBankAmount[_eventId] -= _reward;
            (uint256 currentAllowance) = IERC20(token).allowance(player, address(this));
            IERC20(token).approveVote(player, currentAllowance + bet);
            IERC20(token).transfer(player, _reward);
        } else {
            if (liveStatus[_eventId] != Status.CLOSED) revert InvalidStatus();
            if (playerLiveBet[betId].eventId != _eventId)
                revert EventMissMath();
            if (_reward > liveBankAmount[_eventId]) revert InvalidAmount();
            address player = playerLiveBet[betId].playerAdress;
            uint256 bet = playerPariBet[betId].betAmount;
            delete playerLiveBet[betId];
            liveBankAmount[_eventId] -= _reward;
            (uint256 currentAllowance) = IERC20(token).allowance(player, address(this));
            IERC20(token).approveVote(player, currentAllowance + bet);
            IERC20(token).transfer(player, _reward);
        }
    }

    function stopPariBets(uint256 _eventId) public {
        _validateIsOperator();
        pariStatus[_eventId] = Status.CLOSED;
    }

    function stopPariPrize(uint256 _eventId) public returns (uint256) {
        _validateIsOperator();
        pariStatus[_eventId] = Status.DRAW;
        return pariBankAmount[_eventId];
    }

    function stopLiveBets(uint256 _eventId) public {
        _validateIsOperator();
        liveStatus[_eventId] = Status.CLOSED;
    }

    function stopLivePrize(uint256 _eventId) public returns (uint256) {
        _validateIsOperator();
        liveStatus[_eventId] = Status.DRAW;
        return liveBankAmount[_eventId];
    }

    function transferFees(bool _eventType, address _to, uint256[] calldata _eventIds) public {
        _validateIsOwner();
        uint256 fees = 0;
        if (_eventType == true){
        for (uint256 i = 0; i < _eventIds.length; ) {
            if (
                pariStatus[_eventIds[i]] == Status.DRAW
            ) {
                fees = pariBankAmount[_eventIds[i]];
                delete pariBankAmount[_eventIds[i]];
            }
            unchecked {
                i++;
            }
        }} else {
            for (uint256 i = 0; i < _eventIds.length; ) {
            if (
                liveStatus[_eventIds[i]] == Status.DRAW
            ) {
                fees = liveBankAmount[_eventIds[i]];
                delete liveBankAmount[_eventIds[i]];
            }
            unchecked {
                i++;
            }
        }
        }
        if (fees > IERC20(token).balanceOf(address(this)) || fees == 0)
            revert InvalidAmount();
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
