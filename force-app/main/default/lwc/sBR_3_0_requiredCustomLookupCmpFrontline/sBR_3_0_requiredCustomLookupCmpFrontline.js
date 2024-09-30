/* eslint-disable @lwc/lwc/no-api-reassignments */
import { LightningElement, api, wire, track } from "lwc";
// import apex method from salesforce module
import fetchLookupData from "@salesforce/apex/SBR_3_0_CustomLookupController.fetchLookupData";
import fetchDefaultRecord from "@salesforce/apex/SBR_3_0_CustomLookupController.fetchDefaultRecord";
/* FRONT-8351 start */
import FrontLineCSS from "@salesforce/resourceUrl/FrontLinesCSS";
import { loadStyle } from "lightning/platformResourceLoader";
import LABELS from "c/sbr_3_0_customLabelsCmp";
/* FRONT-8351 end */
import { refreshApex } from "@salesforce/apex";
import { Logger } from "c/sbr_3_0_frontlineUtils";
const logger = Logger.create(true);

const DELAY = 300; // dealy apex callout timing in miliseconds

export default class CustomLookupLwc extends LightningElement {
  // public properties with initial default values

  @track errorTitle;
  @track errorMsg;
  @api label = "Custom Lookup Label";
  helpTextContent = LABELS.HELP_TEXT_CONTENT; //FRONT-8351
  @api placeholder = "search...";
  @api iconName = "standard:opportunity";
  @api sObjectApiName = "Account";
  @api defaultRecordId = "";
  @api fieldsToInclude = "";
  @api hasCustomNameField = false;
  @api customNameField = "";
  @api fieldsToSet = "";
  @api parentcmp;
  @api recordId = "";
  @api whereClause = "";
  @api isAccountLookup = false;
  @api displayLocationDetails = false;
  @api addIconName = "utility:add";
  @api searchIconName = "utility:search";
  doesRMNumberExist = false;
  doesAddressExist = false;
  @track isModalOpen = false;
  @track displayToast = false;
  @track successTitle = "";
  @track successMsg = "";
  @api hasRequired = false;
  @api isContract = ""; //Front-14007, FRONT-16849
  RECORD_TYPE_CHECK;
  //FRONT-2139 Record Types check
  @api recordTypeName; //Front-20803
  @api warningScreen = false; //Front-20803
  isDesktop = false;

  // private properties
  @track lstResult = []; // to store list of returned records
  hasRecords = true;
  searchKey = ""; // to store input field value
  isSearchLoading = false; // to control loading spinner
  delayTimeout;
  selectedRecord = {}; // to store selected lookup record in object formate
  isMobile = false; //FRONT-2445
  @track showAllResultsButton = false;
  @api searchAccountMobile = false; //FRONT-2445
  relatedSearchlookup = {};
  // initial function to populate default selected lookup record if defaultRecordId provided
  connectedCallback() {
    this.loadStyleSheet(); //FRONT-8351
    if (this.defaultRecordId !== "") {
      this.setDefaultSelection();
    } else if (this.recordId !== "" && this.recordId != null) {
      this.defaultRecordId = this.recordId;
      this.setDefaultSelection();
    }
    this.isMobile = window.matchMedia("(max-width: 480px)").matches;
    this.isDesktop = !this.isMobile;
  }
  /* FRONT-8351 start */
  loadStyleSheet() {
    loadStyle(this, FrontLineCSS);
  }
  /* FRONT-8351 end */
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
        logger.log("fetch default error", error);
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
    hasCustomNameField: "$hasCustomNameField"
  })
  searchResult(value) {
    // const { data, error } = value; // destructure the provisioned value
    this.isSearchLoading = false;
    this.relatedSearchlookup = value;
    const { data, error } = this.relatedSearchlookup; // destructure the provisioned value
    if (data) {
      this.hasRecords = data.length === 0 ? false : true;
      this.lstResult = JSON.parse(JSON.stringify(data));
      if (this.sObjectApiName === "Contact") {
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
      }
      for (var i = 0; i < this.lstResult.length; i++) {
        let o = this.lstResult[i];

        if (this.hasCustomNameField) {
          o.DisplayName = o[this.customNameField];
        } else {
          o.DisplayName = o["Name"];
        }
        if (this.isAccountLookup) {
          this.displayAccountFields(o);
        } else if (this.displayLocationDetails) {
          this.generateLocationDetails(o);
        }
      }
    } else if (error) {
      logger.log("(error---> " + JSON.stringify(error));
    }
  }

  displayAccountFields(obj) {
    obj.Line1 = "";
    obj.Line2 = "";
    if (obj.RM_Account_Number__c !== undefined) {
      this.doesRMNumberExist = true;
      obj.Line1 +=
        "Account #: " + obj.RM_Account_Number__c + " (" + obj.Status__c + ")";
    }
    if (obj.ShippingCity !== undefined) {
      this.doesAddressExist = true;
      obj.Line2 +=
        obj.ShippingCity +
        ", " +
        obj.ShippingState +
        " " +
        obj.ShippingPostalCode +
        "  ";
    }
    if (obj.Phone !== undefined) {
      // let phone = obj.Phone.replace(/\D/g, '');
      let phone = "";
      var cleaned = ("" + obj.Phone).replace(/\D/g, "");
      var match = cleaned.match(/^(\d{3})(\d{3})(\d{4})$/);
      if (match) {
        phone = "(" + match[1] + ")" + match[2] + "-" + match[3];
      }
      obj.Line2 += phone;
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
  }

  // update searchKey property on input field change
  handleKeyChange(event) {
    // Debouncing this method: Do not update the reactive property as long as this function is
    // being called within a delay of DELAY. This is to avoid a very large number of Apex method calls.
    this.isSearchLoading = true;
    window.clearTimeout(this.delayTimeout);
    const searchKey = event.target.value;
    this.delayTimeout = setTimeout(() => {
      this.searchKey = searchKey;
    }, DELAY);
  }

  // method to toggle lookup result section on UI
  toggleResult(event) {
    const lookupInputContainer = this.template.querySelector(
      ".lookupInputContainer"
    );

    const clsList = lookupInputContainer.classList;
    const whichEvent = event.target.getAttribute("data-source");
    //Front-18945
    if (this.isMobile && !this.warningScreen) {
      //START::FRONT-2445
      this.searchAccountMobile = true;
      //END::FRONT-2445
    } else {
      switch (whichEvent) {
        case "searchInputField":
          clsList.add("slds-is-open");
          break;
        case "lookupContainer":
          clsList.remove("slds-is-open");
          break;
      }
    }
  }

  // method to clear selected lookup record
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
    //this.template.querySelector("lightning-input").focus();
  }

  // method to update selected record from search result
  handleSelectedRecord(event) {
    var objId = event.target.getAttribute("data-recid"); // get selected record Id
    this.recordId = objId;
    this.selectedRecord = this.lstResult.find((data) => data.Id === objId); // find selected record from list
    this.lookupUpdatehandler(this.selectedRecord); // update value on parent component as well from helper function
    this.handleSelectRecordHelper(); // helper function to show/hide lookup result container on UI
  }

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

  createNewAccount(event) {
    this.isModalOpen = true;
  }

  closeModal() {
    // this.searchAccountMobile = false;
    this.isModalOpen = false;
    //FRONT-12375 : Added manual focus on previous screen
    const inputField = this.template.querySelector(
      '[data-actiontype="searchCustomer"]'
    );
    if (inputField) {
      inputField.focus();
    }
    //End of front
  }
  closeToast(event) {
    this.displayToast = false;
  }

  hideResults(event) {
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
        this.handleSelectedRecordFromModal(account);
      }
    }

    this.showAllResultsFlag = false;
  }

  // method to update selected record from all list view modal
  handleSelectedRecordFromModal(account) {
    // var objId = event.target.getAttribute('data-recid'); // get selected record Id
    this.recordId = account.Id;

    //this.selectedRecord = this.lstResult.find(data => data.Id === objId); // find selected record from list
    this.selectedRecord = account;
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
        if (this.selectedRecord.Id === this.selectedRecords[i].Id) {
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

  // send selected lookup record to parent component using custom event
  lookupUpdatehandler(value) {
    if (this.multiSelect) {
      const oEvent = new CustomEvent("lookupupdate", {
        detail: this.selectedRecordsIds.join(", ")
      });
      this.dispatchEvent(oEvent);
    } else {
      const oEvent = new CustomEvent("lookupupdate", {
        detail: { selectedRecord: value }
      });
      this.dispatchEvent(oEvent);
    }
  }

  @track showAllResultsFlag = false;

  showAllResults(event) {
    this.showAllResultsFlag = !this.showAllResultsFlag;
  }

  showAccountCreationModal(event) {
    this.isModalOpen = true;
    this.showAllResultsFlag = false;
    //FRONT-12375 : manually setting the focus to thecustomModal as part of accessibility issue fix
    setTimeout(() => {
      const customModal = this.template.querySelector(
        "c-sbr_3_0_custom-modal-cmp"
      );
      if (customModal) {
        customModal.setFocus();
      }
    }, 500);
    //End of front 12375
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
  //START::FRONT-2445,2439,2442
  closeAccountSearchMobile() {
    this.searchAccountMobile = false;
  }
  //END::FRONT-2445,2439,2442
  resultFromMobileCmp(event) {
    if (event.detail) {
      let account = JSON.parse(JSON.stringify(event.detail.selectedRecord));
      this.handleSelectedRecordFromModal(account);
    }
    this.showAllResultsFlag = false;
  }

  // FRONT-20757 & FRONT-20761
  @api refreshApexMethod() {
    return refreshApex(this.relatedSearchlookup);
  }

  // FRONT-11447 start
  handleKeyUp(event) {
    let actionType = event.target.dataset.actiontype;
    logger.log("actionType=" + event.target.dataset.actiontype);
    if (event.keyCode === 13) {
      logger.log("dataset=" + JSON.stringify(event.target.dataset));
      logger.log("after enter");
      if (actionType === "showAllResults") {
        this.showAllResults(event);
        //FRONT-12375 : manually setting the focus to the account list modal as part of accessibility issue fix
        setTimeout(() => {
          const listViewCmp = this.template.querySelector(
            "c-sbr_3_0_custom-account-list-view-cmp"
          );
          if (listViewCmp) {
            listViewCmp.setFocus();
          }
        }, 500);
        //End of front 12375
      } else if (actionType === "newAccount") {
        this.createNewAccount(event);
        //FRONT-12375 : manually setting the focus to thecustomModal as part of accessibility issue fix
        setTimeout(() => {
          const customModal = this.template.querySelector(
            "c-sbr_3_0_custom-modal-cmp"
          );
          if (customModal) {
            customModal.setFocus();
          }
        }, 500);
        //End of front 12375
      } else if (actionType === "handleRecordSelection") {
        this.handleSelectedRecord(event);
      } else if (actionType === "searchCustomer") {
        this.toggleResult(event);
      }
    }
  } // end FRONT-11447

  //FRONT-30881 : Remove box shadows left padding for mobile screens
  get selectedInputPillClasses() {
    return this.isDesktop
      ? "slds-input slds-combobox__input slds-combobox__input-value textCss"
      : "slds-input slds-combobox__input slds-combobox__input-value remove-box-shadow-class";
  }

  get selectedIconContainerClasses() {
    return this.isDesktop
      ? "slds-icon_container slds-combobox__input-entity-icon"
      : "slds-icon_container slds-combobox__input-entity-icon slds-var-p-left_xx-small";
  }
  get labelPropertyClasses() {
    return this.isDesktop
      ? "slds-form-element__label label-padding"
      : "slds-form-element__label label-padding label-header-class";
  }
}