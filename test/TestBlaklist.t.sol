// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "forge-std/Test.sol";
import "../src/Blacklist.sol";

contract BlacklistTest is Test {
    Blacklist public blacklist;

    // Адреса для тестирования:
    address admin = address(0x1); // Деплойер и администратор (с ADMIN_ROLE)
    address nonAdmin = address(0x2); // Неадминистратор
    address user = address(0x3); // Тестируемый адрес для blacklist

    // Период, через который можно удалять адреса из чёрного списка
    uint256 public timeToRelease = 3 days; // releaseDate = deploymentDate + 3 days

    // Имитация событий (подобные тем, что выбрасываются контрактом)
    event AddedToBlacklist(address account);
    event RemovedFromBlacklist(address account);

    // Перед каждым тестом разворачиваем контракт с администратором admin
    function setUp() public {
        // Для установки msg.sender равным admin используем vm.prank
        vm.prank(admin);
        blacklist = new Blacklist(timeToRelease);
    }

    /// @notice Тест успешного добавления адреса в чёрный список
    function testAddToBlacklistSuccess() public {
        uint256 vtsBalance = 1000;

        // Ожидаем выброс события AddedToBlacklist с адресом user
        vm.expectEmit(true, false, false, true);
        emit AddedToBlacklist(user);

        vm.prank(admin);
        blacklist.addToBlacklist(user, vtsBalance);

        // Проверяем, что данные в маппинге обновлены корректно
        (uint256 storedBalance, bool blocked) = blacklist.blacklisted(user);
        assertEq(storedBalance, vtsBalance, unicode"Неверный vtsBalance");
        assertTrue(blocked, unicode"Адрес должен быть заблокирован");
    }

    /// @notice Тест: добавление нулевого адреса должно revert с ошибкой InvalidZeroAddress
    function testAddToBlacklistZeroAddress() public {
        vm.prank(admin);
        vm.expectRevert(abi.encodeWithSelector(Blacklist.InvalidZeroAddress.selector));
        blacklist.addToBlacklist(address(0), 500);
    }

    /// @notice Тест: повторное добавление одного и того же адреса должно revert с ошибкой AccountAlreadyBlacklisted
    function testAddToBlacklistAlreadyBlacklisted() public {
        vm.prank(admin);
        blacklist.addToBlacklist(user, 1000);

        vm.prank(admin);
        vm.expectRevert(abi.encodeWithSelector(Blacklist.AccountAlreadyBlacklisted.selector));
        blacklist.addToBlacklist(user, 2000);
    }

    /// @notice Тест: попытка добавить адрес после истечения периода (более 2 дней с момента деплоя) должна revert
    function testAddToBlacklistAfterDeadline() public {
        // Перемещаем время за пределы периода: deploymentDate + 2 days + 1 секунда
        uint256 warpTime = blacklist.deploymentDate() + 2 days + 1;
        vm.warp(warpTime);

        vm.prank(admin);
        vm.expectRevert(); // require без кастомного revert-сообщения
        blacklist.addToBlacklist(user, 1000);
    }

    /// @notice Тест: попытка удаления адреса до наступления releaseDate должна revert
    function testRemoveFromBlacklistBeforeReleaseDate() public {
        // Сначала добавляем адрес в чёрный список
        vm.prank(admin);
        blacklist.addToBlacklist(user, 1000);

        // Попытка удалить до releaseDate – revert, так как require(releaseDate <= block.timestamp)
        vm.prank(admin);
        vm.expectRevert();
        blacklist.removeFromBlacklist(user);
    }

    /// @notice Тест: попытка удалить не заблокированный адрес должна revert с ошибкой AccountNotBlacklisted
    function testRemoveFromBlacklistNotBlacklisted() public {
        // Перемещаем время за пределы releaseDate, чтобы условие времени прошло
        uint256 warpTime = blacklist.releaseDate() + 1;
        vm.warp(warpTime);

        vm.prank(admin);
        vm.expectRevert(abi.encodeWithSelector(Blacklist.AccountNotBlacklisted.selector));
        blacklist.removeFromBlacklist(user);
    }

    /// @notice Тест успешного удаления адреса из чёрного списка после наступления releaseDate
    function testRemoveFromBlacklistSuccess() public {
        vm.prank(admin);
        blacklist.addToBlacklist(user, 1000);

        // Перемещаем время за пределы releaseDate
        uint256 warpTime = blacklist.releaseDate() + 1;
        vm.warp(warpTime);

        // Ожидаем выброс события RemovedFromBlacklist с адресом user
        vm.expectEmit(true, false, false, true);
        emit RemovedFromBlacklist(user);

        vm.prank(admin);
        blacklist.removeFromBlacklist(user);

        // Проверяем, что адрес больше не заблокирован
        (, bool blocked) = blacklist.blacklisted(user);
        assertFalse(blocked, unicode"Адрес должен быть удалён из blacklist");
    }

    /// @notice Тест функции isBlacklisted
    function testIsBlacklisted() public {
        bool status = blacklist.isBlacklisted(user);
        assertFalse(status, unicode"Адрес не должен быть в blacklist");
        vm.prank(admin);
        blacklist.addToBlacklist(user, 1000);
        status = blacklist.isBlacklisted(user);
        assertTrue(status, unicode"Адрес должен быть в blacklist");

        // Перемещаем время за пределы releaseDate и удаляем адрес
        uint256 warpTime = blacklist.releaseDate() + 1;
        vm.warp(warpTime);
        vm.prank(admin);
        blacklist.removeFromBlacklist(user);
        status = blacklist.isBlacklisted(user);
        assertFalse(status, unicode"Адрес должен быть удалён из blacklist");
    }

    /// @notice Тест: вызовы функций доступны только для адресов с ADMIN_ROLE
    function testNonAdminAccess() public {
        // Попытка вызвать addToBlacklist не администратором должна revert
        vm.prank(nonAdmin);
        vm.expectRevert();
        blacklist.addToBlacklist(user, 1000);
        vm.prank(admin);
        blacklist.addToBlacklist(user, 1000);
        uint256 warpTime = blacklist.releaseDate() + 1;
        vm.warp(warpTime);
        vm.prank(nonAdmin);
        vm.expectRevert();
        blacklist.removeFromBlacklist(user);
    }
}
