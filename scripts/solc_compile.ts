/*
 * NOTE: hardhatのコマンドで実行するため使用しない(削除予定)
 */

import "dotenv/config"
import * as fs from "fs"
const solc = require("solc")

const TARGET_FILE = "./contracts/Genesis.sol"
const CONTRACT_NAME = "Genesis"

const compile = async (fileName: string, contractName: string) => {
  console.log("solc version:", solc.version())

  const file = fs.readFileSync(fileName).toString()
  const output = "Genesis.sol"
  const input = {
    language: "Solidity",
    sources: {
      [output]: {
        content: file,
      },
    },
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
      outputSelection: {
        [output]: {
          "*": ["evm.bytecode.object", "abi", "evm.deployedBytecode"],
        },
      },
    },
  }

  const out = JSON.parse(
    solc.compile(JSON.stringify(input), { import: findImports })
  )
  console.log(out)
  const contract = out.contracts[output][contractName]
  return { bytecode: `0x${contract.evm.bytecode.object}`, abi: contract.abi }

  // NOTE: solcとsolidityのバージョンが異なる場合、以下のように特定のバージョンを取得する必要がある

  // await solc.loadRemoteVersion(process.env.SOLC_COMPILER_VERSION, function(err:any, solcSnapshot:any) {
  //   console.log('solcSnapshot')
  //   if (err) {
  //     console.error(err)
  //     return false;
  //   } else {
  //     console.log(solcSnapshot)
  //     const out = JSON.parse(solcSnapshot.compile(JSON.stringify(input), { import: findImports }));
  //     console.log(out)
  //     const contract = out.contracts[output][contractName];
  //     return { bytecode: `0x${contract.evm.bytecode.object}`, abi: contract.abi };
  //   }
  // });
}

const importCache: { [key: string]: { contents: string } } = {}
const findImports = (path: string) => {
  if (importCache[path] == null) {
    // FIXME: contracts内のパスに合わせる場合、ディレクトリ名に合わせて変更が必要
    //   util以外を使用する場合は
    const innerPaths = ["util/"]
    const fullPath = innerPaths.find((name) => path.startsWith(name))
      ? `contracts/${path}`
      : `node_modules/${path}`
    const file = fs.readFileSync(fullPath)
    importCache[path] = {
      contents: file.toString(),
    }
  }
  return importCache[path]
}

const main = async () => {
  compile(TARGET_FILE, CONTRACT_NAME)
  console.log("compiled")
}

main().catch((error) => {
  console.error(error)
  process.exitCode = 1
})
