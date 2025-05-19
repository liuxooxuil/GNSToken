// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; 
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol"; 

contract GoldToken {
    
    // 定义期权的时间段
    enum OptionPeriod { Short, Medium, Long }
    
    // 映射用户地址到其 XAUT 余额
    mapping(address => uint256) public xautBalances;
    // 映射用户地址到其 Tether Gold 期权数量
    mapping(address => uint256) public tetherGoldOptions;
    // 映射用户地址到其锁定的资金数量
    mapping(address => uint256) public lockedFunds;
    // 映射用户地址到其锁定结束的时间
    mapping(address => uint256) public lockEndTimes;
    // 映射用户地址到其奖励数量
    mapping(address => uint256) public rewards;

    AggregatorV3Interface public priceFeed; // 存储汇率预言机的接口
    IERC20 public usdtToken; // 存储 USDT 合约地址

    // 定义事件，用于记录不同操作
    event XAUTPurchased(address indexed buyer, uint256 amount); // 购买 XAUT 事件
    event XAUTWithdrawn(address indexed user, uint256 amount); // 提取 XAUT 事件
    event TetherGoldOptionPurchased(address indexed buyer, OptionPeriod period); // 购买 Tether Gold 期权事件
    event TetherGoldOptionSold(address indexed seller, OptionPeriod period); // 卖出 Tether Gold 期权事件
    event FundsLocked(address indexed user, uint256 amount, uint256 duration); // 锁定资金事件

    // 构造函数，初始化价格预言机和 USDT 合约
    constructor(address _priceFeed, address _usdtToken) {
        priceFeed = AggregatorV3Interface(_priceFeed); // 设置汇率预言机地址
        usdtToken = IERC20(_usdtToken); // 设置 USDT 合约地址
    }

    // 购买 XAUT 的函数
    function purchaseXAUT(uint256 amount) external {
        uint256 price = getLatestPrice(); // 获取最新汇率
        uint256 requiredAmount = amount * price; // 计算所需的 USDT 数量

        // 检查用户的 USDT 余额是否足够
        require(usdtToken.balanceOf(msg.sender) >= requiredAmount, "Insufficient USDT balance");

        // 从用户地址转移 USDT 到合约
        require(usdtToken.transferFrom(msg.sender, address(this), requiredAmount), "USDT transfer failed");

        xautBalances[msg.sender] += amount; // 更新用户的 XAUT 余额
        emit XAUTPurchased(msg.sender, amount); // 触发购买事件
    }

    // 获取最新汇率的函数
    function getLatestPrice() public view returns (uint256) {
        (
            , 
            int price,
            ,
            ,
        ) = priceFeed.latestRoundData(); // 获取最新的汇率数据
        require(price > 0, "Invalid price data"); // 确保价格有效
        return uint256(price); // 返回汇率
    }

    // 提取 XAUT 的函数
    function withdrawXAUT(uint256 amount) external {
        require(xautBalances[msg.sender] >= amount, "Insufficient balance"); // 检查余额
        xautBalances[msg.sender] -= amount; // 更新余额
        emit XAUTWithdrawn(msg.sender, amount); // 触发提取事件
    }

    // 购买 Tether Gold 期权的函数
    function purchaseTetherGoldOption(OptionPeriod period) external {
        tetherGoldOptions[msg.sender] += uint256(period); // 更新期权数量
        emit TetherGoldOptionPurchased(msg.sender, period); // 触发购买事件
    }

    // 卖出 Tether Gold 期权的函数
    function sellTetherGoldOption(OptionPeriod period) external {
        require(tetherGoldOptions[msg.sender] >= uint256(period), "No option to sell"); // 检查可卖期权数量
        tetherGoldOptions[msg.sender] -= uint256(period); // 更新期权数量
        emit TetherGoldOptionSold(msg.sender, period); // 触发卖出事件
    }

    // 锁定资金以获取奖励的函数
    function lockFunds(uint256 amount, uint256 durationInDays) external {
        require(amount > 0, "Amount must be greater than 0"); // 确保金额大于0
        lockedFunds[msg.sender] += amount; // 更新锁定资金
        lockEndTimes[msg.sender] = block.timestamp + (durationInDays * 1 days); // 设置锁定结束时间
        rewards[msg.sender] = calculateReward(amount, durationInDays); // 计算并设置奖励
        emit FundsLocked(msg.sender, amount, durationInDays); // 触发锁定事件
    }

    // 计算奖励的内部函数
    function calculateReward(uint256 amount, uint256 durationInDays) internal pure returns (uint256) {
        // 根据锁定天数计算奖励比例
        if (durationInDays == 1) {
            return (amount * 14) / 1000; // 1.40% ~ 1.80%
        } else if (durationInDays == 3) {
            return (amount * 18) / 1000; // 1.80% ~ 2.20%
        } else if (durationInDays == 7) {
            return (amount * 22) / 1000; // 2.20% ~ 2.60%
        } else if (durationInDays == 15) {
            return (amount * 26) / 1000; // 2.60% ~ 3.00%
        } else if (durationInDays == 30) {
            return (amount * 30) / 1000; // 3.00% ~ 3.40%
        }
        return 0; // 默认返回0
    }

    // 奖励领取合约
    function withdrawRewards() external {
        require(block.timestamp >= lockEndTimes[msg.sender], "Lock period not ended"); // 检查锁定期是否结束
        uint256 reward = rewards[msg.sender]; // 获取奖励
        require(reward > 0, "No rewards to withdraw"); // 确保有奖励可提取
        rewards[msg.sender] = 0; // 重置奖励

        require(usdtToken.transfer(msg.sender, reward), "Transfer failed"); // 转移奖励
    }
}