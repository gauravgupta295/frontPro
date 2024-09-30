import { api, LightningElement, track, wire } from 'lwc';
import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import STATUS from '@salesforce/schema/Order.Status';
import RECORD_TYPE_NAME from '@salesforce/schema/Order.RecordType.Name';
import ORDERING_BRANCH from '@salesforce/schema/Order.Branch__c';
import getOrderAssetColumns from '@salesforce/apex/SBR_3_0_CustomDataTableCmpController.getItemSearchColumns';
import getOrderAssetData from '@salesforce/apex/SBR_3_0_CustomDataTableCmpController.getFilteredOrderItems';
import schedulePickupTicket from '@salesforce/apex/SBR_3_0_API_PickupTicket.getPickupTicketNumberNew';
import sendEmail from '@salesforce/apex/SBR_3_0_EmailClass.sendEmail';
import SetAssetstatus from '@salesforce/apex/SBR_3_0_OrderAssetController.SetAssetstatus';
import ORDER_OBJECT from '@salesforce/schema/Order';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import USER_ID from '@salesforce/user/Id';
import USER_CONTACTID from '@salesforce/schema/User.ContactId';
import USER_EMAIL from '@salesforce/schema/User.Email';
import USER_NAME from '@salesforce/schema/User.Name';
import getPickupTicketDetails from '@salesforce/apex/SBR_3_0_OrderAssetController.getOrderDetailItems'; //SADAPUR, 13808
import * as SBRUtils from 'c/sbrUtils';

const PICKUP_STATUSES = ["ON RENT", "ON RENT PURCHASE"];
const SERVICE_STATUSES = ["ON RENT", "ON RENT PURCHASE", "SCHEDULED FOR PICKUP"];
const MODAL_COLUMN_FIELD_NAMES = ["itemName", "assetNumber", "Quantity", "jobsiteName"];

const assetLineActions = [{
    label: 'View OID',
    name: 'view_asset_line'
},]

export default class Sbr_3_0_orderAssetContainerCmp extends LightningElement {
    // SAL-26261
    @track noDataShowErrorMsg = false;
    @api tabsPanelHeight;
    @api recordId;
    @api objectApiName;
    @api isMobileRequestView = false;
    @track isMobilePickup = false;
    @track isMobileService = false;
    @track isRequestPickup = false;
    @track isRequestService = false;
    @track isRequestView = false;
    showListViews = false;
    showSpinner = false;
    @track isSchedulePickup = false;
    orderId;
    orderStatus;
    @track draftValues = [];
    hasReservation = false;
    orderRecordType;
    isMobile = false;
    @track mobileIsLoading = false;
    rowsOffsetMobile = 0;

    @track data = [];
    columns = [];
    showTable = false;
    rowsOffset = 0;
    batchSize = 7;
    queryParams = '';
    searchKey = '';
    selectedStatus = '';
    mapdata = [];
    requestType;
    modalHeader;
    modalColumns = [];
    @track modalData = [];
    modalOffset = 0;
    viewOid = false;
    showPickupForm;
    showServiceTicketWindow;
    pickupTicket;
    pickupTicketRequestedBy;
    pickupRequestedDate;
    serviceRequestedDate;
    serviceTicketContact;
    orderItemComments;
    //25058
    pickupTicketQuantity;
    pickupTicketItems = [];
    @track showLoading;
    @track pickupComments;
    @track pickupDate;
    serviceProductName;
    serviceMake;
    serviceModel;
    serviceAssetNum;
    serviceSerialNum;
    serviceContractNum;
    serviceYear;
    serviceJobSite;
    branchEmail;
    userId = USER_ID;
    currUser = {}
    currModal;
    modalErrorHeader;
    modalErrorContent;
    orderAssetStatus = '';
    selectedAssetHasOID = false;
    showAssetList = true;
    selectedStatuses = [];
    showRequestScreen;
    @api mobileRequestType;
    lineItemClass;
    requestHeader;
    listClass;
    headerDisplayClass;
    showHeader = true;
    showMobileOID = false;
    cancelButtonLabel = 'Cancel';
    saveButtonLabel = 'Next';
    quantityTableColumns = [];
    @track selectedRows = [];
    @track preSelectedRows = [];
    branch;

    @wire(getObjectInfo, { objectApiName: ORDER_OBJECT })
    orderObjectInfo;

    @wire(getRecord, { recordId: '$recordId', fields: [STATUS, RECORD_TYPE_NAME, ORDERING_BRANCH] })
    wiredOrder({ error, data }) {
        if (error) {
            console.error(error);
        } else if (data) {
            this.orderId = data.id;
            this.orderStatus = data.fields.Status.value;
            this.orderRecordType = getFieldValue(data, RECORD_TYPE_NAME);
            this.hasReservation = (this.orderStatus === 'Reservation Created');
            this.branch = getFieldValue(data, ORDERING_BRANCH);
            if (!this.isMobileRequestView) {
                this.template.querySelector('c-sbr_3_0_order-asset-list-header-cmp').orderStatusChangedHandler(this.orderRecordType);
            }
            if (!this.isMobile) {
                if (this.columns.length < 1) {
                    this.getOrderAssetColumns();
                }
            } else {
                this.getOrderAssetData(this.rowsOffset, false, this.isMobileRequestView);
            }
        }
    }

    @wire(getRecord, { recordId: '$userId', fields: [USER_CONTACTID, USER_NAME, USER_EMAIL] })
    wiredUser({ error, data }) {
        if (data) {
            this.currUser = data;
        } else if (error) {
            this.currUser = undefined;
        }
    }

    @api filterAssets(event) {
        this.rowsOffset = 0;
        this.selectedStatuses = event.detail.filters;
        this.getOrderAssetData(this.rowsOffset, false, false);
    }

    connectedCallback() {

        // this.subscribeToMessageChannel();
        this.isMobile = window.matchMedia('(max-width: 480px)').matches;
        // this.lineItemClass = (this.isMobileRequestView) ? 'line-item slds-p-around_medium request-view-item' : 'line-item slds-p-around_medium';

        if (this.isMobileRequestView) {
            this.lineItemClass = "line-item slds-p-around_medium request-view-item";
            this.requestType = this.mobileRequestType;
            this.requestHeader = (this.mobileRequestType === 'pickup') ? "Schedule Pick Up" : "Create Service Ticket";
            if (this.requestType == 'pickup') {
                this.isRequestPickup = true;
                this.isRequestService = false;
                this.isSchedulePickup = true;
                this.listClass = "item-list-ctr slds-scrollable_y request-list-pickup-ticket";
            }
            if (this.requestType == 'serviceTkt') {
                this.isRequestService = true;
                this.isRequestPickup = false;
                this.isSchedulePickup = false;
                this.requestHeader = 'Create Service Ticket';
                this.listClass = "item-list-ctr slds-scrollable_y request-list";
            }
        } else {
            this.lineItemClass = "line-item slds-p-around_medium";
            this.listClass = "slds-scrollable_y";
        }
    }
    updateShowAssetList(event) {
        this.showAssetList = !event.detail.filtersOpen;
    }

    get assetHeaderDisplayClass() {
        return this.showHeader ? 'show' : 'hide';
    }

    get assetListDisplayClass() {
        return this.showAssetList ? 'show' : 'hide';
    }
    get showRadioButton() {

        let i = this.isRequestService ? true : false;
        return i;
    }
    handleSearch(event) {
        let data = event.detail;

        this.rowsOffset = 0;
        this.searchKey = data.searchKey;
        this.getOrderAssetData(this.rowsOffset, false, false);
    }

    handleAssetStatusChange(event) {
        let data = event.detail;
        if (data) {
            this.selectedStatus = data.selectedStatus;
            this.rowsOffset = 0;

            this.getOrderAssetData(this.rowsOffset, false, false);
        }
    }

    handleRequestSelection(event) {

        this.requestType = event.detail.selectedRequest;
        console.log('## Request type : ' + this.requestType);
        this.isSchedulePickup = false; // make quantity column read only
        if (this.isMobile) {
            this.showRequestScreen = true;
            this.showHeader = false;
            this.showAssetList = false;

            if (this.requestType == 'pickup') {
                this.isRequestPickup = true;
                this.isRequestService = false;
                this.isSchedulePickup = true;
            }
            if (this.requestType == 'serviceTkt') {
                this.isRequestService = true;
                this.isRequestPickup = false;
                this.isSchedulePickup = false;
                this.requestHeader = 'Create Service Ticket';
            }
        } else {
            if (this.requestType == 'pickup' || this.requestType == 'serviceTkt') {
                // if there is an Rent asset, run below. Otherwise show message
                let foundRent = false;
                for (let i = 0; i < this.data.length; i++) {
                    if (PICKUP_STATUSES.includes(this.data[i]?.Status__c)) {
                        foundRent = true;
                    }
                }
                if (foundRent) {
                    let modalTable = this.template.querySelector('[data-id="modal-table"]');
                    //let lightningTable = this.template.querySelector('[data-id="pickup-table"]');
                    let quantityTable = this.template.querySelector('[data-id="quantity-table"]');
                    //modalTable.enableInfiniteLoading = true;
                    //modalTable.isLoading = true;
                    this.modalOffset = 0;
                    this.modalData = [];
                    if (this.requestType == 'pickup') {
                        this.modalHeader = "Schedule Pick Up";
                        this.isSchedulePickup = true; // make quantity column editable
                        //lightningTable.maxRowSelection = null; //this throws an error in the console, but it also removes any value to maxRowSelection which is the whole point of this line, so...
                        if (quantityTable != null || quantityTable != undefined) {
                            quantityTable.maxRowSelection = null; //this throws an error in the console, but it also removes any value to maxRowSelection which is the whole point of this line, so...
                        }
                    } else if (this.requestType == 'serviceTkt') {
                        this.modalHeader = "Create Service Ticket"
                        //lightningTable.maxRowSelection = 1;
                    } else {
                        this.modalHeader = "Unknown Modal";
                    }
                    //this.getOrderAssetColumns();
                    this.getOrderAssetData(this.modalOffset, false, true, 1000);
                    if (modalTable != null || modalTable != undefined) {
                        modalTable.toggleModal();
                    }
                } else {
                    let modalError = this.template.querySelector('[data-id="modal-error"]');
                    this.modalErrorHeader = (this.requestType === 'pickup') ? "Schedule Pick Up" : "Create Service Ticket";
                    this.modalErrorContent = 'This Order has no on rent items.';
                    modalError.toggleModal();
                }
            }
        }
        this.preSelectedRows = [];
    }

    scheduleRequest = async (event) => {

        event.stopPropagation();
        let count = 0;
        let mobileRows = this.data.filter(row => row._isChecked);
        //change for SAL-22395
        if (this.isMobile) {
            if (mobileRows) {
                this.selectedRows = mobileRows;
            }
        } else {
            //let pickupTable = this.template.querySelector('[data-id="pickup-table"]');
            let quantityTable = this.template.querySelector('[data-id="quantity-table"]');
            if (quantityTable) {
                //this.selectedRows = pickupTable.getSelectedRows();
                this.selectedRows = quantityTable.getSelectedRows();
            }
        }
        if (this.selectedRows.length == 0) {
            // show error toast
            this.showNotification('Error', 'Please select at least one asset to navigate forward', 'error');
        } else if (this.saveButtonLabel == 'Schedule Pick Up') {
                console.log('\n@@ scheduling pick up');
                if (!this.pickupDate) {
                    this.showNotification('Error', 'Please select pickup date', 'error');
                    return;
                }
                if (!this.branch) {
                    this.showNotification('Error', 'Please select pickup branch', 'error');
                    return;
                }
                this.showSpinner = true;
                let equipmentsArr = [];
                this.selectedRows.forEach((item) => {
                    let equipments = {};
                    if (item.isEditableFlag) {
                        equipments['quantity'] = item.pickupQuantity;
                    } else {
                        equipments['quantity'] = item.Quantity;
                    }
                    equipments['equipmentNumber'] = item.assetNumber;
                    equipments['lineItemId'] = item.Id;
                    equipmentsArr.push(equipments);
                });
                let pickupDetails = {
                    'pickupDate': this.pickupDate,
                    'requestedById': this.userId,
                    'equipments': equipmentsArr,
                    'comments': this.pickupComments
                };
                this.schedulePickupTicketHandler(JSON.stringify(pickupDetails));
            if (!this.isMobile) {
                this.template.querySelector('[data-id="modal-table"]').toggleModal();
            }
                if (this.isMobile) {
                    this.isMobileRequestView = false;
                    this.isMobilePickup = false;
                    this.isRequestView = false;
                    this.rowsOffset = 0;
                    this.data = [];
                    this.getOrderAssetData(0, false, this.isMobileRequestView);
                    this.showAssetList = true;
                    this.showRequestScreen = false;
                this.isSchedulePickup = false;
                }
            }
        else {
            if (this.requestType == 'pickup') {
                if (this.isMobile) {
                    this.isRequestView = true;
                    this.isMobilePickup = true;
                    this.isMobileService = false;
                } else {
                       this.showPickupForm = true;
                }
                this.saveButtonLabel = 'Schedule Pick Up';
                this.requestHeader = 'Schedule Pick Up';
                this.showAssetList = false;
            } else {

                let modalTable = this.template.querySelector('[data-id="modal-table"]');
                let serviceTicketModal = this.template.querySelector('[data-id="service-ticket-modal"]');
                this.currModal = serviceTicketModal;
                if (this.isMobile) {
                    this.isRequestView = true;
                    this.isMobileService = true;
                    this.isMobilePickup = false;
                    this.isRequestService = false;
                } else {
                    this.showServiceTicketWindow = true;
                }

                this.saveButtonLabel = 'Create Service Ticket';
                let selectedAsset = this.selectedRows[0];
                if (selectedAsset.Product2) {
                    this.serviceProductName = selectedAsset.Product2.Name;
                }
                if (selectedAsset.SBQQ__Asset__r) {
                    this.serviceMake = selectedAsset.SBQQ__Asset__r.SM_PS_Make__c;
                    this.serviceModel = selectedAsset.SBQQ__Asset__r.SM_PS_Model__c;
                    this.serviceAssetNum = selectedAsset.SBQQ__Asset__r.SM_PS_Asset_Id__c;
                    this.serviceSerialNum = selectedAsset.SBQQ__Asset__r.SM_PS_Serial_Number__c;
                    this.serviceYear = selectedAsset.SBQQ__Asset__r.SM_PS_Model_Year__c;
                }
                if (selectedAsset.Order) {
                    this.serviceContractNum = selectedAsset.Order.ContractId;

                    if (selectedAsset.Order.Jobsite__r) {
                        this.serviceJobSite = selectedAsset.Order.Jobsite__r.JobsiteName__c;
                    }
                    if (selectedAsset.Order.Branch_Email__c != null) {
                        this.branchEmail = selectedAsset.Order.Branch_Email__c;
                    } else if (selectedAsset.Order.Branch__r) {
                        this.branchEmail = selectedAsset.Order.Branch__r.Branch_Email__c;
                    }
                }
                
                if(!this.isMobile)
                {
                    
                    serviceTicketModal.toggleModal();
                    modalTable.toggleModal();
                }
            }
            this.cancelButtonLabel = 'Back';
        }
    }

    schedulePickupTicketHandler(pickupDetails) {
        schedulePickupTicket({
            pickupDetails: pickupDetails
        })
            .then((data) => {
                console.log('pickup ticket response -> ' + data);
                this.showSpinner = false;
                if (data.includes('error')) {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            message: `Failed to create Pickup Ticket. Please reach out to Support team if issue persists.`,
                            variant: 'error',
                        }),
                    );
                } else {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success',
                            message: `Pickup Ticket created successfully.`,
                            variant: 'success',
                        }),
                    );
                }
            })
            .catch((error) => {
                console.error('Pickup Ticket handled promise error ' + error);
            });
    }
    setStatus() {
        let orderItemRecordsParam = JSON.stringify(this.mapdata);
        let pickupCommentParam = this.pickupComments;
        let pickupDateParam = this.pickupDate;
        let loggedinUserParam = this.userId;
        SetAssetstatus({
            orderItemRecords: orderItemRecordsParam,
            pickupComment: pickupCommentParam,
            pickupDate: pickupDateParam,
            loggedInUser: loggedinUserParam
        })
            .then(() => {
                console.log('Output from setStatus ');
            }).catch((error) => {
                console.log('Error log');
                console.error(error);
            });

    }


    sendServiceTicket = (event) => {
        try {
            event.stopPropagation();
            let serviceTicketModal = this.template.querySelector('[data-id="service-ticket-modal"]');
            
            const childCustomLookupCmp = this.template.querySelector('[data-id="search-contact-lookup"]');

            let proceedFurther = childCustomLookupCmp.validateInput();
            console.log('proceedFurther -> ' + proceedFurther);
            if (proceedFurther === false) {
                return;
            }

            if (!this.isMobile) {
                serviceTicketModal.toggleModal();
            }

            this.showServiceTicketWindow = false;

            let emailDetails = {
                addContact: "",
                toAddress: [this.branchEmail],
                frm: this.currUser.fields.Email.value,
                bcc: "",
                subject: 'Service Requested for ' + this.serviceContractNum + ', ' + this.serviceAssetNum,
                body: (this.currUser.fields.Name.value + ' has submitted ' + this.serviceAssetNum + ' for Service.  Please see below for details:<br>' +
                    '<br>Customer Contact: ' + this.serviceTicketContact +
                    '<br>Comments: ' + this.pickupComments +
                    '<br>Product Name: ' + this.serviceProductName +
                    '<br>Make: ' + this.serviceMake +
                    '<br>Model: ' + this.serviceModel +
                    '<br>Asset #: ' + this.serviceAssetNum +
                    '<br>Serial #: ' + this.serviceSerialNum +
                    '<br>Contract #: ' + this.serviceContractNum +
                    '<br>Year: ' + this.serviceYear +
                    '<br>Job Site: ' + this.serviceJobSite),
                recId: this.serviceContractNum,
                frmName: this.currUser.fields.Name.value
            };

            this.showSpinner = true;
            sendEmail({
                emailStr: JSON.stringify(emailDetails)
            })
                .then(() => {
                    this.showNotification('Success!', 'Email Sent Successfully!', 'success');
                    this.showSpinner = false;
                    if (this.isMobile) {
                        this.isMobileRequestView = false;
                        this.isMobilePickup = false;
                        this.isRequestService = false;
                        this.isRequestView = false;
                        this.rowsOffset = 0;
                        this.data = [];
                        this.getOrderAssetData(0, false, this.isMobileRequestView);
                        this.showHeader = true;
                        this.showAssetList = true;
                        this.showRequestScreen = false;
                    }

                }).catch((error) => {
                    this.showNotification('Error', error.body.message, 'error');
                    this.showSpinner = false;
                });
        } catch (e) {
            this.showNotification('Error', e.body.message, 'error');
        }
    }
    handleRequestCancelButton() {
        const statusChangeEvent = new CustomEvent('cancelrequest', {});
        this.dispatchEvent(statusChangeEvent);
    }
    handleRequestPreviousButtonMobile() {

        this.showHeader = true;
        this.isMobile = true;
        this.isRequestView = false;
        this.isMobilePickup = false;
        this.showAssetList = true;
        //this.isSchedulePickup = false;
        this.saveButtonLabel = 'Previous Screen'
    }

    cancelRequest() {
        this.showHeader = true;
        this.showAssetList = true;
        this.isSchedulePickup = false;
        //this.isSchedulePickup=true;
        this.showRequestScreen = false;
    }

    loadMoreItems(event) {
        let datatableTarget = event.target;
        datatableTarget.isLoading = true;
        this.getOrderAssetData(this.rowsOffset, true, false);
    }

    loadMoreModalItems(event) {
        let datatableTarget = event.target;
        datatableTarget.isLoading = true;
        this.getOrderAssetData(this.modalOffset, true, true);
    }

    loadMoreDataMobile(event) {
        if (event.target.scrollTop > event.target.scrollHeight - (event.target.offsetHeight) && !this.mobileIsLoading) {
            this.mobileIsLoading = true;
            new Promise(
                (resolve, reject) => {
                    setTimeout(() => {
                        this.getOrderAssetData(this.rowsOffset, true, false);
                        resolve();
                    }, 3000);
                }).then(
                    () => this.mobileIsLoading = false
                );
        }
    }

    handleQuantityEdit(event) {
        console.log('##'+JSON.stringify(event.detail));
        let draftTableValues = this.template.querySelector('[data-id="quantity-table"]');
        let recId = event.detail.recordId;
        let pickupQuantity = event.detail.value;

        this.modalData.forEach(curVal => {
            if (curVal.Id == recId) {
                if (curVal.createdQuantity >= pickupQuantity) {
                    curVal.pickupQuantity = event.detail.value;
                    this.template.querySelector('[data-id="modal-table"]').enableSaveBtn();
                } else {
                    this.template.querySelector('[data-id="modal-table"]').disableSaveBtn();
                }
            }
        });

        let selectedRecords = this.template.querySelector('[data-id="quantity-table"]').getSelectedRows();
        selectedRecords.forEach(currentItem => {
            if (recId == currentItem.Id) {
                //currentItem.Quantity = event.detail.value;
                currentItem.pickupQuantity = event.detail.value;
            }
        });
        console.log('### ModalData',JSON.stringify(this.modalData));
        console.log('### SelectedData',JSON.stringify(this.selectedRows));
    }

    async handleEdit(event) {
        console.log('+++','called event');
        draftTableValues.forEach(curVal => {
            const objWithIdIndex = this.draftValues.findIndex((obj) => obj.Id === curVal.Id);
            if (objWithIdIndex > -1) {
                this.draftValues.splice(objWithIdIndex, 1);
            }
            if (curVal.Quantity < 1) {
                this.showNotification('Error',
                    'Quantity can not be less than One',
                    'error');
                return;
            }
            this.draftValues.push(curVal);
            this.draftValues[curVal.Id] = curVal.Quantity;
        });
        selectedRecords.forEach(currentItem => {
            if (this.draftValues[currentItem.Id] && this.draftValues[currentItem.Id] >= 1) {
                currentItem.Quantity = this.draftValues[currentItem.Id];
            }
        });
    }
    onRowSelection(event) {
        let selectedRows = [];
        selectedRows = event.detail.selectedRows;
        if (selectedRows.length === this.modalData.length) {
            let selectedIds = [];
            selectedRows.forEach(e => {
                selectedIds.push(e.Id);
            })
            this.preSelectedRows = selectedIds;
            this.modalData.forEach(function (e) {
                if (e.isEditableFlag) {
                    e.pickupQuantity = e.createdQuantity;
                }
            });
            this.modalData = [...this.modalData];
        }
        if (selectedRows.length === 0) {
            this.preSelectedRows = [];
            this.modalData.forEach(function (e) {
                if (e.isEditableFlag) {
                    e.pickupQuantity = 0;
                }
            });
            this.modalData = [...this.modalData];
        }
    }
    decrement(event) {
        const itemNum = event.target.value;
        const filteredNumbers = this.data.map((element) => {
            if (element.assetNumber == itemNum) {
                if (element.Quantity > 1) {
                    element.Quantity -= 1;
                }
            }
        });
    }
    increment(event) {
        const itemNum = event.target.value;
        const filteredNumbers = this.data.map((element) => {
            if (element.assetNumber == itemNum) {
                element.Quantity += 1;
            }
        });
    }
    handlePickupQuantityChange(event) {
        let assetId = event.currentTarget.dataset.id;
        console.log('asset',assetId);
        let quantValue = event.target.value;
        console.log('quant',quantValue);
        this.data.forEach(function (e) {
            if (e.Id == assetId) {
                e.pickupQuantity = quantValue;
            }
        })
    }
    getOrderAssetColumns() {
        getOrderAssetColumns()
            .then((data) => {
                if (!this.isMobile) {
                    let orderAssetCols = data.filter(col => col.Context__c === 'Order Asset');
                    orderAssetCols.sort((a, b) => a.Order__c - b.Order__c);
                    orderAssetCols.forEach(col => {
                        let colItem = {};
                        colItem.label = col.Label;
                        colItem.fieldName = col.Field_Name__c;
                        colItem.hideDefaultActions = true;
                        colItem.sortable = col.IsSortable__c;
                        colItem.type = col.Type__c ? col.Type__c : 'text';
                        colItem.wrapText = true;
                        if (col.fixedWidth__c) colItem.initialWidth = col.fixedWidth__c;

                        if( (this.orderRecordType !='Reservation Order' && this.orderRecordType !='Locked Reservation Order') || 
                            (col.Field_Name__c != 'status' && (this.orderRecordType =='Reservation Order' || this.orderRecordType =='Locked Reservation Order') )
                         
                         ){
                            this.columns.push(colItem);
                            this.queryParams += col.Field_Name__c + ',';
                        }
                        
                    });
                    let modalCols1 = this.columns.filter((col) => MODAL_COLUMN_FIELD_NAMES.includes(col.fieldName));
                    console.log('## colum'+JSON.stringify(modalCols1));
                    const modalsCols2 = JSON.parse(JSON.stringify(modalCols1));
                    modalsCols2.forEach((col) => {
                        col.sortable = false;
                    });
                    this.modalColumns = modalsCols2;
                    let quantityColumn;
                    const testCol = this.modalColumns;
                    testCol.forEach((col) => {
                        col.sortable = false;
                        if (col.fieldName == 'Quantity') {
                            col.type = 'customQuantity';

                            col.typeAttributes = {
                                isEditableFlag: {
                                    fieldName: 'isEditableFlag'
                                },
                                itemRecord: {
                                    fieldName: 'itemRecord'
                                },
                                pickupQuantity: {
                                    fieldName: 'pickupQuantity'
                                },
                                createdQuantity: {
                                    fieldName: 'createdQuantity'
                                }
                            }
                            quantityColumn = col;
                        }
                    });
                    let quantityTable = [];
                    console.log('Entered quan 243');
                    if (quantityColumn) {
                        quantityTable = testCol.filter((e) => {
                            return e.fieldName != 'Quantity'
                        });
                        quantityTable.push(quantityColumn);
                    }


                    this.quantityTableColumns = quantityTable;
                    console.log('##new12456', JSON.stringify(this.quantityTableColumns));
                    //changes end
                    this.columns.forEach((col) => {
                        col.sortable = false;
                        col.editable = false;
                    });
                    this.showTable = true;
                    this.getOrderAssetData(this.rowsOffset, false, false);

                    this.columns.push({
                        type: 'action',
                        typeAttributes: {
                            rowActions: assetLineActions,
                            menuAlignment: 'right'
                        }
                    });
                }
            })
            .catch((error) => {
                console.error(error);
            });
    }

    getOrderAssetData(offset, isLoadingMoreItems, isModal, batchSize = 21) {
        let whereClause = '';
        if (this.selectedStatus) {
            whereClause = `${whereClause} AND Status__c = '${this.selectedStatus}'`;
        } else if (this.selectedStatuses.length > 0) {
            let statusClause = " AND Status__c IN ('" + this.selectedStatuses.join("', '") + "') ";
            whereClause += statusClause;
        } else if (isModal) {
            let statuses = (this.requestType === 'pickup' || this.requestType === 'serviceTkt') ? PICKUP_STATUSES : SERVICE_STATUSES;
            let stringStatuses = statuses.map(status => {
                return "'" + status + "'"
            });
            let statusString = stringStatuses.join(", ");
            whereClause = `${whereClause} AND Status__c IN (${statusString})`;
        }
        getOrderAssetData({
            orderId: this.orderId,
            offset: null,
            batchSize: null,
            searchKey: this.searchKey,
            whereClause: whereClause
        })
            .then((data) => {
                // SAL-26261 START
                if (data.length == 0 && this.isMobileRequestView) {
                    this.noDataShowErrorMsg = true;
                } else {
                    this.noDataShowErrorMsg = false;

                    let tempData = JSON.parse(JSON.stringify(data));
                    // change for SAL-16762
                    data = tempData.map(row => {
                        if (row.Product2.Bulk_Item__c) {
                            return {
                                ...row,
                                Quantity: ((row.Quantity ? row.Quantity > 0 : false) && (row.Status_Created_Qty__c ? row.Status_Created_Qty__c > 0 : false)) ? (row.Status_Created_Qty__c) : (row.Quantity ? row.Quantity : 0),
                                itemRecord: row.Id,
                                assetName: row.SBQQ__Asset__r?.Name,
                                itemName: row.Product2.Name,
                                assetNumber: row.Product2.Bulk_Item__c ? row.Product2.itemNumberUsedByReservationsRentalOut__c : row.SBQQ__Asset__r?.Name,
                                jobsiteName: row.Order.Jobsite__r?.JobsiteName__c,
                                isEditableFlag: row.Product2.Bulk_Item__c && !row.Product2.IsSerialized ? true : false,
                                createdQuantity: ((row.Quantity ? row.Quantity > 0 : false) && (row.Status_Created_Qty__c ? row.Status_Created_Qty__c > 0 : false)) ? (row.Status_Created_Qty__c) : (row.Quantity ? row.Quantity : 0),
                                pickupQuantity: 0,
                                status: row.Status__c, // SF-5881
                                hasOID: (this.orderRecordType === 'Contract Order' && row.Status__c === "SCHEDULED FOR PICKUP")
                            };
                        } else {
                            return {
                                ...row,
                                itemRecord: row.Id,
                                assetName: row.SBQQ__Asset__r?.Name,
                                itemName: row.Product2.Name,
                                assetNumber: row.Product2.Bulk_Item__c ? row.Product2.itemNumberUsedByReservationsRentalOut__c : row.SBQQ__Asset__r?.Name,
                                jobsiteName: row.Order.Jobsite__r?.JobsiteName__c,
                                isEditableFlag: row.Product2.Bulk_Item__c && !row.Product2.IsSerialized ? true : false,
                                createdQuantity: ((row.Quantity ? row.Quantity > 0 : false) && (row.Status_Pick_Created_Qty__c ? row.Status_Pick_Created_Qty__c > 0 : false)) ? (row.Quantity - row.Status_Pick_Created_Qty__c) : (row.Quantity ? row.Quantity : 0),
                                pickupQuantity: 0,
                                status: row.Status__c, // SF-5881
                                hasOID: (this.orderRecordType === 'Contract Order' && row.Status__c === "SCHEDULED FOR PICKUP")
                            };
                        }

                    })
                    if (!this.isMobile) {
                        let infiniteLoadingStatus = (data.length >= this.batchSize);

                        if (isModal) {
                            this.template.querySelector('[data-id="modal-table"]').enableInfiniteLoading = infiniteLoadingStatus;

                            this.modalData = (isLoadingMoreItems) ? this.modalData.concat(data) : data;
                            this.modalOffset += data.length;
                            this.template.querySelector('[data-id="modal-table"]').isLoading = false;
                        } else {
                            this.template.querySelector('c-sbr_3_0_custom-data-table-cmp').enableInfiniteLoading = infiniteLoadingStatus;

                            this.data = (isLoadingMoreItems) ? this.data.concat(data) : data;
                            this.rowsOffset += data.length;

                            this.template.querySelector('c-sbr_3_0_order-asset-list-header-cmp').searchCompletionHandler(this.rowsOffset);
                            this.template.querySelector('c-sbr_3_0_custom-data-table-cmp').isLoading = false;
                        }
                        console.log('###'+this.modalData);
                    } else {
                        //mobile
                        this.data = (isLoadingMoreItems) ? this.data.concat(data) : data;
                        this.rowsOffset += data.length;
                        this.template.querySelector('c-sbr_3_0_order-asset-list-header-cmp').searchCompletionHandler(this.rowsOffset);
                    }
                }
                // SAL-26261 END
            })
            .catch((error) => {
                console.log(error);
            });
    }

    //sorting needs to be refactored
    defaultSortDirection = 'asc';
    sortDirection = 'asc';
    sortedBy;

    sortBy(field, reverse, primer) {
        const key = primer ?
            function (x) {
                return primer(x[field]);
            } :
            function (x) {
                return x[field];
            };

        return function (a, b) {
            a = key(a);
            b = key(b);
            return reverse * ((a > b) - (b > a));
        };
    }

    onHandleSort(event) {
        const {
            fieldName: sortedBy,
            sortDirection
        } = event.detail;
        const cloneData = [...this.data];

        cloneData.sort(this.sortBy(sortedBy, sortDirection === 'asc' ? 1 : -1));
        this.data = cloneData;
        this.sortDirection = sortDirection;
        this.sortedBy = sortedBy;
    }

    handleRowAction(event) {
        this.viewOid = true;
        const action = event.detail.action;
        const row = event.detail.row;
        switch (action.name) {
            case 'view_asset_line':
                this.assetId = row.Id;
                console.log('\n @@ assetId =' + this.assetId);
                console.log('\n @@ row.Id =' + row.Id);
                for (let i = 0; i < this.data.length; i++) {
                    if (this.data[i].Id == this.assetId) {
                        this.selectedAssetHasOID = false;
                        console.log('\n @@row data = ' + JSON.stringify(this.data[i],null,2));
                        if (this.data[i].SBQQ__Asset__r != null && this.data[i].Order_Item_Detail__c != null) {
                            this.selectedAssetHasOID = true;
                        } else if (this.data[i].Product2.Bulk_Item__c && this.data[i].Order_Item_Detail__c != null) {
                            this.selectedAssetHasOID = true;
                        } else {
                            this.selectedAssetHasOID = false;
                        }
                        //25058, SADAPUR
                        /* if (this.data[i].Order_Item_Detail__r != null) {
                            console.log('orderItemDetail_SA->'+JSON.stringify(this.data[i],null,2));
                            this.pickupTicket = this.data[i].Order_Item_Detail__r.Pickup_Ticket__c;
                            //this.pickupTicketRequestedBy = this.data[i].Order_Item_Detail__r?.Pickup_Ticket_Requested_By__r?.Name;
                            this.pickupTicketRequestedBy = this.data[i].Order_Item_Detail__r?.Pickup_Ticket_Request_By__c; //13808
                            if (!this.data[i].Order_Item_Detail__r.Pickup_Requested_Date__c) {
                                this.pickupRequestedDate = new Date(this.data[i].Order_Item_Detail__r.Pickup_Requested_Date__c);
                            } else {
                                this.pickupRequestedDate = this.data[i].Order_Item_Detail__r.Pickup_Requested_Date__c;
                            }
                            this.orderItemComments = this.data[i].Order_Item_Detail__r.Order_Item_Comments__c;
                            this.pickupTicketQuantity = this.data[i].Order_Item_Detail__r.Created_Qty__c;
                        } */
                        // else {
                        //13808, SADAPUR
                        //let orderItemDtls = [];
                        getPickupTicketDetails({
                            orderLineItemId: this.assetId
                        }).then((result) => {
                            let tempOrdeItemDtlsData = JSON.parse(JSON.stringify(result));
                            console.log('\n details =' + JSON.stringify(result, null, 2));
                            this.pickupTicketItems = tempOrdeItemDtlsData.map(row => {
                                this.pickupTicket = row.Pickup_Ticket__c;
                                //this.pickupTicketRequestedBy = row.Pickup_Ticket_Requested_By__r?.Name;
                                this.pickupTicketRequestedBy = row.Pickup_Ticket_Request_By__c; //138080
                                this.pickupRequestedDate = row.Pickup_Requested_Date__c;
                                this.orderItemComments = row.Order_Item_Comments__c;
                                this.selectedAssetHasOID = true;
                                this.pickupTicketQuantity = row.Created_Qty__c;
                                return {
                                    ...row
                                };
                            });
                            console.log('\n pickupTicketItems =' + JSON.stringify(this.pickupTicketItems, null, 2));
                        })
                            .catch((error) => {
                                console.log(error);
                            });
                        //}
                    }
                }
                this.modalHeader = "Order Item Details";
                this.template.querySelector("c-sbr_3_0_modal-cmp").toggleModal();
                break;
        }
    }
    handleMobileOIDClick(event) {
        this.assetId = event.target.dataset.value;
        let asset = this.data.filter(obj => {
            return obj.Id === this.assetId
        });
        this.selectedAssetHasOID = false;
        this.selectedAssetHasOID = asset[0].hasOID ? true : false;
        getPickupTicketDetails({
            orderLineItemId: asset[0].Id
        }).then((result) => {
            let tempOrdeItemDtlsData = JSON.parse(JSON.stringify(result));
            this.pickupTicketItems = tempOrdeItemDtlsData.map(row => {
                this.pickupTicket = row.Pickup_Ticket__c;
                this.pickupTicketRequestedBy = row.Pickup_Ticket_Request_By__c; //138080
                this.pickupRequestedDate = row.Pickup_Requested_Date__c;
                this.orderItemComments = row.Order_Item_Comments__c;
                this.selectedAssetHasOID = true;
                this.pickupTicketQuantity = row.Created_Qty__c;
                return {
                    ...row
                };
            });
            this.showMobileOID = true;
        })
            .catch((error) => {
                console.log(error);
            });
        // }
    }
    closeMobileOID() {
        this.showMobileOID = false;
        this.clearOIDFields();
    }
    populateOIDFields(oid) {
        this.pickupTicket = oid.Pickup_Ticket__c;
        this.pickupTicketRequestedBy = oid.Pickup_Ticket_Request_By__c; //13808
        if (!oid.Pickup_Requested_Date__c) {
            this.pickupRequestedDate = new Date(oid.Pickup_Requested_Date__c);
        } else {
            this.pickupRequestedDate = oid.Pickup_Requested_Date__c;
        }
        if (!oid.Service_Requested_Date__c) {
            this.serviceRequestedDate = new Date(oid.Service_Requested_Date__c);
        } else {
            this.serviceRequestedDate = oid.Service_Requested_Date__c;
        }
        this.serviceTicketContact = oid.Service_Ticket_Contact__r?.Name;
        this.orderItemComments = oid.Order_Item_Comments__c;
    }
    clearOIDFields() {
        this.pickupTicket = "";
        this.pickupTicketRequestedBy = "";
        this.pickupRequestedDate = "";
        this.serviceRequestedDate = "";
        this.serviceTicketContact = "";
        this.orderItemComments = "";
        this.selectedAssetHasOID = false;
    }
    handleSelectAll(event) {
        let r = event.target;
        this.data.forEach(function (e) {
            e._isChecked = r.checked;
        })
        if (r.checked) {
            this.data.forEach(function (e) {
                if (e.isEditableFlag) {
                    e.pickupQuantity = e.createdQuantity;
                }

            })
        }
        if (!r.checked) {
            this.data.forEach(function (e) {
                if (e.isEditableFlag) {
                    e.pickupQuantity = 0;
                }
            })
        }
    }
    handleRowSelection(event) {
        let r = event.target;
        if (!r.checked) {
            this.template.querySelector(".selectAll").checked = false;
        }
        let i = this.data.findIndex(e => e.Id === r.value);
        this.data[i]._isChecked = r.checked;
    }
    handlePickUpBack() {
        this.showPickupForm = false;
        if (this.cancelButtonLabel != 'Back') {
            console.log('Entered back func');
            this.pickupDate = null;
            this.pickupComments = null;
        }
        this.cancelButtonLabel = 'Cancel';
        this.saveButtonLabel = 'Next';
        let selectedIds = [];
        this.selectedRows.forEach(e => {
            selectedIds.push(e.Id);
        })
        this.preSelectedRows = selectedIds;
    }

    handleServiceTktBack() {
        let modalTable = this.template.querySelector('[data-id="modal-table"]');
        let serviceTicketModal = this.template.querySelector('[data-id="service-ticket-modal"]');
        serviceTicketModal.toggleModal();
        modalTable.toggleModal();
        this.showPickupForm = false;
        this.cancelButtonLabel = 'Cancel';
        this.saveButtonLabel = 'Next';
        this.pickupComments = '';
    }
    handlePickupBranch(event) {
        if (SBRUtils.isEmpty(event.detail.selectedRecord)) {
            this.branch = '';
        } else {
            this.branch = event.detail.selectedRecord.Id;
        }
    }
    handleCustomerContact(event) {
        if (event.detail.selectedRecord !== undefined) {
            this.serviceTicketContact = event.detail.selectedRecord.Id;
        } else {
            this.serviceTicketContact = '';
        }
    }
    updateComments(event) {
        this.pickupComments = event.detail.value;
    }

    upadatepickupDate(event) {
        this.pickupDate = event.detail.value;
    }
    showNotification(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(evt);
    }
    get branchWhere() {
        return 'RecordType.Name = \'Branch\'';
    }
    }