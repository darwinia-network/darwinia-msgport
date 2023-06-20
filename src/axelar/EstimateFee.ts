import { IEstimateFee } from "../interfaces/IEstimateFee";
import { PublicClient, getContract } from "viem";
import { decodeAbiParameters, parseAbiParameters } from "viem";
import {
  Environment,
  AxelarQueryAPI,
  EvmChain,
  GasToken,
} from "@axelar-network/axelarjs-sdk";
import AxelarDockContract from "../../artifacts/contracts/docks/AxelarDock.sol/AxelarDock.json";

const axelarNativeTokens: { [chainName: string]: string } = {};
axelarNativeTokens[EvmChain.ETHEREUM] = GasToken.ETH;
axelarNativeTokens[EvmChain.BNBCHAIN] = GasToken.BINANCE;
axelarNativeTokens[EvmChain.FANTOM] = GasToken.FTM;

async function buildEstimateFeeFunction(
  provider: PublicClient,
  senderDockAddress: string,
  environment: Environment
) {
  const sdk = new AxelarQueryAPI({
    environment: environment,
  });

  // dock
  const dock = getContract({
    address: senderDockAddress as `0x${string}`,
    abi: AxelarDockContract.abi,
    publicClient: provider,
  });

  const estimateFee: IEstimateFee = async (
    fromChainId,
    _fromDappAddress,
    toChainId,
    _toDappAddress,
    _messagePayload,
    feeMultiplier,
    params
  ) => {
    console.log(`fromChainId: ${fromChainId}, toChainId: ${toChainId}`);
    const axelarSrcChainName = await dock.read.chainIdDown([fromChainId]);
    const axelarDstChainName = await dock.read.chainIdDown([toChainId]);
    console.log(
      `axelarSrcChainName: ${axelarSrcChainName}, axelarDstChainName: ${axelarDstChainName}`
    );

    const gasLimit = decodeAbiParameters(
      parseAbiParameters("uint256"),
      params as `0x${string}`
    )[0];
    console.log(`gasLimit: ${gasLimit}`);
    // convert gasLimit to number
    // const gasLimitNumber = parseInt(gasLimit);

    const axelarSrcGasToken = axelarNativeTokens[axelarSrcChainName as string];

    return BigInt(
      (await sdk.estimateGasFee(
        axelarSrcChainName as string,
        axelarDstChainName as string,
        axelarSrcGasToken,
        Number(gasLimit),
        feeMultiplier,
        "2025000000"
      )) as string
    );
  };

  return estimateFee;
}

export { buildEstimateFeeFunction, Environment };
