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



import "./BUSD.sol";
import "./ProofOfBurn.sol";


pragma solidity ^0.8.28;

/// @title Burn Ceremony (bUSD)
/// @author steviep.eth
/// @notice Interface for issuing new bUSD and Proofs of Burn
contract BurnCeremony {
  BUSD public busd;
  ProofOfBurn public proofOfBurn;
  IBurnAgreement public burnAgreement;
  address public burnAgent;

  event Issuance(address indexed account, uint256 indexed denomination, string indexed serial);

  constructor() {
    busd = BUSD(msg.sender);
  }

  /// @dev This is necessary due to some weird solidity quirk during instantiation. Should only be called once
  function init(address owner, ProofOfBurn pob) external {
    require(burnAgent == address(0));

    burnAgent = owner;
    proofOfBurn = pob;
  }

  modifier onlyAgent {
    require(msg.sender == burnAgent, 'Caller is not Burn Agent');
    _;
  }

  /// @notice Set the Burn Agent role
  function setBurnAgent(address _agent) external {
    require(msg.sender == busd.owner(), 'Ownable: caller is not BUSD owner');
    burnAgent = _agent;
  }

  /// @notice Designate the Burn Agreement contract
  function setBurnAgreement(address agreement) external {
    require(msg.sender == busd.owner(), 'Ownable: caller is not BUSD owner');
    burnAgreement = IBurnAgreement(agreement);
  }

  /// @notice Issue new bUSD. This may only be called during the completion of an official Burn Ceremony
  /// @param account Address to send the POB token to
  /// @param denomination Denomination of the burnt bill
  /// @param serial Serial number of the bunt bill
  function issue(
    address account,
    uint256 denomination,
    string calldata serial
  ) external onlyAgent {
    busd.issue(account, denomination * 1 ether);
    proofOfBurn.mint(account, denomination, serial);

    emit Issuance(account, denomination, serial);
  }

  /// @notice Issue new bUSD using a Burn Agreement NFT. This may only be called during the completion of an official Burn Ceremony
  /// @param agreementTokenId Issue bUSD to the owner of this token
  /// @param denomination Denomination of the burnt bill
  /// @param serial Serial number of the bunt bill
  function issueWithAgreement(
    uint256 agreementTokenId,
    uint256 denomination,
    string calldata serial
  ) external onlyAgent {
    address account = burnAgreement.ownerOf(agreementTokenId);

    burnAgreement.markAgreementUsed(agreementTokenId);
    busd.issue(account, denomination * 1 ether);
    proofOfBurn.mint(account, denomination, serial);

    emit Issuance(account, denomination, serial);
  }
}

