//  FRONT-2186, FRONT-6226, FRONT-6227, FRONT-6228, FRONT-7403
import { LightningElement, api, track, wire } from "lwc";
import { updateRecord } from "lightning/uiRecordApi";
import sbr_3_0_AssignAssetTableComponentDesktop from "./sbr_3_0_AssignAssetTableComponentDesktop.html";
import sbr_3_0_AssignAssetTableComponentMobile from "./sbr_3_0_AssignAssetTableComponentMobile.html";
import getFilteredAssets from "@salesforce/apex/SBR_3_0_CustomDataTableCmpController.getFilteredAssets";
import getFilteredAssetsOtherLocations from "@salesforce/apex/SBR_3_0_CustomDataTableCmpController.getFilteredAssetsOtherLocations";
import noContentSvg from "@salesforce/resourceUrl/NoContentSVG";
import LABELS from "c/sbr_3_0_customLabelsCmp";
import FORM_FACTOR from "@salesforce/client/formFactor";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { Logger } from "c/sbr_3_0_frontlineUtils";
import getLocationInfo from "@salesforce/apex/SBR_3_0_SpotlightPanelCmpController.getProfileBranchChronosDetails";
import deselectProductRowChannel from "@salesforce/messageChannel/deselectProductRowChannel__c";
import {
  subscribe,
  unsubscribe,
  APPLICATION_SCOPE,
  MessageContext,
  publish
} from "lightning/messageService";
const DEFAULT_FILTERING_FIELDS = ["Product2.Name", "SM_PS_Equipment_Number__c"];
const JOIN_AND_CLAUSE = " AND ";
const JOIN_OR_CLAUSE = " OR ";
const logger = Logger.create(true);
export default class Sbr_3_0_AssignAssetTableComponent extends LightningElement {
  isMobile;
  @api originrecordid;
  @api productId;
  @api parentId; //Added as part of FRONT-7416
  @api orderItemId; //Added as part of FRONT-7416
  @api locationInfo;
  @api objectApiName;
  preSelectedRows = [];
  mapAssetvsProdId;
  selectedRowList = [];
  //FRONT-11320,FRONT-11322 part
  @wire(MessageContext)
  messageContext;
  //7419-Start
  //to check current tab on Assign Asset modal
  @api currentTabName;
  //7419-End
  offset = 0;
  AssignedAsset = false;
  batchSize = 50;
  loadMoreStatus;
  targetDatatable;
  whereClause = "";
  @track inventoryCount;
  @track wiredAsset = [];
  _searchKey;
  selectedStatus = [];
  selctedprodvalue;
  noContentimageUrl = noContentSvg;
  selectedmultivalues = LABELS.SBR_3_0_AssetStatusPicklistValues;

  @track isDataLoaded = false;
  showAssetDetials = false;

  openViewAssetModal = false;
  selectedAssetId = "";
  selectedDesc;
  assetspotlightcmp = false;

  sourcingBranchOffset = 0;
  otherBranchOffset = 0;

  /*FRONT-8711 : Variables for UI*/
  noOtherLocationsFoundErrorMessage;
  noDefaultLocationsFoundErrorMessage;
  isDefaultLocationTab;
  isOtherLocationTab;
  /*END : FRONT-8711*/

  //FRONT-8712 start
  walkthroughNotAvailable = LABELS.WALKTHROUGH_NOT_AVAILABLE;
  @track searchItem = true;
  @track noLocationFoundMessage = LABELS.WALKTHROUGH_NOT_AVAILABLE_NO_LOCATION;
  //FRONT-8712 end
  /*Added as part of FRONT-10330*/
  showViewAssetDetails = false;
  isItemSearchAssetsTab = false;
  /* FRONT-10330 Ends*/
  get searchKey() {
    return this._searchKey;
  }

  set searchKey(key) {
    this._searchKey = key;
    this.whereClause = this.buildDefaultQuery();
  }

  get productFilterClause() {
    if (this.currentTabName === "itemsearchassets") {
      return "";
    }
    return `Product2Id ='${this.productId}'`;
  }

  get defaultStatusFilterClause() {
    let regex = /,/g;

    let str = this.selectedmultivalues;
    let res = str.replace(regex, "','");
    if (this.currentTabName === "itemsearchassets") {
      return " (Status IN ('" + res + "') OR Status ='')";
    }

    return "  AND (Status IN ('" + res + "') OR Status ='')";
  }

  //FRONT-7415
  columns = [
    {
      label: "Current Location",
      fieldName: "Current_Location_Number__c",
      type: "text",
      editable: false,
      wrapText: true
    },
    {
      label: "Asset Number", //Modified as Part of FRONT-13026
      fieldName: "SM_PS_Equipment_Number__c",
      // type: { fieldName: "assetType" }, //Modified as part of FRONT-10327, 10328
      editable: false,
      type: "button",
      fieldName: "assetType",
      editable: false,
      wrapText: true,
      cellAttributes: {
        class: { fieldName: "linkColor" }
      },
      typeAttributes: {
        label: { fieldName: "SM_PS_Equipment_Number__c" },
        fieldName: "SM_PS_Equipment_Number__c",
        name: "view_assign_asset",
        target: "_blank",
        variant: "base"
      }
    },
    {
      label: "Status",
      fieldName: "Status",
      type: "text",
      editable: false,
      wrapText: true
    },
    {
      label: "Description",
      initialWidth: 300,
      fieldName: "Description",
      type: "text",
      editable: false,
      wrapText: true
    },
    {
      label: "Last transaction",
      initialWidth: 200,
      fieldName: "SM_PS_Last_Transaction_Date__c",
      type: "date",
      editable: false,
      wrapText: true,
      typeAttributes: { month: "2-digit", day: "2-digit", year: "numeric" }
    },
    {
      type: "button",
      initialWidth: 105,
      typeAttributes: {
        label: { fieldName: "buttonValue" },
        name: { fieldName: "buttonValue" },
        title: { fieldName: "buttonValue" },
        disabled: false,
        value: { fieldName: "buttonValue" },
        variant: { fieldName: "buttonVariant" }
      }
    }
  ];

  async connectedCallback() {
    if (!this.locationInfo) {
      this.locationInfo = await getLocationInfo({
        objectId: null,
        objectApiName: null
      });
    }

    //START: FRONT-20882
    //when this component is calling from sbr_3_0_itemSearchCtrCmp we are getting locationInfo without "branch" node
    //and when its called from sbr_3_0_AssignAssetModalComponent locationInfo comes with "branch" node, so removing "branch" node
    //from locationInfo before its been used
    if (this.locationInfo && this.locationInfo.branch) {
      this.locationInfo = this.locationInfo.branch;
    }
    //END: FRONT-20882

    this.subscribeToMessageChannel();
    // this.resetNoAssetFoundMessages();
    let defaultLocationClause = "";
    
    if (this.currentTabName === "defaultlocation") {
      defaultLocationClause = ` AND SM_PS_Current_Branch_Location_Number__c = '${this.locationInfo?.Branch_Location_Number__c}' `;
    }
    this.isMobile = FORM_FACTOR === "Small";

    //START: FRONT-10327, 10328 - for item search tab we need to fetch all Assets so avoiding ProductId filter
    if (this.currentTabName !== "itemsearchassets") {
      this.whereClause = `${this.productFilterClause}`;
    }
    //END: FRONT-10327, 10328

    if (this.currentTabName === "itemsearchassets") {
      let locationClause = ` AND SM_PS_Market_Name__c =  '${this.locationInfo?.Market_Name__c}' `; //added as a part of Front-20343
      defaultLocationClause = locationClause;
    }
    this.whereClause += this.defaultStatusFilterClause + defaultLocationClause;
    logger.log("===this.whereClause===", this.whereClause);

    if (this.currentTabName === "defaultlocation") {
      this.getFilterAssetsResult(this.whereClause);
    } else if (this.currentTabName === "otherlocation") {
      this.getFilteredAssetsOtherLocation(this.whereClause, "true");
      //START: FRONT-10327,FRONT-10330,FRONT-10328
    } else if (this.currentTabName === "itemsearchassets") {
      this.isItemSearchAssetsTab = true;
      this.handleItemSearchAssetTabView();
    }
    //END: FRONT-10327 ,FRONT-10330, FRONT-10328
  }

  //START: FRONT-10327, 10328
  handleItemSearchAssetTabView() {
    //need to remove Assign/Remove button from the last column
    this.columns.pop();
    this.getFilterAssetsResult(this.whereClause);
  }
  //END: FRONT-10327, 10328

  hasRendered = true;
  renderedCallback() {
    if (this.hasRendered) {
      const baseTableEle = this.template.querySelector("lightning-datatable");
      if (baseTableEle) {
        baseTableEle.enableInfiniteLoading = true;
      }
      this.hasRendered = false;
    }
  }

  handleSearch(event) {
    const baseTableEle = this.template.querySelector("lightning-datatable");
    if (baseTableEle) {
      baseTableEle.enableInfiniteLoading = true;
    }

    let data = event.detail;
    this.offset = 0;
    this.searchKey = data.searchKey;
    this.selectedStatus = data.selectedStatus;
    this.wiredAsset = [];
    this.whereClause = this.buildDefaultQuery();
    this.sourcingBranchOffset = 0;
    this.otherBranchOffset = 0;
    this.searchItem = data.searchItem;

    /*FRONT-8711 : Reseting the fields CSS and Assigning location Searchkey value*/
    this.locationSearchKey = data.locationSearchKey;
    this.hideSearchFieldError();
    this.hideLocationFieldError();
    /*END : FRONT-8711*/

    if (this.selectedStatus && this.selectedStatus.length > 0) {
      let statusSet = [];
      this.selectedStatus.forEach((element) => {
        if (element !== "Any Status" && element !== "Unassigned") {
          statusSet.push("'" + element + "'");
        }
      });

      if (!this.selectedStatus.includes("Any Status")) {
        if (
          this.selectedStatus.includes("Unassigned") &&
          this.selectedStatus.length > 1
        ) {
          if (this.currentTabName === "itemsearchassets") {
            //FRONT-11316,FRONT-11317
            this.whereClause +=
              "(Status IN (" + statusSet + ") OR Status ='') ";
          } else {
            this.whereClause +=
              " AND (Status IN (" + statusSet + ") OR Status ='') ";
          }
        } else if (
          this.selectedStatus.includes("Unassigned") &&
          this.selectedStatus.length === 1
        ) {
          if (this.currentTabName === "itemsearchassets") {
            //FRONT-11316,FRONT-11317
            this.whereClause += " Status ='' ";
          } else {
            this.whereClause += " AND Status ='' ";
          }
        } else {
          if (this.currentTabName === "itemsearchassets") {
            //FRONT-11316,FRONT-11317
            this.whereClause += " Status IN (" + statusSet + ")";
          } else {
            this.whereClause += " AND Status IN (" + statusSet + ")";
          }
        }
      } else {
        this.whereClause += this.defaultStatusFilterClause;
      }
    } else {
      this.whereClause += this.defaultStatusFilterClause;
    }

    if (
      data.selectedLocation &&
      this.locationInfo &&
      (this.currentTabName === "defaultlocation" ||
        this.currentTabName == "itemsearchassets")
    ) {
      let locationClause;
      let locationFilter = data.selectedLocation;
      if (locationFilter === "Source") {
        locationClause = ` SM_PS_Current_Branch_Location_Number__c = '${this.locationInfo?.Branch_Location_Number__c}' `;
      } else if (locationFilter === "Region") {
        locationClause = ` SM_PS_Region__c = '${this.locationInfo?.Region__c}' `;
      } else if (locationFilter === "District") {
        locationClause = ` SM_PS_District__c =  '${this.locationInfo?.District__c}' `;
      } else if (locationFilter === "Market") {
        locationClause = ` SM_PS_Market_Name__c =  '${this.locationInfo?.Market_Name__c}' `;
      }
      if (locationClause) this.whereClause += " AND " + locationClause;
    }
    if (data.locationSearchKey && this.currentTabName === "otherlocation") {
      this.whereClause +=
        " AND SM_PS_Current_Branch_Location_Number__c LIKE '%" +
        data.locationSearchKey +
        "%' ";
    }
    logger.log("===whereClause===", this.whereClause);
    this.isDataLoaded = false;

    if (this.currentTabName === "defaultlocation") {
      this.getFilterAssetsResult(this.whereClause);
    } else if (this.currentTabName === "otherlocation") {
      this.getFilteredAssetsOtherLocation(this.whereClause, "false");
    } else if (this.currentTabName === "itemsearchassets") {
      //need to remove Assign/Remove button from the last column
      this.getFilterAssetsResult(this.whereClause);
    }
  }

  // wire function property to fetch search record based on user input
  //Integer offset, Integer batchSize, String searchKey, String whereClause
  getFilterAssetsResult(whereCondition) {
    getFilteredAssets({
      offset: this.offset,
      batchSize: 50,
      searchKey: "",
      whereClause: whereCondition
    })
      .then((value) => {
        this.isDataLoaded = true;
        this.buildData(value);

        if (this.wiredAsset.length < 5) {
          this.inventoryCount = this.wiredAsset.length;
        } else {
          this.inventoryCount = "5+";
        }
        if (this.targetDatatable) this.targetDatatable.isLoading = false;

        if (value.length === 0) {
          const baseTableEle = this.template.querySelector(
            "lightning-datatable"
          );
          if (baseTableEle) {
            baseTableEle.enableInfiniteLoading = false;
          }
          /*FRONT-8711 : Setting Error CSS since no Assets Records found*/
          this.setNoAssetsFoundMessages();
          /*END : FRONT-8711 */
        }
      })
      .catch((error) => {
        console.error(error);
      });
  }

  //SearchKey is part of wherecondition so not sending it separately
  getFilteredAssetsOtherLocation(whereCondition, isInitialLoad) {
    getFilteredAssetsOtherLocations({
      sourcingBranchOffset: this.sourcingBranchOffset,
      otherBranchOffset: this.otherBranchOffset,
      batchSize: 50,
      searchKey: "",
      whereClause: whereCondition,
      isInitialLoad: isInitialLoad,
      locationInfo: JSON.stringify(this.locationInfo)
    })
      .then((value) => {
        this.sourcingBranchOffset = value.sourcingBranchOffset;
        this.otherBranchOffset = value.otherBranchOffset;
        this.isDataLoaded = true;
        this.buildData(value.assetList);

        if (this.wiredAsset.length < 5) {
          this.inventoryCount = this.wiredAsset.length;
        } else {
          this.inventoryCount = "5+";
        }
        if (this.targetDatatable) this.targetDatatable.isLoading = false;

        if (value.assetList.length === 0) {
          const baseTableEle = this.template.querySelector(
            "lightning-datatable"
          );
          if (baseTableEle) {
            baseTableEle.enableInfiniteLoading = false;
          }
          /*FRONT-8711 : Setting Error CSS since no Other Location Records found*/
          this.setNoAssetsFoundMessages();
          /*END : FRONT-8711*/
        }
      })
      .catch((error) => {
        logger.log("===error===", error.stack);
      });
  }

  handleLoadMore(event) {
    event.preventDefault();
    // increase the offset count by 10 on every loadmore event
    this.offset = this.offset + 50;
    //Display a spinner to signal that data is being loaded
    event.target.isLoading = true;
    //Set the onloadmore event target to make it visible to imperative call response to apex.
    this.targetDatatable = event.target;
    //this.getFilterAssetsResult(this.whereClause);
    // Get new set of records and append to this.data
    if (this.currentTabName === "defaultlocation") {
      this.getFilterAssetsResult(this.whereClause);
    } else if (this.currentTabName === "otherlocation") {
      this.getFilteredAssetsOtherLocation(this.whereClause, "false");
    } else if (this.currentTabName === "itemsearchassets") {
      //need to remove Assign/Remove button from the last column
      this.getFilterAssetsResult(this.whereClause);
    }
  }

  buildData(data) {
    try {
      let preparedAssets = [];
      data.forEach((asset) => {
        let preparedAsset = {};
        preparedAsset.id = asset.Id;
        preparedAsset.isAssetAttached = asset.Id === this.parentId;
        preparedAsset.Current_Location_Number__c =
          asset?.SM_PS_Current_Location__r?.Branch_Location_Number__c;
        preparedAsset.Rate_Branch = preparedAsset.Current_Location_Number__c;
        preparedAsset.Description = asset?.Product2?.Name;
        preparedAsset.Name = asset?.Product2?.Name;
        preparedAsset.assetDescription = asset?.Description; //Added as part of Front-10330
        preparedAsset.SM_PS_Equipment_Number__c =
          asset.SM_PS_Equipment_Number__c;
        preparedAsset.Product_SKU__c = asset.Product2?.Product_SKU__c;
        preparedAsset.ProductId = asset.Product2?.Id;
        preparedAsset.Product_Type__c = asset.Product2?.Product_Type__c;
        preparedAsset.Product_Category__c = asset.Product2?.Product_Category__c;
        preparedAsset.Product_Sub_Category__c =
          asset.Product2?.Product_Sub_Category__c;
        preparedAsset.Is_Kit__c = asset.Product2?.Is_Kit__c;
        preparedAsset.Changeable__c = asset.Product2?.Changeable__c;
        preparedAsset.Status = asset.Status;
        preparedAsset.SM_PS_Last_Transaction_Date__c =
          asset.SM_PS_Last_Transaction_Date__c;
        preparedAsset.linkColor = !this.isItemSearchAssetsTab
          ? "successLink"
          : ""; //Modified as part of FRONT-10327, 10328
        preparedAsset.cellAlign = "alignCellData";
        //FRONT-7415
        preparedAsset.buttonValue = preparedAsset.isAssetAttached
          ? "Remove"
          : "Assign";
        preparedAsset.buttonVariant =
          preparedAsset.buttonValue === "Remove" ? "Neutral" : "Brand";
        preparedAsset.assetType = !this.isItemSearchAssetsTab
          ? "button"
          : "text"; //Added as part of FRONT-10327, 10328
        preparedAssets.push(preparedAsset);
      });

      //logic to remove duplicate records from the wiredAsset list
      let tempWiredAsset = [...this.wiredAsset, ...preparedAssets];
      let jsonObject = tempWiredAsset.map(JSON.stringify);
      let uniqueSet = new Set(jsonObject);
      this.wiredAsset = Array.from(uniqueSet).map(JSON.parse);

      //show sourcing branch records top in the the array for other location tab
      if (this.currentTabName === "otherlocation") {
        let tempSourcingBranchAssets = [];
        let tempOtherBranchAssets = [];

        //to show sourcing branch records at the top of the list
        this.wiredAsset.forEach((item) => {
          if (
            item.Current_Location_Number__c ===
            `${this.locationInfo?.Branch_Location_Number__c}`
          ) {
            tempSourcingBranchAssets.push(item);
          } else {
            tempOtherBranchAssets.push(item);
          }
        });
        this.wiredAsset = [
          ...tempSourcingBranchAssets,
          ...tempOtherBranchAssets
        ];
      }
    } catch (error) {
      logger.log("===error===", error.stack);
    }
  }

  buildDefaultQuery() {
    let whereSearchClause = "";
    if (this.searchKey && this.searchKey !== "") {
      const defaultFilters = DEFAULT_FILTERING_FIELDS.map((field) => {
        return {
          fieldApiName: field,
          value: this.searchKey
        };
      });
      whereSearchClause = this.buildWhereClause(defaultFilters, JOIN_OR_CLAUSE);
    }
    //On rendering the component with nothing in 'Customer Info' field in Modal
    //then just add Record type check in Where clause
    else if (!this.searchKey) {
      whereSearchClause += this.buildWhereClause(null);
    }
    return whereSearchClause;
  }

  buildWhereClause(filters, joinClause = JOIN_AND_CLAUSE) {
    let whereClauseArray = [];
    let whereClause = "";
    if (filters) {
      for (let filter of filters) {
        let value = filter.value.replaceAll("'", "\\'");
        if (filter.operator === "=")
          whereClauseArray.push(
            ` ${filter.fieldApiName} ${filter.operator} '${value}' `
          );
        else
          whereClauseArray.push(` ${filter.fieldApiName} LIKE '%${value}%' `);
      }
    }
    if (whereClauseArray.length === 1) {
      whereClause = whereClauseArray[0];
    } else if (whereClauseArray.length > 1) {
      whereClause += "(";
      whereClause += whereClauseArray.join(joinClause);
      whereClause += ")";
    }
    if (whereClause) {
      whereClause += JOIN_AND_CLAUSE;
      whereClause += this.productFilterClause;
    } else {
      whereClause = this.productFilterClause;
    }

    return whereClause;
  }

  // FRONT-7416 Started
  async handleRemove(event) {
    this.isDataLoaded = false;

    let record = {
      fields: {
        Id: this.orderItemId,
        SBQQ__Asset__c: null
      }
    };

    await updateRecord(record);

    const closeModalEvent = new CustomEvent("close", {
      bubbles: true,
      composed: true
    });
    this.dispatchEvent(closeModalEvent);

    if (!this.isMobile) {
      const refreshOrderLineItemTable = new CustomEvent("refresh_oli_table", {
        bubbles: true,
        composed: true
      });
      this.dispatchEvent(refreshOrderLineItemTable);
    }

    const toastEvent = new ShowToastEvent({
      message: "Asset has been Removed",
      variant: "success",
      mode: "dismissable"
    });
    this.dispatchEvent(toastEvent);
  }
  // FRONT-7416 Ended

  render() {
    let renderTemplate;
    if (this.isMobile) {
      renderTemplate = sbr_3_0_AssignAssetTableComponentMobile;
    } else {
      renderTemplate = sbr_3_0_AssignAssetTableComponentDesktop;
    }
    return renderTemplate;
  }

  //Added as part of FRONT-7403
  handleRowAction(event) {
    const action = event.detail.action;
    const row = event.detail.row;

    if (action.name === "view_assign_asset") {
      this.showViewAssetModal(row?.id);
      return;
    }
    //FRONT-7415
    if (row.buttonValue === "Assign") {
      this.commitAssetAssignment(this.orderItemId, row?.id);
    }
    if (row.buttonValue === "Remove") {
      this.handleRemove();
    }
  }

  getSelectedName(event) {
    let selectedRows = event.target.getSelectedRows();
    let my_ids = [];
    this.selectedRowList = selectedRows;
    for (let i = 0; i < selectedRows.length; i++) {
      my_ids.push(selectedRows[i].id);
    }
    this.preSelectedRows = my_ids;
    const selectedRowsEvent = new CustomEvent("rowsselected", {
      detail: selectedRows
    });
    this.dispatchEvent(selectedRowsEvent);
  }

  showViewAssetModal(rowId) {
    this.dispatchEvent(
      new CustomEvent("viewasset", {
        detail: {
          assetId: rowId
        }
      })
    );
  }
  @api hideViewAssetScreen() {
    this.openViewAssetModal = false;
  }

  handleAssignAsset(event) {
    let assetId = event.target.dataset.assetId;
    this.commitAssetAssignment(this.orderItemId, assetId);
  }

  async commitAssetAssignment(orderLineItemId, assetId) {
    try {
      let record = {
        fields: {
          Id: orderLineItemId,
          SBQQ__Asset__c: assetId
        }
      };

      await updateRecord(record);

      if (!this.isMobile) {
        const refreshOrderLineItemTable = new CustomEvent("refresh_oli_table", {
          bubbles: true,
          composed: true
        });
        this.dispatchEvent(refreshOrderLineItemTable);
      }

      const successToastEvent = new ShowToastEvent({
        message: "Asset has been Assigned",
        variant: "success",
        mode: "dismissable"
      });
      this.dispatchEvent(successToastEvent);

      //await this.getFilterAssetsResult(this.whereClause);
      if (this.currentTabName === "defaultlocation") {
        await this.getFilterAssetsResult(this.whereClause);
      } else if (this.currentTabName === "otherlocation") {
        await this.getFilteredAssetsOtherLocation(this.whereClause, "false");
      }
      const closeModalEvent = new CustomEvent("close", {
        bubbles: true,
        composed: true
      });
      this.dispatchEvent(closeModalEvent);
    } catch (error) {
      const errorToastEvent = new ShowToastEvent({
        message: "Error Occured",
        variant: "error",
        mode: "dismissable"
      });
      this.dispatchEvent(errorToastEvent);

      const closeModalEvent = new CustomEvent("close", {
        bubbles: true,
        composed: true
      });
      this.dispatchEvent(closeModalEvent);
    }
  }

  handleRemoveAsset() {
    this.handleRemove();
  }

  handleMobileViewAssetDetails(event) {
    this.showViewAssetModal(event.target.dataset.assetId);
  }

  /* FRONT-8711 : Logic to show Illustrations and pushing error on search components upon no data found */
  showSearchFieldError() {
    this.template
      .querySelector("c-sbr_3_0_-Assign-Asset-Header-Component")
      .showErrorOnSearchField();
  }

  hideSearchFieldError() {
    this.template
      .querySelector("c-sbr_3_0_-Assign-Asset-Header-Component")
      .hideErrorOnSearchField();
  }

  showLocationFieldError() {
    this.template
      .querySelector("c-sbr_3_0_-Assign-Asset-Header-Component")
      .showErrorOnLocationField();
  }

  hideLocationFieldError() {
    this.template
      .querySelector("c-sbr_3_0_-Assign-Asset-Header-Component")
      .hideErrorOnLocationField();
  }

  setNoAssetsFoundMessages() {
    try {
      this.isDefaultLocationTab = this.currentTabName === "defaultlocation";
      this.isOtherLocationTab = this.currentTabName === "otherlocation";
      this.noDefaultLocationsFoundErrorMessage =
        LABELS.NO_ASSETS_FOUND_DISPLAY_MESSAGE;
      this.noOtherLocationsFoundErrorMessage =
        LABELS.NO_LOCATION_FOUND_DISPLAY_MESSAGE;
      this.hideSearchFieldError();
      this.hideLocationFieldError();

      if (
        this.searchKey &&
        this.searchKey !== undefined &&
        this.inventoryCount <= 0
      ) {
        this.showSearchFieldError();
        this.noDefaultLocationsFoundErrorMessage =
          LABELS.NO_DEFAULT_LOCATION_FOUND_DISPLAY_MESSAGE;
        /* FRONT - 9049 : Defaulting the error message to show no assets found when search key entered on ither locations tab*/
        this.noOtherLocationsFoundErrorMessage = this.isOtherLocationTab
          ? LABELS.NO_DEFAULT_LOCATION_FOUND_DISPLAY_MESSAGE
          : LABELS.NO_LOCATION_FOUND_DISPLAY_MESSAGE;
        /* END : FRONT - 9049 */
      }

      if (
        this.locationSearchKey &&
        this.locationSearchKey !== undefined &&
        this.inventoryCount <= 0
      ) {
        this.showLocationFieldError();
        this.noOtherLocationsFoundErrorMessage =
          LABELS.NO_OTHER_LOCATION_FOUND_DISPLAY_MESSAGE;
      }
    } catch (error) {
      logger.log("===error==", error.stack);
    }
  }

  /* END : FRONT-8711 */
  /*Added as part of FRONT-10330*/
  get computedMainDivClass() {
    return this.isItemSearchAssetsTab
      ? "slds-grid slds-wrap item-box bgcolor"
      : "slds-grid slds-wrap item-box";
  }

  handleChange(event) {
    if (event.target.checked) {
      //this.showViewAssetDetails=true;
      this.selectedAssetId = event.target.value;
      this.selectedRowList = this.wiredAsset.filter(
        (item) => item.id === this.selectedAssetId
      );
      this.assetspotlightcmp = true;
    }
  }

  // Defect - 13052
  handleItemSelection(event) {
    this.selectedAssetId = event.currentTarget.dataset.id;
    this.selectedRowList = this.wiredAsset.filter(
      (item) => item.id === this.selectedAssetId
    );
    //this.assetspotlightcmp = true; commented as part of FRONT-15575
  }

  get fieldsTitleClass() {
    return this.isItemSearchAssetsTab
      ? "fieldsTitle slds-p-left_large"
      : "title";
  }

  get labelCss() {
    return this.isItemSearchAssetsTab ? "data" : "custom-label data";
  }

  /*FRONT-10330 Ends here*/
  /*Added as part of FRONT-10327, FRONT-10328*/
  get hideCheckBox() {
    return !this.isItemSearchAssetsTab ? true : false;
  }

  get innerContainerClass() {
    return this.isItemSearchAssetsTab
      ? "item-search-inner-container item-search-asset-container "
      : "oal-inner-container ";
  }

  get enableInfiniteLoading() {
    return !this.isItemSearchAssetsTab ? true : false;
  }

  /*FRONT-10327, FRONT-10328 Ends here*/
  //Added for FRONT-11320,11322 starts here
  disconnectedCallback() {
    this.unsubscribeToMessageChannel();
  }

  subscribeToMessageChannel() {
    if (!this.dprSubscription) {
      this.dprSubscription = subscribe(
        this.messageContext,
        deselectProductRowChannel,
        (item) => this.deselectProductRow(item),
        { scope: APPLICATION_SCOPE }
      );
    }
  }

  unsubscribeToMessageChannel() {
    unsubscribe(this.dprSubscription);
    this.dprSubscription = null;
  }

  deselectProductRow(item) {
    try {
      if (!item.productId) {
        //FRONT-11329 Changes
        this.selectedRowList = [];
        this.preSelectedRows = [];
      } else {
        let filterRows = this.selectedRowList.filter(
          (row) => row.id != item.productId
        ); //FRONT-13129 changes
        this.selectedRowList = filterRows;
        let my_ids = [];
        for (let i = 0; i < filterRows.length; i++) {
          my_ids.push(filterRows[i].id);
        }
        this.preSelectedRows = my_ids;
      }
      const selectedRowsEvent = new CustomEvent("rowsselected", {
        //FRONT-11329 changes
        detail: this.selectedRowList
      });
      this.dispatchEvent(selectedRowsEvent);
    } catch (error) {
      //FRONT-11320,11322 ends here
      logger.log("===error===", error.stack);
    }
  }

  handleBackToItemSearchButton(event) {
    this.assetspotlightcmp = false;
  }
}