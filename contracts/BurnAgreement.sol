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


contract BurnAgreement is ERC721, Ownable {
  uint256 public totalSupply;
  string public activeAgreementId;
  address public burnCeremony;

  uint256 public price = 0.01 ether;

  mapping(uint256 => string) public tokenIdToAgreementId;
  mapping(string => string) public agreementIdToMetadata;
  mapping(uint256 => bool) public agreementUsed;

  event MetadataUpdate(uint256 _tokenId);
  event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);



  constructor(address ceremony) ERC721('Burn Agreement', 'BA') {
    burnCeremony = ceremony;
  }

  function exists(uint256 tokenId) external view returns (bool) {
    return _exists(tokenId);
  }

  function mint() external payable {
    (bool paymentMade,) = payable(owner()).call{value: price}('');

    if (paymentMade) {
      tokenIdToAgreementId[totalSupply] = activeAgreementId;
      _safeMint(msg.sender, totalSupply);
      totalSupply++;
    }
  }

  function markAgreementUsed(uint256 tokenId) external {
    require(msg.sender == burnCeremony, 'Only burn ceremony can use agreement');
    require(!agreementUsed[tokenId], 'Agreement already used');

    agreementUsed[tokenId] = true;
    emit MetadataUpdate(tokenId);
  }


  function setPrice(uint256 _price) external onlyOwner {
    price = _price;
  }

  function setBurnCeremony(address _burnCeremony) external onlyOwner {
    burnCeremony = _burnCeremony;
  }

  function setActiveAgreement(string calldata _activeAgreementId) external onlyOwner {
    activeAgreementId = _activeAgreementId;
  }


  function setAgreementMetadata(string calldata agreementId, string calldata metadata) external onlyOwner {
    agreementIdToMetadata[agreementId] = metadata;
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    string memory agreementVersion = tokenIdToAgreementId[tokenId];
    string memory bg = agreementUsed[tokenId] ? '#000' : '#fff';
    string memory text = agreementUsed[tokenId] ? '#fff' : '#000';

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
        string.concat('{ "trait_type": "Agreement Used", "value": "', agreementUsed[tokenId] ? 'True' : 'False', '" }'),
      ']'
    );

    return string(abi.encodePacked(
      'data:application/json;utf8,'
      '{"name": "Burn Agreement v', agreementVersion,
      '", "description": "By purchasing this token you implicitly agree to the terms of this agreement.'
      '", "image": "', thumbnail,
      '", "animation_url": "', agreementIdToMetadata[agreementVersion],
      '", "attributes":', attrs,
      '}'
    ));
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721) returns (bool) {
    return interfaceId == bytes4(0x49064906) || super.supportsInterface(interfaceId);
  }
}