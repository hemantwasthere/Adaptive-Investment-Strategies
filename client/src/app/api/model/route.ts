import axios from "axios";
import { NextResponse } from "next/server";

export async function POST(req: Request) {
  try {
    const response = await axios.post("http://0.0.0.0:6000/predict");

    const data = await response.data;

    return NextResponse.json({
      success: true,
      data: data,
    });
  } catch (error) {
    console.error(error);
    return NextResponse.json({
      success: false,
      error: "Error connecting to the Python server",
    });
  }
}
