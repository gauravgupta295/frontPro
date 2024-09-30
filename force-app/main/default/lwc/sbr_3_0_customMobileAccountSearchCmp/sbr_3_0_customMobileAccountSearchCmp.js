import { LightningElement, api, wire, track } from "lwc";
// import apex method from salesforce module
import fetchLookupData from "@salesforce/apex/SBR_3_0_CustomLookupController.fetchLookupDataUsingParent";
import fetchDefaultRecord from "@salesforce/apex/SBR_3_0_CustomLookupController.fetchDefaultRecord";
import getAccounts from "@salesforce/apex/SBR_3_0_CustomAccountListViewController.getFilteredAccountsWithoutCacheable";
import { getPicklistValues, getObjectInfo } from "lightning/uiObjectInfoApi";
import ACCOUNT_OBJECT from "@salesforce/schema/Account";
const DELAY = 300; // dealy apex callout timing in miliseconds

const RECORD_TYPE_OPTIONS = [
  { label: "Prospect", value: "Prospect" },
  { label: "Non-Credit", value: "Non-Credit" },
  { label: "Credit", value: "Credit" },
  { label: "Corp Link", value: "Corp Link" },
  { label: "Guest", value: "Guest" } //FRONT-16849
];
import COUNTRY_FIELD from "@salesforce/schema/Account.BillingCountryCode";
import STATE_FIELD from "@salesforce/schema/Account.BillingStateCode";
import DL_STATE_OPTS from "@salesforce/schema/Account.Driver_s_License_State__c";
import { isEmpty } from "c/sbr_3_0_frontlineUtils";
import Sbr_3_0_customMobileSearch_Css from "@salesforce/resourceUrl/Sbr_3_0_customMobileSearch_Css";
import { loadStyle } from "lightning/platformResourceLoader";
import FrontLineCSS from "@salesforce/resourceUrl/FrontLinesCSS";

import EmailEncodingKey from "@salesforce/schema/User.EmailEncodingKey";

//static resources
import noContentSvg from "@salesforce/resourceUrl/NoContentSVG";

//labels /* START::FRONT-2445,2443,2440,2442,2439,3125 */
import phonePlaceholder from "@salesforce/label/c.sbr_3_0_filterPlaceholderForPhone";
import countryPlaceholder from "@salesforce/label/c.Sbr_3_0_CountryPlaceholder";
import DLPlaceholder from "@salesforce/label/c.sbr_3_0_DL";
import AddressPlaceholder from "@salesforce/label/c.sbr_3_0_searchAddressPlaceholder";
import AccountSearchPlaceholder from "@salesforce/label/c.sbr_3_0_AccountNameP";
import StatePlaceholder from "@salesforce/label/c.Sbr_3_0_StateProvincePlaceholder";
import EmailPlaceholder from "@salesforce/label/c.Sbr_3_0_EmailPlaceholder";
/* END::FRONT-2445,2443,2440,2442,2439,3125 */
import { notifyRecordUpdateAvailable, getRecord } from "lightning/uiRecordApi";
import COMPANY_NAME from "@salesforce/schema/User.CompanyName";
import USER_ID from "@salesforce/user/Id";

const JOIN_AND_CLAUSE = " AND ";

export default class Sbr_3_0_customMobileAccountSearchCmp extends LightningElement {
  @track searchKey;
  placeholder = "Search Account";
  @api label = "Custom Lookup Label";
  @api placeholder = "Search Account Name, Phone, Email, Acct #";
  @api iconName = "standard:account";
  @api addIconName = "utility:add";
  @api searchIconName = "utility:search";
  @api sObjectApiName = "Account";
  @api defaultRecordId = "";
  //Modified as part of FRONT-4085
  @api fieldsToInclude =
    "Status__c,Account_Type__c,Phone,Record_Type_Text__c,AccountNumber,RM_Account_Number__c,BillingCity,BillingState,BillingStreet, BillingPostalCode, BillingCountry";
  @api hasCustomNameField = false;
  @api customNameField = "";
  @api fieldsToSet = "";
  @api isDisabled = false;
  @api multiSelect = false;
  @track selectedRecords = [];
  @api selectedRecordsIds = [];
  @track isModalOpen = false;
  @track showAllResults = false;
  @api recordId = "";
  @api whereClause;
  @api searchAccountMobile = false;
  @api filterIcon = "utility:filterList";
  @api iscontract = "";
  RECORD_TYPE_CHECK =
    " RecordType.DeveloperName IN ('Prospect', 'ERP_Link', 'Non_Credit', 'Credit', 'Guest')"; //Added Guest for FRONT-16849
  @track showAllResultsButton = false;
  @track isSearchAccount = true;
  orderClause = " ORDER BY SYSTEMMODSTAMP DESC ";
  limitClause = " LIMIT 100";
  //Modified as part of FRONT-4085
  DEFAULT_FILTERING_FIELDS = [
    "Name",
    "Phone",
    "E_mail_Address__c",
    "RM_Account_Number__c"
  ];

  JOIN_OR_CLAUSE = " OR ";
  fetchCount = false;
  // private properties
  @track lstResult = []; // to store list of returned records
  hasRecords = true;
  searchKey = ""; // to store input field value
  isSearchLoading = false; // to control loading spinner
  delayTimeout;
  selectedRecord = {}; // to store selected lookup record in object formate
  isMobile = false;
  isLoaded = false;
  @track avaiableAccounts = [];
  dlStateOpts = [];
  _countries = [];
  _countryToStates = {};
  strCountry = "";
  //FRONT 2149
  @track comboboxFilters = [];
  @api accName = "";
  @track email = "";
  @track accountTypeFilterValue = "";
  @track driverLicenseNo = "";
  @track editRecordForm = false;
  @track props;
  searchType;
  @track filterRemoved = ''; // FRONT-11596
  @track applyBtn = ''; // FRONT-11596
  @track resetBtn = ''; // FRONT-11596
  @api recordTypeName;//FRONT-20803
  @api parentcmp = ""; //*FRONT-2445,2443,2440,2442,2439,3125 */
  noContentimageUrl = noContentSvg;
  selectedRecId = ""; //added for 4002
  openConversionScreen = false; //added for 4002
  /* START::FRONT-2445,2443,2440,2442,2439,3125 */
  label = {
    phonePlaceholder,
    countryPlaceholder,
    DLPlaceholder,
    AddressPlaceholder,
    AccountSearchPlaceholder,
    StatePlaceholder,
    EmailPlaceholder
  };
  /* END::FRONT-2445,2443,2440,2442,2439,3125 */

  /* Start - 13454 */
  billingCity;
  billingZip;
  billingStateSelected;
  /* End - 13454 */
  connectedCallback() {
    this.loadStyleSheet();
    if (this.defaultRecordId != "") {
      //c/sbr_3_0_customModalCmpthis.setDefaultSelection();
    } else if (this.recordId != "" && this.recordId != null) {
      this.defaultRecordId = this.recordId;
      //this.setDefaultSelection();
      console.log("this.recordId", this.recordId);
    }
    this.isMobile = true;
    this.getRecentRecords();
  }

  loadStyleSheet() {
    loadStyle(this, FrontLineCSS);
  }

  //START::FRONT-13127
  get isAccountScreenParent() {
    return this.parentcmp === 'accountsearchscreen';
  }
  //END::FRONT-13127

  setDefaultSelection() {
    fetchDefaultRecord({
      recordId: this.defaultRecordId,
      sObjectApiName: this.sObjectApiName,
      hasCustomNameField: this.hasCustomNameField
    })
      .then((result) => {
        if (result != null) {
          this.selectedRecord = result;
          this.recordId = result.Id;
          this.handleSelectRecordHelper(); // helper function to show/hide lookup result container on UI
          this.isLoaded = true;
        }
      })
      .catch((error) => {
        console.log("(error---> ", JSON.stringify(error));
        this.error = error;
        this.selectedRecord = {};
        this.recordId = "";
      });
  }

  // wire function property to fetch search record based on user input

  getRecentRecords() {
    this.searchType = "Recent";
    fetchLookupData({
      searchKey: this.searchKey,
      sObjectApiName: this.sObjectApiName,
      whereClause: this.RECORD_TYPE_CHECK,
      fieldsToInclude: this.fieldsToInclude,
      hasCustomNameField: this.hasCustomNameField,
      parentName: ""
    })
      .then((data) => {
        this.isSearchLoading = false;
        this.hasRecords = data.length == 0 ? false : true;
        this.lstResult = JSON.parse(JSON.stringify(data));
        this.avaiableAccounts = this.lstResult;
        console.log("lstresult", this.lstResult);
        for (var i = 0; i < this.lstResult.length; i++) {
          let o = this.lstResult[i];

          if (this.hasCustomNameField) {
            o.DisplayName = o[this.customNameField];
          } else {
            o.DisplayName = o["Name"];
          }
        }
        this.isLoaded = true;
        this.checkforAccountUpdate(); // #Front-3541
      })
      .catch((error) => {
        console.log("(error---> ", JSON.stringify(error));
      });
  }

  getSearchResult() {
    this.whereClause =
      this.buildDefaultQuery() + " AND " + this.RECORD_TYPE_CHECK;

    const filedsToFetch = "Id,Name," + this.fieldsToInclude;
    this.fetchMatchedAccounts(filedsToFetch);
  }

  fetchMatchedAccounts(fieldsToFetch) {
    //this.searchType = 'Recent';
    this.searchType = "Filter";
    getAccounts({
      searchKey: this.searchKey,
      fields: fieldsToFetch,
      objectName: this.sObjectApiName,
      whereClause: this.whereClause,
      orderClause: this.orderClause,
      limitClause: this.limitClause,
      fetchCount: this.fetchCount
    })
      .then((data) => {
        this.parseResult(data);
      })
      .catch((error) => {
        console.log("(error---> ", JSON.stringify(error));
      });
  }

  parseResult(result) {
    try {
      this.wiredAccounts = result.data;
      this.isLoaded = true;
      this.hasRecords = result.data.length == 0 ? false : true;
      this.lstResult = JSON.parse(JSON.stringify(result.data));
      this.avaiableAccounts = this.lstResult;
      console.log("lstresult", this.lstResult);
      for (var i = 0; i < this.lstResult.length; i++) {
        let o = this.lstResult[i];

        if (this.hasCustomNameField) {
          o.DisplayName = o[this.customNameField];
        } else {
          o.DisplayName = o["Name"];
        }
      }
      this.checkforAccountUpdate(); // #Front-3541
    } catch (error) {
      console.log("(error---> ", JSON.stringify(error));
    }
  }

  // update searchKey property on input field change
  handleKeyChange(event) {
    // Debouncing this method: Do not update the reactive property as long as this function is
    // being called within a delay of DELAY. This is to avoid a very large number of Apex method calls.
    if (event.keyCode === 13) {
      event.preventDefault(); /*FRONT-2445,2443,2440,2442,2439,3125 */
      this.isSearchLoading = true;
      this.isLoaded = false;
      window.clearTimeout(this.delayTimeout);
      const searchKey = event.target.value;
      this.searchKey = searchKey;
      this.delayTimeout = setTimeout(() => {
        this.searchKey = searchKey;
      }, DELAY);
      console.log(searchKey);

      //FRONT-3028
      this.clearFilters();

      //FRONT-3019
      this.setDefaultUserCountry();

      if (searchKey.length) {
        this.showAllResultsButton = true;
        this.getSearchResult();
      } else {
        this.showAllResultsButton = false;
        this.getRecentRecords();
      }
    }
  }

  // update searchKey property on input field change
  handleCancleChange(event) {
    this.searchKey = event.target.value;
    if (!event.target.value) {
      this.showAllResultsButton = false;
      this.getRecentRecords();
    }
  }

  // method to toggle lookup result section on UI
  toggleResult(event) {
    const lookupInputContainer = this.template.querySelector(
      ".lookupInputContainerMobile"
    );
    const clsList = lookupInputContainer.classList;
    const whichEvent = event.target.getAttribute("data-source");

    console.log("toggleresult", lookupInputContainer, whichEvent);

    switch (whichEvent) {
      case "searchInputField":
        clsList.add("slds-is-open");
        break;
      case "lookupContainer":
        clsList.remove("slds-is-open");
        break;
    }
  }

  // send selected lookup record to parent component using custom event
  lookupUpdatehandler(value) {
    if (this.multiSelect) {
      const oEvent = new CustomEvent("lookupupdate", {
        detail: this.selectedRecordsIds.join(", ")
      });
      this.dispatchEvent(oEvent);
    } else {
      console.log("this.selectedRecord", JSON.stringify(this.selectedRecord));
      const oEvent = new CustomEvent("lookupupdate", {
        detail: { selectedRecord: value }
      });
      this.dispatchEvent(oEvent);
    }
  }

  //FRONT-2453
  handleRecordClick(event) {
    var objId = event?.target?.getAttribute("data-recid"); // get selected record Id
    if (!objId) objId = event.detail.id;
    this.recordId = objId;
    console.log("selected recordId -> ", this.recordId);

    let frozenSelectedRecord = this.lstResult.find((data) => data.Id === objId); // find selected record from list
    this.selectedRecord = Object.assign({}, frozenSelectedRecord);
    if (this.selectedRecord && this._selectedRecordCopy) {
      this.selectedRecord.Name = this._selectedRecordCopy.title;
      this.selectedRecord.Id = this._selectedRecordCopy.id;
      this.selectedRecord.Record_Type_Text__c =
        this._selectedRecordCopy.Record_Type_Text__c;
    }
    if (
      (this.selectedRecord.Record_Type_Text__c === "Prospect" &&
        this.parentcmp === "orderrequireCustomLookup") ||
      ((this.iscontract === "Contract" || this.recordTypeName === "Create Contract")
        && this.selectedRecord.Record_Type_Text__c === "Guest") //FRONT-16849,20803
    ) {
      this.selectedRecId = this.selectedRecord.Id;
      this.openConversionScreen = true;
    } else {
      if (this.parentcmp === "orderrequireCustomLookup") {
        //Start FRONT-2487: Added If condtition
        if (
          ((this.selectedRecord.Record_Type_Text__c === "Non-Credit" ||
            this.selectedRecord.Record_Type_Text__c === "Credit" ||
            this.selectedRecord.Record_Type_Text__c === "Corp Link") &&
            this.selectedRecord.Status__c === "Active") ||
          this.selectedRecord.Record_Type_Text__c === "Prospect" ||
          this.selectedRecord.Record_Type_Text__c === "Guest" //FRONT-16849
        ) {
          this.handleSelectRecordHelper();
          if (this.multiSelect) {
            this.lookupUpdatehandler(this.selectedRecords);
          } else {
            this.lookupUpdatehandler(this.selectedRecord);
          } // helper function to show/hide lookup result container on UI
        }
      }
      //End FRONT-2487
      else if (this.parentcmp === "accountsearchscreen" ||
        ((this.parentcmp === "customLookup" || this.parentcmp === "quoterequireCustomLookup") && //FRONT-16849
          this.selectedRecord.Record_Type_Text__c === "Guest")) { //FRONT-16849
        //Start FRONT-13601: Else If condtition
        this.handleSelectRecordHelper();
        if (this.multiSelect) {
          this.lookupUpdatehandler(this.selectedRecords);
        } else {
          this.lookupUpdatehandler(this.selectedRecord);
        } // helper function to show/hide lookup result container on UI
      }
      //End FRONT-13601
      else {
        //Start FRONT-11071: Added If condtition
        //Added Prospect condition for the story#FRONT-23624 by Gopal Raj
        if (
          ((this.selectedRecord.Record_Type_Text__c === "Non-Credit" ||
            this.selectedRecord.Record_Type_Text__c === "Prospect") &&
            this.selectedRecord.Status__c !== "Closed" &&
            this.selectedRecord.Status__c !== "Deleted" &&
            this.selectedRecord.Status__c !== "Inactive") ||
          ((this.selectedRecord.Record_Type_Text__c === "Credit" ||
            this.selectedRecord.Record_Type_Text__c === "Corp Link") &&
            this.selectedRecord.Status__c !== "Closed" &&
            this.selectedRecord.Status__c !== "Deleted" &&
            this.selectedRecord.Status__c !== "Inactive" &&
            this.selectedRecord.Status__c !== "Credit Denied")
        ) {
          this.handleSelectRecordHelper();
          if (this.multiSelect) {
            this.lookupUpdatehandler(this.selectedRecords);
          } else {
            this.lookupUpdatehandler(this.selectedRecord);
          } // helper function to show/hide lookup result container on UI
        }
      }
      //End FRONT-11071
    }
  }

  // method to update selected record from search result
  handleSelectedRecord(event) {
    var objId = event?.target?.getAttribute("data-recid"); // get selected record Id
    if (!objId) objId = event.detail.id;
    this.recordId = objId;
    console.log("selected recordId -> ", this.recordId);

    let frozenSelectedRecord = this.lstResult.find((data) => data.Id === objId); // find selected record from list
    this.selectedRecord = Object.assign({}, frozenSelectedRecord);
    if (this.selectedRecord && this._selectedRecordCopy) {
      this.selectedRecord.Name = this._selectedRecordCopy.title;
      this.selectedRecord.Id = this._selectedRecordCopy.id;
      this.selectedRecord.Record_Type_Text__c =
        this._selectedRecordCopy.Record_Type_Text__c;
    }
    this.handleSelectRecordHelper();
    if (this.multiSelect) {
      this.lookupUpdatehandler(this.selectedRecords);
    } else {
      this.lookupUpdatehandler(this.selectedRecord);
    } // helper function to show/hide lookup result container on UI
  }

  /*COMMON HELPER METHOD STARTED*/

  handleSelectRecordHelper() {
    if (this.multiSelect) {
      let addToList = true;
      for (let i = 0; i < this.selectedRecords.length; i++) {
        if (this.selectedRecord.Id == this.selectedRecords[i].Id) {
          addToList = false;
        }
      }

      if (addToList) {
        this.selectedRecords.push(this.selectedRecord);
        this.selectedRecordsIds.push(this.selectedRecord.Id);
        this.template.querySelectorAll("lightning-input").forEach((each) => {
          each.value = "";
        });
      }
    } else {
      // console.log(" this.template.querySelector('.lookupInputContainerMobile').classList.remove('slds-is-open');",  this.template.querySelector('.lookupInputContainerMobile').classList.remove('slds-is-open'))
      // this.template.querySelector('.lookupInputContainerMobile').classList.remove('slds-is-open');

      // const searchBoxWrapper = this.template.querySelector('.searchBoxWrapper');
      // searchBoxWrapper.classList.remove('slds-show');
      // searchBoxWrapper.classList.add('slds-hide');

      // const pillDiv = this.template.querySelector('.pillDiv');
      // pillDiv.classList.remove('slds-hide');
      // pillDiv.classList.add('slds-show');
      this.closeAccountSearchMobile();
    }
  }

  get selectedRecordName() {
    if (this.hasCustomNameField) {
      return this.selectedRecord[this.customNameField];
    } else {
      return this.selectedRecord["Name"];
    }
  }

  @api get defaultRecord() {
    return this.defaultRecordId;
  }
  set defaultRecord(value) {
    this.defaultRecordId = value;

    this.setDefaultSelection();
  }

  //getter & setter for setting the selectedRecord attribute
  @api
  get selectedRecordObject() {
    return this.selectedRecord;
  }
  set selectedRecordObject(value) {
    if (value) {
      if (value.Id) {
        this.selectedRecord = value;
        this.recordId = value.Id;
        this.handleSelectRecordHelper();
      } else {
        this.searchKey = "";
        this.selectedRecord = {};
        this.recordId = "";

        // remove selected pill and display input field again
        const searchBoxWrapper =
          this.template.querySelector(".searchBoxWrapper");
        if (searchBoxWrapper) {
          searchBoxWrapper.classList.remove("slds-hide");
          searchBoxWrapper.classList.add("slds-show");
        }

        const pillDiv = this.template.querySelector(".pillDiv");
        if (pillDiv) {
          pillDiv.classList.remove("slds-show");
          pillDiv.classList.add("slds-hide");
        }
      }
    }
  }

  get accountTypeFilterOptions() {
    return RECORD_TYPE_OPTIONS;
  }
  buildDefaultQuery() {
    let whereClause = "";
    try {
      if (this.searchKey && this.searchKey !== "") {
        const defaultFilters = this.DEFAULT_FILTERING_FIELDS.map((field) => {
          return {
            fieldApiName: field,
            value: this.searchKey
          };
        });
        whereClause = this.buildWhereClause(
          defaultFilters,
          this.JOIN_OR_CLAUSE
        );
      }
    } catch (error) {
      //alert(error);
    }
    return whereClause;
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
    //If something is already present in where clause then add 'AND' in clause before the Record type check
    if (whereClause) {
      whereClause += JOIN_AND_CLAUSE;
    }
    //Add Record Type check so that Accounts of only 4 record types are shown
    whereClause += this.RECORD_TYPE_CHECK;
    return whereClause === "" ? whereClause : ` WHERE ${whereClause}`;
  }

  createNewAccount(event) {
    this.isSearchAccount = false;
    this.isModalOpen = true;
  }
  //4002

  closeConvertModal() {
    this.openConversionScreen = false; //4002
  }

  closeModal() {
    this.isModalOpen = false;
    this.closeAccountSearchMobile();
  }

  closeAccountSearchMobile() {
    const closeModal = new CustomEvent("closemodal", { isModalOpen: false });
    this.dispatchEvent(closeModal);
  }

  submitDetails() {
    this.isModalOpen = false;
  }

  @track showFilters = false;

  openFilters() {
    this.showFilters = !this.showFilters;
    // FRONT-12020
    // Focus the filter close button when filter opens.
    window.setTimeout(() => {
      let ele = this.template.querySelector('.filters-close-button');

      if (ele && ele.focus) {
        ele.focus();
      }
    }, 5);
  }

  @track streetAddressValue = "";
  @track phoneValue = "";
  @track stateSelected = "";

  handleCountryChange(event) {
    this.strCountry = event.target.value;
  }

  handleStateChange(event) {
    this.stateSelected = event.target.value;
    console.log("stateSelected", this.stateSelected, event.target);
  }

  handleBillingStateChange(event) {
    this.billingStateSelected = event.target.value;
    // console.log("stateSelected", this.stateSelected, event.target);
  }

  handleStreetAddressChange(event) {
    this.streetAddressValue = event.target.value;
  }
  handlePhoneChange(event) {
    this.phoneValue = event.target.value;
  }

  filterData() {
    let avaiableAccounts = JSON.parse(JSON.stringify(this.avaiableAccounts));
    if (this.stateSelected) {
      console.log(this.stateSelected);
      avaiableAccounts = avaiableAccounts.filter((account) => {
        return account.BillingState.includes(this.stateSelected);
      });
    }

    if (this.streetAddressValue) {
      avaiableAccounts = avaiableAccounts.filter((account) => {
        let lowerCaseChars = account.BillingStreet.toLowerCase();
        return lowerCaseChars.includes(this.streetAddressValue);
      });
    }

    if (this.phoneValue) {
      avaiableAccounts = avaiableAccounts.filter((account) => {
        let phoneDigits = "";
        if (account.Phone) {
          phoneDigits = account.Phone.replace("(", "")
            .replace(")", "")
            .replace("-", "")
            .replace(" ", "");
          // console.log('phonedigits', phoneDigits)
        }
        return phoneDigits.includes(this.phoneValue);
      });
      this.resultCount = avaiableAccounts.length;
    }

    this.lstResult = avaiableAccounts;
    console.log(this.lstResult);
  }

  hideResults(event) {
    console.log("From Mobile", event.detail);
    const hideResults = new CustomEvent("hideresults", {
      detail: event.detail
    });
    this.dispatchEvent(hideResults);
  }

  handleFilterCancel() {
    this.showFilters = false;

    // FRONT-12020
    // Focus the filter icon after the filter is closed.
    const setFocus = window.setTimeout(() => {
      let ele = this.template.querySelector('.filter-button-mobile');
      if (ele && ele.focus) {
        ele.focus();
        window.clearTimeout(setFocus);
      }
    }, 200);
  }

  @wire(getObjectInfo, { objectApiName: ACCOUNT_OBJECT })
  objectInfo;

  @wire(getPicklistValues, {
    recordTypeId: "$objectInfo.data.defaultRecordTypeId",
    fieldApiName: DL_STATE_OPTS
  })
  dlstateCode({ data, error }) {
    if (data) {
      this.dlStateOpts = data?.values;
      console.log("dlstateoptions", this.dlStateOpts);
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
    console.log("map", validForNumberToCountry);
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

  get countryOptions() {
    return this._countries;
  }

  get stateOptions() {
    let stateOpts = this.strCountry
      ? this._countryToStates[this.strCountry]
      : this.dlStateOpts;
    return stateOpts;
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
    console.log("even:" + event.target.value);
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

  _rendered = false;
  // Resolved Bug - #2541
  renderedCallback() {
    /* START::FRONT-2445,2443,2440,2442,2439,3125 */
    this.setFocusOnFirstElement();
    if (
      this.parentcmp == "quoterequireCustomLookup" ||
      this.parentcmp == "orderrequireCustomLookup"
    ) {
      var ite = this.template.querySelectorAll('[data-id="Quote"]');
      ite.forEach((ele) => ele.classList.add("demo"));
    } /* END::FRONT-2445,2443,2440,2442,2439,3125 */
  }

  //FRONT-2149
  handleFilterChange(event) {
    if (event.target.label === "Account Name") {
      this.accName = event.target.value;
    } else if (event.target.label === "Account Type") {
      this.accountTypeFilterValue = event.target.value;
    } else if (event.target.label === "D/L Number") {
      this.driverLicenseNo = event.target.value;
    } else if (event.target.label === "Email Address") {
      this.email = event.target.value;
    } else if (event.target.label === "Billing City") {
      this.billingCity = event.target.value;
    } else if (event.target.name === "BillingPostalCode") {
      this.billingZip = event.target.value;
    }
    console.log("Field:" + event.target.value);
  }

  get showFilterPills() {
    loadStyle(this, Sbr_3_0_customMobileSearch_Css);
    return this.comboboxFilters && this.comboboxFilters.length > 0;
  }

  /**
   * Story Number : Front-2103
   * Developer    : Kishore Meesala
   */
  applyFilters() {
    /** added for 11596 ****/
    // Announce "Button clicked" only once
    if (isEmpty(this.applyBtn)) {
      this.applyBtn = 'Filters Added';




    }
    // Clear the announcement after some time to ensure the same message can be announced again if needed
    //Removed SetTimeout from above to this line for FRONT-11596, iphone issue
    setTimeout(() => {
      this.isLoaded = false;
      let filters = [];
      let hasErrors = false;
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
        //FRONT-3028
        //this.searchKey = null;
        this.searchKey = "";

        this.comboboxFilters = filters;
        this.showFilters = false;

        this.buildFilterPills(this.comboboxFilters);
        // FRONT-12020
        // Focus the filter icon after the filter is closed and after the results are loaded.
        const parentLWC = this;
        var setFocus = window.setInterval(() => {
          if (parentLWC.isLoaded) {
            let ele = this.template.querySelector('.filter-button-mobile');
            if (ele && ele.focus) {
              ele.focus();
            }
            window.clearInterval(setFocus);
          }
        }, 2);
      } else {
        this.isLoaded = true;
      }
      //Added for 2447,2448
      if (this.comboboxFilters.length) {
        this.showAllResultsButton = true;
      }

      this.applyBtn = '';
    }, 2000); // Adjust the timeout duration as necessary
  }

  /**
   * Story Number : Front-2103
   * Developer    : Kishore Meesala
   */
  buildFilterPills(filters) {
    if (!filters) {
      this.comboboxFilters = [];
    } else {
      this.comboboxFilters = filters.map((filter) => {
        //if (filter.fieldApiName === "Name") this.searchKey = filter.value;

        let label = filter.filterLabel || filter.label;
        return {
          get label() {
            return `${this.filterLabel} - ${this.value}`;
          },
          value: filter.value,
          filterLabel: label,
          fieldApiName: filter.fieldApiName,
          operator: filter.operator
        };
      });
    }
    let whereClause;

    if (this.comboboxFilters.length === 0 && this.searchKey !== "") {
      whereClause = this.buildDefaultQuery();
    } else {
      whereClause = this.buildWhereClause(
        this.comboboxFilters,
        JOIN_AND_CLAUSE
      );
    }
    //START: ,FRONT-2447,FRONT 2448
    if (this.comboboxFilters.length != 0) {
      this.runFiltering(whereClause);
    }
    //END: FRONT-2447,FRONT 2448
  }

  /**
   * Story Number : Front-2103
   * Developer    : Kishore Meesala
   */
  runFiltering(whereClause) {
    this.whereClause = whereClause;
    //this.whereClause =  this.buildDefaultQuery() + ' AND ' + this.RECORD_TYPE_CHECK;
    const filedsToFetch = "Id,Name," + this.fieldsToInclude;
    this.fetchMatchedAccounts(filedsToFetch);
  }

  handlePillRemoveClick(event) {
    /** added for 11596 ****/
    if (!this.filterRemoved) {
      let filterSelected = event.detail.item;
      let selectedFilterLabel = filterSelected.filterLabel;
      let filterRemove = " filter removed";
      this.filterRemoved = `${selectedFilterLabel} ${filterRemove}`;
      // Clear the announcement after some time to ensure the same message can be announced again if needed
      setTimeout(() => {
        this.filterRemoved = '';
      }, 1000); //increased the time for FRONT-11596 for iphone issue, Adjust the timeout duration as necessary
    }
    //this.isSearchLoading = true;
    const index = event.detail.index;
    const removedItem = event.detail.item;
    if (this.comboboxFilters[index].fieldApiName === "Name")
      this.searchKey = "";

    this.comboboxFilters.splice(index, 1);
    //START: FRONT-2447,FRONT 2448
    if (this.comboboxFilters.length === 0) {
      // this.searchKey = "";
      this.showAllResultsButton = false;
      this.getRecentRecords();
    }
    //END:2447,2448
    this.buildFilterPills(this.comboboxFilters);
    this.updateFilters(removedItem);
  }

  updateFilters(removedItem) {
    if (removedItem.fieldApiName === "Name") {
      this.accName = null;
    } else if (removedItem.fieldApiName === "Record_Type_Text__c") {
      this.accountTypeFilterValue = null;
    } else if (removedItem.fieldApiName === "BillingStreet") {
      this.streetAddressValue = null;
    } else if (removedItem.fieldApiName === "Phone") {
      this.phoneValue = null;
    } else if (removedItem.fieldApiName === "BillingCountryCode") {
      this.strCountry = null;
    } else if (removedItem.fieldApiName === "Driver_s_License_State__c") {
      this.stateSelected = null;
    } else if (removedItem.fieldApiName === "Drivers_License__c") {
      this.driverLicenseNo = null;
    } else if (removedItem.fieldApiName === "E_mail_Address__c") {
      this.email = null;
    } else if (removedItem.fieldApiName === "BillingCity") {
      this.billingCity = null;
    } else if (removedItem.fieldApiName === "BillingPostalCode") {
      this.billingZip = null;
    } else if (removedItem.fieldApiName === "BillingState") {
      this.billingStateSelected = null;
    }
    this.comboboxFilters = this.comboboxFilters.filter(
      (filter) => filter.fieldApiName !== removedItem.fieldApiName
    );
  }

  /**
   * Story Number : Front-2103
   * Developer    : Kishore Meesala
   */
  resetFilters() {
    /** added for 11596 ****/
    if (!this.resetBtn) {
      this.resetBtn = 'All Filters Removed';
      // Clear the announcement after some time to ensure the same message can be announced again if needed
      setTimeout(() => {
        this.resetBtn = '';
      }, 1000); // Adjust the timeout duration as necessary
    }
    this.clearFilters();
    this.setDefaultUserCountry();
    this.isLoaded = false;
    this.showAllResultsButton = false;
    this.getRecentRecords();
  }

  /**
   * Story Number : Front-3028
   * Developer    : Kishore Meesala
   */
  clearFilters() {
    this.accName = null;
    this.accountTypeFilterValue = null;
    this.streetAddressValue = null;
    this.phoneValue = null;
    this.strCountry = null;
    this.stateSelected = null;
    this.driverLicenseNo = null;
    this.email = null;
    this.comboboxFilters = [];
    this.billingCity = null;
    this.billingZip = null;
    this.billingStateSelected = null;
  }
  //START: FRONT-3033, FRONT-2621, FRONT- 3115, FRONT-3125
  async openEditForm(event) {
    const selectedId = event.detail;
    const selectedRecord = this.lstResult.filter(
      (result) => result.Id === selectedId
    )[0];
    this.props = {
      recordId: selectedRecord.Id,
      recordTypeName: selectedRecord.Record_Type_Text__c,
      recordTypeId: selectedRecord.RecordTypeId
    };
    this.editRecordForm = true;
  }

  closeEditModal() {
    this.editRecordForm = false;
  }

  handleForceRefresh() {
    this.isLoaded = false;
    this.refreshData();
  }

  refreshData() {
    //FRONT-4002
    if (this.openConversionScreen == false) {
      if (this.searchType == "Recent") {
        this.isLoaded = true;
        this.getRecentRecords();
      } else {
        this.isLoaded = true;
        const filedsToFetch = "Id,Name," + this.fieldsToInclude;
        this.fetchMatchedAccounts(filedsToFetch);
      }
    }
  }

  // Start:  #Front-3541
  updatedRecordEvent;
  handleSaveAndSelectRecord(event) {
    this.updatedRecordEvent = event;
    this._selectedRecordCopy = event.detail;
    this.handleSelectedRecord(this.updatedRecordEvent);
    this.refreshData();
  }

  checkforAccountUpdate() {
    if (this.updatedRecordEvent) {
      this.updatedRecordEvent = null;
    }
  }
  //End:  #Front-3541
  //END: FRONT-3033, FRONT-2621, FRONT- 3115, FRONT-3125

  /**
   * Story Number : Front-3019
   * Developer    : Kishore Meesala
   */
  @wire(getRecord, { recordId: USER_ID, fields: [COMPANY_NAME] })
  UserDetails({ error, data }) {
    console.log("Data?", data);
    if (data) {
      if (data.fields.CompanyName.value !== null) {
        console.log("Check if company code?", data.fields.CompanyName.value);
        this.companyCode = data.fields.CompanyName.value;
        this.setDefaultUserCountry();
      }
    }
  }
  /**
   * Story Number : Front-3019
   * Developer    : Kishore Meesala
   */
  setDefaultUserCountry() {
    console.log("Check if company code there?", this.companyCode);
    if (this.companyCode) {
      if (this.companyCode === "01") {
        this.strCountry = "US";
      } else if (this.companyCode === "02") {
        this.strCountry = "CA";
      }
    }
  }

  get getBackgroundImage() {
    return `background-image:url("${this.noContentimageUrl}")`;
  }
  //Added for 4002

  openConversionForm(event) {
    this.selectedRecId = event.detail;
    this.openConversionScreen = true;
  }

  setFocusOnFirstElement(identifier = ".search-account-input") {
    // eslint-disable-next-line @lwc/lwc/no-async-operation
    window.setTimeout(() => {
      if (!this._rendered) {
        let ele = this.template.querySelector(identifier);
        if (ele && ele.focus) {
          ele.focus();
          this._rendered = true;
        }
      }
    }, 5);
  }
}