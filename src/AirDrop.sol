pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract AirDrop is Pausable, AccessControl, ReentrancyGuard {
    using SafeERC20 for IERC20;

    event SingleDrop(address indexed to, uint256 amount);
    event MassDrop(address[] to, uint256[] amounts);

    error AlreadyDropped();
    error NotOperator();
    error NotOwner();

    constructor(address _token, address operator, address owner) {
        _grantRole(DEFAULT_ADMIN_ROLE, owner);
        _grantRole(OPERATOR_ROLE, operator);
        token = IERC20(_token);
    }

    IERC20 public immutable token;

    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    struct dropCalldata {
        address playerAddress;
        uint256 amount;
    }

    mapping(address => uint256) public droplist;

    function singleDrop(address _player, uint256 _amount) external whenNotPaused nonReentrant {
        _validateIsOperator();
        if (droplist[_player] != 0) {
            revert AlreadyDropped();
        }
        droplist[_player] = _amount;
        token.safeTransfer(_player, _amount);
        emit SingleDrop(_player, _amount);
    }

    function massDrop(dropCalldata[] calldata _dropCalldata) external whenNotPaused nonReentrant {
        _validateIsOperator();
        uint256 length = _dropCalldata.length;
        address[] memory recipients = new address[](length);
        uint256[] memory amounts = new uint256[](length);
        for (uint256 i = 0; i < length;) {
            address player = _dropCalldata[i].playerAddress;
            uint256 amount = _dropCalldata[i].amount;
            if (droplist[player] == 0) {
                droplist[player] = amount;
                token.safeTransfer(player, amount);
            }
            unchecked {
                i++;
            }
        }
        emit MassDrop(recipients, amounts);
    }

    function pause() public {
        _validateIsOwner();
        _pause();
    }

    function unpause() public {
        _validateIsOwner();
        _unpause();
    }

    function _validateIsOperator() private view {
        if (!hasRole(OPERATOR_ROLE, msg.sender)) revert NotOperator();
    }

    function _validateIsOwner() private view {
        if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) revert NotOwner();
    }
}
