const { expect } = require("chai");
const UniswapV3Proxy = artifacts.require("UniswapV3Proxy");
const fs = require("fs");
const addressConfJson = require("../address.json");
const tokens = require("../tokens.json");

const timestamp = Date.parse(new Date());

describe("UniswapV3Proxy", function () {
    // 0xCC4c9Cd0521d3FC76Bff73b9A990C83f7d26f2a3
    // it("Should return the new uniswapv3 once it's changed", async function () {
    // 	// const UniswapV3Proxy = await ethers.getContractFactory("UniswapV3Proxy");
    // 	// console.log(UniswapV3Proxy);
    // 	const uniswapV3Proxy = await UniswapV3Proxy.at(addressConfJson.uniswapV3Proxy);
    // 	// await uniswapV3Proxy.deployed();
    // 	console.log("代理合约地址：",uniswapV3Proxy.address);
    // });

    it.only(" getAmountsForLiquidity()", async function(){
        console.log("通过池子当前流动性的量获取tokenA、B的量: ");
        const uniswapV3Proxy = await UniswapV3Proxy.at(addressConfJson.uniswapV3Proxy);
        let amou = await uniswapV3Proxy.getAmountsForLiquidity(tokens.UNI, tokens.WETH, 3000);
        console.log("amountA: ", amou[0].toString());
    	console.log("amountB: ", amou[1].toString());
    });

    // it.only(" getLiquidity()", async function(){
    //     console.log("通过池子当前流动性的量获取tokenA、B的量: ");
    //     const uniswapV3Proxy = await UniswapV3Proxy.at(addressConfJson.uniswapV3Proxy);
    //     let li = await uniswapV3Proxy.getLiquidity(tokens.UNI, tokens.WETH, 3000);
    //     console.log("流动性: ", li.toString());
    // });

    function _floor(tick) {
        let compressed = tick / 60;
        if (tick < 0 && tick % 60 != 0) compressed--;
        return compressed * 60;
    }
    function _ceil(tick) {
        return _floor(tick) + 60;
    }

    // it.only(" mint", async function () {
    //     const uniswapV3Proxy = await UniswapV3Proxy.at("0xCC4c9Cd0521d3FC76Bff73b9A990C83f7d26f2a3");
    //     let mintInfo = await uniswapV3Proxy.mint({
    //         token0: tokens.TUSDC,
    //         token1: tokens.WETH,
    //         fee: 3000,
    //         tickLower: 9960,
    //         tickUpper: 10140,
    //         amount0Desired: 10000000,
    //         amount1Desired: 2000900,
    //         amount0Min: 30000,
    //         amount1Min: 0,
    //         recipient: addressConfJson.strategy,
    //         deadline: timestamp + 3000
    //     });
    //     console.log("添加流动性，tokenId:", mintInfo[0]);
    //     console.log("添加流动性，流动性:", mintInfo[1]);
    //     console.log("添加流动性，amountA:", mintInfo[2]);
    //     console.log("添加流动性，amountB:", mintInfo[3]);
    //     console.log(_floor(9960));
    //     console.log(_ceil(10140));
    // });

    // it.only(" decreaseLiquidity", async function () {
    //     let to = "0xF9758dB6571Cfe61e6eB9146D82A0f0FF7ACBc45";
    //     let _tokenId = 3312;
    //     let _liquidity = 18365375;
    //     const uniswapV3Proxy = await UniswapV3Proxy.at(addressConfJson.uniswapV3Proxy);
    //     let de = uniswapV3Proxy.decreaseLiquidity({
    //         tokenId: _tokenId,
    //         liquidity: 474221726,
    //         amount0Min: 0,
    //         amount1Min: 0,
    //         deadline: timestamp + 3000
    //     });
    //     // console.log("移除流动性 A 的量",de[0].toString());
    //     // console.log("移除流动性 B 的量",de[1].toString());
    // });

});
