//created as part of FRONT-9256
import { LightningElement, wire, api } from "lwc";
import { getRecord } from "lightning/uiRecordApi";
import getRecords from "@salesforce/apex/SBR_3_0_CustomRecordController.getFilteredRecords";
import ORDER_ACCOUNT_ID from "@salesforce/schema/Order.AccountId";
import QUOTE_ACCOUNT_ID from "@salesforce/schema/SBQQ__Quote__c.SBQQ__Account__c";
import {
  isMobile,
  DynamicRecordFormMixin
} from "c/sbr_3_0_dynamicRecordFormUtility";
import { FORM_STORE } from "c/sbr_3_0_dynamicRecordFormRegistry";
import FrontLineCSS from "@salesforce/resourceUrl/FrontLinesCSS";
import { loadStyle } from "lightning/platformResourceLoader";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { Logger } from "c/sbr_3_0_frontlineUtils";
const logger = Logger.create(true);

const DEFAULT_FILTERING_FIELDS = [
  "AssociatedLocationNumber",
  "Location_Name__c"
];
const DEFAULT_ORDER_CLAUSE = " ORDER BY LastViewedDate DESC ";
const DEFAULT_BTN_ICON_CLASS = "slds-m-top_medium"; // FRONT-20769
const DEFAULT_LIMIT_CLAUSE = " LIMIT 5";
const JOIN_AND_CLAUSE = " AND ";
const JOIN_OR_CLAUSE = " OR ";
const OBJECT_API_NAME_TO_ACCOUNT_RELATIONSHIP = {
  Order: "Account",
  SBQQ__Quote__c: "SBQQ__Account__r"
};
const OBJECT_API_NAME_TO_ACCOUNT_FIELD = {
  Order: "AccountId",
  SBQQ__Quote__c: "SBQQ__Account__c"
};

export default class Sbr_3_0_jobSiteWrapper extends DynamicRecordFormMixin(
  LightningElement
) {
  fieldsToInclude = [
    "AssociatedLocation.Id",
    "AssociatedLocation.AssociatedLocationNumber",
    "AssociatedLocation.Location_Name__c"
  ];
  sObjectApiName = "AssociatedLocation";
  jobsiteFields = "Id,AssociatedLocationNumber,Location_Name__c";
  //objectFieldToQuery="Location_Name__c";
  jobsiteId;
  accountId = "";
  searchKey = "";
  fetchCount = false;
  whereClause = "";
  errors = [];
  recentlyViewed = [];
  hasAccountInfoChanged = false;
  newRecordOptions = [{ value: "AssociatedLocation", label: "New Job Site" }];
  initialSelection = [];
  inputVariables = [];
  showNewJobSite = false;
  isQuote = false;
  toastTitle = "";
  toastMessage = "";
  jobSiteValue = "";
  //FRONT-20772
  disableEditInfo = false;
  isCreateContract = false;
  isMobile = isMobile;

  connectedCallback() {
    let accountRelationshipName =
      OBJECT_API_NAME_TO_ACCOUNT_RELATIONSHIP[this.objectApiName];
    this.accountId =
      FORM_STORE.records[this.recordId]?.fields?.[
        accountRelationshipName
      ]?.value?.id;

    this.jobsiteId =
      FORM_STORE.records[this.recordId]?.fields?.Jobsite__c?.value;

    if (this.objectApiName === "Order") {
      this.objectFieldToQuery = ORDER_ACCOUNT_ID;
    } else if (this.objectApiName === "SBQQ__Quote__c") {
      this.objectFieldToQuery = QUOTE_ACCOUNT_ID;
    }

    //START: FRONT-20772
    const recordTypeName =
      FORM_STORE.records[this.recordId]?.fields?.Record_Type_Name__c?.value;
    this.isCreateContract = recordTypeName === "Create Contract" ? true : false;
    //END: FRONT-20772
    this.registerListeners(this.handleMessage);
  }

  renderedCallback() {
    loadStyle(this, FrontLineCSS);
  }

  @wire(getRecord, { recordId: "$jobsiteId", fields: "$fieldsToInclude" })
  recordData({ error, data }) {
    if (data) {
      this.initialSelection = [
        {
          id: data?.fields?.Id?.value,
          sObjectType: "AssociatedLocation",
          icon: "standard:location",
          title: data?.fields?.AssociatedLocationNumber.value,
          subtitle: data?.fields?.Location_Name__c.value
        }
      ];

      this.whereClause = this.buildDefaultQuery();
    } else {
      console.log("error::", error);
    }
  }

  buildDefaultQuery() {
    let whereClause = "";
    if (this.searchKey && this.searchKey !== "") {
      const defaultFilters = DEFAULT_FILTERING_FIELDS.map((field) => {
        return {
          fieldApiName: field,
          value: this.searchKey
        };
      });
      whereClause = this.buildWhereClause(defaultFilters, JOIN_OR_CLAUSE);
    } else if (!this.searchKey) {
      whereClause += this.buildWhereClause(null);
    }
    return whereClause;
  }

  buildWhereClause(filters, joinClause = JOIN_AND_CLAUSE) {
    let whereClauseArray = [];
    let whereClause = "";
    if (filters) {
      for (let filter of filters) {
        let value = filter.value.replaceAll("'", "\\'");

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
    if (whereClause) {
      whereClause += JOIN_AND_CLAUSE;
    }
    whereClause += "ParentRecordId = '" + this.accountId + "'";
    return whereClause === "" ? whereClause : ` WHERE ${whereClause}`;
  }

  initLookupDefaultResults() {
    const lookup = this.template.querySelector("c-sbr_3_0_job-site-search-cmp");
    if (lookup) {
      lookup.setDefaultResults(this.recentlyViewed);
    }
  }

  handleLookupSearch(event) {
    this.recentlyViewed = [];
    this.searchKey = event.detail.searchTerm;
    this.whereClause = this.buildDefaultQuery();
  }

  checkForErrors() {
    this.errors = [];
    const selection = this.template
      .querySelector("c-sbr_3_0_job-site-search-cmp")
      .getSelection();
    // Custom validation rule
    if (this.isMultiEntry && selection.length > this.maxSelectionSize) {
      this.errors.push({
        message: `You may only select up to ${this.maxSelectionSize} items.`
      });
    }
  }

  @wire(getRecords, {
    fields: "$jobsiteFields",
    objectName: "$sObjectApiName",
    whereClause: "$whereClause",
    orderClause: DEFAULT_ORDER_CLAUSE,
    limitClause: DEFAULT_LIMIT_CLAUSE,
    fetchCount: "$fetchCount"
  })
  getRecentRecords({ data, error }) {
    if (data) {
      let finalData = data.data;
      finalData = finalData.map((item) => {
        return {
          id: item.Id,
          sObjectType: this.sObjectApiName,
          icon: "standard:location",
          title: item.AssociatedLocationNumber,
          subtitle: item.Location_Name__c
        };
      });
      this.recentlyViewed = finalData;
      if (!this.searchKey) {
        this.initLookupDefaultResults();
      } else {
        const lookupElement = this.template.querySelector(
          "c-sbr_3_0_job-site-search-cmp"
        );
        lookupElement.setSearchResults(this.recentlyViewed);
      }
    } else {
      console.log("error:", error);
    }
  }

  handleChange(event) {
    event.stopPropagation();
    event.preventDefault();
    this.disableEditInfo = false;
    this.jobSiteValue = JSON.stringify(event.detail[0]);
    this.jobsiteId = event.detail[0];

    if (this.objectApiName === "Order") {
      this.errors = [];
    }

    if (JSON.stringify(event.detail[0])) {
      this.hasAccountInfoChanged = false;
      //FRONT-20772 - to hide Job Site Edit Info button if there is no value in the lookup
    } else {
      this.disableEditInfo = true;
    }

    this.updateDRFFieldUpdate([
      {
        apiName: this.field.apiName,
        value: event.detail[0]
      }
    ]);
    const toastNotification = new CustomEvent("hidetoast", {
      bubbles: true,
      composed: true
    });
    this.dispatchEvent(toastNotification);
    this.whereClause = this.buildDefaultQuery();
  }

  //FRONT-11423
  hideToastInfo() {
    const toastNotification = new CustomEvent("hidetoast", {
      bubbles: true,
      composed: true
    });
    this.dispatchEvent(toastNotification);
  }

  handleMessage(message) {
    if (
      message.apiName ===
        OBJECT_API_NAME_TO_ACCOUNT_FIELD[this.objectApiName] &&
      message.value
    ) {
      this.accountId = message.value;
      this.whereClause = this.buildDefaultQuery();
      this.hasAccountInfoChanged = true;
      //this.initialSelection = [];
      if (this.objectApiName === "Order") {
        this.errors.push({
          message: ""
        });
      }
    } else {
      this.hasAccountInfoChanged = false;
    }
  }

  //Front-9257 start //
  handleJobSiteCreation() {
    this.showNewJobSite = true;
    let _inputVariables;
    if (this.objectApiName === "SBQQ__Quote__c") {
      this.isQuote = true;
      _inputVariables = this.quoteInputVariables;
    } else if (this.objectApiName === "Order") {
      _inputVariables = this.orderInputVariables;
      this.errors = [];
    }
    this.inputVariables = _inputVariables;
    this.hasAccountInfoChanged = false;
  }

  get quoteInputVariables() {
    return [
      {
        name: "FromCreateRentalQuote",
        value: true,
        type: "Boolean"
      },
      {
        name: "FromCreateStandardQuoteFlow",
        value: true,
        type: "Boolean"
      },
      {
        name: "officeAccountId",
        value:
          FORM_STORE.records[this.recordId]?.fields?.Office_Account__c?.value ??
          "",
        type: "String"
      },
      {
        name: "orderedById",
        value:
          FORM_STORE.records[this.recordId]?.fields?.Ordered_by__c?.value ?? "",
        type: "String"
      },
      {
        name: "quoteRecordTypeId",
        value: FORM_STORE.records[this.recordId]?.fields?.RecordTypeId?.value,
        type: "String"
      },
      {
        name: "recordId",
        value: this.accountId,
        type: "String"
      },
      {
        name: "associatedRecordId",
        value: this.recordId,
        type: "String"
      }
    ];
  }

  get orderInputVariables() {
    return [
      {
        name: "officeAccountId",
        value:
          FORM_STORE.records[this.recordId]?.fields?.Office_Account__c?.value ??
          "",
        type: "String"
      },
      {
        name: "orderedById",
        value:
          FORM_STORE.records[this.recordId]?.fields?.Order_By__c?.value ?? "",
        type: "String"
      },
      {
        name: "accountId",
        value: this.accountId,
        type: "String"
      },
      {
        name: "opportunityId",
        value:
          FORM_STORE.records[this.recordId]?.fields?.OpportunityId?.value ?? "",
        type: "String"
      },
      {
        name: "RentalProtection",
        value: false,
        type: "Boolean"
      },
      {
        name: "associatedRecordId",
        value: this.recordId,
        type: "String"
      }
    ];
  }

  handleCloseModal() {
    this.showNewJobSite = false;
  }

  handleFlowStatusChange(event) {
    if (event.detail.status === "FINISHED") {
      const jobSiteId = event.detail.outputVariables.filter(
        (element) => element.name === "jobsiteRecordId"
      );
      if (jobSiteId.length > 0) {
        this.jobsiteId = jobSiteId[0].value;

        this.updateDRFFieldUpdate([
          {
            apiName: this.field.apiName,
            value: this.jobsiteId
          }
        ]);
        this.toastMessage = "Job site have successfully been updated";
      }
      this.handleCloseModal();
      this.showToast(this.toastTitle, this.toastMessage);
      // FRONT-4333
      this.template
        .querySelector("c-sbr_3_0_job-site-search-cmp")
        .checkValidity(jobSiteId);
    }
  }

  showToast(toastTitle, toastMessage) {
    const toastEvent = new ShowToastEvent({
      title: toastTitle,
      message: toastMessage,
      variant: "success",
      mode: "dismissable"
    });
    this.dispatchEvent(toastEvent);
  }
  //Front-9257 end //

  //START: FRONT-20772
  handleEditJobSiteInfo() {
    this.refs.editJobSiteModal.toggleModal();
  }

  handleSaveJobSite = (event) => {
    event.stopPropagation();
    event.preventDefault();
    this.template
      .querySelector("c-sbr_3_0_job-site-edit-cmp")
      .saveJobSiteDetails();
  };

  handleJobSiteCloseModal() {
    this.refs.editJobSiteModal.toggleModal();
  }

  handleCancelModal = (event) => {
    //to reset the values if user made changes and close the modal
    this.template
      .querySelector("c-sbr_3_0_job-site-edit-cmp")
      .refreshJobSiteData();
    this.refs.editJobSiteModal.toggleModal();
    event.stopPropagation();
    event.preventDefault();
  };
  //END: FRONT-20772

  get editInfoClass() {
    return this.isMobile
      ? "slds-p-top_medium slds-p-left_small"
      : "editInfoButton";
  }

  get btnIconClass() {
    return this.disableEditInfo
      ? DEFAULT_BTN_ICON_CLASS + " btn-icon-disabled-class"
      : DEFAULT_BTN_ICON_CLASS + " btn-icon-enabled-class";
  }
}
//FRONT-9256 Ends here