import { AsyncResult, Err, Fetcher, Ok } from '@catalogfi/utils';
import { Chain } from '@shanmukh0504/orderbook';
import { Environment, Url } from '@shanmukh0504/utils';

type Response = {
  [key in Chain]: number;
};

export interface IBlockNumberFetcher {
  fetchBlockNumbers(): AsyncResult<Response, string>;
}

export class BlockNumberFetcher implements IBlockNumberFetcher {
  private url: Url;

  constructor(url: string, network: Environment) {
    this.url = new Url(url).endpoint('blocknumbers').endpoint(network);
  }

  async fetchBlockNumbers(): AsyncResult<Response, string> {
    try {
      const res = await Fetcher.get<Response>(this.url);
      return Ok(res);
    } catch (error) {
      return Err('Failed to fetch block numbers', error);
    }
  }
}
