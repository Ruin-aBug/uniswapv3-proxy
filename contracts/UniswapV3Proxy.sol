// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

// import "@uniswap/v3-core/contracts/libraries/TickMath.sol";
// import "@uniswap/v3-core/contracts/libraries/SqrtPriceMath.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";

import "./libraries/TickMath.sol";
import "./libraries/SqrtPriceMath.sol";
import "./libraries/LiquidityAmounts.sol";
import "./libraries/PoolAddress.sol";
import "./interfaces/INonfungiblePositionManager.sol";
import "./interfaces/ISwapRouter.sol";
import "./interfaces/IQuoter.sol";
import "./libraries/TransferHelper.sol";
import "./ConstantInfo.sol";

/**
 * UNIV3SWAP 的代理合约基础接口
 */
contract UniswapV3Proxy is
    ISwapRouter,
    INonfungiblePositionManager,
    ConstantInfo
{
    // address public SWAP_ROUTER = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    // address public QUOTER_ROUTER = 0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6;
    // address public factory = 0x1F98431c8aD98523631AE4a59f267346ea31F984;
    // address public NonfungiblePositionManager =
    //     0xC36442b4a4522E871399CD717aBDD847Ab11FE88;

    function swap(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        address to,
        uint256 amountIn
    ) public payable returns (uint256) {
        uint256 amountOutMin = IQuoter(QUOTER_ROUTER).quoteExactInputSingle(
            tokenIn,
            tokenOut,
            fee,
            amountIn,
            0
        );
        TransferHelper.safeApprove(tokenIn, SWAP_ROUTER, type(uint256).max);
        uint256 amountOut = exactInputSingle(
            ExactInputSingleParams({
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                fee: fee,
                recipient: to,
                deadline: block.timestamp + 300,
                amountIn: amountIn,
                amountOutMinimum: (amountOutMin * 995) / 1000,
                sqrtPriceLimitX96: 0
            })
        );
        return amountOut;
    }

    function getPrice(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountIn
    ) public returns (uint256) {
        TransferHelper.safeApprove(tokenIn, QUOTER_ROUTER, type(uint256).max);
        return
            IQuoter(QUOTER_ROUTER).quoteExactInputSingle(
                tokenIn,
                tokenOut,
                fee,
                amountIn,
                0
            );
    }

    function exactInputSingle(ExactInputSingleParams memory params)
        public
        payable
        override
        returns (uint256 amountOut)
    {
        amountOut = ISwapRouter(SWAP_ROUTER).exactInputSingle(params);
    }

    // 继承自接口的方法，可不进行实现
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata _data
    ) external override {}

    // 获取tick下限
    function _floor(int24 tick, address pool) internal view returns (int24) {
        int24 compressed = tick / tickSpacing(pool);
        if (tick < 0 && tick % tickSpacing(pool) != 0) compressed--;
        return compressed * tickSpacing(pool);
    }

    // 获取tick上限
    function _ceil(int24 tick, address pool) internal view returns (int24) {
        int24 floor = _floor(tick, pool);
        return floor + tickSpacing(pool);
    }

    function getPoolAddress(
        address tokenA,
        address tokenB,
        uint24 fee
    ) public pure returns (address) {
        return
            PoolAddress.computeAddress(
                factory,
                PoolAddress.getPoolKey(tokenA, tokenB, fee)
            );
    }

    // 获取池子的当前相关信息
    function getPoolSlot(
        address tokenA,
        address tokenB,
        uint24 fee
    )
        public
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        )
    {
        address pool = getPoolAddress(tokenA, tokenB, fee);
        return IUniswapV3Pool(pool).slot0();
    }

    // 获取池子当前流动性的量
    function getLiquidity(
        address tokenA,
        address tokenB,
        uint24 fee
    ) public view returns (uint128) {
        return IUniswapV3Pool(getPoolAddress(tokenA, tokenB, fee)).liquidity();
    }

    // 通过池子当前流动性的量获取tokenA、B的量
    function getAmountsForLiquidity(
        address tokenA,
        address tokenB,
        uint24 fee
    ) public view returns (uint256 amount0, uint256 amount1) {
        uint128 liquidity = getLiquidity(tokenA, tokenB, fee);
        address pool = getPoolAddress(tokenA, tokenB, fee);
        (uint160 sqrtRatioX96, int24 tick, , , , , ) = IUniswapV3Pool(pool)
        .slot0();
        // uint160 sqrtRatioX96 = TickMath.getSqrtRatioAtTick(tick);
        uint160 sqrtRatioAX96 = TickMath.getSqrtRatioAtTick(_floor(tick, pool));
        uint160 sqrtRatioBX96 = TickMath.getSqrtRatioAtTick(_ceil(tick, pool));
        (amount0, amount1) = LiquidityAmounts.getAmountsForLiquidity(
            sqrtRatioX96,
            sqrtRatioAX96,
            sqrtRatioBX96,
            liquidity
        );
    }

    function getQuoter(
        address tokenA,
        address tokenB,
        uint24 fee,
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidityDelta
    ) public view returns (uint256, uint256) {
        address pool = getPoolAddress(tokenA, tokenB, fee);
        (uint160 sqrtRatioX96, , , , , , ) = IUniswapV3Pool(pool)
        .slot0();
        int256 amount0 = SqrtPriceMath.getAmount0Delta(
            sqrtRatioX96,
            TickMath.getSqrtRatioAtTick(tickUpper),
            int128(liquidityDelta)
        );
        int256 amount1 = SqrtPriceMath.getAmount1Delta(
            TickMath.getSqrtRatioAtTick(tickLower),
            sqrtRatioX96,
            int128(liquidityDelta)
        );
        return (uint256(amount0),uint256(amount1));
    }

    function tickBitmap(int16 wordPosition, address pool)
        external
        view
        returns (uint256)
    {
        return IUniswapV3Pool(pool).tickBitmap(wordPosition);
    }

    function ticks(int24 tick, address pool)
        external
        view
        returns (
            uint128 liquidityGross,
            int128 liquidityNet,
            uint256 feeGrowthOutside0X128,
            uint256 feeGrowthOutside1X128,
            int56 tickCumulativeOutside,
            uint160 secondsPerLiquidityOutsideX128,
            uint32 secondsOutside,
            bool initialized
        )
    {
        return IUniswapV3Pool(pool).ticks(tick);
    }

    function tickSpacing(address pool) public view returns (int24) {
        return IUniswapV3Pool(pool).tickSpacing();
    }

    // 通过 tokenId 获取 NFT 的相关信息
    function positions(uint256 tokenId)
        public
        view
        override
        returns (
            uint96 nonce,
            address operator,
            address tokenA,
            address tokenB,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        )
    {
        return
            INonfungiblePositionManager(NonfungiblePositionManager).positions(
                tokenId
            );
    }

    // 第一次添加流动性的时候将返回 NFT (在同一个 tick 范围上只会返回一个 NFT)
    function mint(MintParams memory params)
        public
        payable
        override
        returns (
            uint256 tokenId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        )
    {
        TransferHelper.safeApprove(
            params.token1,
            NonfungiblePositionManager,
            type(uint256).max
        );
        TransferHelper.safeApprove(
            params.token0,
            NonfungiblePositionManager,
            type(uint256).max
        );
        (tokenId, liquidity, amount0, amount1) = INonfungiblePositionManager(
            NonfungiblePositionManager
        ).mint(params);
        uint256 amountA = IERC20(params.token0).balanceOf(address(this));
        uint256 amountB = IERC20(params.token1).balanceOf(address(this));
        if (amountA > 0) {
            IERC20(params.token0).transfer(msg.sender, amountA);
        }
        if (amountB > 0) {
            IERC20(params.token1).transfer(msg.sender, amountB);
        }
    }

    // 在该 tick 范围中非第一次添加流动性时调用
    function increaseLiquidity(IncreaseLiquidityParams calldata params)
        external
        payable
        override
        returns (
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        )
    {
        (liquidity, amount0, amount1) = INonfungiblePositionManager(
            NonfungiblePositionManager
        ).increaseLiquidity(params);
    }

    // 移除流动性
    function decreaseLiquidity(DecreaseLiquidityParams memory params)
        public
        payable
        override
        returns (uint256 amount0, uint256 amount1)
    {
        (uint256 amA, uint256 amB) = INonfungiblePositionManager(
            NonfungiblePositionManager
        ).decreaseLiquidity(params);

        (amount0, amount1) = collect(
            CollectParams({
                tokenId: params.tokenId,
                recipient: address(this),
                amount0Max: uint128(amA),
                amount1Max: uint128(amB)
            })
        );
        (, , address tokenA, address tokenB, , , , , , , , ) = positions(
            params.tokenId
        );
        TransferHelper.safeTransfer(tokenA, msg.sender, amount0);
        TransferHelper.safeTransfer(tokenB, msg.sender, amount1);
    }

    function collect(CollectParams memory params)
        public
        payable
        override
        returns (uint256 amount0, uint256 amount1)
    {
        (amount0, amount1) = INonfungiblePositionManager(
            NonfungiblePositionManager
        ).collect(params);
    }

    // 移除流动性
    function burn(uint256 tokenId) external payable override {}
}
