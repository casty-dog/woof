/*
 * NOTE: hardhatのコマンドで実行するため使用しない(削除予定)
 */

import fetch from "node-fetch"

export const verifyContract = async (contractAddress: string) => {
  const url = process.env.SCAN_API_URL ?? ""
  const apiKey = process.env.SCAN_API_KEY ?? ""
  if (url === "" || apiKey === "")
    throw new Error("SCAN_API_URL or SCAN_API_KEY is not set")

  await fetch(url, {
    method: "POST",
    body: new URLSearchParams({
      apiKey: apiKey,
      module: "contract",
      action: "verifysourcecode",
      codeformat: "solidity-standard-json-input",
      compilerversion: process.env.SOLC_COMPILER_VERSION ?? "",
      // constructorArguements,
      // sourcecode: standardJson,
      // contractaddress,
      // contractname,
    }).toString(),
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
  })
}
