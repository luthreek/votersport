// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// Определение контракта стейк-пула
contract StakePool is Ownable {
    VoterSport public token; // ERC-20 токен
    MyNFT public nft; // ERC-721 NFT

    uint256 public stakingReward = 100; // Количество токенов для награды за стейкинг
    uint256 public totalStaking;
    struct UserInfo {
        uint256 amount; // Количество стейкнутых токенов
        uint256 rewardDebt; // Долг награды (для корректного расчета награды)
        bool hasNFT; // Флаг для отслеживания, получил ли пользователь NFT
    }

    mapping(address => UserInfo) public userInfo; // Информация о пользователях
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event ClaimNFT(address indexed user, uint256 tokenId);

    constructor(MyToken _token, MyNFT _nft) {
        token = _token;
        nft = _nft;
    }

    // Функция для стейкинга токенов
    function deposit(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");

        // Передача токенов в контракт стейк-пула
        token.transferFrom(msg.sender, address(this), amount);

        // Обновление информации о пользователе
        UserInfo storage user = userInfo[msg.sender];
        user.amount += amount;
        user.rewardDebt += (user.amount * stakingReward) / 1e18; // Пример расчета награды

        // Выдача NFT, если пользователь еще не получил
        if (!user.hasNFT) {
            uint256 tokenId = uint256(
                keccak256(abi.encodePacked(msg.sender, block.number))
            );
            totalStaking += amount;
            nft.mint(msg.sender, tokenId);
            user.hasNFT = true;
            emit ClaimNFT(msg.sender, tokenId);
        }

        emit Deposit(msg.sender, amount);
    }

    // Функция для вывода стейкнутых токенов
    function withdraw(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");

        // Обновление информации о пользователе
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount >= amount, "Insufficient staked amount");

        // Расчет и перевод награды
        uint256 reward = ((user.amount * stakingReward) / 1e18) -
            user.rewardDebt;
        token.transfer(msg.sender, amount + reward);

        // Выдача NFT, если пользователь еще не получил
        if (!user.hasNFT) {
            uint256 tokenId = uint256(
                keccak256(abi.encodePacked(msg.sender, block.number))
            );
            totalStaking -= amount;
            nft.burn(msg.sender, tokenId);
            user.hasNFT = true;
            emit ClaimNFT(msg.sender, tokenId);
        }

        emit Withdraw(msg.sender, amount);
    }

    function claimReward() external {
        // Обновление информации о пользователе
        UserInfo storage user = userInfo[msg.sender];

        // Расчет и перевод награды
        uint256 reward = ((user.amount * stakingReward) / 1e18) -
            user.rewardDebt;
        token.transfer(msg.sender, reward);

        // Обновление долга награды
        user.rewardDebt = (user.amount * stakingReward) / 1e18;

        emit ClaimReward(msg.sender, reward);
    }

    function distributeRewards() external onlyOwner {}
}
