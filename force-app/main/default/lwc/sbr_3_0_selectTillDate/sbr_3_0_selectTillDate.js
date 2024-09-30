import { LightningElement, track,wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getTillRecord from '@salesforce/apex/Sbr_3_0_endOfDayTillController.getEndOfTillRecord';
import getDraftTillRecord from '@salesforce/apex/Sbr_3_0_endOfDayTillController.getDraftEndOfTillRecord'; 
import checkEODRecordPresent from '@salesforce/apex/Sbr_3_0_endOfDayTillController.checkEODRecordPresent';
import checkTillDetailRecordPresent from '@salesforce/apex/Sbr_3_0_endOfDayTillController.checkTillDetailRecordPresent'; //FRONT-32190
import getUserLocationInfo from '@salesforce/apex/Sbr_3_0_endOfDayTillController.getUserLocationInfo'; //FRONT-32190
import getCustomSettindays from '@salesforce/apex/Sbr_3_0_endOfDayTillController.getCustomSettingDays';  //FRONT-33219
import { getFocusedTabInfo, refreshTab } from 'lightning/platformWorkspaceApi'; 
import { MessageContext, publish } from 'lightning/messageService';

import getTillSummary from '@salesforce/apex/SBR_3_0_API_GetEodTillSummary.getTillSummary';
import USER_ID from '@salesforce/user/Id';
import CLOSE_MODAL from '@salesforce/messageChannel/sbr_3_0_quickActionModalEvents__c';
import { makeEodAPICalls, openTabForSubmittedRecord, openTabForDraftRecord, getInputValues, formatValueWithCurrencySign, formatDate } from 'c/sbr_3_0_eodTillHelper';


export default class SelectTillDate extends  NavigationMixin(LightningElement) {
    label = {
        FailedMesssage : ''
    }
    @track selectedDate = new Date().toISOString().slice(0,10);
    @track isNextDisabled = false;
    @track showFutureDateError = false;
    @track isLoading = false;
    @track modelLoaded = false
    @track dataExist = false;
    @track today;
    @track isProcessingRefresh = false;
    @track isRefreshFailed = false;
    singleDraftRecord = false;
    singleDraftDate
    multipleDrafts = []
    showmultipleDrafts = false
    multipleDraftRecords = false;
    datepickerInitialized = false;
    @track TillId = ''
    @track startDrawer = 1000;
    @track accountedFor 
    @track nextDayDrawer = ''
    @wire(MessageContext)
    messageContext;
    branchLocationNumber; //FRONT-32190
    branchCompanyId; //FRONT-32190
    compoundKey;
    userLocationFetchFailed = false;
    eodTillId;
    apiCallStarted = false;
    @wire(getCustomSettindays)
    getCustomSettindays;

    get actionlabel(){
        return this.tillTable['Till Status'] == 'Submitted'?'View Details':'Next';
    }
    
    async connectedCallback() {
        this.addEventListener('callhandleNext', this.handleCallHandleNext);
        try {
            this.today = new Date().toISOString().slice(0, 10);
            await Promise.all([this.gettilldata(),this.getDraftRecords()]);
            await this.getUserLocationDetails();
            this.modelLoaded = true;
        } catch (error) {
            console.error('error connectedcallback',error)
            this.isProcessingRefresh = false;
            this.label.FailedMesssage = error?.body?.message;
            this.isRefreshFailed = true;
            this.userLocationFetchFailed = !this.compoundKey;
        }
    }

    async getDraftRecords() {
        try {
            const branchDetails = [this.branchCompanyId,this.branchLocationNumber].join('-');
            const data = await getDraftTillRecord({ compoundKey: branchDetails });
            const inputArray = this.generatePastDays();
            console.log('input array', inputArray);
    
            const datesToRemove = new Set(data.map(item => item.Till_Date__c));
    
            const finalArray = inputArray.filter(date => !datesToRemove.has(date));
            console.log('final array', finalArray);
    
            if (finalArray.length > 1) {
                this.multipleDraftRecords = true;
                this.multipleDrafts = finalArray.reverse().map(formatDate);
            } else if (finalArray.length === 1) {
                this.singleDraftDate = formatDate(finalArray[0]);
                this.singleDraftRecord = true;
            }
        } catch (error) {
            console.error('getDraftRecords error',error);
        }
    }
    
    generatePastDays() {
        console.log('EOD Till Custom Settings days : ' + this.getCustomSettindays.data);
        const days = parseInt( this.getCustomSettindays.data);
        let past30Days = [];
        let today = new Date();
        today.setDate(today.getDate() - 1);
        for (let i = 0; i < days; i++) {
            let date = new Date(today);
            date.setDate(date.getDate() - i);
            past30Days.push(date.toISOString().split('T')[0]);
        }
        return past30Days;
    }

    async getUserLocationDetails(){
        console.log('getUserLocationDetails');
        const userLocationInfo = await getUserLocationInfo({ userId: USER_ID }) //FRONT-32190
        console.log('userLocationInfo  ',userLocationInfo)
        this.branchLocationNumber = userLocationInfo?.[0]?.Branch__r?.Branch_Location_Number__c;
        this.branchCompanyId = userLocationInfo?.[0]?.Branch__r?.Company_ID__c;
        this.compoundKey = [this.branchCompanyId,this.branchLocationNumber,this.selectedDate].join('-');
        this.userLocationFetchFailed = false;
    }

    handleCallHandleNext() {
        // Call the public method when the event is received
        this.handleNext();
    }
    
    get futuredate(){
        return this.selectedDate > this.today ? true : false
    }

    getDateVal(event){
        this.selectedDate = event.detail.value;
        this.dataExist = false;
        const btnvisible = this.template.querySelector('.submitBtn');
        if(this.futuredate){
            btnvisible.disabled = true;
            const STYLE = document.createElement("style");
            STYLE.innerText = `.validateDate .slds-form-element__control{
               border : 2px solid var(--slds-g-color-error-base-40, var(--lwc-colorTextError,rgb(234, 0, 30)));
               border-radius: 4px;
            }.validateDate .slds-input{
                border : none !important;
            }.validateDate .slds-input:focus{
                outline: none !important;
                --slds-c-input-shadow : none;
            }`;
            this.template.querySelector('.validateDate').appendChild(STYLE);
        }
        if(!this.futuredate){
            btnvisible.disabled = false;
            const STYLE = document.createElement("style");
            STYLE.innerText = `.validateDate .slds-form-element__control{
            border : 1px solid lightgray;
            border-radius: 4px;
            }.validateDate .slds-input{
                border : none !important;
            }`;
        this.template.querySelector('.validateDate').appendChild(STYLE);
            this.gettilldata();
            this.isLoading = true;
        }
       
    }

    handleBacktoTIll(event){
        this.showmultipleDrafts = false
    }

    @track tillTable = {
        'Till Date' : '',
        'Deposit Cash' : '',
        'Deposit Checks':'',
        'Deposit ROA Cash':'',
        'Deposit ROA Checks':'',
        'Total Bank Deposit':'',
        'User':'',
        'Date Submitted':'',
        'Time Submitted':'',
        'Till Status':'',
    }

    get tableData() {
        return Object.entries(this.tillTable).map(([key, value]) => ({ key, value }));
    }

    handleMultipleDrafts(event){
        this.showmultipleDrafts = true
    }

    async gettilldata() {
        try {
            await this.getUserLocationDetails();
            console.log('inside gettilldata', this.selectedDate, this.compoundKey);
    
            const getTillData = await getTillRecord({ tillDate: this.selectedDate, compoundKey: this.compoundKey });
    
            if (getTillData && getTillData.Till_Status__c) {
                console.log('getTillRecord getTillData', getTillData);
    
                this.tillTable = {
                    'Till Date': formatDate(getTillData.Till_Date__c),
                    'Deposit Cash':  formatValueWithCurrencySign(getTillData.Total_Cash__c || ''),
                    'Deposit Checks': formatValueWithCurrencySign(getTillData.Total_Checks__c || ''),
                    'Deposit ROA Cash': formatValueWithCurrencySign(getTillData.Total_ROA_Cash__c || ''),
                    'Deposit ROA Checks': formatValueWithCurrencySign(getTillData.Total_ROA_Checks__c || ''),
                    'Total Bank Deposit':  formatValueWithCurrencySign(getTillData.Total_Deposit_in_Bank__c || ''),
                    'User': '',
                    'Date Submitted': '',
                    'Time Submitted': '',
                    'Till Status': getTillData.Till_Status__c || ''
                };
    
                if (getTillData.Submitted_Date__c) {
                    const dateTime = new Date(getTillData.Submitted_Date__c);
                    const formattedDate = formatDate(dateTime.toISOString().split('T')[0]);
                    const timeSubmitted = dateTime.toLocaleTimeString("en-US", { hour12: false });
                    this.tillTable['Date Submitted'] = formattedDate;
                    this.tillTable['Time Submitted'] = timeSubmitted;
                    this.tillTable['User'] = getTillData.Submitted_User__r?.Alias || '';
                }
    
                this.TillId = getTillData.Id;
                this.startDrawer = getTillData.Start_Drawer__c || '';
                this.nextDayDrawer = getTillData.Next_Day_Drawer__c || '';
                this.accountedFor = getTillData.Adjustments_Accounted_For__c || '';
    
                this.dataExist = true;
            } else {
                this.resetTillTable();
                this.startDrawer = 1000;
            }
        } catch (error) {
            console.error('gettilldata error', error);
            this.resetTillTable();
            this.dataExist = false;
        } finally {
            this.isLoading = false;
        }
    }
    
    resetTillTable() {
        for (let key in this.tillTable) {
            if (this.tillTable.hasOwnProperty(key)) {
                this.tillTable[key] = '';
            }
        }
        this.accountedFor = '';
        this.nextDayDrawer = '';
        this.TillId = '';
    }
    
    handleTillRec(res){
        console.log('record is'+res)
    }
  
    handleClose() {
        const message = {
            closeModal: true
        };
        publish(this.messageContext, CLOSE_MODAL, { payload: message });
        this.dispatchEvent(new CustomEvent('cancel'));    
    }

    handleCancel() {
        const message = {
            closeModal: true
        };
        publish(this.messageContext, CLOSE_MODAL, { payload: message });
        this.dispatchEvent(new CustomEvent('cancel'));
    }

    removeSpecialCharacters(value) {
        return value.replace(/[^\d.-]/g, ''); // This will Remove non-numeric characters
    }

    handleGoBack(){
        if (this.apiCallStarted) {
            this.isProcessingRefresh = this.isRefreshFailed = this.apiCallStarted = false;
            this.modelLoaded = true;
            return;
        }
        const message = {
            closeModal: true
        };
        publish(this.messageContext, CLOSE_MODAL, { payload: message });
    }

    disconnectedCallback(){
        this.removeEventListener('callhandleNext', this.handleCallHandleNext);
        getFocusedTabInfo().then(tabInfo => {
            refreshTab(tabInfo.tabId, {
                includeAllSubtabs: true
            });
           
        });
    }

    async handleNext() {
        try {
            if (this.userLocationFetchFailed) {
                await this.getUserLocationDetails();
                this.isProcessingRefresh = this.isRefreshFailed = false;
                this.modelLoaded = true;
                return;
            }
        } catch (error) {
            this.label.FailedMesssage = error?.body?.message;
            this.isRefreshFailed = true;
            this.userLocationFetchFailed = true;
            return;
        }
        this.isProcessingRefresh = true;
        this.isRefreshFailed = false;
        this.apiCallStarted = true;
        document.body.classList.add("blurBackground");
        try {
            const compoundKey = [this.branchCompanyId, this.branchLocationNumber, this.selectedDate].join('-'); //FRONT-32190
            let [getTillSummaryNext, eodTillId] = await Promise.all([getTillSummary({ tillDate: this.selectedDate, userId: USER_ID, sourceName: 'Next' }), checkEODRecordPresent({ compoundKey })])
            let tillDetailId = await checkTillDetailRecordPresent({ eodTillId }); //FRONT-32190
            if (this.tillTable['Till Status'] == 'Submitted') {
                this.isProcessingRefresh = false;
                const inputValues = await getInputValues.call(this, eodTillId, tillDetailId, getTillSummaryNext);
                await openTabForSubmittedRecord.call(this, inputValues, eodTillId);
                this.dispatchEvent(new CustomEvent('cancel'));
            } else {
                let { eodTillId, tillDetailId } = await makeEodAPICalls.call(this, getTillSummaryNext, compoundKey);
                const inputValues = await getInputValues.call(this, eodTillId, tillDetailId, getTillSummaryNext);
                await openTabForDraftRecord.call(this, inputValues);
                this.dispatchEvent(new CustomEvent('cancel'));
                this.isProcessingRefresh = false;
            }
        } catch (error) {
            console.error('handleNext error', error);
            this.errorMessage = error?.body?.message || error?.body || error;
            this.isProcessingRefresh = false;
            this.label.FailedMesssage = this.errorMessage;
            this.isRefreshFailed = true;
        }
    }
}