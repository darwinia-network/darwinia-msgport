export type IEstimateFee = (
  fromChainId: number,
  fromDappAddress: string,
  toChainId: number,
  toDappAddress: string,
  messagePayload: string,
  feeMultiplier: number
) => Promise<number>;
