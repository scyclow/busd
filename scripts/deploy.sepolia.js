
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

    await BurnCeremony.connect(owner).mint(owner.address, 100, 'MB 70433235 C')
    await BurnCeremony.connect(owner).mint(owner.address, 100, 'MB70433235C')
    await BurnCeremony.connect(owner).mint(owner.address, 1, 'F 54578165 A')

    await BurnCeremony.connect(owner).mint(owner.address, 100, 'MB 70433235 C')
    await BurnCeremony.connect(owner).mint(owner.address, 100, 'MB70433235C')
    await BurnCeremony.connect(owner).mint(owner.address, 1, 'F 54578165 A')

    await ProofOfBurn.connect(owner).addProofBatch([3, 4, 5], 'ipfs://QmdWo5QJDHG8yC6zE2rTo4M6nNAKAL9qZY2AeMNH6Lrse3/', '.mp4')



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