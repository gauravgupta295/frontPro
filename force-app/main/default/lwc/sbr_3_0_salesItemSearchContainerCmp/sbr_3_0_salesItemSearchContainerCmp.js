import { LightningElement, api, wire, track } from "lwc";
import mobileTemplate from "./sbr_3_0_salesItemSearchContainerCmpMobile.html";
import { loadStyle } from "lightning/platformResourceLoader";
import desktopTemplate from "./sbr_3_0_salesItemSearchContainerCmpDesktop.html";
import FrontLineCSS from "@salesforce/resourceUrl/FrontLinesCSS";
import Bulleting from "@salesforce/resourceUrl/DotImage";
import getItemSearchColumns from "@salesforce/apex/SBR_3_0_CustomDataTableCmpController.getItemSearchColumns";
import fetchProductData from "@salesforce/apex/SBR_3_0_ConsumablesItemSearchCtrl.getAllProductItemsForSales";
import FORM_FACTOR from "@salesforce/client/formFactor";
import {
  subscribe,
  unsubscribe,
  APPLICATION_SCOPE,
  MessageContext,
  publish
} from "lightning/messageService";
import deselectProductRowChannel from "@salesforce/messageChannel/deselectProductRowChannel__c";
import updateLineItemsChannel from "@salesforce/messageChannel/UpdateLineItemsChannel__c";
import { Logger } from "c/sbr_3_0_frontlineUtils";
import LABELS from "c/sbr_3_0_customLabelsCmp"; //FRONT-10297
const logger = Logger.create(true);

const DELAY = 500;

//FRONT-15259 Contract Sales Tab Location Dropdown values have different label as of Reservation
const allContractSalesLocations = [
  { label: LABELS.BRANCH, value: "Current" },
  { label: LABELS.DISTRICT, value: "District" },
  { label: LABELS.MARKET, value: "Market" },
  { label: LABELS.REGION, value: "Region" },
  { label: LABELS.ALL_BRANCHES, value: "Company" } //FRONT-15255 : All Branches for Location Filter
];

export default class Sbr_3_0_salesItemSearchContainerCmp extends LightningElement {
  @api isMobile;
  @api locationInfo;
  // isMobile = false;
  // start FRONT-10297
  itemSearchPlaceholder = "";
  sortedByItem = "";
  itemSearch = "";
  allItems = "";
  filterAllItems = "";
  bulletImage=Bulleting
  items = "";
  locationCriteria = "";
  contractSelectedrows = []; //FRONT-15258
  // end FRONT-10297

  showFilters = false;
  selectedLoctionFilter = "";
  isSelectedValueNotMisc = true; //FRONT-14355
  @track data = [];
  @track columns = [];
  defaultSortDirection = "asc";
  sortDirection = "asc";
  sortedBy;
  productRowsOffset = 0;
  searchKey = "";
  batchSize = 50;
  @api maxRowSelection; // Front-1639
  isSalesTabPage; //11395
  showAvailability = true; //<!--added for 14361-->
  @api recordId;
  @api objectApiName;
  @track columnsForSalesItems = []; //FRONT-14355
  @track columnsForMiscItems = []; //FRONT-14355
  @track showPill = true;
  @track showFilterPhrase = false;
  @api contractSalesTab; //FRONT-15258

  sourceLocation;
  totalRecords;
  SelectedValue = "SALES";
  @track options = [
    //FRONT-14358
    {
      label: "Sales",
      value: "SALES"
    },
    {
      label: "Misc",
      value: "MISC"
    }
  ];
  locationOptions = [];
  whereClause = "";
  isItemSearchLoading = false;
  delayTimeout;
  availableOnly;
  stockVendorValue;
  manufacturerValue;
  isFilterActive = false;
  filterCount;
  showSpinner = false;
  loadingMoreItems = false;
  locationFilter;
  locationFilterPillsLabel = ""; //FRONT-20425
  appliedFilterList = [];
  selectedValueList = [];
  @api selectedProductIds;
  dprSubscription = null;

  sortByName;
  currentFilter;
  _itemSearchCols;
  isWidthCalculated;
  @wire(MessageContext)
  messageContext;

  //method to load columns for the line items datatable

  //to handle cart count on cart icon
  lineItems = [];
  cartItemsCount = 0;
  addToCartSubscription = null;
  isNotRecordPage = false;

  get isCartEmpty() {
    return this.cartItemsCount === 0;
  }

  get locationFilterClause() {
    if (this.locationInfo) {
      if (this.selectedLoctionFilter === "District") {
        return ` Location.District__c = '${this.locationInfo.District__c}' `;
      } else if (this.selectedLoctionFilter === "Region") {
        return ` Location.Region__c = '${this.locationInfo.Region__c}' `;
      } else if (this.selectedLoctionFilter === "Company") {
        return ` Location.Company__c = '${this.locationInfo.Company__c}' `;
      } else if (this.selectedLoctionFilter === "Market") {
        return ` Location.Market_Name__c = '${this.locationInfo.Market_Name__c}' `;
      } else if (this.SelectedValue !== "MISC") {
        //FRONT-14358
        return ` LocationId = '${this.locationInfo.Id}' `;
      }
      return "";
    }
    return "";
  }

  buildWhereClause() {
    let defaultWhereClause = `${this.locationFilterClause}`;
    if (this.SelectedValue !== "MISC") {
      //FRONT-14358

      if (this.availableOnly) {
        defaultWhereClause +=
          " AND SM_PS_PartsMerch_Available_Quantity__c > 0 ";
      }
      if (this.stockVendorValue) {
        defaultWhereClause +=
          " AND SM_PS_Stock_Class__c LIKE '%" + this.stockVendorValue + "%' ";
      }
      if (this.manufacturerValue) {
        defaultWhereClause +=
          " AND Product2.Manufacturer_Item_Number__c LIKE '%" +
          this.manufacturerValue +
          "%' ";
      }
    }
    if (this.searchKey) {
      if (this.SelectedValue === "SALES") {
        defaultWhereClause += "AND ";
      }
      defaultWhereClause +=
        " (Product2.Item_Number__c LIKE '%" +
        this.searchKey +
        "%' OR Product2.Stock_class__c LIKE '%" +
        this.searchKey +
        "%' OR Product2.Name LIKE '%" +
        this.searchKey +
        "%') ";
    }
    return defaultWhereClause;
  }

  handleChangeOptions(event) {
    this.data = [];
    this.productRowsOffset = 0;
    this.SelectedValue = event.target.value;

    if (this.SelectedValue === "MISC") {
      //FRONT-14358
      this.isSelectedValueNotMisc = false; //FRONT-14355
      this.showPill = false;
      this.showAvailability = false; //<!--added for 14361-->
      this.columns = this.columnsForMiscItems; //FRONT-14355
      this.whereClause = "";
      this.dispatchEvent(new CustomEvent("closeproductfilter")); //FRONT-15691
    } else {
      this.showPill = true;
      this.isSelectedValueNotMisc = true; //FRONT-14355
      this.columns = this.columnsForSalesItems;
      this.showAvailability = true; //<!--added for 14361-->
      this.whereClause = this.buildWhereClause();
    }

    this.updateLocationFilterPill();
    this.getProductData(this.whereClause, false);
  }

  connectedCallback() {
    this.subscribeToMessageChannel();

    this.isNotRecordPage = !this.recordId && !this.objectApiName;

    // start FRONT-10297
    this.itemSearchPlaceholder = LABELS.SEARCH_ITEM_NAME_VENDOR_ID;
    this.sortedByItem = LABELS.SORTED_BY_ITEM;
    this.itemSearch = LABELS.ITEM_SEARCH;
    this.allItems = LABELS.ALL_ITEMS;
    this.filterAllItems = LABELS.FILTERED_ALL_ITEMS;
    this.items = LABELS.ITEMS;
    this.locationCriteria = LABELS.LOCATIONCRITERIA;
    // end FRONT-10297

    //this.isMobile = window.matchMedia("(max-width: 480px)").matches;
    this.isSalesTabPage = true; //11395

    //FRONT-11309 get the first value of filter from loctioninfo
    if (this.locationInfo) {
      this.whereClause = this.buildWhereClause();

      //FRONT-15259 Sales Tab Filter Location Dropdown values
      /* FRONT-31728 : Pushing location option with current branch even for desktop */
      if (this.contractSalesTab /*&& this.isMobile*/) {
        this.locationOptions = allContractSalesLocations;
        this.selectedLoctionFilter = "Current";
      } else {
        this.locationOptions.push({
          label:
            "Location Criteria - PC" +
            this.locationInfo?.Branch_Location_Number__c, //FRONT-20425
          value: this.locationInfo.Id
        });
        this.locationOptions.push({ label: "District", value: "District" });
        this.locationOptions.push({ label: "Region", value: "Region" });
        this.locationOptions.push({ label: "Company", value: "Company" });
        this.selectedLoctionFilter = this.locationInfo.Id;
      }

      this.updateLocationFilterPill();
      this.getProductData(this.whereClause, false);
    }
  }

  updateLocationFilterPill() {
    this.locationOptions.forEach((item) => {
      if (item.value === this.selectedLoctionFilter) {
        this.locationFilter = this.locationFilterPillsLabel + item.label;
      }
    });
  }

  renderedCallback() {
    loadStyle(this, FrontLineCSS)
      .then(() => logger.log("Files loaded."))
      .catch((error) => logger.log("Error " + error.body.message));
    this.observeWidth();
  }

  @wire(getItemSearchColumns)
  itemSearchColumns({ error, data }) {
    if (data) {
      if (!this.isMobile) {
        let itemSearchCols = data.filter(
          (col) => col.Context__c === "Sale Item Search"
        );
        this._itemSearchCols = data.filter(
          (col) => col.Context__c === "Sale Item Search"
        );
        this._itemSearchCols.sort((a, b) => a.Order__c - b.Order__c);
        this.generateColoumns();
      }
    } else if (error) {
      logger.log(error);
    }
  }

  loadMoreItems(event) {
    let datatableTarget = event.target;
    datatableTarget.isLoading = true;
    this.getProductData(this.whereClause, true);
  }

  getProductData(whereCondition, isloadMoreItems) {
    logger.log("this.whereclause: " + this.whereClause);
    let fixedbatchsize = 50; //added for 14361 starts here
    if (this.isMobile) {
      fixedbatchsize = 51;
    } //added for 14361 ends here we are using this attribute value for batchSize
    this.showSpinner = isloadMoreItems;
    fetchProductData({
      offset: this.productRowsOffset,
      batchSize: fixedbatchsize,
      whereClause: whereCondition,
      productType: this.SelectedValue
    })
      .then((data) => {
        let tempData = JSON.parse(JSON.stringify(data));
        console.log("---- product Data---" + JSON.stringify(data));
        data = tempData.map((row) => {
          return {
            ...row,
            Id: row.product.Id,
            description: row.product.Product_Description__c,
            itemNumber: row.product.Item_Number__c,
            stockClass: row.product.Stock_class__c,
            availableQty: row.availableQty,
            productName: row.product.Name,
            inventoriedItem: row.product.Inventoried_Item__c,
            miscellaneousChargeItem: row.product.Miscellaneous_Charge_Item__c,
            typeOfMiscChargeItem: row.product.Type_of_Misc_Charge_Item__c
          };
        });
        this.isItemSearchLoading = false;
        this.showSpinner = true;

        const salesDataTable = this.template.querySelector(
          "c-sbr_3_0_custom-data-table-cmp[data-comp-id=consumablesDataTable]"
        );
        if (!this.isMobile) {
          if (data.length < this.batchSize) {
            salesDataTable.enableInfiniteLoading = false;
          } else {
            salesDataTable.enableInfiniteLoading = true;
          }
        }

        this.data = this.data.concat(data);
        this.totalRecords = this.data.length;
        if (this.totalRecords <= 50) {
          this.totalRecords = this.data.length;
        } else {
          this.totalRecords = "50+";
        }
        this.productRowsOffset += data.length;
        salesDataTable.isLoading = false;
      })
      .catch((error) => {
        logger.log("Error in getProductData", error.stack);
      });
  }

  updateSelectedRows(event) {
    if (!this.contractSalesTab || !this.isSelectedValueNotMisc) {
      let selectedRows = event.target.getSelectedRows();
      const selectedRowsEvent = new CustomEvent("salesrowsselected", {
        detail: {
          selected: selectedRows,
          isSelectedValueNotMisc: this.isSelectedValueNotMisc
        }
      });

      this.dispatchEvent(selectedRowsEvent);
    } else {
      let contractSelectedrecords = [];
      let selectedRows = event.target.getSelectedRows();
      this.contractSelectedrows = [];
      selectedRows.forEach((row) => {
        if (row.availableQty > 0) {
          this.contractSelectedrows = [...this.contractSelectedrows, row.Id];
          contractSelectedrecords.push(row);
        }
      });
      const selectedRowsEvent = new CustomEvent("salesrowsselected", {
        detail: {
          selected: contractSelectedrecords,
          isSelectedValueNotMisc: this.isSelectedValueNotMisc
        }
      });
      this.dispatchEvent(selectedRowsEvent);
    }
  }

  render() {
    if (this.isMobile) {
      return mobileTemplate;
    }
    return desktopTemplate;
  }

  // recordId; Why used duplicate recordID ??

  get variables() {
    return {
      recordId: this.recordId
    };
  }

  handleLocationCriteriaChange(event) {
    this.data = [];
    this.productRowsOffset = 0;
    this.selectedLoctionFilter = event.detail.value;
    this.whereClause = this.buildWhereClause();
    this.updateLocationFilterPill();
    this.getProductData(this.whereClause, false);
  }

  handleViewFilter() {
    if (!this.isMobile) {
      this.showFilters = true;
      const selectedEvent = new CustomEvent("handleviewfilterdesktop");
      this.dispatchEvent(selectedEvent);
    } else {
      this.showFilters = !this.showFilters;
    }
  }

  searchItems(event) {
    //below condition added for FRONT-15258
    if (event.keyCode === 13) {
      //added for 14365 and 14366
      this.productRowsOffset = 0;
      this.isItemSearchLoading = true;
      window.clearTimeout(this.delayTimeout);
      const searchKey = event.currentTarget.value;
      this.delayTimeout = setTimeout(() => {
        this.itemSearchUpdateHandler(searchKey);
      }, DELAY);
    }
  }

  itemSearchUpdateHandler(searchKey) {
    this.data = [];
    this.searchKey = searchKey;
    this.whereClause = this.buildWhereClause();
    this.getProductData(this.whereClause, false);
  }

  handleCartClick() {
    const viewCartEvent = new CustomEvent("viewcart");
    this.dispatchEvent(viewCartEvent);
  }

  @api
  handleApplyProductFilter(availableOnly, stockVendorValue, manufacturerValue) {
    this.handleFilterPills(availableOnly, stockVendorValue, manufacturerValue);
    this.updateLocationFilterPill();

    this.data = [];
    this.productRowsOffset = 0;
    this.availableOnly = availableOnly;
    this.stockVendorValue = stockVendorValue;
    this.manufacturerValue = manufacturerValue;
    this.updateFilterCount();

    this.whereClause = this.buildWhereClause();
    this.getProductData(this.whereClause, false);
  }

  updateFilterCount() {
    this.filterCount = 0;
    if (this.availableOnly) {
      this.filterCount++;
    }
    if (this.stockVendorValue) {
      this.filterCount++;
    }
    if (this.manufacturerValue) {
      this.filterCount++;
    }
    if (this.selectedLoctionFilter && this.isMobile) {
      this.filterCount++;
    }
    this.isFilterActive = this.filterCount > 0 ? true : false;
  }

  applySalesProductFiltersMobile(event) {
    this.showSpinner = false;
    this.selectedLoctionFilter = event.detail.locationValue;
    this.handleFilterPills(
      event.detail.availableOnly,
      event.detail.stockVendorValue,
      event.detail.manufacturerValue
    );
    this.handleApplyProductFilter(
      event.detail.availableOnly,
      event.detail.stockVendorValue,
      event.detail.manufacturerValue
    );

    this.updateLocationFilterPill();
    this.handleViewFilter();
  }

  sortBy(field, reverse, primer) {
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

  onHandleSort(event) {
    console.log("sort by", event.detail.fieldName);
    const { fieldName: sortedBy, sortDirection } = event.detail;
    const cloneData = [...this.data];

    cloneData.sort(this.sortBy(sortedBy, sortDirection === "asc" ? 1 : -1));
    this.data = cloneData;
    this.sortDirection = sortDirection;
    this.sortedBy = sortedBy;
    let filtername = event.detail.fieldName;
    const filternamemap = new Map([
      ["itemNumber", "Part/Item #"],
      ["stockClass", "Stock/Vendor"],
      ["productName", "Name"],
      ["availableQty", "Available"]
    ]);
    this.sortByName = filternamemap.get(filtername);
  }

  handleFilterPills(quantity, stockVendor, manufacturer) {
    this.appliedFilterList = [];
    if (quantity) {
      this.appliedFilterList.push(`${LABELS.QUANTITY_LABEL} - Available Only`);
    }
    if (stockVendor) {
      this.appliedFilterList.push(
        `${LABELS.STOCK_VENDOR_LABEL} - ${stockVendor}`
      );
    }
    if (manufacturer) {
      this.appliedFilterList.push(
        `${LABELS.MANUFACTURER_LABEL} - ${manufacturer}`
      );
    }
    if (this.appliedFilterList.length === 0) {
      this.showFilterPhrase = false;
    } else {
      this.showFilterPhrase = true;
    }
    this.selectedValueList = this.appliedFilterList;
  }

  handlePillsRemove(event) {
    let pillLabel = event.target.label;
    let tempList = this.appliedFilterList;
    const index = tempList.indexOf(pillLabel);

    tempList.splice(index, 1);
    this.appliedFilterList = tempList;
    let removedItem = {
      label: pillLabel?.split(" - ")?.[0],
      value: pillLabel?.split(" - ")?.[1]
    };

    // if (this.isMobile) {
    if (removedItem.label === LABELS.QUANTITY_LABEL) {
      this.availableOnly = false;
    } else if (removedItem.label === LABELS.STOCK_VENDOR_LABEL) {
      this.stockVendorValue = "";
    } else if (removedItem.label === LABELS.MANUFACTURER_LABEL) {
      this.manufacturerValue = "";
    }

    this.selectedValueList = this.appliedFilterList.filter(
      (item) => item !== removedItem.label
    );

    if (this.selectedValueList.length === 0) {
      this.showFilterPhrase = true;
    } else {
      this.showFilterPhrase = false;
    }
    if (!this.isMobile) {
      const productFilterEvent = new CustomEvent("productfilterevent", {
        detail: {
          availableOnly: this.availableOnly,
          stockVendorValue: this.stockVendorValue,
          manufacturerValue: this.manufacturerValue
        }
      });
      this.dispatchEvent(productFilterEvent);
    }
    this.handleApplyProductFilter(
      this.availableOnly,
      this.stockVendorValue,
      this.manufacturerValue
    );
  }

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

    if (!this.addToCartSubscription) {
      this.addToCartSubscription = subscribe(
        this.messageContext,
        updateLineItemsChannel,
        (item) => this.updateLineItem(item),
        { scope: APPLICATION_SCOPE }
      );
    }
  }

  unsubscribeToMessageChannel() {
    unsubscribe(this.dprSubscription);
    this.dprSubscription = null;

    unsubscribe(this.addToCartSubscription);
    this.addToCartSubscription = null;
  }

  deselectProductRow(item) {
    if (item.variant === "consumableSalesAddOn") {
      let selectedRows = this.template.querySelector(
        "c-sbr_3_0_custom-data-table-cmp[data-comp-id='consumablesDataTable']"
      ).selectedRows;

      if (item.productId == null) {
        this.template.querySelector(
          "c-sbr_3_0_custom-data-table-cmp[data-comp-id='consumablesDataTable']"
        ).selectedRows = [];
      } else {
        let index = selectedRows.indexOf(item.productId);
        if (index >= 0) {
          selectedRows.splice(index, 1);
          this.template.querySelector(
            "c-sbr_3_0_custom-data-table-cmp[data-comp-id='consumablesDataTable']"
          ).selectedRows = selectedRows;
        }
      }
      let selectedRowsData = this.template
        .querySelector(
          "c-sbr_3_0_custom-data-table-cmp[data-comp-id='consumablesDataTable']"
        )
        .getSelectedRows();

      const selectedRowsEvent = new CustomEvent("salesrowsselected", {
        //FRONT-15736
        detail: {
          selected: selectedRowsData,
          isSelectedValueNotMisc: this.isSelectedValueNotMisc
        }
      });

      this.dispatchEvent(selectedRowsEvent);
    }
  }

  updateLineItem(item) {
    if (item.lineItem.itemType === "consumableSalesAddOn") {
      if (item.type === "add") {
        this.lineItems.push(item.lineItem);
        this.cartItemsCount = this.lineItems.length;
      }
      if (item.type === "remove") {
        if (item.recordId === this.recordId)
          this.cartItemsCount = item.lineItemsCount;
        if (item.lineItemsCount === 0) {
          this.lineItems = [];
        }
      }
    }
  }

  handleLoadMoreMobile(event) {
    if (event.detail.isLoadMoreMobile) {
      this.getProductData(this.whereClause, true);
    }
  }

  /*below condition added for FRONT-19392*/
  detailedview(event) {
    if (event.detail.chosendetailedview) {
      this.showPill = false;
    } else {
      this.showPill = true;
      if (this.SelectedValue === "MISC") {
        this.showPill = false;
      }
    }
  }

  searchItemsOnChange(event) {
    //FRONT-20891
    const searchKey = event.currentTarget.value;
    logger.log("searchKey", searchKey);
    if (!searchKey) {
      this.itemSearchUpdateHandler(searchKey);
    }
  }

  getColumnWidth(orderAssetCols) {
    let columnWidthMap;
    let widthContainer = this.template.querySelector(
      ".scrollable-list-container"
    );
    if (widthContainer) {
      const viewPortWidth = widthContainer.getBoundingClientRect().width;
      logger.log("viewPortWidth", viewPortWidth);
      if (orderAssetCols) {
        columnWidthMap = {};
        orderAssetCols.forEach((item) => {
          if (item.fixedWidth__c)
            columnWidthMap[item.DeveloperName] =
              (item.fixedWidth__c * (viewPortWidth - 50)) / 100;
        });
      }
    }
    return columnWidthMap;
  }
  observeWidth() {
    if (!this.isWidthCalculated) {
      this.generateColoumns();
    }
  }
  generateColoumns() {
    let columnWidthMap = this.getColumnWidth(this._itemSearchCols);
    if (!this._itemSearchCols || !columnWidthMap) {
      return;
    }
    let _tablecols = [];
    this._itemSearchCols.forEach((col) => {
      let colItem = {};
      colItem.label = col.Label;
      colItem.fieldName = col.Field_Name__c;
      colItem.hideDefaultActions = true;
      colItem.sortable = col.IsSortable__c;
      colItem.type = col.Type__c ? col.Type__c : "text";
      colItem.wrapText = true;
      // if (col.fixedWidth__c) colItem.fixedWidth = col.fixedWidth__c;
      if (col.fixedWidth__c) {
        if (
          col.Width_Unit__c === "Percent" &&
          columnWidthMap[col.DeveloperName]
        ) {
          colItem.initialWidth = columnWidthMap[col.DeveloperName];
        } else {
          colItem.initialWidth = col.fixedWidth__c;
        }
      }
      //colItem.cellAttributes = { alignment: "right" }
      this.columnsForSalesItems.push(colItem); //FRONT-14355

      if (colItem.fieldName !== "availableQty") {
        this.columnsForMiscItems.push(colItem); //FRONT-14355
      }
      _tablecols.push(colItem);
      //this.queryParams += col.Field_Name__c + ","; //unused Variable
    });
    this.columns = [..._tablecols];
    this.isWidthCalculated = true;
  }
}