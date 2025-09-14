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


pragma solidity ^0.8.28;


/// @title Burn Agreement (bUSD)
/// @author steviep.eth
/// @notice Terms and conditions for engaging with the bUSD project. Owning a Burn Agreement token can be used to streamline the bUSD issuance process. Ownership of this NFT does not guarantee participation in a Burn Ceremony
contract BurnAgreement is ERC721, Ownable {
  uint256 public totalSupply = 1;
  string public activeAgreementVersion = '1.0.0';
  address public burnCeremony;
  BurnAgreementURI public uri;
  BurnAgreementMinter public minter;

  /// @notice Map a Burn Agreement token to the agreement version
  mapping(uint256 => string) public tokenIdToAgreementVersion;

  /// @notice Map an agreement version to the agreement content uri
  mapping(string => string) public agreementVersionToMetadata;

  /// @notice Keeps track of whether an agreement token has been used in a Ceremony
  mapping(uint256 => bool) public agreementUsed;

  event MetadataUpdate(uint256 _tokenId);
  event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);


  /// @dev Mints #0 to the contract deployer
  constructor(address ceremony) ERC721('Burn Agreement', 'BA') {
    burnCeremony = ceremony;
    uri = new BurnAgreementURI();
    minter = new BurnAgreementMinter();
    _safeMint(msg.sender, 0);
    tokenIdToAgreementVersion[0] = activeAgreementVersion;
  }

  /// @notice Checks if given token ID exists
  /// @param tokenId Token to run existence check on
  /// @return True if token exists
  function exists(uint256 tokenId) external view returns (bool) {
    return _exists(tokenId);
  }

  /// @notice Mints a Burn Agreement token to the recipient
  /// @param recipient Address to sent token to
  /// @dev Can only be called by the BurnAgreementMinter
  function mint(address recipient) external payable {
    require(msg.sender == address(minter), 'Only minting address can mint');

    tokenIdToAgreementVersion[totalSupply] = activeAgreementVersion;
    _safeMint(recipient, totalSupply);
    totalSupply++;
  }

  /// @notice Marks an Agreement as "used" as part of a burn ceremony
  /// @dev Can only be called by the BurnCeremony
  function markAgreementUsed(uint256 tokenId) external {
    require(msg.sender == burnCeremony, 'Only burn ceremony can use agreement');
    require(!agreementUsed[tokenId], 'Agreement already used');

    agreementUsed[tokenId] = true;
    emit MetadataUpdate(tokenId);
  }


  function setMinter(BurnAgreementMinter newMinter) external onlyOwner {
    minter = newMinter;
  }


  function setBurnCeremony(address _burnCeremony) external onlyOwner {
    burnCeremony = _burnCeremony;
  }

  function setActiveAgreement(string calldata _activeAgreementVersion) external onlyOwner {
    activeAgreementVersion = _activeAgreementVersion;
  }


  function setAgreementMetadata(string calldata agreementVersion, string calldata metadata) external onlyOwner {
    agreementVersionToMetadata[agreementVersion] = metadata;
  }


  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    return uri.tokenURI(tokenId);
  }

  function setURI(address newURI) external onlyOwner {
    uri = BurnAgreementURI(newURI);
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721) returns (bool) {
    return interfaceId == bytes4(0x49064906) || super.supportsInterface(interfaceId);
  }
}


/// @title Burn Agreement Minter (bUSD)
/// @author steviep.eth
/// @notice Interface for minting bUSD Burn Agreement NFTs
contract BurnAgreementMinter {
  uint256 public price = 0.01 ether;

  BurnAgreement public burnAgreement;

  constructor() {
    burnAgreement = BurnAgreement(msg.sender);
  }

  modifier onlyOwner {
    require(msg.sender == burnAgreement.owner(), "Ownable: caller is not the owner");
    _;
  }

  function mint() external payable {
    require(msg.value >= price, 'Invalid value');

    burnAgreement.mint(msg.sender);
  }


  function withdraw(uint256 balance) external onlyOwner {
    (bool success, ) = payable(burnAgreement.owner()).call{value: balance}('');
    require(success, "Transfer failed");
  }

  function setPrice(uint256 _price) external onlyOwner {
    price = _price;
  }
}



contract BurnAgreementURI {
  BurnAgreement public agreement;

  constructor() {
    agreement = BurnAgreement(msg.sender);
  }


  function tokenURI(uint256 tokenId) public view returns (string memory) {
    bool agreementUsed = agreement.agreementUsed(tokenId);
    string memory agreementVersion = agreement.tokenIdToAgreementVersion(tokenId);

    string memory bg = agreementUsed ? '#000' : '#fff';
    string memory text = agreementUsed ? '#ef791f' : '#000';

    bytes memory thumbnail = abi.encodePacked(
      'data:image/svg+xml;base64,',
      Base64.encode(abi.encodePacked(
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 850 1100">'
          '<style>text{font:bold 50px sans-serif;fill:', text, ';text-anchor: middle}</style>'
          '<rect width="850" height="1100" x="0" y="0" fill="', bg,'" stroke="none"/>'
          '<rect x="150" y="150" width="550" height="800" style="fill:none;stroke:', text,';stroke-width:7.5px"/>'
          '<text x="425" y="450">BURN</text>'
          '<text x="425" y="550">AGREEMENT</text>'
          '<text x="425" y="650">v', agreementVersion, '</text>'
        '</svg>'
      ))
    );

    string memory attrs = string.concat(
      '[',
        string.concat('{ "trait_type": "Agreement Version", "value": "', agreementVersion, '" },'),
        string.concat('{ "trait_type": "Agreement Used", "value": "', agreementUsed ? 'True' : 'False', '" }'),
      ']'
    );

    return string(abi.encodePacked(
      'data:application/json;utf8,'
      '{"name": "Burn Agreement v', agreementVersion,
      '", "description": "By purchasing this token you implicitly agree to the terms of this agreement. Ownership of this NFT does not guarantee participation in a Burn Ceremony. Participation shall be left to the full discretion of the Burn Agent.'
      '", "image": "', thumbnail,
      '", "animation_url": "', agreement.agreementVersionToMetadata(agreementVersion),
      '", "attributes":', attrs,
      '}'
    ));
  }
}