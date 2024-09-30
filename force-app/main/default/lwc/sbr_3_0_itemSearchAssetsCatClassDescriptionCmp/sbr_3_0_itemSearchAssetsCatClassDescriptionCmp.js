import { LightningElement, api, track, wire } from "lwc";
import FORM_FACTOR from "@salesforce/client/formFactor";
import LABELS from "c/sbr_3_0_customLabelsCmp";
import { Logger, isEmpty } from "c/sbr_3_0_frontlineUtils";
import { loadStyle } from "lightning/platformResourceLoader";
import FrontLineCSS from "@salesforce/resourceUrl/FrontLinesCSS";
//Added as part of FRONT-18174
import DESKTOPTEMPLATE from "./desktop.html";
import MOBILETEMPLATE from "./mobile.html";
import noContentSvg from "@salesforce/resourceUrl/NoContentSVG";
import getProductItemList from "@salesforce/apex/SBR_3_0_AssetController.getProductItemList";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import {
  publish,
  subscribe,
  unsubscribe,
  APPLICATION_SCOPE,
  MessageContext
} from "lightning/messageService";
import lineItemUpdate from "@salesforce/messageChannel/sbr_3_0_contractLineItemsUpdate__c";
import createOrderItem from "@salesforce/apex/SBR_3_0_DMLOpsController.createSObject"; //20232

const DEFAULT_TABLE_COLUMNS = [
  {
    label: "Cat Class",
    initialWidth: 150, //FRONT-15699
    fieldName: "Product2.PPA_CatClass__c",
    type: "url",
    editable: false,
    hideDefaultActions: true,
    //FRONT-15699
    typeAttributes: {
      label: { fieldName: "Product2.PPA_CatClass__c" },
      target: "_blank"
    }
  },
  {
    label: "Cat Class Description",
    fieldName: "ProductName",
    type: "text",
    editable: false,
    hideDefaultActions: true
  },
  {
    label: "Available",
    initialWidth: 150, //FRONT-15699
    fieldName: "SM_PS_Quantity_Available__c",
    type: "text", //FRONT-15699
    editable: false,
    hideDefaultActions: true
  },
  {
    label: "Reservation",
    initialWidth: 150, //FRONT-15699
    fieldName: "SM_PS_Quantity_Reserved__c",
    type: "url", //FRONT-15699
    editable: false,
    hideDefaultActions: true,
    //FRONT-15699
    typeAttributes: {
      label: { fieldName: "SM_PS_Quantity_Reserved__c" },
      target: "_blank"
    }
  },
  {
    label: "",
    fieldName: "buttonLabel", //FRONT-15699
    type: "button",
    editable: false,
    hideDefaultActions: true,
    initialWidth: 300,
    typeAttributes: {
      label: { fieldName: "buttonLabel" }, //FRONT-15699
      name: { fieldName: "buttonLabel" }, //FRONT-15699
      title: { fieldName: "buttonLabel" }, //FRONT-15699
      disabled: false,
      value: { fieldName: "buttonLabel" }, //FRONT-15699
      variant: { fieldName: "buttonVariant" }
    },
    cellAttributes: {
      class: "slds-align_absolute-center"
    }
  }
];

const logger = Logger.create(true);
export default class Sbr_3_0_itemSearchAssetsCatClassDescriptionCmp extends LightningElement {
  columns = DEFAULT_TABLE_COLUMNS;
  noContentLabel = LABELS.NOCONTENT_LABEL; //FRONT-14480
  noCatClassContentLabel = LABELS.NOCONTENTCATCLASS_LABEL; // FRONT-17146
  noContentimageUrl = noContentSvg;
  @api recordId;
  @api orderData;
  @api objectApiName;
  isMobile;
  isDataLoaded = false;
  @track result;
  catClassVal;
  productItemParamObject = {};
  buttonVal;
  productIdToOrderItems = {};
  selectedLocationFilter = "Current Branch";
  rowLimit = 100; // FRONT-15699 & FRONT-17146
  rowOffSet = 0; // FRONT-15699 & FRONT-17146
  searchKey;
  itemListSearchKey; // FRONT-17146
  activeTab = "Cat Class Description";
  modalHeader;
  isEditorRateShow = false; //19001
  @track selectedAssetRow;
  @track catClassDescDataForMobile = [];
  showSpinner = true;
  hideEditorFooter = false;
  noCatContentLabel = LABELS.NOCONTENT_LABEL;
  inventorySize = 0;
  checkHandleLoadMoreOnce = false; // FRONT-17146
  isDisable = false;
  connectedCallback() {
    if (FORM_FACTOR === "Small") {
      this.isMobile = true;
    }
    this.productItemParamObject = {
      searchKey: this.searchKey,
      itemListSearchKey: this.itemListSearchKey, // FRONT-17146
      actvTab: "Cat Class Description",
      selectedLocationFilter: this.selectedLocationFilter,
      contractId: this.recordId,
      limitSize: this.rowLimit, // FRONT-15699 & FRONT-17146
      offset: this.rowOffSet // FRONT-15699 & FRONT-17146
    };
  }

  // FRONT-17146
  renderedCallback() {
    Promise.all([loadStyle(this, FrontLineCSS)])
      .then(() => {
        console.log("Files loaded");
      })
      .catch((error) => {});

    if (!this.isMobile) {
      if (this.result && this.result.length > 0) {
        this.template
          .querySelector('[data-id="tableDiv"]')
          .classList.add("table-height");
      } else {
        this.template
          .querySelector('[data-id="tableDiv"]')
          .classList.remove("table-height");
      }
    }
  }

  handleSearchCriteriaChange(event) {
    logger.log("event details", JSON.stringify(event.detail));
    this.checkHandleLoadMoreOnce = false;
    this.showSpinner = false;
    this.inventorySize = 0;
    this.rowOffSet = 0;
    this.searchKey = event.detail.searchKey;
    this.itemListSearchKey = event.detail.itemListSearchKey; // FRONT-17146
    this.productItemParamObject = {
      ...this.productItemParamObject,
      searchKey: event.detail.searchKey,
      itemListSearchKey: this.itemListSearchKey, // FRONT-17146
      selectedLocationFilter: event.detail.selectedLocationFilter,
      contractId: this.recordId,
      limitSize: this.rowLimit, // FRONT-15699
      offset: this.rowOffSet // FRONT-15699
    };
    this.result = null;
    logger.log(
      "++productItemParamObject ",
      JSON.stringify(this.productItemParamObject)
    );
    const lightningDatatable = this.template.querySelector(
      "lightning-datatable"
    );
    if (lightningDatatable) {
      lightningDatatable.isLoading = true;
    }
    this.fetchData();
  }

  // Modified for FRONT-15699 & FRONT-17146
  fetchData() {
    getProductItemList({ params: this.productItemParamObject })
      .then((data) => {
        if (data && data.length > 0) {
          this.inventorySize = this.inventorySize + data.length;
          if (!this.isMobile) {
            this.showSpinner = true;
            this.template
              .querySelector("c-sbr_3_0_item-search-assets-header")
              .setIsItemListSearchDisabled(false); // FRONT-17146
            let oldData = this.result ? this.result : [];
            this.processResult(data);
            let updatedRecords = [...oldData, ...this.result];
            this.result = updatedRecords;
            const lightningDatatable = this.template.querySelector(
              "lightning-datatable"
            );
            logger.log("++data.length" + data.length);
            if (data.length === this.rowLimit) {
              logger.log("++inside if");
              lightningDatatable.enableInfiniteLoading = true;
            } else {
              logger.log("++inside else");
              lightningDatatable.enableInfiniteLoading = false;
            }
            lightningDatatable.isLoading = false;
          } else {
            this.processResult(data);
          }
        } else {
          this.inventorySize = 0;
          if (!this.isMobile) {
            this.showSpinner = true;
            if (!this.itemListSearchKey) {
              this.template
                .querySelector("c-sbr_3_0_item-search-assets-header")
                .setIsItemListSearchDisabled(true); // FRONT-17146
            }
            this.result = [];
            const lightningDatatable = this.template.querySelector(
              "lightning-datatable"
            );
            lightningDatatable.enableInfiniteLoading = false;
            lightningDatatable.isLoading = false;
          } else {
            this.catClassDescDataForMobile = [];
          }
        }
      })
      .catch((error) => {
        logger.log(
          "error in -- Sbr_3_0_itemSearchAssetsCatClassDescriptionCmp" +
            JSON.stringify(error)
        );
        this.result = [];
        const lightningDatatable = this.template.querySelector(
          "lightning-datatable"
        );
        lightningDatatable.enableInfiniteLoading = false;
        lightningDatatable.isLoading = false;
      });
  }

  processResult(productItemData) {
    let productItems = [];
    if (productItemData) {
      productItemData.forEach((item) => {
        productItems.push(item.productItem);
        this.productIdToOrderItems[item.productItem.Product2Id] =
          item.orderItems;
      });
    }
    this.catClassDescDataForMobile = productItems;
    const flattenedJSONArray = this.flattenArrayOfJSON(productItems);
    this.result = flattenedJSONArray;
  }
  //FRONT-24414
  handleTabClicked(event) {

    this.hideEditorFooter = event.detail.ratematrix;
  }

  flattenArrayOfJSON(arr) {
    let flattenedArray = [];
    arr.forEach((obj) => {
      let flattenedObj = {};
      for (let key in obj) {
        if (typeof obj[key] === "object" && obj[key] !== null) {
          let nestedObj = this.flattenJSON(obj[key], key);
          flattenedObj = { ...flattenedObj, ...nestedObj };
        } else {
          flattenedObj[key] = obj[key];
        }
      }
      if (obj.Product2.Bulk_Item__c) {
        //FRONT-17145: added logic to get the button label dynamically
        let buttonLabel = this.getBulkItemButtonLabel(flattenedObj);
        let buttonVariant =
          buttonLabel === "Select" ? "Brand" : "brand-outline";
        flattenedObj = {
          ...flattenedObj,
          buttonLabel: buttonLabel,
          buttonVariant: buttonVariant
        };
        logger.log("@@flattenedObj bulk::", JSON.stringify(flattenedObj));
      } else {
        logger.log("flattenedObj-> " + JSON.stringify(flattenedObj));
        flattenedObj = {
          ...flattenedObj,
          buttonLabel: "View Assets",
          buttonVariant: "Brand"
        };
      }
      flattenedArray.push(flattenedObj);
    });
    return flattenedArray;
  }

  //FRONT-17145: to get the button label dynamically if OrderItem exist for the list bulk Product Item
  getBulkItemButtonLabel(flattenedObj) {
    let buttonLabel = "Select";
    if (
      flattenedObj &&
      this.productIdToOrderItems &&
      this.productIdToOrderItems[flattenedObj.Product2Id]
    ) {
      buttonLabel = "Remove";
    }
    return buttonLabel;
  }

  flattenJSON(obj, parentKey = "") {
    let flattened = {};
    for (let key in obj) {
      if (typeof obj[key] === "object" && obj[key] !== null) {
        let nestedObj = this.flattenJSON(obj[key], key);
        flattened = { ...flattened, ...nestedObj };
      } else {
        let newKey = parentKey !== "" ? `${parentKey}.${key}` : key;
        flattened[newKey] = obj[key];
      }
    }
    return flattened;
  }

  callRowAction(event) {
    this.catClassVal = this.isMobile
      ? event.target.value
      : event.detail.row["Product2.Product_SKU__c"];
    this.buttonVal = this.isMobile
      ? event.target.label
      : event.detail.row["buttonLabel"];

    if (this.buttonVal === "View Assets") {
      const sendValueEvent = new CustomEvent("switchtocatclass", {
        detail: {
          catClassValue: this.catClassVal,
          selectedLocationFilter: this.productItemParamObject
            .selectedLocationFilter
            ? this.productItemParamObject.selectedLocationFilter
            : "Current Branch"
        },
        bubbles: true,
        composed: true
      });
      logger.log("sendValueEvent::" + JSON.stringify(sendValueEvent));
      this.dispatchEvent(sendValueEvent);
      //FRONT-17145 - send selected row to parent container component
    } else if (this.buttonVal === "Select") {
      //started for Front-19001
      //FRONT - 19005
      if (this.isMobile) {
        let index = Number(event.currentTarget.dataset.index);
        this.selectedAssetRow = this.catClassDescDataForMobile[index];
        this.handleAssetSelectButtonClickedMobile(this.selectedAssetRow);
      }
      //ended for Front-19001
      else {
        this.selectedAssetRow = event.detail.row;
        this.handleAssetSelectButtonClicked(this.selectedAssetRow);
      }
    }
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

  //FRONT-24414
  handleBack() {
    this.hideEditorFooter = false;
    const childComponent = this.template.querySelector(
      "c-sbr_3_0_item-search-select-asset-container-cmp"
    );
    childComponent.editorDisplay = "editor show";
  }

  //FRONT-17145: handling selected item and showing the details to editor modal
  handleAssetSelectButtonClicked(selectedRow) {
    if (selectedRow.buttonLabel === "Select") {
      this.modalHeader = `Asset # ${selectedRow["Product2.itemNumberUsedByReservationsRentalOut__c"]}`;
    } /* else {
      this.modalHeader = `Asset # ${selectedRow.Name}`;
    }*/
    this.refs.selectedAssetContainerModal.toggleModal();
  }

  //FRONT - 19005
  handleAssetSelectButtonClickedMobile(selectedRow) {
    this.modalHeader =
      "Asset # " +
      selectedRow.Product2.itemNumberUsedByReservationsRentalOut__c;
    this.isEditorRateShow = true;
  }

  //FRONT-17145/16637: Create Order Item record
  handleConfirm = () => {
    let orderItmObjRef = this.refs.orderItemObject;
    let stagedOrderItmRecord = orderItmObjRef.getUpdatedOrderItem();
    this.createOrderItemRecord(stagedOrderItmRecord);
  };

  //FRONT-17145/16637: Creating Order Item record on click of Confirm button from editor modal
  createOrderItemRecord(orderItemProp) {
    //FRONT-33324
    this.showSpinner = false;
    if (!this.isMobile) {
      this.refs.selectedAssetContainerModal.toggleModal();
    }
    let orderItemObjectFields = {
      OrderId: this.recordId,
      Product2Id: this.selectedAssetRow.Product2Id,
      Quantity: orderItemProp?.itemQty,
      UnitPrice: 0,
      Line_Comments__c: orderItemProp?.lineItemNotes,
      Discount_Percentage__c: orderItemProp?.rateDiscount,
      Min_Rate__c: orderItemProp?.minRate,
      Hourly_Rate__c: orderItemProp?.minRate,
      Daily_Rate__c: orderItemProp?.day,
      Weekly_Rate__c: orderItemProp?.week,
      Monthly_Rate__c: orderItemProp?.fourWeek,
      Suggested_Minimum_Rate__c: orderItemProp?.suggestedMinRate,
      Suggested_Daily_Rate__c: orderItemProp?.suggestedDailyRate,
      Suggested_Weekly_Rate__c: orderItemProp?.suggestedWeeklyRate,
      Suggested_Monthly_Rate__c: orderItemProp?.suggestedMonthlyRate,
      Suggested_Hourly_Rate__c: orderItemProp?.suggestedMinRate,
      is_User_Added__c: orderItemProp?.isUserAdded
    };
    //20232
    const recordInput = orderItemObjectFields;
    recordInput.sobjectType = "OrderItem";
    createOrderItem({
      record: recordInput,
      allowDuplicateRule: false
    })
      .then((response) => {
        logger.log("OrderItem created with Id: " + JSON.stringify(response));
        if (!this.isMobile) {
          //this.refs.selectedAssetContainerModal.toggleModal();
          this.updateButtonLabel();
        } else {
          //FRONT - 19005;
          this.isEditorRateShow = false;
          this.updateButtonLabelMobile();
        }

        // FRONT-25706
        const newEvent = new ShowToastEvent({
          title: "",
          message: this.modalHeader + " has been added to the contract",
          variant: "success"
        });
        this.dispatchEvent(newEvent);
        const messagePayload = {
          origin: "rentalLineItems",
          action: "refresh"
        };
        publish(this.messageContext, lineItemUpdate, messagePayload);
      })
      .catch((error) => {
        logger.log(
          "error in create Order Item:",
          JSON.stringify(error.body),
          error.status,
          error.statustext
        );
      })
      //FRONT-33324
      .finally(() => {
        this.showSpinner = true;
        // this.isMobileLoading = false;
      });
  }

  //FRONT-16637/17145: Update button label after OrderItem created
  updateButtonLabel() {
    let updatedResult = [];
    if (this.result) {
      let tempResult = JSON.parse(JSON.stringify(this.result));
      tempResult.forEach((item) => {
        if (
          item["Product2.Bulk_Item__c"] &&
          item["Product2.Id"] === this.selectedAssetRow.Product2Id
        ) {
          item = {
            ...item,
            buttonLabel: "Remove",
            buttonVariant: "brand-outline"
          };
        }
        updatedResult.push(item);
      });
      this.result = [...updatedResult];
    }
  }

  //FRONT - 19005
  updateButtonLabelMobile() {
    let updatedResult = [];
    let tempResult = JSON.parse(JSON.stringify(this.catClassDescDataForMobile));
    tempResult.forEach((item) => {
      if (
        item.Product2.Bulk_Item__c &&
        item.Product2Id === this.selectedAssetRow.Product2Id
      ) {
        item = {
          ...item,
          showRemoveButton: true
        };
      }
      updatedResult.push(item);
    });
    this.catClassDescDataForMobile = [...updatedResult];
  }

  //on modal close resetting the selected Asset row variable
  handleCloseModal() {
    //Added for Front-19001
    if (this.isMobile) {
      this.isEditorRateShow = false;
    } else {
      this.selectedAssetRow = null;
    }
  }

  // START FRONT-15699 & FRONT-17146 : To implement lazy loading
  loadMoreDataHandler(event) {
    if (this.checkHandleLoadMoreOnce) {
      logger.log("+++loadMoreDataHandler calledd");
      const { target } = event;
      target.isLoading = true;
      this.rowOffSet = this.rowOffSet + this.rowLimit;
      this.productItemParamObject = {
        ...this.productItemParamObject,
        searchKey: this.searchKey,
        itemListSearchKey: this.itemListSearchKey, // FRONT-17146
        selectedLocationFilter: this.selectedLocationFilter,
        contractId: this.recordId,
        limitSize: this.rowLimit,
        offset: this.rowOffSet
      };
      this.fetchData();
    }
    this.checkHandleLoadMoreOnce = true;
  }
  // END FRONT-15699 & FRONT-17146

  //FRONT-17146
  get isDataAvailable() {
    return !isEmpty(this.result);
  }

  get isDataAvailableMobile() {
    return isEmpty(this.catClassDescDataForMobile);
  }

  //FRONT-17146
  get isCatClassDataAvailable() {
    logger.log("isCatClassDataAvailable", this.searchKey);
    return this.searchKey !== "" && this.searchKey !== undefined;
  }

  handleViewAssetMobile(event) {
    logger.log("title:::" + event.target.label);
  }

  /*handleCloseButtonClick = () => {
    this.refs.selectedAssetContainerModal.toggleModal();
    this.handleCloseModal();
  };*/

  handleChange(event) {
    this.isDisable = event.detail;
  }
  //Modified as part of fFRONT-10855
  handleCancel() {
    this.refs.selectedAssetContainerModal.toggleModal();
    this.handleCloseModal();
  }
  @wire(MessageContext)
  messageContext;
}