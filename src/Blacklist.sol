// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract Blacklist is AccessControl {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    constructor(uint256 timeToRelease) {
        _grantRole(ADMIN_ROLE, msg.sender);
        deploymentDate = block.timestamp;
        releaseDate = timeToRelease + block.timestamp;
    }

    uint256 public releaseDate;
    uint256 public deploymentDate;

    struct BL {
        uint256 vtsBalance;
        bool blocked;
        uint256 timeToRelease;
    }

    mapping(address => BL) public blacklisted;

    event AddedToBlacklist(address account);
    event RemovedFromBlacklist(address account);

    error InvalidZeroAddress();
    error AccountAlreadyBlacklisted();
    error AccountNotBlacklisted();

    function addToBlacklist(address account, uint256 vtsBalance) public virtual onlyRole(ADMIN_ROLE) {
        require(block.timestamp <= deploymentDate + 2 days);
        if (account == address(0)) revert InvalidZeroAddress();
        if (blacklisted[account].blocked) revert AccountAlreadyBlacklisted();
        _addToBlacklist(account, vtsBalance);
    }

    function removeFromBlacklist(address account) public onlyRole(ADMIN_ROLE) {
        require(releaseDate <= block.timestamp);
        if (!blacklisted[account].blocked) revert AccountNotBlacklisted();
        _removeFromBlacklist(account);
    }

    function isBlacklisted(address account) public view returns (bool) {
        return _isBlacklisted(account);
    }

    function _addToBlacklist(address account, uint256 vtsBalance) internal {
        blacklisted[account] = BL({vtsBalance: vtsBalance, blocked: true, timeToRelease: releaseDate});
        emit AddedToBlacklist(account);
    }

    function increaseLock(address account, uint256 addTime) public onlyRole(ADMIN_ROLE) {
        blacklisted[account].timeToRelease = blacklisted[account].timeToRelease + addTime;
    }

    function _removeFromBlacklist(address account) internal {
        blacklisted[account].blocked = false;
        emit RemovedFromBlacklist(account);
    }

    function _isBlacklisted(address account) internal view returns (bool) {
        return blacklisted[account].blocked;
    }
}
