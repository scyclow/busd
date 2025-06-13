
const toETH = amt => ethers.utils.parseEther(String(amt))
const txValue = amt => ({ value: toETH(amt) })

async function main() {
    signers = await ethers.getSigners()

    ;([owner, burnAgent, recipient] = signers)


    const BUSDFactory = await ethers.getContractFactory('BUSD', owner)
    const BurnCeremonyFactory = await ethers.getContractFactory('BurnCeremony', owner)
    const ProofOfBurnFactory = await ethers.getContractFactory('ProofOfBurn', owner)

    const BurnAgreementFactory = await ethers.getContractFactory('BurnAgreement', owner)




    // 1.
    const BUSD = await BUSDFactory.deploy()
    await BUSD.deployed()

    const ProofOfBurn = await ProofOfBurnFactory.attach(
      await BUSD.proofOfBurn()
    )


    const BurnCeremony = await BurnCeremonyFactory.attach(
      await BUSD.ceremony()
    )


    // 2.
    await BurnCeremony.connect(owner).setBurnAgent(burnAgent.address)


    // 3.
    const BurnAgreement = await BurnAgreementFactory.deploy(BurnCeremony.address)

    // 4.
    await BurnCeremony.connect(owner).setBurnAgreement(BurnAgreement.address)


    // 5.
    await BurnAgreement.connect(owner).setActiveAgreement('1.0.0')

    // 6.
    await BurnAgreement.connect(owner).setAgreementMetadata('1.0.0', 'https://steviep.xyz/busd/burn-agreement-1_0_0.html')




    console.log('deployer:', owner.address)
    console.log('burnAgent:', burnAgent.address)
    console.log('recipient:', recipient.address)
    console.log('BUSD:', BUSD.address)
    console.log('Proof of Burn:', ProofOfBurn.address)
    console.log('Burn Ceremony:', BurnCeremony.address)
    console.log('Burn Agreement:', BurnAgreement.address)







    await BurnAgreement.connect(burnAgent).mint({gasLimit: 180000, ...txValue(0.01)})
    await BurnAgreement.connect(burnAgent).mint({gasLimit: 180000, ...txValue(0.01)})

    await BurnAgreement.connect(owner).totalSupply()
    await BurnAgreement.connect(owner).exists(0)



    await BurnCeremony.connect(burnAgent).mint(recipient.address, 1, 'E00484988A')
    await BurnCeremony.connect(burnAgent).mint(recipient.address, 1, 'B52726219C')
    await BurnCeremony.connect(burnAgent).mintWithAgreement(0, 1, 'L24083692Q')



    await ProofOfBurn.connect(burnAgent).addProofBatch([0, 1, 2], 'ipfs://QmRdEizvuQ14Mt3zGXS9S6MKgQSVEF318MPGioJokGyoNc/testburn', '-small.mp4')

    await BurnAgreement.connect(burnAgent).withdraw(toETH(0.02))

    console.log('complete! =======')

    // await BurnCeremony.connect(owner).mint(owner.address, 100, 'MB 70433235 C')
    // await BurnCeremony.connect(owner).mint(owner.address, 100, 'MB70433235C')
    // await BurnCeremony.connect(owner).mint(owner.address, 1, 'F 54578165 A')

    // await BurnCeremony.connect(owner).mint(owner.address, 100, 'MB 70433235 C')
    // await BurnCeremony.connect(owner).mint(owner.address, 100, 'MB70433235C')
    // await BurnCeremony.connect(owner).mint(owner.address, 1, 'F 54578165 A')

    // await ProofOfBurn.connect(owner).addProofBatch([3, 4, 5], 'ipfs://QmdWo5QJDHG8yC6zE2rTo4M6nNAKAL9qZY2AeMNH6Lrse3/', '.mp4')




}


main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });