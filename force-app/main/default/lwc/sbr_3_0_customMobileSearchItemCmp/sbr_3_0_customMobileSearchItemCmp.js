import { LightningElement, api } from "lwc";
import FrontLineCSS from "@salesforce/resourceUrl/FrontLinesCSS";
import { loadStyle } from "lightning/platformResourceLoader";
//FRONT-4592 Const Map variable for Account's Status__c field values
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

export default class Sbr_3_0_customMobileSearchItemCmp extends LightningElement {
  editableAccount = ["Prospect", "Non-Credit","Guest"]; //added guest for FRONT-16849
  convertableAccount = ["Prospect","Guest"]; //added for 4002,added guest for FRONT-16849
    openConversionScreen = false; // added for 4002
  columnVisibilityAccount = ["Credit", "Non-Credit", "Corp Link"];
    @api recordItem = {};
    isMobile = false;
  @api parentcmp = ""; //added for 2442
  selectedRecId = "";
    styleSheetLoaded = false;
    isEditable = false;
    get displayName() {
        return this.recordItem.DisplayName;
    }

    get itemNumber() {
        return this.recordItem.RM_Account_Number__c;
    }

    get itemType() {
        return this.recordItem.Record_Type_Text__c;
    }

    get phoneNumber() {
        return this.recordItem.Phone;
    }

    get cityState() {

        //let state = this.recordItem.BillingState ? ', ' + this.recordItem.BillingState : '';
    let value = "";
    if (this.recordItem.BillingCity) value = this.recordItem.BillingCity;
        if (this.recordItem.BillingState)
      value = value + ", " + this.recordItem.BillingState;
        return value;
    }
    //Modified as part of FRONT-4085
    get status() {
        return this.recordItem.Status__c;
    }
    //Start for FRONT-4002
    get IsConvert() {
        return this.convertableAccount.includes(this.itemType);
    }
    //End for FRONT-4002
    get hasEditable() {
        console.log('this.editableAccount'+JSON.stringify(this.editableAccount));
        console.log('this.itemType'+this.itemType);
        console.log('hasEditable'+this.editableAccount.includes(this.itemType));
        return this.editableAccount.includes(this.itemType);
    }

    get checkVisibility() {
        return this.columnVisibilityAccount.includes(this.itemType);
    }

    //START: FRONT-13601
    get isAccountScreenParent() {
        console.log('parentcmp'+this.parentcmp);
        return this.parentcmp === 'accountsearchscreen';
    }

    get isAccEditable() {
        return (this.recordItem.Record_Type_Text__c === "Prospect" || (this.recordItem.Record_Type_Text__c === "Non-Credit" &&  this.recordItem.Status__c !== ACCOUNT_STATUS_VALUES.DELETED) ||
        (this.parentcmp === 'accountsearchscreen' && this.recordItem.Record_Type_Text__c === "Guest")); //Added for FRONT-16849
    }
    //END: FRONT-13601


    openMenu(event) {
        event.stopPropagation();
    }

    //START: FRONT-3033, FRONT-2621, FRONT- 3115, FRONT-3125 
    connectedCallback() {
        this.selectedRecId = this.recordItem.Id;
        this.isMobile = window.matchMedia("(max-width: 480px)").matches;
    }
    //END: FRONT-3033, FRONT-2621, FRONT- 3115, FRONT-3125

    //Start for 2442,2443,2445,2439,2440
    renderedCallback() {
    if (
      this.parentcmp == "quoterequireCustomLookup" ||
      this.parentcmp == "orderrequireCustomLookup"
    ) {
            var ite = this.template.querySelectorAll('[data-id="quOrd"]');
      ite.forEach((ele) => ele.classList.add("itemVal"));
        }
        if (!this.styleSheetLoaded) {
            this.loadStyleSheet();
        }
    }
    //End for 2442,2443,2445,2439,2440

    //START: FRONT-3033, FRONT-2621, FRONT- 3115, FRONT-3125 
    openEditForm() {
    const sendEvent = new CustomEvent("editclick", {
      detail: this.selectedRecId
    });
        this.dispatchEvent(sendEvent);
    }
    //END: FRONT-3033, FRONT-2621, FRONT- 3115, FRONT-3125
    //start for FRONT-4002
    handleConversion() {
    const convertEvent = new CustomEvent("covertclick", {
      detail: this.selectedRecId
    });
        this.dispatchEvent(convertEvent);
    }

    viewDetails() {
        const convertEvent = new CustomEvent('click', { detail: this.selectedRecId });
        this.dispatchEvent(convertEvent);
    }

    async loadStyleSheet() {
        try {
            await loadStyle(this, FrontLineCSS);
            this.styleSheetLoaded = true;
        } catch (e) {
            console.error(e);
        }
    }

    //Adding as part of FRONT-4592
    applyStatusButtonBackgroundColor(status) {
        let defaultStatusClass = "color-boxes ";
        let colorClass = "";

        if (status === ACCOUNT_STATUS_VALUES.ACTIVE) colorClass = "greenColor";
        if (status === ACCOUNT_STATUS_VALUES.INACTIVE) colorClass = "greyColor";
        if (status === ACCOUNT_STATUS_VALUES.CLOSED) colorClass = "greyColor";
        if (status === ACCOUNT_STATUS_VALUES.ONHOLD) colorClass = "orangeColor";
        if (status === ACCOUNT_STATUS_VALUES.NONE) colorClass = "greyColor";
        if (status === ACCOUNT_STATUS_VALUES.BADDEBT) colorClass = "redColor";
        if (status === ACCOUNT_STATUS_VALUES.DELETED) colorClass = "redColor";
        if (status === ACCOUNT_STATUS_VALUES.SUSPENDED) colorClass = "redColor";
        if (status === ACCOUNT_STATUS_VALUES.CREDITDENIED) colorClass = "redColor";
        return defaultStatusClass + colorClass;
    }

    //Adding as part of FRONT-4592
    get statusButtonBackgroundColour() {
        if (this.status) {
            return this.applyStatusButtonBackgroundColor(this.status);
        }
    }

    // Start FRONT-11071
    get showchevron() {
    if (this.parentcmp === "orderrequireCustomLookup") {
            // Start FRONT-2487
      if (
        ((this.recordItem.Record_Type_Text__c === "Credit" ||
          this.recordItem.Record_Type_Text__c === "Corp Link" ||
          this.recordItem.Record_Type_Text__c === "Non-Credit") &&
          this.recordItem.Status__c === ACCOUNT_STATUS_VALUES.ACTIVE) ||
        this.recordItem.Record_Type_Text__c === "Prospect" ||
        this.recordItem.Record_Type_Text__c === "Guest" //FRONT-16849
      ) {
                return true;
            }
            return false;
            // End FRONT-2487
    } else {
      if (
        (this.recordItem.Record_Type_Text__c === "Credit" ||
          this.recordItem.Record_Type_Text__c === "Corp Link") &&
                (this.recordItem.Status__c === ACCOUNT_STATUS_VALUES.CLOSED ||
                    this.recordItem.Status__c === ACCOUNT_STATUS_VALUES.DELETED ||
                    this.recordItem.Status__c === ACCOUNT_STATUS_VALUES.INACTIVE ||
          this.recordItem.Status__c === ACCOUNT_STATUS_VALUES.CREDITDENIED)
      ) {
                return false;
      } else if (
        this.recordItem.Record_Type_Text__c === "Non-Credit" &&
                (this.recordItem.Status__c === ACCOUNT_STATUS_VALUES.CLOSED ||
                    this.recordItem.Status__c === ACCOUNT_STATUS_VALUES.DELETED ||
          this.recordItem.Status__c === ACCOUNT_STATUS_VALUES.INACTIVE)
      ) {
                return false;
            }
            return true;
        }
    }
    // End FRONT-11071
}