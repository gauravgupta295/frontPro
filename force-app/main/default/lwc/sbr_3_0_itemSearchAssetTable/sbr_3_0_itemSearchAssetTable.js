import { LightningElement, api, track } from "lwc";
import noContentSvg from "@salesforce/resourceUrl/NoContentSVG"; //15677
import dividerCss from "@salesforce/resourceUrl/Sbr_3_0_AddressCss";
import { loadStyle } from "lightning/platformResourceLoader";
import LABELS from "c/sbr_3_0_customLabelsCmp"; //Front-15677
const DEFAULT_COLUMNS = [
  {
    label: "Cat Class",
    fieldName: "CatClass",
    type: "text",
    editable: false,
    hideDefaultActions: true
  },
  {
    label: "Cat Class Description",
    fieldName: "CatClassDescription",
    type: "text",
    editable: false,
    hideDefaultActions: true
    // initialWidth: 600
  },
  {
    label: "Available",
    fieldName: "Available",
    type: "text",
    editable: false,
    hideDefaultActions: true
  },
  {
    label: "Reservation",
    fieldName: "Reservation",
    type: "text",
    editable: false,
    hideDefaultActions: true
  },
  {
    label: "",
    fieldName: "",
    type: "button",
    editable: false,
    hideDefaultActions: true,
    initialWidth: 100,
    typeAttributes: {
      label: "Select",
      name: "Select",
      title: "Select",
      disabled: false,
      value: "select",
      variant: "Brand"
    }
  }
];

const DUMMY_DEFAULT_TABLE_DATA = [
  {
    CatClass: "7-0025",
    CatClassDescription: "Plea",
    Available: "101",
    Reservation: "5"
  }
];

export default class Sbr_3_0_itemSearchAssetTable extends LightningElement {
  isDataLoaded = true;
  @track columns;
  @track data;
  //Front-15677 start
  noData = false;
  @api activeTab;
  @api descriptionSelectedLocation = "Current Branch"; //FRONT - 15702
  showBlankMsg = false;
  noContentimageUrl = noContentSvg;
  noContentLabel = LABELS.NOCONTENT_LABEL;
  catClassVal = ""; // FRONT - 15702
  buttonVal = ""; // FRONT - 15702
  //Front-15677 end
  @api
  get assetTableColumns() {
    return this.columns;
  }
  set assetTableColumns(value) {
    this.columns = value ? value : DEFAULT_COLUMNS;
  }

  @api
  get assetTableData() {
    return this.data;
  }
  set assetTableData(value) {
    //Front-15677 start
    if (value != "" && value != null && value != "undefined") {
      this.data = value;
      this.noData = false;
    } else {
      this.noData = true;
    }

    //Front-15677 end
  }

  //Front-15677
  renderedCallback() {
    if (
      this.activeTab == "Cat Class Description" ||
      this.activeTab == "Asset"
    ) {
      this.showBlankMsg = true;
    } else {
      this.showBlankMsg = false;
    }
    Promise.all([loadStyle(this, dividerCss)])
      .then(() => {
        console.log("Files loaded");
      })
      .catch((error) => {});
  }

  callRowAction(event) {
    //FRONT - 15702
    this.catClassVal = event.detail.row["Product2.Product_SKU__c"];
    this.buttonVal = event.detail.row["buttonLabel"];
    if (this.buttonVal === "View Assets") {
      const sendValueEvent = new CustomEvent("sendvaluetocontainer", {
        detail: {
          catClassValue: this.catClassVal,
          selectedLocation: this.descriptionSelectedLocation
        }
      });
      this.dispatchEvent(sendValueEvent);
      //FRONT-17145 - send selected row to parent container component
    } else if (this.buttonVal === "Select") {
      const selectEvent = new CustomEvent("selectbulkitem", {
        detail: {
          selectedRow: event.detail.row
        }
      });
      this.dispatchEvent(selectEvent);
    }
  }
}