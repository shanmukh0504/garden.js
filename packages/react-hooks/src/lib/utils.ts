import { Asset } from '@shanmukh0504/orderbook';

export const constructOrderpair = (fromAsset: Asset, toAsset: Asset) =>
  `${fromAsset.chain}:${fromAsset.atomicSwapAddress}::${toAsset.chain}:${toAsset.atomicSwapAddress}`;

export const hasAnyValidValue = (obj: Record<string, any>) => {
  return Object.values(obj).some((value) => value !== undefined);
};
