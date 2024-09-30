import { LightningElement, api, track, wire } from "lwc";
import { getPicklistValues, getObjectInfo } from "lightning/uiObjectInfoApi";
import ACCOUNT_OBJECT from "@salesforce/schema/Account";
import LOCATION_OBJECT from '@salesforce/schema/Location';
import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import Address from "@salesforce/schema/Lead.Address";
import { isEmpty } from "c/sbr_3_0_frontlineUtils";
import getVendorName from '@salesforce/apex/SBR_3_0_ChangeVendorController.getVendorName';
const BASE_CLASSES ="slds-dropdown slds-dropdown_fluid filter-options inner-dropdown-element";
const FLOW_IDENTIFIER = "/flow/";
import FORM_FACTOR from "@salesforce/client/formFactor";
import STATE_CODES from '@salesforce/schema/Location.State__c';
import VENDOR_STATUS from '@salesforce/schema/Account.Vendor_Status__c';

const accFields = ['Name', 'Vendor_Account_Number__c', 'ToLabel(Vendor_Status__c)', 'BillingStreet', 'BillingState', 'BillingPostalCode', 'Id'];
const SMALL_FORM_FACTOR = "Small";

export default class Sbr_3_0_changevendorfilter extends LightningElement {
  //functional properties
  disabled = false;
  picklistOpenDropdown = false;
  openDropDown = false;
  closeDropdown = true;
  options;
  delaytimeout;
  accName = '';
  accType = '';
  accNumber = '';
  accStreet = '';
  accState = '';
  accZip = '';
  isInitialClick=true;
  recordType='RecordType.Name =\'Vendor\'';
  filters = [];
  searchResults;
  selectedSearchResult;
  picklistOrdered = [];
  showSearchResults = false;
  companyCode;
  locationRecordTypeId;
  accountRecordTypeId;
  stateCodes = [];
  defaultVendorStatuses = [];
  vendorStatuses = [];
  accStatusValue = '';
  accStatusLabel = '';
  accStatuses = [];
  mobileFilterOpen = false;
  
  connectedCallback() {
    this.computeFilterCSS();
  }
  get isMobileView() {
    return FORM_FACTOR === SMALL_FORM_FACTOR;
  }

  @wire(getObjectInfo, { objectApiName: LOCATION_OBJECT })
  locResults({ error, data }) {
    if (data) {
      this.locationRecordTypeId = data.defaultRecordTypeId;
      this.error = undefined;
    } else if (error) {
      this.error = error;
      this.locationRecordTypeId = undefined;
    }
  }
  @wire(getObjectInfo, { objectApiName: ACCOUNT_OBJECT })
  accResults({ error, data }) {
    if (data) {
      this.accountRecordTypeId = data.defaultRecordTypeId;
      this.error = undefined;
    } else if (error) {
      this.error = error;
      this.accountRecordTypeId = undefined;
    }
  }

  @wire(getPicklistValues, { recordTypeId: '$locationRecordTypeId', fieldApiName: STATE_CODES })
  stateCodeValues({ error, data }) {
    if (data) {
      this.stateCodes = [...data.values].sort((a, b) => (a.label > b.label) ? 1 : -1);
    } else if (error) {
      this.error = error;
      this.stateCodes = undefined;
    }
  }

  @wire(getPicklistValues, { recordTypeId: '$accountRecordTypeId', fieldApiName: VENDOR_STATUS })
  vendorStatusValues({ error, data }) {
    if (data) {
      this.defaultVendorStatuses = data.values;
      this.vendorStatuses = [...data.values].map(item => {
        return {
          ...item,
          label: (item.label === 'Hold Payment and Purchasing' || item.label === 'Hold for Purchasing (Orders)') ? 'On-Hold' : item.label
        };
      }).sort((a, b) => (a.label > b.label) ? 1 : -1);
      const key = 'label';
      const uniqStatuses = [
        ...this.vendorStatuses
          .reduce((uniq, curr) => {
            if (!uniq.has(curr[key])) {
              uniq.set(curr[key], curr);
            }
            return uniq;
          }, new Map())
          .values()
      ];
      this.vendorStatuses = uniqStatuses;
    } else if (error) {
      this.error = error;
      this.vendorStatuses = undefined;
    }
  }
  
  get computedDropDownClasses() {
    if (this.openDropDown || this.mobileFilterOpen) {
      return `${BASE_CLASSES} is-filter-open`;
    } else {
      return BASE_CLASSES;
    }
  }
  //Method to handle readonly input click
  handleInputClick(event) {
    if (this.isMobileView) {
      this.mobileFilterOpen = !this.mobileFilterOpen;
    }
    else {
      this.toggleOpenDropDown();
      this.adjustHeight();
    }
  }
  //Method to toggle openDropDown
  toggleOpenDropDown() {
    this.openDropDown = !this.openDropDown;
  }
  //getter setter for labelClass
  get labelClass() {
    return this.fieldLabel && this.fieldLabel !== ""
      ? "slds-form-element__label slds-show"
      : "slds-form-element__label slds-hide";
  }
  handleFilterChange(event) {
    if (event.target.label === "Vendor Name") {
      this.accName = event.target.value;
    }
    else if (event.target.label === "Vendor Number") {
      this.accNumber = event.target.value;
    }
    else if (event.target.label === "Vendor Status") {
      this.accStatuses = [];
      this.accStatusValue = event.detail.value;
      this.accStatusLabel = event.target.options.find(opt => opt.value === event.detail.value).label;
      if (this.accStatusLabel == 'On-Hold') {
        this.defaultVendorStatuses.forEach(x => { if (x.label.includes("Hold Payment and Purchasing") || x.label.includes("Hold for Purchasing (Orders)")) this.accStatuses.push(`'${x.value}'`) });
      }
      else {
        this.defaultVendorStatuses.forEach(x => { if (x.label.includes(this.accStatusLabel)) this.accStatuses.push(`'${x.value}'`) });
      }
    }
    else if (event.target.label === "Billing Street") {
      this.accStreet = event.target.value;
    }
    else if (event.target.label === "Billing State/Province") {
      this.accState = event.target.value;
    }
    else if (event.target.label === "Zip/Postal Code") {
      this.accZip = event.target.value;
    }
    console.log("Field:" + event.target.value);
  }

  handleApply(event) { 
        this.data = [];
        //this.template.querySelector('[data-field-class="filterOption"]').value = '';
        let whereClause = (this.recordType + (this.accName != '' ? ' and Name Like \'%' + this.accName + '%\'' : '')
          + (this.accNumber != '' ? ' and Vendor_Account_Number__c Like \'%' + this.accNumber + '%\'' : '')
          + (this.accStatuses.length > 0 ? ' and Vendor_Status__c IN (' + this.accStatuses + ')' : '')
          + (this.accStreet != '' ? ' and BillingStreet Like \'%' + this.accStreet + '%\'' : '') 
          + (this.accState != '' ? ' and BillingState Like \'%' + this.accState + '%\'' : '') 
          + (this.accZip != '' ? ' and BillingPostalCode Like \'%' + this.accZip + '%\'' : '')
        );
        console.log(whereClause);
        
    getVendorName({ recordId: this.recordId, objectName: 'Account', fieldName: accFields, filterBy: whereClause })
            .then(result => {this.partialResult=result;
                console.log('this.partialResult',this.partialResult);
                    this.data = this.partialResult;
                    console.log(this.data);
                const searchEvent = new CustomEvent("getsearchvalue",{detail: this.data});
                // Dispatches the event.
                this.dispatchEvent(searchEvent);
            })
            .catch(error => {
                console.log('no Data');
            });
    if (this.isMobileView) {
        this.mobileFilterOpen = false;
      }
      else {
        this.openDropDown = false;
      }
    }
    
    handleReset(event) {
      this.accName='';
      this.accNumber='';
      this.accStatusLabel = '';
      this.accStatusValue = '';
      this.accStatuses = [];
      this.accStreet='';
      this.accState='';
      this.accZip='';
      this.handleApply(event);
    }   

    handleCancel() {
      this.mobileFilterOpen = false;
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

  @api closeFilterDropDown() {
    if(this.isMobileView){
      this.mobileFilterOpen = false;
    }
    else{      
    this.openDropDown = false;
    }
  }

  handleFilterCancel() {
    this.mobileFilterOpen = false;
  }

  openFilters() {
    this.mobileFilterOpen = !this.mobileFilterOpen;
  }

  @api adjustHeight() {
    const dropdown = this.template.querySelector(".inner-dropdown-element");
    const viewPortHeight = window.innerHeight;
    //FRONT-7753 Updated the if condition to set the height accordingly
    if((viewPortHeight - dropdown.getBoundingClientRect().top) < dropdown.scrollHeight){
      const comboboxFinalHeight = viewPortHeight - dropdown.getBoundingClientRect().top;
      dropdown.style.height = comboboxFinalHeight + "px";
    } else {
      dropdown.style.height = "auto";
    }
  }
}