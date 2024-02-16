// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract VoterBank {
    using SafeERC20 for IERC20;

    constructor(address _token) {
        token = _token;
    }

    uint256 id;
    uint256 protocolFee = 0.5 ether;
    uint256 bank;
    address token;
    uint256 reward;

    struct PlayerPari {
        uint256 eventId;
        address playerAdress;
        uint256 betAmount;
        bool betTarget;
    }

    struct PlayerLive {
        uint256 eventId;
        address playerAdress;
        uint256 betAmount;
        uint256 numberOfVotes;
    }

    mapping(uint256 => PlayerPari) public playerPari;
    mapping(uint256 => PlayerLive) public playerLive;
    mapping(uint256 => uint256) public bankAmount;
    mapping(uint256 => uint256) public target0BankAmount;
    mapping(uint256 => uint256) public target1BankAmount;

    function setPari(uint256 _eventId, uint256 betId, address _playerAdress, bool _betTarget, uint256 _betAmount) public {

        playerPari[betId] = PlayerPari({
            eventId: _eventId,
            playerAdress: _playerAdress,
            betAmount: _betAmount,
            betTarget: _betTarget
        });

        bankAmount[_eventId] +=  _betAmount;

        if(_betTarget == true) {
            target1BankAmount[_eventId] +=  _betAmount;
        } else {
            target0BankAmount[_eventId] +=  _betAmount;
        }
        
        // IERC20(token).transferFrom(msg.sender, address(this), _betAmount);

    }

    function takePariPrize(uint256 _eventId, uint256 betId) public returns(uint256){
        require(playerPari[betId].eventId == _eventId, 'Event mismatch');
        if(playerPari[betId].betTarget == true) {
            reward = bankAmount[_eventId] * playerPari[betId].betAmount / target1BankAmount[_eventId] - protocolFee;
            return reward;
        } else {
            reward = bankAmount[_eventId] * playerPari[betId].betAmount / target0BankAmount[_eventId] - protocolFee;
            return reward;
        }
        
        // IERC20(token).safeTransfer(msg.sender, reward);

    }





    function getPlayerPari(uint256 betId) public view returns(uint256) {
        return playerPari[betId].betAmount;
    }

    function getTarget1BankAmount(uint256 _eventId) public view returns(uint256) {
        return target1BankAmount[_eventId];
    }

    function getBankAmount(uint256 _eventId) public view returns(uint256) {
        return bankAmount[_eventId];
    }

}