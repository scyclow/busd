// SPDX-License-Identifier: MIT

/*




by steviep.eth
2025

*/



import "./Dependencies.sol";


pragma solidity ^0.8.28;


/// @title bUSD
/// @author steviep.eth
/// @notice ...

contract BUSD is ERC20, Ownable {
  address public issuer;
  uint256 public billsBurned;
  ProofOfBurn public proofOfBurn
  mapping(uint256 => string) public billToSerial;
  mapping(uint256 => uint8) public billToDenomination;
  mapping(uint256 => string) public burnProofs;
  mapping(uint256 => uint256) public burnTimestamps;
  mapping(uint256 => string) public burnNotes;
  mapping(address => uint256) public burnedBy;

  constructor() ERC20('Burnt USD', 'bUSD') {
    issuer = msg.sender;
  }

  modifier onlyIssuer {
    require(msg.sender == issuer, 'Only the Issuer can execute this action');
    _;
  }

  function assignIssuer(address _issuer) external onlyOwner {
    issuer = _issuer;
  }

  function mint(
    address account,
    uint8 denomination,
    string calldata serial,
    bool sendPob,
  ) external onlyIssuer {
    billToDenomination[billsBurned] = denomination;
    billToSerial[billsBurned] = serial;
    burnProofs[billsBurned] = proof;
    burnTimestamps[billsBurned] = block.timestamp;

    address pobRecipient = sendPob ? account : owner();
    proofOfBurn.mint(billsBurned, pobRecipient);

    billsBurned += 1;

    _mint(account, denomination * 1 ether);
  }



  function addProof(uint256 burnId, string calldata proof) external onlyIssuer {
    burnProofs[burnId] = proof;
  }

  function addProofBatch(uint256[] burnIds, string calldata baseURI, string calldata ext) external onlyIssuer {
    for (uint256 i; i < burnIds.length; i++) {
      burnProofs[burnIds[i]] = string.concat(baseURI, '/', Strings.toString(i), ext);
    }
  }

  function addNote(uint256 burnId, string calldata note) external onlyIssuer {
    burnNotes[burnId] = note;
  }



  function burn(uint256 amount) external {
    burnedBy[msg.sender] += amount;
    _burn(msg.sender, amount);
  }

  function burnFrom(address account, uint256 amount) external {
    address burner = msg.sender;

    if (burner != address(proofOfBurn)) {
      _spendAllowance(account, burner, amount);
    }

    burnedBy[account] += amount;
    _burn(account, amount);
  }
}






contract ProofOfBurn is ERC721, ERC721Burnable {
  BUSD public busd;

  constructor() ERC721('Proof of Burn', 'POB') {
    busd = msg.sender;
  }

  function mint(address to, uint256 tokenId) {
    require(msg.sender == busd, 'Invalid minter');
    _safeMint(to, tokenId);
  }

  function exists(uint256 tokenId) external view returns (bool) {
    return _exists(tokenId);
  }

  function totalSupply() external view returns (uint256) {
    return busd.billsBurned();
  }

  function burn(uint256 tokenId) public virtual {
    require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");

    uint256 denomination = uint256(busd.billToDenomination(tokenId)));
    busd.burnFrom(ownerOf(tokenId), denomination * 1 ether);

    _burn(tokenId);
  }


  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    string memory tokenString = Strings.toString(tokenId);
    string memory denomination = Strings.toString(busd.billToDenomination(tokenId));
    string memory timestampString = Strings.toString(busd.burnTimestamps(tokenId));
    string memory serial = busd.billToSerial(tokenId);
    string memory proof = busd.burnProofs(tokenId);
    string memory notes = busd.burnNotes(tokenId);

    string memory attrs = string.concat(
      '[',
        string.concat('{ "trait_type": "Serial", "value": "', serial, '" },'),
        string.concat('{ "trait_type": "Denomination", "value": "', denomination, '" },'),
        string.concat('{ "trait_type": "Burned at", "value": "', timestampString, '" }'),
        notes != '' ? string.concat(',{ "trait_type": "Burn Notes", "value": "', notes, '" }') : '',
      ']'
    );



    return string(abi.encodePacked(
      'data:application/json;utf8,'
      '{"name": "Proof of Burn ', string.concat(serial, ' ($', denomination,'.00)'),
      '", "description": "'
      '", "image": "', proof,
      '", "animation_url": "', proof,
      '", "attributes":', attrs
      '}'
    ));
  }
}