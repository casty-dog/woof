import "dotenv/config"
import { ethers } from "ethers"
import { MerkleTree } from "merkletreejs"
import { prepareContract } from "./prepareContract"
import { ALLOW_LIST } from "../resources/AllowList"

const main = async () => {
  const { signer, artifact } = await prepareContract()
  const { keccak256 } = ethers.utils
  const contractAddress: string = process.env.CONTRACT_ADDRESS ?? ""
  if (contractAddress === "") throw new Error("CONTRACT_ADDRESS is not set")

  const leafNodes = ALLOW_LIST.map((account) =>
    ethers.utils.solidityKeccak256(
      ["address", "uint256"],
      [account[0], account[1]]
    )
  )
  const merkleTree = new MerkleTree(leafNodes, keccak256, { sortPairs: true })
  const allowlistRootHash = merkleTree.getHexRoot()

  console.log("allowlistRootHash:", allowlistRootHash)

  const contract = new ethers.Contract(contractAddress, artifact.abi, signer)
  contract.attach(contractAddress)
  const tx = await contract.setAllowlist(allowlistRootHash)

  console.log(`contract address: ${contract.address}`)
  console.log(`updateAllowlist by: ${process.env.SCAN_BASE_URL}/tx/${tx.hash}`)
}

main().catch((error) => {
  console.error(error)
  process.exitCode = 1
})
