import { LightningElement,wire } from 'lwc';
import LightningModal from 'lightning/modal';
import { NavigationMixin } from 'lightning/navigation'; //SF -5409

import Manage_Website_Users_Title from '@salesforce/label/c.SBR_3_0_Manage_Website_Users_Title';
import SBR_3_0_Manage_Website_Users_Placeholder_For_Global_Action from '@salesforce/label/c.SBR_3_0_Manage_Website_Users_Placeholder_For_Global_Action';
import FORM_FACTOR from "@salesforce/client/formFactor";
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import searchWebsiteUser from '@salesforce/apex/SBR_3_0_ManageWebsiteUserController.searchWebsiteUser';
import ManageWebsiteUsersColumns from '@salesforce/apex/SBR_3_0_ManageWebsiteUserController.getManageWebsiteUsersColumns';
import searchUserEmail from '@salesforce/apex/SBR_3_0_ManageWebsiteUserController.searchUserEmail';

export default class SBR_3_0_AccountManagementCRProcessActions extends NavigationMixin(LightningModal) {
    isLoaded = true; /* This variable is used to control loader in the component */
    deviceTypeDesktp; /* This variable is used to determine the device that component is opened as Desktop */
    deviceTypeTablet; /* This variable is used to determine the device that component is opened as Tablet */
    deviceTypeMobile; /* This variable is used to determine the device that component is opened as Mobile */

    AccountResponse; /* This variable is used to store all the Results that need to be displayed on the page */
    AccountColumns; /* This variable is used to store all the Headers that need to be displayed in the Data Table */
    AccountResults; /* This variable is used to store all Results  that need to be displayed in the Data Table */
    sortBy = 'name'; /* This variable is used to control the sorting field in the Data Table */
    defaultSortDirection = 'asc'; /* This variable is used to control the default sorting direction in the Data Table */
    sortDirection = 'asc'; /* This variable is used to control the sorting direction in the Data Table */

    isDisabled = true; /* This variable is used to control infinite loading Enable/Disabled*/

    ShowSearchInput = true; /* This variable is used to control visibility of the User Invite screen */
    ShowSearchResults = false; /* This variable is used to control visibility of the User Results screen */
    ShowSearchResultsHeader = false; /* This variable is used to control visibility of the User Results Header screen */
    ShowCancel = true; /* This variable is used to control visibility of the User Confirmation screen */

    items = []; /* This variable is used to store the list of User record that are fetched from the Account Number as copy */
    recordCount = 20; /* This variable is used to store the Records Count which will be used for loging more data in Data table*/
    totalRecountCount = 0; /* This variable is used to store the Total Records Count which will be used for loging more data in Data table*/
    targetDatatable; /* This variable is used to load the Data table*/
    LoadMore = true; /* This variable is used to control Infinite loading in the Data Table*/

    SearchEmail; /* This variable is used to store Email from the list of emails shown on page*/
    DataToProcess; /* This variable is used to store users with respect to Account Type*/
    UsersWithName; /* This variable is used to store all the Emails of Users that need to be displayed on the page */
    UsersWithSizeOver25 = true; /* This variable is used to control the visibility of no of records exceeded on page */
    NameSearchString; /* This variable is used to store Search String from the Page*/
    ShowSearchEmailResults = false; /* This variable is used to control the visibility of list of Emails from search string on page */
    stylesLoaded = false;
    searchEmailInputValue = '';
    errorMessage;
    isCashProfile = false;
    isResultEmpty= false;
    label = {
        Manage_Website_Users_Title,
        SBR_3_0_Manage_Website_Users_Placeholder_For_Global_Action
    };

    connectedCallback() {
        if (FORM_FACTOR === 'Large') {
            this.deviceTypeDesktp = true;
        } else if (FORM_FACTOR === 'Medium') {
            this.deviceTypeTablet = true;
        } else if (FORM_FACTOR === 'Small') {
            this.deviceTypeMobile = true;
        }
    }

    searchUserEmailWithName(event) {
        this.isLoaded = false;
        this.NameSearchString = this.template.querySelector('lightning-input[data-name="SearchString"]').value;
        searchUserEmail({ SearchString: this.NameSearchString })
            .then((data) => {
                this.UsersWithName = data.slice(0, 25);
                if (data.length > 25) {
                    this.UsersWithSizeOver25 = true;
                } else {
                    this.UsersWithSizeOver25 = false;
                }
                this.ShowSearchEmailResults = true;
                this.isDisabled = true;
                this.isLoaded = true;
                this.ShowSearchInput = true;
                this.isResultEmpty= false;
            })
            .catch((error) => {
                this.error = error;
                this.ShowSearchInput = true;
                this.ShowSearchEmailResults = false;
                this.isResultEmpty = true;
                this.isLoaded = true;
                this.errorMessage = error.body.message;
                console.log("Error");
            });
    }

    handleSearchChange(event) {
        this.searchEmailInputValue = event.detail.value;
        this.isDisabled = false;
    }

    handleSortdata(event) {
        this.sortBy = event.detail.fieldName;
        this.sortDirection = event.detail.sortDirection;
        this.sortMWUData(event.detail.fieldName, event.detail.sortDirection);
    }
    sortMWUData(fieldname, direction) {
        let parseData;
        parseData = JSON.parse(JSON.stringify(this.AccountResults));
        let keyValue = (a) => {
            return a[fieldname];
        };
        let isReverse = direction === 'asc' ? 1 : -1;
        parseData.sort((x, y) => {
            x = keyValue(x) ? keyValue(x) : '';
            y = keyValue(y) ? keyValue(y) : '';

            return isReverse * ((x > y) - (y > x));
        });
        this.AccountResults = parseData;
    }

    handleSearchEmailChange(event) {
        const email = event.currentTarget.getAttribute('data-value');
        this.SearchEmail = email;
        this.isLoaded = false;
        this.ShowSearchInput = false;
        this.ShowSearchEmailResults = false;
        this.createData();
    }

    createColumns(Columns) {
        var ColumnsMap = [];
        for (var key in Columns) {
            var values = Columns[key];
            var Label = values[0];
            var APIName = values[1];
            var DataType = values[2];
            if (APIName == 'AccountName') {
                ColumnsMap.push({
                    label: Label,
                    fieldName: 'nameUrl',
                    type: 'url',
                    value: Label,
                    sortable: 'true',
                    typeAttributes: { label: { fieldName: APIName }, target: '_self' }
                });
            } else {
                if (DataType == 'DATE') {
                    ColumnsMap.push({
                        label: Label,
                        fieldName: APIName,
                        type: 'date',
                        sortable: 'true',
                        value: Label,
                        typeAttributes: {
                            month: 'numeric',
                            day: 'numeric',
                            year: 'numeric',
                            day: '2-digit',
                            month: '2-digit'
                        }
                    });
                } else {
                    ColumnsMap.push({
                        label: Label,
                        fieldName: APIName,
                        type: 'text',
                        value: Label,
                        sortable: 'true'
                    });
                }
            }
        }
        this.AccountColumns = ColumnsMap;
    }

    createData() {
        searchWebsiteUser({ SearchEmail: this.SearchEmail })
            .then((RecordsData) => {
                this.AccountResponse = RecordsData;
                this.ShowSearchResultsHeader = true;
                let AccType;
                this.DataToProcess = [];
                if (RecordsData.accountType == 'credit') {
                    AccType = 'Credit Accounts Search';
                    this.DataToProcess = RecordsData.CreditAccountSearchResults;
                    ManageWebsiteUsersColumns({ Category: AccType })
                        .then((Columns) => {
                            this.createColumns(Columns);
                            let nameUrl;
                            this.AccountResults = this.DataToProcess.map((row) => {
                                if (`${row.Id}` != 'undefined') {
                                    nameUrl = `/${row.Id}`;
                                } else {
                                    nameUrl = `/${row.AccountName}`;
                                }
                                console.log('nameUrl' + nameUrl);
                                return { ...row, nameUrl };
                            });
                            this.totalRecountCount = this.AccountResults.length;
                            var itemsFromRes = [];
                            itemsFromRes = this.AccountResults;
                            this.items = itemsFromRes;
                            this.AccountResults = this.items.slice(0, this.recordCount);

                            if (this.AccountResults.lengt > 20) {
                                this.LoadMore = true;
                            } else {
                                this.LoadMore = false;
                            }
                            this.isDisabled = true;
                            this.ShowSearchResults = true;
                            this.isLoaded = true;
                            this.isCashProfile = false;
                        })
                        .catch((error) => {
                            this.error = error;
                            this.isLoaded = true;
                        });
                } else if (RecordsData.accountType == 'cash') {
                    AccType = 'Cash Accounts Search';
                    this.DataToProcess = RecordsData.CashAccountSearchResults;
                    this.isLoaded = true;
                    this.LoadMore = false;
                    this.isCashProfile = true;
                } else {
                    AccType = 'Cash Accounts Search';
                    this.DataToProcess = RecordsData.CashAccountSearchResults;
                    this.isLoaded = true;
                    this.LoadMore = false;
                    this.isCashProfile = true;
                }
            })
            .catch((error) => {
                this.error = error;
                this.ShowSearchInput = true;
                this.ShowSearchEmailResults = true;
                this.ShowSearchResultsHeader = false;
                this.ShowSearchResults = false;
                this.isLoaded = true;
                const event = new ShowToastEvent({
                    message: error,
                    variant: 'error',
                    mode: 'dismissable'
                });
                this.dispatchEvent(event);
            });
    }

    PreviousScreen(event) {
        this.ShowSearchInput = true;
        this.ShowSearchResults = false;
        this.ShowSearchResultsHeader = false;
        this.ShowSearchEmailResults = true;
    }

    closeModal() {
        this.dispatchEvent(new CustomEvent('modalclose'));
    }

    handleLoadMore(event) {
        event.preventDefault();
        if (this.LoadMore) {
            this.recordCount = this.recordCount + 20;
            event.target.isLoading = true;
            this.targetDatatable = event.target;
            this.getRecords();
        }
    }

    openAccount(event) {
        let accId = event.currentTarget.dataset.id;
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: accId,
                objectApiName: 'Account',
                actionName: 'view'
            }
        });
    }

    getRecords() {
        this.recordCount = this.recordCount > this.totalRecountCount ? this.totalRecountCount : this.recordCount;
        this.AccountResults = this.items.slice(0, this.recordCount);
        if (this.targetDatatable) {
            this.targetDatatable.isLoading = false;
        }
    }
}