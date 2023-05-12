const { deployDock, setRemoteDock } = require("../helper");

async function main() {
  const senderChain = "pangolin";
  const senderMsgportAddress = "0x3f1394274103cdc5ca842aeeC9118c512dea9A4F"; // <---- This is the sender msgport address from 1-setup-msgports.js
  const senderDockName = "DarwiniaS2sDock";
  const senderDockParams = [
    "0xE8C0d3dF83a07892F912a71927F4740B8e0e04ab", // sender endpoint address
  ];

  const receiverChain = "pangoro";
  const receiverMsgportAddress = "0xE7fb517F60dA00e210A43Bdf23f011c3fa508Da7"; // <---- This is the receiver msgport address from 1-setup-msgports.js
  const receiverDockName = "DarwiniaS2sDock";
  const receiverDockParams = [
    "0x23E31167E3D46D64327fdd6e783FE5391427B728", // receiver endpoint address
  ];

  await setupDocks(
    senderChain,
    senderMsgportAddress,
    senderDockName,
    senderDockParams,
    receiverChain,
    receiverMsgportAddress,
    receiverDockName,
    receiverDockParams
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
