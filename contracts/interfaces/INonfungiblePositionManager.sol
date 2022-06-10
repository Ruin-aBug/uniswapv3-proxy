// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

import "./IERC721Permit.sol";
import "./IPeripheryImmutableState.sol";
import "../libraries/PoolAddress.sol";
import "./IV3PoolStruct.sol";

interface INonfungiblePositionManager is IV3PoolStruct {
    // event IncreaseLiquidity(
    //     uint256 indexed tokenId,
    //     uint128 liquidity,
    //     uint256 amount0,
    //     uint256 amount1
    // );

    // event DecreaseLiquidity(
    //     uint256 indexed tokenId,
    //     uint128 liquidity,
    //     uint256 amount0,
    //     uint256 amount1
    // );

    // event Collect(
    //     uint256 indexed tokenId,
    //     address recipient,
    //     uint256 amount0,
    //     uint256 amount1
    // );

    // 获取 NFT 相关信息
    function positions(uint256 tokenId)
        external
        view
        returns (
            uint96 nonce,
            address operator,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    // struct MintParams {
    //     address token0;
    //     address token1;
    //     uint24 fee;
    //     int24 tickLower;
    //     int24 tickUpper;
    //     uint256 amount0Desired;
    //     uint256 amount1Desired;
    //     uint256 amount0Min;
    //     uint256 amount1Min;
    //     address recipient;
    //     uint256 deadline;
    // }

    // 添加流动性
    function mint(MintParams calldata params)
        external
        payable
        returns (
            uint256 tokenId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        );

    // struct IncreaseLiquidityParams {
    //     uint256 tokenId;
    //     uint256 amount0Desired;
    //     uint256 amount1Desired;
    //     uint256 amount0Min;
    //     uint256 amount1Min;
    //     uint256 deadline;
    // }

    // 添加流动性
    function increaseLiquidity(IncreaseLiquidityParams calldata params)
        external
        payable
        returns (
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        );

    // struct DecreaseLiquidityParams {
    //     uint256 tokenId;
    //     uint128 liquidity;
    //     uint256 amount0Min;
    //     uint256 amount1Min;
    //     uint256 deadline;
    // }

    // 移除流动性
    function decreaseLiquidity(DecreaseLiquidityParams calldata params)
        external
        payable
        returns (uint256 amount0, uint256 amount1);

    // struct CollectParams {
    //     uint256 tokenId;
    //     address recipient;
    //     uint128 amount0Max;
    //     uint128 amount1Max;
    // }

    function collect(CollectParams calldata params)
        external
        payable
        returns (uint256 amount0, uint256 amount1);

    // 移除流动性
    function burn(uint256 tokenId) external payable;
}
