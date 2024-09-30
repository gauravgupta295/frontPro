import { LightningElement, api, track, wire } from "lwc";
import getContract from '@salesforce/apex/sbr_3_0_PurchaseOrderTransferSearch.getTransferForFilter';
import getTransfers from '@salesforce/apex/sbr_3_0_PurchaseOrderTransferSearch.getTransfersForFilter';
const BASE_CLASSES = "slds-dropdown slds-dropdown_fluid filter-options inner-dropdown-element";
const FLOW_IDENTIFIER = "/flow/";
import FORM_FACTOR from "@salesforce/client/formFactor";
import ORDER_OBJECT from "@salesforce/schema/Internal_Order__c";
import { getPicklistValues, getObjectInfo } from "lightning/uiObjectInfoApi";
import ORDER_STATUS from '@salesforce/schema/Internal_Order__c.Status__c';;
const transferFields = ['RM_Transfer_Number__c', 'Receiving_Branch_Name__c', 'Sending_Branch_Name__c', 'Status__c', 'Transfer_Date__c', 'Ordered_By_Name__c'];
const transferFields2 = ['Transfer_Number__r.RM_Transfer_Number__c', 'Transfer_Number__r.Receiving_Branch_Name__c', 'Transfer_Number__r.Sending_Branch_Name__c', 'Transfer_Number__r.Status__c', 'Transfer_Number__r.Transfer_Date__c', 'Transfer_Number__r.Ordered_By_Name__c'];

export default class Sbr_3_0_TransferSearchFilter extends LightningElement {

//functional properties
  disabled = false;
  picklistOpenDropdown = false;
  openDropDown = false;
  closeDropdown = true;
  options;
  delaytimeout;
  transferNum = '';
  sLoc = '';
  dLoc = '';
  ordBy='';
  ordStatus = '';
  defaultOrderStatuses = [];
  orderStatuses = [];
  orderRecordTypeId;
  ordStatusValue = '';
  ordStatusLabel = '';
  ordStatuses = [];

  ordendDate = '';
  ordDate = '';
  equipNo=''
  isInitialClick = true;
  filters = [];
  searchResults;
  selectedSearchResult;
  picklistOrdered = [];
  showSearchResults = false;
  companyCode;
  locationRecordTypeId;
  stateCodes = [];
  connectedCallback() {
    this.computeFilterCSS();
  }
  /* To get picklist values of Contract Status --------------------------------------------------------------------------------*/
  @wire(getObjectInfo, { objectApiName: ORDER_OBJECT })
  ordResults({ error, data }) {
    if (data) {
      console.log('ORDER_OBJECT data >>  : ', JSON.stringify(data));
      this.orderRecordTypeId = data.defaultRecordTypeId;
      this.error = undefined;
    } else if (error) {
      this.error = error;
      // this.accountRecordTypeId = undefined;
    }
  }
  @wire(getPicklistValues, { recordTypeId: "$orderRecordTypeId",fieldApiName: ORDER_STATUS })
  orderStatusValues({ error, data }) {
     console.log('intooo  : orderStatusValues');
    if (data) {
      console.log('intoo if of orderStatusValues >>  : ');
      console.log('ORDER_STATUS data >>  : ', JSON.stringify(data));
      this.defaultOrderStatuses = data.values;
      console.log('defaultOrderStatuses  >>  : ', this.defaultOrderStatuses);
      this.orderStatuses = [...data.values].map(item => {
        return {
          ...item,
          // label: (item.label === 'Hold Payment and Purchasing' || item.label === 'Hold for Purchasing (Orders)') ? 'On-Hold' : item.label
        };
      }).sort((a, b) => (a.label > b.label) ? 1 : -1);
      console.log('this.orderStatuses >>  : ', this.orderStatuses);
      const key = 'label';
      const uniqStatuses = [
        ...this.orderStatuses
          .reduce((uniq, curr) => {
            if (!uniq.has(curr[key])) {
              uniq.set(curr[key], curr);
            }
            return uniq;
          }, new Map())
          .values()
      ];
      this.orderStatuses = uniqStatuses;
    } else if (error) {
      console.error('Error retrieving ORDER_STATUS data: ', error);
      this.error = error;
      this.orderStatuses = undefined;
    }
  }
  /* END of method To get picklist values of Contract Status --------------------------------------------------------------------------------*/

  get computedDropDownClasses() {
    if (this.openDropDown) {
      return `${BASE_CLASSES} is-filter-open`;
    } else {
      return BASE_CLASSES;
    }
  }
  //Method to handle readonly input click
  handleInputClick(event) {
    this.toggleOpenDropDown();
    this.adjustHeight();
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
    if (event.target.label === "Transfer Number") {
      this.transferNum = event.target.value;
    }
    else if (event.target.label === "Source Location") {
      this.sLoc = event.target.value;
    }
    else if (event.target.label === "Destination Location") {
      this.dLoc = event.target.value;
    }
    else if (event.target.label === "Ordered by") {
      this.ordBy = event.target.value;
    }
    /*
        else if (event.target.label === "Status") {
          this.ordStatus = event.target.value;
        }
    */
    else if (event.target.label === "Status") {
      this.ordStatuses = [];
      this.ordStatusValue = event.detail.value;
      console.log('this.ordStatusValue >> : ',this.ordStatusValue);

      this.ordStatusLabel = event.target.options.find(opt => opt.value === event.detail.value).label;
      console.log('this.ordStatusLabel >> : ',this.ordStatusLabel);

      this.defaultOrderStatuses.forEach(x => { if (x.label.includes(this.ordStatusLabel)) this.ordStatuses.push(`'${x.value}'`) });
      /*
      if (this.accStatusLabel == 'On-Hold') {
        this.defaultVendorStatuses.forEach(x => { if (x.label.includes("Hold Payment and Purchasing") || x.label.includes("Hold for Purchasing (Orders)")) this.accStatuses.push(`'${x.value}'`) });
      }
      else {
        this.defaultVendorStatuses.forEach(x => { if (x.label.includes(this.accStatusLabel)) this.accStatuses.push(`'${x.value}'`) });
      }
      */
    }

    else if (event.target.label === "Contract End Date") {
      this.ordendDate = event.target.value;
    }
    else if (event.target.label === "Needed") {
      this.ordDate = event.target.value;
    }
    else if (event.target.label === "Equipment#") {
      this.equipNo = event.target.value;
    }
    console.log("Field:" + event.target.value);
  }
  handleApply(event) {
    this.data = [];
    let isEqp=false;
    //this.template.querySelector('[data-field-class="filterOption"]').value = '';
    if(this.equipNo==''){
    let whereClause = ((this.transferNum != '' ? ' AND RM_Transfer_Number__c  Like \'%' + this.transferNum + '%\'' : '')
      + (this.sLoc != '' ? ' AND Sending_Branch_Name__c  Like \'%' + this.sLoc + '%\'' : '')
      + (this.dLoc != '' ? ' AND Receiving_Branch_Name__c Like \'%' + this.dLoc + '%\'' : '')
       + (this.ordBy != '' ? ' AND Ordered_By_Name__c Like \'%' + this.ordBy + '%\'' : '')
      + (this.ordStatuses.length > 0 ? ' and Status__c IN ('+this.ordStatuses+')' : '')
      + (this.ordDate != '' ? ' AND DAY_ONLY(Transfer_Date__c) = ' + this.ordDate : '')
    );
    console.log('recordId',this.recordId );
    console.log(whereClause);
    isEqp=false;
    getContract({ recordId: this.recordId, objectName: 'Internal_Order__c', fieldName: transferFields, filterBy: whereClause })
      .then(result => {
        this.partialResult = result;
        console.log('this.partialResult', this.partialResult);
        this.data = this.partialResult;
        console.log(this.data);
        const searchEvent = new CustomEvent("getsearchvalue", { detail: {data:this.data, isEqp:isEqp} });
        // Dispatches the event.
        this.dispatchEvent(searchEvent);
      })
      .catch(error => {
        console.log('no Data');
        console.log(error.message);
      });
    this.openDropDown = false;
    }
    else{
      console.log('Equipment', this.equipNo);
       let whereClause = ((this.equipNo != '' ? ' Asset_Number__r.SM_PS_Equipment_Number__c  Like \'%' + this.equipNo + '%\'' : '')
       +(this.transferNum != '' ? ' AND Transfer_Number__r.RM_Transfer_Number__c  Like \'%' + this.transferNum + '%\'' : '')
       + (this.sLoc != '' ? ' AND Transfer_Number__r.Sending_Branch_Name__c  Like \'%' + this.sLoc + '%\'' : '')
        + (this.dLoc != '' ? ' AND Transfer_Number__r.Receiving_Branch_Name__c Like \'%' + this.dLoc + '%\'' : '')
       + (this.ordBy != '' ? ' AND Transfer_Number__r.Ordered_By_Name__c Like \'%' + this.ordBy + '%\'' : '')
       + (this.ordDate != '' ? ' AND DAY_ONLY(Transfer_Number__r.Transfer_Date__c) = ' + this.ordDate : '') 
      + (this.ordStatuses.length > 0 ? ' and Transfer_Number__r.Status__c IN ('+this.ordStatuses+')' : '')
       );
       isEqp=true;
    console.log('recordId',this.recordId );
    console.log(whereClause);
    getTransfers({ recordId: this.recordId, objectName: 'Internal_Order_Line_Item__c', fieldName: transferFields2, filterBy: whereClause })
      .then(result => {
        this.partialResult = result;
        console.log('this.partialResult', this.partialResult);
        this.data = this.partialResult;
        console.log(this.data);
        const searchEvent = new CustomEvent("getsearchvalue", { detail: {data:this.data, isEqp:isEqp} });
        // Dispatches the event.
        this.dispatchEvent(searchEvent);
      })
      .catch(error => {
        console.log('no Data');
        console.log(error.message);
      });
    }
     this.openDropDown = false;
    
  }
  handleReset(event) {
    this.transferNum = '';
    this.sLoc = '';
    this.dLoc = '';
    this.ordBy='';
    this.ordStatuses = [];
    this.ordStatusLabel = '';
    this.ordStatusValue = '';
    this.ordendDate = '';
    this.ordDate = '';
    this.equipNo=''
    this.handleApply(event);
    //this.openDropDown = false;
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
    this.openDropDown = false;
  }
  @api adjustHeight() {
    const dropdown = this.template.querySelector(".inner-dropdown-element");
    const viewPortHeight = window.innerHeight;
    //FRONT-7753 Updated the if condition to set the height accordingly
    if ((viewPortHeight - dropdown.getBoundingClientRect().top) < dropdown.scrollHeight) {
      const comboboxFinalHeight = viewPortHeight - dropdown.getBoundingClientRect().top;
      dropdown.style.height = comboboxFinalHeight + "px";
    } else {
      dropdown.style.height = "auto";
    }
    //Set margin if mobile device
    if (FORM_FACTOR === 'Small') {
      dropdown.style.margin = "0px 0px 0px 50px";
    }
  }
}