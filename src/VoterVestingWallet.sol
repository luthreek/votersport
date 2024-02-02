// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract VoterVestingWallet is Ownable{

    event MoneyReceived(address indexed _from, uint256 _amount);

    address token;
    address stakeContract;
    uint256 timeToRelease;
    uint256 balance;

    constructor(address owner, address _token, address _stakeContract, uint256 vestingTime) Ownable(owner) {
        token = _token;
        stakeContract = _stakeContract;
        release = Release.CLOSED;
        timeToRelease = block.timestamp + vestingTime;
        balance = address(this).balance;
    }

    struct Beneficiarie {
        address wallet;
        uint256 share;
    }

    enum Release {
        OPEN,
        CLOSED
    }

    Release public release;

    mapping (uint256 => Beneficiarie) public idToBene;

    modifier onlyBeneficiaries(uint256 beneID) {
    require(msg.sender == idToBene[beneID].wallet, "You cannot transfer tokens!");
    _;
  }

    function addBeneficiaries(uint256 beneID, address _bene, uint256 share) public onlyOwner {
        require(share <= balance, "Share could not be greater than balance");
        idToBene[beneID] = Beneficiarie({wallet: _bene, share: share});
        balance -= share;
    }

    function stake(uint256 beneID, uint256 amount) public onlyBeneficiaries(beneID) {
        require(amount <= idToBene[beneID].share, "Amount exceeds your share!");
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, stakeContract, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ST');
        idToBene[beneID].share -= amount;
    }

    //еще нужно добавить возможность проверки на соответствие msg.sender к NFT от стейка
    function withdrawStake(uint256 beneID, uint256 tokenId, uint256 amount) public onlyBeneficiaries(beneID) {

    }


    function withdraw(uint256 beneID, address to, uint256 amount) public onlyBeneficiaries(beneID) {
        require(amount <= idToBene[beneID].share, "Amount exceeds your share!");
        checkRelease(beneID);
        require(release == Release.OPEN, "Release is closed!");
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ST');
        idToBene[beneID].share -= amount;
    }

    function checkRelease(uint256 beneID) public onlyBeneficiaries(beneID) returns(bool) {
        require(release == Release.CLOSED, "Release is open");
        if (block.timestamp >= timeToRelease) {
            release = Release.OPEN;
            return true;
        }
    }

    fallback() external payable {}
    receive() external payable {
    emit MoneyReceived(msg.sender, msg.value);
  }

}