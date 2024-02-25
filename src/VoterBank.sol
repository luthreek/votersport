// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract VoterBank is Pausable, Ownable{
    using SafeERC20 for IERC20;

    event MoneyReceived(address indexed _from, uint256 _amount);

    constructor(address _token, address owner) Ownable(owner) {
        token = _token;
    }

    uint256 id;
    uint256 protocolFee = 0.5 ether;
    uint256 bank;
    address token;
    uint256 reward;

    struct Player {
        uint256 eventId;
        address playerAdress;
        uint256 betAmount;
    }

    mapping(uint256 => Player) public playerBet;
    mapping(uint256 => uint256) public bankAmount;
    mapping(uint256 => uint256) public target0BankAmount;
    mapping(uint256 => uint256) public target1BankAmount;

        function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function setBet(uint256 _eventId, uint256 betId, address _playerAdress, uint256 _betAmount) public {

        playerBet[betId] = Player({
            eventId: _eventId,
            playerAdress: _playerAdress,
            betAmount: _betAmount
        });

        bankAmount[_eventId] +=  _betAmount;


        
        IERC20(token).transferFrom(_playerAdress, address(this), _betAmount);

    }

    function takeBetPrize(uint256 _eventId, uint256 betId, uint256 _reward) public {
        require(playerBet[betId].eventId == _eventId, 'Event mismatch');
        require(_reward >= bankAmount[_eventId], 'Reward is greater than the Bank');

        address player = playerBet[betId].playerAdress;
        
        IERC20(token).safeTransfer(player, _reward);

    }

    fallback() external payable {}
    receive() external payable {
    emit MoneyReceived(msg.sender, msg.value);}


}