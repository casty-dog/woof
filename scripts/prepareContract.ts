import "dotenv/config"
import { ethers } from "ethers"
import Artifact from "../artifacts/contracts/Genesis.sol/Genesis.json"

export const prepareContract = async () => {
  const privateKey: string = process.env.OWNER_PRIVATE_KEY ?? ""
  if (privateKey === "") throw new Error("OWNER_PRIVATE_KEY is not set")

  const rpcUrl: string = process.env.RPC_URL ?? ""
  if (rpcUrl === "") throw new Error("RPC_URL is not set")

  const provider = new ethers.providers.JsonRpcProvider(rpcUrl)
  const signer = new ethers.Wallet(privateKey, provider)
  const artifact = Artifact

  return { provider, signer, artifact }
}
