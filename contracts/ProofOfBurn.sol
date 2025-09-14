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
import "./BUSD.sol";


pragma solidity ^0.8.28;

/// @title Proof of Burn (bUSD)
/// @author steviep.eth
/// @notice Archival NFTs representing the proof that specific bills were burned in an official bUSD Burn Ceremony
contract ProofOfBurn is ERC721, Ownable {
  BUSD public busd;
  uint256 public billsBurned;
  uint256 public proofsBurned;
  ProofOfBurnURI public uri;

  /// @notice Mapping of tokenIds to serial numbers of burnt bills
  mapping(uint256 => string) public serials;

  /// @notice Mapping of tokenIds to denominations of burnt bills
  mapping(uint256 => uint8) public denominations;

  /// @notice Mapping of tokenIds to metadata
  mapping(uint256 => string) public proofs;

  /// @notice Timestamp of the completion of the bill's Burn Ceremony
  mapping(uint256 => uint256) public timestamps;

  /// @notice Notes regarding the bill's Burn Ceremony
  mapping(uint256 => string) public memos;

  /// @notice A record of which Proofs of Burn were burned by which addresses
  mapping(uint256 => address) public burnedBy;

  /// @notice A log of serial numbers alreay burned
  mapping(string => bool) public serialUsed;

  uint256[] public sessionEnds;

  event MetadataUpdate(uint256 _tokenId);
  event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);
  event Burn(address burner, uint256 tokenId, uint256 amount);

  constructor() ERC721('Proof of Burn (bUSD)', 'POB') {
    busd = BUSD(msg.sender);
    uri = new ProofOfBurnURI();
    transferOwnership(tx.origin);
  }

  /// @notice Checks if given token ID exists
  /// @param tokenId Token to run existence check on
  /// @return True if token exists
  function exists(uint256 tokenId) external view returns (bool) {
    return _exists(tokenId);
  }

  /// @notice Total circulating supply of Proof of Burn tokens
  function totalSupply() external view returns (uint256) {
    return billsBurned - proofsBurned;
  }


  modifier onlyAgent {
    address burnAgent = busd.ceremony().burnAgent();
    require(msg.sender == burnAgent, 'Caller is not Burn Agent');
    _;
  }

  /// @notice Total unique burn sessions completed
  function totalSessions() public view returns (uint256) {
    return sessionEnds.length;
  }

  /// @notice Finds the burn session a specific bill
  function tokenIdToSessionId(uint256 tokenId) public view returns (uint256) {
    uint256 ts = timestamps[tokenId];

    for (uint256 i; i < sessionEnds.length; ++i) {
      if (ts < sessionEnds[i]) return i;
    }

    return sessionEnds.length;
  }


  /// @notice Mark the end of a "session" (i.e. a series of Burn Ceremonies)
  function markSessionEnd() external onlyAgent {
    sessionEnds.push(block.timestamp);
  }

  /// @notice Add the metadata to a specific Proof of Burn token
  function addProof(uint256 tokenId, string calldata proof) external onlyAgent {
    proofs[tokenId] = proof;
    emit MetadataUpdate(tokenId);
  }

  /// @notice Add the metadata to a batch of Proof of Burn tokens
  function addProofBatch(uint256[] calldata tokenIds, string calldata baseURI, string calldata ext) external onlyAgent {
    for (uint256 i; i < tokenIds.length; ++i) {
      proofs[tokenIds[i]] = string.concat(baseURI, Strings.toString(tokenIds[i]), ext);
    }
    emit BatchMetadataUpdate(0, billsBurned);
  }

  /// @notice Add a memo to
  function addMemo(uint256 tokenId, string calldata memo) external onlyAgent {
    memos[tokenId] = memo;
  }


  /// @notice Mint a new Proof of Burn token
  /// @dev This can only be called by the BurnCeremony contract
  /// @param account Address to send the POB token to
  /// @param denomination Denomination of the burnt bill
  /// @param serial Serial number of the bunt bill
  function mint(
    address account,
    uint256 denomination,
    string calldata serial
  ) external {
    require(msg.sender == address(busd.ceremony()), 'Invalid minter');
    require(!serialUsed[serial], 'Serial already used');

    denominations[billsBurned] = uint8(denomination);
    serials[billsBurned] = serial;
    serialUsed[serial] = true;
    timestamps[billsBurned] = block.timestamp;

    _safeMint(account, billsBurned);

    billsBurned += 1;
  }


  /// @notice Burn a specific Proof of Burn token. This will also burn a an amount of the owner's bUSD corresponding to the bill's denomination
  /// @dev This can be delegated to an operator
  function burn(uint256 tokenId) public virtual {
    require(_isApprovedOrOwner(msg.sender, tokenId), 'ERC721: caller is not token owner or approved');

    uint256 amount = uint256(denominations[tokenId]) * 1 ether;
    busd.burnFrom(ownerOf(tokenId), amount);
    burnedBy[tokenId] = ownerOf(tokenId);

    proofsBurned += 1;
    _burn(tokenId);

    emit Burn(burnedBy[tokenId], tokenId, amount);
  }


  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    return uri.tokenURI(tokenId);
  }

  function setURI(address newURI) external {
    require(msg.sender == busd.owner(), 'Caller is not BUSD Owner');
    uri = ProofOfBurnURI(newURI);
  }


  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721) returns (bool) {
    return interfaceId == bytes4(0x49064906) || super.supportsInterface(interfaceId);
  }


  string private _contractURI = 'data:application/json;utf8,{"name":"Proof of Burn (bUSD)"}';
  event ContractURIUpdated();

  function contractURI() external view returns (string memory) {
    return _contractURI;
  }

  function updateContractURI(string calldata newURI) external onlyOwner {
    _contractURI = newURI;
    emit ContractURIUpdated();
  }
}



contract ProofOfBurnURI {
  ProofOfBurn public pob;

  constructor() {
    pob = ProofOfBurn(msg.sender);
  }

  function tokenURI(uint256 tokenId) external view returns (string memory) {
    string memory denomination = Strings.toString(pob.denominations(tokenId));
    string memory timestampString = Strings.toString(pob.timestamps(tokenId));
    string memory serial = pob.serials(tokenId);
    string memory memo = pob.memos(tokenId);
    string memory sessionId = Strings.toString(pob.tokenIdToSessionId(tokenId));
    string memory tokenIdStr = Strings.toString(tokenId);

    bool hasMemo = bytes(memo).length > 0;
    string memory description = string.concat('Proof of Burn #', tokenIdStr, ' for bill: ', serial, ', issuing ', denomination, ' bUSD at timestamp ', timestampString, hasMemo ? string.concat('. Included Memo: ', memo) : '.');
    bytes memory proof = bytes(pob.proofs(tokenId));


    if (proof.length == 0) {
      proof = abi.encodePacked(
        'data:image/svg+xml;base64,',
        Base64.encode(abi.encodePacked(
          '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 320 180">'
            '<rect x="0" y="0" width="100%" height="100%" fill="#000"></rect>'
            '<text x="50%" y="43%" font-size="20px" fill="#fff" font-family="monospace" dominant-baseline="middle" text-anchor="middle">Proof of Burn #', tokenIdStr,'</text>'
            '<text x="50%" y="57%" font-size="20px" fill="#fff" font-family="monospace" dominant-baseline="middle" text-anchor="middle">',
              serial, ' $', denomination,
            '</text>'
          '</svg>'
        ))
      );
    }

    string memory attrs = string.concat(
      '[',
        string.concat('{ "trait_type": "Serial", "value": "', serial, '" },'),
        string.concat('{ "trait_type": "Denomination", "value": "', denomination, '" },'),
        string.concat('{ "trait_type": "Burned at", "value": "', timestampString, '" },'),
        string.concat('{ "trait_type": "Session ID", "value": "', sessionId, '" }'),
        hasMemo ? string.concat(',{ "trait_type": "Burn Memo", "value": "', memo, '" }') : '',
      ']'
    );


    return string(abi.encodePacked(
      'data:application/json;utf8,'
      '{"name": "Proof of Burn #', string.concat(tokenIdStr, ' (', serial, ', $', denomination, ')'),
      '", "description": "', description,
      '", "image": "', proof,
      '", "animation_url": "', proof,
      '", "attributes":', attrs,
      '}'
    ));
  }
}