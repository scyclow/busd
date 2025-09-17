


export const CONTRACTS = {
  BUSD: {
    addr: {
      sepolia: '0xF530235506346C98B2102b24c0187D4120Bcb558',
      mainnet: '0xb9bdb5221585ad31ba3a4fa9c7a7b73a0495916e'
    },
    abi: [
      'function totalSupply() external view returns (uint256)'
    ]
  },

  ProofOfBurn: {
    addr: {
      sepolia: '0xC6fc7F5F4422E23e6ef7BFffCDFC51C6Afa1d871',
      mainnet: '0x46b2Fc11FD3209D42CB0971AE2C824f1814F1245'
    },
    abi: [
      'function totalSupply() external view returns (uint256)',
      'function billsBurned() external view returns (uint256)',
      'function markSessionEnd() external',
      'function totalSessions() external view returns (uint256)',
      'function addMemo(uint256 tokenId, string memo) external',
      'function addProof(uint256 tokenId, string proof) external',
      'function addProofBatch(uint256[] tokenIds, string baseURI, string ext)',
      'function tokenURI(uint256 tokenId) external view returns (string) ',
      'function ownerOf(uint256 tokenId) external view returns (address) ',
    ]
  },

  BurnCeremony: {
    addr: {
      sepolia: '0x9e0d24437C7A436f17C33b8F8BB6575854121c86',
      mainnet: '0x0400B4D05090FB3DA2d6857280ab7e7648BC544c'
    },
    abi: [
      'function burnAgent() public view returns (address)',
      'function issue(address account, uint256 denomination, string serial) external',
      'function issueWithAgreement(uint256 agreementTokenId, uint256 denomination, string serial) external',
    ]
  },

  BurnAgreement: {
    addr: {
      sepolia: '0x31766DEDb986E3d69640Ddc8106D4130D725E69F',
      mainnet: '0xA537Efd05d57AEb529f3b90517CCAc099a392729'
    },
    abi: [
      'function agreementUsed(uint256 tokenId) external view returns (bool)',
      'function exists(uint256 tokenId) external view returns (bool)',
      'function ownerOf(uint256 tokenId) external view returns (address)',
    ]
  },

  BurnAgreementMinter: {
    addr: {
      mainnet: '0xc4ef253a7147Fcc3322165D014cc8053870F4090'
    },
    abi: [
      'function mint() external payable',
    ]
  },

  UniswapV4StateView: {
    addr: {
      mainnet: '0x7ffe42c4a5deea5b0fec41c94c136cf115597227'
    },
    abi: [
      'function getSlot0(bytes32 poolId) external view returns (uint160 sqrtPriceX96, int24 tick, uint24 protocolFee, uint24 lpFee)',
    ]
  },

}

