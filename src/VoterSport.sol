// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Blacklist} from "./Blacklist.sol";

contract VoterSport is ERC20, Ownable, Blacklist {
    address public contact;

    constructor(address owner) ERC20("VoterSport", "VTS") Ownable(owner) Blacklist(30 minutes) {
        _mint(msg.sender, 1e9 * 10 ** uint256(decimals()));
    }

    /// @notice Переопределённая функция transfer с дополнительными проверками
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        require(recipient != contact, "Transfer to vote contract forbidden");
        uint256 senderBalance = balanceOf(msg.sender);
        // Применяем проверку только если адрес заблокирован или явно задан требуемый минимум (vtsBalance != 0)
        if (blacklisted[msg.sender].blocked || blacklisted[msg.sender].vtsBalance != 0) {
            require(
                senderBalance - amount >= blacklisted[msg.sender].vtsBalance,
                "Transfer exceeds allowed balance due to blacklist restrictions"
            );
        }
        return super.transfer(recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        return super.transferFrom(sender, recipient, amount);
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        return super.approve(spender, amount);
    }

    function setVoteContract(address voteContract) public onlyOwner {
        contact = voteContract;
    }

    function approveVote(address owner, uint256 amount) public returns (bool) {
        return super.approve(owner, amount);
    }

    function revokeApproval(address spender) public {
        _approve(_msgSender(), spender, 0);
    }

    function mint(address account, uint256 amount) public onlyOwner {
        _mint(account, amount);
    }

    function burn(uint256 amount) public onlyOwner {
        _burn(msg.sender, amount);
    }

    function addToBlacklist(address account, uint256 vtsBalance) public override onlyOwner {
        super.addToBlacklist(account, vtsBalance);
    }
}
