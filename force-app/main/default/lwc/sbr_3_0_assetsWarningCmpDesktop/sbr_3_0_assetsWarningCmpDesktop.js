import { LightningElement,track,api } from 'lwc';
import LABELS from "c/sbr_3_0_customLabelsCmp";

export default class Testpopup extends LightningElement {
    value = "call_toast";
    label = LABELS;
    isDisabled = false;
      hideModalBox() {
        console.log('Go back  button clicked'+this.value);
        let payload = { eventType: 'GoBack' };
        this.sendEvent(payload);
      }
    
      handleRadioChange(event) {
        console.log('radio on event'+event);
        this.value = event.target.value;
        this.enableConfirmButton();
      }
    
      confirmModalBox() {
        console.log('confirm button clicked'+this.value);
        let payload = { eventType: 'confirm',selectedvalue: this.value };
        this.sendEvent(payload);
        this.disableConfirmButton();
        }    

      get options() {
            return [
              { label: "Keep assigned asset(s)", value: "call_toast" },
              { label: "Remove assigned asset(s)", value: "call_server" }
            ];
          }

      sendEvent(payload) {
            console.log('sendEvent of confirmation popup'+payload);
            const notifyEvent = new CustomEvent("popupevent", {
              detail: payload
            });
            this.dispatchEvent(notifyEvent);
          }

      disableConfirmButton(){
        this.isDisabled = true;
      }
      enableConfirmButton(){
        this.isDisabled = false;
      }
}