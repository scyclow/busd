// SPDX-License-Identifier: MIT

/*
              (    (
   (          )\ ) )\ )
 ( )\     (  (()/((()/(
 )((_)    )\  /(_))/(_))
((_)_  _ ((_)(_)) (_))_
 | _ )| | | |/ __| |   \
 | _ \| |_| |\__ \ | |) |
 |___/ \___/ |___/ |___/


by steviep.eth
2025

*/



import "./Dependencies.sol";
import "./BurnCeremony.sol";
import "./ProofOfBurn.sol";


pragma solidity ^0.8.28;

interface IBurnAgreement {
  function ownerOf(uint256) external view returns (address);
  function markAgreementUsed(uint256) external;
}



/// @title Burnt US Dollars (bUSD)
/// @author steviep.eth
/// @notice Burnt US Dollars ($bUSD) is a coin that represents the value of burned US Dollars.
contract BUSD is ERC20, Ownable {
  BurnCeremony public ceremony;
  ProofOfBurn public proofOfBurn;

  /// @notice BUSD can no longer be issued once the contract is locked
  bool public isLocked;

  /// @notice Keeps track of which addresses burned the most bUSD
  mapping(address => uint256) public busdBurnedBy;

  constructor() ERC20('Burnt US Dollars', 'bUSD') {
    ceremony = new BurnCeremony();
    proofOfBurn = new ProofOfBurn();

    ceremony.init(owner(), proofOfBurn);
  }

  /// @notice Issue new bUSD
  /// @param account Address to issue bUSD to
  /// @param amount Amount of bUSD to issue
  /// @dev This can only be called by the BurnCeremony address
  function issue(address account, uint256 amount) external {
    require(!isLocked, 'New issuance is locked');
    require(msg.sender == address(ceremony), 'Can only issue through official Burn Ceremony');
    _mint(account, amount);
  }

  /// @notice Burn bUSD along with a Proof of Burn token
  /// @param account Address to burn bUSD from
  /// @param amount Amount of bUSD to burn
  /// @dev This can only be called by the ProofOfBurn contract
  function burnFrom(address account, uint256 amount) external {
    require(msg.sender == address(proofOfBurn));

    busdBurnedBy[account] += amount;
    _burn(account, amount);
  }

  /// @notice Change the BurnCeremony contract
  /// @param newCeremony New BurnCeremony contract address
  function modifyCeremony(address newCeremony) external onlyOwner {
    ceremony = BurnCeremony(newCeremony);
  }


  /// @notice Lock new bUSD issuance
  /// @dev This is one way. Issuance cnanot be unlocked
  function lockIssuance() external onlyOwner {
    isLocked = true;
  }

  string private _contractURI = 'data:application/json;utf8,{"name":"Burnt US Dollars"}';
  event ContractURIUpdated();

  function contractURI() external view returns (string memory) {
    return _contractURI;
  }

  function updateContractURI(string calldata newURI) external onlyOwner {
    _contractURI = newURI;
    emit ContractURIUpdated();
  }

}

