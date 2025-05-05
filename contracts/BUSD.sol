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
  ProofOfBurn public proofOfBurn;
  mapping(uint256 => string) public serials;
  mapping(uint256 => uint8) public denominations;
  mapping(uint256 => string) public proofs;
  mapping(uint256 => uint256) public timestamps;
  mapping(uint256 => string) public memos;
  mapping(address => uint256) public busdBurnedBy;

  constructor() ERC20('Burned United States Dollars', 'bUSD') {
    issuer = msg.sender;
    proofOfBurn = new ProofOfBurn();
  }

  modifier onlyIssuer {
    require(msg.sender == issuer, 'Only the Issuer can execute this action');
    _;
  }

  function assignIssuer(address _issuer) external onlyOwner {
    issuer = _issuer;
  }


  // function mint(
  //   address account,
  //   uint256 denomination,
  //   string calldata serial
  // ) external {
  //   mint(account, denomination, serial, false, 0);
  // }

  function mint(
    address account,
    uint256 denomination,
    string calldata serial,
    bool sendPob,
    uint256 feeBps
  ) external onlyIssuer {
    denominations[billsBurned] = uint8(denomination);
    serials[billsBurned] = serial;
    timestamps[billsBurned] = block.timestamp;

    address pobRecipient = sendPob ? account : owner();
    proofOfBurn.mint(pobRecipient, billsBurned);

    billsBurned += 1;

    uint256 fee = (denomination * 1 ether * feeBps) / 10000;

    _mint(account, denomination * 1 ether - fee);

    if (fee > 0) {
      _mint(owner(), fee);
    }
  }



  function addProof(uint256 burnId, string calldata proof) external onlyIssuer {
    proofs[burnId] = proof;
  }

  function addProofBatch(uint256[] calldata burnIds, string calldata baseURI, string calldata ext) external onlyIssuer {
    for (uint256 i; i < burnIds.length; i++) {
      proofs[burnIds[i]] = string.concat(baseURI, '/', Strings.toString(i), ext);
    }
  }

  function addMemo(uint256 burnId, string calldata memo) external onlyIssuer {
    memos[burnId] = memo;
  }



  function burn(uint256 amount) external {
    busdBurnedBy[msg.sender] += amount;
    _burn(msg.sender, amount);
  }

  function burnFrom(address account, uint256 amount) external {
    address burner = msg.sender;

    if (burner != address(proofOfBurn)) {
      _spendAllowance(account, burner, amount);
    }

    busdBurnedBy[account] += amount;
    _burn(account, amount);
  }
}






contract ProofOfBurn is ERC721 {
  BUSD public busd;
  uint256 public proofsBurned;

  constructor() ERC721('bUSD Proof of Burn', 'POB') {
    busd = BUSD(msg.sender);
  }

  function mint(address to, uint256 tokenId) external {
    require(msg.sender == address(busd), 'Invalid minter');
    _safeMint(to, tokenId);
  }

  function exists(uint256 tokenId) external view returns (bool) {
    return _exists(tokenId);
  }

  function totalSupply() external view returns (uint256) {
    return busd.billsBurned() - proofsBurned;
  }

  function burn(uint256 tokenId) public virtual {
    require(_isApprovedOrOwner(msg.sender, tokenId), 'ERC721: caller is not token owner or approved');

    uint256 denomination = uint256(busd.denominations(tokenId));
    busd.burnFrom(ownerOf(tokenId), denomination * 1 ether);

    proofsBurned += 1;
    _burn(tokenId);
  }


  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    string memory denomination = Strings.toString(busd.denominations(tokenId));
    string memory timestampString = Strings.toString(busd.timestamps(tokenId));
    string memory serial = busd.serials(tokenId);
    string memory proof = busd.proofs(tokenId);
    string memory memo = busd.memos(tokenId);

    string memory attrs = string.concat(
      '[',
        string.concat('{ "trait_type": "Serial", "value": "', serial, '" },'),
        string.concat('{ "trait_type": "Denomination", "value": "', denomination, '" },'),
        string.concat('{ "trait_type": "Burned at", "value": "', timestampString, '" }'),
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