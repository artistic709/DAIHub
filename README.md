# DAIHub
DAIHub is a pool for user to deposit DAI to earn the greatest interest not only across different lending protocal, but also from flash-lending to arbitraguer.


## Tools
- [builder](https://buidler.dev/)
- [Ethers](https://docs.ethers.io/ethers.js/html/index.html)
- [Web3](https://web3js.readthedocs.io/en/v1.2.1/)
- [Solhint](https://protofire.github.io/solhint/)


## Get Started
```
npm install
npx builder
```

change `.env.example` to `.env`, and set up your environment variables.
Noted: There should be a prefix `0x` in private key.


### Folder structure
- artifacts: all constract artifacts are under this folder
- contracts: all contracts are under this folder
- scripts: all scripts are under this folder
- test: all tests are under this folder


### Compile contract
```
npm run compile
```
After compiling, contract artifacts will be located under `artifacts` folder.


### Lint
Lint with Solhint
```
npm run lint
```

If you want to prettier your solidity codes, run
```
npm run prettier
```


### Test
```
npm run test
```

You can specify network options to test contracts on testnet.
```
npm run test:rinkeby
npm run test:ropsten
```


### Flatten your contracts
```
npm run flatten
```

### Open console
[Using buidler console](https://buidler.dev/guides/buidler-console.html)
```
npm run console
```


### Write your scripts
You can write your custom scripts, and run.
- [Deploying your contract](https://buidler.dev/guides/deploying.html)
- [Writing scripts](https://buidler.dev/guides/scripts.html)

### Write your tasks
[Creating tasks](https://buidler.dev/guides/create-task.html)
