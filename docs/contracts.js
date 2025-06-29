


export const CONTRACTS = {
  BUSD: {
    addr: {
      sepolia: '0x87BEc860d6297108481E4Dedf3D8D64133842C5d',
      mainnet: ''
    },
    abi: [
      'function totalSupply() external view returns (uint256)'
    ]
  },

  ProofOfBurn: {
    addr: {
      sepolia: '0x5a581C9A2Cf3d07BDBA0bA09e1168f5bc95Ad060',
      mainnet: ''
    },
    abi: [
      'function totalSupply() external view returns (uint256)'
    ]
  },

  BurnCeremony: {
    addr: {
      sepolia: '0xae900709887e5A895f5Ee9384D6765457229c6f9',
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
      sepolia: '0x89E65a1b37c1F82542A7c3C7cb73bE3e7b29063e',
      mainnet: ''
    },
    abi: [
      'function agreementUsed(uint256 tokenId) external view returns (bool)',
      'function exists(uint256 tokenId) external view returns (bool)',
      'function ownerOf(uint256 tokenId) external view returns (address)',
    ]
  },

}

