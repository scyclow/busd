


export const CONTRACTS = {
  BUSD: {
    addr: {
      sepolia: '0xF530235506346C98B2102b24c0187D4120Bcb558',
      mainnet: ''
    },
    abi: [
      'function totalSupply() external view returns (uint256)'
    ]
  },

  ProofOfBurn: {
    addr: {
      sepolia: '0xC6fc7F5F4422E23e6ef7BFffCDFC51C6Afa1d871',
      mainnet: ''
    },
    abi: [
      'function totalSupply() external view returns (uint256)',
      'function billsBurned() external view returns (uint256)',
      'function markSessionEnd() external',
      'function totalSessions() external view returns (uint256)',
      'function addProof(uint256 tokenId, string proof) external',
      'function addProofBatch(uint256[] tokenIds, string baseURI, string ext)',
      'function tokenURI(uint256 tokenId) external view returns (string) ',
      'function ownerOf(uint256 tokenId) external view returns (address) ',
    ]
  },

  BurnCeremony: {
    addr: {
      sepolia: '0x9e0d24437C7A436f17C33b8F8BB6575854121c86',
      mainnet: ''
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
      mainnet: ''
    },
    abi: [
      'function agreementUsed(uint256 tokenId) external view returns (bool)',
      'function exists(uint256 tokenId) external view returns (bool)',
      'function ownerOf(uint256 tokenId) external view returns (address)',
    ]
  },

}

