---
title: Listen to transfer of Ethereum ERC20 token
description: >-
  Tutorial: How to create a MESG Service that listens for the transfers of an
  Ethereum ERC20 token.
published_link: 'https://docs.mesg.com/tutorials/erc20-transfer-notifications/listen-for-transfers-of-an-ethereum-erc20-token.html'
---

# Listen for transfers of an Ethereum ERC20 token

## Introduction

In this tutorial, we will cover how to create a MESG Service that listens for the transfers of an Ethereum ERC20 token.

This Service will be developed with JavaScript and [Node.js](https://nodejs.org).  
We will use the library [Web3.js](https://web3js.readthedocs.io/en/1.0/) to interact with Ethereum through [Infura](https://infura.io/).

You can access the final version of the [source code on GitHub](https://github.com/mesg-foundation/docs/tree/master/tutorials/erc20-transfer-notifications/listen-to-transfer-of-ethereum-erc20-token).

You can find a more advanced and maintained version of this service here: [Service Ethereum ERC20](https://github.com/mesg-foundation/service-ethereum-erc20)

::: tip
If you haven't installed **MESG Core** yet, you can do so by running the command:

`bash <(curl -fsSL https://mesg.com/install)`

You can also install it manually by following [this guide](/guide/installation.md#manual-installation).
:::

## Create the MESG service

It's time to create our MESG Service. First, open a terminal in your development folder and run the following command:

```bash
mesg-core service init
```

Then, answer the prompts with the following information:

```text
? Enter the output directory: service-ethereum-erc20
? Select a template to use Javascript (https://github.com/mesg-foundation/template-service-javascript)
```

The command should have created a `service-ethereum-erc20` folder containing `mesg.yml`, `Dockerfile` files and a boilerplate for the service.  
Leave these files intact; we'll return to them a bit later in this tutorial.

::: tip
You should see a **mesg.yml** and a **Dockerfile** in your service folder which are the fundamental parts of every MESG service.

* **mesg.yml:** A file that contains all of the metadata of your Service. It gives some global descriptions but also includes the tasks and events that the Service can provide.
  
* **Dockerfile:** A file that describes your Docker container and configures the environment for your service to run inside.
:::

### Before starting...
Let's remove some code related with the service boilerplate for now to create a usual node.js app for demonstration.

First, make sure your terminal is pointed towards the newly-created `service-ethereum-erc20` folder.  

Clean all the code inside `index.js`. And remove the `tasks` folder since we're not going to use it for this service.

And install the dependencies:

 ```bash	
npm install
```	

### Initialize Web3 with Infura

Let's install [Web3.js](https://web3js.readthedocs.io/en/1.0/):

```text
npm install --save web3
```

The first step is to load Web3 and initialize it with Infura.
Add the following code to the top of `index.js` :

```javascript
const Web3 = require('web3')
const web3 = new Web3('wss://mainnet.infura.io/ws')
```

### Specify the ERC20 contract

To listen to transfers of an ERC20, we'll have to direct both the contract ABI and its address to Web3.  
In this tutorial, we will use the 0x Protocol (ZRX) token. You can find its ABI and address on [Etherscan](https://etherscan.io/address/0xe41d2489571d322189246dafa5ebde1f4699f498#code).  
For the simplicity of this tutorial, we will use only a small part of the ABI that exposes the transfers.

Create the file `erc20-abi.json` in the Service folder and copy/paste the following ABI:

<<< @/tutorials/erc20-transfer-notifications/listen-to-transfer-of-ethereum-erc20-token/erc20-abi.json

Now, let's come back to `index.js` and initialize the contract with the ABI and the address. Add:

```javascript
const contract = new web3.eth.Contract(require('./erc20-abi.json'), '0xe41d2489571d322189246dafa5ebde1f4699f498')
```

### Listen for transfer events on ERC20 network

We're finally ready to listen for transfers!

Web3, thanks to the ABI, gives us access to the contract neatly. Let's add the following code to `index.js` :

```javascript
contract.events.Transfer({fromBlock: 'latest'})
  .on('data', (event) => {
    console.log('transfer', event)
  })
  .on('error', (err) => {
    console.error(err)
  })

console.log('Listening ERC20 transfer...')
```

Let's try it!

```bash
node index.js
```

::: warning
It might take a while to receive and display a transfer in the console. The events are received in real time, but if nobody is transferring this ERC20, you won't receive or see any events. You can go onto [Etherscan](https://etherscan.io/token/0xe41d2489571d322189246dafa5ebde1f4699f498) to see the transfers.
:::

Let's improve the output by showing only the useful information. Edit to match:

```javascript
contract.events.Transfer({fromBlock: 'latest'})
  .on('data', (event) => {
    console.log('transfer', {
      blockNumber: event.blockNumber,
      transactionHash: event.transactionHash,
      from: event.returnValues.from,
      to: event.returnValues.to,
      value: String(event.returnValues.value / Math.pow(10, 18)) // We convert value to its user representation based on the number of decimals used by this ERC20.
    })
  })
  .on('error', (err) => {
    console.error(err)
  })

console.log('Listening ERC20 transfer...')
```

Let's run it again:

```bash
node index.js
```

In the terminal, we should see something like:

```text
transfer { blockNumber: 5827612,
  transactionHash: '0x02019f4a80ad43019b8e69aed59e1dea0f03fb48d9df610686a1f590e8f6216d',
  from: '0x58993319Fc9e1b6cFAda8047B63a723Cceb1FfFE',
  to: '0x99f79B7A134db6e30d1b12F9Ee823339CaC0BA83',
  value: '11276800815' }
transfer { blockNumber: 5827612,
  transactionHash: '0xf4a0aad5245417ae376cb9962c93bb9c599d8160cec49a5d82ba593033e657d2',
  from: '0x385dFF5650776188f4da150aA8b17a467812923b',
  to: '0xe8b69609342C337873cD20513e64be7FdE9feCf2',
  value: '100000000' }
```

::: tip Congratulation
You've built a Node app that listens in real-time to transfers of an ERC20 token!
:::

## Transform the node app to a MESG Service

Now, it's time to transform this node app to a fully-compatible MESG Service.

### Update mesg.yml

Let's add the event we want to emit to MESG Core to the `mesg.yml` file.

First, clean the `mesg.yml` file, keeping only the keys: `name`, `sid` and `description`. Change their value to look like this:

```yaml
name: Ethereum ERC20 Service Tutorial
sid: service-ethereum-erc20-tuto
description: Listen to transfers of an ERC20
```

Let's add the transfer event definition:

```yaml
events:
  transfer:
    data:
      blockNumber:
        type: Number
      transactionHash:
        type: String
      from:
        type: String
      to:
        type: String
      value:
        type: String
```

This definition matches the JavaScript object we want to emit to MESG Core. You can refer to the [documentation](/guide/service/service-file.md) for more information about the `mesg.yml` file.

### Require MESG service client

Add the following code to the top of `index.js` :

```javascript
const mesg = require('mesg-js').service()
```

### Emit `transfer` service event to MESG Core

Replace `console.log` by `mesg.emitEvent`, like so:

```javascript
contract.events.Transfer({fromBlock: 'latest'})
  .on('data', (event) => {
    console.log('New ERC20 transfer received with hash:', event.transactionHash)
    mesg.emitEvent('transfer', {
      blockNumber: event.blockNumber,
      transactionHash: event.transactionHash,
      from: event.returnValues.from,
      to: event.returnValues.to,
      value: String(event.returnValues.value / Math.pow(10, 18)) // We convert value to its user representation based on the number of decimals used by this ERC20.
    })
  })
  .on('error', (err) => {
    console.error(err)
  })

console.log('Listening ERC20 transfer...')
```

## Testing

The first step of testing is to make sure that the Service is valid by running:

```bash
mesg-core service validate
```

You should have a message with `Service is valid`, if not, check the previous steps again; you probably missed something 🤔

It's time to test the Service with MESG!

Make sure MESG Core is running:

```bash
mesg-core start
```

Let's actually test the service! Run:

```bash
mesg-core service dev
```

After the building and deployment steps, you should see that the Service has started:

```text
Service started
Listening for events from the service...
Listening for results from the service...
```

And finally, after a few seconds:

```text
2018/06/21 18:40:15 Receive event transfer : {"blockNumber":5828174,"from":"0x5B47bbA2F60AFb4870c3909a5b249F01E6d11BAe","to":"0x819B2368fa8781C4866237A0EA5E61Ec51492A32","transactionHash":"0x524751269a73294fa1fddf8fd584e40d51f4174df2a4ee8e081ea9a94ce7cc90","value":"79000000"}
```

::: tip Congratulation!
Hooray!!! 🎉 You finished building a MESG Service that listens for transfer of an ERC20 token!
:::

## Usage

To use this Service in your future application, you'll need to deploy it:

```text
mesg-core service deploy
```

This command returns the service's ID that will be required by your application.

## Final version of the source code

<card-link url="https://github.com/mesg-foundation/docs/tree/master/tutorials/erc20-transfer-notifications/listen-to-transfer-of-ethereum-erc20-token"></card-link>
