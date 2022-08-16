// function deployFunc(hre) {
//   console.log("hi");
// }

const { network } = require("hardhat");
const { networkConfig } = require("../helper-hardhat-config");
const { verify } = require("../utils/verify");
// module.exports.default = deployFunc;

module.exports = async (hre) => {
  const { getNamedAccounts, deployments } = hre;
  const { deploy, log } = deployments;
  const { deployer } = await getNamedAccounts();
  const chainId = network.config.chainId;

  // if chainId is X use address Y
  // if chainId is Z use address A
  // console.log(`__________${chainId}_________ass`);

  let ethUsdPriceFeedAddress;
  if (chainId == 31337) {
    const ethUsdAggregator = await deployments.get("MockV3Aggregator");
    ethUsdPriceFeedAddress = ethUsdAggregator.address;
  } else {
    ethUsdPriceFeedAddress = networkConfig[chainId]["ethUsdPriceFeed"];
  }
  //if the contract doesn't exist, we deploy a minimal version of it for our local testing

  // well what happens when we want to change chains?
  // when going for localhost or hardhat network we want to use a mock
  const args = [ethUsdPriceFeedAddress];
  const fundMe = await deploy("FundMe", {
    from: deployer,
    args: [ethUsdPriceFeedAddress], // put price feed address
    log: true,
    waitConfirmations: network.config.blockConfirmations || 1,
  });

  // verify

  if (chainId !== 31337 && process.env.ETHERSCAN_API_KEY) {
    await verify(fundMe.address, args);
  }
  log("-----------------------------------------");
};

module.exports.tags = ["all", "fundme"];
