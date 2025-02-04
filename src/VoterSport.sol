// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
// Подключение библиотек OpenZeppelin

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Blacklist} from "./Blacklist.sol";

// Определение контракта ERC-20 токена с использованием OpenZeppelin
contract VoterSport is ERC20, Ownable, Blacklist{

    // Конструктор контракта, задаем имя и символ токена, а также количество токенов
    constructor(address owner) ERC20("VoterSport", "VTS") Ownable(owner) Blacklist(30 minutes) {
        // Выпуск общего количества токенов, например, 1 миллиард (1e9)
        _mint(msg.sender, 1e9 * 10 ** uint256(decimals()));
    }

    address contact;

    // Функция для передачи токенов
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        require(recipient != contact && blacklisted[msg.sender].vtsBalance < ERC20(address(this)).balanceOf(msg.sender) - amount);
        // Вызываем функцию transfer из родительского контракта ERC20
        return super.transfer(recipient, amount);
    }

    // Функция для передачи токенов с разрешения (для других адресов)
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        // Вызываем функцию transferFrom из родительского контракта ERC20
        return super.transferFrom(sender, recipient, amount);
    }

    // Функция для разрешения другому адресу использовать определенное количество токенов
    function approve(address spender, uint256 amount) public override returns (bool) {
        // Вызываем функцию approve из родительского контракта ERC20
        return super.approve(spender, amount);
    }

    function setVoteContract(address voteContract) public override onlyOwner{
        contact = voteContract;
        return super.setVoteContract(voteContract);
    }

    function approveVote(address owner, uint256 amount) public override returns (bool) {
        // Вызываем функцию approve из родительского контракта ERC20
        return super.approveVote(owner, amount);
    }

    function increaseAllowance(address owner, address spender, uint256 addedValue) public override returns (bool){
        return super.increaseAllowance(owner, spender, addedValue);
    }

    // Функция для изъятия разрешения на использование токенов
    function revokeApproval(address spender) public {
        // Устанавливаем разрешение в 0
        _approve(_msgSender(), spender, 0);
    }

    // Функция для выпуска дополнительных токенов (только владелец контракта может вызывать)
    function mint(address account, uint256 amount) public onlyOwner {
        // Вызываем функцию mint из родительского контракта ERC20
        _mint(account, amount);
    }

    // Функция для уничтожения токенов (только владелец контракта может вызывать)
    function burn(uint256 amount) public onlyOwner {
        // Вызываем функцию burn из родительского контракта ERC20
        _burn(msg.sender, amount);
    }

    function addToBlacklist(address account, uint256 vtsBalance) public override onlyOwner {
        return super.addToBlacklist(account, vtsBalance);
    }

    //  function _update(address from, address to, uint256 value) internal override {
    //     require(to != contact && blacklisted[from].vtsBalance < ERC20(address(this)).balanceOf(from) - value);
    //     super._update(from, to, value);
    // }
}
