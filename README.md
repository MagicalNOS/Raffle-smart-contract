# Raffle Smart Contract Project

A decentralized raffle system built with Solidity and Foundry, leveraging Chainlink VRF (Verifiable Random Function) for provably fair randomness and Chainlink Automation for automated raffle execution.

## Features

- **Provably Fair Randomness**: Uses Chainlink VRF to ensure tamper-proof random number generation
- **Automated Execution**: Leverages Chainlink Automation for trustless raffle draws
- **Multi-Network Support**: Deployable on localhost (Anvil) and Sepolia testnet
- **Comprehensive Testing**: Full test suite with Foundry framework

## Etherscan-Example
 
https://sepolia.etherscan.io/address/0x710eaa17c9c3434e998755d89f15a48815ec7efa#code

## Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation.html)
- [Git](https://git-scm.com/)

## Installation

Clone the repository and install dependencies:

```bash
git clone <repository-url>
cd raffle-project
make install
```

This will install the following dependencies:
- `cyfrin/foundry-devops@0.2.2` - Development operations utilities
- `smartcontractkit/chainlink-brownie-contracts@1.1.1` - Chainlink contract interfaces
- `foundry-rs/forge-std@v1.8.2` - Foundry standard library
- `transmissions11/solmate@v6` - Gas-optimized contract primitives

## Environment Setup

Create a `.env` file in the project root with the following variables:

```env
SEPOLIA_RPC_URL=your_sepolia_rpc_url
SEPOLIA_PRIVATE_KEY=your_private_key
ETHERSCAN_API_KEY=your_etherscan_api_key
```

**⚠️ Security Note**: Never commit your `.env` file or expose private keys. The `.env` file is included in `.gitignore`.

## Usage

### Local Development

Start a local Ethereum node with Anvil:

```bash
make anvil
```

This starts Anvil with:
- Mnemonic: `test test test test test test test test test test test junk`
- Step tracing enabled
- 1-second block time
- Default private key: `0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80`

### Building and Testing

```bash
# Clean the project
make clean

# Build contracts
make build

# Run tests
make test

# Generate gas snapshots
make snapshot

# Format code
make format
```

### Deployment

#### Deploy to Local Network (Anvil)

```bash
make deploy
```

#### Deploy to Sepolia Testnet

```bash
make deploy ARGS="--network sepolia"
```

### Chainlink Integration

The project includes scripts for Chainlink VRF and Automation setup:

#### Create VRF Subscription

```bash
# Local
make createSubscription

# Sepolia
make createSubscription ARGS="--network sepolia"
```

#### Add Consumer Contract

```bash
# Local  
make addConsumer

# Sepolia
make addConsumer ARGS="--network sepolia"
```

#### Fund VRF Subscription

```bash
# Local
make fundSubscription  

# Sepolia
make fundSubscription ARGS="--network sepolia"
```

## Project Structure

```
├── src/                    # Smart contracts source code
├── script/                 # Deployment and interaction scripts
│   ├── DeployRaffle.s.sol # Main deployment script
│   └── Interactions.s.sol  # Chainlink interaction scripts
├── test/                   # Test files
├── lib/                    # Dependencies (managed by Foundry)
├── .env                    # Environment variables (create this)
├── .gitignore             # Git ignore rules
├── foundry.toml           # Foundry configuration
├── Makefile              # Build automation
└── README.md             # This file
```

## Smart Contract Architecture

### Raffle Contract
The main raffle contract implements:
- Entry fee collection
- Player registration
- Integration with Chainlink VRF for random winner selection
- Integration with Chainlink Automation for periodic draws
- Prize distribution

### Chainlink Integration
- **VRF (Verifiable Random Function)**: Provides cryptographically secure randomness
- **Automation**: Enables trustless execution of raffle draws based on time intervals

## Testing

The project includes comprehensive tests covering:
- Contract deployment
- Raffle entry mechanics
- Chainlink VRF integration
- Automation functionality
- Edge cases and error handling

Run tests with different verbosity levels:

```bash
forge test                    # Standard output
forge test -v                 # Verbose
forge test -vv                # More verbose
forge test -vvv               # Very verbose
forge test -vvvv              # Maximum verbosity
```

## Gas Optimization

Gas snapshots help track gas usage:

```bash
make snapshot
```

This generates a `.gas-snapshot` file showing gas costs for each function.

## Network Configuration

### Local Development (Anvil)
- RPC URL: `http://localhost:8545`
- Chain ID: 31337
- Default funded accounts available

### Sepolia Testnet
- Requires SEPOLIA_RPC_URL in `.env`
- Requires testnet ETH for deployment
- Contracts are verified on Etherscan automatically

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Run the test suite
6. Submit a pull request

## Security Considerations

- All randomness is generated using Chainlink VRF
- Contracts are designed to be non-upgradeable for transparency
- Comprehensive testing covers edge cases
- Consider professional audit before mainnet deployment

## License

[MIT](LICENSE)

## Support

For questions about Chainlink integration:
- [Chainlink Documentation](https://docs.chain.link/)
- [Chainlink Discord](https://discord.gg/chainlink)

For Foundry-related questions:
- [Foundry Book](https://book.getfoundry.sh/)
- [Foundry GitHub](https://github.com/foundry-rs/foundry)

---

Built with ❤️ using Foundry and Chainlink
