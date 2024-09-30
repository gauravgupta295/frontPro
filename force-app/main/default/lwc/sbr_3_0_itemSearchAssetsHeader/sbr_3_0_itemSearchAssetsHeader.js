import { LightningElement, api, track } from "lwc";
import { Logger, isEmpty } from "c/sbr_3_0_frontlineUtils";
// import getAssetList from "@salesforce/apex/SBR_3_0_AssetController.getAssetList";
import getStatuses from "@salesforce/apex/SBR_3_0_CustomDataTableCmpController.getOrderItemStatusOptions";
import LABELS from "c/sbr_3_0_customLabelsCmp";
import DESKTOPTEMPLATE from "./sbr_3_0_itemSearchAssetsHeader.html";
import MOBILETEMPLATE from "./sbr_3_0_itemSearchAssetsHeaderMobile.html";
import { isMobile } from "c/sbr_3_0_dynamicRecordFormUtility";

const logger = Logger.create(true);

export default class sbr_3_0_itemSearchAssetsHeader extends LightningElement {
  _activeTab;
  @api get activeTab() {
    return this._activeTab;
  } // FRONT-14464

  set activeTab(value) {
    this._activeTab = value;
    if (this.activeTab === "Cat Class Description") {
      this.isCatClassDescrip = true;
    } else {
      this.isCatClassDescrip = false;
    }
    if (this.activeTab === "CatClass") {
      this.isCatClassDescrip = true;
      this.showCatClassTabDDL = true;
    } else {
      this.showCatClassTabDDL = false;
    }
  }
  assetSearchTypeCriteriaValue = "description";
  assetSearchTypePlaceholder = "Search Description";
  @api assetSearchListInputPlaceholder = "Search List";
  @api recordId; // FRONT-15699
  @api isDataAvailable;
  @api showDefaultScreen;
  isAssetSearchTypeLoading = false;
  isAssetSearchListInputLoading = false;
  @api selectedLocationFilter = "Current Branch";
  locationOptions = [];
  selecetdStatusList = ["Any Status"];
  statusOptions = []; //15681
  filterOptions = []; //15681
  isCatClassDescrip = false; //15677
  showCatClassTabDDL = false; //15681
  catClassDescriptionFilter = false;
  @track selectedOption = "";
  @track showDropdown = false;
  @track searchKey = ""; // FRONT-14464
  @track result = []; // FRONT-14464
  @api assetFlag = ""; // FRONT-19000
  showlocationfilter = false;
  key = "";
  error;
  options = [
    { label: "Option 1", value: "option1" },
    { label: "Option 2", value: "option2" },
    { label: "Option 3", value: "option3" }
  ];
  //15681 Start

  filterdropdownOpen = false;
  isstatusdropdownOpen = false;
  statuscheckedvalues;
  filterYear = "";
  eqpLocation = "";
  @api inventory = "0";
  showEqpLoc = false; // FRONT - 15702
  yearWarningMsg = "Please enter only last two digits of the year";
  /*catClassDescrpPlaceholder = LABELS.CATCLASSDESCRPLACEHOLDER;
  catClassPlaceholder = LABELS.CATCLASSPLACEHOLDER;*/
  LABELS = LABELS;
  //15681 End
  @api catClassVal; // FRONT - 15702
  @track pillLabel = ""; // FRONT - 15702
  infiniteLoad = true;
  @api productRowsOffset;
  @api selectedCatClassVal = "";
  @track listViewOptions = [];
  @track allLocationViewOptions = [];
  @track isAnySelected = true;
  @track appliedStatusList = [];
  selectedStatus = "";
  debounceDelay;
  @track isItemListSearchDisabled = false; // FRONT-17146
  //itemListSearchVal; // FRONT-17146
  @track itemListSearchKey = ""; // FRONT-17146
  @track allListViewOptions; //FRONT-14482
  @track value = []; //FRONT-14482
  @track preValue = []; //FRONT-14482
  toggleDropdown() {
    this.showDropdown = !this.showDropdown;
  }

  selectOption(event) {
    this.selectedOption = event.target.textContent;
    this.showDropdown = false;
  }

  get isSerialOrAssetTab() {
    if (this.activeTab == "Serial" || this.activeTab == "Asset") {
      return true;
    } else {
      return false;
    }
  }

  //@api locationInfo;

  selectedFilterComboboxValue = "Filters";
  selectedStatusComboboxValue = "Status";
  filterComboboxOptions = [];
  statusComboboxOptions = [];
  catClassFilterLabel = "";
  searchKeyCatClass = "";
  isdisplayDataMobile = false; //FRONT-18121

  get assetSearchTypeCriteriaOptions() {
    //all values lowercased for consistency
    return [
      { label: "Description", value: "description" },
      { label: "Cat-Class", value: "catclass" },
      { label: "Asset #", value: "asset" },
      { label: "Serial #", value: "serial" }
    ];
  }

  get isSearchTypeCriteriaOptionSelectedAsAsset() {
    return this.assetSearchTypeCriteriaValue === "asset";
  }
  @api isMobile = isMobile;
  isItemSearchAssetsTab = false;
  isOtherLocationActive = false;
  locationFilter;
  locationFilterPillsLabel = "Location - ";
  itemSearchPlaceholder = `Search Cat Class`;
  itemListSearchPlaceholder = "Search the list records";

  @track assetListParamObject = {};

  @track productItemParamObject = {};

  connectedCallback() {
    if (this.isMobile) {
      this.selectedLocationFilter = "Current Branch";
    } else {
      this.isItemListSearchDisabled = true; // FRONT-17146
    }
    // this.assetListParamObject = {
    //   searchKey: this.searchKey,
    //   actvTab: this.activeTab,
    //   catClass: this.selectedCatClassVal,
    //   contractId: this.recordId,
    //   offset: this.productRowsOffset
    // };
    this.productItemParamObject = {
      searchKey: this.searchKey,
      actvTab: this.activeTab,
      selectedLocationFilter: this.selectedLocationFilter,
      contractId: this.recordId
    };

    //this.selectedLocationFilter = this.locationInfo.Id;
    this.locationOptions.push({
      //   label: "PC" + this.locationInfo?.Branch_Location_Number__c,
      //   value: this.locationInfo.Id
      label: LABELS.BRANCH,
      value: "Current Branch"
    });
    this.locationOptions.push({
      label: LABELS.DISTRICT,
      value: "All District Branches"
    });
    this.locationOptions.push({
      label: LABELS.MARKET,
      value: "All Market Branches"
    });
    this.locationOptions.push({
      label: LABELS.REGION,
      value: "All Region Branches"
    });
    this.locationOptions.push({ label: "All Branches", value: "All Branches" });
    logger.log("Inside itemSearchAssetsHeader");

    //15681 Start
    this.statusOptions.push({
      label: LABELS.ANYSTATUS,
      value: "Any Status",
      selected: true
    });
    this.statusOptions.push({
      label: LABELS.AVAILABLESTATUS,
      value: "Available"
    });
    this.statusOptions.push({
      label: LABELS.DOWN20LESS,
      value: "Down less than 20 days"
    });
    this.statusOptions.push({
      label: LABELS.DOWN20MORE,
      value: "Down more than 20 days"
    });
    this.statusOptions.push({
      label: LABELS.INTRANSIT,
      value: "In Transit"
    });
    this.statusOptions.push({
      label: LABELS.ONTRUCK,
      value: "On Truck"
    });
    this.statusOptions.push({
      label: LABELS.ONRENT,
      value: "On Rent"
    });
    this.statusOptions.push({
      label: LABELS.NEEDCHKOUT,
      value: "Returned-Need Check Out"
    });
    this.statusOptions.push({
      label: LABELS.SATBRANCH,
      value: "Satellite Branch"
    });
    this.statusOptions.push({
      label: LABELS.PCKUPSCH,
      value: "Scheduled for Pickup"
    });
    this.statusOptions.push({
      label: LABELS.SEASONAL,
      value: "Seasonal"
    });
    this.statusOptions.push({
      label: LABELS.LOCKOUT,
      value: "Safety/Service Lockout"
    });

    this.initListViewOptions();
    //15681 End
    this.setFilterComboBoxValues();
    this.setStatusComboBoxValues();
    for (let option of this.statusOptions) {
      //FRONT-14482 starts

      this.value.push(option.value);
      this.preValue.push(option.value);
    } //FRONT-14482 ends
    // window.addEventListener("click", this.handleOutsideClick);
  }

  toggleFilter() {
    logger.log("inside filter change", this.catClassVal);
    if (this.activeTab === "Cat Class Description"){
      this.catClassDescriptionFilter=true;
    }else{
      this.catClassDescriptionFilter=false;

    }
    this.showlocationfilter = true;
  }

  /*
  searchItems(event) {
    console.log("Event fire for showdata");
    let val = event.target.value;
    this.searchKey = val;
    if (event.target.value) {
      const event = new CustomEvent("showdata", {
        detail: {
          value: true,
          searchKey: this.searchKey
        }
      });
      this.dispatchEvent(event);
    } else {
      const event = new CustomEvent("showdata", {
        detail: {
          value: false
        }
      });
      this.dispatchEvent(event);
    }
  }
*/
  //Front-15677,15681 start
  renderedCallback() {}
  //Front-15677 end

  handleComboboxClick(event) {
    let value = event.target.value;
    this.selectedLocationFilter = value;
    this.fireCustomEvent();
  }

  handleAssetSearchListInputChange(event) {
    logger.log("event fired " + JSON.stringify(event.target.value));
    // if (!isEmpty(event.target.value)){
    this.searchKey = event.target.value;
    logger.log("searchKey " + this.searchKey);
    this.debounce(500);
    // }
  }

  //To avoid multiple server calls when user is searching items
  debounce(timeout = 500) {
    if (this.debounceDelay) clearTimeout(this.debounceDelay);
    this.debounceDelay = setTimeout(() => {
      this.fireCustomEvent();
    }, timeout);
  }

  fireCustomEvent() {
    const e = new CustomEvent("filtercriteriachange", {
      detail: this.getPayload()
    });
    this.dispatchEvent(e);
  }

  getPayload() {
    let payload;
    if (this.activeTab === "Cat Class Description") {
      payload = this.getCatClassDescriptionPayload();
    } else if (this.activeTab === "CatClass") {
      payload = this.getCatClassPayload();
    } else if (this.activeTab === "Asset") {
      payload = this.getAssetPayload();
    } else if (this.activeTab === "Serial") {
      payload = this.getSerialPayload();
    }
    return payload;
  }

  getCatClassDescriptionPayload() {
    return {
      searchKey: this.searchKey,
      itemListSearchKey: this.itemListSearchKey,
      selectedLocationFilter: this.selectedLocationFilter
    };
  }

  getCatClassPayload() {
    if (this.isMobile) {
      this.catClassVal = this.searchKey;
    }
    //logger.log("searchKey " + this.searchKey + this.catClassVal); //.includes("-") ? this.searchKey.split("-").join(""): this.searchKey;
    return {
      searchKey: this.searchKey,
      statusList: this.selecetdStatusList,
      year: this.filterYear,
      loc: this.eqpLocation,
      contractId: this.recordId,
      selectedLocation: this.selectedLocationFilter,
      offset: null,
      actvTab: this.activeTab,
      catClass: this.searchKey,
      selectedCatClassVal: this.selectedCatClassVal
    };
  }

  getAssetPayload() {
    return {
      searchKey: this.searchKey
    };
  }

  getSerialPayload() {
    return {
      searchKey: this.searchKey
    };
  }

  get selectedLocationFilterValue() {
    return this.selectedLocationFilter || "Current Branch";
  }

  //Not used anywhere

  // handleSearchKeyPress(event) {
  //   this.infiniteLoad = true;
  //   if (event.keyCode === 13) {
  //     // Call your search method/function here passing searchTerm
  //     if (this.key !== "") {
  //       this.searchKey = this.key;
  //     }
  //     this.fireCustomEvent();
  //   }
  // }

  // FRONT-14464 End

  handleLocationCriteriaChange(event) {
    this.selectedLocationFilter = event.detail.value;
    if (this.selectedLocationFilter === "Current Branch") {
      this.showEqpLoc = false;
    } else {
      this.showEqpLoc = true;
    }
    this.fireCustomEvent();
  }

  setFilterComboBoxValues() {
    let filterComboBoxValues = [
      {
        label: "Filters",
        value: "Filters"
      }
    ];
    this.filterComboboxOptions = filterComboBoxValues;
  }

  setStatusComboBoxValues() {
    let statusComboBoxValues = [
      {
        label: "Status",
        value: "Status"
      }
    ];
    this.statusComboboxOptions = statusComboBoxValues;
  }

  handleFilterComboBoxOptionChange(event) {}

  handleStatusComboBoxOptionChange(event) {}

  //FRONT-14464 Start
  get assetSearchTypePlaceholderFunc() {
    if (this.activeTab === "Cat Class Description") {
      this.itemListSearchPlaceholder = "Search the list";
      return LABELS.FTABPH;
    }
    if (this.activeTab === "CatClass") {
      this.itemListSearchPlaceholder = "Search the list";
      return this.isMobile ? LABELS.STABPH : LABELS.STABPHD;
    } else if (this.activeTab === "Asset") {
      return "Search Asset #";
    } else if (this.activeTab === "Serial") {
      return "Search Serial #";
    }
  } //FRONT-14464 End

  //FRONT-15681
  toggleDropdowncatFilters() {
    this.filterdropdownOpen = !this.filterdropdownOpen;
  }

  toggleDropdowncatStatus() {
    this.isstatusdropdownOpen = !this.isstatusdropdownOpen;
  }

  handleYearChange(e) {
    // FRONT - 15702
    logger.log("inside year change");
    const regex = /^\d+$/;
    this.filterYear = e.detail.value;
    if (!regex.test(this.filterYear) && !isEmpty(this.filterYear)) {
      e.target.setCustomValidity("Enter last two digits of the year only");
      e.target.reportValidity();
    } else {
      e.target.setCustomValidity("");
      e.target.reportValidity();
    }
  }

  handleEquipmentLocChange(e) {
    // FRONT - 15702
    const regex = /^\d+$/;
    logger.log("inside eqp loc change");
    this.eqpLocation = e.detail.value;
    if (!regex.test(this.eqpLocation) && !isEmpty(this.eqpLocation)) {
      e.target.setCustomValidity("Enter numbers only");
      e.target.reportValidity();
    } else {
      e.target.setCustomValidity("");
      e.target.reportValidity();
    }
  }

  handleFilterReset(e) {
    this.filterYear = "";
    this.eqpLocation = "";
    this.handlFilterApply(e);
  }

  // FRONT - 15702
  handlFilterApply(e) {
    this.infiniteLoad = true;
    this.filterdropdownOpen = !this.filterdropdownOpen;
    logger.log(this.filterYear + " " + this.eqpLocation);
    if (e.detail.name === "year") {
      this.filterYear = e.detail.value;
    }
    if (e.detail.name === "eqpLoc") {
      this.eqpLocation = e.detail.value;
    }
    this.fireCustomEvent();
  }

  get selectedValues() {
    logger.log(this.statuscheckedvalues);
    return this.statuscheckedvalues.join(",");
  }

  handleStatusFilterChange(e) {
    //FRONT-14482 starts
    this.value = e.detail.value;
    let selectAllStatus = this.value.indexOf("Any Status") === -1;
    let selectAllPrevStatus = this.preValue.indexOf("Any Status") === -1;
    if (selectAllStatus && !selectAllPrevStatus) {
      this.value = [];
      this.preValue = this.value;
    } else if (!selectAllStatus && selectAllPrevStatus) {
      this.value = [];
      for (let option of this.statusOptions) {
        this.value.push(option.value);
        this.preValue.push(option.value);
      }
    } else {
      if (selectAllStatus === false) {
        this.value.splice(selectAllStatus, 1);
      }
      this.preValue = this.value;
    }
    if (this.value.length === 11 && selectAllStatus === true) {
      this.value.push("Any Status");
    }
    logger.log(this.value); //FRONT-14482 ends
  }

  handleApplyStatusFilters() {
    this.productRowsOffset = 0;
    this.infiniteLoad = true;
    this.isstatusdropdownOpen = !this.isstatusdropdownOpen;
    logger.log("inside apply status filters");
    this.selecetdStatusList = [...this.value];
    this.fireCustomEvent();
  }

  hanlderesetStatusDropDown() {
    this.value = []; //FRONT-14482 starts
    for (let option of this.statusOptions) {
      this.value.push(option.value);
      this.preValue.push(option.value);
    } // FRONT-14482 ends
    this.handleApplyStatusFilters();
  }

  //FRONT - 15702
  get showPill() {
    let hasPillAvailable;
    if (this.activeTab === "CatClass") {
      if (this.selectedCatClassVal && this.assetFlag) {
        hasPillAvailable = true;
        this.pillLabel = "Cat Class - " + this.selectedCatClassVal;
      } else if (this.catClassVal && !this.assetFlag) {
        hasPillAvailable = true;
        this.pillLabel = "Cat Class - " + this.catClassVal;
      }
    }
    return hasPillAvailable;
  }
  get searchKeyVal() {
    if (this.isCatClassTab && this.isMobile && this.assetFlag) {
      //FRONT-19000
      return this.selectedCatClassVal;
    }
    return this.searchKey || this.catClassVal;
  }

  get isCatClassTab() {
    return this.activeTab === "CatClass";
  }
  //FRONT-15681

  get isSerialTab() {
    return this.activeTab === "Serial";
  }

  handlePillRemoveClick() {
    this.hasPillAvailable = false;
    this.searchKey = "";
    this.appliedStatusList = [];
    this.value = ""; //Front-28032
    this.showEqpLoc = false;

    const switchToDescriptionEvent = new CustomEvent("switchtodescription", {
      bubbles: true,
      composed: true
    });
    this.catClassVal = "";
    this.selectedCatClassVal = "";
    this.filterYear = "";
    this.eqpLocation = "";
    this.selecetdStatusList = [];
    this.dispatchEvent(switchToDescriptionEvent);
  }

  // END : FRONT - 15702
  //Added as part of FRONT_18174
  render() {
    let renderTemplate;
    if (this.isMobile) {
      renderTemplate = MOBILETEMPLATE;
    } else {
      renderTemplate = DESKTOPTEMPLATE;
    }
    return renderTemplate;
  }
  handleChangeLocation(event) {
    if (event.target.value) {
      this.selectedLocationFilter = event.target.value;
      if (this.selectedLocationFilter === "Current Branch") {
        this.showEqpLoc = false;
      } else {
        this.showEqpLoc = true;
      }
    }
  }
  handleLocationComboboxFocus(event) {
    const combobox = this.template.querySelector("lightning-combobox");
    if (combobox.className.search("slds-is-open") === -1) {
      combobox.className = "slds-section slds-is-open";
    } else {
      combobox.className = "slds-section slds-is-close";
      combobox.blur();
    }
  }
  resetFilterPanel() {
    this.selectedLocationFilter = "Current Branch";
    this.selecetdStatusList = [];
    this.eqpLocation = "";
    this.filterYear = "";
    this.fireCustomEvent();
    //this.getMobileCatClassFilter(this.catClassVal);
    this.showlocationfilter = false;
  }
  cancelClick() {
    this.showlocationfilter = false;
  }
  applyFilter() {
    this.searchKey = this.catClassVal;
    this.fireCustomEvent();
    this.showlocationfilter = false;
  }
  //Added as part of FRONT-18174
  @track results = [];

  initListViewOptions() {
    this.listViewOptions = [
      {
        label: "Any Status",
        value: "Any Status",
        isSelected: false
      }
    ];

    this.allLocationViewOptions.push("Any");
    getStatuses()
      .then((data) => {
        const excludedStatuses = [
          "IN PROGRESS",
          "RETURNED TO VENDOR",
          "Deinstalled",
          "Manufactured",
          "Deleted",
          "ON RENTAL PURCHASE",
          "JUNKED",
          "MISSING LOST",
          "SOLD",
          "STOLEN"
        ];

        if (data.length > 0) {
          //const dataInOrder = JSON.stringify(data).sort();
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
      })
      .catch((error) => {
        console.log(error);
      });
  }
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
  handleSelectOptionList(event) {
    this.selecetdStatusList = event.detail.selectedStatus;
    this.isAnySelected = event.detail.isAnyChecked;
  }

  //FRONT-18121
  handleEnterClickMobile(event) {
    if (event.keyCode === 13) {
      this.searchKey = "";
      if (this.assetFlag && this.isMobile && this.isCatClassTab) {
        //19000
        this.selectedCatClassVal = event.target.value;
      }
      this.handleAssetSearchListInputChange(event);
    }
  }

  //FRONT-18121
  handleEmptyValueMobile(event) {
    logger.log("close click on search box");
    this.handleAssetSearchListInputChange(event);
  }

  //FRONT-17146
  @api
  setIsItemListSearchDisabled(isBooleanVal) {
    this.isItemListSearchDisabled = isBooleanVal;
  }

  //FRONT-17146
  handleItemListSearchPress(event) {
    if (event.keyCode === 13 && event.target.value !== "") {
      logger.log("event fired 2" + JSON.stringify(event.target.value));
      this.itemListSearchKey = event.target.value;
      this.debounce(500);
    }
  }

  //FRONT-17146
  handleUpdateValue(event) {
    this.itemListSearchKey = event.target.value;
  }

  //FRONT-17146
  handleAssetSearchListInputCommit(event) {
    if (event.target.value === "") {
      if (this.activeTab === "Cat Class Description") {
        this.template.querySelector('[data-id="itemListSearchInput"]').value =
          "";
      }

      this.itemListSearchKey = "";
      this.handleAssetSearchListInputChange(event); //FRONT-15699
    }
  }

  //FRONT-15699
  handleEnterClickDesktop(event) {
    if (event.keyCode === 13) {
      this.handleAssetSearchListInputChange(event);
    }
  }
  onFocusMethod(event) {
    console.log("Target", event.target.label);
    let currentfieldname = event.target.label;
    if (currentfieldname === "searchYear") {
      this.template
        .querySelector(".customColorYR")
        .classList.add("customColorFocus");
    } else if (currentfieldname === "Equipment Location") {
      this.template
        .querySelector(".customColorEL")
        .classList.add("customColorFocus");
    } else if (currentfieldname === "Location Criteria") {
      this.template
        .querySelector(".customColorLC")
        .classList.add("customColorFocus");
    }
  }
  onBlurMethod(event) {
    let currentfieldname = event.target.label;
    if (currentfieldname === "searchYear") {
      this.template
        .querySelector(".customColorYR")
        .classList.remove("customColorFocus");
    } else if (currentfieldname === "Equipment Location") {
      this.template
        .querySelector(".customColorEL")
        .classList.remove("customColorFocus");
    } else if (currentfieldname === "Location Criteria") {
      this.template
        .querySelector(".customColorLC")
        .classList.remove("customColorFocus");
    }
  }

  //FRONT-29393,FRONT-29680
  @api applyRedBorder(noSearchResults) {
    let itemSearchInput = this.template.querySelector(".item-search-input");
    if (noSearchResults) {
      itemSearchInput?.classList.remove("searchBoxWrapper");
      itemSearchInput?.classList.add("searchBoxWrapperRed");
    } else if (!noSearchResults) {
      itemSearchInput?.classList.remove("searchBoxWrapperRed");
      itemSearchInput?.classList.add("searchBoxWrapper");
    }
  }

  /* FRONT-30494, FRONT-30493 : changing searchbox variant*/
  @api toggleDestructiveVariantOnSearchBox(noSearchResults) {
    const searchBox = this.template.querySelector(".item-search-input");
    if (searchBox && !this.isMobile) {
      const lfValue = searchBox.value;
      searchBox.blur();
      searchBox.value = lfValue;

      if (noSearchResults) {
        searchBox.classList.add("destructive-input-variant-class");
      } else if (
        searchBox.classList.contains("destructive-input-variant-class")
      ) {
        searchBox.classList.remove("destructive-input-variant-class");
      }
    }
  }
}