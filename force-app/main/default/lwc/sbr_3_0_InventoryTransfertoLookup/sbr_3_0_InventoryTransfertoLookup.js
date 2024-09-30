/* eslint-disable @lwc/lwc/no-api-reassignments */
import { LightningElement, api, wire } from "lwc";
// import apex method from salesforce module
import fetchLookupData from "@salesforce/apex/SBR_3_0_CustomLookupController.fetchLookupDataUsingParent";
import fetchDefaultRecord from "@salesforce/apex/SBR_3_0_CustomLookupController.fetchDefaultRecord";
import { FlowAttributeChangeEvent } from "lightning/flowSupport";
import FORM_FACTOR from "@salesforce/client/formFactor";
import getRecordTypeInfo from "@salesforce/apex/SBR_3_0_CustomLookupController.getRecordTypeInfo"; //FRONT-8624,11071
import { loadStyle } from "lightning/platformResourceLoader";
import CUSTOMCSS from "@salesforce/resourceUrl/customError"; // Front-12597

const DELAY = 300; // dealy apex callout timing in miliseconds

export default class CustomLookupLwc extends LightningElement {
  // public properties with initial default values
  @api label = "Custom Lookup Label";
  @api placeholder = "search...";
  @api iconName = "standard:opportunity";
  @api sObjectApiName = "Opportunity";
  @api defaultRecordId = "";
  @api fieldsToInclude = "";
  @api hasCustomNameField = false;
  @api customNameField = "";
  @api fieldsToSet = "";

  @api recordId = "";
  @api parentName = "";
  @api whereClause = "";
  @api newProfileBranch;

  @api isAccountLookup = false;
  @api isLocationLookup = false;
  @api isContactLookup = false;
  @api displayLocationDetails = false;
  //@api lstResultDefault = []; //Added as part of SAL-26648
  doesRMNumberExist = false;
  doesAddressExist = false;
  hasOrderByBlank = false;
  isCssLoaded = false; //Front-12597

  // private properties
  spinnerShow = false; //Added as part of SAL-26648
  lstResult = []; // to store list of returned records
  hasRecords = true;
  searchKey = ""; // to store input field value
  isSearchLoading = false; // to control loading spinner
  delayTimeout;
  selectedRecord = {}; // to store selected lookup record in object formate
  isMobile = false;
  isJobSite = false;
  spinnerCss = "spinner-height";

  //FRONT-1644 Start
  @api showNewContact;
  @api showContact;
  @api showNewContactButton;
  @api addIconName = "utility:add";
  isContactModalOpen = false;
  //showFrontlineComponents = false;
  @api accId = "";
  //FRONT-1644 End
  recordTypeData = []; //FRONT-8624,11071: to store list of Account Record Types
  selectedRecordRT = {}; //FRONT-8624,11071: to store selected record type record in object format
  //START: FRONT-11400
  @api parentCmp = "";
  isJobSiteContactCreation = false;
  //END: FRONT-11400

  // initial function to populate default selected lookup record if defaultRecordId provided
  connectedCallback() {
    if (FORM_FACTOR === "Small") {
      this.isMobile = true;
    }
   if (this.defaultRecordId != "") {
      this.newProfileBranch = this.defaultRecordId;
      this.dispatchEvent(
        new FlowAttributeChangeEvent("newProfileBranch", this.newProfileBranch)
      );
      this.setDefaultSelection();
    } else if (this.recordId != "" && this.recordId != null) {
      this.defaultRecordId = this.recordId;
      this.setDefaultSelection();
    }
    //START: FRONT-11400
  /*  if (this.parentCmp === "contactLookupCmp") {
      this.isJobSiteContactCreation = true;
    } *///END: FRONT-11400
  }

  @api
  validate() {
    if (
      this.selectedRecord &&
      Object.keys(this.selectedRecord).length === 0 &&
      Object.getPrototypeOf(this.selectedRecord) === Object.prototype
    ) {
      return {
        isValid: false,
        errorMessage: this.sObjectApiName + " is required"
      };
    } else {
      return { isValid: true };
    }
  }

  @api validateInput() {
    let proceedFurther = false;
    const inputField = this.template.querySelector(
      'lightning-input[data-id="check-input-validity"]'
    );
    console.log("input field below");
    if (!inputField.value) {
      inputField.setCustomValidity("Complete this field.");
      inputField.reportValidity();
    } else {
      proceedFurther = true;
    }
    return proceedFurther;
  }

  setDefaultSelection() {
    fetchDefaultRecord({
      recordId: this.defaultRecordId,
      sObjectApiName: this.sObjectApiName,
      hasCustomNameField: this.hasCustomNameField
    })
      .then((result) => {
        if (result != null) {
          console.log("fetched default record from requiredCustomLookupcmp->");
          console.log(result);
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

  // wire function property to fetch search record based on user input
  @wire(fetchLookupData, {
    searchKey: "$searchKey",
    sObjectApiName: "$sObjectApiName",
    whereClause: "$whereClause",
    fieldsToInclude: "$fieldsToInclude",
    hasCustomNameField: "$hasCustomNameField",
    parentName: "$parentName"
  })
  searchResult(value) {
    this.spinnerShow = true;
    console.log(
      this.sObjectApiName + " Child MEthod Call > WHERE -->" + this.whereClause
    );
    /*if(this.whereClause == 'SKIP') {
            console.log(this.sObjectApiName + ' << Lookup lstResultDefault >> '+JSON.stringify(this.lstResultDefault));
            this.setDefaultResultList();
            this.spinnerShow = false;
        }
        else {*/
    console.log(this.sObjectApiName + "searchResult-->" + value);
    const { data, error } = value; // destructure the provisioned value
    this.isSearchLoading = false;
    console.log(
      "searchResult data in requiredCustomLookup Cmp-->" + JSON.stringify(data)
    );
    console.log("whereClause data-->" + this.whereClause);
    console.log("searchResult error-->" + JSON.stringify(error));
    try {
      if (data) {
        this.hasRecords = data.length == 0 ? false : true;
        this.lstResult = JSON.parse(JSON.stringify(data));
        /*if (this.sObjectApiName === "Contact") {
          // Sorting by Last then First Name
          this.lstResult.sort((a, b) =>
            a.LastName > b.LastName
              ? 1
              : a.LastName < b.LastName
              ? -1
              : a.FirstName > b.FirstName
              ? 1
              : a.FirstName < b.FirstName
              ? -1
              : 0
          );
        }*/
        for (var i = 0; i < this.lstResult.length; i++) {
          let o = this.lstResult[i];
          if (this.hasCustomNameField) {
            o.DisplayName = o[this.customNameField];
          } else {
            o.DisplayName = o["Name"];
          }
          /*if (this.isAccountLookup) {
            this.displayAccountFields(o);
          } else if (this.sObjectApiName === "AssociatedLocation") {
            this.isJobSite = true;
          } else if (this.displayLocationDetails) {
            this.generateLocationDetails(o);
          } else if (this.isContactLookup) {
            this.displayContactFields(o);
          }*/
        }
        this.spinnerShow = false;
      } else if (error) {
        console.log("(error---> " + JSON.stringify(error));
      }
    } catch (error) {
      console.error(error);
    }
    //}
  }

  /*displayAccountFields(obj) {
    obj.Line1 = "";
    obj.Line2 = "";
    if (
      obj.RM_Account_Number_Display__c !== undefined ||
      obj.Status__c !== undefined
    ) {
      obj.Line1 += "Account #: ";
    }
    obj.Line1 += `${
      obj.RM_Account_Number_Display__c
        ? `${obj.RM_Account_Number_Display__c}`
        : ""
    } ${obj.Status__c ? `  (${obj.Status__c})` : ""}`;
    obj.Line2 += `${obj.ShippingCity ? `${obj.ShippingCity}` : ""}${
      obj.ShippingState ? `, ${obj.ShippingState}` : ""
    } ${obj.ShippingPostalCode ? `  ${obj.ShippingPostalCode}` : ""}`;

    if (obj.Phone !== undefined) {
      // let phone = obj.Phone.replace(/\D/g, '');
      let phone = "";
      var cleaned = ("" + obj.Phone).replace(/\D/g, "");
      var match = cleaned.match(/^(\d{3})(\d{3})(\d{4})$/);
      if (match) {
        phone = "(" + match[1] + ")" + match[2] + "-" + match[3];
      }
      obj.Line2 += `   ${phone}`;
    }
    obj.recordTypeName = "";
    obj.recordTypeName = obj["RecordType"]
      ? obj.RecordType["Name"]
        ? obj.RecordType.Name
        : ""
      : "";
  }

  displayContactFields(obj) {
    obj.Line1 = "";
    obj.Line2 = "";
    obj.hasPhone = false;
    obj.hasMobile = false;
    if (obj.Phone !== undefined) {
      obj.hasPhone = true;
      // let phone = obj.Phone.replace(/\D/g, '');
      let phone = "";
      var cleaned = ("" + obj.Phone).replace(/\D/g, "");
      var match = cleaned.match(/^(\d{3})(\d{3})(\d{4})$/);
      if (match) {
        phone = "(" + match[1] + ")" + match[2] + "-" + match[3];
      }
      obj.Line1 += phone;
    }
    if (obj.MobilePhone !== undefined) {
      obj.hasMobile = true;
      // let phone = obj.Phone.replace(/\D/g, '');
      let mobile = "";
      var cleaned = ("" + obj.MobilePhone).replace(/\D/g, "");
      var match = cleaned.match(/^(\d{3})(\d{3})(\d{4})$/);
      if (match) {
        mobile = "(" + match[1] + ")" + match[2] + "-" + match[3];
      }
      obj.Line2 += mobile;
    }
  }

  generateLocationDetails(obj) {
    obj.Line1 = "";
    obj.Line2 = "";
    if (this.sObjectApiName === "AssociatedLocation") {
      obj.Line1 += "Job Number: " + obj.Job_Number__c;
    }
    let address = "";
    address += obj.Street_Address__c;
    if (obj.Street_Address_2__c !== undefined) {
      address += ", " + obj.Street_Address_2__c;
    }
    address +=
      ", " + obj.City__c + ", " + obj.State__c + ", " + obj.Zip_Code__c;
    obj.Line2 = address;
  }*/

  // update searchKey property on input field change
  handleKeyChange(event) {
    // Debouncing this method: Do not update the reactive property as long as this function is
    // being called within a delay of DELAY. This is to avoid a very large number of Apex method calls.
    const lookupInputContainer = this.template.querySelector(
      ".lookupInputContainer"
    );
    lookupInputContainer.classList.add("slds-is-open");

    this.spinnerCss = this.lstResult.length == 0 ? "spinner-height" : "";
    this.hasRecords = true;
    this.spinnerShow = true;
    this.isSearchLoading = true;
    window.clearTimeout(this.delayTimeout);
    const searchKey = event.target.value;
    this.delayTimeout = setTimeout(() => {
      this.searchKey = searchKey;
    }, DELAY);
  }

  handleKeyPress(event) {
    if (event.keyCode === 13) {
      event.preventDefault();
    }
  }

  // method to toggle lookup result section on UI
  toggleResult(event) {
    const lookupInputContainer = this.template.querySelector(
      ".lookupInputContainer"
    );
    const clsList = lookupInputContainer.classList;
    const whichEvent = event.target.getAttribute("data-source");

    switch (whichEvent) {
      case "searchInputField":
        clsList.add("slds-is-open");
        break;
      case "lookupContainer":
        clsList.remove("slds-is-open");
        break;
    }
  }

  // method to clear selected lookup record
  @api
  handleRemove() {
    this.searchKey = "";
    this.selectedRecord = {};
    this.recordId = "";
    this.lookupUpdatehandler(undefined); // update value on parent component as well from helper function

    // remove selected pill and display input field again
    const searchBoxWrapper = this.template.querySelector(".searchBoxWrapper");
    searchBoxWrapper.classList.remove("slds-hide");
    searchBoxWrapper.classList.add("slds-show");

    const pillDiv = this.template.querySelector(".pillDiv");
    pillDiv.classList.remove("slds-show");
    pillDiv.classList.add("slds-hide");

    // show validation error
    var clsName;
    if (this.isMobile) {
      clsName = "inputMobile";
    } else {
      clsName = "inputDesktop";
    }
    var inputCmp = this.template.querySelector("." + clsName);
    if (!inputCmp.value) {
      inputCmp.setCustomValidity("Complete this field.");
      inputCmp.reportValidity();
    }
  }

  //Front-12597 Ends

  // method to update selected record from search result
  handleSelectedRecord(event) {
    var objId = event.target.getAttribute("data-recid"); // get selected record Id
    this.recordId = objId;
    this.newProfileBranch = objId;

    /*this.dispatchEvent(
      new FlowAttributeChangeEvent("newProfileBranch", this.newProfileBranch)
    );*/
    this.selectedRecord = this.lstResult.find((data) => data.Id === objId); // find selected record from list
    // Start FRONT-8624,11071
    /*if (this.sObjectApiName === "Account") {
      this.selectedRecordRT = this.recordTypeData.find(
        (data) => data.Id === this.selectedRecord.RecordTypeId
      );
      if (
        (this.selectedRecordRT.Name === "Non-Credit" &&
          this.selectedRecord.Status__c !== "Closed" &&
          this.selectedRecord.Status__c !== "Deleted" &&
          this.selectedRecord.Status__c !== "Inactive") ||
        ((this.selectedRecordRT.Name === "Credit" ||
          this.selectedRecordRT.Name === "Corp Link") &&
          this.selectedRecord.Status__c !== "Closed" &&
          this.selectedRecord.Status__c !== "Deleted" &&
          this.selectedRecord.Status__c !== "Inactive" &&
          this.selectedRecord.Status__c !== "Credit Denied")
      ) {
        this.lookupUpdatehandler(this.selectedRecord); // update value on parent component as well from helper function
        this.handleSelectRecordHelper(); // helper function to show/hide lookup result container on UI
      }
    }
    // End FRONT-8624,11071
    else {*/
      this.lookupUpdatehandler(this.selectedRecord); // update value on parent component as well from helper function
      this.handleSelectRecordHelper();
   // }
  }

  //Start FRONT-8624,11071
 /* @wire(getRecordTypeInfo, {
    sObjectApiName: "$sObjectApiName"
  })
  recordTypeInfo(value) {
    const { data, error } = value; // destructure the provisioned value
    if (data) {
      this.recordTypeData = JSON.parse(JSON.stringify(data));
    } else if (error) {
      console.log("error---> " + JSON.stringify(error));
    }
  }*/
  //End FRONT-8624,11071

  /*COMMON HELPER METHOD STARTED*/

  handleSelectRecordHelper() {
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

  // send selected lookup record to parent component using custom event
  lookupUpdatehandler(value) {
    const oEvent = new CustomEvent("lookupupdate", {
      detail: { selectedRecord: value }
    });
    this.dispatchEvent(oEvent);
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
    console.log("set default record value requiredCustomLookUpCmp-> ", value);
    this.defaultRecordId = value;
    //this.setDefaultSelection();
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
        searchBoxWrapper.classList.remove("slds-hide");
        searchBoxWrapper.classList.add("slds-show");

        const pillDiv = this.template.querySelector(".pillDiv");
        pillDiv.classList.remove("slds-show");
        pillDiv.classList.add("slds-hide");
      }
    }
  }

  get validateSObjectLabelDisplay() {
    return !this.displayLocationDetails;
  }

  // Method shows required field error. This is not handled using standard required feature bcoz it was making user select a record twice for the lookup field. As first time it was throwing error.
  showRequiredFieldError(event) {
    var clsName = event.target.classList[0];
    var inputCmp = this.template.querySelector("." + clsName);
    if (!inputCmp.value) {
      inputCmp.setCustomValidity("Complete this field.");
      inputCmp.reportValidity();
      const dropdownContainer = this.template.querySelector(".slds-dropdown");
      if (dropdownContainer) {
        dropdownContainer.classList.add("spinner-top");
      }
    }
  }
  //FRONT-12597 Ends
  //FRONT-1644 Start
 /* createNewContact() {
    this.isContactModalOpen = true;
    // this.dispatchEvent(new CustomEvent("showfrontlinecmp"));
  }

  closeContactModal() {
    this.isContactModalOpen = false;
  }
  handleSaveContact(event) {
    this.dispatchEvent(
      new CustomEvent("lookupupdate", {
        detail: { selectedRecord: event.detail }
      })
    );
    this.isContactModalOpen = false;
  }*/
  //FRONT-1644 End
}