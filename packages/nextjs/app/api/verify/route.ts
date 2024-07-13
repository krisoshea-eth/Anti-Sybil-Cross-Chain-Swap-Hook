// /app/api/verify/route.ts
import { NextRequest, NextResponse } from "next/server";
import { IVerifyResponse, verifyCloudProof } from "@worldcoin/idkit";

export async function POST(req: NextRequest) {
  const proof = await req.json();
  const app_id = process.env.APP_ID;
  const action = process.env.ACTION_ID;

  if (!app_id || !action) {
    return NextResponse.json({ error: "Environment variables APP_ID and ACTION_ID must be set" }, { status: 500 });
  }

  try {
    //ts-ignore
    const verifyRes = (await verifyCloudProof(proof, `app_${app_id}`, `action_${action}`)) as IVerifyResponse;

    if (verifyRes.success) {
      // This is where you should perform backend actions if the verification succeeds
      // Such as, setting a user as "verified" in a database
      return NextResponse.json(verifyRes, { status: 200 });
    } else {
      // This is where you should handle errors from the World ID /verify endpoint.
      // Usually, these errors are due to a user having already verified.
      return NextResponse.json(verifyRes, { status: 400 });
    }
  } catch (error) {
    return NextResponse.json({ error: "Internal Server Error" }, { status: 500 });
  }
}
