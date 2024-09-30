import { LightningElement, api, track, wire } from "lwc";
import FORM_FACTOR from "@salesforce/client/formFactor";
import { Logger } from "c/sbr_3_0_frontlineUtils";
import getAssetListcatclass from "@salesforce/apex/SBR_3_0_AssetController.getFilteredAssetsCatClass";
import { loadStyle } from "lightning/platformResourceLoader";
import FrontLineCSS from "@salesforce/resourceUrl/FrontLinesCSS";
//Added as part of FRONT-18174
import DESKTOPTEMPLATE from "./desktop.html";
import MOBILETEMPLATE from "./mobile.html";
import { isEmpty } from "c/sbr_3_0_frontlineUtils";
import noContentSvg from "@salesforce/resourceUrl/NoContentSVG";
import LABELS from "c/sbr_3_0_customLabelsCmp";
import getProductItemList from "@salesforce/apex/SBR_3_0_AssetController.getProductItemList"; //FRONT-19000
import deleteOrderItem from "@salesforce/apex/SBR_3_0_AssetController.deleteOrderItem"; //FRONT-19006
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import createOrderItem from "@salesforce/apex/SBR_3_0_DMLOpsController.createSObject"; //20232

import {
  publish,
  subscribe,
  unsubscribe,
  APPLICATION_SCOPE,
  MessageContext
} from "lightning/messageService";
import lineItemUpdate from "@salesforce/messageChannel/sbr_3_0_contractLineItemsUpdate__c";

const logger = Logger.create(true);
const CATCLASS_FILTER_TABLE_COLUMNS = [
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
export default class Sbr_3_0_itemSearchAssetsCatClassCmp extends LightningElement {
  columns = CATCLASS_FILTER_TABLE_COLUMNS;
  productRowsOffset = 0;
  filterYear;
  @track isMobileLoading;
  @api recordId;
  @api orderData;
  @api brachLocation;
  rowLimit = 100;
  isMobile = false;
  selecetdStatusList;
  @track result; //FRONT 19000
  @track isAssetFlag = false;
  @track selectedAssetRow;
  activeTab = "CatClass";
  hideEditorFooter = false;
  assetIdToOrderItems = {};
  noContentimageUrl = noContentSvg;
  LABELS = LABELS;
  noCatContentLabel = LABELS.NOCONTENT_LABEL;
  inventorySize = 0;
  showEditorRate = false; //18999
  defaultSortDirection = "asc";
  sortDirection = "asc";
  sortedBy;
  // FRONT-15702
  @track selectedCatClassVal = "";
  selectedLocationFilter = "";
  searchKey = "";
  loc = "";
  showSpinner = false;
  @track catClassDataForMobile = []; //FRONT 19000
  productIdToOrderItems = {}; //FRONT 19000
  @track customClass = "brand-button remove-button";
  mobileProps = {
    zIndex: 9004,
    variant: "static"
  };

  connectedCallback() {
    if (FORM_FACTOR === "Small") {
      this.isMobile = true;
    }
  }
  @api
  catClassFilter(catClassVal, locationFilter) {
    // FRONT-15702
    this.productRowsOffset = 0;
    this.result = [];
    this.catClassDataForMobile = [];
    this.showSpinner = true;
    logger.log("catClassVal-> " + catClassVal);
    this.selectedCatClassVal = catClassVal;
    this.selectedLocationFilter = locationFilter;
    this.loadCatClassFilterOnLoadMore();
  }

  // FRONT-15702
  loadCatClassFilterOnLoadMore() {
    //called on click of View Asset from Cat class description tab
    if (this.isMobile) {
      this.searchKey = this.selectedCatClassVal;
    }
    logger.log("selectedCatClassVal-> " + this.selectedCatClassVal);
    this.isAssetFlag = true; //isAssetFlag used to track whether we are showing Asset list or product Item list
    let assetListParamObject = {
      actvTab: "CatClass",
      catClass: this.selectedCatClassVal,
      statusList: this.selecetdStatusList,
      offset: this.productRowsOffset,
      year: this.filterYear,
      contractId: this.recordId,
      selectedLocation: this.selectedLocationFilter,
      //selectedLocation: "",
      loc: this.loc,
      searchKey: this.searchKey
      // searchKey: this.selectedCatClassVal
    };
    logger.log("assetListParamObject", JSON.stringify(assetListParamObject));
    getAssetListcatclass({
      params: assetListParamObject
    })
      .then((data) => {
        logger.log(
          "result of apex from loadCatClassFilterOnLoadMore:- " +
            JSON.stringify(data)
        );
        if (!this.isMobile) {
          if (data && data.length > 0) {
            this.showSpinner = false;
            let oldData = this.result ? this.result : [];
            this.processCatClassTabResult(data);
            this.flattenedData(data);
            if (oldData.length > 0) {
              let updatedRecords = [...oldData, ...this.result];
              this.result = updatedRecords;
            }
            const lightningDatatable = this.template.querySelector(
              "c-sbr_3_0_custom-data-table-cmp"
            );
            if (data.length === this.rowLimit) {
              lightningDatatable.enableInfiniteLoading = true;
            } else {
              lightningDatatable.enableInfiniteLoading = false;
            }
            lightningDatatable.isLoading = false;
          } else {
            this.showSpinner = false;
            const lightningDatatable = this.template.querySelector(
              "c-sbr_3_0_custom-data-table-cmp"
            );
            lightningDatatable.enableInfiniteLoading = false;
            lightningDatatable.isLoading = false;
          }
        } else {
          this.processCatClassTabResult(data);
          this.flattenedData(data);
        }
        //this.processCatClassTabResult(this.result);
        this.inventorySize = this.result.length;
      })
      .catch((error) => {
        console.error("Error Cat Class Filter: ", JSON.stringify(error));
      });
  }

  flattenedData(data) {
    this.showNoContentImage = false;
    this.result = data.map((item) => {
      let buttonLabel = "Select";
      if (this.assetIdToOrderItems && this.assetIdToOrderItems[item.Id]) {
        buttonLabel = "Remove";
        this.isMobileLoading = false;
      }
      let buttonVariant =
        buttonLabel === "Select" ? "brand" : "brand-outline remove-button";
      return {
        ...item,
        StatusDisabled: !(
          item.Status === "AVAILABLE" &&
          item.SM_PS_Current_Branch_Location_Number__c === this.brachLocation
        ),
        calculatedBtnVariable: buttonLabel,
        calculatedBtnVariant: buttonVariant,
        ViewMore: false,
        HideComments: false
      };
    });
    this.isMobileLoading = false;
  }

  flattenedDataBulk(data) {
    //FRONT-19006
    this.catClassDataForMobile = data.map((item) => {
      let showRemoveBtn = false;
      if (
        this.productIdToOrderItems &&
        this.productIdToOrderItems[item.Product2.Id]
      ) {
        showRemoveBtn = true;
        this.isMobileLoading = false;
      }
      return {
        ...item,
        showRemoveButton: showRemoveBtn
      };
    });
    this.isMobileLoading = false;
  }
  renderedCallback() {
    Promise.all([loadStyle(this, FrontLineCSS)])
      .then(() => {
        console.log("Files loaded");
      })
      .catch((error) => {});
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

  //FRONT-16637: create map of assetId to orderitems list
  processCatClassTabResult(assetData) {
    if (assetData) {
      assetData.forEach((item) => {
        if (item.SBQQ__OrderProducts__r) {
          this.assetIdToOrderItems[item.Id] = item.SBQQ__OrderProducts__r;
        }
      });
    }
  }
  callRowAction(event) {
    //FRONT - 15702
    //Started for Front-18999
    this.buttonVal = event.target.label;
    let assetId = event.target.dataset.assetId;
    let productId = event.target.dataset.productId;
    console.log(' this.assetIdToOrderItems[event.target.dataset.assetId]', JSON.stringify(this.assetIdToOrderItems));
	  console.log('AssetId', assetId);
    if (this.isMobile) {
      if (this.buttonVal === "Remove") {
        this.isMobileLoading = true;
        if (
          this.isAssetFlag &&
          this.assetIdToOrderItems &&
          this.assetIdToOrderItems[event.target.dataset.assetId]
        ) {
          let removeOrderItemId =
            this.assetIdToOrderItems[event.target.dataset.assetId][0].Id;
          deleteOrderItem({ orderItemId: removeOrderItemId })
            .then((result) => {
              delete this.assetIdToOrderItems[assetId]; //Removing Key value pair from this map
              this.flattenedData(this.result);
              let deletedAssetObj = this.result.find(
                (obj) => obj.Id === assetId
              );
              let obj = {
                detail: {
                  title: "",
                  message:
                    "Asset #" +
                    deletedAssetObj.Name +
                    " has been removed from the contract.",
                  variant: "success",
                  mode: "sticky"
                }
              };
              this.showToastNotification(obj);
              this.isMobileLoading = false;
            })
            .catch((error) => {
              console.log("Error is" + JSON.stringify(error));
              this.isMobileLoading = false;
            });
        } else if (
          !this.isAssetFlag &&
          this.productIdToOrderItems &&
          this.productIdToOrderItems[productId]
        ) {
          deleteOrderItem({
            orderItemId: this.productIdToOrderItems[productId][0].Id
          })
            .then((result) => {
              delete this.productIdToOrderItems[productId]; //Removing Key value pair from this map
              this.flattenedDataBulk(this.catClassDataForMobile);
              let deletedProductObj = this.catClassDataForMobile.find(
                (obj) => obj.Product2.Id === productId
              );
              let obj = {
                detail: {
                  title: "",
                  message:
                    "Asset # " +
                    deletedProductObj.Product2
                      .itemNumberUsedByReservationsRentalOut__c +
                    " has been removed from the contract.",
                  variant: "success",
                  mode: "sticky"
                }
              };
              this.showToastNotification(obj);
              this.isMobileLoading = false;
            })
            .catch((error) => {
              console.log("Error is" + JSON.stringify(error));
              this.isMobileLoading = false;
            });
        }
      } else {
        if (this.result) {
          // Asset list from Cat Class Description tab
          const rows = this.result;
          const rowIndex = rows.findIndex(
            (r) => r.Id === event.target.dataset.assetId
          );
          let selectedRecord = rows[rowIndex];
          this.selectedAssetRow = selectedRecord;
          this.modalHeader = `Asset # ${selectedRecord.Name}`;
          this.showEditorRate = true;
        } else {
          //Product Item list from Cat class tab
          let index = Number(event.currentTarget.dataset.index);
          this.selectedAssetRow = this.catClassDataForMobile[index];
          if (this.buttonVal === "Select") {
            this.handleAssetSelectButtonClicked(this.selectedAssetRow);
          } else if (this.buttonVal === "View Assets") {
            this.selectedCatClassVal =
              this.selectedAssetRow.Product2.Product_SKU__c;
            this.searchAssetRecords(this.selectedAssetRow);
          }
        }
        //this.showEditorRate = true;
      }
    }
    //Ended for Front-18999
    else {
        this.selectedAssetRow = event.detail.row;
        this.handleAssetSelectButtonClicked(this.selectedAssetRow);
      }
    }

  searchAssetRecords(selectedRow) {
    //asset initial load on click of View Asset in Cat Class tab
    this.isAssetFlag = true;
    let assetListParamObject;
    this.selectedCatClassVal = selectedRow?.Product2?.Product_SKU__c;
    assetListParamObject = {
      actvTab: "CatClass",
      catClass: selectedRow?.Product2?.Product_SKU__c,
      searchKey: "",
      statusList: [],
      year: "",
      loc: "",
      contractId: this.recordId,
      selectedLocation: this.productItemParamObject.selectedLocationFilter
        ? this.productItemParamObject.selectedLocationFilter
        : "Current Branch",
      offset: null
    };
    this.getAssetListRecords(assetListParamObject);
  }

  getAssetListRecords(assetListParamObject) {
    getAssetListcatclass({ params: assetListParamObject })
      .then((data) => {
        this.selectedCatClassVal = assetListParamObject.catClass;
        logger.log("result of apex :- " + JSON.stringify(data));
        this.catClassDataForMobile = [];
        this.processCatClassTabResult(data);
        this.flattenedData(data);
        this.inventorySize = data.length;
        logger.log(" final result*  :- " + JSON.stringify(data));
        this.selectedCatClassVal = assetListParamObject.catClass;
      })
      .catch((error) => {
        logger.log("Error is " + JSON.stringify(error));
      });
  }

  handleAssetSelectButtonClicked(selectedRow) {
    if (!this.isMobile) {
      this.modalHeader = `Asset # ${selectedRow.Name}`;
      this.refs.selectedAssetContainerModal.toggleModal();
    } else {
      this.modalHeader = `Asset # ${selectedRow?.Product2?.itemNumberUsedByReservationsRentalOut__c}`;
      this.showEditorRate = true;
    }
  }
  //FRONT-17145/16637: Create Order Item record
  handleConfirm = () => {
    this.isMobileLoading = true;
    let orderItmObjRef = this.refs.orderItemObject;
    let stagedOrderItmRecord = orderItmObjRef.getUpdatedOrderItem();
    this.createOrderItemRecord(stagedOrderItmRecord);
    // this.customClass = this.customClass + "remove-button";
    // FRONT-19002
    if (this.isMobile && this.isAssetFlag) {
      this.showEditorRate = false;
    }
  };

  //FRONT-17145/16637: Creating Order Item record on click of Confirm button from editor modal
  createOrderItemRecord(orderItemProp) {
    //FRONT-33324
    if (!this.isMobile && this.isAssetFlag) {
      // FRONT-19002
      this.refs.selectedAssetContainerModal.toggleModal();
    }
    this.showSpinner = true;
    this.isMobileLoading = true;

    let orderItemObjectFields = {
      OrderId: this.recordId,
      Product2Id: this.selectedAssetRow.Product2Id,
      Quantity: orderItemProp?.itemQty,
      UnitPrice: 0,
      SBQQ__Asset__c: this.isAssetFlag ? this.selectedAssetRow.Id : "",
      Line_Comments__c: orderItemProp?.lineItemNotes,
      Discount_Percentage__c: orderItemProp?.rateDiscount,
      Min_Rate__c: orderItemProp?.minRate,
      Hourly_Rate__c: orderItemProp?.minRate,
      Daily_Rate__c: orderItemProp?.day,
      Weekly_Rate__c: orderItemProp?.week,
      Monthly_Rate__c: orderItemProp?.fourWeek,
      Meter_Reading_Out__c: orderItemProp?.hourMeterReading, //FRONT-29160
      Suggested_Minimum_Rate__c: orderItemProp?.suggestedMinRate,
      Suggested_Daily_Rate__c: orderItemProp?.suggestedDailyRate,
      Suggested_Weekly_Rate__c: orderItemProp?.suggestedWeeklyRate,
      Suggested_Monthly_Rate__c: orderItemProp?.suggestedMonthlyRate,
      Suggested_Hourly_Rate__c: orderItemProp?.suggestedHourlyRate,
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
        if (this.isAssetFlag) {
          // if (!this.isMobile) {
          //   // FRONT-19002
          //   this.refs.selectedAssetContainerModal.toggleModal();
          // }
          this.updateButtonLabel(response.attributes.record.Id);
          let obj = {
            detail: {
              title: "",
              message:
                "Asset " +
                this.selectedAssetRow.Name +
                " has been added to the contract.",
              variant: "success",
              mode: "sticky"
            }
          };
          this.showToastNotification(obj);
        } else if (!this.isAssetFlag && this.isMobile) {
          // this.isMobileLoading = false;
          this.showEditorRate = false;
          let obj = {
            detail: {
              title: "",
              message: this.modalHeader + " has been added to the contract.",
              variant: "success",
              mode: "sticky"
            }
          };
          this.showToastNotification(obj);
          this.updateButtonLabelMobile(response.attributes.record.Id);
        }
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
        // setTimeout(() => {

        // }, 3000);

        this.showSpinner = false;
        this.isMobileLoading = false;
      });
  }

  updateButtonLabelMobile(orderItemId) {
    let updatedResult = [];
    let tempResult = JSON.parse(JSON.stringify(this.catClassDataForMobile));
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

    let OrderItem = [{ Id: orderItemId }];
    this.productIdToOrderItems[this.selectedAssetRow.Product2Id] = OrderItem;
    this.catClassDataForMobile = [...updatedResult];
  }
  //FRONT-16637/17145: Update button label after OrderItem created
  updateButtonLabel(orderItemId) {
    this.assetIdToOrderItems[this.selectedAssetRow.Id] = [
      {
        SBQQ__Asset__c: this.selectedAssetRow.Id,
        Id: orderItemId
      }
    ];
    this.flattenedData(this.result);
  }
  //on modal close resetting the selected Asset row variable
  handleCloseModal() {
    this.selectedAssetRow = null;
  }
  get isDataAvailable() {
    return !isEmpty(this.result);
  }

  get isProductsAvailable() {
    return !isEmpty(this.catClassDataForMobile);
  }

  handleSearchCriteriaChange(event) {
    this.productRowsOffset = 0;
    this.result = [];
    this.catClassDataForMobile = [];
    this.showSpinner = true;
    if (!this.isMobile) {
      this.selectedLocationFilter = event.detail.selectedLocation;
      this.searchKey = event.detail.searchKey;
      this.loc = event.detail.loc;
      this.filterYear = event.detail.year;
      this.selecetdStatusList = event.detail.statusList;
      this.loadCatClassFilterOnLoadMore();
    }
    if (!event.detail.searchKey && this.isMobile) {
      this.isAssetFlag = false;
      this.inventorySize = 0;
      this.productItemParamObject = {};
    }
    logger.log("isAssetList", this.isAssetFlag);
    if (this.isAssetFlag && this.isMobile) {
      this.getAssetRecords(event);
    } else if (
      this.isMobile &&
      !this.isAssetFlag &&
      event.detail.searchKey !== ""
    ) {
      this.rowOffSet = 0;
      this.inventorySize = 0;
      this.getProductItems(event);
    }
  }

  getProductItems(event) {
    this.itemListSearchKey = event.detail.itemListSearchKey;
    this.productItemParamObject = {
      searchKey: event.detail.searchKey,
      itemListSearchKey: this.itemListSearchKey,
      selectedLocationFilter: event.detail.selectedLocation,
      contractId: this.recordId,
      limitSize: this.rowLimit,
      offset: this.rowOffSet,
      actvTab: "Cat Class"
    };
    logger.log(
      "productItemParamObject",
      JSON.stringify(this.productItemParamObject)
    );
    this.result = null;
    this.fetchData();
  }
  getAssetRecords(event) {
    //on filter change
    let assetListParamObject;
    assetListParamObject = {
      actvTab: "CatClass",
      catClass: event.detail.selectedCatClassVal,
      searchKey: "",
      statusList: event.detail.statusList,
      year: event.detail.year,
      loc: event.detail.loc,
      contractId: event.detail.contractId,
      selectedLocation: event.detail.selectedLocation,
      offset: null
    };
    this.getAssetListRecords(assetListParamObject);
    logger.log("Changing input");
  }

  fetchData() {
    //FRONT-19000
    getProductItemList({ params: this.productItemParamObject })
      .then((data) => {
        if (data && data.length > 0) {
          this.inventorySize = this.inventorySize + data.length;
          logger.log("Product Item data", JSON.stringify(data));
          this.processResult(data);
        } else {
          this.inventorySize = 0;
          if (!this.itemListSearchKey) {
            this.result = [];
            this.catClassDataForMobile = [];
          }
        }
      })
      .catch((error) => {
        logger.log(
          "error in -- Sbr_3_0_itemSearchAssetsCatClassCmp" +
            JSON.stringify(error)
        );
        this.result = [];
      });
  }

  processResult(productItemData) {
    //FRONT-19000
    let productItems = [];
    if (productItemData) {
      productItemData.forEach((item) => {
        productItems.push(item.productItem);
        this.productIdToOrderItems[item.productItem.Product2Id] =
          item.orderItems;
      });
    }
    this.catClassDataForMobile = productItems;
    this.flattenedDataBulk(this.catClassDataForMobile);
  }

  toggleViewContent(event) {
    let currentAssetId = event.target.dataset.assetId;
    let toggleType = event.target.dataset.toggleType;
    //Added as part of FRONT-18174
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
  get computedMainDivClass() {
    return this.isCatClassTab
      ? "slds-grid slds-wrap bgcolor"
      : "slds-grid slds-wrap";
  }
  //started for Front-18999
  handleCancel() {
    this.showEditorRate = false;
  }
  //FRONT-24414
  handleTabClicked(event) {
    this.hideEditorFooter = event.detail.ratematrix;
  }
  //Ended for Front-18999

  handleApplyStatus(event) {
    this.processCatClassTabResult(event.detail.value);
    this.flattenedData(event.detail.value);
  }

  handleOnSort(event) {
    const { fieldName: sortedBy, sortDirection } = event.detail;
    const cloneData = [...this.result];
    cloneData.sort(this.sortBy(sortedBy, sortDirection === "asc" ? 1 : -1));
    this.result = cloneData;
    this.sortDirection = sortDirection;
    this.sortedBy = sortedBy;
  }
  //FRONT-24414
  handleBack() {
    this.hideEditorFooter = false;
    const childComponent = this.template.querySelector(
      "c-sbr_3_0_item-search-select-asset-container-cmp"
    );
    childComponent.editorDisplay = "editor show";
  }

  sortBy(field, reverse, primer) {
    logger.log("inside sortby");
    const key = primer
      ? function (x) {
          return primer(x[field]);
        }
      : function (x) {
          return x[field];
        };

    return function (a, b) {
      a = key(a);
      b = key(b);
      return reverse * ((a > b) - (b > a));
    };
  }
  get fieldsTitleClass() {
    return this.activeTab === "CatClass" ? "fieldsTitle" : "title";
  }

  // FRONT-15702
  handleSwitchToDescription() {
    this.selectedCatClassVal = "";
    //Added for Front-28032
    if (this.activeTab === "CatClass") {
      //FRONT-19000
      this.result = [];
      this.catClassDataForMobile = [];
      this.inventorySize = 0;
      this.isAssetFlag = false; // FRONT-19000
      //started for 28032
      this.filterYear = "";
      this.selecetdStatusList = [];
      this.loc = "";
      this.productItemParamObject = {};
    }
  }

  // FRONT-15702
  loadMoreData(event) {
    const { target } = event;
    target.isLoading = true;
    this.productRowsOffset = this.productRowsOffset + this.rowLimit;
    this.loadCatClassFilterOnLoadMore();
  }
  //FRONT-26612 Modified as part of fFRONT-10855
  handleCancelButtonClick() {
    this.refs.selectedAssetContainerModal.toggleModal();
    this.handleCloseModal();
  }

  showToastNotification(event) {
    const newEvent = new ShowToastEvent({
      title: event.detail.title,
      message: event.detail.message,
      variant: event.detail.variant,
      mode: event.detail.mode
    });
    this.dispatchEvent(newEvent);
  }

  //FRONT-30359
  get labelTextForSearchField() {
    let searchkey =
      this.productItemParamObject != undefined &&
      !isEmpty(
        JSON.parse(JSON.stringify(this.productItemParamObject)).searchKey
      )
        ? JSON.parse(JSON.stringify(this.productItemParamObject)).searchKey
        : "";

    return isEmpty(searchkey)
      ? LABELS.NOCONTENT_LABEL
      : LABELS.NO_CAT_CLASS_FOUND_FOR_CONTRACT_ITEM_SEARCH;
  }
  
  @wire(MessageContext) //FRONT-31105
  messageContext;
}