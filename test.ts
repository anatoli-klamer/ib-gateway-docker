/* Example: Print all portfolio positions to console. */

import { IBApi, EventName, ErrorCode, Contract } from "@stoqey/ib";

// create IBApi object

const ib = new IBApi({
  // clientId: 0,
  host: "127.0.0.1",
  port: 4002,
});

// register event handler

let positionsCount = 0;

ib.on(EventName.error, (err: Error, code: ErrorCode, reqId: number) => {
    console.error(`${err.message} - code: ${code} - reqId: ${reqId}`);
  console.error("Failed to connect to TWS/IB Gateway: ", err);
})
  .on(
    EventName.position,
    (account: string, contract: Contract, pos: number, avgCost?: number) => {
      console.log(`${account}: ${pos} x ${contract.symbol} @ ${avgCost}`);
      positionsCount++;
    }
  )
  .once(EventName.positionEnd, () => {
    console.log(`Total: ${positionsCount} positions.`);
    console.log("Connected successfully to TWS/IB Gateway");

    ib.disconnect();
  });

// call API functions

ib.connect();
ib.reqPositions();
