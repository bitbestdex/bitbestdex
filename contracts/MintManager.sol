// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract MintManager is Ownable {
    // 累计铸造
    uint256 private freezeAmount;

    // 发放上限
    uint256 private unfreezeAmount;

    // 已发 累计
    uint256 private total;

    address STC_TOKEN;

    //0x511c46d42d5993906d6d532349a724aa637e5e5d
    //TFvShw7iNYdr8FasYEJp5FqJbVw5G4J2Js
    bytes4 private constant SELECTOR =
        bytes4(keccak256(bytes("transfer(address,uint256)")));

    event SpentERC20(address erc20contract, address to, uint256 transfer);

    constructor(address owner, address src) {
        STC_TOKEN = src;
        _transferOwnership(owner);
    }

    function setUnfreezeAmount(uint256 _unfreezeAmount) external onlyOwner {
        unfreezeAmount = _unfreezeAmount;
    }

    function getUnfreezeAmount() external view onlyOwner returns (uint256) {
        return unfreezeAmount;
    }

    function addFreezeAmount(uint256 _freezeAmount) external onlyOwner {
        freezeAmount = freezeAmount + _freezeAmount;
    }

    function getTotal() external view onlyOwner returns (uint256) {
        return total;
    }

    function getFreezeAmount() external view onlyOwner returns (uint256) {
        return freezeAmount;
    }

    function spendERC20(address destination, uint256 value) external onlyOwner {
        require(destination != address(this), "Not allow sending to yourself");
        // transfer erc20 token
        require(unfreezeAmount >= value, "Insufficient Balance");
        unfreezeAmount = unfreezeAmount - value;
        total = total + value;
        require(total < freezeAmount, "Insufficient Balance");
        // transfer tokens from this contract to the destination address
        _safeTransfer(STC_TOKEN, destination, value);
        emit SpentERC20(STC_TOKEN, destination, value);
    }

    function _safeTransfer(address token, address to, uint256 value) private {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(SELECTOR, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "MintManager: TRANSFER_FAILED"
        );
    }
}
