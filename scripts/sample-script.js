// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");
const fs = require("fs");
const addressConfJson = require("../address.json");
const tokens = require("../tokens.json");

async function main() {
	// Hardhat always runs the compile task when running scripts with its command
	// line interface.
	//
	// If this script is run directly using `node` you may want to call compile
	// manually to make sure everything is compiled
	// await hre.run('compile');

	// We get the contract to deploy
	const UniswapV3Proxy = await hre.ethers.getContractFactory("UniswapV3Proxy");
	const uniswapV3Proxy = await UniswapV3Proxy.deploy();

	await uniswapV3Proxy.deployed();

	console.log("UniswapV3Proxy deployed to:", uniswapV3Proxy.address);
	
	const Strategy = await hre.ethers.getContractFactory("Strategy");
	const strategy = await Strategy.deploy(uniswapV3Proxy.address);

	await strategy.deployed();
	addressConfJson.uniswapV3Proxy = uniswapV3Proxy.address;
	addressConfJson.strategy = strategy.address;
	fs.writeFileSync("./address.json", JSON.stringify(addressConfJson), "utf8");

	console.log("Strategy deployed to:", strategy.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
	.then(() => process.exit(0))
	.catch((error) => {
		console.error(error);
		process.exit(1);
	});
