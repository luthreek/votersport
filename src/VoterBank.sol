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

    address token;
    uint256 reward;

    struct Player {
        uint256 eventId;
        address playerAdress;
        uint256 betAmount;
    }

    enum Status {
        OPEN,
        CLOSED
    }

    Status public status;

    mapping(uint256 => Player) public playerBet;
    mapping(uint256 => uint256) public bankAmount;
    mapping(uint256 => Status) public pariStatus;

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function setBet(uint256 _eventId, uint256 betId, address _playerAdress, uint256 _betAmount) public whenNotPaused{
        require(pariStatus[_eventId] != Status.CLOSED, 'Pari for this event is closed');

        playerBet[betId] = Player({
            eventId: _eventId,
            playerAdress: _playerAdress,
            betAmount: _betAmount
        });

        bankAmount[_eventId] +=  _betAmount;


        IERC20(token).approve(_playerAdress, _betAmount);
        IERC20(token).safeTransferFrom(_playerAdress, address(this), _betAmount);

    }

    function takeBetPrize(uint256 _eventId, uint256 betId, uint256 _reward) public whenNotPaused{
        require(playerBet[betId].eventId == _eventId, 'Event mismatch');
        require(_reward >= bankAmount[_eventId], 'Reward is greater than the Bank');

        address player = playerBet[betId].playerAdress;

        delete playerBet[betId];
        IERC20(token).approve(address(this), _reward);
        IERC20(token).safeTransferFrom(address(this), player, _reward);

    }

    function stopPariBets(uint256 _eventId) public {
        pariStatus[_eventId] = Status.CLOSED;
    }

    function transferFees(address _to, uint256 _amount) public onlyOwner{
        require(_amount <= address(this).balance, "Fee amount is greater than the balance");
        IERC20(token).approve(address(this), _amount);
        IERC20(token).safeTransferFrom(address(this), _to, _amount);
    }

    function getBalance() public view returns(uint256){
        return address(this).balance;
    }

    fallback() external payable {}
    receive() external payable {
    emit MoneyReceived(msg.sender, msg.value);}


}