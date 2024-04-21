import "dotenv/config"
import { ethers } from "ethers"
import { prepareContract } from "./prepareContract"

const main = async () => {
  const { signer, artifact } = await prepareContract()
  const contractAddress: string = process.env.CONTRACT_ADDRESS ?? ""
  if (contractAddress === "") throw new Error("CONTRACT_ADDRESS is not set")

  const scanBaseUrl = `${process.env.SCAN_BASE_URL}/tx/`

  const contract = new ethers.Contract(contractAddress, artifact.abi, signer)
  contract.attach(contractAddress)
  const isPublicSalePaused = await contract.publicSalePaused()

  if (isPublicSalePaused) {
    // public sale is paused, unpause it
    await contract.setPublicSalePaused(false).then(async (tx: any) => {
      console.log(`setPublicSalePaused: false`, `tx: ${scanBaseUrl + tx.hash}`)
      // pre sale pause
      await contract
        .setPreSalePaused(true)
        .then((tx: any) =>
          console.log(`setPreSalePaused: true`, `tx: ${scanBaseUrl + tx.hash}`)
        )
    })
  } else {
    // pre sale is paused, unpause it
    await contract.setPreSalePaused(false).then(async (tx: any) => {
      console.log(`setPreSalePaused: false`, `tx: ${scanBaseUrl + tx.hash}`)
      // public sale pause
      await contract
        .setPublicSalePaused(true)
        .then((tx: any) =>
          console.log(
            `setPublicSalePaused: true`,
            `tx: ${scanBaseUrl + tx.hash}`
          )
        )
    })
  }
}

main().catch((error) => {
  console.error(error)
  process.exitCode = 1
})
