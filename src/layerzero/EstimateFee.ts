import { IEstimateFee } from "../interfaces/IEstimateFee";
import { PublicClient, getContract } from "viem";
import { encodeAbiParameters, parseAbiParameters } from "viem";
import LayerZeroDockContract from "../../artifacts/contracts/docks/LayerZeroDock.sol/LayerZeroDock.json";
import ILayerZeroEndpoint from "@layerzerolabs/solidity-examples/artifacts/contracts/interfaces/ILayerZeroEndpoint.sol/ILayerZeroEndpoint.json";
import Decimal from "decimal.js";

async function buildEstimateFeeFunction(
  provider: PublicClient,
  senderDockAddress: string
) {
  // dock
  const senderDock = getContract({
    address: senderDockAddress as `0x${string}`,
    abi: LayerZeroDockContract.abi,
    publicClient: provider,
  });
  const lzEndpointAddress = await senderDock.read.lzEndpointAddress();

  // lzEndpoint
  const lzEndpoint = getContract({
    address: lzEndpointAddress as `0x${string}`,
    abi: ILayerZeroEndpoint.abi,
    publicClient: provider,
  });

  // estimateFee function
  const estimateFee: IEstimateFee = async (
    fromChainId: number,
    fromDappAddress: string,
    toChainId: number,
    toDappAddress: string,
    messagePayload: string,
    feeMultiplier,
    params
  ) => {
    console.log(`fromChainId: ${fromChainId}, toChainId: ${toChainId}`);
    const lzSrcChainId = await senderDock.read.chainIdDown([fromChainId]);
    const lzDstChainId = await senderDock.read.chainIdDown([toChainId]);
    console.log(`lzSrcChainId: ${lzSrcChainId}, lzDstChainId: ${lzDstChainId}`);

    const payload = encodeAbiParameters(
      parseAbiParameters("address, address, address, bytes"),
      [
        senderDockAddress as `0x${string}`,
        fromDappAddress as `0x${string}`,
        toDappAddress as `0x${string}`,
        messagePayload as `0x${string}`,
      ]
    );

    console.log(`params: ${params}`);
    const decimalfeeMultiplier: Decimal = new Decimal(feeMultiplier);

    const result = (await lzEndpoint.read.estimateFees([
      lzDstChainId,
      senderDockAddress,
      payload,
      false,
      params,
    ])) as [bigint, bigint];
    const d: Decimal = decimalfeeMultiplier.times(result[0].toString());

    return BigInt(d.toFixed(0));
  };

  return estimateFee;
}

export { buildEstimateFeeFunction };
