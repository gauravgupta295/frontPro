import { LightningElement, api, track } from "lwc";
import { CLI } from "c/sbr_3_0_frontlineConstants";
import sbr_3_0_customDataTableCSS from "@salesforce/resourceUrl/sbr_3_0_customDataTable_css";
import FrontLineCSS from "@salesforce/resourceUrl/FrontLinesCSS";
import LABELS from "c/sbr_3_0_customLabelsCmp"; //added for FRONT-31384 - Mobile Change
import borderStyle from "@salesforce/resourceUrl/Sbr_3_0_AddressCss";
import { loadStyle } from "lightning/platformResourceLoader";
import { Logger } from "c/sbr_3_0_frontlineUtils";
const logger = Logger.create(true);
export default class Sbr_3_0_contractLineItemsContainer extends LightningElement {
  @api recordId;
  @api objectApiName;
  @track lineItemsToRemove = []; //added for FRONT-31384 - Mobile Change
  showRemoveButton = false; //added for FRONT-31384 - Mobile Change
  lineItemtype; //FRONT-31384 - Mobile Change
  showRemoveScreen = false; //added for FRONT-31384 - Mobile Change
  LABELS = LABELS; //added for FRONT-31384 - Mobile Change
  itemsSize = 0; //added for FRONT-31384 - Mobile Change
  activeSections = [
    "Rental Items",
    "Sales/Misc Items",
    "Delivery Items",
    "Ancillary Charges"
  ];
  showRemoveScreenSales = false; //FRONT-29023

  get rentalsVariant() {
    return CLI.RENTAL;
  }

  get consumeablesVariant() {
    return CLI.CONSUMABLES;
  }

  get deliveryVariant() {
    return CLI.DELIVERY;
  }

  get ancillaryVariant() {
    return CLI.ANCILLARY;
  }

  renderedCallback() {
    if (!this.isMobile) {
      Promise.all([
        loadStyle(this, sbr_3_0_customDataTableCSS),
        loadStyle(this, borderStyle),
        loadStyle(this, FrontLineCSS)
      ])
        .then(() => {
          logger.log("sbr_3_0_customDataTableCSS file loaded");
        })
        .catch((error) => {
          logger.log(
            "Error in loading sbr_3_0_customDataTableCSS file",
            error.body.message
          );
        });
    }
  }
  //added for FRONT-31384 - Mobile Change
  recordstoRemoveHandler(event) {
    this.itemsSize = 0;
    this.lineItemtype = event.detail.lineItemType;
    const recordsToRemove = event.detail.selectedRecordstoRemove;
    logger.log("remove records", JSON.stringify(recordsToRemove));
    if (recordsToRemove.length >= 1) {
      this.showRemoveButton = true;
      this.itemsSize = recordsToRemove.length;
      this.lineItemsToRemove = recordsToRemove;
    } else {
      this.showRemoveButton = false;
    }
  }

  /* FRONT-31386 */
  handleSelectAll() {
    if (this.lineItemtype === "Rental") {
      this.refs.Rentals.selectAllInRentalsCmp();
    } else if (this.lineItemtype === "Consumables") {
      //FRONT-29023
      this.refs.Consumables.selectAllInConsumablesCmp();
    }
  }

  //added for FRONT-31384 - Mobile Change
  removePopUp(e) {
    e.preventDefault();
    e.stopPropagation();
    if (this.lineItemtype === "Rental") {
      this.showRemoveScreen = true;
    } else if (this.lineItemtype === "Consumables") {
      //FRONT-29023
      this.showRemoveScreenSales = true;
    }
  }

  //added for FRONT-31384 - Mobile Change
  handleCancel() {
    this.showRemoveScreen = false;
    this.showRemoveButton = false;
    this.showRemoveScreenSales = false; //FRONT-29023
  }
}