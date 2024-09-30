import { api, wire, LightningElement } from 'lwc';
import { FlowAttributeChangeEvent } from 'lightning/flowSupport';
 

import getLookupValues from '@salesforce/apex/CustomLookupCmpController.getLookupValues';

import getinitRecord from '@salesforce/apex/CustomLookupCmpController.getinitRecord';

import gerRecentlyCreatedRecords from '@salesforce/apex/CustomLookupCmpController.gerRecentlyCreatedRecords';

 

export default class CustomLookupCmp extends LightningElement {

 

    //public properties

    @api uniqueName = 'Account';

    @api initialLookupValue = '';

    @api objectAPIName = 'Location';

    @api displayLabelField = '';

    @api fieldToSearchWith = 'Name';

    @api iconName = 'standard:account';

    @api labelForComponent = 'Profile Branch'

    @api placeHolder = 'Search New Profile Branch ...'

    @api recordLimit = 50;

    @api labelHidden = false;

    searchKeyWord = '';

    @api selectedRecord = {}; // Use, for store SELECTED sObject Record

    @api where = '';

    @api newProfileBranch;

 

 

    // private properties

 

    selectedRecordLabel = '';

    searchRecordList = []; // Use,for store the list of search records which returns from apex class

    message = '';

    spinnerShow = false;

    error = '';

    noRecordFound = false;

 

 

    @wire(getLookupValues, { searchKeyWord: '$searchKeyWord', objectAPIName: '$objectAPIName', whereCondition: '$where', fieldNames: '$fieldToSearchWith', displayFields: '$displayLabelField', customLimit: '$recordLimit' })
    wiredsearchRecordList({ error, data }) {
        this.spinnerShow = true;
        if (data) {
            this.spinnerShow = false;

            this.searchRecordList = JSON.parse(JSON.stringify(data));
            console.log("list of locations ", this.searchRecordList)
            this.error = undefined;

            this.hasRecord();
        } else if (error) {
            console.log('getLookupValues Error 2 —> ' + JSON.stringify(error));

            this.hasRecord();

            this.error = error;

            this.searchRecordList = undefined;
        }

    }

 

    connectedCallback() {
        console.log('initial value = ', this.initialLookupValue);
        if (this.initialLookupValue != '') {
            this.newProfileBranch = this.initialLookupValue;
            this.dispatchEvent(new FlowAttributeChangeEvent('newProfileBranch', this.newProfileBranch));
            
            getinitRecord({ recordId: this.initialLookupValue, 'objectAPIName': this.objectAPIName, 'fieldNames': this.displayLabelField })

                .then((data) => {

                    if (data != null) {

                        this.selectedRecord = data;

                        this.selectedRecordLabel = data.Name; //data[this.displayLabelField];

                        this.selectionRecordHelper();

                    }

                })

                .catch((error) => {

                    console.log('getinitRecord Error —> ' + JSON.stringify(error));

                    this.error = error;

                    this.selectedRecord = {};

                });

        }

    }

 

    handleClickOnInputBox(event) {

        let container = this.template.querySelector('.custom-lookup-container');

        container.classList.add('slds-is-open');

        if (typeof this.searchKeyWord === 'string' && this.searchKeyWord.trim().length === 0) {
            this.spinnerShow = true;
            gerRecentlyCreatedRecords({ 'objectAPIName': this.objectAPIName, 'fieldNames': this.displayLabelField, 'whereCondition': this.where, 'customLimit': this.recordLimit })

                .then((data) => {

                    if (data != null) {

                        try {

                            console.log('gerRecentlyCreatedRecords —> ', JSON.stringify(data));

                            this.spinnerShow = false;

                            this.searchRecordList = JSON.parse(JSON.stringify(data));

                            this.hasRecord();

                        } catch (error) {

                            console.log(error);

                            this.hasRecord();

                        }

                    }

                })

                .catch((error) => {

                    console.log('gerRecentlyCreatedRecords Error —> ' + JSON.stringify(error));

                    this.error = error;

                });

        } 

    }

    @api
    fireLookupUpdateEvent(value) {
        const oEvent = new CustomEvent('selectvalue', { detail: value })
        this.dispatchEvent(oEvent);
    }

 

    handleKeyChange(event) {

        this.searchKeyWord = event.detail.value;

        console.log(this.searchKeyWord);

        if (typeof this.searchKeyWord === 'string' && this.searchKeyWord.trim().length > 0) {

            this.searchRecordList = [];

        }

    }

 

    /*
    handleOnblur(event) {

        let container = this.template.querySelector('.custom-lookup-container');

        container.classList.remove('slds-is-open');

        this.spinnerShow = false;

        this.searchRecordList = [];

    }

    */

    handleSelectionRecord(event) {

        var recid = event.target.getAttribute('data-recid');
        this.newProfileBranch = recid;

        this.dispatchEvent(new FlowAttributeChangeEvent('newProfileBranch', this.newProfileBranch));
 
        let container = this.template.querySelector('.custom-lookup-container');

        container.classList.remove('slds-is-open');

        this.selectedRecord = this.searchRecordList.find(data => data.Id === recid);

        this.selectedRecordLabel = this.selectedRecord.Name;//this.selectedRecord[this.displayLabelField];

        console.log('selected : ', this.selectedRecord);

        this.fireLookupUpdateEvent(this.selectedRecord);

        this.selectionRecordHelper();

    }

 

    selectionRecordHelper() {

        let custom_lookup_pill_container = this.template.querySelector('.custom-lookup-pill');

        custom_lookup_pill_container.classList.remove('slds-hide');

        custom_lookup_pill_container.classList.add('slds-show');

        let search_input_container_container = this.template.querySelector('.search-input-container');

        search_input_container_container.classList.remove('slds-show');

        search_input_container_container.classList.add('slds-hide');

    }

 

    clearSelection() {
        this.recordId = '';
        console.log('sourcing branch = ', this.recordId);

        let custom_lookup_pill_container = this.template.querySelector('.custom-lookup-pill');

        custom_lookup_pill_container.classList.remove('slds-show');

        custom_lookup_pill_container.classList.add('slds-hide');

        let search_input_container_container = this.template.querySelector('.search-input-container');

        search_input_container_container.classList.remove('slds-hide');

        search_input_container_container.classList.add('slds-show');

        this.fireLookupUpdateEvent(undefined);

        this.clearSelectionHelper();

    }

 

    clearSelectionHelper() {

        this.selectedRecord = {};

        this.selectedRecordLabel = '';

        this.searchKeyWord = '';

        this.searchRecordList = [];

    }

 

    hasRecord() {

        if (this.searchRecordList && this.searchRecordList.length > 0) {

            this.noRecordFound = false;

        } else {

            this.noRecordFound = true;

        }

    }

}