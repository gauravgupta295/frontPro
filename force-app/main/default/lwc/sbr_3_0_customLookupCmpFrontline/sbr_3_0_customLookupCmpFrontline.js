import { LightningElement, api, wire, track } from "lwc";
// import apex method from salesforce module
import fetchLookupData from "@salesforce/apex/SBR_3_0_CustomLookupController.fetchLookupData";
import fetchDefaultRecord from "@salesforce/apex/SBR_3_0_CustomLookupController.fetchDefaultRecord";
/* FRONT-8351 start */
import FrontLineCSS from "@salesforce/resourceUrl/FrontLinesCSS";
import { loadStyle } from "lightning/platformResourceLoader";
import LABELS from "c/sbr_3_0_customLabelsCmp";
/* FRONT-8351 end */

const DELAY = 300; // dealy apex callout timing in miliseconds

export default class Sbr_3_0_customLookupCmpFrontline extends LightningElement {
  // public properties with initial default values
  @api label = "Custom Lookup Label";
  helpTextContent = LABELS.HELP_TEXT_CONTENT; //FRONT-8351
  @api placeholder = "search...";
  @api iconName = "standard:opportunity";
  @api addIconName = "utility:add";
  @api searchIconName = "utility:search";
  @api sObjectApiName = "Opportunity";
  @api defaultRecordId = "";
  @api fieldsToInclude = "";
  @api hasCustomNameField = false;
  @api customNameField = "";
  @api fieldsToSet = "";
  @api isDisabled = false;
  @api doNotShowCancel = false;
  @api doNotShowHelpText = false;
  @api doNotShowAccScreen = false;
  @api classesToAdd;
  @api labelClassesToAdd;
  @api multiSelect = false;
  @track selectedRecords = [];
  @api selectedRecordsIds = [];
  @track isModalOpen = false;
  @track showAllResults = false;
  @api recordId = "";
  @api whereClause = "";
  @api searchAccountMobile = false;

  @track showAllResultsButton = false;
  @track customerInfoPlaceHolder = LABELS.HELP_TEXT_CONTENT; //FRONT-8351

  // private properties
  lstResult = []; // to store list of returned records
  hasRecords = true;
  searchKey = ""; // to store input field value
  isSearchLoading = false; // to control loading spinner
  delayTimeout;
  selectedRecord = {}; // to store selected lookup record in object formate
  isMobile = false;
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
    // this.fieldsToInclude += 'Phone,E_mail_Address__c';
  }

  //FRONT-8351
  loadStyleSheet() {
    loadStyle(this, FrontLineCSS);
  }

  setDefaultSelection() {
    fetchDefaultRecord({
      recordId: this.defaultRecordId,
      sObjectApiName: this.sObjectApiName,
      hasCustomNameField: this.hasCustomNameField
    })
      .then((result) => {
        if (result != null) {
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
    hasCustomNameField: "$hasCustomNameField"
  })
  searchResult(value) {
    const { data, error } = value; // destructure the provisioned value
    this.isSearchLoading = false;
    if (data) {
      console.log("DATA", data);
      this.hasRecords = data.length == 0 ? false : true;
      this.lstResult = JSON.parse(JSON.stringify(data));
      for (var i = 0; i < this.lstResult.length; i++) {
        let o = this.lstResult[i];

        if (this.hasCustomNameField) {
          o.DisplayName = o[this.customNameField];
        } else {
          o.DisplayName = o["Name"];
        }
      }
    } else if (error) {
      console.log("(error---> " + JSON.stringify(error));
    }
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

    if (searchKey.length && this.showFrontlineComponents) {
      this.showAllResultsButton = true;
    } else {
      this.showAllResultsButton = false;
    }
  }

  // method to toggle lookup result section on UI
  toggleResult(event) {
    const lookupInputContainer = this.template.querySelector(
      ".lookupInputContainer"
    );
    const clsList = lookupInputContainer.classList;
    const whichEvent = event.target.getAttribute("data-source");

    if (this.isMobile) {
      //this.searchAccountMobile = true;
      this.searchAccountMobile = this.doNotShowAccScreen ? false : true;
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

  openAccountSearch() {
    this.searchAccountMobile = true;
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
  }

  // method to update selected record from search result
  handleSelectedRecord(event) {
    var objId = event.target.getAttribute("data-recid"); // get selected record Id
    this.recordId = objId;
    //this.lstResult.push(event);
    this.selectedRecord = this.lstResult.find((data) => data.Id === objId); // find selected record from list
    this.handleSelectRecordHelper();
    if (this.multiSelect) {
      this.lookupUpdatehandler(this.selectedRecords);
    } else {
      this.lookupUpdatehandler(this.selectedRecord);
    } // helper function to show/hide lookup result container on UI
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

  removeRecord(event) {
    console.log(event.detail);
    let selectRecId = [];
    this.selectedRecordsIds = [];
    for (let i = 0; i < this.selectedRecords.length; i++) {
      if (event.detail.name !== this.selectedRecords[i].Id) {
        selectRecId.push(this.selectedRecords[i]);
        this.selectedRecordsIds.push(this.selectedRecords[i].Id);
      }
    }
    this.selectedRecords = [...selectRecId];
    const oEvent = new CustomEvent("lookupupdate", {
      detail: this.selectedRecordsIds.join(", ")
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

  createNewAccount(event) {
    this.isModalOpen = true;

    //FRONT-12375: manually setting the focus to the new account modal as part of accessibility issue fix
    setTimeout(() => {
      const customModal = this.template.querySelector(
        "c-sbr_3_0_custom-modal-cmp"
      );
      if (customModal) {
        customModal.setFocus();
      }
    }, 500);
  }

  closeModal() {
    this.searchAccountMobile = false;
    this.isModalOpen = false;
    //FRONT-12375: manually setting the focus to the searchInputField   
    const inputField = this.template.querySelector(
      '[data-source="searchInputField"]'
    );
    if (inputField) {      
      inputField.focus();
    }    
    //End FRONT-12375
  }
  submitDetails() {
    this.isModalOpen = false;
  }

  showResults(event) {
    this.showAllResults = true;
    //FRONT-11490: manually setting the focus to the account list modal as part of accessibility issue fix
    setTimeout(() => {
      const listViewCmp = this.template.querySelector(
        "c-sbr_3_0_custom-account-list-view-cmp"
      );
      if (listViewCmp) {
        listViewCmp.setFocus();
      }
    }, 500);
  }

  @track accountSelected;

  hideResults(event) {
    if (event.detail) {
      if (JSON.parse(JSON.stringify(event.detail.acc))) {
        this.accountSelected = JSON.parse(JSON.stringify(event.detail.acc));
        let account = JSON.parse(JSON.stringify(event.detail.acc));
        this.handleSelectedRecordFromModal(account);
      }
    }

    this.showAllResults = false;
    //Added for FRONT-12375 on 06/11/2024
    this.setManualFocusOnTriggeringElement();
  }
  resultFromMobileCmp(event) {
    if (event.detail) {
      let account = JSON.parse(JSON.stringify(event.detail.selectedRecord));
      this.handleSelectedRecordFromModal(account);
    }
    this.showAllResultsFlag = false;
  }

  closeAccountSearchMobile() {
    this.searchAccountMobile = false;
  }
  closeAccountSearchOpenCustomModal() {
    this.searchAccountMobile = false;
    this.isModalOpen = true;
  }
  showAccountCreationModal(event) {
    this.showAllResults = false;
    this.isModalOpen = true;
  }

  //FRONT-11414
  handleKeyUp(event) {
    let actionType = event.target.dataset.actiontype;
    if (event.keyCode === 13) {
      if (actionType === "showAllResults") {
        this.showResults(event);
      } else if (actionType === "newAccount") {
        this.createNewAccount(event);
      } else if (actionType === "handleRecordSelection") {
        this.handleSelectedRecord(event);
      } else if (actionType === "searchCustomer") {
        this.toggleResult(event);
      }
    }
  }

  //FRONT-12375: manually setting the focus to the searchInputField 
  setManualFocusOnTriggeringElement(){
    const inputField = this.template.querySelector(
      '[data-source="searchInputField"]'
    );
    if (inputField) {      
      inputField.focus();
    }        
  }
  //End FRONT-12375

  //FRONT-29481
  get computedClasses(){
    return `slds-combobox__form-element slds-input-has-icon slds-input-has-icon_left-right ${this.classesToAdd}`
  }

  get computedLabelClasses(){
    return `slds-form-element__label label-padding ${this.labelClassesToAdd}`;
  }
}