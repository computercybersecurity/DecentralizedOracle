import {
  updatedRequest,
  newRequest
} from "./ethereum";

const consume = () => {
  updatedRequest((error, event) => {
    console.log(error, event)
    console.log("UPDATE REQUEST DATA EVENT ON SMART CONTRACT");
    // console.log("BLOCK NUMBER: ");
    // console.log("  " + result.blockNumber)
    // console.log("UPDATE REQUEST DATA: ");
    // console.log(result.args);
    console.log("\n");
  });

  newRequest((error, event) => {
    console.log(error, event);
    console.log("NEW REQUEST DATA EVENT ON SMART CONTRACT");
    // console.log("BLOCK NUMBER: ");
    // console.log("  " + result.blockNumber)
    // console.log("NEW REQUEST DATA: ");
    // console.log(result.args);
    console.log("\n");
  });
};

export default consume;