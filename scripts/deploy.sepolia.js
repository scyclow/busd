
const toETH = amt => ethers.utils.parseEther(String(amt))
const txValue = amt => ({ value: toETH(amt) })

async function main() {
    signers = await ethers.getSigners()

    ;([owner, burnAgent, recipient] = signers)

    const BUSDFactory = await ethers.getContractFactory('BUSD', owner)
    const BurnCeremonyFactory = await ethers.getContractFactory('BurnCeremony', owner)
    const ProofOfBurnFactory = await ethers.getContractFactory('ProofOfBurn', owner)


    BUSD = await BUSDFactory.deploy()
    await BUSD.deployed()

    ProofOfBurn = await ProofOfBurnFactory.attach(
      await BUSD.proofOfBurn()
    )


    BurnCeremony = await BurnCeremonyFactory.attach(
      await BUSD.ceremony()
    )

    await BurnCeremony.connect(owner).mint(owner.address, 100, 'abc123')
    await BurnCeremony.connect(owner).mint(owner.address, 100, 'abc123')
    await BurnCeremony.connect(owner).mint(owner.address, 100, 'abc123')

    console.log('deployer:', owner.address)
    console.log('BUSD:', BUSD.address)
    console.log('Proof of Burn:', ProofOfBurn.address)
    console.log('Burn Ceremony:', BurnCeremony.address)

}


main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });