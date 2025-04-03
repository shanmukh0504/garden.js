import { WBTCArbitrumLocalnetAsset } from "@shanmukh0504/orderbook";

import { WBTCEthereumLocalnetAsset } from "@shanmukh0504/orderbook";

import { bitcoinRegtestAsset } from "@shanmukh0504/orderbook";

export enum IOType {
  input = "input",
  output = "output",
}


export const chainToAsset = {
  ethereum_localnet: WBTCEthereumLocalnetAsset,
  arbitrum_localnet: WBTCArbitrumLocalnetAsset,
  bitcoin_regtest: bitcoinRegtestAsset,
};