/* eslint-disable @lwc/lwc/no-async-operation */
/* eslint-disable @lwc/lwc/no-leading-uppercase-api-name */
/* eslint-disable @lwc/lwc/valid-api */
/* eslint-disable @lwc/lwc/no-api-reassignments */
/* eslint-disable eqeqeq */
/* eslint-disable no-constant-condition */
/* eslint-disable no-unused-vars */
import { LightningElement, track, api, wire } from "lwc";
import fetchLookupData from "@salesforce/apex/SBR_3_0_CustomLookupController.fetchLookupData";
import fetchDefaultRecord from "@salesforce/apex/SBR_3_0_CustomLookupController.fetchDefaultRecord";
import getAccounts from "@salesforce/apex/SBR_3_0_CustomAccountListViewController.getFilteredAccounts";
import FrontLineCSS from "@salesforce/resourceUrl/FrontLinesCSS";
import Sbr_3_0_customModalCmpDesktop_Css from "@salesforce/resourceUrl/Sbr_3_0_customModalCmpDesktop_Css";
import { loadStyle } from "lightning/platformResourceLoader";
import { getRecord } from "lightning/uiRecordApi";
import accountSearchDesktopTemplate from "./sbr_3_0_customAccountListViewCmpAccountSearch.html";
import customSearchDesktopTemplate from "./sbr_3_0_customAccountListViewCmp.html";
const DELAY = 300; // dealy apex callout timing in miliseconds
const DEFAULT_ORDER_CLAUSE = " ORDER BY SYSTEMMODSTAMP DESC";

const DEFAULT_LIMIT_CLAUSE = " LIMIT 100";
//Modified as part of FRONT-2133
const DEFAULT_FILTERING_FIELDS = [
  "Name",
  "Phone",
  "E_mail_Address__c",
  "RM_Account_Number__c"
];
const JOIN_AND_CLAUSE = " AND ";
const JOIN_OR_CLAUSE = " OR ";
//Added for Front-14007
const RECORD_TYPE_CHECK =
  " RecordType.DeveloperName IN ('Prospect', 'ERP_Link', 'Non_Credit', 'Credit','Guest')"; //FRONT-1730 Record Types check
//Front - 1272 - Start
import { getObjectInfo } from "lightning/uiObjectInfoApi";
import ACCOUNT_OBJECT from "@salesforce/schema/Account";
import Id from "@salesforce/schema/Account.Id";
//Front - 1272 - End
import {
  isUndefined,
  isEmpty,
  isUndefinedOrNull
} from "c/sbr_3_0_frontlineUtils";
import { refreshApex } from "@salesforce/apex";
/* Imported logger framework */
import { Logger } from "c/sbr_3_0_frontlineUtils";

import LABELS from "c/sbr_3_0_customLabelsCmp"; //FRONT-8351
//FRONT-1681 Const Map variable for Account's Status__c field values
const ACCOUNT_STATUS_VALUES = Object.freeze({
  ACTIVE: "Active",
  INACTIVE: "Inactive",
  CLOSED: "Closed",
  DELETED: "Deleted",
  ONHOLD: "On Hold",
  BADDEBT: "Bad Debt",
  NONE: "None",
  SUSPENDED: "Suspended",
  CREDITDENIED: "Credit Denied"
});
/* Initiated Logger */
const logger = Logger.create(true);

export default class Sbr_3_0_customAccountListViewCmp extends LightningElement {
  @track modalHeader = "Account Search";
  @track resultCount = 0;
  @api _searchKey = "";
  @api isContract; //front-14007
  @api
  get searchKey() {
    return this._searchKey;
  }

  set searchKey(key) {
    this._searchKey = key;
    let whereClause = this.buildDefaultQuery();
    this.runFiltering(whereClause);
    //this.isEnterClicked = true; FRONT-22445
  }
  sObjectApiName = "Account";
  fieldsToInclude =
    "Id, Name,Phone,Record_Type_Text__c,Driver_s_License_State__c,Drivers_License__c, E_mail_Address__c,BillingStateCode,BillingStreet,BillingPostalCode,BillingCountryCode, RecordTypeId, RecordType.DeveloperName, RecordType.Name, Status__c";
  @api recordId = "";
  @api hasCustomNameField = false;
  @api whereClause;
  @api customNameField = "";
  @api fieldsToSet = "";
  @track openAccountScreen = false;
  copyOfData;
  @api parentcmp = "";
  //FRONT 1062
  userProfileName;
  selectedRow;
  selectedRow2;
  rowId;
  rowName;
  accId = "";
  @track editRecordForm = false;
  @track editConversionFrom = false;
  @api recordTypeName; //Front-20803
  // private properties
  lstResult = []; // to store list of returned records
  hasRecords = true;
  isSearchLoading = false; // to control loading spinner
  delayTimeout;
  selectedRecord = {}; // to store selected lookup record in object format
  fetchCount = false; //FRONT-10250
  @track data = [];
  @track avaiableAccounts = [];
  //Front - 1272 - Start
  @track newColumns = [];
  columnsTmp = [];
  wiredAccounts;
  //isEnterClicked = false; //FRONT-3020 Variable to check if Enter key is pressed to search by Customer Info field //Commented as part of FRONT-22445
  customerInfoText; //FRONT-3020 Variable to store Customer Info field value, maily used to store the value before enter click
  //RECORD_TYPE_CHECK; //FRONT-2139 AD
  @track filterRemoved = '';

  customerInfoPlaceHolder = LABELS.HELP_TEXT_CONTENT; //FRONT-8351
  /* FRONT - 8124 : Using variable to alter class for table action */
  tableActionClass = "slds-cell_action-mode action-cell";
  /* END : FRONT - 8124 */
  @wire(getObjectInfo, {
    objectApiName: ACCOUNT_OBJECT
  })
  AccLabels({ data, error }) {
    if (data) {
      const actions = [
        { label: "Record Details", name: "record_details" },
        { label: "Edit", name: "edit" },
        { label: "Delete", name: "delete" }
      ];

      this.newColumns = [
        {
          label: data.fields.Name.label,
          fieldName: "Name",
          type: "url",
          onclick: this.selectAccount
        },
        {
          label: "Account Type",
          fieldName: "Record_Type_Text__c",
          type: "text"
        },
        {
          label: "Status",
          fieldName: "Status__c",
          type: ""
        },
        {
          label: data.fields.BillingAddress.label,
          fieldName: "BillingAddress",
          type: "text"
        },
        {
          label: "Phone",
          fieldName: "Phone",
          type: "Phone"
        },
        {
          label: "Country",
          fieldName: "BillingCountryCode",
          type: ""
        },
        {
          label: data.fields.Driver_s_License_State__c.label,
          fieldName: "Driver_s_License_State__c",
          type: ""
        },
        {
          label: data.fields.Drivers_License__c.label,
          fieldName: "Drivers_License__c",
          type: "text"
        },
        {
          label: "Email",
          fieldName: "E_mail_Address__c",
          type: "text"
        }
      ];

      this.columnsTmp = JSON.parse(JSON.stringify(this.newColumns));
    }
  }
  //Front - 1272 - End

  @track searchState;
  @track searchedAddress;
  @track searchedPhone;
  @track comboboxFilters = [];
  stateOptions = [
    {
      value: "",
      label: "--None--"
    },
    {
      value: "AL",
      label: "AL"
    },
    {
      value: "AK",
      label: "AK"
    },
    {
      value: "AZ",
      label: "AZ"
    },
    {
      value: "AR",
      label: "AR"
    },
    {
      value: "CA",
      label: "CA"
    },
    {
      value: "CO",
      label: "CO"
    },
    {
      value: "CT",
      label: "CT"
    },
    {
      value: "DE",
      label: "DE"
    },
    {
      value: "DC",
      label: "DC"
    },
    {
      value: "FL",
      label: "FL"
    },
    {
      value: "GA",
      label: "GA"
    },
    {
      value: "HI",
      label: "HI"
    },
    {
      value: "ID",
      label: "ID"
    },
    {
      value: "IL",
      label: "IL"
    },
    {
      value: "IN",
      label: "IN"
    },
    {
      value: "IA",
      label: "IA"
    },
    {
      value: "KS",
      label: "KS"
    },
    {
      value: "KY",
      label: "KY"
    },
    {
      value: "LA",
      label: "LA"
    },
    {
      value: "ME",
      label: "ME"
    },
    {
      value: "MD",
      label: "MD"
    },
    {
      value: "MA",
      label: "MA"
    },
    {
      value: "MI",
      label: "MI"
    },
    {
      value: "MN",
      label: "MN"
    },
    {
      value: "MS",
      label: "MS"
    },
    {
      value: "MO",
      label: "MO"
    },
    {
      value: "MT",
      label: "MT"
    },
    {
      value: "NE",
      label: "NE"
    },
    {
      value: "NV",
      label: "NV"
    },
    {
      value: "NH",
      label: "NH"
    },
    {
      value: "NJ",
      label: "NJ"
    },
    {
      value: "NM",
      label: "NM"
    },
    {
      value: "NY",
      label: "NY"
    },
    {
      value: "NC",
      label: "NC"
    },
    {
      value: "ND",
      label: "ND"
    },
    {
      value: "OH",
      label: "OH"
    },
    {
      value: "OK",
      label: "OK"
    },
    {
      value: "OR",
      label: "OR"
    },
    {
      value: "PA",
      label: "PA"
    },
    {
      value: "RI",
      label: "RI"
    },
    {
      value: "SC",
      label: "SC"
    },
    {
      value: "SD",
      label: "SD"
    },
    {
      value: "TN",
      label: "TN"
    },
    {
      value: "TX",
      label: "TX"
    },
    {
      value: "UT",
      label: "UT"
    },
    {
      value: "VT",
      label: "VT"
    },
    {
      value: "VA",
      label: "VA"
    },
    {
      value: "WA",
      label: "WA"
    },
    {
      value: "WV",
      label: "WV"
    },
    {
      value: "WI",
      label: "WI"
    },
    {
      value: "WY",
      label: "WY"
    }
  ];

  orderClause = DEFAULT_ORDER_CLAUSE;
  limitClause = DEFAULT_LIMIT_CLAUSE;
  totalRecordCount;
  filterTemplate;
  /*FRONT-7984 previousPortHeight - Varibale created to set the port height to calculate the window viewport height at the beginning
   * and setting as current viewport height when window resizes after using the previous height in adjustScrollableTableHeight
   */
  previousPortHeight;
  @track
  props;
  isAccountSearchScreen = false;
  connectedCallback() {
    if (this.parentcmp === "accountsearchscreen") {
      this.isAccountSearchScreen = true;
    }
    this.isSearchLoading = true;
    this.loadStyleSheet();
    if (this.defaultRecordId != "") {
      this.setDefaultSelection();
    } else if (this.recordId != "" && this.recordId != null) {
      this.defaultRecordId = this.recordId;
      this.setDefaultSelection();
    }
    window.addEventListener("resize", () => {
      this.resizeEventMethods();
    });
    this.previousPortHeight = window.innerHeight;
  }

  disconnectedCallback() {
    window.removeEventListener("resize", this.resizeEventMethods);
  }

  //A single method calling 2 methods so that we can use multiple methods in windowResize event
  resizeEventMethods() {
    this.handleResize();
    this.adjustScrollableTableHeight();
  }

  handleResize() {
    const dropdown = this.template.querySelector(
      "c-sbr_3_0_custom-combobox-filter"
    );
    if (dropdown) {
      dropdown.adjustHeight();
    }
  }

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
        }
      })
      .catch((error) => {
        console.log("fetch default error", error);
        this.error = error;
        this.selectedRecord = {};
        this.recordId = "";
      });
  }
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
      this.template
        .querySelector(".lookupInputContainer")
        .classList.remove("slds-is-open");

      const searchBoxWrapper = this.template.querySelector(".searchBoxWrapper");
      searchBoxWrapper.classList.remove("slds-show");
      searchBoxWrapper.classList.add("slds-hide");

      const pillDiv = this.template.querySelector(".pillDiv");
      pillDiv.classList.remove("slds-hide");
      pillDiv.classList.add("slds-show");
    }
  }

  // wire function property to fetch search record based on user input
  @wire(getAccounts, {
    searchKey: "$searchKey",
    fields: "$fieldsToInclude",
    objectName: "$sObjectApiName",
    whereClause: "$whereClause",
    orderClause: "$orderClause",
    limitClause: "$limitClause",
    fetchCount: "$fetchCount"
  })
  searchResult(value) {
    const { data, error } = value; // destructure the provisioned value
    this.wiredAccounts = value;
    this.isSearchLoading = false;
    if (data) {
      this.totalRecordCount = data.count;
      this.buildData(data.data).then(() => {
        //FRONT-7984 Calling this method only after when the data loads fully irrespective of time taken
        this.adjustScrollableTableHeight();
      });
    } else if (error) {
      console.log("(error---> ", error);
    }
  }

  //Commented as part of FRONT-22445
  //FRONT-3020 Method created to be called on onkeypress Event on Customer Info lightning-input field
  // handleEnterClick(event) {
  //   console.log("Inside handleEnterClick");
  //   //If Enter key is pressed then only apply search
  //   if (event.target.value && event.keyCode === 13) {
  //     this.isEnterClicked = true;

  //     //If there are filter chips already present, then on searching from Customer Info field and then pressing Enter key will remove the filtet chips
  //     if (this.comboboxFilters.length !== 0) {
  //       const childFilterComponent = this.template.querySelector(
  //         "c-sbr_3_0_custom-combobox-filter"
  //       );
  //       childFilterComponent.resetFilters();
  //     }

  //     //Perform the search as per text in Customer Info field
  //     this.searchAccount(event);
  //   }
  // }

  /*FROMT-3020 Method created to be called on onchange Event on Customer Info lightning-input field.
   * This is done to automatically reset the table when the Customer Info field is emptied (without pressing Enter key).*/
  //Changed as part of FRONT-22445
  handleEmptyFieldValue(event) {
    console.log("Inside handleEmptyFieldValue");
    //Only called when there is no value in Customer Info field
    //and some search was done before from the field (to avoid extra calls).
    // if (!event.target.value && this.isEnterClicked) {
    if (!event.target.value) {
      this.searchAccount(event);
      //this.isEnterClicked = false;
    }
    //this.customerInfoText = event.target.value;
  }

  //FRONT-22445
  handleOnKeyDown(event) {
    console.log("Inside handleOnKeyDown", event.target.value);
    if (!event.target.value && event.keyCode === 13) {
      this.searchAccount(event);
    } else if (event.target.value && event.keyCode === 13) {
      console.log("Clicked keyCode 13");

      //If there are filter chips already present, then on searching from Customer Info field and then pressing Enter key will remove the filtet chips
      if (this.comboboxFilters.length !== 0) {
        const childFilterComponent = this.template.querySelector(
          "c-sbr_3_0_custom-combobox-filter"
        );
        childFilterComponent.resetFilters();
      }

      //Perform the search as per text in Customer Info field
      this.searchAccount(event);
    }
    this.customerInfoText = event.target.value;
  }

  //FRONT-3020 Done changes in this method - removed searchKey syncing with accName and added event.preventDefault()
  searchAccount(event) {
    event.preventDefault();
    this.isSearchLoading = true;
    window.clearTimeout(this.delayTimeout);
    const searchKey = event.target.value;
    // eslint-disable-next-line @lwc/lwc/no-async-operation
    this.delayTimeout = setTimeout(() => {
      // eslint-disable-next-line @lwc/lwc/no-api-reassignments
      this.searchKey = searchKey;
    }, DELAY);
  }
  @api accountSelected;

  hideResults(account) {
    let hideResults;
    if (account.Id) {
      let accObj = {
        acc: account,
        newOrExistingAcc: "Existing"
      };
      hideResults = new CustomEvent("hideresults", {
        detail: accObj
      });
    } else {
      hideResults = new CustomEvent("hideresults", {
        hideResults: false
      });
    }

    this.dispatchEvent(hideResults);
  }

  handleStateChange(event) {
    this.searchState = event.target.value;
    this.filterData();
  }

  handleAddressChange(event) {
    this.searchedAddress = event.target.value;
    this.filterData();
  }

  handlePhoneChange(event) {
    this.searchedPhone = event.target.value;
    this.filterData();
  }

  filterData() {
    let avaiableAccounts = this.avaiableAccounts;
    if (this.searchState) {
      avaiableAccounts = avaiableAccounts.filter((account) => {
        return account.BillingState.includes(this.searchState);
      });
    }

    if (this.searchedAddress) {
      avaiableAccounts = avaiableAccounts.filter((account) => {
        let lowerCaseChars = account.BillingStreet.toLowerCase();
        return lowerCaseChars.includes(this.searchedAddress);
      });
    }

    if (this.searchedPhone) {
      avaiableAccounts = avaiableAccounts.filter((account) => {
        let phoneDigits = "";
        if (account.Phone) {
          phoneDigits = account.Phone.replace("(", "")
            .replace(")", "")
            .replace("-", "")
            .replace(" ", "");
        }
        return phoneDigits.includes(this.searchedPhone);
      });
      this.resultCount = avaiableAccounts.length;
    }

    this.data = avaiableAccounts;
  }

  onAccountNameClicked(event) {
    let id;
    if (event.target.id) {
      id = event.target.id;
      id = id.slice(0, id.indexOf("-"));
    } else if (event.detail.id) {
      id = event.detail.id;
    } else {
      id = event.currentTarget.dataset.id;
    }
    let Name = event.target.title ? event.target.title : event.detail.title;
    let account = this.data.find((a) => a.Id == id);
    //FRONT-4097
    if (
      account.Record_Type_Text__c === "Prospect" &&
      this.parentcmp === "orderrequireCustomLookup"
    ) {
      this.openConversionModal(account);
    }
    //Front-14007 start
    //Modified for Front-20803
    else if (
      (this.isContract == "Contract" ||
        this.recordTypeName == "Create Contract") &&
      account.Record_Type_Text__c === "Guest"
    ) {
      this.openConversionModal(account);
    }
    //Front-14007 end
    else {
      //FRONT-3880, 4001
      account = { ...account };
      account.Name = Name;
      this.hideResults(account);
    }
  }

  selectAccount(event) {
    let id;
    if (event.target.id) {
      id = event.target.id;
      id = id.slice(0, id.indexOf("-"));
    } else {
      id = event.detail.id;
    }
    let Name = event.target.title ? event.target.title : event.detail.title;
    let Record_Type_Text__c = event.target.Record_Type_Text__c
      ? event.target.Record_Type_Text__c
      : event.detail.Record_Type_Text__c;

    let account = this.data.find((a) => a.Id == id);
    //FRONT-4097
    /* if(account.Record_Type_Text__c === "Prospect") {
      this.openConversionModal(account);
    } else { */
    //FRONT-3880, 4001
    account = { ...account };
    account.Name = Name;
    account.Id = event.target.id ? event.target.id : event.detail.id;
    account.Record_Type_Text__c = Record_Type_Text__c;
    this.hideResults(account);
    // }
  }
  showAccountCreationModal(event) {
    console.log("Inside Show Account Method");
    if (
      this.parentcmp === "requireCustomLookup" ||
      this.parentcmp === "accountsearchscreen"
    ) {
      //dispatching event to the parent?
      const showAccountCreationModal = new CustomEvent(
        "showaccountcreationmodal",
        {
          isModalOpen: true,
          showAllResultsFlag: false
        }
      );

      this.dispatchEvent(showAccountCreationModal);
    } else if ((this.parentcmp = "customAccountListView")) {
      const showAccountCreationModal = new CustomEvent(
        "showaccountcreationmodal",
        {
          showAllResultsFlag: false,
          isModalOpen: true,
          recordId: this.recordId
        }
      );
      this.dispatchEvent(showAccountCreationModal);
    }
  }
  closeModal() {
    this.openAccountScreen = false;
    this.editRecordForm = false;
    this.editConversionFrom = false;
    window.setTimeout(() => {
      this.resizeEventMethods();
    }, 5);
  }

  get showFilterPills() {
    return this.comboboxFilters && this.comboboxFilters.length > 0;
  }
  handleFilters(event) {
    this.isSearchLoading = true;
    this.buildFilterPills(event.detail);
  }

  buildFilterPills(filters) {
    if (!filters) {
      this.comboboxFilters = [];
    } else {
      this.comboboxFilters = filters.map((filter) => {
        if (filter.fieldApiName === "Name") this.searchKey = filter.value;

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
      whereClause = this.buildWhereClause(this.comboboxFilters);
      logger.log("whereClause---->" + whereClause);
      //FRONT-3020 Added this If block to empty the Customer Info field when clicking Apply on Filters dropdown
      if (this.comboboxFilters.length !== 0) {
        if (this.searchKey !== "") this.searchKey = "";
        if (this.customerInfoText !== "")
          this.template.querySelector(".filters-accountName").value = "";
      }
    }
    this.runFiltering(whereClause);
  }

  runFiltering(whereClause) {
    this.whereClause = whereClause;
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
      }, 1000); // Adjust the timeout duration as necessary, updated time to 10ms for FRONT-11596
    }
    this.isSearchLoading = true;
    const index = event.detail.index;
    const removedItem = event.detail.item;
    if (this.comboboxFilters[index].fieldApiName === "Name")
      this.searchKey = "";

    this.comboboxFilters.splice(index, 1);
    this.buildFilterPills(this.comboboxFilters);
    const filterComp = this.template.querySelector(
      "c-sbr_3_0_custom-combobox-filter"
    );
    if (filterComp) {
      filterComp.updateFilters(removedItem);
    }
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
    whereClause += RECORD_TYPE_CHECK;
    return whereClause === "" ? whereClause : ` WHERE ${whereClause}`;
  }

  buildData(data) {
    //FRONT-7984 returning promise so that it will return only when the data loads fully
    return new Promise((resolve) => {
      this.data = data;
      this.avaiableAccounts = this.data;
      this.copyOfData = data;
      this.resultCount = this.data.length;
      this.hasRecords = data.length === 0 ? false : true;
      this.lstResult = JSON.parse(JSON.stringify(data));
      for (let i = 0; i < this.lstResult.length; i++) {
        let o = this.lstResult[i];
        if (this.hasCustomNameField) {
          o.DisplayName = o[this.customNameField];
        } else {
          o.DisplayName = o.Name;
        }
        //1602

        if (o.Record_Type_Text__c === "Non-Credit") {
          o.ShowPopUpFlag = true;
          o.showProspectConversion = false;
        } else if (o.Record_Type_Text__c === "Prospect") {
          o.ShowPopUpFlag = true;
          o.showProspectConversion = true;
        }
        //Front-14007 start
        else if (o.Record_Type_Text__c === "Guest") {
          o.ShowPopUpFlag = true;
          o.showProspectConversion = true;
        }
        //Front-14007 end
        else {
          o.ShowPopUpFlag = false;
          o.showProspectConversion = false;
        }

        if (!o.ShowPopUpFlag) {
          //TODO : Remove actions from this.newColumns
          this.newColumns = JSON.parse(JSON.stringify(this.columnsTmp)).filter(
            (value) => {
              if (value.type != "action") return value;
            }
          );
        } else {
          this.newColumns = JSON.parse(JSON.stringify(this.columnsTmp));
        }

        /* FRONT - 8124 : Covering AC2 i.e. removing edit action for Non-Credit customers with Deleted status*/
        if (
          o.Record_Type_Text__c === "Non-Credit" &&
          o.Status__c === ACCOUNT_STATUS_VALUES.DELETED
        ) {
          o.ShowPopUpFlag = false;
          this.tableActionClass = "table-cell";
        }
        /*END : FRONT - 8124 */

        //FRONT-1681 If the Status cell has value then only apply background color to it
        //computedStatusClasses is a property set in HTML in Status column div element
        if (o.Status__c) {
          o.computedStatusClasses = this.applyBackgroundColor(o.Status__c);
        }
        o.menuAlignment = i === this.resultCount - 1 ? "auto" : "right";
        if (this.parentcmp === "orderrequireCustomLookup") {
          //Start FRONT-2487
          //added for Front-14007

          if (
            ((o.Record_Type_Text__c === "Credit" ||
              o.Record_Type_Text__c === "Corp Link" ||
              o.Record_Type_Text__c === "Non-Credit") &&
              o.Status__c === ACCOUNT_STATUS_VALUES.ACTIVE) ||
            o.Record_Type_Text__c === "Prospect" ||
            o.Record_Type_Text__c === "Guest"
          ) {
            o.allowAccountSelection = true;
          } else {
            o.allowAccountSelection = false;
          }
          //End FRONT-2487
        } else {
          //Start FRONT-8624
          //if(o.Record_Type_Text__c !== 'Prospect'){
          if (
            (o.Record_Type_Text__c === "Credit" ||
              o.Record_Type_Text__c === "Corp Link" ||
              o.Record_Type_Text__c === "Non-Credit") &&
            o.Status__c !== ACCOUNT_STATUS_VALUES.ACTIVE //added for 32432
          ) {
            o.allowAccountSelection = false;
          } else if (
            o.Record_Type_Text__c === "Non-Credit" &&
            (o.Status__c === ACCOUNT_STATUS_VALUES.CLOSED ||
              o.Status__c === ACCOUNT_STATUS_VALUES.DELETED ||
              o.Status__c === ACCOUNT_STATUS_VALUES.INACTIVE)
          ) {
            o.allowAccountSelection = false;
          } else {
            o.allowAccountSelection = true;
          }
          //}
          //End FRONT-8624
        }
      }

      logger.log(
        "👉👉👉this.lstResult👉👉👉 " + JSON.stringify(this.lstResult)
      );

      resolve();
    });
  }

  buildDefaultQuery() {
    if (this.comboboxFilters.length > 0) {
      return this.whereClause;
    }
    let whereClause = "";
    if (this.searchKey && this.searchKey !== "") {
      const defaultFilters = DEFAULT_FILTERING_FIELDS.map((field) => {
        return {
          fieldApiName: field,
          value: this.searchKey
        };
      });
      whereClause = this.buildWhereClause(defaultFilters, JOIN_OR_CLAUSE);
    }
    //On rendering the component with nothing in 'Customer Info' field in Modal
    //then just add Record type check in Where clause
    else if (!this.searchKey) {
      whereClause += this.buildWhereClause(null);
    }
    return whereClause;
  }

  get countLabel() {
    let label;
    if (this.isSearchLoading) {
      label = "";
    } else if (this.fetchCount) {
      label = `${this.resultCount} of ${this.totalRecordCount} Results Found`;
    } else {
      label = `${this.resultCount} Results`;
    }

    return label;
  }

  loadStyleSheet() {
    loadStyle(this, FrontLineCSS);
    loadStyle(this, Sbr_3_0_customModalCmpDesktop_Css);
  }
  showRowOptions(event) {
    console.log(JSON.parse(event.target));
  }

  /* Start ---- Story - #1273 */
  renderedCallback() {
    const self = this;
    document.addEventListener("click", (event) => {
      let hasNode = false;
      const path = event.composedPath();
      Array.prototype.forEach.call(path, function (entry) {
        if (entry.nodeName == "C-SBR_3_0_CUSTOM-COMBOBOX-FILTER") {
          hasNode = true;
        }
      });
      if (!hasNode && path.length > 0) {
        if (self.template.querySelector("c-sbr_3_0_custom-combobox-filter")) {
          self.template
            .querySelector("c-sbr_3_0_custom-combobox-filter")
            .closeFilterDropDown();
        }
      }
    });
  }
  /* End ---- Story - #1273 */

  async openEditForm(event) {
    const selectedId = event.currentTarget.dataset.id;
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

  handleConversionClick(event) {
    const selectedId = event.currentTarget.dataset.id;
    const selectedRecord = this.lstResult.filter(
      (result) => result.Id === selectedId
    )[0];
    this.openConversionModal(selectedRecord);
  }

  openConversionModal(selectedRecord) {
    this.accId = selectedRecord.Id;
    this.editConversionFrom = true;
  }

  get searchModalComputedClasses() {
    let classes = "slds-modal outer-modal-element"; // slds-modal_large";
    if (!this.editRecordForm && !this.editConversionFrom) {
      classes += " slds-fade-in-open";
    }
    return classes;
  }

  //Method to refresh the Search modal component
  //It is called onrefreshcomponent event in html, this event is called from child component sbr_3_0_editAccountCmp
  handleForceRefresh() {
    this.isSearchLoading = true;
    refreshApex(this.wiredAccounts).then(() => {
      this.isSearchLoading = false;
    });
  }

  //FRONT-1681 Method created to set background colors as per status values
  //color-boxes is the default class set for Status field cell in the table to provide sizing to the color box
  //color classes are been created in CSS file as per different required colors
  applyBackgroundColor(status) {
    let defaultStatusClass = "color-boxes ";
    let colorClass = "";

    if (status === ACCOUNT_STATUS_VALUES.ACTIVE) colorClass = "greenColor";
    if (status === ACCOUNT_STATUS_VALUES.INACTIVE) colorClass = "greyColor";
    if (status === ACCOUNT_STATUS_VALUES.CLOSED) colorClass = "greyColor";
    if (status === ACCOUNT_STATUS_VALUES.ONHOLD) colorClass = "orangeColor";
    if (status === ACCOUNT_STATUS_VALUES.NONE) colorClass = "greyColor";
    if (status === ACCOUNT_STATUS_VALUES.BADDEBT) colorClass = "redColor";
    if (status === ACCOUNT_STATUS_VALUES.DELETED) colorClass = "redColor";
    if (status === ACCOUNT_STATUS_VALUES.SUSPENDED) colorClass = "orangeColor";
    if (status === ACCOUNT_STATUS_VALUES.CREDITDENIED) colorClass = "redColor";

    return defaultStatusClass + colorClass;
  }

  handleHideResult(event) {
    if (event.detail) {
      let account = JSON.parse(JSON.stringify(event.detail.acc));
      if (JSON.parse(JSON.stringify(event.detail.acc))) {
        //Front 803 toast msg for non-credit.
        if (account.RecordTypeName === "Non-Credit") {
          if (event.detail.newOrExistingAcc === "New") {
            this.setNonCreditToastMessage(account);
          }
        } else {
          if (event.detail.newOrExistingAcc === "New") {
            this.displayToast = true;
            this.successTitle = "Success";
            this.successMsg = "Account Created.";
            this.closeToastAsync(3000);
          }
        }
      }
    }
  }
  setNonCreditToastMessage(record, timer = 10000) {
    let recordId = record.Id;
    this.successTitle = "Success";
    this.successMsg = `New Account has been successfully created. <a href="/lightning/r/Account/${recordId}/view?c__showTC=true">Get T&C Signature</a>`;
    this.displayToast = true;
    this.closeToastAsync(timer);
  }

  closeToastAsync(timer) {
    // eslint-disable-next-line @lwc/lwc/no-async-operation
    window.setTimeout(() => {
      this.closeToast();
    }, timer);
  }

  //FRONT-7984 Method created to adjust height of the table with data
  //it will be called when the data loads and when window resizes
  adjustScrollableTableHeight() {
    if (this.template.querySelector(".slds-scrollable_y")) {
      const table = this.template.querySelector(".slds-scrollable_y");
      const footer = this.template.querySelector(".slds-modal__footer");

      const currentViewPortHeight = window.innerHeight;
      let adddedSpace = 0;

      if (this.previousPortHeight < currentViewPortHeight) {
        adddedSpace = currentViewPortHeight - this.previousPortHeight;
      }

      this.previousPortHeight = currentViewPortHeight;

      const availableSpace =
        footer.getBoundingClientRect().top -
        table.getBoundingClientRect().top +
        adddedSpace;

      table.style.height = availableSpace + "px";
    }
  }

  render() {
    let returnTemplate;
    if (this.parentcmp === "accountsearchscreen") {
      returnTemplate = accountSearchDesktopTemplate;
    } else {
      returnTemplate = customSearchDesktopTemplate;
    }
    return returnTemplate;
  }

  @api
  setFocus() {
    const acclistview = this.template.querySelector(".customModalCloseButton");
    if (acclistview) {
      acclistview.focus();
    }
  }
}