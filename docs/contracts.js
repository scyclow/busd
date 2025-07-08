


export const CONTRACTS = {
  BUSD: {
    addr: {
      sepolia: '0x91032e4DD917c5850907A3f134E07E0ec7CAD04D',
      mainnet: ''
    },
    abi: [
      'function totalSupply() external view returns (uint256)'
    ]
  },

  ProofOfBurn: {
    addr: {
      sepolia: '0x6b8dCA99bc84F6b6Ab27064BA5d72F8Ef4ca963E',
      mainnet: ''
    },
    abi: [
      'function totalSupply() external view returns (uint256)',
      'function markSessionEnd() external',
      'function totalSessions() external view returns (uint256)',
    ]
  },

  BurnCeremony: {
    addr: {
      sepolia: '0x73c15E8C45C9E1eEE273e6604b44f37453EaCD62',
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
      sepolia: '0x85e4fCAca45BA56F423834F6610d61eAc507eae6',
      mainnet: ''
    },
    abi: [
      'function agreementUsed(uint256 tokenId) external view returns (bool)',
      'function exists(uint256 tokenId) external view returns (bool)',
      'function ownerOf(uint256 tokenId) external view returns (address)',
    ]
  },

}

