import axios from "axios";
import { NextResponse } from "next/server";

// Type definition for the ETH price object
interface EthPriceEntry {
  price: number;
  timestamp: Date;
}

// Array to store past ETH prices
let ethPrices: EthPriceEntry[] = [];
const maxChanges = 6;

export async function POST(req: Request): Promise<Response> {
  try {
    const res = await axios.get("https://app.strkfarm.xyz/api/price/ETH");
    const currentEthPrice: number = res?.data?.price;

    if (typeof currentEthPrice !== "number" || currentEthPrice <= 0) {
      throw new Error("Invalid ETH price fetched");
    }

    ethPrices.push({
      price: currentEthPrice,
      timestamp: new Date(),
    });

    // Ensure only two prices are used for comparison to keep memory usage low
    if (ethPrices.length > 2) {
      ethPrices.shift();
    }

    // Calculate the percentage change if we have at least two prices
    let percentageChanges: number[] = [];
    if (ethPrices.length === 2) {
      const [oldPriceObj, newPriceObj] = ethPrices;
      const oldPrice: number = oldPriceObj.price;
      const newPrice: number = newPriceObj.price;
      const percentageChange: number = ((newPrice - oldPrice) / oldPrice) * 100;

      // Ensure no decimal numbers in the percentage change
      percentageChanges.push(Math.round(percentageChange));
    }

    // Stop when we have 6 percentage changes
    if (percentageChanges.length >= maxChanges) {
      return NextResponse.json({
        success: true,
        data: {
          percentageChanges: percentageChanges.slice(0, maxChanges),
        },
      });
    }

    const response = await axios.post("http://0.0.0.0:6000/predict", {
      volatility: percentageChanges,
    });

    const data: unknown = response.data;

    return NextResponse.json({
      success: true,
      data: data,
      percentageChanges: percentageChanges,
    });
  } catch (error) {
    console.error("Error:", error);
    return NextResponse.json({
      success: false,
      error: "Error connecting to the Python server or fetching ETH price",
    });
  }
}
