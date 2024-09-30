import { LightningElement, api, track } from "lwc";
import getStatuses from "@salesforce/apex/SBR_3_0_CustomDataTableCmpController.getOrderItemStatusOptions";
import LABELS from "c/sbr_3_0_customLabelsCmp"; //added as a part of 6276
import { appName, FL_APP_NAME, SAL_APP_NAME } from "c/sbr_3_0_frontlineUtils";
import FL_TEMPLATE from "./FL/defaultFL.html";
import SAL_TEMPLATE from "./SAL/defaultSAL.html";

const DELAY = 500;

export default class sbr_3_0_OrderAssetListHeaderCmp extends LightningElement {
  @api recordId;
  orderRecordType;
  assetCount = 0;
  isSearchLoading = false;
  delayTimeout;
  statusOptions;
  selectedStatus = "";
  listViewOptions = []; //Changes made for 6276
  @track allListViewOptions = [];
  selectedView = "Any Status";
  itemSearchPlaceholder = `Search this list...`;

  showRequestButton = false;
  @api showAssetStatusFilter = false;

  isMobile = false;
  showFilters = false;
  isFilterActive = false;
  filterOptions = [];
  @track selectedFilterOptions = [];
  appliedFilters = [];
  appliedFiltersDisplay = "All Statuses";
  showListView = true;
  dropdownVisible = false;
  chosenvalues; //Added for Story 6276
  finalvalues; //Added for Story 6276
  selectedmultivalues = LABELS.SBR_3_0_AssetStatusPicklistValues; //Added for Story 6276
  assetTabToolTip = LABELS.ASSET_TAB_TOOL_TIP; //Added for Story 7409
  @track value = ["Any Status"]; //Added for Story 6276
  cancelBtnClass = "slds-button slds-button_neutral selected-btn";
  resetBtnClass = "slds-button reset-btn-class";
  resetTxtClass = "slds-button slds-p-right_small reset-txt-class";
  applyBtnClass = "slds-button slds-button_neutral apply-btn-class";
  @track isDropdownOpen = false;

  @api searchCompletionHandler(itemCount) {
    this.isSearchLoading = false;
    this.assetCount = itemCount;
  }

  connectedCallback() {
    this.setAppName();
    this.initListViewOptions();
    this.isMobile = window.matchMedia("(max-width: 480px)").matches;
    console.debug("header is mobile:", this.isMobile);
  }

  @api orderStatusChangedHandler(orderRecordType) {
    this.orderRecordType = orderRecordType;
    this.showRequestButton = this.orderRecordType === "Contract Order";
    this.showAssetStatusFilter = this.orderRecordType === "Contract Order";
    console.debug("header order type:", this.orderRecordType);
    console.debug("show status filter:", this.showAssetStatusFilter);
    //this.showAssetStatusFilter = (this.orderStatus === 'Draft');
  }

  initListViewOptions() {
    if (this.isMobile) {
      this.listViewOptions = [
        {
          label: "All",
          value: ""
        }
      ];
    }
    getStatuses()
      .then((data) => {
        //Added for Story 6276
        if (this.orderRecordType === "Contract Order") {
          this.listViewOptions.push({
            label: "Any Status",
            value: ""
          });
        const excludedStatuses = [
          "Returned to Vendor",
          "Deinstalled",
          "Manufactured",
          "Deleted"
        ];

        if (data.length > 0) {
          const newStatuses = data.filter(
            (item) => !excludedStatuses.includes(item)
          );
          newStatuses.forEach((status) => {
            status = this.changeTextFormat(status);
            this.listViewOptions.push({
              label: status,
              value: status,
              isSelected: false
            });
          });
          this.allListViewOptions = new Array(...this.listViewOptions);
        }
      } else {
        //Added for Story 6276
        this.listViewOptions.push({
          label: "Any Status",
          value: "Any Status"
        });
        /*this.listViewOptions.push({
              label: 'Unassigned',
              value: 'Unassigned',
              isSelected: false
          });*/
        const excludedStatuses = [
          "HELD FOR SALE",
          "HELD FOR CENTRAL DISPOSAL",
          "ON RENTAL PURCHASE",
          "JUNKED",
          "MISSING LOST",
          "SOLD",
          "STOLEN",
          "Deleted"
        ];
        if (data.length > 0) {
          const newStatuses = data.filter(
            (item) => !excludedStatuses.includes(item)
          );
          newStatuses.forEach((status) => {
            status = this.changeTextFormat(status);
            this.listViewOptions.push({
              label: status,
              value: status,
              isSelected: true
            });
          });
          this.listViewOptions.push({
            label: "Unassigned",
            value: "Unassigned",
            isSelected: false
          });
          this.allListViewOptions = new Array(...this.listViewOptions);
          if (this.allListViewOptions) {
            this.isDropdownOpen = true;
          }
        }
        }
      })
      .catch((error) => {
        console.log(error);
      });
  }

  isEnterClicked = false;
  handleEnterClick(event) {
    //If Enter key is pressed then only apply search
    if (
      event.target.value &&
      event.keyCode === 13 &&
      this.orderRecordType !== "Contract Order"
    ) {
      this.isEnterClicked = true;
    }
    this.searchItems(event);
  }

  searchItems(event) {
    //Added for Story 6276
    if (
      this.orderRecordType === "Contract Order" ||
      (event.keyCode === 13 &&
        this.orderRecordType !== "Contract Order" &&
        this.isEnterClicked)
    ) {
      this.isSearchLoading = true;
      window.clearTimeout(this.delayTimeout);
      const searchKey = event.target.value;
      this.delayTimeout = setTimeout(() => {
        this.searchUpdateHandler(searchKey);
      }, DELAY);
      if (!event.target.value && this.isEnterClicked) {
        this.isEnterClicked = false;
      }
    } else if (event.target.value === "") {
      this.searchUpdateHandler(event.target.value);
    }
  }
  //Added for Story 6276
  handleKeyChange(event) {
    if (event.keyCode == 8) {
      let str = event.target.value;
      str = str.slice(0, -1);
      window.clearTimeout(this.delayTimeout);
      if (str == "") {
        const searchKey = str;
        this.delayTimeout = setTimeout(() => {
          this.searchUpdateHandler(searchKey);
        }, DELAY);
      }
    }
  }

  @api refreshDataHandler() {
    this.isSearchLoading = true;
    let searchKey = this.template.querySelector(
      'lightning-input[data-source="searchInputField"]'
    ).value;
    this.searchUpdateHandler(searchKey);
  }

  searchUpdateHandler(searchKey) {
    this.searchKey = searchKey;
    const searchEvent = new CustomEvent("orderassetsearchupdate", {
      detail: { searchKey: searchKey }
    });
    this.dispatchEvent(searchEvent);
  }

  handleStatusChange(event) {
    //Added for Story 6276
    if (!this.isMobile && this.orderRecordType === "Contract Order") {
      this.selectedStatus = event.detail.value;
      const statusChangeEvent = new CustomEvent("assetstatusupdate", {
        detail: {
          selectedStatus: this.selectedStatus
        }
      });
      this.dispatchEvent(statusChangeEvent);
    }
    //Added for Story 6276,6275
    if (this.orderRecordType !== "Contract Order") {
      this.value = event.detail;
      if (!this.isMobile) {
        this.applyFilter();
      }
    }
  }

  handleRequestMenuSelection(event) {
    let selectedOption = event.detail.value;

    const requestSelectEvent = new CustomEvent("requestselected", {
      detail: {
        selectedRequest: selectedOption
      }
    });
    this.dispatchEvent(requestSelectEvent);
  }

  //mobile header functions
  toggleFilter() {
    this.showFilters = !this.showFilters;
  }

  openFilterPanel() {
    //Added for Story 6276
    if (this.orderRecordType !== "Contract Order") {
      this.nonreservationorderflag = true;
    }
    this.showFilters = true;
    if (this.orderRecordType === "Contract Order") {
      //Added for Story 6276
      this.template.querySelector("lightning-radio-group").value =
        this.selectedStatus;
    } else {
    }
    const showFilterEvt = new CustomEvent("togglefilters", {
      detail: { filtersOpen: this.showFilters }
    });
    this.dispatchEvent(showFilterEvt);
  }

  closeFilterPanel() {
    this.showFilters = false;
    const showFilterEvt = new CustomEvent("togglefilters", {
      detail: { filtersOpen: this.showFilters }
    });
    this.dispatchEvent(showFilterEvt);
  }

  toggleSection(event) {
    let buttonid = event.currentTarget.dataset.buttonid;
    let currentsection = this.template.querySelector(
      '[data-id="' + buttonid + '"]'
    );
    if (currentsection.className.search("slds-is-open") == -1) {
      currentsection.className =
        "light-grey slds-section slds-is-open menu-height";
    } else {
      currentsection.className = "light-grey slds-section slds-is-close";
    }
  }
  applyFilter() {
    //Added for Story 6276
    if (this.orderRecordType === "Contract Order") {
      this.selectedStatus = this.template.querySelector(
        "lightning-radio-group"
      ).value;
      this.appliedFiltersDisplay =
        this.selectedStatus === "" ? "All Statuses" : this.selectedStatus;
      const statusChangeEvent = new CustomEvent("assetstatusupdate", {
        detail: {
          selectedStatus: this.selectedStatus
        }
      });
      this.dispatchEvent(statusChangeEvent);
      this.closeFilterPanel();
    }
    //Added for Story 6276
    else {
      const statusChangeEvent = new CustomEvent("assetstatusupdate", {
        detail: {
          selectedStatus: this.value
        }
      });
      this.dispatchEvent(statusChangeEvent);
      this.closeFilterPanel();
    }
  }

  @api resetFilterPanel() {
    this.selectedFilterOptions = [];
    //Added for Story 6276
    if (this.orderRecordType === "Contract Order") {
      this.template.querySelector("lightning-radio-group").value = "";
      this.selectedStatus = "Any Status";
      this.appliedFiltersDisplay = "All Statuses";
    }
    //Added for Story 6276
    else {
      this.selectedStatus = this.selectedmultivalues;
      this.template
        .querySelector("c-sbr_3_0_multi-select-picklist")
        .resetFilters();
    }
  }

  get itemSearchDisplay() {
    return this.showListView ? "header-mob-hide" : "header-mob-show";
  }

  get headerDisplay() {
    return this.showFilters ? "hide" : "show";
  }

  get filterDisplay() {
    return this.showFilters ? "show" : "hide";
  }
  toggleDropdown() {
    this.isDropdownOpen = !this.isDropdownOpen;
  }
  //Added as part of FRONT-7410
  changeTextFormat(status) {
    let result = "";
    let capitalizeNext = true;

    for (const char of status) {
      if (/[a-zA-Z]/.test(char)) {
        if (capitalizeNext) {
          result += char.toUpperCase();
          capitalizeNext = false;
        } else {
          result += char.toLowerCase();
        }
      } else {
        result += char;
        capitalizeNext = true;
      }
    }

    return result;
  }

  async setAppName() {
    this.appName = await appName;
  }

  render() {
    return this.isFrontlineApp ? FL_TEMPLATE : SAL_TEMPLATE;
  }

  get isFrontlineApp() {
    return this.appName === FL_APP_NAME;
  }
}