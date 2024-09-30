/* eslint-disable @lwc/lwc/no-api-reassignments */
import { LightningElement, api, track, wire } from "lwc";
import { getRecord, getFieldValue } from "lightning/uiRecordApi";
//import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { NavigationMixin } from "lightning/navigation";
import { FlowNavigationNextEvent } from "lightning/flowSupport";
//import ACCOUNT_LOOKUP_FIELD from '@salesforce/schema/SBQQ__Quote__c.SBQQ__Account__c';
//import ACCOUNT_OFFICE_LOOKUP_FIELD from '@salesforce/schema/SBQQ__Quote__c.Office_Account__c';
import ACCOUNT_NAME_FIELD from "@salesforce/schema/Account.Name";
//import ACCOUNT_OBJECT from '@salesforce/schema/Account';
import SAL_TEMPLATE from "./sbr_3_0_changeCustomerOnOrderSAL.html";
import FL_TEMPLATE from "./sbr_3_0_changeCustomerOnOrderFL.html";

import LABELS from "c/sbr_3_0_customLabelsCmp"; //FRONT-9251
import { ShowToastEvent } from "lightning/platformShowToastEvent";

import ACCOUNT_LOOKUP_FIELD from "@salesforce/schema/SBQQ__Quote__c.SBQQ__Account__c";
import ACCOUNT_OFFICE_LOOKUP_FIELD from "@salesforce/schema/SBQQ__Quote__c.Office_Account__c";
import ACCOUNT_PARENTID_FIELD from "@salesforce/schema/Account.ParentId";
import ACCOUNT_OBJECT from "@salesforce/schema/Account";
// import QUOTE_NAME_FIELD from '@salesforce/schema/SBQQ__Quote__c.Quote_Name__c';
// import QUOTE_ORDERED_BY_FIELD from '@salesforce/schema/SBQQ__Quote__c.Ordered_by__c';
import getAppName from "@salesforce/apex/SBR_3_0_CustomLookupController.getAppName";

export default class Sbr_3_0_changeCustomerOnOrder extends NavigationMixin(
  LightningElement
) {
  //   areDetailsVisible = false;
  //   accountLookupField = ACCOUNT_LOOKUP_FIELD;
  //   officeAccountLookupField = ACCOUNT_OFFICE_LOOKUP_FIELD;

  @api accountId;
  @api accountName;
  @api officeAccountId;
  @api relatedRecordId;
  @api quoteName;
  @api orderedBy;
  //@api minStartDate
  @api useJobSite = false;
  @api accountWhere;

  //   defaultOfficeAccountId;
  //   isChangeAccount = false;
  @track isAccountSelected = false;
  @track isOrderedByButtonDisabled = true;
  @track mobileMainDiv = "";
  //@track durationSelection
  //@track selectedAccount;
  //@track selectedOfficeAccount;
  //@track selectedContact;
  //@track customLineStyle;
  @track showFrontlineComponents;
  @track parentComp = "orderrequireCustomLookup";
  @api accountRecordType;
  @track isNonCreditAccount = false;
  frontlineDefaultFilteringFields =
    "RM_Account_Number__c,Status__c,ShippingPostalCode,ShippingCity,Record_Type_Text__c,ShippingState,Phone,E_mail_Address__c";

  appName = "RAE Frontline";
  @api showNewContact;
 @api IsContract; //Front-14007, FRONT-16849
  customerInfoPlaceHolder = LABELS.HELP_TEXT_CONTENT; //FRONT-8351
  get showNewContactButton() {
    return this.showFrontlineComponents;
  }

  // @wire(getRecord, { recordId: '$selectedAccount', fields: [ACCOUNT_PARENTID_FIELD]})
  // wiredAccount;
  //   @wire(getRecord, {
  //     recordId: "$officeAccountId",
  //     fields: [ACCOUNT_PARENTID_FIELD]
  //   })
  //   wiredOfficeAccount({ error, data }) {
  //     if (data) {
  //       console.log("Wired Office Provision");
  //       this.selectedOfficeAccount = data;
  //       this.error = undefined;
  //     } else if (error) {
  //       this.error = error;
  //       this.selectedOfficeAccount = undefined;
  //     }
  //   }

  //   @wire(getObjectInfo, { objectApiName: ACCOUNT_OBJECT })
  //   accountObjectInfo;
  @wire(getRecord, { recordId: "$accountId", fields: [ACCOUNT_NAME_FIELD] })
  wiredAccount({ error, data }) {
    if (data) {
      this.accountName = data.fields.Name.value;
      this.error = undefined;
    } else if (error) {
      this.error = error;
      this.accountName = "";
    }
  }
  connectedCallback() {
    if (window.matchMedia("(max-width: 480px)").matches) {
      this.mobileMainDiv = "mobileMainDiv";
    }
    //this.minStartDate = new Date();
    if (this.accountId !== undefined) {
      this.isAccountSelected = true;
    }
    if(this.orderedBy !== undefined) {
      this.isOrderedByButtonDisabled = false;
    }


    getAppName()
      .then((results) => {
        this.appName = results;
        if (this.appName === "RAE Frontline") {
          this.isNonCreditAccount = this.accountRecordType === "Non-Credit"; // FRONT: 4576
          this.showFrontlineComponents = true;
          this.accountWhere =
            "((Status__c = 'Active') AND (RecordType.DeveloperName = 'Credit' OR RecordType.DeveloperName = 'ERP_Link' OR RecordType.DeveloperName = 'Non_Credit') AND (Company_Code__c = '' OR Company_Code__c = '01' OR Company_Code__c = '02'))"; //FRONT-2139 AD
          console.log("frontline");
        }
      })
      .catch((error) => {
        console.log("error");
      });
  }

    renderedCallback() {
      let footer = this.template.querySelector(".customfooter");
      let width = footer?.getBoundingClientRect().width + 24; // null check FRONT-16849
      this.customLineStyle =
        "position: absolute; width: " +
        width +
        "px; margin-left: -12px; margin-right: 12px";
    }

  handleNext(event) {
    const nextNavigationEvent = new FlowNavigationNextEvent();
    this.dispatchEvent(nextNavigationEvent);
  }
  // Added by FRONTLINE to check for both "Id" & "id".
  handleOrderedByChange(event) {
    if (event.detail.selectedRecord !== undefined) {
      this.orderedBy =
        event.detail.selectedRecord.id === undefined
          ? event.detail.selectedRecord.Id
          : event.detail.selectedRecord.id;
      this.isOrderedByButtonDisabled = false;
      console.log("Selected Contact: ", this.orderedBy);
    } else {
      this.orderedBy = "";
      this.isOrderedByButtonDisabled = true;
    }
  }

  handleOfficeAccountChange(event) {
    if (event.detail.selectedRecord !== undefined) {
      this.officeAccountId = event.detail.selectedRecord.Id;
      console.log("Selected Office Account: ", this.officeAccountId);
    } else {
      this.officeAccountId = "";
    }
  }

  handleAccountChange(event) {
    if (event.detail.selectedRecord !== undefined) {
      //this.isChangeAccount=true;
      this.accountId = event.detail.selectedRecord.Id;
      this.accountName = event.detail.selectedRecord.Name;
      console.log(
        "@@selected Acc " + JSON.stringify(event.detail.selectedRecord)
      );
      this.isAccountSelected = true;
      //Start ------>FRONT-4576
      this.isNonCreditAccount =
        event.detail.selectedRecord.Record_Type_Text__c === "Non-Credit" &&
        this.appName === "RAE Frontline";
      this.accountRecordType = event.detail.selectedRecord.Record_Type_Text__c;
      //END ------>FRONT-4576
    } else {
      this.isAccountSelected = false;
      //this.isChangeAccount = false;
      //this.isOrderedByButtonDisabled = true;
      this.accountId = "";
      this.accountName = "";
      this.officeAccountId = "";
      this.orderedBy = "";
      this.isNonCreditAccount = false;
      this.accountRecordType = "";
    }
  }
  @api
  validate() {
    if (!this.accountId) {
      return {
        isValid: false,
        errorMessage: "Please select an Account."
      };
    } else if (!this.orderedBy) {
      return {
        isValid: false,
        errorMessage: "Please select Ordered By Contact."
      };
    } else {
      return {
        isValid: true,
        errorMessage: ""
      };
    }
  }

  /*handleChecked(event) {
    this.areDetailsVisible = event.target.checked;
  }*/

  /*handleUseJobsite(event) {
    this.useJobSite = event.target.checked;
  }*/
  // Start ------>FRONT-4576
  // Commenting since this is part of FS2
  get showExternalOffice() {
    if (this.showFrontlineComponents && this.isNonCreditAccount) {
      return false;
    }
    return true;
  }
  // END ------>FRONT-4576 /*
  /*get account() {
    if (this.accountId !== undefined) {
      console.log("Get Account Standard");
      return this.accountId;
    } else if (this.officeAccountId !== undefined) {
      console.log("Get Account Is Office Account");
      console.log(
        getFieldValue(this.selectedOfficeAccount, ACCOUNT_PARENTID_FIELD)
      );
      return getFieldValue(this.selectedOfficeAccount, ACCOUNT_PARENTID_FIELD);
    } else if (this.isBillingAccount) {
      console.log("Get Account Is Billing Account");
      return this.relatedRecordId;
    }
  }

  set account(value) {
    console.log("Set Account");
    this.accountId = value;
  }

  get officeAccount() {
    if (this.officeAccountId !== undefined) {
      console.log("Get Office Account");
      return this.officeAccountId;
    }
    return "";
  }

  set officeAccount(value) {
    this.officeAccountId = value;
    this.officeWhere = value;
    console.log("Setting");
  }

  get officeRtId() {
    if (this.accountObjectInfo.data !== undefined) {
      const rtis = this.accountObjectInfo.data.recordTypeInfos;
      return Object.keys(rtis).find((rti) => rtis[rti].name === "Office");
    }
    return;
  }*/
  get accountWhereClause() {
    console.log(" this.accountWhere @@ " + this.accountWhere);
    return this.accountWhere + " AND RecordType.Name != 'Office'";
  }
  get officeWhereClause() {
    console.log("ParentId -> ", this.accountId);
    if (this.accountId && this.accountWhere) {
      return "ParentId ='" + this.accountId + "' AND " + this.accountWhere;
    }
    return "";
    /*if(this.account !== undefined && this.account !== null) {
      this.officeAccountWhereClause = 'ParentId = \'' + this.account + '\' AND RecordTypeId = \'' + this.officeRtId + '\'';
    }
        else {
      this.officeAccountWhereClause = 'RecordTypeId = \'' + this.officeRtId + '\'';
    }
    return this.officeAccountWhereClause;*/
  }

  /*set officeWhere(value) {
    if (this.account !== undefined && this.account !== null) {
      this.officeAccountWhereClause =
        "ParentId = '" +
        value +
        "' AND RecordTypeId = '" +
        this.officeRtId +
        "'";
    } else {
      this.officeAccountWhereClause =
        "RecordTypeId = '" + this.officeRtId + "'";
    }
  }*/

  /*get isOfficeAccount() {
    if (this.objectApiName === "Account" && this.accRtId === this.officeRtId) {
      return true;
    }
    return false;
  }*/

  get orderedByWhere() {
    if (this.accountId && this.officeAccountId) {
      return (
        "(AccountId = '" +
        this.accountId +
        "' OR AccountId = '" +
        this.officeAccountId +
        "')"
      );
    } else if (this.accountId) {
      return "AccountId = '" + this.accountId + "'";
    }
    // if (this.account && this.officeAccountId) {
    //   this.contactWhereClause =
    //     "(AccountId = '" +
    //     this.account +
    //     "' OR AccountId = '" +
    //     this.officeAccountId +
    //     "')";
    // } else if (this.account) {
    //   this.contactWhereClause = "AccountId = '" + this.account + "'";
    // }
    // console.log("contactWhereClause -> " + this.contactWhereClause);
    // return this.contactWhereClause;
  }

  /*set orderedByWhere(value) {
    let accountCheck = this.account != undefined && this.account != null;
    let officeAccountCheck =
      this.officeAccountId != undefined && this.officeAccountId != null;
    if (accountCheck && officeAccountCheck) {
      this.contactWhereClause =
        "(AccountId = '" +
        this.account +
        "' OR AccountId = '" +
        this.officeAccountId +
        "')";
    } else if (accountCheck) {
      this.contactWhereClause = "AccountId = '" + this.account + "'";
    }
  }*/

  handleSaveContact(event) {
    this.isContactModalOpen = false;
    this.dispatchEvent(
      new CustomEvent("savecon", {
        detail: event.detail
      })
    );
  }

  render() {
    return this.appName === "RAE Frontline" ? FL_TEMPLATE : SAL_TEMPLATE;
  }
}