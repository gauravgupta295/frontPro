import { LightningElement, track, api } from "lwc";
import FORM_FACTOR from "@salesforce/client/formFactor";
import DESKTOPTEMPLATE from "./sbr_3_0_delivery_OtherSourceBranchDesktop.html";
import MOBILETEMPLATE from "./sbr_3_0_delivery_OtherSourceBranchMobile.html";
import noContentSvg from "@salesforce/resourceUrl/NoContentSVG";
import fetchBranchDetails from "@salesforce/apex/SBR_3_0_AssetInquiryController.getBranchLocation";
import LABELS from "c/sbr_3_0_customLabelsCmp";
const columns = [
  {
    label: LABELS.OTHERSOURCEBRANCHLOCATIONHEADER,
    fieldName: "Branch_Location_Number__c",
    type: "text",
    wrapText: true,
    cellAttributes: {
      class: "successLink",
      headerColumn: true
    },
    initialWidth: 150
  },
  {
    label: LABELS.OTHERSOURCEBRANCHADDRESSHEADER,
    fieldName: "Address__c",
    type: "text",
    wrapText: true
  },
  {
    label: LABELS.PHONEHASH,
    fieldName: "Phone__c",
    type: "text",
    wrapText: true,
    cellAttributes: {
      class: "successLink"
    },
    initialWidth: 150
  }
];
export default class Sbr_3_0_delivery_OtherSourceBranch extends LightningElement {
  @api sourcingBranchValue;
  isMobile;
  @track locationData = [];
  isSearchLocation = false;
  isLocationNotFound = false;
  searchKey = "";
  itemSearchPlaceholder = LABELS.SEARCHLOCATIONLABELPLACEHOLDER;
  noContentimageUrl = noContentSvg;
  columns = columns;
  @track selectedRow = [];
  label = LABELS;
  showSpinner = false;

  render() {
    this.isMobile = FORM_FACTOR === "Small";
    let renderTemplate;
    if (this.isMobile) {
      renderTemplate = MOBILETEMPLATE;
    } else {
      renderTemplate = DESKTOPTEMPLATE;
    }
    return renderTemplate;
  }
  
  searchItems(event) {
    if (event.keyCode === 13) {
      this.showSpinner = true;
      if (event.target.value) {
        this.searchKey = event.target.value;
        fetchBranchDetails({
          branchNumber: this.searchKey
        })
          .then((data) => {
            if (data) {
              this.showSpinner = false;
              this.locationData = [];
              this.selectedRow = [];
              this.isSearchLocation = true;
              this.locationData.push(data);
              this.selectedRow.push(this.locationData[0].Id);
              this.template
                .querySelector(".iserror")
                .classList.remove("no-records");
              this.sendNotification("enableConfirm");
            }
          })
          .catch((error) => {
            console.log(JSON.stringify(error));
            this.showSpinner = false;
            this.isSearchLocation = false;
            this.isLocationNotFound = true;
            this.template.querySelector(".iserror").classList.add("no-records");
            this.template.querySelector(".iserror").blur();
            this.sendNotification("disableConfirm");
          });
      }
    }
  }

  handleSearchChange(event) {
    if (!event.target.value) {
      this.searchKey = event.target.value;
      this.isSearchLocation = false;
      this.isLocationNotFound = false;
      this.sendNotification("disableConfirm");
    }
  }

  sendNotification(eventType) {
    const customEvent = new CustomEvent("eventnotification", {
      detail: {
        eventType: eventType
      }
    });
    this.dispatchEvent(customEvent);
  }
}