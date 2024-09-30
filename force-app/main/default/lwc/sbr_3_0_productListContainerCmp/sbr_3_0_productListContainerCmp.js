import { LightningElement, api, track } from "lwc";

export default class Sbr_3_0_productListContainerCmp extends LightningElement {
  isMobile = false;
  @api tabsPanelHeight;
  @api recordId;
  @api objectApiName;
  @api isCustomerAdded;
  @api syncCustomerName;
  totalLineCount = 0;
  @api showRadioButtons = false; //FRONT-8793

  showListViews = false;
  @api maxRowSelection; // Front-1639
  connectedCallback() {
    this.isMobile = window.matchMedia("(max-width: 480px)").matches;
  }

  get listHeight() {
    let listHeaderHeight = this.template.querySelector(".list-header-container")
      ? this.template.querySelector(".list-header-container").offsetHeight
      : 75;
    return this.tabsPanelHeight - listHeaderHeight;
  }



  handleSelectedRows(event) {
    let selectedRows = event.detail;
    const selectedRowsEvent = new CustomEvent("rowsselected", {
      detail: selectedRows
    });
    this.dispatchEvent(selectedRowsEvent);
  }
  handleItemSearch(event) {
    let data = event.detail;
    this.template
      .querySelector("c-sbr_3_0_product-list-cmp")
      .searchProductList(data.searchKey, data.isCatClass); //FRONT-11313
  }
  handleListViewChange(event) {
    let data = event.detail;

    this.template
      .querySelector("c-sbr_3_0_product-list-cmp")
      .filterProductList({
        filterType: "Filter_Level_1__c",
        filterValue: data.selectedView,
        selectedCategories: data.selectedCategories,
        selectedSubCategories: data.selectedSubCategories,
        catSubCatWhere: data.catSubCatWhere //SAL-26801
      });
  }
  handleSearchCompletion(event) {
    console.log("search complete in handleSearchCompletion ");
    let itemCount = event.detail;

    this.template
      .querySelector("c-sbr_3_0_product-list-header-cmp")
      .searchCompletionHandler(itemCount);
  }
  handleViewCart(event) {
    const viewCartEvent = new CustomEvent("viewcart");
    this.dispatchEvent(viewCartEvent);
  }

  handleToggleProdInqMobileState(event) {
    if (event.detail.viewState.valueOf() == "list-view") {
      this.showListViews = true;
    } else {
      this.showListViews = false;
    }
  }

  get productListClass() {
    return this.showListViews ? "product-list-hide" : "product-list-show";
  }
}