import { GardenProvider } from '@shanmukh0504/react-hooks';
import { Environment } from '@shanmukh0504/utils';
import { useWalletClient } from 'wagmi';
import { Swap } from './components/Swap';

function App() {
  const { data: walletClient } = useWalletClient();
  console.log('walletClient :', walletClient);

  return (
    <GardenProvider
      config={{
        store: localStorage,
        environment: Environment.TESTNET,
        walletClient: walletClient,
      }}
    >
      <Swap />
    </GardenProvider>
  );
}

export default App;
