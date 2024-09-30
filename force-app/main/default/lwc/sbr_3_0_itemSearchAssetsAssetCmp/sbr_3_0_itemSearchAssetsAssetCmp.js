import { LightningElement, api, track, wire } from "lwc";
import { isMobile } from "c/sbr_3_0_dynamicRecordFormUtility";
import LABELS from "c/sbr_3_0_customLabelsCmp";
import DESKTOPTEMPLATE from "./desktop.html";
import MOBILETEMPLATE from "./mobile.html";
import { Logger, isEmpty } from "c/sbr_3_0_frontlineUtils";
import noContentSvg from "@salesforce/resourceUrl/NoContentSVG";
import getAssetList from "@salesforce/apex/SBR_3_0_AssetController.getAssetList";
import deleteOrderItem from "@salesforce/apex/SBR_3_0_AssetController.deleteOrderItem"; //FRONT-31106
import { ShowToastEvent } from "lightning/platformShowToastEvent"; //FRONT-31106
import { publish, subscribe, MessageContext } from "lightning/messageService"; //FRONT-31106
import lineItemUpdate from "@salesforce/messageChannel/sbr_3_0_contractLineItemsUpdate__c"; //FRONT-31106
import { loadStyle } from "lightning/platformResourceLoader"; //FRONT-31110
import FrontLineCSS from "@salesforce/resourceUrl/FrontLinesCSS"; //FRONT-31110

const logger = Logger.create(true);
const ASSET_FILTER_TABLE_COLUMNS = [
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
    initialWidth: 300,
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
    initialWidth: 150,
    type: "text",
    wrapText: true,
    editable: false,
    hideDefaultActions: true,
    sortable: true
  },
  {
    label: "Status",
    fieldName: "Status",
    type: "text",
    editable: false,
    hideDefaultActions: true,
    sortable: true
  },
  {
    label: "Current Location",
    fieldName: "SM_PS_Current_Branch_Location_Number__c",
    type: "text",
    editable: false,
    hideDefaultActions: true,
    sortable: true
  },
  {
    label: "Equipment Comments",
    fieldName: "",
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

export default class Sbr_3_0_itemSearchAssetsAssetCmp extends LightningElement {
  columns = ASSET_FILTER_TABLE_COLUMNS;
  showAssets = false;
  @api orderData;
  @api brachLocation;
  get computedMainDivClass() {
    return this.isCatClassTab
      ? "slds-grid slds-wrap item-box bgcolor"
      : "slds-grid slds-wrap item-box";
  }
  assetIdToOrderItems = {};
  @api recordId;
  isMobile = isMobile;
  @track result;
  searchKey;
  noContentimageUrl = noContentSvg;
  assetListParamObject = {
    actvTab: "Asset",
    searchKey: this.searchKey
  };
  LABELS = LABELS;
  inventorySize = 0; //FRONT-19115
  showSpinner = true;
  noRecordsFound = "No records found.";
  assetMessage = "Please use a valid Asset #.";
  flattenedData(data) {
    this.result = data.map((item) => {
      let buttonLabel = "Select";
      if (this.assetIdToOrderItems && this.assetIdToOrderItems[item.Id]) {
        // FRONT-31106
        buttonLabel = "Remove";
      }
      let buttonVariant =
        buttonLabel === "Select" ? "brand" : "brand-outline remove-button";
      //FRONT-31110
      let showRemoveButton =
        buttonLabel === "Remove" ? true : false;

      return {
        ...item,
        StatusDisabled: !(
          (
            item.Status === "AVAILABLE" &&
            item.SM_PS_Current_Branch_Location_Number__c ===
              this.brachLocation &&
            item.SM_PS_Equipment_Type__c !== "Rental"
          ) //FRONT-19115
        ),
        calculatedBtnVariable: buttonLabel,
        calculatedBtnVariant: buttonVariant,
        showRemoveButton: showRemoveButton
      };
    });
  }

  render() {
    let renderTemplate;
    if (this.isMobile) {
      renderTemplate = MOBILETEMPLATE;
    } else {
      renderTemplate = DESKTOPTEMPLATE;
    }
    return renderTemplate;
  }

  //FRONT-19115 --> This method is used to toggle view more and equipment comment section
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
  //FRONT-19115
  handleSearchCriteriaChange(event) {
    this.showSpinner = false;
    this.searchKey = event.detail.searchKey; //FRONT-29393
    logger.log("event Fired for Asset Tab -" + JSON.stringify(event.detail));
    this.assetListParamObject = {
      actvTab: "Asset",
      searchKey: event.detail.searchKey,
      contractId: this.recordId //FRONT-31106
    };
    this.fetchData();
  }
  
  fetchData(){
    getAssetList({ params: this.assetListParamObject })
      .then((data) => {
        logger.log("result of apex :- " + JSON.stringify(data));
        this.showSpinner = true;
        this.result = data;
        this.processResult(data);
        this.flattenedData(data);
        this.inventorySize = data.length;
        if (this.isMobile) {
          this.refs.assetHeader.applyRedBorder(
            //FRONT-29393
            isEmpty(this.result) &&
              this.searchKey !== "" &&
              this.searchKey !== undefined
          );
        } else {
          //FRONT - 30493
          this.refs.assetHeader.toggleDestructiveVariantOnSearchBox(
            isEmpty(this.result) && !isEmpty(this.searchKey)
          );
        }
      })
      .catch((error) => {
        logger.log("Error is " + JSON.stringify(error));
      });
  }
  

  //FRONT-16637: create map of assetId to orderitems list
  processResult(assetData) {
    if (assetData) {
      assetData.forEach((item) => {
        if (item.SBQQ__OrderProducts__r) {
          this.assetIdToOrderItems[item.Id] = item.SBQQ__OrderProducts__r;
        }
      });
    }
  }
  //FRONT-19115
  get isDataAvailable() {
    return !isEmpty(this.result);
  }

  //FRONT-31106
  callRowAction(event) {
    let buttonVal = event.detail.row.calculatedBtnVariable;
    let assetId = event.detail.row.Id;
    if (buttonVal === "Remove") {
      this.showSpinner = false;
      this.removeOrderItem(assetId);
    }
  }

  //FRONT-31106
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
          origin: 'assetTab',
          action: 'refresh'
        };
        publish(this.messageContext, lineItemUpdate, messagePayload);
        this.showSpinner = true;
      })
      .catch((error) => {
        console.log("Error is" + JSON.stringify(error));
        this.showSpinner = true;
      });
  }

  //FRONT-31106
  showToastNotification(event) {
    const newEvent = new ShowToastEvent({
      title: event.detail.title,
      message: event.detail.message,
      variant: event.detail.variant,
      mode: event.detail.mode
    });
    this.dispatchEvent(newEvent);
  }

  //FRONT-31106
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

  //FRONT-30493
  get labelTextForAssetSearchField() {
    return isEmpty(this.searchKey)
      ? LABELS.NOASSETCONTENT_LABEL
      : LABELS.NO_ASSETS_FOUND_FOR_CONTRACT_ITEM_SEARCH;
  }
  
  //FRONT-31110
  handleAssignAsset(event){
    let buttonVal = event.target.dataset.label;
    let assetId = event.target.dataset.id;
    if (buttonVal === "Remove") {
      this.showSpinner = false;
      this.removeOrderItem(assetId);
    }
  }

  //FRONT-31110
  renderedCallback() {
    Promise.all([loadStyle(this, FrontLineCSS)])
      .then(() => {
        console.log("Files loaded");
      })
      .catch((error) => {});
  }
}