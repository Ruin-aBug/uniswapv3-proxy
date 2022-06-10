const { expect } = require("chai");
const { default: BigNumber } = require("bignumber.js");
const Strategy = artifacts.require("Strategy");
const fs = require("fs");
const bignumber = require("bignumber.js");
const addressConfJson = require("../address.json");
const tokens = require("../tokens.json");
const approve = artifacts.require("ERC20Approve");

const timestamp = Date.parse(new Date());

describe("Strategy", function () {
    // 
    // 0xecC92947DeF6eCd509f8fA153bb55879765E2a3E
    // it.only("授权", async function(){
    //     const approves = await approve.at(addressConfJson.approve);
    //     console.log("授权 WETH 币：", await approves.approve(tokens.WETH, addressConfJson.strategy, new BigNumber(1).times(1e18)));
    //     console.log("授权 UNI 币：", await approves.approve(tokens.UNI, addressConfJson.strategy, new BigNumber(1).times(1e18)));
    // });

    // it.only("查询授权信息：", async function(){
    //     const approves = await approve.at(addressConfJson.approve);
    //     let onwe = "0xF9758dB6571Cfe61e6eB9146D82A0f0FF7ACBc45";
    //     console.log("WETH 授权数量：", await approves.allowance(tokens.WETH, onwe, addressConfJson.strategy ));
    //     console.log("UNI 授权数量：", await approves.allowance(tokens.UNI, onwe, addressConfJson.strategy ));
    // });

    // it.only("合约实例：", async function () {
    //     const strategy = await Strategy.at(addressConfJson.strategy);
    //     console.log("Strategy合约地址：",strategy.address);
    // });

    // it.only(" deposit", async function(){
    //     console.log("抵押资产: ");
    //     let tokenA = tokens.UNI;
    //     let tokenB = tokens.WETH;
    //     let amountA = 100000;
    //     let amountB = 1000000;
    //     // let amountA = new bignumber(1).times(1e18);
    //     // let amountB = new bignumber(0.5).times(1e18);
    //     let to = "0xF9758dB6571Cfe61e6eB9146D82A0f0FF7ACBc45";
    //     const strategy = await Strategy.at(addressConfJson.strategy);
    //     await strategy.deposit(tokenA, tokenB, amountA, amountB, to);
    //     console.log("抵押资产完成");
    // });

    // it.only(" getUserInfo", async function () {
    //     let to = "0xF9758dB6571Cfe61e6eB9146D82A0f0FF7ACBc45";
    //     const strategy = await Strategy.at(addressConfJson.strategy);
    //     let info = await strategy.getUserInfo(to, tokens.UNI, tokens.WETH)
    //     console.log("抵押信息：");
    //     console.log("tokenA: ", info[0].toString());
    //     console.log("tokenB: ", info[1].toString());
    //     console.log("amountA: ", info[2].toString());
    //     console.log("amountB: ", info[3].toString());
    //     console.log("infoId: ", info[4].toString());
    //     console.log(_floor(6946));
    //     console.log(BigNumber(1).times(1e18));
    // });

    // it.only("userInfo",async function(){
    //     const strategy = await Strategy.at(addressConfJson.strategy);
    //     const info = await strategy.userInfo("0xF9758dB6571Cfe61e6eB9146D82A0f0FF7ACBc45",1);
    //     console.log("抵押信息：");
    //     console.log("tokenA: ",info[0].toString());
    //     console.log("tokenB: ",info[1].toString());
    //     console.log("amountA: ",info[2].toString());
    //     console.log("amountB: ",info[3].toString());
    //     console.log("infoId: ",info[4].toString());
    // })

    function _floor(tick) {
        const compressed = parseInt(tick / 60);
        if (tick < 0 && tick % 60 != 0) compressed;
        return compressed * 60;
    }
    function _ceil(tick) {
        return _floor(tick) + 60;
    }

    // it.only(" mint", async function () {
    //     const strategy = await Strategy.at(addressConfJson.strategy);
    //     const amount0 = 1000;
    //     let _tickLower = 6840;
    //     let _tickUpper = 7020;
    //     const amount1 = await strategy.getAmountOutForAmountIn(tokens.UNI, tokens.WETH, 3000, _tickLower, _tickUpper, amount0);
    //     // console.log(timestamp/1000);
    //     console.log(amount0);
    //     console.log(amount1.toString(16));
    //     await strategy.mint({
    //         token0: tokens.UNI,
    //         token1: tokens.WETH,
    //         fee: 3000,
    //         tickLower: _tickLower,
    //         tickUpper: _tickUpper,
    //         amount0Desired: amount0,
    //         amount1Desired: amount1.toNumber(),
    //     }, 1004, "0xF9758dB6571Cfe61e6eB9146D82A0f0FF7ACBc45");
    // });

    // it.only("getStrategyInfo",async function(){
    //     const strategy = await Strategy.at(addressConfJson.strategy);
    //     const res = await strategy.getStrategyInfo();
    //     console.log(res);
    // });

    // it.only("getAmountsForLiquidity", async function () {
    //     let liquidity = new bignumber(1).times(1e18);
    //     const str = await Strategy.at(addressConfJson.strategy);
    //     const amount = await str.getAmountsForLiquidity(tokens.UNI, tokens.WETH, 3000, liquidity, 6900, 6960);
    //     console.log(amount[0].toString());
    //     console.log(amount[1].toString());
    // });

    it.only("getQuoter", async function () {
        const str = await Strategy.at(addressConfJson.strategy);
        const res = await str.getQuoter(tokens.UNI, tokens.WETH, 3000, 6900, 6960, 90000, 3000);
        console.log(res[0].toString());
        console.log(res[1].toString());
    });

    it.only("getAmountOutForAmountIn", async function () {
        const str = await Strategy.at(addressConfJson.strategy);
        const res = await str.getAmountOutForAmountIn(tokens.UNI, tokens.WETH, 3000, 6900, 6960, 353);
        console.log("amount1", res.toString());
    });

    it.only("getAmountInForAmountOut", async function () {
        const str = await Strategy.at(addressConfJson.strategy);
        const res = await str.getAmountInForAmountOut(tokens.WETH, tokens.UNI, 3000, 6900, 6960, 3000);
        console.log("amount0", res.toString());
    });

    // it.only("get prcie",async function(){
    //     const strategy = await Strategy.at(addressConfJson.strategy);
    //     const res = await strategy.getPrice(tokens.UNI,tokens.WETH,3000);
    //     console.log("价格：", res.logs[0].args[0].toString());
    // });

    // it.only(" getPoolAddres", async function(){
    //     const strategy = await Strategy.at(addressConfJson.strategy);
    //     console.log("池子地址：",await strategy.getPoolAddress(tokens.TUSDC,tokens.ETH,3000));
    // });

    // it.only("getPoolSlot", async function(){
    //     const strategy = await Strategy.at(addressConfJson.strategy);
    //     let pool = await strategy.getPoolSlot(tokens.UNI,tokens.WETH,3000);
    //     console.log("获取池子相关信息");
    //     console.log("1, sqrtPriceX96: ",pool[0].toString());
    //     console.log("2, tick: ",pool[1].toString());
    //     console.log("3, observationIndex: ",pool[2].toString());
    //     console.log("4, observationCardinality: ",pool[3].toString());
    //     console.log("5, observationCardinalityNext: ",pool[4].toString());
    //     console.log("6, feeProtocol: ",pool[5].toString());
    //     console.log("7, unlocked: ",pool[6].toString());
    // });

    // it.only("test",function(){
    //     let x = 6.3000;
    //     console.log(new bignumber(x).integerValue(1).toString());
    // })

    // it.only(" positions", async function(){
    //     let tokenId = 3254;
    //     const strategy = await Strategy.at(addressConfJson.strategy);
    //     let po = await strategy.positions(tokenId);
    //     console.log("获取NFT相关信息");
    //     console.log("1, nonce: ",po[0].toString());
    //     console.log("2, operator: ",po[1].toString());
    //     console.log("3, tokenA: ",po[2].toString());
    //     console.log("4, tokenB: ",po[3].toString());
    //     console.log("5, fee: ",po[4].toString());
    //     console.log("6, tickLower: ",po[5].toString());
    //     console.log("7, tickUpper: ",po[6].toString());
    //     console.log("8, liquidity: ",po[7].toString());
    //     console.log("9, feeGrowthInside0LastX128: ",po[8].toString());
    //     console.log("10, feeGrowthInside1LastX128: ",po[9].toString());
    //     console.log("11, tokensOwed0: ",po[10].toString());
    //     console.log("12, tokensOwed1: ",po[11].toString());
    // });

    // it.only(" niuBFunction", async function(){
    //     console.log("策略执行函数:");
    //     let niub = [
    //         {
    //           token0: tokens.UNI,
    //           token1: tokens.WETH,
    //           fee: 3000,
    //           tickLower: 9960,
    //           tickUpper: 10140,
    //           amount0Desired: 1000000,
    //           amount1Desired: 0,
    //           id: 1626941534,
    //           to:"0xF9758dB6571Cfe61e6eB9146D82A0f0FF7ACBc45",
    //           flag: 1
    //         }];
    //     const strategy = await Strategy.at(addressConfJson.strategy);
    //     await strategy.niuBFunction(niub);
    //     console.log("策略执行完成");
    // });

    // it.only(" decreaseLiquidity", async function(){
    //     let to = "0xF9758dB6571Cfe61e6eB9146D82A0f0FF7ACBc45";
    //     let strId = 1004;
    //     const strategy = await Strategy.at(addressConfJson.strategy);
    //     let de = strategy.decreaseLiquidity(to, strId);
    //     // console.log("移除流动性 A 的量",de[0].toString());
    //     // console.log("移除流动性 B 的量",de[1].toString());
    // });

    // it.only(" withdraw", async function(){
    //     console.log("提取资产: ");
    //     let to = "0xF9758dB6571Cfe61e6eB9146D82A0f0FF7ACBc45";
    //     // let amountA = BigNumber(14.9999).times(1e18);
    //     // let amountB = BigNumber(9).times(1e18);
    //     let amountA = 109999;
    //     let amountB = 1099999;
    //     const strategy = await Strategy.at(addressConfJson.strategy);
    //     await strategy.withdraw( tokens.UNI, tokens.WETH, amountA, amountB, to);
    //     console.log("提取资产完成");
    // });
});