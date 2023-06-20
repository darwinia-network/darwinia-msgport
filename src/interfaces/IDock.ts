export type IDock = {
  address: string;

  getLocalChainId: () => Promise<number>;

  getOutboundLane: (remoteChainId: number) => Promise<any>;

  getRemoteDockAddress: (remoteChainId: number) => Promise<string>;

  estimateFee: (
    remoteChainId: number,
    messagePayload: string,
    feeMultiplier: number,
    params: string
  ) => Promise<BigInt>;
};
