/* eslint-disable @lwc/lwc/no-api-reassignments */
import { LightningElement, api, track, wire } from "lwc";
import { getRecord, getFieldValue } from "lightning/uiRecordApi";

import { NavigationMixin } from "lightning/navigation";
import { FlowNavigationNextEvent } from "lightning/flowSupport";
import ACCOUNT_NAME_FIELD from "@salesforce/schema/Account.Name";
// import ACCOUNT_LOOKUP_FIELD from "@salesforce/schema/SBQQ__Quote__c.SBQQ__Account__c";
// import ACCOUNT_OFFICE_LOOKUP_FIELD from "@salesforce/schema/SBQQ__Quote__c.Office_Account__c";
// import ACCOUNT_PARENTID_FIELD from "@salesforce/schema/Account.ParentId";
// import ACCOUNT_OBJECT from "@salesforce/schema/Account";
// import ACCOUNT_RECORDTYPE from "@salesforce/schema/Account.Record_Type_Text__c";
// import QUOTE_NAME_FIELD from '@salesforce/schema/SBQQ__Quote__c.Quote_Name__c';
// import QUOTE_ORDERED_BY_FIELD from '@salesforce/schema/SBQQ__Quote__c.Ordered_by__c';
import USER_ID from "@salesforce/user/Id";
import ANALYSIS_REGION_KEY_FIELD from "@salesforce/schema/User.Analysis_Region_Key__c";
import getAppName from "@salesforce/apex/SBR_3_0_CustomLookupController.getAppName";
//import getCompanyCode from "@salesforce/apex/SBR_3_0_CustomLookupController.getCompanyCode";
import SAL_TEMPLATE from "./sbr_3_0_changeCustomerOnQuoteSAL.html";
import FL_TEMPLATE from "./sbr_3_0_changeCustomerOnQuoteFL.html";
const userFields = [ANALYSIS_REGION_KEY_FIELD];
import LABELS from "c/sbr_3_0_customLabelsCmp"; //FRONT-9251

export default class Sbr_3_0_changeCustomerOnQuote extends NavigationMixin(
  LightningElement
) {
  // areDetailsVisible = false;
  // accountLookupField = ACCOUNT_LOOKUP_FIELD;
  // officeAccountLookupField = ACCOUNT_OFFICE_LOOKUP_FIELD;
  @api accountId = "";
  @api accountName = "";
  @api officeAccountId;
  @api relatedRecordId;
  @api quoteName;
  @api orderedBy;
  //@api minStartDate;
  @api useJobSite = false;
  @api externalQuote = false;
  @api accountWhere;
  @api quoteRecordType;
  @api accountRecordType;
  @api currentUser;
  @api flowName;//FRONT-16849
  showFooterQuote = false;//FRONT-16849
  //defaultOfficeAccountId;
  //isChangeAccount = false;
  @track isAccountSelected = false;
  //@track isOrderedByButtonDisabled = true;

  //@track durationSelection;
  @track selectedAccount;
  @track selectedOfficeAccount;
  @track selectedContact;
  //@track customLineStyle;
  @track showFrontlineComponents;
  //@track companyCode;
  @track mobileMainDiv = "";
  @track parentComp = "quoterequireCustomLookup";
  // FRONTLINE changes
  @track isNonCreditAccount = false;
  //accountData;
  //Added as part of FRONT-2133
  frontlineDefaultFilteringFields =
    "RM_Account_Number__c, Phone,E_mail_Address__c,Record_Type_Text__c";

  //FRONT-1644 Start
  appName = "RAE Frontline";
  //showContact = true;
  // FRONTLINE change - FS2 - Leaving it uncommented since we have a property of the same name.
  @api showNewContact;
  currentUserId = USER_ID;
  currentUserRegionKey;
  showExternalUsedTools = false;
  externalToolCheckbox = false;
  jobSiteCheckbox = false;

  @track customerInfoPlaceHolder = LABELS.HELP_TEXT_CONTENT; //FRONT-8351

  @api hideExternalTool = false; //Added for the stroy #FRONT-19214 by Gopal Raj
  
  get showNewContactButton() {
    return this.showFrontlineComponents;
  }
  
  //FRONT-1644 End

  //currentProfileName;

  // @wire(getRecord, {
  //   recordId: "$officeAccountId",
  //   fields: [ACCOUNT_PARENTID_FIELD],
  // })
  // wiredOfficeAccount({ error, data }) {
  //   if (data) {
  //     this.selectedOfficeAccount = data;
  //     this.error = undefined;
  //   } else if (error) {
  //     this.error = error;
  //     this.selectedOfficeAccount = undefined;
  //   }
  // }
  // @wire(getObjectInfo, { objectApiName: ACCOUNT_OBJECT })
  // accountObjectInfo;
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

  //Retrieve current User based on UserId
  @wire(getRecord, { recordId: "$currentUserId", fields: userFields })
  currentUserInfo({ error, data }) {
    if (data) {
      this.currentUserRegionKey = getFieldValue(
        data,
        ANALYSIS_REGION_KEY_FIELD
      );
      if (
        this.quoteRecordType == 'Rental' &&
        (
          this.currentUserRegionKey === "934" ||
          this.currentUserRegionKey === "941"
        )
      ) {
        this.showExternalUsedTools = true;
      }
    } else if (error) {
      console.log(
        "An error occured while retrieving current user data " +
          error.body.message
      );
    }
  }

  connectedCallback() {
    if (window.matchMedia("(max-width: 480px)").matches) {
      this.mobileMainDiv = "mobileMainDiv";
    }
    //################################################## Soni - commented below line to avoid hard-coding of where clause ######################################################################################
    // this.minStartDate = new Date();
    // console.log(this.minStartDate);
    if (this.accountId !== undefined && this.accountId !== "") {
      this.isAccountSelected = true;
    }
    // if (this.orderedBy !== undefined) {
    //   this.isOrderedByButtonDisabled = false;
    // }

    getAppName()
      .then((results) => {
        this.appName = results;
        if (this.appName === "RAE Frontline") {
          this.isNonCreditAccount = this.accountRecordType === "Non-Credit";
          this.showFrontlineComponents = true;
          console.log("frontline");
          this.accountWhere =
            "(Status__c = 'Active' AND (RecordType.DeveloperName = 'Credit' OR RecordType.DeveloperName = 'Non_Credit' OR RecordType.DeveloperName = 'ERP_Link' OR RecordType.DeveloperName = 'Prospect') AND (Company_Code__c = '' OR Company_Code__c = '01' OR Company_Code__c = '02'))"; //   make this change on flow
        }
      })
      .catch((error) => {
        console.log("error");
      });
    // getCompanyCode()
    //   .then((results) => {
    //     this.companyCode = results;
    //   })
    //   .catch((error) => {
    //     console.log("error");
    //   });

    //FRONT-16849
    if(this.flowName === "RentalQuoteAcc" || this.flowName === "RateQuote"){
      this.showFooterQuote = true;
    }
  }

  renderedCallback() {
    // let footer = this.template.querySelector(".customfooter");
    // let width = footer.getBoundingClientRect().width + 24;
    // this.customLineStyle =
    //   "position: absolute; width: " +
    //   width +
    //   "px; margin-left: -12px; margin-right: 12px";
    if (this.externalQuote) {
      this.externalToolCheckbox = true;
    }
    if (this.useJobSite) {
      this.jobSiteCheckbox = true;
    }
  }

  handleNext(event) {
    const nextNavigationEvent = new FlowNavigationNextEvent();
    this.dispatchEvent(nextNavigationEvent);
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

  // FRONTLINE Changes to check for for "Id" & "id"
  handleOrderedByChange(event) {
    if (event.detail.selectedRecord !== undefined) {
      this.orderedBy =
        event.detail.selectedRecord.id == undefined
          ? event.detail.selectedRecord.Id
          : event.detail.selectedRecord.id;
      // this.isOrderedByButtonDisabled = false;
      console.log("Selected Contact: ", this.orderedBy);
    } else {
      this.orderedBy = "";
      // this.isOrderedByButtonDisabled = true;
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
    console.log('CHANGECUSTOMERONQUOTE',JSON.stringify(event.detail.selectedRecord));
    if (event.detail.selectedRecord !== undefined) {
      //this.isChangeAccount = true;
      this.accountId = event.detail.selectedRecord.Id;
      this.accountName = event.detail.selectedRecord.Name;
      this.isAccountSelected = true;
      // FRONTLINE Changes
      this.isNonCreditAccount =
        event.detail.selectedRecord.Record_Type_Text__c === "Non-Credit" &&
        this.appName === "RAE Frontline";
      this.accountRecordType = event.detail.selectedRecord.Record_Type_Text__c;
    } else {
      this.isAccountSelected = false;
      // this.isChangeAccount = false;
      this.accountName = "";
      // this.isOrderedByButtonDisabled = true;
      this.accountId = "";
      this.officeAccountId = "";
      this.orderedBy = "";
      this.isNonCreditAccount = false;
      this.accountRecordType = "";
    }
  }

  handleChecked(event) {
    if (event.target.checked != null) this.externalQuote = event.target.checked;
    //this.externalQuote = this.areDetailsVisible;
  }

  handleUseJobsite(event) {
    if (event.target.checked != null) this.useJobSite = event.target.checked;
  }

  get showExternalOffice() {
    if (this.showFrontlineComponents && this.isNonCreditAccount) {
      return false;
    }
    return true;
  }

  /*get account() {
    if (this.accountId !== undefined) {
      console.log("Get Account Standard");
      return this.accountId;
    } else if (this.officeAccountId !== undefined) {
      console.log("Get Account Is Office Account");
      return getFieldValue(this.selectedOfficeAccount, ACCOUNT_PARENTID_FIELD);
    } else if (this.isBillingAccount) {
      console.log("Get Account Is Billing Account");
      return this.relatedRecordId;
    }
  }*/
  get accountWhereClause() {
    console.log(" this.accountWhere @@ " + this.accountWhere);
    return this.accountWhere + ' AND RecordType.Name != \'Office\'';
  }

  /*
  set account(value) {
    console.log("Set Account");
    this.accountId = value;
  }
  */

  /*get officeAccount() {
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
      console.log("this.accountObjectInfo.data");
      const rtis = this.accountObjectInfo.data.recordTypeInfos;
      const creditRtId = Object.keys(rtis).find(
        (rti) => rtis[rti].name === "Credit"
      );
      const globalRtId = Object.keys(rtis).find(
        (rti) => rtis[rti].name === "Prospect"
      );
      const officeRtId = Object.keys(rtis).find(
        (rti) => rtis[rti].name === "Office"
      );
      return [creditRtId, globalRtId, officeRtId];
    }
    return [];
  }*/

  get officeWhereClause() {
    console.log("ParentId -> ", this.account);
    if (
      this.accountId &&
      this.accountWhere &&
      !this.showFrontlineComponents
    ) {
      return (
        "ParentId ='" + this.accountId + "' AND " + this.accountWhere
      );
    } else if (this.showFrontlineComponents) {
      return (
        "ParentId ='" + this.accountId + "' AND RecordType.Name = 'Office'"
      );
    }
    //return "";    console.log("RecordTypeId -> ", this.officeRtId);

    //############################################################### Soni - changed where clause #########################################################################

    /*if (
      this.account !== undefined &&
      this.account !== null &&
      this.companyCode !== undefined &&
      this.companyCode !== null
    ) {
      this.officeAccountWhereClause =
        " (RecordTypeId = '" +
        this.officeRtId[2] +
        "' AND (Parent.Record_Type_Text__c = 'Credit' AND (Status__c = 'Active' OR Status__c = 'On Hold' OR Status__c = 'Bad Debt' OR Status__c = 'Inactive' OR  = 'Suspended'))OR RecordTypeId = '" +
        this.officeRtId[1] +
        "' ) ";
    } else if (this.account !== undefined && this.account !== null) {
      this.officeAccountWhereClause =
        "ParentId = '" +
        this.account +
        "' AND RecordTypeId = '" +
        this.officeRtId[2] +
        "'  AND Company_Code__c != null";
    } else if (this.companyCode !== undefined && this.companyCode !== null) {
      this.officeAccountWhereClause =
        "RecordTypeId = '" +
        this.officeRtId +
        "'  AND Company_Code__c != null AND Company_Code__c = '" +
        this.companyCode +
        "'";
    } else {
      this.officeAccountWhereClause =
        "RecordTypeId = '" + this.officeRtId + "'  AND Company_Code__c != null";
    }

    console.log(
      "Office Account Where clause -> ",
      this.officeAccountWhereClause
    );
    return this.officeAccountWhereClause;
    */
  }

  /*set officeWhere(value) {
    if (
      this.account !== undefined &&
      this.account !== null &&
      this.companyCode !== undefined &&
      this.companyCode !== null
    ) {
      this.officeAccountWhereClause =
        "ParentId = '" +
        value +
        "' AND (RecordTypeId = '" +
        this.officeRtId[0] +
        "' OR RecordTypeId = '" +
        this.officeRtId[1] +
        "' ) AND Company_Code__c != null AND Company_Code__c = '" +
        this.companyCode +
        "'";
    } else if (this.account !== undefined && this.account !== null) {
      this.officeAccountWhereClause =
        "ParentId = '" +
        value +
        "' AND RecordTypeId = '" +
        this.officeRtId[3] +
        "'";
    } else if (this.companyCode !== undefined && this.companyCode !== null) {
      this.officeAccountWhereClause =
        "RecordTypeId = '" +
        this.officeRtId +
        "'  AND Company_Code__c != null AND Company_Code__c = '" +
        this.companyCode +
        "'";
    } else {
      this.officeAccountWhereClause =
        "RecordTypeId = '" + this.officeRtId + "' AND Company_Code__c != null";
    }
  }

  get isOfficeAccount() {
    if (this.objectApiName === "Account" && this.accRtId === this.officeRtId) {
      return true;
    }
    return false;
  }
*/
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

  showAccountCreationModal(event) {
    event.preventDefault();
  }

  render() {
    return this.appName === "RAE Frontline" ? FL_TEMPLATE : SAL_TEMPLATE;
  }
}