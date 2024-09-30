import { LightningElement, api, track } from "lwc";
import { Logger, isUndefinedOrNull } from "c/sbr_3_0_frontlineUtils";
import { NavigationMixin } from "lightning/navigation";
import { openTab, focusTab } from "lightning/platformWorkspaceApi";
import FORM_FACTOR from "@salesforce/client/formFactor";

const logger = Logger.create(true);

export default class Sbr_3_0_convertToContract extends NavigationMixin(
  LightningElement
) {
  @api recordId;
  isMobile = false;
  @api objectApiName;
  @api props;
  @api orderId;
  disableConfirm = true; //make this true when all checkboxes are checked
  @track itemListDisplay = true;
  lineItemsLabel;
  rentalItemsLabel;
  salesItemsLabel;
  tabName;

  rentalData = [
    {
      id: "1",
      isChecked: true,
      catClass: "0010012",
      quantity: 1,
      assetNo: "1111",
      status: "Available",
      availableAssets: 1
    },
    {
      id: "2",
      isChecked: true,
      catClass: "0020034",
      quantity: 2,
      assetNo: "2222",
      status: "Available",
      availableAssets: 2
    }
  ];

  salesData = [
    {
      id: "1",
      isChecked: true,
      partItem: "0010022",
      stockVendor: "PALME",
      quantity: 1,
      available: 9
    },
    {
      id: "2",
      isChecked: true,
      partItem: "0020044",
      stockVendor: "PALME",
      quantity: 2,
      available: 9
    }
  ];

  connectedCallback() {
    this.isMobile = FORM_FACTOR === "Small";
    logger.log("inside converttoContract");
    let allRentalItemsChecked = this.rentalData.every(function (i) {
      return i.isChecked === true;
    });
    let allSalesItemsChecked = this.salesData.every(function (i) {
      return i.isChecked === true;
    });
    if (allRentalItemsChecked === true && allSalesItemsChecked === true) {
      this.disableConfirm = false;
    }
    this.lineItemsLabel =
      "Line Item(s) (" + (this.rentalData.length + this.salesData.length) + ")";
    this.rentalItemsLabel = "Rental Items (" + this.rentalData.length + ")";
    this.salesItemsLabel = "Sales Items (" + this.salesData.length + ")";
  }

  @api invoke() {
    console.log("inside invoke");
    this.openNewTab();
  }

  openNewTab() {
    
    if(this.objectApiName === 'SBQQ__Quote__c'){     //FRONT-25312
       this.tabName ='Convert_Quote_To_Contract';
    }
    else{
       this.tabName='Convert_Order_To_Contract';
    }
    openTab({
      url: "/lightning/n/"+ this.tabName + "?c__recordId="+this.recordId,
      label: "Convert To Contract",
      focus: true,
    }).catch((error) => {
      console.log(error);
    });
  }                      //FRONT-25312

  closeMethod() {
    const closeEvent = new CustomEvent("closemodal");
    this.dispatchEvent(closeEvent);
  }

  handleConfirm() {}

  handleSectionClose() {}

  activeSections = ["rentalSection", "salesSection"];

  handleSectionToggle() {}

  onFilterClick() {}

  showAssignAssetScreen() {}

  showRemoveAssetScreen() {}

  handleViewAssetDetails() {}

  handleProductDetails() {}
}