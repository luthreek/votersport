// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract StakingContract is Ownable, ERC721Holder {
    using SafeERC20 for IERC20;
    using ECDSA for bytes32;

    struct Stake {
        uint256 amount;
        uint256 rewards;
        uint256 timestamp;
    }

    struct Loan {
        uint256 amount;
        uint256 leverage;
        uint256 startTimestamp;
    }

    struct InterestRate {
        uint256 rate5x;
        uint256 rate10x;
        uint256 rate20x;
    }

    mapping(address => mapping(address => Stake)) public stakes;
    mapping(address => uint256) public totalStaked;
    mapping(address => uint256) public totalRewards;
    mapping(address => InterestRate) public interestRates;

    mapping(address => mapping(address => Loan)) public loans;

    event StakeDeposited(
        address staker,
        address token,
        uint256 amount,
        uint256 tokenId
    );
    event StakeWithdrawn(
        address staker,
        address token,
        uint256 stakedAmount,
        uint256 rewardAmount
    );
    event LoanTaken(
        address borrower,
        address token,
        uint256 amount,
        uint256 leverage
    );
    event LoanRepaid(address borrower, address token, uint256 amount);
    event LoanLiquidated(
        address borrower,
        address token,
        uint256 amount,
        uint256 rewardAmount
    );
    event OutcomeProcessed(
        address borrower,
        address token,
        string outcome,
        uint256 winningAmount
    );

    uint256 public constant MULTI_SIGNATURE_THRESHOLD = 3;

    Counters.Counter private _nonce;
    mapping(uint256 => uint256) private _confirmations;

    modifier multiSignature(
        uint256 _operationHash,
        uint8[] memory _v,
        bytes32[] memory _r,
        bytes32[] memory _s
    ) {
        require(
            _v.length == MULTI_SIGNATURE_THRESHOLD,
            "Invalid number of signatures"
        );
        require(
            _v.length == _r.length && _v.length == _s.length,
            "Invalid input lengths"
        );

        address lastSigner = address(0);
        for (uint256 i = 0; i < _v.length; i++) {
            address signer = recoverSigner(_operationHash, _v[i], _r[i], _s[i]);
            require(
                signer > lastSigner && isOwner(signer),
                "Invalid signer or not owner"
            );
            _confirmations[_operationHash] |= (1 << i);
            lastSigner = signer;
        }
        require(
            popCount(_confirmations[_operationHash]) >=
                MULTI_SIGNATURE_THRESHOLD,
            "Insufficient signatures"
        );
        _;
    }

    constructor() {}

    function depositStake(address _token, uint256 _amount) external {
        require(_amount > 0, "Amount must be greater than zero");
        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);

        uint256 tokenId = totalStaked[_token] + 1; // Increment token ID
        IERC721(_token).safeTransferFrom(address(this), msg.sender, tokenId);

        Stake storage userStake = stakes[msg.sender][_token];
        userStake.amount += _amount;
        userStake.timestamp = block.timestamp;
        totalStaked[_token] += _amount;

        emit StakeDeposited(msg.sender, _token, _amount, tokenId);
    }

    function withdrawStake(address _token, uint256 _tokenId) external {
        Stake storage userStake = stakes[msg.sender][_token];
        require(userStake.amount > 0, "No staked amount");

        uint256 reward = userStake.rewards;

        userStake.amount = 0;
        totalStaked[_token] -= userStake.amount;

        totalRewards[_token] -= reward;
        userStake.rewards = 0;

        IERC721(_token).safeTransferFrom(msg.sender, address(this), _tokenId);
        IERC20(_token).safeTransfer(msg.sender, userStake.amount + reward);

        emit StakeWithdrawn(msg.sender, _token, userStake.amount, reward);
    }

    function claimReward(address _token) external {
        Stake storage userStake = stakes[msg.sender][_token];
        uint256 reward = userStake.rewards;
        require(reward > 0, "No rewards to claim");

        totalRewards[_token] -= reward;
        userStake.rewards = 0;

        IERC20(_token).safeTransfer(msg.sender, reward);
        emit StakeWithdrawn(msg.sender, _token, reward);
    }

    function takeLoan(
        address _token,
        uint256 _amount,
        uint256 _leverage
    ) external {
        require(
            _leverage == 5 || _leverage == 10 || _leverage == 20,
            "Invalid leverage"
        );
        require(_amount > 0, "Amount must be greater than zero");
        require(loans[msg.sender][_token].amount == 0, "Existing loan exists");

        uint256 firstDayInterest = calculateDayInterest(_amount, _leverage);
        uint256 totalCollateralAmount = _amount - firstDayInterest;
        uint256 loanAmount = totalCollateralAmount * _leverage;

        Loan storage loan = loans[msg.sender][_token];
        loan.amount = totalCollateralAmount;
        loan.leverage = _leverage;
        loan.startTimestamp = block.timestamp;

        require(
            IERC20(_token).transferFrom(
                msg.sender,
                address(this),
                totalCollateralAmount
            ),
            "Transfer failed"
        );
        require(
            IERC20(_token).transferFrom(msg.sender, address(this), loanAmount),
            "Transfer failed"
        );

        emit LoanTaken(msg.sender, _token, _amount, _leverage);
    }

    function repayLoan(address _token) external {
        Loan storage loan = loans[msg.sender][_token];
        require(loan.amount > 0, "No existing loan");

        uint256 elapsedTime = block.timestamp - loan.startTimestamp;
        uint256 totalInterest = (loan.amount * loan.leverage * elapsedTime) /
            1 days;
        uint256 totalToRepay = loan.amount + totalInterest;

        IERC20(_token).safeTransferFrom(
            msg.sender,
            address(this),
            totalToRepay
        );

        if (totalInterest > loan.amount) {
            // Liquidate loan
            totalRewards[_token] += totalToRepay - loan.amount;
            delete loans[msg.sender][_token];

            emit LoanLiquidated(
                msg.sender,
                _token,
                loan.amount,
                totalToRepay - loan.amount
            );
        } else {
            // Repay loan
            delete loans[msg.sender][_token];
            emit LoanRepaid(msg.sender, _token, loan.amount);
        }
    }

    function processOutcome(
        address _token,
        string memory _outcome,
        uint256 _winningAmount
    )
        external
        multiSignature(
            hashOperation(msg.sender, _token, _outcome, _winningAmount),
            _v,
            _r,
            _s
        )
    {
        require(_winningAmount > 0, "Winning amount must be greater than zero");
        Stake storage userStake = stakes[msg.sender][_token];
        require(userStake.amount > 0, "No stake exists");

        uint256 totalInterest = calculateTotalInterest(msg.sender, _token);
        uint256 totalAmountDue = userStake.amount + totalInterest;

        if (
            keccak256(abi.encodePacked(_outcome)) ==
            keccak256(abi.encodePacked("win"))
        ) {
            require(
                _winningAmount >= totalAmountDue,
                "Insufficient winning amount"
            );

            uint256 netWinningAmount = _winningAmount - totalAmountDue;
            uint256 rewardAmount = totalInterest;
            totalRewards[_token] += rewardAmount;

            delete stakes[msg.sender][_token];
            totalStaked[_token] -= userStake.amount;

            IERC20(_token).safeTransfer(msg.sender, netWinningAmount);

            emit StakeWithdrawn(
                msg.sender,
                _token,
                userStake.amount,
                rewardAmount
            );
        } else if (
            keccak256(abi.encodePacked(_outcome)) ==
            keccak256(abi.encodePacked("lose"))
        ) {
            delete stakes[msg.sender][_token];
            totalStaked[_token] -= userStake.amount;

            totalRewards[_token] += totalInterest;

            emit LoanLiquidated(
                msg.sender,
                _token,
                userStake.amount,
                totalInterest
            );
        } else if (
            keccak256(abi.encodePacked(_outcome)) ==
            keccak256(abi.encodePacked("draw"))
        ) {
            delete stakes[msg.sender][_token];
            totalStaked[_token] -= userStake.amount;

            totalRewards[_token] += totalInterest;

            uint256 remainingAmount = _winningAmount - totalInterest;
            IERC20(_token).safeTransfer(msg.sender, remainingAmount);

            emit LoanRepaid(msg.sender, _token, userStake.amount);
        } else {
            revert("Invalid outcome");
        }

        emit OutcomeProcessed(msg.sender, _token, _outcome, _winningAmount);
    }

    /*     function calculateTotalInterest(
        address _staker,
        address _token
    ) public view returns (uint256) {
        Stake memory userStake = stakes[_staker][_token];
        uint256 elapsedTime = block.timestamp - userStake.timestamp;
        return
            (userStake.amount *
                getInterestRate(_token, userStake.amount) *
                elapsedTime) / (1 days * 365);
    } */

    function getInterestRate(
        address _token,
        uint256 _amount
    ) internal view returns (uint256) {
        InterestRate memory rates = interestRates[_token];
        if (_amount > 0 && _amount <= 100) {
            return rates.rate5x;
        } else if (_amount <= 1000) {
            return rates.rate10x;
        } else {
            return rates.rate20x;
        }
    }

    function calculateDayInterest(
        uint256 _amount,
        uint256 _leverage,
        address _token
    ) internal view returns (uint256) {
        return _amount * getInterestRate(_token, _leverage);
    }

    function setInterestRates(
        address _token,
        uint256 _rate5x,
        uint256 _rate10x,
        uint256 _rate20x
    ) external onlyOwner {
        interestRates[_token] = InterestRate(_rate5x, _rate10x, _rate20x);
    }

    function hashOperation(
        address _to,
        address _token,
        string memory _outcome,
        uint256 _winningAmount
    ) public view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        address(this),
                        _to,
                        _token,
                        _outcome,
                        _winningAmount
                    )
                )
            );
    }

    function execute(
        address payable _to,
        address _token,
        string memory _outcome,
        uint256 _winningAmount,
        _nonce,
        uint8[] memory _v,
        bytes32[] memory _r,
        bytes32[] memory _s
    )
        external
        multiSignature(
            hashOperation(_to, _token, _outcome, _winningAmount),
            _v,
            _r,
            _s
        )
    {
        require(_nonce == _nonce.current(), "Invalid nonce");
        _nonce.increment();

        if (
            keccak256(abi.encodePacked(_outcome)) ==
            keccak256(abi.encodePacked("win"))
        ) {
            uint256 totalAmountDue = getTotalAmountDue(msg.sender, _token);
            require(
                _winningAmount >= totalAmountDue,
                "Insufficient winning amount"
            );

            uint256 netWinningAmount = _winningAmount - totalAmountDue;
            IERC20(_token).safeTransfer(_to, netWinningAmount);
        } else if (
            keccak256(abi.encodePacked(_outcome)) ==
            keccak256(abi.encodePacked("draw"))
        ) {
            uint256 totalAmountDue = getTotalAmountDue(msg.sender, _token);
            require(
                _winningAmount >= totalAmountDue,
                "Insufficient winning amount"
            );

            uint256 remainingAmount = _winningAmount - totalAmountDue;
            IERC20(_token).safeTransfer(_to, remainingAmount);
        } else {
            revert("Invalid outcome");
        }
    }

    function getTotalAmountDue(
        address _staker,
        address _token
    ) public view returns (uint256) {
        Stake memory userStake = stakes[_staker][_token];
        uint256 totalInterest = calculateTotalInterest(_staker, _token);
        return userStake.amount + totalInterest;
    }

    function recoverSigner(
        uint256 _hash,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) internal pure returns (address) {
        return ecrecover(toEthSignedMessageHash(_hash), _v, _r, _s);
    }

    function toEthSignedMessageHash(
        uint256 _hash
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash)
            );
    }

    function popCount(uint256 _x) internal pure returns (uint256 count) {
        for (count = 0; _x > 0; count++) {
            _x &= _x - 1;
        }
    }
}
