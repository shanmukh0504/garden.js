[![NPM Version](https://img.shields.io/npm/v/%40shanmukh0504%2Fcore?style=for-the-badge&logo=npm&label=core&color=B1D8B7)](https://www.npmjs.com/package/@shanmukh0504/core) [![NPM Version](https://img.shields.io/npm/v/%40shanmukh0504%2Forderbook?style=for-the-badge&logo=npm&label=orderbook&color=B1D8B7)](https://www.npmjs.com/package/@shanmukh0504/orderbook)

# Garden SDK

The Garden SDK is a set of typescript packages that allow you to bridge Bitcoin to EVM-based chains. It is an abstraction over the Garden APIs, allowing developers to easily integrate Garden components into their dApps.

## Packages

- [@shanmukh0504/orderbook](./packages/orderbook/README.md): Allows you to create orders and listen to them.
- [@shanmukh0504/core](./packages/core/README.md): Allows you to interact with orders once you setup your wallets.

## Docs

Check out our [docs](https://docs.garden.finance/developers/sdk) to learn more about Garden and how to build on it. 

## Contributing

### Setup

This project uses yarn workspaces. Run `yarn` in the directory to install all dependencies.

To build a package, use:

```bash
yarn workspace @shanmukh0504/<package_name> build
```

To run the development server while building all packages as you develop, use:

```bash
yarn dev
```

To run the development server for the documentation, use:

```bash
yarn start:docs
```
