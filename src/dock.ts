import { PublicClient, getContract } from "viem";
import { IEstimateFee } from "./interfaces/IEstimateFee";
import { layerzero } from "./layerzero/index";
import { axelar } from "./axelar/index";
import BaseMessageDockContract from "../artifacts/contracts/docks/base/BaseMessageDock.sol/BaseMessageDock.json";
import { IDock } from "./interfaces/IDock";

enum DockType {
  Axelar = 0,
  AxelarTestnet = 1,
  Celer = 2,
  Darwinia = 3,
  DarwiniaS2S = 4,
  DarwiniaXcmp = 5,
  LayerZero = 6,
}

async function getDock(
  provider: PublicClient,
  dockAddress: string,
  dockType: DockType
) {
  const dock = getContract({
    address: dockAddress as `0x${string}`,
    abi: BaseMessageDockContract.abi,
    publicClient: provider,
  });

  let estimateFee: IEstimateFee = await buildEstimateFunction(
    provider,
    dockType,
    dockAddress
  );

  const result: IDock = {
    address: dockAddress,

    getLocalChainId: async () => {
      return (await dock.read.getLocalChainId()) as number;
    },

    getOutboundLane: async (remoteChainId: number) => {
      const outboundLane = (await dock.read.outboundLanes([remoteChainId])) as [
        number,
        string,
        number
      ];

      return {
        fromChainId: await result.getLocalChainId(),
        fromDockAddress: dockAddress,
        toChainId: outboundLane[0],
        toDockAddress: outboundLane[1],
        nonce: outboundLane[2],
      };
    },

    getRemoteDockAddress: async (remoteChainId: number) => {
      const lane = (await dock.read.outboundLanes([remoteChainId])) as [
        number,
        string,
        number
      ];
      return lane[1];
    },

    estimateFee: async (
      remoteChainId: number,
      messagePayload: string,
      feeMultiplier: number,
      params
    ) => {
      const remoteDockAddress = await result.getRemoteDockAddress(
        remoteChainId
      );
      console.log(`remoteDockAddress: ${remoteDockAddress}`);
      return await estimateFee(
        (await dock.read.getLocalChainId()) as number,
        dockAddress,
        remoteChainId,
        remoteDockAddress,
        messagePayload,
        feeMultiplier,
        params
      );
    },
  };

  return result;
}

async function buildEstimateFunction(
  provider: PublicClient,
  dockType: DockType,
  dockAddress: string
) {
  let estimateFee: IEstimateFee;
  if (dockType == DockType.LayerZero) {
    estimateFee = await layerzero.buildEstimateFeeFunction(
      provider,
      dockAddress
    );
  } else if (dockType == DockType.Axelar) {
    estimateFee = await axelar.buildEstimateFeeFunction(
      provider,
      dockAddress,
      axelar.Environment.MAINNET
    );
  } else if (dockType == DockType.AxelarTestnet) {
    estimateFee = await axelar.buildEstimateFeeFunction(
      provider,
      dockAddress,
      axelar.Environment.TESTNET
    );
  } else {
    throw new Error("Unsupported dock type");
  }
  return estimateFee;
}

export { getDock, DockType };
