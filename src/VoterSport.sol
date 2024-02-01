// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
// Подключение библиотек OpenZeppelin
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

// Определение контракта ERC-20 токена с использованием OpenZeppelin
contract VoterSport is ERC20, Ownable {
    // Конструктор контракта, задаем имя и символ токена, а также количество токенов
    constructor(address owner) ERC20("VoterSport", "VTS") Ownable(owner) {
        // Выпуск общего количества токенов, например, 1 миллиард (1e9)
        _mint(msg.sender, 1e9 * 10 ** uint(decimals()));
    } 

    // Функция для передачи токенов
    function transfer(
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        // Вызываем функцию transfer из родительского контракта ERC20
        return super.transfer(recipient, amount);
    }

    // Функция для передачи токенов с разрешения (для других адресов)
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        // Вызываем функцию transferFrom из родительского контракта ERC20
        return super.transferFrom(sender, recipient, amount);
    }

    // Функция для разрешения другому адресу использовать определенное количество токенов
    function approve(
        address spender,
        uint256 amount
    ) public override returns (bool) {
        // Вызываем функцию approve из родительского контракта ERC20
        return super.approve(spender, amount);
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
}
