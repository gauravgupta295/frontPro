import { LightningElement, api, track, wire } from "lwc";
import { isMobile } from "c/sbr_3_0_dynamicRecordFormUtility";
import LABELS from "c/sbr_3_0_customLabelsCmp";
import { Logger, isEmpty } from "c/sbr_3_0_frontlineUtils";
import DESKTOPTEMPLATE from "./desktop.html";
import MOBILETEMPLATE from "./mobile.html";
import noContentSvg from "@salesforce/resourceUrl/NoContentSVG";
import frontLineCss from "@salesforce/resourceUrl/FrontLinesCSS"; // FRONT-28937
import getAssetList from "@salesforce/apex/SBR_3_0_AssetController.getAssetList";
import { loadStyle } from "lightning/platformResourceLoader"; // FRONT-28937
import deleteOrderItem from "@salesforce/apex/SBR_3_0_AssetController.deleteOrderItem"; //FRONT-31107
import { ShowToastEvent } from "lightning/platformShowToastEvent"; //FRONT-31107
import { publish, subscribe, MessageContext } from "lightning/messageService"; //FRONT-31107
import lineItemUpdate from "@salesforce/messageChannel/sbr_3_0_contractLineItemsUpdate__c"; //FRONT-31107
const logger = Logger.create(true);

const SERIAL_FILTER_TABLE_COLUMNS = [
  {
    label: "Asset #",
    fieldName: "Name",
    type: "text",
    editable: false,
    initialWidth: 100,
    hideDefaultActions: true,
    sortable: true,
    cellAttributes: {
      class: "successLink"
    }
  },
  {
    label: "Serial #",
    fieldName: "SM_PS_Serial_Number__c",
    type: "text",
    editable: false,
    initialWidth: 100,
    hideDefaultActions: true,
    sortable: true
  },
  {
    label: "Type",
    fieldName: "SM_PS_Equipment_Type__c",
    initialWidth: 150,
    type: "text",
    editable: false,
    hideDefaultActions: true,
    sortable: true
    //   initialWidth: 600
  },
  {
    label: "Cat Class",
    fieldName: "SM_PS_Cat_Class__c",
    initialWidth: 150,
    type: "text",
    editable: false,
    hideDefaultActions: true,
    sortable: true
  },
  {
    label: "Asset Description",
    fieldName: "SM_PS_Cat_Class_Description__c",
    type: "text",
    wrapText: true,
    editable: false,
    hideDefaultActions: true,
    sortable: true
  },
  {
    label: "Year",
    fieldName: "SM_PS_Model_Year__c",
    initialWidth: 100,
    type: "text",
    editable: false,
    hideDefaultActions: true,
    sortable: true
  },
  {
    label: "Last / Est. Return Date",
    fieldName: "SM_PS_Due_Off_Rent_Date__c",
    initialWidth: 100,
    type: "text",
    wrapText: true,
    editable: false,
    hideDefaultActions: true,
    sortable: true
  },
  {
    label: "Status",
    fieldName: "Status",
    initialWidth: 100,
    type: "text",
    editable: false,
    hideDefaultActions: true,
    sortable: true
  },
  {
    label: "Current Location",
    fieldName: "SM_PS_Current_Branch_Location_Number__c",
    initialWidth: 100,
    type: "text",
    editable: false,
    hideDefaultActions: true,
    sortable: true
  },
  {
    label: "Equipment Comments",
    fieldName: "",
    initialWidth: 100,
    type: "button-icon",
    editable: false,
    hideDefaultActions: true,
    typeAttributes: {
      iconName: "utility:note",
      iconPosition: "left",
      class: "notes-icon-color"
    }
  },
  {
    //FRONT-31107
    label: "",
    fieldName: "calculatedBtnVariable",
    type: "button",
    editable: false,
    hideDefaultActions: true,
    initialWidth: 100,
    typeAttributes: {
      label: { fieldName: "calculatedBtnVariable" },
      name: { fieldName: "calculatedBtnVariable" },
      title: { fieldName: "calculatedBtnVariable" },
      disabled: { fieldName: "StatusDisabled" },
      value: { fieldName: "calculatedBtnVariable" },
      variant: { fieldName: "calculatedBtnVariant" }
    }
  }
];

export default class Sbr_3_0_itemSearchAssetsSerialCmp extends LightningElement {
  noSerialContentLabel = LABELS.NOCONTENTSERIAL_LABEL;
  columns = SERIAL_FILTER_TABLE_COLUMNS;
  @api recordId;
  isMobile = isMobile;
  result;
  searchKey;
  noRecordsFound = "No records found.";
  useSerialMessage = "Please use a valid Serial #.";
  showDefaultScreen = true;
  noContentimageUrl = noContentSvg;
  assetListParamObject = {
    actvTab: "Serial",
    searchKey: this.searchKey
  };
  activeTab = "Serial";
  LABELS = LABELS;
  @api brachLocation;
  inventorySize = 0;
  showSpinner = false;
  assetIdToOrderItems = {}; //FRONT-31107
  fetchData() {
    getAssetList({
      params: this.assetListParamObject
    })
      .then((data) => {
        console.log("DATA FROM SERIAL", JSON.stringify(data));
        this.showDefaultScreen = false;
        this.showSpinner = false;
        this.result = data;
        this.processResult(data); //FRONT-31107
        this.flattenedData(data);
        this.inventorySize = data.length;
        logger.log("this.searchkey : " + this.searchKey);
        //logger.log('this.result: '+isEmpty(this.result)&&this.searchKey !== "" &&this.searchKey !== undefined);
        if (this.isMobile) {
          this.refs.assetSerial.applyRedBorder(
            //FRONT-29680
            isEmpty(this.result) &&
              this.searchKey !== "" &&
              this.searchKey !== undefined
          );
        } else {
          //FRONT-30494
          this.refs.assetSerial.toggleDestructiveVariantOnSearchBox(
            isEmpty(this.result) && !isEmpty(this.searchKey)
          );
        }
      })
      .catch((error) => {
        logger.error("Error Serial Sub Tab", JSON.stringify(error));
      });
  }

  // START : FRONT-28937
  renderedCallback() {
    Promise.all([loadStyle(this, frontLineCss)])
      .then(() => {
        logger.log("Files loaded");
      })
      .catch((error) => {
        logger.log(error.body.message);
      });
  }
  // END : FRONT-28937

  render() {
    let renderTemplate;
    if (this.isMobile) {
      renderTemplate = MOBILETEMPLATE;
    } else {
      renderTemplate = DESKTOPTEMPLATE;
    }
    return renderTemplate;
  }

  async handleSearchCriteriaChange(event) {
    this.showSpinner = true;
    this.searchKey = event.detail.searchKey;
    this.assetListParamObject = {
      ...this.assetListParamObject,
      searchKey: event.detail.searchKey,
      contractId: this.recordId //FRONT-31107
    };
    this.fetchData();
  }

  get isDataAvailable() {
    return !isEmpty(this.result);
  }

  toggleViewContent(event) {
    let currentAssetId = event.target.dataset.assetId;
    let toggleType = event.target.dataset.toggleType;
    this.result = this.result.map((item) => {
      if (item.Id === currentAssetId) {
        if (toggleType === "ViewMore") {
          return {
            ...item,
            ViewMore: !item.ViewMore
          };
        } else if (toggleType === "EquipComments") {
          return {
            ...item,
            HideComments: !item.HideComments
          };
        }
      }
      return item;
    });
  }

  flattenedData(data) {
    this.result = data.map((item) => {
      let buttonLabel = "Select";
      //FRONT-31107
      if (this.assetIdToOrderItems && this.assetIdToOrderItems[item.Id]) {
        console.log(
          "this.assetIdToOrderItems[item.Id]",
          this.assetIdToOrderItems[item.Id]
        );
        buttonLabel = "Remove";
      }
      let buttonVariant =
        buttonLabel === "Select" ? "brand" : "brand-outline remove-button"; //FRONT-31107

      //FRONT-31111
      let showRemoveButton =
        buttonLabel === "Remove" ? true : false;

      return {
        ...item,
        StatusDisabled: !(
          item.Status === "AVAILABLE" &&
          item.SM_PS_Current_Branch_Location_Number__c === this.brachLocation &&
          item.SM_PS_Equipment_Type__c !== "Rental"
        ),
        calculatedBtnVariable: buttonLabel, //FRONT-31107
        calculatedBtnVariant: buttonVariant,
        showRemoveButton : showRemoveButton, //FRONT-31111
        ViewMore: false,
        HideComments: false
      };
    });
  }

  //FRONT-31107
  processResult(assetData) {
    //creating a map of Assets to OrderItems
    if (assetData) {
      assetData.forEach((item) => {
        if (item.SBQQ__OrderProducts__r) {
          this.assetIdToOrderItems[item.Id] = item.SBQQ__OrderProducts__r;
        }
      });
    }
  }

  //FRONT-31107
  callRowAction(event) {
    this.buttonVal = event.detail.row.calculatedBtnVariable;
    let assetId = event.detail.row.Id;
    if (this.buttonVal === "Remove") {
      this.showSpinner = true;
      this.removeOrderItem(assetId);
    }
  }

  //FRONT-31107
  removeOrderItem(assetId) {
    deleteOrderItem({ orderItemId: this.assetIdToOrderItems[assetId][0].Id })
      .then(() => {
        delete this.assetIdToOrderItems[assetId]; //Removing Key value pair from this map
        let deletedAssetObj = this.result.find((obj) => obj.Id === assetId);
        this.flattenedData(this.result);
        let obj = {
          detail: {
            title: "",
            message:
              "Asset # " +
              deletedAssetObj.Name +
              " has been removed from the contract.",
            variant: "success",
            mode: "sticky"
          }
        };
        this.showToastNotification(obj);
        const messagePayload = {
          origin: 'serialTab',
          action: 'refresh'
        };
        publish(this.messageContext, lineItemUpdate, messagePayload);
        this.showSpinner = false;
      })
      .catch((error) => {
        console.log("Error is" + JSON.stringify(error));
        this.showSpinner = false;
      });
  }

  //FRONT-31107
  showToastNotification(event) {
    const newEvent = new ShowToastEvent({
      title: event.detail.title,
      message: event.detail.message,
      variant: event.detail.variant,
      mode: event.detail.mode
    });
    this.dispatchEvent(newEvent);
  }

  //FRONT-31107
  @wire(MessageContext)
  messageContext;

  subscribeToMessageChannel() {
    this.subscription = subscribe(
      this.messageContext,
      lineItemUpdate,
      (message) => this.handleMessage(message)
    );
  }

  handleMessage(message) {
    this.result = null;
    this.assetIdToOrderItems = {};
    this.fetchData();
  }

  connectedCallback() {
    this.subscribeToMessageChannel();
  }

  //FRONT-30494
  get labelTextForSerialSearchField() {
    return isEmpty(this.searchKey)
      ? LABELS.NOCONTENTSERIAL_LABEL
      : LABELS.NO_SERIAL_FOUND_FOR_CONTRACT_ITEM_SEARCH;
  }

  //FRONT-31111
  handleAssignAsset(event){
    let buttonVal = event.target.dataset.label;
    let assetId = event.target.dataset.id;
    if (buttonVal === "Remove") {
      this.showSpinner = true;
      this.removeOrderItem(assetId);
    }
  }
}