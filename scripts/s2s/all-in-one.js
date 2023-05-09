const hre = require("hardhat");

async function main() {
  const pangolinEndpointAddress = "0xE8C0d3dF83a07892F912a71927F4740B8e0e04ab";
  const pangoroEndpointAddress = "0x23E31167E3D46D64327fdd6e783FE5391427B728";

  ////////////////////////////////////
  // Setup msgports
  ////////////////////////////////////
  hre.changeNetwork("pangolin");
  console.log("Setting up pangolin msgport...");
  let DefaultMsgport = await hre.ethers.getContractFactory("DefaultMsgport");
  const pangolinChainId = 0;
  let pangolinMsgport = await DefaultMsgport.deploy(pangolinChainId);
  await pangolinMsgport.deployed();
  const pangolinMsgportAddress = pangolinMsgport.address;
  console.log(`  pangolinMsgport: ${pangolinMsgportAddress}`);

  hre.changeNetwork("pangoro");
  console.log("Setting up pangoro msgport...");
  DefaultMsgport = await hre.ethers.getContractFactory("DefaultMsgport");
  const pangoroChainId = 1;
  let pangoroMsgport = await DefaultMsgport.deploy(pangoroChainId);
  await pangoroMsgport.deployed();
  const pangoroMsgportAddress = pangoroMsgport.address;
  console.log(`  pangoroMsgport: ${pangoroMsgportAddress}`);

  ////////////////////////////////////
  // Setup endpoints
  ////////////////////////////////////
  console.log("Setting up pangolin endpoint...");
  const S2sPangolinEndpoint = await hre.ethers.getContractFactory(
    "DarwiniaS2sEndpoint"
  );
  const s2sPangolinAdapter = await S2sPangolinAdapter.deploy(
    pangolinEndpointAddress
  );
  await s2sPangolinAdapter.deployed();
  const s2sPangolinAdapterAddress = s2sPangolinAdapter.address;
  console.log(`  s2sPangolinAdapter: ${s2sPangolinAdapterAddress}`);

  hre.changeNetwork("pangoro");
  const S2sPangoroAdapter = await hre.ethers.getContractFactory(
    "DarwiniaS2sAdapter"
  );
  const s2sPangoroAdapter = await S2sPangoroAdapter.deploy(
    pangoroEndpointAddress
  );
  await s2sPangoroAdapter.deployed();
  console.log(`  s2sPangoroAdapter: ${s2sPangoroAdapter.address}`);

  // CONNECT TO EACH OTHER
  await s2sPangoroAdapter.setRemoteChannelAddress(s2sPangolinAdapter.address);
  hre.changeNetwork("pangolin");
  await s2sPangolinAdapter.setRemoteChannelAddress(s2sPangoroAdapter.address);

  ////////////////////////////////////
  // Add channel to msgport
  ////////////////////////////////////
  console.log("Add pangolin channel to pangolin msgport...");
  DefaultMsgport = await hre.ethers.getContractFactory("DefaultMsgport");
  pangolinMsgport = await DefaultMsgport.attach(pangolinMsgportAddress);

  const adapterId = 3; // IMPORTANT!!! This needs to be +1 if the channel is changed.
  const tx = await pangolinMsgport.setAdapterAddress(
    adapterId,
    s2sPangolinAdapterAddress
  );
  console.log(
    `  pangolinMsgport.setAdapterAddress tx: ${
      (await tx.wait()).transactionHash
    }`
  );

  ////////////////////////////////////
  // Dapp
  ////////////////////////////////////
  console.log("Setting up dapp...");
  // s2s Pangolin Dapp
  let S2sPangolinDapp = await hre.ethers.getContractFactory("S2sPangolinDapp");
  let s2sPangolinDapp = await S2sPangolinDapp.deploy(pangolinMsgportAddress);
  await s2sPangolinDapp.deployed();
  const pangolinDappAddress = s2sPangolinDapp.address;
  console.log(`  s2sPangolinDapp: ${pangolinDappAddress}`);

  // s2s Pangoro Dapp
  hre.changeNetwork("pangoro");
  const S2sPangoroDapp = await hre.ethers.getContractFactory("S2sPangoroDapp");
  const s2sPangoroDapp = await S2sPangoroDapp.deploy();
  await s2sPangoroDapp.deployed();
  const pangoroDappAddress = s2sPangoroDapp.address;
  console.log(`  s2sPangoroDapp: ${pangoroDappAddress}`);

  ////////////////////////////////////
  // Run
  ////////////////////////////////////
  console.log("Run...");
  hre.changeNetwork("pangolin");
  S2sPangolinDapp = await hre.ethers.getContractFactory("S2sPangolinDapp");
  s2sPangolinDapp = S2sPangolinDapp.attach(pangolinDappAddress);
  const fee = await estimateFee(s2sPangolinDapp, adapterId);
  console.log(`  Market fee: ${fee} wei`);

  // Run
  const tx2 = await s2sPangolinDapp.remoteAdd(adapterId, pangoroDappAddress, {
    value: fee,
  });
  console.log(`  tx: ${(await tx2.wait()).transactionHash}`);
}

async function estimateFee(pangolinDapp, adapterId) {
  const msgportAddress = await pangolinDapp.msgportAddress();
  const DefaultMsgport = await hre.ethers.getContractFactory("DefaultMsgport");
  const msgport = DefaultMsgport.attach(msgportAddress);

  const msgportAddress = await msgport.msgportAddresses(adapterId);
  const DarwiniaS2sAdapter = await hre.ethers.getContractFactory(
    "DarwiniaS2sAdapter"
  );
  const channel = DarwiniaS2sAdapter.attach(msgportAddress);
  return await channel.estimateFee();
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
