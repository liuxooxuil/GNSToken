// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";

contract CSYDToken is ERC20, Ownable {
    uint256 public constant TOTAL_SUPPLY = 150_000_000 * 10**18; // 1.5亿枚
    uint256 public constant TEAM_LOCK_PERIOD = 3 * 365 days; // 团队锁仓3年
    uint256 public initialPrice;

    address[] private teamAddresses;
    uint256 public teamLockedUntil;

    // constructor(address[] memory _teamAddresses)  数组形式部署 可多个团队
    constructor(address[] memory _teamAddresses)
        ERC20("csyd", "CSYD")
        Ownable(msg.sender) // 调用 Ownable 的构造函数
    {
        require(_teamAddresses.length > 0, "At least one team address required");
        teamAddresses = _teamAddresses;

        initialPrice = 13 * 10**16; // 0.13美元

        _mint(msg.sender, TOTAL_SUPPLY * 80 / 100); // 80%流通
        for (uint256 i = 0; i < teamAddresses.length; i++) {
            _mint(teamAddresses[i], TOTAL_SUPPLY * 10 / 100 / teamAddresses.length); // 10%团队
        }
        _mint(address(this), TOTAL_SUPPLY * 10 / 100); // 10%资金池

        teamLockedUntil = block.timestamp + TEAM_LOCK_PERIOD; // 锁仓设置
    }

    modifier teamLocked() {
        require(block.timestamp >= teamLockedUntil, "Team tokens are locked");
        _;
    }

    function transfer(address recipient, uint256 amount) public override teamLocked returns (bool) {
        return super.transfer(recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override teamLocked returns (bool) {
        return super.transferFrom(sender, recipient, amount);
    }

    function getInitialPrice() public view returns (uint256) {
        return initialPrice; // 返回初始价格
    }
}