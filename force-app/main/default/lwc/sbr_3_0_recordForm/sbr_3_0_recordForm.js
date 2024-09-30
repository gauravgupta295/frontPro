import { LightningElement, api, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import ACCOUNT_OBJECT from '@salesforce/schema/Account';
import getAppointment from '@salesforce/apex/SBR_3_0_GoogleMapCmpController.getAppointment';
import getTask from '@salesforce/apex/SBR_3_0_GoogleMapCmpController.getTask';
import getProject from '@salesforce/apex/SBR_3_0_GoogleMapCmpController.getProject';
import getOpportunity from '@salesforce/apex/SBR_3_0_GoogleMapCmpController.getOpportunity';
import getAccount from '@salesforce/apex/SBR_3_0_GoogleMapCmpController.getAccount';
import getLead from '@salesforce/apex/SBR_3_0_GoogleMapCmpController.getLead';
import updateTaskEvent from '@salesforce/apex/SBR_3_0_GoogleMapCmpController.updateTaskEvent';
import TIME_ZONE from '@salesforce/i18n/timeZone';

import { loadStyle } from 'lightning/platformResourceLoader';
import DISABLE_LINKS from '@salesforce/resourceUrl/sbr_3_0_disableLinks';
import { encodeDefaultFieldValues } from 'lightning/pageReferenceUtils';

export default class sbr_3_0_recordForm extends NavigationMixin(LightningElement) {
    forceRerender = true;
    @api
    set recordid(value) {
        this._recordId = value;        
        /*Temporary workaround as the lightning-record-form cmp was not 
        rerendering with the recordid change once it was in the DOM */
        this.forceRerender = false;
		this.getData();
        setTimeout(() => {
            this.forceRerender = true;
        }, 1000);

    }
    get recordid() {
        return this._recordId;
    }

    renderedCallback() {
        Promise.all([loadStyle(this, DISABLE_LINKS)]);
    }

    _obj;
    get obj() {
        return this._obj;
    }

    @api
    set obj(value) {
        this._obj = value;
        this.forceRerender = false;
		this.getData();
        setTimeout(() => {
            this.forceRerender = true;
        }, 1000);
    }

    @api icon;
    @api title;
    @api lat;
    @api lng;
    @api street = '';
    @api city = '';
    @api state = '';
    @api fullState = '';
    @api zip = '';
    @api country = '';

    @api view = false;
    @api create = false;
    @api showSelectionScreen = false;

    @api wrapper;
    _recordId;
    record;
    showSpinner = false;

    name = '';
    parentId = '';
    officeType = '';
    phone = '';
    otherPhone = '';
    email = '';
    fax = '';
    subject = '';
    assignedTo = '';
    allDayAppointment = '';
    start = '';
    end = '';
    description = '';
    reminderSet = false;
    reminderDT = '';
    dueDate = '';
    priority = '';
    comments = '';
    createRecur = false;
    hasWhat = '';
    hasWho = '';
    parentTypeLabel = '';
    status;
    preferences = '';
    primaryEquipment = '';
    rentalOpp = '';
    specialtyOpp = '';
    otherOpp = '';
    strategyLastUpdated = '';
    projectStatus = '';
    projectStage = '';
    primProjectType = '';
    secondProjectType = '';
    typeOfWork = '';
    projectOrigin = 'User Created';
    userTimeZone = TIME_ZONE;
    accountProspectRTId = '';
    accountOfficeRTId = '';

    contLeadToggle = false;
    relatedLead;
    relatedContact;

    showCompleteForm = false;
    outcomeText = '';
    followUp = false;
    error;
    whoId = '';
    whatId = '';
    countryAppointment = '';

    showLeadAssignment = false;
    leadId;

    @wire(getObjectInfo, { objectApiName: ACCOUNT_OBJECT })
    objectInfo({ error, data }) {
        if (data) {
            const recordTypes = data.recordTypeInfos;
            let prospectRT = Object.values(recordTypes).filter(element => element.name == 'Prospect');
            let officeRT = Object.values(recordTypes).filter(element => element.name == 'Office');
            this.accountProspectRTId = prospectRT[0].recordTypeId;
            this.accountOfficeRTId = officeRT[0].recordTypeId;
        }
    }

    connectedCallback() {

        if (this.create) {
            this.showSelectionScreen = true;
        }
        this.getData();
    }

    getData() {
        if (this.isEvent && this.view) {
            getAppointment({ id: this.recordid })
                .then(result => {

                    this.wrapper = result;
                    this.record = result.event;
                    this.subject = this.record.Subject;
                    this.assignedTo = result.assignedToName;
                    this.allDayAppointment = this.record.IsAllDayEvent;
                    this.start = this.record.StartDateTime;
                    this.end = this.record.EndDateTime;
                    this.street = this.record.Street__c;
                    this.city = this.record.City__c;
                    this.state = this.record.State__c;
                    this.zip = this.record.ZIP_Code__c;
                    this.lat = this.record.Latitude_Longitude__Latitude__s;
                    this.lng = this.record.Latitude_Longitude__Longitude__s;
                    this.reminderSet = this.record.IsReminderSet;
                    this.reminderDT = this.record.ReminderDateTime;
                    this.outcomeText = this.record.Outcome__c;
                    if (this.record.WhatId != null) {
                        this.hasWhat = true;
                        this.whatId = this.record.WhatId;
                        this.parentTypeLabel = this.wrapper.parentTypeLabel;
                    }
                    if (this.record.WhoId != null) {
                        this.hasWho = true;
                        this.whoId = this.record.WhoId;
                    }
                    this.countryAppointment = this.record.Country__c;
                    let maxSize = 30;
                    this.description = this.record.Description;
                    if (this.description.length > maxSize) {
                        this.description = this.description.substring(0, maxSize);
                    }

                })
                .catch(error => {
                    console.log('getAppointment error -> ', error);
                    this.error = error;
                });
        }

        if (this.isTask && this.view) {
            getTask({ id: this.recordid })
                .then(result => {

                    this.wrapper = result;
                    this.record = result.task;
                    this.subject = this.record.Subject;
                    this.assignedTo = result.assignedToName;
                    this.priority = this.record.Priority;
                    this.status = this.record.Status;
                    this.dueDate = this.record.ActivityDate;
                    this.outcomeText = this.record.Description;

                    this.reminderSet = this.record.IsReminderSet;
                    this.reminderDT = this.record.ReminderDateTime;
                    if (this.record.WhatId != null) {
                        this.hasWhat = true;
                        this.parentTypeLabel = this.wrapper.parentTypeLabel;
                    }
                    if (this.record.WhoId != null) {
                        this.hasWho = true;
                    }

                    let maxSize = 30;
                    this.comments = this.record.Description;
                    if (this.comments.length > maxSize) {
                        this.comments = this.comments.substring(0, maxSize);
                    }

                })
                .catch(error => {
                    console.log('getTask error -> ', error);
                    this.error = error;
                });
        }
    }

    
    @api
    handleSubmit(event) {

        //event.preventDefault(); // stop the form from submitting

        let validated = true;
        this.template.querySelectorAll('lightning-input-field').forEach(element => {
            element.reportValidity();
            if (!element.reportValidity()) {
                validated = false;
            }
        });

        if (validated) {
            //const submitEvent = new CustomEvent('submit');
            //this.dispatchEvent(submitEvent);
            if (this.obj == 'Lead') {
                this.template.querySelector('c-sbr_3_0_create-lead-record-cmp').pressSave();
                //this.handleSuccess();
            }
            else {
                this.showSpinner = true;
                this.template.querySelector('lightning-record-edit-form').submit();
            }
        }

    }

    setLeadRecordId(event) {
        this.recordId = event.detail.newRecordId;
        this.showSpinner = true;

        getLead({ id: this.recordId })
            .then(result => {
                this.showSpinner = false;

                this.title = result.summary;
                this.street = result.street;
                this.city = result.city;
                this.state = result.state;
                this.postal = result.postal;
                this.country = result.country;
                this.lat = result.lat;
                this.lng = result.lng;

                var address = this.buildAddress(this.street, this.city, this.state,
                    this.postal, this.country);

                this.navToRecord(result.recId, this.title, this.lat, this.lng, address, this.obj, this.icon, 'Lead');

                this.showLeadAssignment = true;
            });
    }

    handleSuccess(event) {

        // get saved opp and set this fields...title, address fields, lat, lng
        console.log('handle success');
        if(this.isLead) {
            this.recordId = this.leadId;
        } else {
            var record = JSON.parse(JSON.stringify(event.detail));
            console.log(JSON.parse(JSON.stringify(record)));
            this.recordId = record.id;
        }

        this.showSpinner = false;

        if (this.isOpportunity) {
            getOpportunity({ id: this.recordId })
                .then(result => {

                    this.title = result.summary;
                    this.street = result.street;
                    this.city = result.city;
                    this.state = result.state;
                    this.postal = result.postal;
                    this.country = result.country;
                    this.lat = result.lat;
                    this.lng = result.lng;

                    var address = this.buildAddress(this.street, this.city, this.state,
                        this.postal, this.country);

                    this.navToRecord(result.recId, this.title, this.lat, this.lng, address, this.obj, this.icon, 'Opportunity');

                });
        }

        if (this.isProject) {
            getProject({ id: this.recordId })
                .then(result => {
                    

                    this.title = result.summary;
                    this.street = result.street;
                    this.city = result.city;
                    this.state = result.state;
                    this.postal = result.postal;
                    this.country = result.country;
                    this.lat = result.lat;
                    this.lng = result.lng;

                    var address = this.buildAddress(this.street, this.city, this.state,
                        this.postal, this.country);

                    this.navToRecord(result.recId, this.title, this.lat, this.lng, address, this.obj, this.icon, 'Project');

                });
        }

        if (this.isOffice || this.isProspect) {
            getAccount({ id: this.recordId })
                .then(result => {
                    

                    this.title = result.summary;
                    this.street = result.street;
                    this.city = result.city;
                    this.state = result.state;
                    this.postal = result.postal;
                    this.country = result.country;
                   
                    //this.lat = result.lat;
                    //this.lng = result.lng;

                    var address = this.buildAddress(this.street, this.city, this.state,
                        this.postal, this.country);

                    if (this.isProspect) {
                        this.navToRecord(result.recId, this.title, this.lat, this.lng, address, 'Account', this.icon, 'Prospect');

                    } if (this.isOffice) {
                        this.navToRecord(result.recId, this.title, this.lat, this.lng, address, 'Account', this.icon, 'Office');
                    }

                });
        }

        if (this.isLead) {
            getLead({ id: this.recordId })
                .then(result => {
                   

                    this.title = result.summary;
                    this.street = result.street;
                    this.city = result.city;
                    this.state = result.state;
                    this.postal = result.postal;
                    this.country = result.country;
                    this.lat = result.lat;
                    this.lng = result.lng;

                    var address = this.buildAddress(this.street, this.city, this.state,
                        this.postal, this.country);

                    this.navToRecord(result.recId, this.title, this.lat, this.lng, address, this.obj, this.icon, 'Lead');

                });
        }
    }

    handleError(error) {

        // show form for user to fix error
        this.create = true;

        const errorMsg = error.detail.detail;
        const errorEvent = new CustomEvent('error', { detail: errorMsg });
        this.dispatchEvent(errorEvent);
        this.showSpinner = false;
    }

    navToRecord(recId, summary, lat, lng, address, obj, icon, recordType) {

        const navMapToRecord = new CustomEvent('saved', {
            detail: {
                recId: recId,
                summary: summary,
                lat: lat,
                lng: lng,
                address: address,
                objectType: obj,
                icon: icon,
                recordType: recordType
            }
        });

        this.dispatchEvent(navMapToRecord);
    }

    handleMenuOnClick(event) {

        let target = event.currentTarget;
        let recId = target.dataset.recid;
        let obj = target.dataset.obj;
        let act = target.dataset.act;

       

        if (act == 'view') {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: recId,
                    actionName: 'view'
                }
            });
        }

        if (act == 'newTask') {
            this[NavigationMixin.Navigate]({
                type: 'standard__objectPage',
                attributes: {
                    objectApiName: 'Task',
                    actionName: 'new'
                }
            });
        }

        if (act == 'newAppt') {
            this[NavigationMixin.Navigate]({
                type: 'standard__objectPage',
                attributes: {
                    objectApiName: 'Event',
                    actionName: 'new'
                }
            });
        }
    }

    radioValueChange(event) {
       
        this.obj = event.target.value;
        this.dispatchEvent(new CustomEvent('enablenext', { detail: event.target.value }));
    }

    toggleContactLeadToggle() {
        this.contLeadToggle = !this.contLeadToggle;
    }

    priorityChange(event) {
        this.priority = event.detail.value;
    }

    statusChange(event) {
        this.status = event.detail.value;
    }

    reminderSetChange() {
        this.reminderSet = !this.reminderSet;
    }

    createRecurChange() {
        this.createRecur = !this.createRecur;
    }

    handlerLatLng(event) {
        this.lat = event.target.latitude;
        this.lng = event.target.longitude;
    }

    buildAddress(street, city, state, postal, country) {
        var addressArray = [street, city, state, postal, country];
        addressArray = addressArray.filter(element => element); // remove nulls, blanks, undefined
        var address = addressArray.join(', ');

        return address;
    }

    clearFields() {

        lat = '';
        lng = '';
        street = '';
        city = '';
        state = '';
        zip = '';
        country = '';
        view = false;
        create = false;
        wrapper = null;
        record = null;

        name = '';
        subject = '';
        assignedTo = '';
        allDayAppointment = '';
        start = '';
        end = '';
        description = '';
        reminderSet = false;
        reminderDT = '';
        dueDate = '';
        priority = '';
        comments = '';
        createRecur = false;
        hasWhat = '';
        hasWho = '';
        parentTypeLabel = '';

        contLeadToggle = false;
        relatedLead = '';
        relatedContact = '';
    }

    displayCompleteForm() {
        this.showCompleteForm = true;
        this.followUp = false;
    }

    hideCompleteForm() {
        this.showCompleteForm = false;
        this.followUp = false;
    }

    submitCompleteForm() {
        this.handleShowSpinner();
        var defaultValues ={};
          if(this.street){
            defaultValues.Street__c = this.street;
          }
          if(this.city){
            defaultValues.City__c = this.city;
          }
          if(this.state){
            defaultValues.State__c = this.state;
          }
          if(this.zip){
            defaultValues.ZIP_Code__c = this.zip;
          }
          if(this.lat){
            defaultValues.Latitude_Longitude__Latitude__s = this.lat;
          }
          if(this.lng){
            defaultValues.Latitude_Longitude__Longitude__s = this.lng;
          }
          if(this.countryAppointment){
            defaultValues.Country__c = this.countryAppointment;
          }
          if(this.whoId)
          {
            defaultValues.WhoId = this.whoId;
          }
          if(this.whatId)
          {
            defaultValues.WhatId = this.whatId;
          }
        defaultValues = encodeDefaultFieldValues(defaultValues);
        
        updateTaskEvent({ id: this.recordid, outcome: this.outcomeText })
            .then(result => {
                if (this.followUp) {
                    this[NavigationMixin.Navigate]({
                        type: 'standard__objectPage',
                        attributes: {
                            objectApiName: this.obj,
                            actionName: 'new'
                        },
                        state: {
                            defaultFieldValues : defaultValues,

                        }
                    });
                }

                this.handleSuccessToast();
                this.showCompleteForm = false;
                this.outcomeText = '';
                this.followUp = false;
                this.handleGoBack();
                this.handleHideSpinner();
            })
            .catch(error => {
                console.log(error);
                this.error = error.body.message;
                const toastEvent = new ShowToastEvent({
                    title: 'An error occured. Please try again.',
                    message: this.error,
                    variant: 'error'
                });
                this.dispatchEvent(toastEvent);
                this.handleHideSpinner();
            });
    }

    handleSuccessToast() {
        const evt = new ShowToastEvent({
            title: 'Success!',
            message: 'Successfully updated.',
            variant: 'success',
        });
        this.dispatchEvent(evt);
    }

    handleGoBack() {
        const event = new CustomEvent('back');
        this.dispatchEvent(event);
    }

    handleShowSpinner() {
        const event = new CustomEvent('showspinner');
        this.dispatchEvent(event);
    }

    handleHideSpinner() {
        const event = new CustomEvent('hidespinner');
        this.dispatchEvent(event);
    }

    toggleFollowUp() {
        this.followUp = !this.followUp;
    }

    handleValueChange(event) {
        this.outcomeText = event.target.value;
    }

    get isEvent() {
        return this.obj == 'Event';
    }

    get isTask() {
        return this.obj == 'Task';
    }

    get isProject() {
        return this.obj == 'Project__c';
    }

    get isOpportunity() {
        return this.obj == 'Opportunity';
    }

    get isProspect() {
        return this.obj == 'Prospect';
    }

    get isOffice() {
        return this.obj == 'Office';
    }

    get isLead() {
        return this.obj == 'Lead';
    }

    get isViewSupported() {
        return this.obj != 'Event' && this.obj != 'Task';
    }

    get recordOptions() {
        return [
            { label: 'Account - Prospect', value: 'Prospect' },
            { label: 'Account - Office', value: 'Office' },
            { label: 'Opportunity', value: 'Opportunity' },
            { label: 'Project', value: 'Project__c' },
            { label: 'Lead', value: 'Lead' }
        ];
    }

    get completeFormTitle() {
        if (this.isEvent) {
            return 'Complete Appointment';
        }
        if (this.isTask) {
            return 'Complete Task';
        }
    }

    get completeFormCompleteBtn() {
        if (this.isEvent) {
            return 'Confirm Appointment Complete';
        }
        if (this.isTask) {
            return 'Confirm Task Complete';
        }
    }

    get outcomeLabel() {
        if (this.isEvent) {
            return 'Outcome';
        }
        if (this.isTask) {
            return 'Comment';
        }
    }

    get leadAssignmentInputVariables() {
        return [
            {
                name: "fromMap",
                type: "Boolean",
                value: true
            },
            {
                name: "defaultStreet",
                type: "String",
                value: this.street
            },
            {
                name: "defaultCity",
                type: "String",
                value: this.city
            },
            {
                name: "defaultState",
                type: "String",
                value: this.state
            },
            {
                name: "defaultZip",
                type: "String",
                value: this.zip
            },
            {
                name: "defaultCountry",
                type: "String",
                value: this.country
            },
            {
                name: "defaultLat",
                type: "String",
                value: this.lat
            },
            {
                name: "defaultLng",
                type: "String",
                value: this.lng
            }
        ];
    }

    handleLeadAssignFlowStatusChange(event) {
        console.log('in handleLeadAssignFlowStatusChange');
        console.log(event);
        if (event.detail.status === "FINISHED") {
            
            // set behavior after a finished flow interview.
            const createdLead = event.detail.outputVariables.find((variable) => variable.name === "createdLeadId");
            console.log('createdLead Id -> ', createdLead.value);
            
            // hide form
            const submitLeadEvent = new CustomEvent('hideleadform');
            this.dispatchEvent(submitLeadEvent);

            // pass new Lead ID to parent
            this.leadId = createdLead.value;
            this.handleSuccess();
        }
    }
}