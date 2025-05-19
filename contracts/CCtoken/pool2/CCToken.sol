// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";
import "https://github.com/Uniswap/v3-periphery/blob/main/contracts/interfaces/INonfungiblePositionManager.sol";
import "https://github.com/Uniswap/v3-core/blob/main/contracts/interfaces/IUniswapV3Pool.sol";

contract CSYDToken is ERC20, Ownable {
    uint256 public constant TOTAL_SUPPLY = 150_000_000 * 10**18; // 1.5亿枚
    uint256 public constant TEAM_LOCK_PERIOD = 3 * 365 days; // 团队锁仓3年

    address[] private teamAddresses;
    uint256 public teamLockedUntil;
    address public uniswapPool;

    constructor(address[] memory _teamAddresses, address _uniswapPool)
        ERC20("csyd", "CSYD")
        Ownable(msg.sender)
    {
        require(_teamAddresses.length > 0, "At least one team address required");
        teamAddresses = _teamAddresses;
        uniswapPool = _uniswapPool;

        _mint(msg.sender, TOTAL_SUPPLY * 80 / 100); // 80%流通
        for (uint256 i = 0; i < teamAddresses.length; i++) {
            _mint(teamAddresses[i], TOTAL_SUPPLY * 10 / 100 / teamAddresses.length); // 10%团队
        }
        _mint(address(this), TOTAL_SUPPLY * 10 / 100); // 10%资金池

        teamLockedUntil = block.timestamp + TEAM_LOCK_PERIOD; // 锁仓设置
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        return super.transfer(recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        return super.transferFrom(sender, recipient, amount);
    }

    function getCurrentPrice() public view returns (uint256 price) {
        IUniswapV3Pool pool = IUniswapV3Pool(uniswapPool);
        (uint160 sqrtPriceX96, , , , , , ) = pool.slot0();
        price = uint256(sqrtPriceX96) * uint256(sqrtPriceX96) / (2**192); // 计算价格
    }
}