import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord, getFieldValue, createRecord } from 'lightning/uiRecordApi';
import LOCALE from '@salesforce/i18n/locale';
import ReminderDateTime from '@salesforce/schema/Task.ReminderDateTime';
import { NavigationMixin } from 'lightning/navigation';

export default class Sbr_3_0_lineItemsContainerCmp extends NavigationMixin(LightningElement) {
    isMobile = false;
    @api recordId;
    @api objectApiName;
    //to be used to explicitly sync customer information on sbr_3_0_itemSearchCtrCmp and sbr_3_0_lineItemsContainerCmp when inside sbr_3_0_quickQuoteContainerCmp
    @api
    get syncCustomer() {
        return this._selectedCustomer;
    }
    set syncCustomer(value) {
        if (value) {
            if (this.isFirstRender) {
                this._tempCustomer = value.Id ? value : {};
            } else {
                this._selectedCustomer = value.Id ? value : {};
            }
        }
    }

    _selectedCustomer = null;
    tabTitle = 'Cart';
    clrBtnLabel = 'Clear Cart';
    saveBtnLabel = 'Save Cart';
    rentalPeriod = '7days';
    minStartDate;
    minReturnDate;
    startDate;
    startTime = '12:00:00.000';
    returnDate;
    returnTime = '12:00:00.000';
    disableDuration = true;
    deliveryCpu = 'cpu';
    jobsiteZip;
    notes;
    isJobsiteRequired = false;
    jobsiteErrorMsg = 'Job Site Zip Code is required for Delivery';
    whereClause = "recordtype.name in ('Credit', 'Non-Credit')";
    acctFields = "RM_Account_Number__c,";
    _context = 'Cart';
    isFirstRender = true;
    fields = [];

    cancelBtnClass = 'slds-button cancel-btn-class';
    saveBtnClass = 'slds-button save-btn-class';
    isNotCartInfo = false;
    showCartInfo = false;
    showHeader = false;
    activeTab = 'cart';
    viewState = 'base';
    zipValid = false;
    isValidZip = true;
    customerName;

    isNotCart = false;
    viewStateOld = '';
    mobileIsLoading = false;
    isEmptyCart = false;
    isInvalidStartDate = false;
    isInvalidEndDate = false;

    savedRentalPeriod;
    savedStartDate;
    savedReturnDate;
    savedStartTime;
    savedReturnTime;
    savedDeliveryCpu;
    savedZipCode;
    savedNotes;
    savedCustomer;
    tempMinReturnDate = '';

    //wire method to set customer information based on record page context
    @wire(getRecord, { recordId: '$recordId', fields: '$fields' })
    wiredRecord({ error, data }) {
        if (data) {
            let fieldsData;
            switch (this.objectApiName) {
                case 'Cart__c':
                    fieldsData = data.fields.Account__r.value;
                    break;
                case 'SBQQ__Quote__c':
                    fieldsData = data.fields.SBQQ__Account__r.value;
                    break;
                case 'Order':
                    fieldsData = data.fields.Account.value;
                    break;
            }
            if (fieldsData) {
                let acctInfo = {
                    Id: fieldsData.fields.Id.value,
                    Name: fieldsData.fields.Name.value,
                    RM_Account_Number__c: fieldsData.fields.RM_Account_Number__c.value,
                    RecordTypeId: fieldsData.recordTypeId,
                    DisplayName: fieldsData.fields.Name.value
                };
                this._selectedCustomer = acctInfo;
            }
        } else if (error) {
            console.log(error);
        }
    }
    //set fields to fetch for account information based on record page context
    setRecordFields() {
        switch (this.objectApiName) {
            case 'Cart__c':
                this.fields = ['Cart__c.Account__r.Name', 'Cart__c.Account__r.Id', 'Cart__c.Account__r.RM_Account_Number__c'];
                break;
            case 'SBQQ__Quote__c':
                this.fields = ['SBQQ__Quote__c.SBQQ__Account__r.Name', 'SBQQ__Quote__c.SBQQ__Account__r.Id', 'SBQQ__Quote__c.SBQQ__Account__r.RM_Account_Number__c'];
                break;
            case 'Order':
                this.fields = ['Order.AccountId.Name', 'Order.AccountId.Id', 'Order.AccountId.RM_Account_Number__c'];
                break;
        }
    }
    connectedCallback() {
        if (this.recordId) {
            //set tabTitle to appropriate record page title
            this.setRecordFields();
            this.setContext();
        }
        this.initializeFields();
        this.isMobile = window.matchMedia('(max-width: 480px)').matches;
    }
    renderedCallback() {
        if (this.isFirstRender && !this.recordId) {
            this.isFirstRender = false;
            this._selectedCustomer = this._tempCustomer;
        }
        if (this.isMobile) {
            let viewportHeight = window.innerHeight;
        }
    }
    initializeFields() {
        //this.showHeader = true;
        let today = new Date();
        today.setDate(today.getDate() + 1);
        //this.startDate = `${today.getFullYear()}-${today.getMonth() + 1}-${today.getDate()}`;
        let startMonthPad;
        let startDayPad;
        if ((today.getMonth() + 1) > 0 && (today.getMonth() + 1) < 10 &&
            today.getDate() > 0 && today.getDate() < 10) {
            startMonthPad = (today.getMonth() + 1).toString().padStart(2, '0');
            startDayPad = today.getDate().toString().padStart(2, '0');
            this.startDate = `${today.getFullYear()}-${startMonthPad}-${startDayPad}`;
        }
        // if only date is between 1-9
        else if (today.getDate() > 0 && today.getDate() < 10) {
            startDayPad = today.getDate().toString().padStart(2, '0');
            this.startDate = `${today.getFullYear()}-${today.getMonth() + 1}-${startDayPad}`;
        }
        // if only month is between 1-9
        else if ((today.getMonth() + 1) > 0 && (today.getMonth() + 1) < 10) {
            startMonthPad = (today.getMonth() + 1).toString().padStart(2, '0');
            this.startDate = `${today.getFullYear()}-${startMonthPad}-${today.getDate()}`;
        } else {
            this.startDate = `${today.getFullYear()}-${today.getMonth() + 1}-${today.getDate()}`
        }
        this.minStartDate = this.startDate;
        today.setDate(today.getDate() + 7);
        let returnMonthPad;
        let returnDayPad;
        if ((today.getMonth() + 1) > 0 && (today.getMonth() + 1) < 10 &&
            today.getDate() > 0 && today.getDate() < 10) {
            returnMonthPad = (today.getMonth() + 1).toString().padStart(2, '0');
            returnDayPad = today.getDate().toString().padStart(2, '0');
            this.returnDate = `${today.getFullYear()}-${returnMonthPad}-${returnDayPad}`;
        }
        else if (today.getDate() > 0 && today.getDate() < 10) {
            returnDayPad = today.getDate().toString().padStart(2, '0');
            this.returnDate = `${today.getFullYear()}-${today.getMonth() + 1}-${returnDayPad}`;
        }

        else if ((today.getMonth() + 1) > 0 && (today.getMonth() + 1) < 10) {
            returnMonthPad = (today.getMonth() + 1).toString().padStart(2, '0');
            this.returnDate = `${today.getFullYear()}-${returnMonthPad}-${today.getDate()}`;
        } else {
            this.returnDate = `${today.getFullYear()}-${today.getMonth() + 1}-${today.getDate()}`;
        }

        this.savedStartDate = this.startDate;
        this.savedReturnDate = this.returnDate;
        this.savedDeliveryCpu = this.deliveryCpu;

        this.updateCartInfo();
    }
    setContext() {
        switch (this.objectApiName) {
            case 'Cart__c':
                this._context = 'Cart';
                break;
            case 'SBQQ__Quote__c':
                this._context = 'Quote';
                break;
            case 'Order':
                this._context = 'Order';
                break;
            default:
                this._context = 'Cart';
                break;
        }
    }
    validateClearLineItems() {
        this.template.querySelector("c-sbr_3_0_modal-cmp").toggleModal();
    }
    clearLineItems = (event) => {
        event.stopPropagation();
        this.template.querySelector("c-sbr_3_0_line-items-cmp").clearLineItems();
        this.template.querySelector("c-sbr_3_0_modal-cmp").toggleModal();
    }
    setEmptyCart(event) {
        this.isEmptyCart = event.detail.isEmptyCart.valueOf();
    }
    saveLineItems() {
        let isValid = this.validateCartInfo();
        if (isValid) {
            //this.template.querySelector("c-sbr_3_0_line-items-cmp").saveLineItems('Product Inquiry', this.getInfoObject());
            this.mobileIsLoading = true;
            new Promise(
                (resolve, reject) => {
                    setTimeout(() => {
                        this.template.querySelector("c-sbr_3_0_line-items-cmp").saveLineItems('Product Inquiry', this.getInfoObject());
                        resolve();
                    }, 3000);
                }).then(
                    () => this.mobileIsLoading = false
                );
        } else {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Please resolve errors in information section to proceed with Save Cart.',
                    variant: 'error',
                }),
            );
        }
    }
    toggleInfoPanel(e) {
        let container = this.template.querySelector('.slds-section');
        let isExpanded = e.target.getAttribute('aria-expanded');
        let content = this.template.querySelector('.slds-section__content');
        if (isExpanded == 'true') {
            e.target.setAttribute('aria-expanded', false);
            content.setAttribute('aria-hidden', true);
            container.classList.remove('slds-is-open');
        } else {
            e.target.setAttribute('aria-expanded', true);
            content.setAttribute('aria-hidden', false);
            container.classList.add('slds-is-open');
        }
    }
    // display cart info
    displayCartInfo(event) {
        this.showCartInfo = true;
        // for banner with menu dropdown
        this.isNotCartInfo = true;
        const toggleprodinqmobilestate = new CustomEvent('toggleprodinqmobilestate', {
            bubbles: true,
            composed: true,
            detail: {
                viewState: 'cart-info',
                showTabsPanel: false
            }
        });
        this.dispatchEvent(toggleprodinqmobilestate);
    }

    toggleClearCart(event) {
        this.template.querySelector("c-sbr_3_0_modal-cmp").toggleModal();
    }

    toggleProdInqMobileState(event) {
        this.viewStateOld = this.viewState;
        this.viewState = event.detail.viewState.valueOf();
        switch (this.viewState) {
            case 'base':
                this.activeTab = 'cart';
                break;
            case 'cart-info':
                this.activeTab = 'cart-info';
                break;
            default:
                break;
        }
    }
    updateField(e) {
        let targetField = e.target;
        switch (targetField.name) {
            case 'rental-period':
                this.rentalPeriod = targetField.value;
                if (targetField.value == 'custom') {
                    this.disableDuration = false;
                } else {
                    this.disableDuration = true;
                }
                this.updateReturnDates();
                break;
            case 'start-date':
                if (targetField.value == null || targetField.value == '') {
                    targetField.value = this.startDate;
                } else {
                    let date = new Date(targetField.value);
                    date.setDate(date.getDate() + 1);
                    let monthPad;
                    let dayPad;
                    // if both month and date are between 1-9, pad with 0
                    if (((date.getMonth() + 1) > 0) && (date.getMonth() + 1) < 10 &&
                        date.getDate() > 0 && date.getDate() < 10) {
                        monthPad = (date.getMonth() + 1).toString().padStart(2, '0');
                        dayPad = date.getDate().toString().padStart(2, '0');
                        this.startDate = `${date.getFullYear()}-${monthPad}-${dayPad}`;
                    }
                    // if only date is between 1-9
                    else if (date.getDate() > 0 && date.getDate() < 10) {
                        dayPad = date.getDate().toString().padStart(2, '0');
                        this.startDate = `${date.getFullYear()}-${date.getMonth() + 1}-${dayPad}`;
                    }
                    // if only month is between 1-9
                    else if ((date.getMonth() + 1) > 0 && (date.getMonth() + 1) < 10) {
                        monthPad = (date.getMonth() + 1).toString().padStart(2, '0');
                        this.startDate = `${date.getFullYear()}-${monthPad}-${date.getDate()}`;
                    } else {
                        this.startDate = `${date.getFullYear()}-${date.getMonth() + 1}-${date.getDate()}`;
                    }
                }
                this.validateStartDate();
                this.updateReturnDates();
                break;
            case 'start-time':
                if (targetField.value == null || targetField.value == '') targetField.value = this.startTime;
                this.startTime = targetField.value;
                break;
            case 'return-date':
                if (targetField.value == null || targetField.value == '') {
                    targetField.value = this.returnDate;
                } else {
                    let date = new Date(targetField.value);
                    date.setDate(date.getDate() + 1);
                    let monthPad;
                    let dayPad;
                    // if both month and date are between 1-9, pad with 0
                    if (((date.getMonth() + 1) > 0) && (date.getMonth() + 1) < 10 &&
                        date.getDate() > 0 && date.getDate() < 10) {
                        monthPad = (date.getMonth() + 1).toString().padStart(2, '0');
                        dayPad = date.getDate().toString().padStart(2, '0');
                        this.returnDate = `${date.getFullYear()}-${monthPad}-${dayPad}`;
                    }
                    // if only date is between 1-9
                    else if ((date.getDate() > 0 && date.getDate() < 10) &&
                        !((date.getMonth() + 1) > 0 && (date.getMonth() + 1) < 10)) {
                        dayPad = date.getDate().toString().padStart(2, '0');
                        this.returnDate = `${date.getFullYear()}-${date.getMonth() + 1}-${dayPad}`;
                    }
                    // if only month is between 1-9
                    else if (((date.getMonth() + 1) > 0 && (date.getMonth() + 1) < 10)
                        && !(date.getDate() > 0 && date.getDate() < 10)) {
                        monthPad = (date.getMonth() + 1).toString().padStart(2, '0');
                        this.returnDate = `${date.getFullYear()}-${monthPad}-${date.getDate()}`;
                    } else {
                        this.returnDate = `${date.getFullYear()}-${date.getMonth() + 1}-${date.getDate()}`;
                    }
                }
                this.validateReturnDate();
                break;
            case 'return-time':
                if (targetField.value == null || targetField.value == '') targetField.value = this.returnTime;
                this.returnTime = targetField.value;
                break;
            case 'delivery-cpu':
                this.deliveryCpu = targetField.value;
                this.isJobsiteRequired = targetField.value == 'delivery' ? true : false;
                if (this.deliveryCpu == 'cpu') {
                    this.deliveryCpu.toUpperCase();
                }
                if (this.deliveryCpu == 'delivery') {
                    this.template.querySelector('[data-name=jobsite-zip]').focus();
                }
                break;
            case 'jobsite-zip':
                this.jobsiteZip = targetField.value;
                if (this.deliveryCpu == 'delivery' && targetField.value == '') {
                    this.template.querySelector('[data-name=jobsite-zip]').focus();
                }
                break;
            case 'notes':
                this.notes = targetField.value;
        }
        this.updateEstimates();
    }
    cancelCartInfo(event) {
        this.showCartInfo = false;
        this.isNotCartInfo = false;
        this.isInvalidStartDate = false;
        this.isInvalidEndDate = false;
        if (this.savedRentalPeriod) this.rentalPeriod = this.savedRentalPeriod;
        if (this.savedStartDate) this.startDate = this.savedStartDate;
        if (this.savedReturnDate) this.returnDate = this.savedReturnDate;
        if (this.template.querySelector('[data-name=jobsite-zip]').value == null || this.template.querySelector('[data-name=jobsite-zip]').value == '') {
            this.jobsiteZip = this.savedZipCode;
            this.template.querySelector('[data-name=jobsite-zip]').value = this.savedZipCode;
        }
        else{
            this.jobsiteZip = this.savedZipCode;
            this.template.querySelector('[data-name=jobsite-zip]').value = this.savedZipCode;
        }
        if (this.savedStartTime) this.startTime = this.savedStartTime;
        if (this.savedReturnTime) this.returnTime = this.savedReturnTime;
        if (this.savedDeliveryCpu) {
            this.deliveryCpu = this.savedDeliveryCpu;
            this.isJobsiteRequired = this.deliveryCpu == 'delivery' ? true : false;
        }
        this.template.querySelector('[data-name=notes]').value = this.savedNotes;
        this.notes = this.savedNotes;


        if (this.savedCustomer != null) {
            if (this._selectedCustomer != null) {
                if (this._selectedCustomer.Name != null && this.savedCustomer == null) {
                    this.customerName = '';
                    this._selectedCustomer = null;
                    this.template.querySelector('c-s-b-r_3_0_custom-lookup-cmp').handleRemove();
                } else {
                    this.customerName = this.savedCustomer.Name + ', ';
                    this._selectedCustomer = this.savedCustomer;
                    this.template.querySelector('c-s-b-r_3_0_custom-lookup-cmp').selectedRecordObject(this.savedCustomer);
                    console.log('Customer should be changed here');
                }
            } else {
                this.customerName = '';
                this._selectedCustomer = null;
            }
        } else {
            this.customerName = '';
            this._selectedCustomer = null;
            this.template.querySelector('c-s-b-r_3_0_custom-lookup-cmp').handleRemove();
        }
        console.log('Send toggleprodinqmobilestate');
            const toggleprodinqmobilestate = new CustomEvent('toggleprodinqmobilestate', {
                bubbles: true,
                composed: true,
                detail: {
                    viewState: 'base',
                    showTabsPanel: true
                }
            });
            this.dispatchEvent(toggleprodinqmobilestate);
    }
        saveCartInfo(event) {
            let today = new Date();
            today.setDate(today.getDate() + 1);
            let startMonthPad;
            let startDayPad;
            let validDate;
            if ((today.getMonth() + 1) > 0 && (today.getMonth() + 1) < 10 &&
                today.getDate() > 0 && today.getDate() < 10) {
                startMonthPad = (today.getMonth() + 1).toString().padStart(2, '0');
                startDayPad = today.getDate().toString().padStart(2, '0');
                validDate = `${startMonthPad}/${startDayPad}/${today.getFullYear()}`;
            }
            // if only date is between 1-9
            else if (today.getDate() > 0 && today.getDate() < 10) {
                startDayPad = today.getDate().toString().padStart(2, '0');
                validDate = `${today.getMonth() + 1}/${startDayPad}/${today.getFullYear()}`;
            }
            // if only month is between 1-9
            else if ((today.getMonth() + 1) > 0 && (today.getMonth() + 1) < 10) {
                startMonthPad = (today.getMonth() + 1).toString().padStart(2, '0');
                validDate = `${startMonthPad}/${today.getDate()}/${today.getFullYear()}/`;
            } else {
                validDate = `${today.getMonth() + 1}/${today.getDate()}/${today.getFullYear()}`
            }

            this.savedRentalPeriod = this.rentalPeriod;
            if (this.validateStartDate() && this.validateReturnDate()){
                this.savedStartDate = this.startDate;
                this.savedReturnDate = this.returnDate;
            } 
            this.savedStartTime = this.startTime;
            this.savedReturnTime = this.returnTime;
            this.savedDeliveryCpu = this.deliveryCpu;

            if (this.template.querySelector('[data-name=jobsite-zip]').value == null || this.template.querySelector('[data-name=jobsite-zip]').value == '') {
                this.jobsiteZip = this.template.querySelector('[data-name=jobsite-zip]').value;
            } else {
                this.savedZipCode = this.jobsiteZip;
            }
            this.savedNotes = this.notes;

            if (this._selectedCustomer != null) {
                if (this._selectedCustomer.Name == null) {
                    this.customerName = '';
                    this.savedCustomer = null
                } else {
                    this.customerName = this._selectedCustomer.Name + ', ';
                    this.savedCustomer = this._selectedCustomer;
                }
            } else {
                this.customerName = '';
                this.savedCustomer = null
            }

            this.showCartInfo = false;
            this.isNotCartInfo = false;
            if (this.validateCartInfo()) {
                if (this.jobsiteZip != null && this.jobsiteZip != '') {
                    this.zipValid = true;
                } else {
                    this.zipValid = false;
                }

                this.updateCartInfo();
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: `Cart Information Saved`,
                        variant: 'success',
                    }),
                );

                const toggleprodinqmobilestate = new CustomEvent('toggleprodinqmobilestate', {
                    bubbles: true,
                    composed: true,
                    detail: {
                        viewState: 'base',
                        showTabsPanel: true
                    }
                });
                this.dispatchEvent(toggleprodinqmobilestate);
            } else {
                event.preventDefault();
                this.showCartInfo = true;
                this.isNotCartInfo = true;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: `Please resolve errors in information section to proceed with Save Cart.`,
                        variant: 'error'
                    }),
                );
            }
        }
        updateCustomerPricing(event) {
            this._selectedCustomer = event.detail;
            if (!this.recordId) {
                let selectedCustomer = event.detail;
                const selectedCustomerEvent = new CustomEvent('customerselection', { detail: selectedCustomer });
                this.dispatchEvent(selectedCustomerEvent);
            }
        }
        updateCartInfo() {
            let cartInfo = this.getInfoObject();
            if (!this.recordId) {
                console.log('send cartInfo: ', cartInfo);
                console.log('send cartInfo.Customer_Pick_Up__c: ', cartInfo?.Customer_Pick_Up__c);
                const cartSyncEvent = new CustomEvent('cartsync', {
                    detail: {
                        cartInfo: cartInfo
                    }
                });
                this.dispatchEvent(cartSyncEvent);
            }
        }
        getLastDayOfMonth(year, month) {
            return new Date(year, month + 1, 0);
        }

        getFirstDayOfNextMonth(startDate) {
            const date = new Date(startDate);
            return new Date(date.getFullYear(), date.getMonth() + 1, 1);
        }
        updateReturnDates() {
            //let startDate = new Date(this.startDate);
            let startDate = new Date(this.startDate);
            startDate.setDate(startDate.getDate() + 1);
            let monthPad;
            let dayPad;

            const lastDayCurrentMonth = this.getLastDayOfMonth(startDate.getFullYear(), startDate.getMonth());
            let datemin = new Date(this.minReturnDate);

            //format and pass return date in right when you reach the end of the month
            let lastDateCurrentMonth = (lastDayCurrentMonth.getMonth() + 1) + '/' + lastDayCurrentMonth.getDate() + '/' + lastDayCurrentMonth.getFullYear();
            let minDate = (startDate.getMonth() + 1) + '/' + startDate.getDate() + '/' + startDate.getFullYear();

            if (lastDateCurrentMonth === minDate) {
                let newDate = this.getFirstDayOfNextMonth(startDate);
                if ((newDate.getMonth() + 1) > 0 && (newDate.getMonth() + 1) < 10 &&
                    newDate.getDate() > 0 && newDate.getDate() < 10) {
                    monthPad = (newDate.getMonth() + 1).toString().padStart(2, '0');
                    dayPad = newDate.getDate().toString().padStart(2, '0');
                    this.minReturnDate = `${newDate.getFullYear()}-${monthPad}-${dayPad}`;
                }
                // if only date is between 1-9
                else if (newDate.getDate() > 0 && newDate.getDate() < 10) {
                    dayPad = newDate.getDate().toString().padStart(2, '0');
                    this.minReturnDate = `${newDate.getFullYear()}-${newDate.getMonth() + 1}-${dayPad}`;
                }
                // if only month is between 1-9
                else if ((newDate.getMonth() + 1) > 0 && (newDate.getMonth() + 1) < 10) {
                    monthPad = (newDate.getMonth() + 1).toString().padStart(2, '0');
                    this.minReturnDate = `${newDate.getFullYear()}-${monthPad}-${newDate.getDate()}`;
                } else {
                    this.minReturnDate = `${newDate.getFullYear()}-${newDate.getMonth() + 1}-${newDate.getDate()}`;
                }
            } else {
                if ((startDate.getMonth() + 1) > 0 && (startDate.getMonth() + 1) < 10 &&
                    startDate.getDate() > 0 && startDate.getDate() < 10) {
                    monthPad = (startDate.getMonth() + 1).toString().padStart(2, '0');
                    dayPad = (startDate.getDate() + 1).toString().padStart(2, '0');
                    this.minReturnDate = `${startDate.getFullYear()}-${monthPad}-${dayPad}`;
                }
                // if only date is between 1-9
                else if (startDate.getDate() > 0 && startDate.getDate() < 10) {
                    dayPad = (startDate.getDate() + 1).toString().padStart(2, '0');
                    this.minReturnDate = `${startDate.getFullYear()}-${startDate.getMonth() + 1}-${dayPad}`;
                }
                // if only month is between 1-9
                else if ((startDate.getMonth() + 1) > 0 && (startDate.getMonth() + 1) < 10) {
                    monthPad = (startDate.getMonth() + 1).toString().padStart(2, '0');
                    this.minReturnDate = `${startDate.getFullYear()}-${monthPad}-${startDate.getDate() + 1}`;
                } else {
                    this.minReturnDate = `${startDate.getFullYear()}-${startDate.getMonth() + 1}-${startDate.getDate() + 1}`;
                }
            }
            let returnDate = new Date(this.startDate);
            returnDate.setDate(returnDate.getDate() + 1);
            switch (this.rentalPeriod) {
                case '1day':
                    returnDate.setDate(returnDate.getDate() + 1);
                    break;
                case '7days':
                    returnDate.setDate(returnDate.getDate() + 7);
                    break;
                case '14days':
                    returnDate.setDate(returnDate.getDate() + 14);
                    break;
                case '28days':
                    returnDate.setDate(returnDate.getDate() + 28);
                    break;
            }
            if (this.rentalPeriod != 'custom') {
                let monthPad;
                let dayPad;
                if (((returnDate.getMonth() + 1) > 0) && (returnDate.getMonth() + 1) < 10 &&
                    returnDate.getDate() > 0 && returnDate.getDate() < 10) {
                    monthPad = (returnDate.getMonth() + 1).toString().padStart(2, '0');
                    dayPad = returnDate.getDate().toString().padStart(2, '0');
                    this.returnDate = `${returnDate.getFullYear()}-${monthPad}-${dayPad}`;
                }
                else if ((returnDate.getDate() > 0 && returnDate.getDate() < 10) &&
                    !((returnDate.getMonth() + 1) > 0 && (returnDate.getMonth() + 1) < 10)) {
                    dayPad = returnDate.getDate().toString().padStart(2, '0');
                    this.returnDate = `${returnDate.getFullYear()}-${returnDate.getMonth() + 1}-${dayPad}`;
                }
                else if (((returnDate.getMonth() + 1) > 0 && (returnDate.getMonth() + 1) < 10)
                    && !(returnDate.getDate() > 0 && returnDate.getDate() < 10)) {
                    monthPad = (returnDate.getMonth() + 1).toString().padStart(2, '0');
                    this.returnDate = `${returnDate.getFullYear()}-${monthPad}-${returnDate.getDate()}`;
                } else {
                    this.returnDate = `${returnDate.getFullYear()}-${returnDate.getMonth() + 1}-${returnDate.getDate()}`;
                }
            }
            this.validateReturnDate();
            // this.returnDate = `${returnDate.getFullYear()}-${returnDate.getMonth() + 1}-${returnDate.getDate()}`;
        }
        updateEstimates() {
            //trigger call to update estimates
        }
        validateCartInfo() {
            let isStartDateValid = this.template.querySelector('[data-name=start-date]').validity.valid && this.validateStartDate();
            let isReturnDateValid = this.template.querySelector('[data-name=return-date]').validity.valid && this.validateReturnDate();
            let isJobsiteZipValid = this.template.querySelector('[data-name=jobsite-zip]').validity.valid;
            //let areDatesValid = this.validateDates();
            return isStartDateValid && isReturnDateValid && isJobsiteZipValid;

        }
        validateStartDate() {
            let startDate = new Date(this.startDate);
            startDate.setDate(startDate.getDate() + 1);
            let minStart = new Date(this.minStartDate);
            let today = new Date();
            today.setDate(today.getDate() + 1);
            if (!startDate || startDate <= today) {
                console.log('start date should error');
                this.isInvalidStartDate = true;
                return false;
            } else {
                this.isInvalidStartDate = false;
                return true;
            }
            return true;
        }
        validateReturnDate() {
            let startDate = new Date(this.startDate);
            let returnDate = new Date(this.returnDate);

            startDate.setDate(startDate.getDate() + 1);
            returnDate.setDate(returnDate.getDate() + 1);

            let today = new Date();
            today.setDate(today.getDate() + 1);

            if (!returnDate || startDate >= returnDate) {
                this.isInvalidEndDate = true;
                return false;
            } else {
                this.isInvalidEndDate = false;
                return true;
            }
            return true;
        }
        getInfoObject() {
            let infoObject = {
                Rental_Period__c: '',
                Rental_Start_Date__c: new Date(this.startDate + " " + this.startTime).toISOString(),
                Rental_End_Date__c: new Date(this.returnDate + " " + this.returnTime).toISOString(),
                Account__c: this._selectedCustomer ? this._selectedCustomer.Id : null,
                Customer_Pick_Up__c: this.deliveryCpu,
                Zip_Code__c: this.jobsiteZip,
                Notes__c: this.notes,
                Is_Active__c: true
            };

            switch (this.rentalPeriod) {
                case '1day':
                    infoObject.Rental_Period__c = '1 Day';
                    break;
                case '7days':
                    infoObject.Rental_Period__c = '7 Days';
                    break;
                case '14days':
                    infoObject.Rental_Period__c = '14 Days';
                    break;
                case '28days':
                    infoObject.Rental_Period__c = '28 Days';
                    break;
                case 'custom':
                    infoObject.Rental_Period__c = 'Custom';
                    break;
            }
            switch (this.deliveryCpu) {
                case 'delivery':
                    infoObject.Customer_Pick_Up__c = 'Delivery';
                    break;
                case 'cpu':
                    infoObject.Customer_Pick_Up__c = 'Pickup';
                    break;
            }
            return infoObject;
        }
    get rpOptions() {
            return [
                { label: '1 Day', value: '1day' },
                { label: '7 Days', value: '7days' },
                { label: '14 Days', value: '14days' },
                { label: '28 Days', value: '28days' },
                { label: 'Custom', value: 'custom' }
            ];
        }
    get dcOptions() {
            return [
                { label: 'Delivery', value: 'delivery' },
                { label: 'CPU', value: 'cpu' }
            ];
        }
    get isCartContext() {
            return this._context == 'Cart';
        }
    get hasRecordId() {
            return this.recordId ? true : false;
        }
    get cartInfoDisplay() {
            return this.showCartInfo ? 'cart-info-show' : 'cart-info';
        }
    get cartHeader() {
            return this.showHeader ? 'header-show' : 'header';
        }
    get formattedStartMinDate() {
            let startDate = new Date(this.minStartDate);
            startDate.setDate(startDate.getDate() + 1);
            return `${startDate.getMonth() + 1}/${startDate.getDate()}/${startDate.getFullYear()}`;
        }
    get formattedStartDate() {
            let startDate = new Date(this.startDate);
            //let savedStartDate = new Date(this.savedStartDate);
            startDate.setDate(startDate.getDate() + 1);
            //savedStartDate.setDate(savedStartDate.getDate() + 1);

            return `${startDate.getMonth() + 1}/${startDate.getDate()}/${startDate.getFullYear()}`;
            //return `${savedStartDate.getMonth() + 1}/${savedStartDate.getDate()}/${savedStartDate.getFullYear()}`;
        }
    get formattedReturnMinDate() {
            let returnDate = new Date(this.minReturnDate);
            //let savedReturnDate = new Date(this.savedReturnDate);
            returnDate.setDate(returnDate.getDate() + 1);
            //savedReturnDate.setDate(savedReturnDate.getDate() + 1);
            return `${returnDate.getMonth() + 1}/${returnDate.getDate()}/${returnDate.getFullYear()}`;
           // return `${savedReturnDate.getMonth() + 1}/${savedReturnDate.getDate()}/${savedReturnDate.getFullYear()}`;
        }
    get formattedReturnDate() {
            let returnDate = new Date(this.returnDate);
            returnDate.setDate(returnDate.getDate() + 1);
            return `${returnDate.getMonth() + 1}/${returnDate.getDate()}/${returnDate.getFullYear()}`;
        }
    get formattedStartTime() {
            let timeSplit = this.startTime.split(':'); //18:00 = [18, 00]
            var hours = timeSplit[0];
            var minute = timeSplit[1];

            //it is pm if hours from 12 onwards
            var suffix = (hours >= 12) ? 'PM' : 'AM';

            //only -12 from hours if it is greater than 12 (if not back at mid night)
            hours = (hours > 12) ? hours - 12 : hours;

            //if 00 then it is 12 am
            hours = (hours == '00') ? 12 : hours;

            var hrSplit = hours.split('');

            if (hrSplit[0] == 0) {
                hours = hrSplit[1];
            }

            return hours + ':' + minute + suffix;

        }
    get formattedReturnTime() {
            let timeSplit = this.returnTime.split(':'); //18:00 = [18, 00]
            var hours = timeSplit[0];
            var minute = timeSplit[1];

            var suffix = (hours >= 12) ? 'PM' : 'AM';
            hours = (hours > 12) ? hours - 12 : hours;
            hours = (hours == '00') ? 12 : hours;

            return hours + ':' + minute + suffix;
        }
    get formattedDeliveryCpu() {
            let formatted = this.deliveryCpu;
            return formatted.toUpperCase();
        }
    get lineItemsCtrMobClass() {
            return this.recordId ? 'line-items-ctr-mob on-record' : 'line-items-ctr-mob on-pi';
        }
    get lineItemMobClass() {
            return this.recordId ? 'line-items-mob on-record' : 'line-items-mob on-pi';
        }
    }