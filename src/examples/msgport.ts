import { getMsgport } from "../msgport";

import { createPublicClient, createWalletClient, http } from "viem";
import { encodePacked } from "viem";
import { bscTestnet } from "viem/chains";
import { privateKeyToAccount } from "viem/accounts";

import "dotenv/config";
async function main(): Promise<void> {
  const publicClient = createPublicClient({
    chain: bscTestnet,
    transport: http("https://bsc-testnet.publicnode.com​"),
  });

  const account = privateKeyToAccount(
    `0x${process.env.PRIVATE_KEY}` as `0x${string}`
  );
  const walletClient = createWalletClient({
    account: account,
    chain: bscTestnet,
    transport: http("https://bsc-testnet.publicnode.com​"),
  });

  const msgport = await getMsgport(
    publicClient,
    walletClient,
    "0xeF1c60AB9B902c13585411dC929005B98Ca44541"
  );

  const params = encodePacked(["uint16", "uint256"], [1, BigInt(300000)]);

  const tx = await msgport.send(
    80001,
    async (_) => "0x0C9549C21313cEdEb794816c534Dc71B0D94A21b",
    "0xe13084f8fF65B755E37d95F49edbD49ca26feE13",
    "0x12345678",
    1.1,
    params
  );
  console.log(tx);
}

main();
