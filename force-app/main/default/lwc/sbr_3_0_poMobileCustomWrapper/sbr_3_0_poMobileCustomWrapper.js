import { LightningElement, api } from 'lwc';
import noContentSvg from "@salesforce/resourceUrl/NoContentSVG";
import MODAL_TEMPLATE from './templates/modal.html';
import DIV_TEMPLATE from './templates/div.html';
import MAIN_TEMPLATE from './sbr_3_0_poMobileCustomWrapper.html';


export default class Sbr_3_0_poMobileCustomWrapper extends LightningElement {

    @api title;
    @api recordList = [];

    @api isModal = false;
    @api isDiv = false;

    @api hasTitle = false;
    @api hasSearch = false;
    @api hasCheckbox = false;
    @api isCheckboxChecked = false;
    @api searchObj = {};
    
    @api isVendorFilter = false;
    @api isPurchaseOrderFilter = false;
    @api noHeaderSection = false;

    @api
    set checkAll(value) {
        this.template.querySelector('c-sbr_3_0_po-mobile-custom-data-table').checkAll = value;
    }
    get checkAll() {
        return this.template.querySelector('c-sbr_3_0_po-mobile-custom-data-table').checkAll;
    }
    
    noContentimageUrl = noContentSvg;
    hasRecords = true;
    totalNoOfRecords = 0;
    hasFilter = false;
    openEditScreen = false;

    // render(){
    //     return (this.isModal === true) ? DIV_TEMPLATE : DIV_TEMPLATE;
    // }

    @api refreshRecords(records){
        this.recordList = records;
        if(this.recordList?.length) {
            this.totalNoOfRecords = this.recordList.length;
            this.hasRecords = true;
        }
        else{
            this.totalNoOfRecords = 0;
            this.hasRecords = false;
        }
        this.template.querySelector('c-sbr_3_0_po-mobile-custom-data-table').refreshRecords(this.recordList);
    }

    connectedCallback(){
        this.hasFilter = (this.isVendorFilter || this.isPurchaseOrderFilter) ? true : false;
        this.hasTitle = (this.title) ? true : false;
        this.isSearchOrFilter = (this.hasSearch || this.hasFilter) ? true : false;
        if(this.recordList.length) {
            this.totalNoOfRecords = this.recordList.length;
            this.hasRecords = true;
        }
        else{
            this.totalNoOfRecords = 0;
            this.hasRecords = false;
        }
    }

    renderedCallback(){
        const searchCss = (this.hasFilter) ? 'searchfill' : 'searchfillonly';
        this.setFocusOnFirstElement();
        //this.template.querySelector("div[data-id='searchDiv']").classList.add(searchCss);
    }

    handleSearch(event){
        if (event.keyCode === 13) {
            this.dispatchEvent(new CustomEvent('search', {
                detail : { 
                    value : event.target.value
                }
            }));
        }
    }

    handleClear(event) {
        if (!event.target.value.length) {
            this.dispatchEvent(new CustomEvent('clear'));
        }
    }

    handleEdit(event){
        this.dispatchEvent(new CustomEvent('edit',{
            detail: {
                recordId: event.detail.recordId
            }
        }));
    }
    
    handleRecordSelect(event){
        this.dispatchEvent(new CustomEvent('select', {
            detail: {
                record: event.detail.record
            }
        }));
    }

    handleMenuClick(event) {
        this.dispatchEvent(new CustomEvent(event.detail.eventName, {
            detail: {
                id: event.detail.id
            }
        }));
    }
    handleCheckboxChange(event) {
        this.dispatchEvent(new CustomEvent('checkboxchange', {
            detail: {
                id: event.detail.id,
                checked: event.detail.checked
            }
        }));
    }
    getSearchValue(event) {
        this.dispatchEvent(new CustomEvent('filter', {
            detail: event.detail
        }));
    }

    handleReset(event){
        this.dispatchEvent(new CustomEvent('reset'));
    }

    handleCloseModal(event){
        this.dispatchEvent(new CustomEvent('closemodal'));
    }

    setFocusOnFirstElement() {
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        window.setTimeout(() => {
            if (!this._rendered) {
                let ele = this.template.querySelector('[data-name="searchBox"]');
                if (ele && ele.focus) {
                    ele.focus();
                    this._rendered = true;
                }
            }
        }, 5);
    }
}