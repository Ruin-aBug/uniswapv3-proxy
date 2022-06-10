// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// import "@uniswap/v3-core/contracts/libraries/TickMath.sol";

import "./interfaces/IV3PoolStruct.sol";
import "./interfaces/IStrategyStruct.sol";
import "./interfaces/IUniswapV3Proxy.sol";
import "./libraries/TransferHelper.sol";
import "./libraries/LiquidityAmounts.sol";
import "./libraries/PoolAddress.sol";
import "./libraries/TickMath.sol";
import "./libraries/SafeMath.sol";

/**
 * 网格策略所调用的复合逻辑合约
 */
contract Strategy is IV3PoolStruct, IStrategyStruct {
    using SafeMath for uint256;
    address public UniswapV3_Proxy;

    constructor(address univ3Proxy) {
        UniswapV3_Proxy = univ3Proxy;
    }

    // uint16 strategyId; // 策略id
    uint16 tokenPairId; // 对币id
    mapping(address => StrategyForUser) strategyForUser; // 记录user所操作的策略id数组
    mapping(uint64 => MintLiquidity) public mintLiquidity; // 策略添加流动性信息
    mapping(address => mapping(address => uint16)) tokenPair; // 通过对币地址得到一个对币id
    mapping(address => mapping(uint16 => UserInfo)) public userInfo; // 通过user地址和对币id查找user资金信息

    ///////////////////////////////////////////////////////////////////
    // 1、换币
    function swap(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountIn
    ) public payable returns (uint256) {
        TransferHelper.safeTransfer(tokenIn, UniswapV3_Proxy, amountIn);
        return
            IUniswapV3Proxy(UniswapV3_Proxy).swap(
                tokenIn,
                tokenOut,
                fee,
                address(this),
                amountIn
            );
    }

    event Price(uint256 price);

    // 2、获取价格
    function getPrice(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountIn
    ) public returns (uint256) {
        uint256 price = IUniswapV3Proxy(UniswapV3_Proxy).getPrice(
            tokenIn,
            tokenOut,
            fee,
            amountIn
        );
        emit Price(price);
        return price;
    }

    // 3、获取池子当前相关信息
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
        return
            IUniswapV3Proxy(UniswapV3_Proxy).getPoolSlot(tokenA, tokenB, fee);
    }

    // 4、通过 tokenId 获取 NFT 的相关信息
    function positions(uint256 tokenId)
        public
        view
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
        return IUniswapV3Proxy(UniswapV3_Proxy).positions(tokenId);
    }

    event Mint(
        address token0,
        address token1,
        uint24 fee,
        uint256 amount0,
        uint256 amount1,
        int24 tickLower,
        int24 tickUpper
    );

    // 5、第一次添加流动性的时候将返回 NFT (在同一个 tick 范围上只会返回一个 NFT)
    function mint(
        MintParam memory params,
        uint64 styId,
        address to
    ) public payable {
        TransferHelper.safeTransfer(
            params.token0,
            UniswapV3_Proxy,
            params.amount0Desired
        );
        TransferHelper.safeTransfer(
            params.token1,
            UniswapV3_Proxy,
            params.amount1Desired
        );
        UserInfo storage user = userInfo[to][
            tokenPair[params.token0][params.token1]
        ];
        (
            uint256 _tokenId,
            uint128 _liquidity,
            uint256 _amount0,
            uint256 _amount1
        ) = _mint(params);

        StrategyForUser storage styForUser = strategyForUser[to];
        styForUser.ids.push(styId);
        mintLiquidity[styId] = MintLiquidity({
            tokenId: _tokenId,
            liquidity: _liquidity,
            amount0: _amount0,
            amount1: _amount1,
            strategyId: styId
        });
        user.amountA = user.amountA.sub(_amount0);
        user.amountB = user.amountB.sub(_amount1);
        emit Mint(
            params.token0,
            params.token1,
            params.fee,
            params.amount0Desired,
            params.amount1Desired,
            params.tickLower,
            params.tickUpper
        );
    }

    function _mint(MintParam memory params)
        internal
        returns (
            uint256 tokenId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        )
    {
        (tokenId, liquidity, amount0, amount1) = IUniswapV3Proxy(
            UniswapV3_Proxy
        ).mint(
            MintParams({
                token0: params.token0,
                token1: params.token1,
                fee: params.fee,
                tickLower: params.tickLower,
                tickUpper: params.tickUpper,
                amount0Desired: params.amount0Desired,
                amount1Desired: params.amount1Desired,
                amount0Min: (params.amount0Desired * 995) / 1000,
                amount1Min: (params.amount1Desired * 995) / 1000,
                recipient: UniswapV3_Proxy,
                deadline: block.timestamp + 30000
            })
        );
    }

    event DecreaseLiquidit(address to, uint64 strId);

    // 6、移除流动性
    function decreaseLiquidity(address to, uint64 strId)
        public
        payable
        returns (uint256 amount0, uint256 amount1)
    {
        MintLiquidity storage info = mintLiquidity[strId];
        (
            ,
            ,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            ,
            ,
            ,

        ) = positions(info.tokenId);
        (uint256 amountA, uint256 amountB) = getAmountsForLiquidity(
            token0,
            token1,
            fee,
            liquidity,
            tickLower,
            tickUpper
        );
        (amount0, amount1) = IUniswapV3Proxy(UniswapV3_Proxy).decreaseLiquidity(
            DecreaseLiquidityParams({
                tokenId: info.tokenId,
                liquidity: info.liquidity,
                amount0Min: (amountA * 995) / 1000,
                amount1Min: (amountB * 995) / 1000,
                deadline: block.timestamp + 3000
            })
        );
        info.amount0 = 0;
        info.amount1 = 0;
        info.liquidity = 0;
        UserInfo storage user = userInfo[to][tokenPair[token0][token1]];
        user.amountA += amount0;
        user.amountB += amount1;

        emit DecreaseLiquidit(to, strId);
    }

    // 7、获取池子地址
    function getPoolAddress(
        address tokenA,
        address tokenB,
        uint24 fee
    ) public view returns (address) {
        return
            IUniswapV3Proxy(UniswapV3_Proxy).getPoolAddress(
                tokenA,
                tokenB,
                fee
            );
    }

    // 通过流动性的量获取返回的amountA和amountB
    function getAmountsForLiquidity(
        address tokenA,
        address tokenB,
        uint24 fee,
        uint128 liquidity,
        int24 tickLower,
        int24 tickUpper
    ) public view returns (uint256 amount0, uint256 amount1) {
        address pool = getPoolAddress(tokenA, tokenB, fee);
        (uint160 sqrtRatioX96, , , , , , ) = IUniswapV3Pool(pool).slot0();
        // uint160 sqrtRatioX96 = TickMath.getSqrtRatioAtTick(tick);
        uint160 sqrtRatioAX96 = TickMath.getSqrtRatioAtTick(tickLower);
        uint160 sqrtRatioBX96 = TickMath.getSqrtRatioAtTick(tickUpper);
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
        uint256 amountA,
        uint256 amountB
    ) public view returns (uint256 amount0, uint256 amount1) {
        address pool = getPoolAddress(tokenA, tokenB, fee);
        (uint160 sqrtRatioX96, , , , , , ) = IUniswapV3Pool(pool).slot0();
        // uint160 sqrtRatioX96 = TickMath.getSqrtRatioAtTick(tick);
        uint160 sqrtRatioAX96 = TickMath.getSqrtRatioAtTick(tickLower);
        uint160 sqrtRatioBX96 = TickMath.getSqrtRatioAtTick(tickUpper);
        uint128 liquidityDelta = LiquidityAmounts.getLiquidityForAmounts(
            sqrtRatioX96,
            sqrtRatioAX96,
            sqrtRatioBX96,
            amountA,
            amountB
        );
        (amount0, amount1) = IUniswapV3Proxy(UniswapV3_Proxy).getQuoter(
            tokenA,
            tokenB,
            fee,
            tickLower,
            tickUpper,
            liquidityDelta
        );
    }

    function getAmountOutForAmountIn(
        address tokenA,
        address tokenB,
        uint24 fee,
        int24 tickLower,
        int24 tickUpper,
        uint256 amountIn
    ) public view returns (uint256 amountOut) {
        address pool = getPoolAddress(tokenA, tokenB, fee);
        (uint160 sqrtRatioX96, , , , , , ) = IUniswapV3Pool(pool).slot0();
        uint160 sqrtRatioAX96 = TickMath.getSqrtRatioAtTick(tickLower);
        uint160 sqrtRatioBX96 = TickMath.getSqrtRatioAtTick(tickUpper);
        uint128 liquidity0 = LiquidityAmounts.getLiquidityForAmount0(
            sqrtRatioX96,
            sqrtRatioBX96,
            amountIn
        );
        amountOut = LiquidityAmounts.getAmount1ForLiquidity(
            sqrtRatioAX96,
            sqrtRatioX96,
            liquidity0
        );
    }

    function getAmountInForAmountOut(
        address tokenB,
        address tokenA,
        uint24 fee,
        int24 tickLower,
        int24 tickUpper,
        uint256 amountOut
    ) public view returns (uint256 amountIn) {
        address pool = getPoolAddress(tokenA, tokenB, fee);
        (uint160 sqrtRatioX96, , , , , , ) = IUniswapV3Pool(pool).slot0();
        uint160 sqrtRatioAX96 = TickMath.getSqrtRatioAtTick(tickLower);
        uint160 sqrtRatioBX96 = TickMath.getSqrtRatioAtTick(tickUpper);
        uint128 liquidity = LiquidityAmounts.getLiquidityForAmount1(sqrtRatioAX96, sqrtRatioX96, amountOut);
        amountIn = LiquidityAmounts.getAmount0ForLiquidity(sqrtRatioX96, sqrtRatioBX96, liquidity);
    }

    // function multicall(bytes[] calldata data) external payable returns (bytes[] memory results) {
    //     results = new bytes[](data.length);
    //     for (uint256 i = 0; i < data.length; i++) {
    //         (bool success, bytes memory result) = address(this).delegatecall(data[i]);

    //         if (!success) {
    //             // Next 5 lines from https://ethereum.stackexchange.com/a/83577
    //             if (result.length < 68) revert();
    //             assembly {
    //                 result := add(result, 0x04)
    //             }
    //             revert(abi.decode(result, (string)));
    //         }

    //         results[i] = result;
    //     }
    // }
    // event NB(address token0,uint256 amount0,uint64 id,address to, uint8 flag);
    // 8、终极无敌函数
    function niuBFunction(NiuB[] memory niub) external payable {
        uint256 amountA;
        uint256 amountB;
        for (uint256 i = 0; i < niub.length; i++) {
            // emit NB(niub[i].token0,niub[i].amount0Desired,niub[i].id,niub[i].to,niub[i].flag);
            if (niub[i].flag == 1) {
                if (
                    niub[i].amount0Desired != 0 || niub[i].amount1Desired != 0
                ) {
                    //添加
                    mint(
                        MintParam({
                            token0: niub[i].token0,
                            token1: niub[i].token1,
                            fee: niub[i].fee,
                            tickLower: niub[i].tickLower,
                            tickUpper: niub[i].tickUpper,
                            amount0Desired: niub[i].amount0Desired,
                            amount1Desired: niub[i].amount1Desired
                        }),
                        niub[i].id,
                        niub[i].to
                    );
                } else {
                    //添加
                    mint(
                        MintParam({
                            token0: niub[i].token0,
                            token1: niub[i].token1,
                            fee: niub[i].fee,
                            tickLower: niub[i].tickLower,
                            tickUpper: niub[i].tickUpper,
                            amount0Desired: amountA,
                            amount1Desired: amountB
                        }),
                        niub[i].id,
                        niub[i].to
                    );
                }
            } else if (niub[i].flag == 2) {
                //移除
                (amountA, amountB) = decreaseLiquidity(niub[i].to, niub[i].id);
            } else if (niub[i].flag == 3) {
                if (niub[i].amount0Desired == 0) {
                    if (amountA == 0) {
                        //交换
                        amountA = swap(
                            niub[i].token0,
                            niub[i].token1,
                            niub[i].fee,
                            amountB
                        );
                    } else {
                        //交换
                        amountB = swap(
                            niub[i].token0,
                            niub[i].token1,
                            niub[i].fee,
                            amountA
                        );
                    }
                } else {
                    //交换
                    swap(
                        niub[i].token0,
                        niub[i].token1,
                        niub[i].fee,
                        niub[i].amount0Desired
                    );
                }
            } else {
                revert("no flag");
            }
        }
    }

    // 9、查询策略信息
    function getStrategyInfo() public view returns (MintLiquidity[] memory) {
        MintLiquidity[] memory mintInfo = new MintLiquidity[](
            strategyForUser[msg.sender].ids.length
        );
        for (
            uint16 index = 0;
            index < strategyForUser[msg.sender].ids.length;
            index++
        ) {
            mintInfo[index] = mintLiquidity[
                strategyForUser[msg.sender].ids[index]
            ];
        }
        return mintInfo;
    }

    // 10、抵押资产
    function deposit(
        address tokenA,
        address tokenB,
        uint256 amountA,
        uint256 amountB,
        address to
    ) external payable {
        // require(id<= infoId, "IE");
        TransferHelper.safeTransferFrom(tokenA, to, address(this), amountA);
        TransferHelper.safeTransferFrom(tokenB, to, address(this), amountB);
        // uint16 id;
        if (tokenPair[tokenA][tokenB] == 0) {
            tokenPairId++;
            // id = tokenPairId;
            tokenPair[tokenA][tokenB] = tokenPairId;
            tokenPair[tokenB][tokenA] = tokenPairId;
            UserInfo storage user = userInfo[to][tokenPair[tokenA][tokenB]];
            user.tokenA = tokenA;
            user.tokenB = tokenB;
            user.amountA = amountA;
            user.amountB = amountB;
            user.infoId = tokenPairId;
        } else {
            // id = tokenPair[tokenA][tokenB];
            UserInfo storage user = userInfo[to][tokenPair[tokenA][tokenB]];
            user.amountA += amountA;
            user.amountB += amountB;
        }
        emit Deposit(
            tokenA,
            tokenB,
            amountA,
            amountB,
            tokenPair[tokenA][tokenB]
        );
    }

    // 11、提取资产
    function withdraw(
        address tokenA,
        address tokenB,
        uint256 amountA,
        uint256 amountB,
        address to
    ) external payable {
        require(tokenPair[tokenA][tokenB] != 0, "WE");
        UserInfo storage user = userInfo[to][tokenPair[tokenA][tokenB]];
        require(user.amountA >= amountA, "WE0");
        TransferHelper.safeTransfer(user.tokenA, to, amountA);
        TransferHelper.safeTransfer(user.tokenB, to, amountB);
        user.amountA = user.amountA.sub(amountA);
        user.amountB = user.amountB.sub(amountB);
        emit Withdraw(
            user.tokenA,
            user.tokenB,
            amountA,
            amountB,
            tokenPair[tokenA][tokenB]
        );
    }

    // 12、查询抵押信息
    function getUserInfo(
        address to,
        address tokenA,
        address tokenB
    )
        public
        view
        returns (
            address token0,
            address token1,
            uint256 amountA,
            uint256 amountB,
            uint16 infoId
        )
    {
        uint16 uid = tokenPair[tokenA][tokenB];
        UserInfo memory user = userInfo[to][uid];
        token0 = user.tokenA;
        token1 = user.tokenB;
        amountA = user.amountA;
        amountB = user.amountB;
        infoId = user.infoId;
    }
}
