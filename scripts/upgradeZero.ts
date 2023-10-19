import * as hre from "hardhat";
import { MeowToken, ZeroToken } from "../typechain";
import { getLogger } from "../utilities";

const logger = getLogger("scripts::deployZERO");

// Sepolia
const zeroTokenAddress = "0x1A9A8894bc8611a39c7Ed690AED71b7918995F14";

// Test accounts that have existing balances
const testAccounts = [
  "0xaE3153c9F5883FD2E78031ca2716520748c521dB",
  "0xa74b2de2D65809C613010B3C8Dc653379a63C55b",
  "0x0f3b88095e750bdD54A25B2109c7b166A34B6dDb"
];

async function main() {
  await hre.run("compile");

  logger.log("Upgrading ZERO token to MEOW");

  logger.log(`Upgrading on ${hre.network.name}`);

  const [deployer] = await hre.ethers.getSigners();

  logger.log(
    `'${deployer.address}' will be used as the deployment account`
  );

  const zeroTokenFactory = await hre.ethers.getContractFactory("ZeroToken", deployer);
  const token = zeroTokenFactory.attach(zeroTokenAddress) as ZeroToken;

  logger.log(`Preupgrade checking balances of test accounts`);
  for (const user of testAccounts) {
    const balance = await token.balanceOf(user);
    logger.log(`Balance of ${user} is ${balance.toString()}`);
  }

  const meowTokenFactory = await hre.ethers.getContractFactory("MeowToken", deployer);

  const contract = await hre.upgrades.upgradeProxy(
    zeroTokenAddress,
    meowTokenFactory
  ) as MeowToken;

  await contract.deployed();

  logger.log(`Upgraded contract at address: ${zeroTokenAddress}`);
  const implAddr = await hre.upgrades.erc1967.getImplementationAddress(zeroTokenAddress);
  logger.log(`With implementation contract address at: ${implAddr}`);

  const meowtoken = meowTokenFactory.attach(zeroTokenAddress)

  logger.log(`Postupgrade checking balances of test accounts`);
  for (const user of testAccounts) {
    const balance = await meowtoken.balanceOf(user);
    logger.log(`Balance of ${user} is ${balance.toString()}`);
  }
}

const tryMain = async () => {
  await main();
}

tryMain();