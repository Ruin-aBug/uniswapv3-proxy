const { default: BigNumber } = require("bignumber.js");
const { expect } = require("chai");
const addressConfJson = require("../address.json");
const tokens = require("../tokens.json");
const approve = artifacts.require("ERC20Approve");


describe("授权合约 ERC20Approve：", function () {

    it.only("开始授权WETH：", async function(){
        const approves = await approve.at(addressConfJson.approve);
        console.log("授权 WETH 币：", await approves.approve(tokens.WETH, addressConfJson.strategy, new BigNumber(1).times(1e18)));
    });

    it.only("开始授权UNI：", async function(){
        const approves = await approve.at(addressConfJson.approve);
        console.log("授权 UNI 币：", await approves.approve(tokens.UNI, addressConfJson.strategy, new BigNumber(2).times(1e18)));
    });

    it.only("查询授权WETH信息：", async function(){
        const approves = await approve.at(addressConfJson.approve);
        let onwe = "0xF9758dB6571Cfe61e6eB9146D82A0f0FF7ACBc45";
        let weth = await approves.allowance(tokens.WETH, onwe, addressConfJson.strategy );
        console.log("WETH 授权数量：", weth.toString());
    });

    it.only("查询授权UNI信息：", async function(){
        const approves = await approve.at(addressConfJson.approve);
        let onwe = "0xF9758dB6571Cfe61e6eB9146D82A0f0FF7ACBc45";
        let uni = await approves.allowance(tokens.UNI, onwe, addressConfJson.strategy );
        console.log("UNI 授权数量：", uni.toString());
    });


});