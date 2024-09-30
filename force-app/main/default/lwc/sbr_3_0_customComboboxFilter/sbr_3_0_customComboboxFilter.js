import { LightningElement, api, track, wire } from "lwc";
import { getPicklistValues, getObjectInfo } from "lightning/uiObjectInfoApi";
import COUNTRY_FIELD from "@salesforce/schema/Account.BillingCountryCode";
import STATE_FIELD from "@salesforce/schema/Account.BillingStateCode";
import EMAIL from "@salesforce/schema/Account.E_mail_Address__c";
import ACCNAME_FIELD from "@salesforce/schema/Account.Name";
import PHONE_FIELD from "@salesforce/schema/Account.Phone";
import LICENSE_FIELD from "@salesforce/schema/Account.Drivers_License__c";
import BILLINGADD_FIELD from "@salesforce/schema/Account.BillingAddress";
import ACCOUNT_OBJECT from "@salesforce/schema/Account";
import DL_STATE_OPTS from "@salesforce/schema/Account.Driver_s_License_State__c";
import Country from "@salesforce/schema/Lead.Country";
import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import USER_ID from "@salesforce/user/Id";
import Address from "@salesforce/schema/Lead.Address";
import { isEmpty } from "c/sbr_3_0_frontlineUtils";
import COMPANY_NAME from "@salesforce/schema/User.CompanyName";

/** The delay used when debouncing event handdlers before invoking functions. */
const RECORD_TYPE_OPTIONS = [
  { label: "Prospect", value: "Prospect" },
  { label: "Non-Credit", value: "Non-Credit" },
  { label: "Credit", value: "Credit" },
  { label: "Corp Link", value: "Corp Link" },
  { label: "Guest", value: "Guest" } //Front-14007
];
const BASE_CLASSES =
  "slds-dropdown slds-dropdown_fluid filter-options inner-dropdown-element";
const ERROR_STACK = ["badInput", "valueMissing"];
const FLOW_IDENTIFIER = "/flow/";

export default class ReusableCustomDropdownWithSearchLwc extends LightningElement {
  //functional properties
  @track disabled = false;
  @track picklistOpenDropdown = false;
  @track openDropDown = false;
  @track closeDropdown = true;
  @track inputValue = "";
  @track options;
  delaytimeout;
  @api accName = "";
  @track accType = "";
  @track accAdd = "";
  @track accCity = "";
  @track accZip = "";
  @track phone = "";
  @track country = "";
  @track dlstate = "";
  @track blstate = "";
  @track email = "";
  @track isInitialClick = true;
  @track strCountry = "";
  @track driverLicenseNo = "";
  @track filterList = [];
  phoneErrMsg = "";
  dlStateOpts = [];
  _countries = [];
  _countryToStates = {};
  filters = [];
  //FRONT-11596
  @track applyBtn = "";
  @track resetBtn = "";

  //strCountry = "";
  //variables for DL picklist
  searchResults;
  selectedSearchResult;
  picklistOrdered = [];
  showSearchResults = false;
  //FRONT-3018 AD
  companyCode;

  focusSetByClick = false; //FRONT-11596

  connectedCallback() {
    this.computeFilterCSS();
    this.template.addEventListener("click", this.stopClickPropagation);
  }

  get recordTypes() {
    return RECORD_TYPE_OPTIONS;
  }
  get computedDropDownClasses() {
    if (this.openDropDown) {
      return `${BASE_CLASSES} is-filter-open`;
    } else {
      return BASE_CLASSES;
    }
  }

  search(event) {
    const input = event.target.value.toLowerCase();
    if (input !== "") {
      this.showSearchResults = true;
    } else {
      this.searchResults = this.picklistOrdered;
      this.showSearchResults = true;
      return;
    }
    try {
      const result = this.picklistOrdered.filter((picklistOption) =>
        picklistOption.label.toLowerCase().includes(input)
      );
      this.searchResults = result;
    } catch (e) {
      console.log(e);
    }
  }

  selectSearchResult(event) {
    const selectedValue = event.currentTarget.dataset.value;
    this.selectedSearchResult = this.picklistOrdered.find(
      (picklistOption) => picklistOption.value === selectedValue
    );

    this.clearSearchResults();
  }

  clearSearchResults() {
    this.searchResults = null;
  }

  showPicklistOptions() {
    if (!this.searchResults) {
      if (this.strCountry === "") {
        this.searchResults = this.dlStateOpts;
        this.picklistOrdered = this.dlStateOpts;
      } else {
        let stateOpts = this._countryToStates[this.strCountry] || [];
        this.searchResults = stateOpts;
        this.picklistOrdered = stateOpts;
      }
    }
  }

  hidePicklistOptions(event) {
    this.showSearchResults = false;
  }
  //Picklist values
  get statecodeData() {
    //let stateOpts = this._countryToStates[this.strCountry] || [];
    let stateOpts = this.strCountry
      ? this._countryToStates[this.strCountry]
      : this.dlStateOpts;
    return stateOpts;
  }
  get countryOptions() {
    return this._countries;
  }
  computedFilterCmpCSS;

  //FRONT-3018 AD
  @wire(getRecord, { recordId: USER_ID, fields: [COMPANY_NAME] })
  UserDetails({ error, data }) {
    if (data) {
      if (data.fields.CompanyName.value !== null) {
        this.companyCode = data.fields.CompanyName.value;
      }
    }
  }
  //END of FRONT-3018 AD

  @wire(getObjectInfo, { objectApiName: ACCOUNT_OBJECT })
  objectInfo;

  @wire(getPicklistValues, {
    recordTypeId: "$objectInfo.data.defaultRecordTypeId",
    fieldApiName: DL_STATE_OPTS
  })
  dlstateCode({ data, error }) {
    if (data) {
      this.dlStateOpts = data?.values;
      this.showPicklistOptions();
    }
  }

  @wire(getPicklistValues, {
    recordTypeId: "$objectInfo.data.defaultRecordTypeId",
    fieldApiName: COUNTRY_FIELD
  })
  countryCode({ data, error }) {
    if (data) {
      this._countries = data?.values;
    }
  }

  //getting states for picklist
  @wire(getPicklistValues, {
    recordTypeId: "$objectInfo.data.defaultRecordTypeId",
    fieldApiName: STATE_FIELD
  })
  stateCode({ data, error }) {
    if (!data) {
      return;
    }
    const validForNumberToCountry = Object.fromEntries(
      Object.entries(data.controllerValues).map(([key, value]) => [value, key])
    );
    this._countryToStates = data.values.reduce((accumulatedStates, state) => {
      const countryIsoCode = validForNumberToCountry[state.validFor[0]];
      return {
        ...accumulatedStates,
        [countryIsoCode]: [
          ...(accumulatedStates?.[countryIsoCode] || []),
          state
        ]
      };
    }, {});
  }

  //Method to handle readonly input click
  handleInputClick(event) {
    event.preventDefault();
    event.stopPropagation();

    this.resetParameters();
    this.toggleOpenDropDown(true);
    this.adjustHeight();
    this.setDefaultUserCountry();
  }
  //FRONT-3018 AD
  setDefaultUserCountry() {
    if (this.companyCode) {
      if (this.companyCode === "01" && this.isInitialClick) {
        this.strCountry = "US";
      }
      //this.isInitialClick added as part of FRONT-13453
      else if (this.companyCode === "02" && this.isInitialClick) {
        this.strCountry = "CA";
      }
    }
  }

  //END OF FRONT-3018

  //Method to reset necessary properties
  resetParameters() {
    this.setInputValue("");
    this.optionsToDisplay = this.options;
  }

  //Method to set inputValue for search input box
  setInputValue(value) {
    this.inputValue = value;
  }

  //Method to set label and value based on
  //the parameter provided
  setValues(value, label) {
    this.label = label;
    this.value = value;
  }

  //Method to toggle openDropDown state
  toggleOpenDropDown(toggleState) {
    this.openDropDown = !this.openDropDown;
  }
  togglePicklisDropDown(toggleState) {
    this.picklistOpenDropdown = !this.picklistOpenDropdown;
  }

  //getter setter for labelClass
  get labelClass() {
    return this.fieldLabel && this.fieldLabel !== ""
      ? "slds-form-element__label slds-show"
      : "slds-form-element__label slds-hide";
  }
  get picklistDropdown() {
    let picklisdropdownVal = this.picklistOpenDropdown
      ? "slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-is-open"
      : "slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click";
    return picklisdropdownVal;
  }
  //getter setter for dropDownClass
  get dropDownClass() {
    let drodownVal = this.openDropDown
      ? "slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-is-open"
      : "slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click";
    return drodownVal;
  }

  get isDropdownOpen() {
    return this.openDropDown ? true : false;
  }
  // FRONT-11490 passed dynamic aria label for ipad accessibility fix
  get comboBoxAria() {
    let isIpad =
      /Macintosh/i.test(navigator.userAgent) &&
      navigator.maxTouchPoints &&
      navigator.maxTouchPoints > 1;
    if (isIpad) {
      return this.openDropDown ? "combo box expanded" : "combo box collapsed";
    }
    return "";
  }

  handleFilterChange(event) {
    if (event.target.label === "Account Name") {
      this.accName = event.target.value;
    } else if (event.target.label === "Account Type") {
      this.accType = event.target.value;
    } else if (event.target.label === "Billing Address") {
      this.accAdd = event.target.value;
    } else if (event.target.label === "Phone") {
      this.phone = event.target.value;
    } else if (event.target.label === "Country") {
      this.strCountry = event.target.value;
      this.showPicklistOptions();
    } else if (event.target.label === "Driver's License State/Province") {
      this.dlstate = event.target.value;
    } else if (event.target.label === "Drivers License Number") {
      this.driverLicenseNo = event.target.value;
    } else if (event.target.label === "Email address") {
      this.email = event.target.value;
    }
    //FRONT-13453 Starts
    else if (event.target.label === "Billing City") {
      this.accCity = event.target.value;
    } else if (event.target.label === "Billing Zipcode") {
      this.accZip = event.target.value;
    } else if (event.target.label === "Billing State") {
      this.blstate = event.target.value;
    }
    //FRONT-13453 End

    console.log("Field:" + event.target.value);
  }

  applyFilters() {
    /** added for 11596 ****/
    // Announce "Button clicked" only once
    if (!this.applyBtn) {
      this.applyBtn = "Filters Added";
      // Clear the announcement after some time to ensure the same message can be announced again if needed
      setTimeout(() => {
        this.applyBtn = "";
      }, 1000); // Adjust the timeout duration as necessary
    }

    let filters = [];
    let hasErrors = false;
    this.isInitialClick = false;
    const filterElements = this.template.querySelectorAll(
      '[data-field-class="filterOption"]'
    );
    if (!isEmpty(filterElements)) {
      for (let filter of filterElements) {
        if (!filter.validity.valid) {
          hasErrors = true;
          break;
        }
        let val = filter.value;

        if (!isEmpty(val)) {
          filters.push({
            label: filter.label,
            value: filter.value,
            fieldApiName: filter.dataset.id,
            operator: filter.dataset.attribute
          });
        }
      }
    }

    if (!hasErrors && !isEmpty(filters)) {
      this.filters = filters;
      let filterEvent = new CustomEvent("filterevent", {
        detail: this.filters
      });
      // Dispatches the event.
      this.dispatchEvent(filterEvent);
      this.openDropDown = false;

      // FRONT-12020
      // Focus the filter input/combo box after applying filters.
      const dropdown = this.template.querySelector(".combobox-input-class");
      if (dropdown) {
        dropdown.focus();
      }
    }
    this.focusSetByClick = false;
  }

  //FROMT-3020 Added api annotation to this method as it is called from customAccountListViewCmp component
  @api resetFilters() {
    /** added for 11596 ****/
    if (!this.resetBtn) {
      this.resetBtn = "All Filters Removed";
      // Clear the announcement after some time to ensure the same message can be announced again if needed
      setTimeout(() => {
        this.resetBtn = "";
      }, 1000); // Adjust the timeout duration as necessary
    }

    this.template
      .querySelectorAll('[data-field-class="filterOption"]')
      .forEach((element) => {
        element.value = "";
      });
    this.template.querySelector('[data-id="BillingCountryCode"]').value =
      this.strCountry;

    this.filters = [];
    this.openDropDown = false;
    let filterEvent = new CustomEvent("filterevent");
    this.dispatchEvent(filterEvent);

    // FRONT-12020
    // Focus the filter input/combo box after resetting filters.
    const dropdown = this.template.querySelector(".combobox-input-class");
    if (dropdown) {
    	dropdown.focus();
    }
    this.focusSetByClick = false;
  }
  handlePhone(event) {
    const field = event.target.label;
    switch (field) {
      case "Phone":
        this.validatePhoneNumber(event);
        break;
    }
  }
  validatePhoneNumber(event) {
    let hasError = false;
    const regex = /^\d+$/;
    if (!regex.test(event.target.value) && event.target.value !== "") {
      event.target.setCustomValidity("Use Numbers Only (0-9)");
      hasError = true;
    }

    if (!hasError) {
      event.target.setCustomValidity("");
    }
    event.target.reportValidity();
  }

  @api
  updateFilters(removedItem) {
    const filterEle = this.template.querySelector(
      `[data-id="${removedItem.fieldApiName}"]`
    );
    if (filterEle) {
      filterEle.value = null;
      this.filters = this.filters.filter(
        (filter) => filter.fieldApiName !== removedItem.fieldApiName
      );
    }
  }

  get filterLabel() {
    let label = "Filters";
    if (this.filters.length > 0) {
      label = `${this.filters.length} Filters Selected`;
    }
    return label;
  }

  computeFilterCSS() {
    const currentUrl = window.location.href;
    if (currentUrl.indexOf(FLOW_IDENTIFIER) !== -1) {
      this.computedFilterCmpCSS = "filter-element-quote";
    } else {
      this.computedFilterCmpCSS = "slds-p-top--small";
    }
  }

  @api
  closeFilterDropDown() {
    this.openDropDown = false;
  }

  @api
  adjustHeight() {
    const dropdown = this.template.querySelector(".inner-dropdown-element");
    const viewPortHeight = window.innerHeight;
    //FRONT-7753 Updated the if condition to set the height accordingly
    if (
      viewPortHeight - dropdown.getBoundingClientRect().top <
      dropdown.scrollHeight
    ) {
      const comboboxFinalHeight =
        viewPortHeight - dropdown.getBoundingClientRect().top;
      dropdown.style.height = comboboxFinalHeight + "px";
    } else {
      dropdown.style.height = "auto";
    }
  }

  stopClickPropagation(event) {
    event.stopPropagation();
  }

  //FRONT-11447
  handleKeyUp(event) {
    console.log("===event.keyCode===", event.keyCode);
    event.preventDefault();
    event.stopPropagation();
    if (event.keyCode === 13) {
      this.handleInputClick(event);
    }
  }

  //FRONT-11596
  handleInputClickProgramatically() {
    this.focusSetByClick = true;
  }
}