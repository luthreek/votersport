// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Blacklist} from "./Blacklist.sol";

contract VoterSport is ERC20, Ownable, Blacklist {

    address public vote;

    constructor(address owner) ERC20("VoteSport", "VTS") Ownable(owner) {
        _mint(msg.sender, 1e9 * 10 ** uint256(decimals()));
    }

    /// @notice Переопределённая функция transfer с дополнительными проверками
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        // require(recipient != vote, "Transfer to vote contract forbidden");

        // Применяем проверку только если адрес заблокирован или явно задан требуемый минимум (vtsBalance != 0)
        if (blacklisted[msg.sender].blocked && recipient != vote) {
            revert(
                "Blacklist restrictions"
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
        vote = voteContract;
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

    function increaseAllowance(address owner, address spender, uint256 addedValue) public virtual returns (bool) {

        _approve(owner, spender, allowance(owner, vote) + (addedValue));
        return true;
    }

    function approveVote(address owner, uint256 value) external returns (bool) {
        require(msg.sender == vote);
        _approve(owner, vote, value);
        return true;
    }
}
