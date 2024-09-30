import { LightningElement, wire, api, track } from "lwc";
import getItemSearchColumns from "@salesforce/apex/SBR_3_0_CustomDataTableCmpController.getItemSearchColumns";
import fetchProductData from "@salesforce/apex/SBR_3_0_CustomDataTableCmpController.getFilteredProducts";
import {
  subscribe,
  unsubscribe,
  APPLICATION_SCOPE,
  MessageContext,
  publish
} from "lightning/messageService";
import deselectProductRowChannel from "@salesforce/messageChannel/deselectProductRowChannel__c";
import FrontLineCSS from "@salesforce/resourceUrl/FrontLinesCSS";
import { loadStyle } from "lightning/platformResourceLoader";

export default class Sbr_3_0_productListCmp extends LightningElement {
  @api listHeight;
  data = [];
  columns = [];
  showTable = false;
  dprSubscription = null;
  isMobile = false;

  @api showRadioButtons = false; //FRONT-8793
  @wire(MessageContext)
  messageContext;

  productRowsOffset = 0;
  @api productRowsOffsetMobile = 0;
  batchSize = 50;
  queryParams = "";
  searchKey = "";
  appliedFilters = {
    Filter_Level_1__c: ""
  };
  selectedCategories = [];
  selectedSubCategories = [];
  @track mobileIsLoading = false;
  //@track hasBatchStarted = false;
  isCatClass = true; // FRONT-11313

  @api maxRowSelection; // Front-1639
  connectedCallback() {
    this.subscribeToMessageChannel();
    this.isMobile = window.matchMedia("(max-width: 480px)").matches;
    if (this.isMobile) {
      this.getProductData(this.productRowsOffset, false);
    }
    // FRONT-11315
    this.loadStyleSheet();
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
  }
  unsubscribeToMessageChannel() {
    unsubscribe(this.dprSubscription);
    this.dprSubscription = null;
  }

  deselectProductRow(item) {
    if (
      item.variant !== "consumableSalesAddOn" &&
      item.variant !== "assetsLineItems"
    ) {
      //FRONT-13129
      let selectedRows = this.template.querySelector(
        "c-sbr_3_0_custom-data-table-cmp"
      ).selectedRows;
      if (item.productId == null) {
        this.template.querySelector(
          "c-sbr_3_0_custom-data-table-cmp"
        ).selectedRows = [];
      } else {
        let index = selectedRows.indexOf(item.productId);
        if (index >= 0) {
          selectedRows.splice(index, 1);
          this.template.querySelector(
            "c-sbr_3_0_custom-data-table-cmp"
          ).selectedRows = selectedRows;
        }
      }
      let selectedRowsData = this.template
        .querySelector("c-sbr_3_0_custom-data-table-cmp")
        .getSelectedRows();
      const selectedRowsEvent = new CustomEvent("rowsselected", {
        detail: selectedRowsData
      });
      this.dispatchEvent(selectedRowsEvent);
    }
  }

  @api searchProductList(searchKey, isCatClass) {
    this.productRowsOffset = 0;
    this.searchKey = searchKey;
    this.isCatClass = isCatClass; //FRONT-11313
    this.getProductData(this.productRowsOffset, false);
  }

  @api filterProductList(selectedFilter) {
    this.productRowsOffset = 0;
    switch (selectedFilter.filterType) {
      case "Filter_Level_1__c":
        this.appliedFilters.Filter_Level_1__c =
          selectedFilter.filterValue == "All Items"
            ? ""
            : selectedFilter.filterValue;
        break;
      default:
        this.appliedFilters.Filter_Level_1__c = "";
        break;
    }

    this.selectedCategories = selectedFilter.selectedCategories;
    this.selectedSubCategories = selectedFilter.selectedSubCategories;

    this.getProductData(this.productRowsOffset, false);
  }

  @wire(getItemSearchColumns)
  itemSearchColumns({ error, data }) {
    if (data) {
      if (!this.isMobile) {
        let itemSearchCols = data.filter(
          (col) => col.Context__c == "Item Search"
        );
        itemSearchCols.sort((a, b) => a.Order__c - b.Order__c);
        itemSearchCols.forEach((col) => {
          let colItem = {};
          colItem.label = col.Label;
          colItem.fieldName = col.Field_Name__c;
          colItem.hideDefaultActions = true;
          colItem.sortable = col.IsSortable__c;
          colItem.type = col.Type__c ? col.Type__c : "text";
          colItem.wrapText = true;
          if (col.fixedWidth__c) colItem.fixedWidth = col.fixedWidth__c;
          this.columns.push(colItem);
          this.queryParams += col.Field_Name__c + ",";
        });
        this.showTable = true;
        this.getProductData(this.productRowsOffset, false);
      }
    } else if (error) {
      console.log(error);
    }
  }

  loadMoreItems(event) {
    let datatableTarget = event.target;
    datatableTarget.isLoading = true;
    this.getProductData(this.productRowsOffset, true);
  }

  getProductData(offset, isLoadingMoreItems) {
    let whereClause = "";
    let selCats = this.selectedCategories;
    let selSubCats = this.selectedSubCategories;

    for (let key in this.appliedFilters) {
      if (this.appliedFilters[key]) {
        whereClause = `${whereClause} AND ${key} = '${this.appliedFilters[key]}'`;
      }
    }

    let catWhereClause =
      selCats.length === 0
        ? ""
        : "Filter_Level_2__c IN ('" + selCats.join("','") + "')";
    let subcatWhereClause =
      selSubCats.length === 0
        ? ""
        : "Product_Sub_Category__c IN ('" + selSubCats.join("','") + "')";
    // needs to be AND ( OR )
    if (selCats.length > 0 && selSubCats.length > 0)
      whereClause =
        whereClause +
        " AND (" +
        catWhereClause +
        " OR " +
        subcatWhereClause +
        ")";
    if (selCats.length > 0 && selSubCats.length === 0)
      whereClause = whereClause + " AND " + catWhereClause;
    if (selCats.length === 0 && selSubCats.length > 0)
      whereClause = whereClause + " AND " + subcatWhereClause;

    fetchProductData({
      offset: offset,
      queryParams: "",
      batchSize: 50,
      searchKey: this.searchKey,
      whereClause: whereClause,
      isCatClass: this.isCatClass //FRONT-11313
    })
      .then((data) => {
        if (!this.isMobile) {
          if (data.length < this.batchSize) {
            this.template.querySelector(
              "c-sbr_3_0_custom-data-table-cmp"
            ).enableInfiniteLoading = false;
          } else {
            this.template.querySelector(
              "c-sbr_3_0_custom-data-table-cmp"
            ).enableInfiniteLoading = true;
          }
        }

        if (isLoadingMoreItems) {
          const currentData = this.data;
          const newData = currentData.concat(data);
          this.data = newData;
        } else {
          this.data = data;
        }

        this.productRowsOffset += data.length;

        if (!this.isMobile) {
          this.template.querySelector(
            "c-sbr_3_0_custom-data-table-cmp"
          ).isLoading = false;
        }

        this.dispatchEvent(
          new CustomEvent("searchcomplete", { detail: this.productRowsOffset })
        );
      })
      .catch((error) => {
        console.log(error);
      });
  }
  updateSelectedRows(event) {
    let selectedRows = event.target.getSelectedRows();
    const selectedRowsEvent = new CustomEvent("rowsselected", {
      detail: selectedRows
    });
    this.dispatchEvent(selectedRowsEvent);
  }

  get listHeightStyle() {
    return `height:${this.listHeight}px;`;
  }

  //sorting needs to be refactored
  defaultSortDirection = "asc";
  sortDirection = "asc";
  sortedBy;

  // Used to sort the 'Age' column
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
    const { fieldName: sortedBy, sortDirection } = event.detail;
    const cloneData = [...this.data];

    cloneData.sort(this.sortBy(sortedBy, sortDirection === "asc" ? 1 : -1));
    this.data = cloneData;
    this.sortDirection = sortDirection;
    this.sortedBy = sortedBy;
  }

  loadMoreDataMobile(event) {
    if (
      event.target.scrollTop >
        event.target.scrollHeight - event.target.offsetHeight &&
      !this.mobileIsLoading
    ) {
      this.mobileIsLoading = true;

      new Promise((resolve, reject) => {
        setTimeout(() => {
          this.getProductData(this.productRowsOffset, true);
          resolve();
        }, 3000);
      }).then(() => (this.mobileIsLoading = false));
    }
  }

  // pass in an product object that matches the filters
  showItemSpotlight(event) {
    let selectedItem = this.data[event.target.closest("li").value];

    const toggleprodinqmobilestate = new CustomEvent(
      "toggleprodinqmobilestate",
      {
        bubbles: true,
        composed: true,
        detail: {
          viewState: "item-spotlight",
          product: selectedItem,
          showTabsPanel: false
        }
      }
    );
    this.dispatchEvent(toggleprodinqmobilestate);
    //FRONT-8793 start. Setting the radio whenever the user clicks on an item.
    if (this.showRadioButtons) {
      const radioOption = event.target
        .closest("li")
        .querySelector(`[name="items-list"]`);
      radioOption.checked = true;
    } //FRONT-8793 end
    const selectedRowsEvent = new CustomEvent("rowsselected", {
      detail: selectedItem
    });
    this.dispatchEvent(selectedRowsEvent);
  }

  /* FRONT-11315 Starts */
  loadStyleSheet() {
    loadStyle(this, FrontLineCSS);
  }
  /* FRONT-11315 Ends */
}