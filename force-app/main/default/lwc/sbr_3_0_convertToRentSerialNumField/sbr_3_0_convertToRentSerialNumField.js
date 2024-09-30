import { LightningElement, track, api } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

export default class Sbr_3_0_convertToRentSerialNumField extends LightningElement {
    @track serialNumber;
    handleSerialNumberChange(event) {
        this.serialNumber = event.detail.value;
    }

    @api
    handleSubmit() {
        this.dispatchEvent(
            new ShowToastEvent({
              title: "Success",
              message: "Successfully transferred from Sales to Rental.",
              variant: "success"
            })
          );
    }
}