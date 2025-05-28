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



contract BurnCeremony {
  BUSD public busd;
  ProofOfBurn public proofOfBurn;
  address public burnAgent;

  constructor() {
    busd = BUSD(msg.sender);
  }

  function init(address owner, ProofOfBurn pob) external {
    require(burnAgent == address(0));

    burnAgent = owner;
    proofOfBurn = pob;
  }

  modifier onlyAgent {
    require(msg.sender == burnAgent, 'Caller is not Burn Agent');
    _;
  }

  function setBurnAgent(address _agent) external {
    require(msg.sender == busd.owner(), 'Ownable: caller is not BUSD owner');
    burnAgent = _agent;
  }

  function mint(
    address account,
    uint256 denomination,
    string calldata serial
  ) external onlyAgent {
    busd.mint(account, denomination * 1 ether);
    proofOfBurn.mint(account, denomination, serial);
  }

  // mintWithContract(account, tokenId) payable (0.01)
    // mark contract as executed
    // mint for ownerOf(tokenId)
}


/// @title bUSD
/// @author steviep.eth
/// @notice ...
contract BUSD is ERC20, Ownable {
  BurnCeremony public ceremony;
  ProofOfBurn public proofOfBurn;

  mapping(address => uint256) public busdBurnedBy;

  constructor() ERC20('Burnt United States Dollars', 'bUSD') {
    ceremony = new BurnCeremony();
    proofOfBurn = new ProofOfBurn();

    ceremony.init(owner(), proofOfBurn);
  }

  function mint(address account, uint256 amount) external {
    require(msg.sender == address(ceremony), 'Can only mint through official Burn Ceremony');
    _mint(account, amount);
  }


  function burnFrom(address account, uint256 amount) external {
    require(msg.sender == address(proofOfBurn));

    busdBurnedBy[account] += amount;
    _burn(account, amount);
  }

  function modifyCeremony(address newCeremony) external onlyOwner {
    ceremony = BurnCeremony(newCeremony);
  }
}






contract ProofOfBurn is ERC721, Ownable {
  BUSD public busd;
  uint256 public billsBurned;
  uint256 public proofsBurned;
  ProofOfBurnURI public uri;

  mapping(uint256 => string) public serials;
  mapping(uint256 => uint8) public denominations;
  mapping(uint256 => string) public proofs;
  mapping(uint256 => uint256) public timestamps;
  mapping(uint256 => string) public memos;
  mapping(uint256 => address) public burnedBy;

  uint256[] private _sessionEnds;



  constructor() ERC721('bUSD Proof of Burn', 'POB') {
    busd = BUSD(msg.sender);
    uri = new ProofOfBurnURI();
  }

  function exists(uint256 tokenId) external view returns (bool) {
    return _exists(tokenId);
  }

  function totalSupply() external view returns (uint256) {
    return billsBurned - proofsBurned;
  }


  modifier onlyAgent {
    address burnAgent = busd.ceremony().burnAgent();
    require(msg.sender == burnAgent, 'Caller is not Burn Agent');
    _;
  }

  function totalSessions() public view returns (uint256) {
    return _sessionEnds.length;
  }

  function tokenIdToSessionId(uint256 tokenId) public view returns (uint256) {
    uint256 ts = timestamps[tokenId];

    for (uint256 i; i < _sessionEnds.length; i++) {
      if (ts < _sessionEnds[i]) return i;
    }

    return _sessionEnds.length;
  }


  function markSessionEnd() external onlyAgent {
    _sessionEnds.push(block.timestamp);
  }

  function addProof(uint256 tokenId, string calldata proof) external onlyAgent {
    proofs[tokenId] = proof;
  }

  function addProofBatch(uint256[] calldata tokenIds, string calldata baseURI, string calldata ext) external onlyAgent {
    for (uint256 i; i < tokenIds.length; i++) {
      proofs[tokenIds[i]] = string.concat(baseURI, '/', Strings.toString(i), ext);
    }
  }

  function addMemo(uint256 tokenId, string calldata memo) external onlyAgent {
    memos[tokenId] = memo;
  }


  function mint(
    address to,
    uint256 denomination,
    string calldata serial
  ) external {
    require(msg.sender == address(busd.ceremony()), 'Invalid minter');

    denominations[billsBurned] = uint8(denomination);
    serials[billsBurned] = serial;
    timestamps[billsBurned] = block.timestamp;

    _safeMint(to, billsBurned);

    billsBurned += 1;
  }


  function burn(uint256 tokenId) public virtual {
    require(_isApprovedOrOwner(msg.sender, tokenId), 'ERC721: caller is not token owner or approved');

    uint256 denomination = uint256(denominations[tokenId]);
    busd.burnFrom(ownerOf(tokenId), denomination * 1 ether);
    burnedBy[tokenId] = ownerOf(tokenId);

    proofsBurned += 1;
    _burn(tokenId);
  }


  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    return uri.tokenURI(tokenId);
  }

  function setURI(address newURI) external {
    require(msg.sender == busd.owner(), 'Caller is not BUSD Owner');
    uri = ProofOfBurnURI(newURI);
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
    string memory proof = pob.proofs(tokenId);
    string memory memo = pob.memos(tokenId);
    string memory sessionId = Strings.toString(pob.tokenIdToSessionId(tokenId));

    string memory attrs = string.concat(
      '[',
        string.concat('{ "trait_type": "Serial", "value": "', serial, '" },'),
        string.concat('{ "trait_type": "Denomination", "value": "', denomination, '" },'),
        string.concat('{ "trait_type": "Burned at", "value": "', timestampString, '" },'),
        string.concat('{ "trait_type": "Session ID", "value": "', sessionId, '" }'),
        bytes(memo).length > 0 ? string.concat(',{ "trait_type": "Burn Memo", "value": "', memo, '" }') : '',
      ']'
    );


    return string(abi.encodePacked(
      'data:application/json;utf8,'
      '{"name": "bUSD Proof of Burn ', string.concat(serial, ' ($', denomination,'.00)'),
      '", "description": "'
      '", "image": "', proof,
      '", "animation_url": "', proof,
      '", "attributes":', attrs,
      '}'
    ));
  }
}