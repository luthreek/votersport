// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./VoterSport.sol";

contract VoterBank is Pausable, AccessControl, ReentrancyGuard {
    using SafeERC20 for IERC20;

    error InvalidAmount();
    error EventMissMath();
    error InvalidStatus();
    error NotOperator();
    error NotOwner();

    event MoneyReceived(address indexed _from, uint256 _amount);
    event SetBet(
        bool _eventType, address indexed _playerAdress, uint256 indexed _eventId, uint256 betId, uint256 amount
    );
    event ClaimPrize(bool _eventType, address indexed player, uint256 indexed _eventId, uint256 betId, uint256 _reward);
    event StatusPariChange(uint256 indexed _eventId, Status status);
    event StatusLiveChange(uint256 indexed _eventId, Status status);

    constructor(address _token, address operator, address owner) {
        _grantRole(DEFAULT_ADMIN_ROLE, owner);
        _setRoleAdmin(OPERATOR_ROLE, DEFAULT_ADMIN_ROLE);
        _grantRole(OPERATOR_ROLE, operator);
        token = _token;
    }

    address token;
    address mainWallet;
    

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

    function setMainWallet(address _mainWallet) public {
        _validateIsOwner();
        mainWallet = _mainWallet;
    }

    function setBet(bool _eventType, uint256 _eventId, uint256 betId, address _playerAdress, uint256 _betAmount)
        public
        whenNotPaused
        nonReentrant
    {
        if (_eventType == true) {
            if (pariStatus[_eventId] != Status.OPEN) revert InvalidStatus();
            playerPariBet[betId] = Player({eventId: _eventId, playerAdress: _playerAdress, betAmount: _betAmount});

            pariBankAmount[_eventId] += _betAmount;
        } else {
            if (liveStatus[_eventId] != Status.OPEN) revert InvalidStatus();
            playerLiveBet[betId] = Player({eventId: _eventId, playerAdress: _playerAdress, betAmount: _betAmount});

            liveBankAmount[_eventId] += _betAmount;
        }

        IERC20(token).safeTransferFrom(_playerAdress, address(this), _betAmount);
        emit SetBet(_eventType, _playerAdress, _eventId, betId, _betAmount);
    }

    function takeBetPrize(bool _eventType, uint256 _eventId, uint256 betId, uint256 _reward)
        public
        whenNotPaused
        nonReentrant
    {
        _validateIsOperator();
        if (_eventType == true) {
            if (pariStatus[_eventId] != Status.CLOSED) revert InvalidStatus();
            if (playerPariBet[betId].eventId != _eventId) {
                revert EventMissMath();
            }
            if (_reward > pariBankAmount[_eventId]) revert InvalidAmount();
            address player = playerPariBet[betId].playerAdress;
            
            delete playerPariBet[betId];
            pariBankAmount[_eventId] -= _reward;
            (uint256 currentAllowance) = IERC20(token).allowance(player, address(this));
            VoterSport(token).approveVote(player, currentAllowance + _reward);
            IERC20(token).safeTransfer(player, _reward);
            emit ClaimPrize(_eventType, player, _eventId, betId, _reward);
        } else {
            if (liveStatus[_eventId] != Status.CLOSED) revert InvalidStatus();
            if (playerLiveBet[betId].eventId != _eventId) {
                revert EventMissMath();
            }
            if (_reward > liveBankAmount[_eventId]) revert InvalidAmount();
            address player = playerLiveBet[betId].playerAdress;
            delete playerLiveBet[betId];
            liveBankAmount[_eventId] -= _reward;
            (uint256 currentAllowance) = IERC20(token).allowance(player, address(this));
            VoterSport(token).approveVote(player, currentAllowance + _reward);
            IERC20(token).safeTransfer(player, _reward);
            emit ClaimPrize(_eventType, player, _eventId, betId, _reward);
        }
    }

    function stopPariBets(uint256 _eventId) public {
        _validateIsOperator();
        pariStatus[_eventId] = Status.CLOSED;
        emit StatusPariChange(_eventId, pariStatus[_eventId]);
    }

    function stopPariPrize(uint256 _eventId) public {
        _validateIsOperator();
        uint256 fees;
        pariStatus[_eventId] = Status.DRAW;
        emit StatusPariChange(_eventId, pariStatus[_eventId]);
        fees = pariBankAmount[_eventId];
        delete pariBankAmount[_eventId];
        // if (fees > IERC20(token).balanceOf(address(this)) || fees == 0) {
        //     revert InvalidAmount();
        // }
        IERC20(token).transfer(mainWallet, fees);
    }

    function stopLiveBets(uint256 _eventId) public {
        _validateIsOperator();
        liveStatus[_eventId] = Status.CLOSED;
        emit StatusLiveChange(_eventId, liveStatus[_eventId]);
    }

    function stopLivePrize(uint256 _eventId) public {
        _validateIsOperator();
        uint256 fees;
        liveStatus[_eventId] = Status.DRAW;
        emit StatusLiveChange(_eventId, liveStatus[_eventId]);
        fees = liveBankAmount[_eventId];
        delete liveBankAmount[_eventId];
        // if (fees > IERC20(token).balanceOf(address(this)) || fees == 0) {
        //     revert InvalidAmount();
        // }
        IERC20(token).transfer(mainWallet, fees);
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
