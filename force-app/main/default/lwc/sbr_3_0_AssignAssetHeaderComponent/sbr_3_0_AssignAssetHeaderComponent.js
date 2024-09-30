/* FRONT-2186, FRONT-6226, FRONT-6227, FRONT-6228 */
import { LightningElement, api, track } from "lwc";
import sbr_3_0_AssignAssetHeaderComponentDesktop from "./sbr_3_0_AssignAssetHeaderComponentDesktop.html";
import sbr_3_0_AssignAssetHeaderComponentMobile from "./sbr_3_0_AssignAssetHeaderComponentMobile.html";
import getStatuses from "@salesforce/apex/SBR_3_0_CustomDataTableCmpController.getOrderItemStatusOptions";
import FORM_FACTOR from "@salesforce/client/formFactor";

const allLocations = [
  /*{ label: "Location Criteria - All", value: "All" },*/ //Commented as a part of 7418
  { label: "All District Branches", value: "District" },
  { label: "All Region Branches", value: "Region" },
  { label: "All Market Branches", value: "Market" },
  { label: "Sourcing Branch", value: "Source" }
];

export default class sbr_3_0_AssignAssetHeaderComponent extends LightningElement {
  @api recordId;
  // @api inventory;
  @track isAnySelected;
  statusOptions;
  selectedStatus = "";
  listViewOptions = [
    {
      label: "Any Status",
      value: ""
    }
  ];
  @track allListViewOptions;
  @track allLocationViewOptions = [];
  selectedView = "Any Status";
  //START: FRONT-10327,10328 initializing it in the connected callback for default value
  @track selectedLocation;
  //END: FRONT-10327, 10328
  itemSearchPlaceholder = `Search this list...`;
  otherLocationSearchPlaceholder = "Search Other Locations";
  @api showAssetStatusFilter = false;
  isMobile = false;
  showFilters = false;
  isFilterActive = false;
  filterOptions = [];
  @track selectedFilterOptions = [];
  appliedFilters = [];
  appliedFiltersDisplay = "All Statuses";

  //testing- need to be changed
  @track selectedValue = "Any Status"; //selected values
  @track selectedValueList = ["Any Status"]; //selected values
  @track locationOptions = allLocations;
  @track comboboxFilters = [];
  @track searchKey = "";
  @track searchLocationInput = "";

  //FRONT-7406 - Start
  @track appliedStatusList = [];
  //START: FRONT-10327 initializing it in the connected callback for default value
  locationFilter;
  //END: FRONT-10327
  //FRONT-7406 - End

  //FRONT-7419 - Start
  locationSearchKey = "";
  @api currentTabName;
  isOtherLocationActive = false;
  //FRONT-7419 - End

  //FRONT-8712 start
  @track searchItem = "";
  @track requiredlocation = true;
  //FRONT-8712 end

  combobox;

  //START: FRONT-10327, 10328
  isItemSearchAssetsTab = false;
  locationFilterPillsLabel = "Location - ";
  //END: FRONT-10327, 10328

  //FRONT-7406 on click of default location filter pill focust to the Location Drop Down
  focusLocationFilter() {
    let fieldToFocus = this.template.querySelector("lightning-combobox");
    //added as part of 7407
    if (this.isMobile) {
      this.showFilters = true;
      setTimeout(() => {
        fieldToFocus = this.template.querySelector("lightning-combobox");
        if (fieldToFocus) {
          // Set focus to the location filter
          fieldToFocus.focus();
        }
      }, 500);
    }
    if (fieldToFocus) {
      fieldToFocus.focus();
    }
  }

  //FRONT-7406 handle pills removal and update the data
  handlePillsRemove(event) {
    let pillLabel = event.target.label;
    let tempList = this.appliedStatusList;
    const index = tempList.indexOf(pillLabel);
    tempList.splice(index, 1);
    this.appliedStatusList = tempList;
    let label = pillLabel.replace("Status - ", "");
    let removedItem = { label: label };
    //uncheck the values on pills removal
    let filterComp = this.template.querySelector(
      "c-sbr_3_0_multi-select-picklist"
    );
    if (this.isMobile) {
      if (this.appliedStatusList.length === 0)
        this.selectedValueList = this.allListViewOptions.map(
          (option) => option.value
        );
      else
        this.selectedValueList = this.selectedValueList.filter(
          (item) => item !== removedItem.label
        );
    }
    if (filterComp) {
      //if the last Status Filter Pill is removed then reset the Filters to
      //Any Status else just update the data based on filters selected
      if (this.appliedStatusList && this.appliedStatusList.length === 0) {
        filterComp.resetFilters();
      } else {
        filterComp.updateFilters(removedItem);
      }
    }
    this.sendFiltersData();
  }

  //FRONT-7406 - Show/Hide Status filter piils on Staus selection
  resetPillsOnStatusChanges() {
    this.appliedStatusList = [];
    let tempStatusList = [];
    let count = 0;
    if (this.selectedValueList) {
      this.selectedValueList.forEach((item) => {
        if (item !== "Any Status") {
          count++;
        }
      });
      let isAllStatusSelected = this.allListViewOptions.length === count + 1;

      if (!isAllStatusSelected) {
        this.selectedValueList.forEach((item) => {
          if (item !== "Any Status") {
            tempStatusList.push("Status - " + item);
          }
        });
      }

      //handling when user clicks on apply filter button after opening the assign asset modal without changing the Status Filters
      //as on initial load in selectedValueList only one value is coming i.e Any Status
      if (
        this.selectedValueList.length === 1 &&
        this.selectedValueList[0] === "Any Status"
      ) {
        tempStatusList = [];
      }
      this.appliedStatusList = tempStatusList;
    }
  }

  //FRONT-7419 search records based on Location Numbers when enter key pressed
  searchLocations(event) {
    event.stopPropagation();
    event.preventDefault();
    if (event.keyCode === 13) {
      if (event.target.value) {
        this.searchItem = false; //FRONT-8712
        this.locationSearchKey = event.target.value;
        this.sendFiltersData();
        /* FRONT - 10273 : Commented & Removed the method that altered the visibility of OtherLocation Field*/
        // this.inventoryCount(); //FRONT-8712
        /* END :  FRONT - 10273*/
      }
    }
  }

  //FRONT-7419 reset records when close icon clicked in the search box
  handleLocationSearchChange(event) {
    event.preventDefault();
    event.stopPropagation();
    this.searchLocations(event);
    if (!event.target.value) {
      this.locationSearchKey = event.target.value;
      this.sendFiltersData();
      this.requiredlocation = true; //FRONT-8712
    }
  }

  //for multiselect picklist
  handleSelectOptionList(event) {
    this.selectedValueList = event.detail.selectedStatus;
    this.isAnySelected = event.detail.isAnyChecked;
    if (!this.isMobile) this.handleFilters(event);
  }

  connectedCallback() {
    this.initListViewOptions();
    this.isMobile = FORM_FACTOR === "Small";

    //7419 - using this variable to show hide other location search box
    if (this.currentTabName === "otherlocation") {
      this.isOtherLocationActive = true;
    }

    //START: FRONT-10327,FRONT-10330, FRONT-10328
    if (this.currentTabName === "itemsearchassets") {
      this.isItemSearchAssetsTab = true;
      this.selectedLocation = "Market";
      this.locationFilter = "Location - All Market Branches";
    } else {
      this.selectedLocation = "Source";
      this.locationFilter = "Location - Sourcing Branch";
    }
    //END: FRONT-10327, 10328
  }

  render() {
    let renderTemplate;
    if (this.isMobile) {
      renderTemplate = sbr_3_0_AssignAssetHeaderComponentMobile;
    } else {
      renderTemplate = sbr_3_0_AssignAssetHeaderComponentDesktop;
    }
    return renderTemplate;
  }

  initListViewOptions() {
    if (this.isMobile) {
      this.listViewOptions = [
        {
          label: "All",
          value: ""
        }
      ];
    } else {
      this.listViewOptions = [
        {
          label: "Any Status",
          value: "Any Status",
          isSelected: false
        }
      ];
    }
    this.allLocationViewOptions.push("Any");
    getStatuses()
      .then((data) => {
        const excludedStatuses = [
          "IN PROGRESS",
          "RETURNED TO VENDOR",
          "Deinstalled",
          "Manufactured",
          "Deleted",
          "HELD FOR SALE",
          "HELD FOR CENTRAL DISPOSAL",
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
          this.listViewOptions.push({
            label: "Unassigned",
            value: "Unassigned",
            isSelected: false
          });
          this.allListViewOptions = new Array(...this.listViewOptions);
        }
      })
      .catch((error) => {
        console.log(error);
      });
  }

  searchItems(event) {
    if (event.keyCode === 13) {
      if (event.target.value) {
        this.searchItem = true; //FRONT-8712
        this.searchKey = event.target.value;
        this.sendFiltersData();
      }
    }
  }

  sendFiltersData() {
    console.log("inside sendFiltersData: " + this.selectedLocation);
    const searchEvent = new CustomEvent("assetsearchupdate", {
      detail: {
        searchKey: this.searchKey,
        selectedStatus: this.selectedValueList,
        selectedLocation: this.selectedLocation,
        locationSearchKey: this.locationSearchKey,
        searchItem: this.searchItem ////FRONT-8712
      }
    });
    this.dispatchEvent(searchEvent);
  }

  handleSearchChange(event) {
    if (!event.target.value) {
      this.searchKey = event.target.value;
      this.sendFiltersData();
    }
  }

  handleChangeLocation(event) {
    if (event.target.value) {
      this.selectedLocation = event.target.value;
      if (!this.isMobile) this.sendFiltersData();
    }

    //FRONT-7406 - update the default Location filter pill text based on the selected location filter
    this.locationOptions.forEach((item) => {
      if (item.value === this.selectedLocation) {
        this.locationFilter = this.locationFilterPillsLabel + item.label;
      }
    });
  }

  //mobile header functions
  toggleFilter(event) {
    this.showFilters = !this.showFilters;
    //console.log('event.target.value'+event.target.value);
    //below check added as a part of 13955
    if (!this.isMobile) {
      if (event && event.target && event.target.value === "Cancel")
        this.resetFilterPanel();
    }
  }

  applyFilter() {
    this.sendFiltersData();
    //this.closeFilterPanel();
    this.buildFilterPills();
    this.toggleFilter();
  }

  resetFilterPanel() {
    this.template
      .querySelector("c-sbr_3_0_multi-select-picklist")
      .resetFilters();
    this.selectedFilterOptions = [];
    this.selectedStatus = "";
    //this.selectedLocation = "Source";
    /*Added as part of FRONT-10327, FRONT-10330, FRONT-10328*/
    if (this.currentTabName === "itemsearchassets") {
      this.selectedLocation = "Market"; //uncommented as a part of 20615
    } else {
      this.selectedLocation = "Source";
    }
    /*FRONT-10327, FRONT-10330, FRONT-10328 Ends here*/
  }

  get filterDisplay() {
    return this.showFilters;
  }

  handleFilters(event) {
    //this.isSearchLoading = true;
    this.buildFilterPills(event.detail);
    this.sendFiltersData();
  }

  buildFilterPills(filters) {
    //FRONT-7406
    this.resetPillsOnStatusChanges();
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

  /* FRONT-8711 */
  @api showErrorOnSearchField() {
    let searchField = this.template.querySelector(
      'lightning-input[data-source="searchInputField"]'
    );
    let sfValue = searchField.value;
    searchField.blur();
    searchField.value = sfValue;

    if (!searchField.classList.contains("errorInputText")) {
      searchField.classList.add("errorInputText");
    }
  }

  @api hideErrorOnSearchField() {
    let searchField = this.template.querySelector(
      'lightning-input[data-source="searchInputField"]'
    );
    if (searchField.classList.contains("errorInputText")) {
      searchField.classList.remove("errorInputText");
    }
  }

  @api showErrorOnLocationField() {
    if (this.isOtherLocationActive) {
      //FRONT-8712 start
      // let locationInputField = this.template.querySelector('lightning-input[data-source="locationInputField"]');
      let locationInputField = this.template.querySelector(
        'lightning-input[data-source="locationSearchInput"]'
      );
      //FRONT-8712 end
      let lfValue = locationInputField.value;
      locationInputField.blur();
      locationInputField.value = lfValue;

      if (
        locationInputField.classList &&
        !locationInputField.classList.contains("errorInputText")
      ) {
        locationInputField.classList.add("errorInputText");
      }
    }
  }

  @api hideErrorOnLocationField() {
    if (this.isOtherLocationActive) {
      //FRONT-8712 start
      // let locationInputField = this.template.querySelector('lightning-input[data-source="locationInputField"]');
      let locationInputField = this.template.querySelector(
        'lightning-input[data-source="locationSearchInput"]'
      );
      //FRONT-8712 end
      if (
        locationInputField &&
        locationInputField.classList.contains("errorInputText")
      ) {
        locationInputField.classList.remove("errorInputText");
      }
    }
  }
  /* END : FRONT-8711 */

  @track currentInventory;

  @api
  get inventory() {
    return this.currentInventory;
  }
  set inventory(value) {
    this.currentInventory = value;
  }

  //FRONT-22933
  handleLocationComboboxFocus(event) {
    const combobox = this.template.querySelector("lightning-combobox");

    if (combobox.className.search("slds-is-open") === -1) {
      combobox.className = "slds-section slds-is-open";
    } else {
      combobox.className = "slds-section slds-is-close";
      combobox.blur();
    }
  }
}