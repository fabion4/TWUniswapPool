# TWUniswapPool

Got it! Here's the description formatted in Markdown, suitable for a GitHub `README.md` file or similar documentation.

---

# Pine Script: Concentrated Liquidity Pool Tracker & Visualizer

This Pine Script indicator provides a comprehensive solution for tracking and visualizing concentrated liquidity pools, particularly useful for protocols like Uniswap V3. It allows users to define and monitor multiple liquidity positions directly on their TradingView charts.

## Features

* **Custom Pool Definition**: Define multiple liquidity pools by specifying their open/close times, high/low price bounds ($P_b$ and $P_a$), initial deposited amount ($V_0$), and the price at which the deposit was made ($P_{deposit}$).
* **Liquidity Calculation**: Accurately calculates the underlying liquidity ($L$) for each pool based on the provided initial parameters, crucial for understanding concentrated liquidity mechanics.
* **Real-time Pool Value & Composition**: Dynamically computes and displays the current total value of each pool, along with the individual amounts of Token0 (e.g., USDC) and Token1 (e.g., ETH) held within the pool, adapting to real-time price movements.
* **Visual Range Representation**: Plots horizontal lines on the chart representing the high ($P_b$) and low ($P_a$) price bounds of each active pool, color-coded for clear differentiation.
* **Initial Deposit Price Marker**: Marks the exact price point of the initial liquidity deposit with a clear triangle symbol at the pool's opening time, providing a vital visual reference for entry.
* **Detailed On-Chart Labels**: Presents an informative overlay label for each pool, summarizing key metrics:
    * **Price Span**: The percentage difference between the high and low price bounds.
    * **Calculated Liquidity (L)**: The immutable liquidity value of the pool.
    * **Current Total Value**: The real-time aggregate value of assets in the pool.
    * **Token0 Amount (e.g., USDC)**: The current quantity of the base asset.
    * **Token1 Amount (e.g., ETH)**: The current quantity of the paired asset, along with its current USD equivalent.

## How It Works

The script leverages Pine Script's custom type system to define `Pool` objects, allowing for organized storage of each pool's parameters. A `for` loop iterates through these pools, drawing their respective price ranges using `line.new` and providing dynamic information via `label.new`. The liquidity and asset composition calculations are encapsulated in helper functions, ensuring modularity and readability.

## Use Cases

* **Liquidity Provider (LP) Monitoring**: Easily track the performance and composition of your concentrated liquidity positions.
* **Strategy Backtesting**: Visualize historical pool ranges and observe how asset allocations change with price.
* **Educational Tool**: Understand the dynamics of concentrated liquidity and impermanent loss.
* **Risk Management**: Monitor when your liquidity is moving out of range or becoming entirely one asset.

## Technologies Used

* **Pine Script v6+**: The programming language for TradingView indicators.
* **DeFi Concepts**: Applies principles of concentrated liquidity from protocols like Uniswap V3.

---
