import { PublicClient, WalletClient, getContract, parseUnits } from "viem";
import { getDock, DockType } from "./dock";
import DefaultMsgportContract from "../artifacts/contracts/MessagePort.sol/MessagePort.json";
import { IDockSelectionStrategy } from "./interfaces/IDockSelectionStrategy";
import { dockTypeRegistry } from "./dockTypeRegistry";
import { IMsgport } from "./interfaces/IMsgport";
import { ChainId } from "./chain-ids";

export { DockType };

export async function getMsgport(
  publicClient: PublicClient,
  walletClient: WalletClient,
  msgportAddress: string
) {
  const msgport = getContract({
    address: msgportAddress as `0x${string}`,
    abi: DefaultMsgportContract.abi,
    publicClient: publicClient,
  });

  const result: IMsgport = {
    getLocalChainId: async () => {
      return (await msgport.read.getLocalChainId()) as number;
    },

    getLocalDockAddress: async (
      toChainId: ChainId,
      selectDock: IDockSelectionStrategy
    ) => {
      const localDockAddresses =
        (await msgport.read.getLocalDockAddressesByToChainId([
          toChainId,
        ])) as string[];
      return await selectDock(localDockAddresses);
    },

    getDock: async (toChainId: ChainId, selectDock: IDockSelectionStrategy) => {
      const localDockAddress = await result.getLocalDockAddress(
        toChainId,
        selectDock
      );

      const dockType = dockTypeRegistry[localDockAddress];
      console.log(
        `localDockAddress: ${localDockAddress}, dockType: ${dockType}`
      );
      return await getDock(publicClient, localDockAddress, dockType);
    },

    getLocalDockAddressesByToChainId: async (toChainId: ChainId) => {
      console.log(`toChainId: ${toChainId}`);
      return (await msgport.read.getLocalDockAddressesByToChainId([
        toChainId,
      ])) as string[];
    },

    estimateFee: async (
      toChainId: ChainId,
      selectDock: IDockSelectionStrategy,
      messagePayload: string,
      feeMultiplier: number = 1.1,
      params = "0x"
    ) => {
      const localDock = await result.getDock(toChainId, selectDock);
      return await localDock.estimateFee(
        toChainId,
        messagePayload,
        feeMultiplier,
        params
      );
    },

    send: async (
      toChainId: ChainId,
      selectDock: IDockSelectionStrategy,
      toDappAddress: string,
      messagePayload: string,
      feeMultiplier: number = 1.1,
      params: string = "0x"
    ) => {
      // Get local dock
      const localDock = await result.getDock(toChainId, selectDock);

      // Estimate fee through dock
      const fee = await localDock.estimateFee(
        toChainId,
        messagePayload,
        feeMultiplier,
        params
      );
      console.log(`fee: ${fee.valueOf()}`);

      // Send message through msgport
      const { request } = await publicClient.simulateContract({
        address: msgportAddress as `0x${string}`,
        account: walletClient.account,
        abi: DefaultMsgportContract.abi,
        functionName: "send",
        args: [
          localDock.address,
          toChainId,
          toDappAddress,
          messagePayload,
          params,
        ],
        value: fee.valueOf(),
      });
      const txHash = await walletClient.writeContract(request);
      console.log(`txHash: ${txHash}`);

      console.log(
        `message "${messagePayload}" has been sent to ${toDappAddress} through msgport ${msgportAddress}`
      );

      return txHash;
    },
  };

  return result;
}
