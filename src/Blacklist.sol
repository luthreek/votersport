// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;


contract Blacklist {

    constructor(uint256 timeToRelease) {
        deploymentDate = block.timestamp;
        releaseDate = timeToRelease + block.timestamp;
    }

    uint256 public releaseDate;
    uint256 public deploymentDate;

    struct BL {
        uint256 vtsBalance;
        bool blocked;
    }

    mapping(address => BL) public blacklisted;

    event AddedToBlacklist(address account);
    event RemovedFromBlacklist(address account);

    error ZeroAddressCannotBlacklisted();
    error AccountAlreadyBlacklisted();
    error AccountNotBlacklisted();

    function addToBlacklist(address account, uint256 vtsBalance) public virtual {
        require(block.timestamp <= deploymentDate + 2 days);
        if (account == address(0)) revert ZeroAddressCannotBlacklisted();
        if (blacklisted[account].blocked) revert AccountAlreadyBlacklisted();
        _addToBlacklist(account, vtsBalance);
    }

    function removeFromBlacklist(
        address account
    ) public {
        require(releaseDate <= block.timestamp);
        if (!blacklisted[account].blocked) revert AccountNotBlacklisted();
        _removeFromBlacklist(account);
    }

    function isBlacklisted(address account) public view returns (bool) {
        return _isBlacklisted(account);
    }

    function _addToBlacklist(address account, uint256 vtsBalance) internal {
        blacklisted[account] = BL({
            vtsBalance: vtsBalance,
            blocked: true
        });
        emit AddedToBlacklist(account);
    }

    function _removeFromBlacklist(address account) internal {
        blacklisted[account].blocked = false;
        emit RemovedFromBlacklist(account);
    }

    function _isBlacklisted(address account) internal view returns (bool) {
        return blacklisted[account].blocked;
    }
}
