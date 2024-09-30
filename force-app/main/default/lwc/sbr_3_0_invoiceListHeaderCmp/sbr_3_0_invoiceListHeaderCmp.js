import { LightningElement, api, track, wire } from 'lwc';
//import getOrderStatuses from '@salesforce/apex/SBR_3_0_InvoiceDA.getInvoiceOrderStatusOptions';
import { getPicklistValues, getObjectInfo } from 'lightning/uiObjectInfoApi';
import INVOICE_OBJECT from '@salesforce/schema/Invoice__c';
import INVOICE_STATUS_FIELD from "@salesforce/schema/Invoice__c.Order_Status__c";

export default class Sbr_3_0_invoiceListHeaderCmp extends LightningElement {
    isFilterActive = false;
    statusOptions = [];
    @track allStatusOptions = [];
    newOptions = [];
    newAgeOptions = [];
    selectedStatus = 'All';
    isMobile = false;

    @track fromDate;
    @track toDate;

    showFilters = false;
    filterOptions = [];
    @track selectedFilterOptions = [];
    @track selectedAgeFilterOptions = [];
    appliedFilters = [];
    appliedFiltersDisplay = "All Statuses";
    showListView = true;

    cancelBtnClass = 'slds-button slds-button_neutral selected-btn';
    resetBtnClass = 'slds-button reset-btn-class';
    resetTxtClass = 'slds-button slds-p-right_small reset-txt-class';
    applyBtnClass = 'slds-button slds-button_neutral apply-btn-class';
    
    selectedAge = '0';

    @track ageOptions = [
        {label: 'All Invoices', value: '0', isSelected: true},
        {label: 'Over 30', value: '30', isSelected: false},
        {label: 'Over 60', value: '60', isSelected: false},
        {label: 'Over 90', value: '90', isSelected: false},
        {label: 'Over 120', value: '120', isSelected: false}
    ];

    @wire( getObjectInfo, { objectApiName: INVOICE_OBJECT } )
    objectInfo;

    @wire( getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: INVOICE_STATUS_FIELD } )
    wiredStatusMethod( { error, data } ) {
        if ( data ) {     
           let newData = data.values.filter( val => val.label != 'None');
                this.statusOptions.push({
                    label: 'All Statuses',
                    value: 'All',
                    isSelected: true
                });
                newData.forEach((status) => {
                    this.statusOptions.push({
                        label: status.label,
                        value: status.label,
                        isSelected: false
                    });
                });
          
           this.allStatusOptions = new Array(...this.statusOptions);  
        } else if ( error ) {
            console.error( JSON.stringify( error ) );
        }
    }


    connectedCallback(){
        this.isMobile = window.matchMedia('(max-width: 480px)').matches;
    }

    toggleFilter() {
        this.showFilters = !this.showFilters;
    }

    handleCheckboxUpdate(event) {
        let index = event.target.dataset.elementid;
        let optionValue = this.allStatusOptions[index].value;
        this.newOptions =[];
        this.allStatusOptions.forEach( (element) => {
            if(element.value!= optionValue ){
                this.newOptions.push({
                    label: element.label,
                    value: element.value,
                    isSelected: false
                });
            }else{
                this.newOptions.push({
                    label: element.label,
                    value: element.value,
                    isSelected: true
                });
            }
            
        });
        
        this.allStatusOptions = new Array(...this.newOptions);  
        

        let selectedIndex = this.selectedFilterOptions.indexOf(optionValue);
        if (selectedIndex > -1) {
            this.selectedFilterOptions.splice(selectedIndex, 1);
        } else {
            this.selectedFilterOptions=[];
            this.selectedFilterOptions.push(optionValue);
        }
    }

    handleAgeCheckboxUpdate(event) {
        let index = event.target.dataset.elementid;
        let optionValue = this.ageOptions[index].value;
        this.newAgeOptions =[];
        this.ageOptions.forEach( (element) => {
            if(element.value!= optionValue ){
                this.newAgeOptions.push({
                    label: element.label,
                    value: element.value,
                    isSelected: false
                });
            }else{
                this.newAgeOptions.push({
                    label: element.label,
                    value: element.value,
                    isSelected: true
                });
            }
            
        });
        
        this.ageOptions = new Array(...this.newAgeOptions);  
        
        let selectedIndex = this.selectedAgeFilterOptions.indexOf(optionValue);
        if (selectedIndex > -1) {
            this.selectedAgeFilterOptions.splice(selectedIndex, 1);
        } else {
            this.selectedAgeFilterOptions=[];
            this.selectedAgeFilterOptions.push(optionValue);
        }
        
    }

    toggleSection(event) {
        let buttonid = event.currentTarget.dataset.buttonid;
        let currentsection = this.template.querySelector('[data-id="' + buttonid + '"]');
        if (currentsection.className.search('slds-is-open') == -1) {
            currentsection.className = 'light-grey slds-section slds-is-open';
        } else {
            currentsection.className = 'light-grey slds-section slds-is-close';
        }
    }

    applyFilter() {
        let newFilterDisplay = "";
        this.appliedFilters = JSON.parse(JSON.stringify(this.selectedFilterOptions));
        if (this.appliedFilters.length > 0) {
            this.selectedStatus= this.appliedFilters[0];
        } else {
            newFilterDisplay = "All";
        }

        this.appliedAgeFilters = JSON.parse(JSON.stringify(this.selectedAgeFilterOptions));
        if (this.appliedAgeFilters.length > 0) {
            this.selectedAge= this.appliedAgeFilters[0];
        } else {
            newFilterDisplay = "0";
        }

        //this.appliedFiltersDisplay = newFilterDisplay;
        this.closeFilterPanel();

        const filterUpdate = new CustomEvent('filterupdate', {
            'detail': {filters: this.appliedFilters}
        });
        this.dispatchEvent(filterUpdate);
        this.sendFilterUpdate();


    }

    resetFilterPanel() {
        this.selectedFilterOptions = [];
        // this.appliedFiltersDisplay = "All Statuses";

        this.template.querySelectorAll('lightning-input')
            .forEach((element) => {
                element.checked = false;
            });

        this.allStatusOptions.forEach( (element) => {
            element.isSelected=false;
            if(element.value== 'All' ){
                element.isSelected=true;
            }                
        });
        this.ageOptions.forEach( (element) => {
            element.isSelected=false;
            if(element.value== '0' ){
                element.isSelected=true;
            }                
        });
        this.selectedStatus = 'All';
        this.selectedAge = '0';
        this.sendFilterUpdate();

    }


    openFilterPanel() {
        this.showFilters = true;
        const showFilterEvt = new CustomEvent('togglefilters', {
            'detail': {filtersOpen: this.showFilters}
        });
        this.dispatchEvent(showFilterEvt);
    }

    closeFilterPanel() {
        this.showFilters = false;

        const showFilterEvt = new CustomEvent('togglefilters', {
            'detail': {filtersOpen: this.showFilters}
        });
        this.dispatchEvent(showFilterEvt);
    }
    
    handleFromDateChange(event) {
        this.fromDate = event.detail.value;
        this.sendFilterUpdate();
    }
    
    handleToDateChange(event) {
        this.toDate = event.detail.value;
        this.sendFilterUpdate();
    }
    
    handleStatusChange(event) {
        this.selectedStatus = event.detail.value;
        this.sendFilterUpdate();
    }
    
    handleAgeChange(event) {
        this.selectedAge = event.detail.value;
        this.sendFilterUpdate();
    }
    
    sendFilterUpdate() {
        const statusChangeEvent = new CustomEvent('filterupdate', {
            'detail': {
                selectedStatus: this.selectedStatus,
                selectedFromDate: this.fromDate,
                selectedToDate: this.toDate,
                selectedAge: this.selectedAge
            }
        });
        this.dispatchEvent(statusChangeEvent);
    }

    get headerDisplay() {
        return this.showFilters? "hide" : "show";
    }

    get filterDisplay() {
        return this.showFilters ? "show" : "hide";
    }

}