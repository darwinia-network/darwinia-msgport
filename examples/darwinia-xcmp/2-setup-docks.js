const { setupDocks } = require("../helper");

async function main() {
  const senderChain = "pangoro";
  const senderMsgportAddress = "0xE7fb517F60dA00e210A43Bdf23f011c3fa508Da7"; // <---- This is the sender msgport address from 1-setup-msgports.js
  const senderDockName = "DarwiniaXcmpDock";
  const senderDockParams = [
    "0xe520", // srcParaId
    "0xa10f", // tgtParaId
    "0x2100", // srcPolkadotXcmSendCallIndex
  ];

  const receiverChain = "moonbase";
  const receiverMsgportAddress = "0x3f1394274103cdc5ca842aeeC9118c512dea9A4F"; // <---- This is the receiver msgport address from 1-setup-msgports.js
  const receiverDockName = "DarwiniaXcmpDock";
  const receiverDockParams = [
    "0xa10f", // srcParaId
    "0xe520", // tgtParaId
    "0x1c03", // tgtPolkadotXcmSendCallIndex
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