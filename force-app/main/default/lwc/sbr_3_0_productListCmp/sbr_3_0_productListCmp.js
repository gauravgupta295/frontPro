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

export default class Sbr_3_0_productListCmp extends LightningElement {
  @api listHeight;
  data = [];
  columns = [];
  showTable = false;
  dprSubscription = null;
  isMobile = false;

  @wire(MessageContext)
  messageContext;

  @api showRadioButtons = false; // FRONT-22428

  productRowsOffset = 0;
  offsetList = [];
  @api productRowsOffsetMobile = 0;
  batchSize = 50;
  showSpinner = false;
  queryParams = "";
  searchKey = "";
  appliedFilters = {
    Filter_Level_1__c: ""
  };
  selectedCategories = [];
  selectedSubCategories = [];
  catSubCatWhere; //SAL-26801
  @track mobileIsLoading = false;
  //@track hasBatchStarted = false;
  @api totalLineCount = 0;
  uniqueLineCount = 0;

  @api maxRowSelection;//FRONT-20801

  connectedCallback() {
    this.subscribeToMessageChannel();
    this.isMobile = window.matchMedia("(max-width: 480px)").matches;
    if (this.isMobile) {
      this.getProductData(this.productRowsOffset, false);
    }
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
    console.log("hit deselect row on productListCmp: ", item);
    let selectedRows = this.template.querySelector(
      "c-sbr_3_0_custom-line-items"
    ).selectedRows;
    if (item.productId == null) {
      this.template.querySelector("c-sbr_3_0_custom-line-items").selectedRows =
        [];
    } else {
      let index = selectedRows.indexOf(item.productId);
      if (index >= 0) {
        selectedRows.splice(index, 1);
        this.template.querySelector(
          "c-sbr_3_0_custom-line-items"
        ).selectedRows = selectedRows;
      }
    }
    let selectedRowsData = this.template
      .querySelector("c-sbr_3_0_custom-line-items")
      .getSelectedRows();
    const selectedRowsEvent = new CustomEvent("rowsselected", {
      detail: selectedRowsData
    });
    this.dispatchEvent(selectedRowsEvent);
  }

  @api searchProductList(searchKey) {
    this.productRowsOffset = 0;
    this.searchKey = searchKey;
    this.getProductData(this.productRowsOffset, false);
  }

  @api filterProductList(selectedFilter) {
    this.productRowsOffset = 0;
    this.offsetList = [];
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
    this.catSubCatWhere = selectedFilter.catSubCatWhere;
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
    console.log("****PRODUCTDATA OFFSET ====" + offset);
    this.offsetList.push(offset);
    let whereClause = "";
    let selCats = this.selectedCategories;
    let selSubCats = this.selectedSubCategories;

    for (let key in this.appliedFilters) {
      if (this.appliedFilters[key]) {
        whereClause = `${whereClause} AND ${key} = '${this.appliedFilters[key]}'`;
      }
    }

    // SAL-26801: Changed Cat and Subcat WHERE condition to: (cat1 AND subcats1) OR (cat2 AND subcats2). Previously it was: (allCats OR allSubCats)
    if (this.catSubCatWhere) {
      whereClause = whereClause + " AND " + this.catSubCatWhere;
    } else {
      let catWhereClause =
        selCats.length === 0
          ? ""
          : "Product_Category__c IN ('" + selCats.join("','") + "')"; //SAL-26801 Using Product_Category__c instead of Filter_Level_2__c
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
    }

    console.log("final whereClause >> " + whereClause);

    fetchProductData({
      offset: offset,
      queryParams: "",
      batchSize: 50,
      searchKey: this.searchKey,
      whereClause: whereClause
    })
      .then((data) => {

        if (!this.isMobile) {
          if (data.length < this.batchSize) {
            this.template.querySelector(
              "c-sbr_3_0_custom-line-items"
            ).enableInfiniteLoading = false;
          } else {
            this.template.querySelector(
              "c-sbr_3_0_custom-line-items"
            ).enableInfiniteLoading = true;
          }
        }

        if (isLoadingMoreItems) {
          const currentData = this.data;
          const newData = currentData.concat(data);
          this.data = newData;
          console.log("this.data with loaded data@@" + this.data.length);
        } else {
          this.data = data;
          console.log("this.data without loading" + this.data.length);
        }

        this.productRowsOffset += data.length;
        if (
          data.length == this.batchSize &&
          !this.offsetList.includes(this.productRowsOffset - this.batchSize)
        ) {
          this.productRowsOffset = this.productRowsOffset - this.batchSize;
        }
        console.log(
          "offset after " +
            this.productRowsOffset +
            " data.length" +
            data.length
        );

        if (!this.isMobile) {
          this.template.querySelector(
            "c-sbr_3_0_custom-line-items"
          ).isLoading = false;
        }

        this.dispatchEvent(
          new CustomEvent("searchcomplete", { detail: this.data.length })
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
    console.log("hit productListCmp this.selectedItem: ", selectedItem);

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
    //FRONT-22428 Start
    if (this.showRadioButtons) {
      const radioOption = event.target
        .closest("li")
        .querySelector(`[name="items-list"]`);
      radioOption.checked = true;
    } 
    const selectedRowsEvent = new CustomEvent("rowsselected", {
      detail: selectedItem
    });
    this.dispatchEvent(selectedRowsEvent); //FRONT-22428 end
  
  }
}