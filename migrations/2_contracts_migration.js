const ChainToken = artifacts.require("../contracts/ChainToken.sol");
const SupplyChain = artifacts.require("../contracts/SupplyChain.sol");
const Strings = artifacts.require("../contracts/utils/Strings.sol");

async function doDeploy(deployer) {
  const stringLibrary = await Strings.new();
  await SupplyChain.detectNetwork();
  await SupplyChain.link('Strings', stringLibrary.address);

  await deployer.deploy(ChainToken, "Chain Token", "CHT", 10000);
  await deployer.deploy(SupplyChain);
}

module.exports = (deployer) => {
  deployer.then(async () => {
      await doDeploy(deployer);
  });
};
