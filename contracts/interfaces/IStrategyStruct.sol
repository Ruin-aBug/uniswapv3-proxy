// SPDX-License-Identifier: MIT
pragma solidity >=0.7.5;
pragma abicoder v2;

/**
 * Strategy 中的结构体
 */
interface IStrategyStruct {
    // 0、niuB
    struct NiuB {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint64 id;
        address to;
        uint8 flag; // 用于定位执行方法（1.添加，2.移除，3.交换）
    }

    // 1、记录用户操作的策略ID
    struct StrategyForUser {
        uint64[] ids;
    }

    // function strategyForUser(address to) external view returns(StrategyForUser memory);

    // mint 参数
    struct MintParam {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
    }

    // 2、记录流动性
    struct MintLiquidity {
        uint256 tokenId;
        uint128 liquidity;
        uint256 amount0;
        uint256 amount1;
        uint64 strategyId;
    }

    // function mintLiquidity(uint64 strId)
    //     external
    //     view
    //     returns (
    //         uint256 tokenId,
    //         uint128 liquidity,
    //         uint256 amount0,
    //         uint256 amount1,
    //         uint64 strategyId
    //     );

    // 3、记录用户信息
    struct UserInfo {
        address tokenA;
        address tokenB;
        uint256 amountA;
        uint256 amountB;
        uint16 infoId;
    }

    // function userInfo(address to, uint16 id)
    //     external
    //     view
    //     returns (
    //         address tokenA,
    //         address tokenB,
    //         uint256 amountA,
    //         uint256 amountB,
    //         uint16 infoId
    //     );

    event Deposit(
        address tokenA,
        address tokenB,
        uint256 amountA,
        uint256 amountB,
        uint32 infoId
    );

    event Withdraw(
        address tokenA,
        address tokenB,
        uint256 amountA,
        uint256 amountB,
        uint32 infoId
    );
}
