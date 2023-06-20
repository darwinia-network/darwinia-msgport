import { getDock, DockType } from "../dock";

import { createPublicClient, http } from "viem";
import { bscTestnet } from "viem/chains";

async function main(): Promise<void> {
  const publicClient = createPublicClient({
    chain: bscTestnet,
    transport: http("https://bsc-testnet.publicnode.com​"),
  });

  const dock = await getDock(
    publicClient,
    "0x0C9549C21313cEdEb794816c534Dc71B0D94A21b",
    DockType.LayerZero
  );

  const dockAddress = dock.address;
  console.log(`dockAddress: ${dockAddress}`);

  const localChainId = await dock.getLocalChainId();
  console.log(`localChainId: ${localChainId}`);

  const outboundLane = await dock.getOutboundLane(80001);
  console.log(`outboundLane: `);
  console.log(` fromChainId: ${outboundLane.fromChainId}`);
  console.log(` fromDockAddress: ${outboundLane.fromDockAddress}`);
  console.log(` toChainId: ${outboundLane.toChainId}`);
  console.log(` toDockAddress: ${outboundLane.toDockAddress}`);
  console.log(` nonce: ${outboundLane.nonce}`);

  const remoteDockAddress = await dock.getRemoteDockAddress(80001);
  console.log(`remoteDockAddress: ${remoteDockAddress}`);

  const estimateFee = await dock.estimateFee(80001, "0x12345678", 1.1, "0x");
  console.log(`estimateFee: ${estimateFee}`);
}
main();
