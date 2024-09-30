import { LightningElement } from 'lwc';
import style from "@salesforce/resourceUrl/New_Work_Order_Screen_Style";
import { loadStyle } from "lightning/platformResourceLoader";
export default class Sbr_3_0_sfsNewWorkOrderQuickActionLwc extends LightningElement {
    
    connectedCallback() {
        loadStyle(this, style );
      }

}