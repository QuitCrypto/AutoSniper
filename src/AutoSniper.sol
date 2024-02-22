// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {SniperState} from "./helpers/SniperStructs.sol";
import {IERC721} from "forge-std/interfaces/IERC721.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {IERC1155} from "forge-std/interfaces/IERC1155.sol";
import {Ownable} from "solady/auth/Ownable.sol";

/**
 * @title AutoSniper 4.0 for @oSnipeNFT
 * @author 0xQuit
 */
/*

        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%*+=--::::::--=+*#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*=:.       ......        :=*%@@@@@@@@@%@@@@@@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#=.    .-+*%@@@@@@@@@@@@%#+=:    -@@@@@@=:::=#@@@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@@@@@@@@%+.   :=#@@@@@@@@@@@@@@@@@@@@@@@@#+#@@@@@%**+-:::-%@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@@@@@@#-   :+%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%******+-::=@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@@@@%:   =%@@@@@@@@@@@@@@@@%%%%@@@@@@@@@@@@@@%*++++++***+=+@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@@@=   -@@@@@@@@@@@@#+-:.         :-+%@@@@@%*+++++++++*#@@@@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@#.  :%@@@@@@@@@%+:      ..:::::.  .*@@@%*+++++++++++#@@@@@@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@*   =@@@@@@@@@#:    .=*%@@@@@@@@@@%@@@%+----======+#@@@@@%@@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@+   *@@@@@@@@#:   .+%@@@@@@@@@@@@@@@@@@=-------==+#@@@@@%- -@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@#   #@@@@@@@@=   .*@@@@@@@@@#=.    .-+#+=--------*@@@@@@@%   +@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@.  =@@@@@@@@-   =@@@@@@@@@@:  -+**+-   .--=----+%@@@@@@@@@#   %@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@+  .@@@@@@@@-   +@@@@@@@@@@-  #@@@@%+-:.  :=*@#%@@@*%@@@@@@@=  -@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@.  #@@@@@@@+   =@@@@@@@@@@@:  @@@%=-----.  #@@@@@*. -@@@@@@@@   %@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@#   @@@@@@@@.  .@@@@@@@@@@@@%  :#=:::::--*+=@@@@@@-   %@@@@@@@-  +@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@+  :@@@@@@@%   =@@@@@@@@@@@@@%-:--::::-*@@@@@@@@@@*   *@@@@@@@+  :@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@=  -@@@@@@@#   +@@@@@@@@@@@@@#-:---:-*@@@@@@@@@@@@#   +@@@@@@@+  :@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@+  -@@@@@@@%   =@@@@@@*#@@@#-::---=. -@@@@@@@@@@@@*   +@@@@@@@+  :@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@#  .@@@@@@@@   .@@@@@+  #*-:::--*@@#  -@@@@@@@@@@@-   %@@@@@@@-  =@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@   #@@@@@@@+  =@@@@@%  .--:--+@@@@@=  %@@@@@@@@@#   :@@@@@@@@   %@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@=  :@@@@@@@@=%@@@@@@*:   :-*@@@@@@%. .@@@@@@@@@%    %@@@@@@@=  :@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@   +@@@@@@@@@@@@#+---:.  .=*###*-  :%@@@@@@@@#   .%@@@@@@@#   #@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@*   %@@@@@@@@@#=------*%+-      .-#@@@@@@@@%=   .%@@@@@@@@.  =@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@= .*@@@@@@@@+------=%@@@@@@%%%@@@@@@@@@@#-    +@@@@@@@@@:  :@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@#@@@@@@@@*===---=#@@@@@@@@@@@@@@@@@%*-     +@@@@@@@@@#   -@@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@@@@@@@*=====+#%@@@@@%= .:--==--:.     .-*@@@@@@@@@@+   +@@@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@@@@@@+--==+#@@@@@@@@=:.           :=*%@@@@@@@@@@@*.  .#@@@@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@@@@*===+-*@@@@@@@@@@@@@@%%#####%@@@@@@@@@@@@@@@*.   +@@@@@@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@@@#+==#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#=   .+@@@@@@@@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@+==+%@@@@@@@@@%*%@@@@@@@@@@@@@@@@@@@@@@@@@*-    -*@@@@@@@@@@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@#=%@@@@@@@@@+    -=*%@@@@@@@@@@@@@@%*+-.    :+@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%+-.      ..:::::::.      .-+#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%*+=-:........:-=+*#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

*/

contract AutoSniper is Ownable {
    error InsufficientBalance();
    error FailedToWithdraw();
    error FailedToPayAutosniper();
    error FailedToPayValidator();
    error OrderFailed();
    error CallerNotFulfiller();
    error MigrationNotEnabled();
    error ArrayLengthMismatch();
    error SniperIsPaused();
    error FulfillerCannotHaveBalance();

    event Deposit(address sniper, uint256 amount);
    event Withdrawal(address sniper, uint256 amount);

    address private fulfillerAddress = 0x7D79Bd0E4B3dC90665A3ed30Aa6C6c06c89D224E;
    address public nextContractVersionAddress;
    bool public migrationEnabled;
    mapping(address => SniperState) public sniperStates;

    constructor() {
        _initializeOwner(tx.origin);
    }

    // only the fulfiller can call this function
    modifier onlyFulfiller() {
        if (msg.sender != fulfillerAddress) revert CallerNotFulfiller();
        _;
    }

    // allow the contract to receive Ether
    receive() external payable {}

    /**
     * @dev Generalized function for fulfilling orders
     * @param contractAddresses a list of contract addresses that will be called
     * @param calls a matching array to contractAddresses, each index being a call to make to a given contract
     * @param values a matching array to contractAddresses, each index being the value to send with the call
     * @param sniper the address of the sniper
     * @param validatorTip the amount to send to block.coinbase. Reverts if this is 0.
     * @param fulfillerTip the amount to send to fulfillerAddress. Reverts if this is 0.
     */
    function solSnatch(
        address[] calldata contractAddresses,
        bytes[] calldata calls,
        uint256[] calldata values,
        address sniper,
        uint256 validatorTip,
        uint256 fulfillerTip
    ) external onlyFulfiller {
        if (contractAddresses.length != calls.length) revert ArrayLengthMismatch();
        if (calls.length != values.length) revert ArrayLengthMismatch();
        if (sniperStates[sniper].isPaused) revert SniperIsPaused();

        uint256 balanceBefore = address(this).balance;

        for (uint256 i = 0; i < contractAddresses.length; ++i) {
            (bool success,) = contractAddresses[i].call{value: values[i]}(calls[i]);
            if (!success) revert OrderFailed();
        }

        (bool validatorPaid,) = block.coinbase.call{value: validatorTip}("");
        if (!validatorPaid) revert FailedToPayValidator();
        (bool fulfillerPaid,) = fulfillerAddress.call{value: fulfillerTip}("");
        if (!fulfillerPaid) revert FailedToPayAutosniper();

        uint256 balanceAfter = address(this).balance;

        if (balanceAfter < balanceBefore) {
            uint128 spent = uint128(balanceBefore - balanceAfter);
            if (sniperStates[sniper].ethBalance < spent) revert InsufficientBalance();
            unchecked {
                sniperStates[sniper].ethBalance -= spent;
            }
            emit Withdrawal(sniper, spent);
        } else if (balanceAfter > balanceBefore) {
            unchecked {
                sniperStates[sniper].ethBalance += uint128(balanceAfter - balanceBefore);
            }
            emit Deposit(sniper, balanceAfter - balanceBefore);
        }
    }

    /**
     * @dev deposit Ether into the contract.
     * @param sniper is the address who's balance is affected.
     */
    function deposit(address sniper) public payable {
        if (tx.origin == fulfillerAddress) revert FulfillerCannotHaveBalance();
        unchecked {
            sniperStates[sniper].ethBalance += uint128(msg.value);
        }

        emit Deposit(sniper, msg.value);
    }

    /**
     * @dev deposit Ether into your own contract balance.
     */
    function depositSelf() external payable {
        deposit(msg.sender);
    }

    /**
     * @dev withdraw Ether from your contract balance
     * @param amount the amount of Ether to be withdrawn
     */
    function withdraw(uint256 amount) external {
        if (tx.origin == fulfillerAddress) revert FulfillerCannotHaveBalance();

        if (sniperStates[msg.sender].ethBalance < amount) revert InsufficientBalance();
        unchecked {
            sniperStates[msg.sender].ethBalance -= uint128(amount);
        }

        (bool success,) = payable(msg.sender).call{value: amount}("");
        if (!success) revert FailedToWithdraw();

        emit Withdrawal(msg.sender, amount);
    }

    function setUserIsPaused(bool isPaused) external {
        sniperStates[msg.sender].isPaused = isPaused;
    }

    /**
     * @dev Owner function to change fulfiller address if needed.
     */
    function setFulfillerAddress(address _fulfiller) external onlyOwner {
        fulfillerAddress = _fulfiller;
    }

    /**
     * Enables migration and sets a destination address (the new contract)
     * @param _destination the new AutoSniper version to allow migration to.
     */
    function setMigrationAddress(address _destination) external onlyOwner {
        migrationEnabled = true;
        nextContractVersionAddress = _destination;
    }

    /**
     * @dev in the event of a future contract upgrade, this function allows snipers to
     * easily move their ether balance to the new contract. This can only be called by
     * the sniper to move their personal balance - the contract owner or anybody else
     * does not have the power to migrate balances for users.
     */
    function migrateBalance() external {
        if (!migrationEnabled) revert MigrationNotEnabled();
        uint256 balanceToMigrate = sniperStates[msg.sender].ethBalance;
        sniperStates[msg.sender].ethBalance = 0;

        (bool success,) = nextContractVersionAddress.call{value: balanceToMigrate}(
            abi.encodeWithSelector(this.deposit.selector, msg.sender)
        );
        if (!success) revert FailedToWithdraw();
    }

    function sniperBalance(address sniper) external view returns (uint128) {
        return sniperStates[sniper].ethBalance;
    }

    function onERC1155Received(address, address, uint256, uint256, bytes calldata) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] calldata, uint256[] calldata, bytes calldata)
        public
        virtual
        returns (bytes4)
    {
        return this.onERC1155BatchReceived.selector;
    }

    function onERC721Received(address, address, uint256, bytes calldata) external virtual returns (bytes4) {
        return 0x150b7a02;
    }

    // Used by ERC721BasicToken.sol
    function onERC721Received(address, uint256, bytes calldata) external virtual returns (bytes4) {
        return 0xf0b9e5ba;
    }

    function supportsInterface(bytes4 interfaceId) external view virtual returns (bool) {
        return interfaceId == this.supportsInterface.selector;
    }

    // Emergency function: In case any ERC20 tokens get stuck in the contract unintentionally
    // Only owner can retrieve the asset balance to a recipient address
    function rescueERC20(address asset, address recipient) external onlyOwner {
        IERC20 token = IERC20(asset);
        token.transfer(recipient, token.balanceOf(address(this)));
    }

    // Emergency function: In case any ERC721 tokens get stuck in the contract unintentionally
    // Only owner can retrieve the asset balance to a recipient address
    function rescueERC721(address asset, uint256[] calldata ids, address recipient) external onlyOwner {
        for (uint256 i = 0; i < ids.length; i++) {
            IERC721(asset).transferFrom(address(this), recipient, ids[i]);
        }
    }

    // Emergency function: In case any ERC1155 tokens get stuck in the contract unintentionally
    // Only owner can retrieve the asset balance to a recipient address
    function rescueERC1155(address asset, uint256[] calldata ids, uint256[] calldata amounts, address recipient)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < ids.length; i++) {
            IERC1155(asset).safeTransferFrom(address(this), recipient, ids[i], amounts[i], "");
        }
    }
}
