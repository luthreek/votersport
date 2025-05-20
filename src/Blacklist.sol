// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract Blacklist is AccessControl {

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, 0xe8ba149A60A7F400F3457F5F4A946F1C1013F13a);
        _setRoleAdmin(ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
        deploymentDate = block.timestamp;
    }

    uint256 public releaseDate;
    uint256 public deploymentDate;
    uint256 public blacklistEndDate;

    struct BL {
        bool blocked;
        uint256 dateOfRelease;
    }

    mapping(address => BL) public blacklisted;

    event AddedToBlacklist(address account);
    event RemovedFromBlacklist(address account);

    error InvalidZeroAddress();
    error AccountAlreadyBlacklisted();
    error AccountNotBlacklisted();

    function setTimeToRelease(uint256 _dateOfRelease) public onlyRole(ADMIN_ROLE){
        releaseDate = _dateOfRelease;
    }

    function setBlacklistDate(uint256 _blacklistEndDate) public onlyRole(ADMIN_ROLE){
        blacklistEndDate = _blacklistEndDate;
    }

    function addToBlacklist(address account) public onlyRole(ADMIN_ROLE){
        require(block.timestamp <= blacklistEndDate);
        if (account == address(0)) revert InvalidZeroAddress();
        if (blacklisted[account].blocked) revert AccountAlreadyBlacklisted();
        _addToBlacklist(account);
    }

    function removeFromBlacklist(address account) public {
        require(releaseDate <= block.timestamp);
        if (!blacklisted[account].blocked) revert AccountNotBlacklisted();
        _removeFromBlacklist(account);
    }

    function isBlacklisted(address account) public view returns (bool) {
        return _isBlacklisted(account);
    }

    function _addToBlacklist(address account) internal {
        blacklisted[account] = BL({blocked: true, dateOfRelease: releaseDate});
        emit AddedToBlacklist(account);
    }

    function increaseLock(address account, uint256 newDate) public onlyRole(ADMIN_ROLE){
        blacklisted[account].dateOfRelease = newDate;
    }

    function _removeFromBlacklist(address account) internal {
        blacklisted[account].blocked = false;
        emit RemovedFromBlacklist(account);
    }

    function _isBlacklisted(address account) internal view returns (bool) {
        return blacklisted[account].blocked;
    }
}
