import { LightningElement, api } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
export default class Sbr_3_0_convertToRentQuantityField extends LightningElement {
  itemQuantity;
  @api availableQty;
  invalidInput = false;
  handleItemQtyChange(event) {
    this.itemQuantity = event.target.value;    
    this.validateInput();     
  }

  validateInput() {
    const inputField = this.template.querySelector("lightning-input");   
    //Added for FRONT-29079
    if (!this.itemQuantity) {
      this.invalidInput = true;
      this.dispatchEvent(
        new CustomEvent("itemqtychange", { detail: { value: this.invalidInput } })
      );
      inputField.setCustomValidity(
        "Complete this field."
      );
    } 
    else if (this.itemQuantity < 0) {
      this.invalidInput = true;
      this.dispatchEvent(
        new CustomEvent("itemqtychange", { detail: { value: this.invalidInput } })
      );
      inputField.setCustomValidity(
        "Negative Quantity not allowed."
      );
    } 
    else if(this.itemQuantity != Math.trunc(this.itemQuantity)){
      this.invalidInput = true;
      this.dispatchEvent(
        new CustomEvent("itemqtychange", { detail: { value: this.invalidInput } })
      );
      inputField.setCustomValidity(
        "Your entry isn't a valid increment."
      );
    }
    else if(this.itemQuantity < 1){
      this.invalidInput = true;
      this.dispatchEvent(
        new CustomEvent("itemqtychange", { detail: { value: this.invalidInput } })
      );
      inputField.setCustomValidity(
        "Quantity should be greater than zero."
      );
    }
    else if (this.itemQuantity > this.availableQty) {
      this.invalidInput = true;
      this.dispatchEvent(
        new CustomEvent("itemqtychange", { detail: { value: this.invalidInput } })
      );
      inputField.setCustomValidity(
        "Item Quantity can not be greater than Quantity Available"
      );
    } 
    else {
      this.invalidInput = false;//End of FRONT-29079
      this.dispatchEvent(
        new CustomEvent("itemqtychange", { detail: { value: this.itemQuantity } })
      );
      inputField.setCustomValidity("");
    }
    inputField.reportValidity();
  }

  @api
  handleSubmit() {
    this.validateInput(); 
    if (this.invalidInput) { 
      return false;
    }

    this.dispatchEvent(
      new ShowToastEvent({
        title: "Success",
        message: "Successfully transferred from Sales to Rental.",
        variant: "success"
      })
    );
    return true;
  }
}