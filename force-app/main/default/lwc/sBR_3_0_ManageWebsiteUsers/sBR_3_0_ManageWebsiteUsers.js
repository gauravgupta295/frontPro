import { LightningElement, wire, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import FORM_FACTOR from '@salesforce/client/formFactor';

import Category_Account_Results from '@salesforce/label/c.SBR_3_0_Manage_Website_Category_Account_Results';
import Manage_Website_Users_Title from '@salesforce/label/c.SBR_3_0_Manage_Website_Users_Title';
import Manage_Website_Users_Heading from '@salesforce/label/c.SBR_3_0_Manage_Website_Users_Heading';
import Manage_Website_Users_Search from '@salesforce/label/c.SBR_3_0_Manage_Website_Users_Search';
import Manage_Website_Users_Placeholder from '@salesforce/label/c.SBR_3_0_Manage_Website_Users_Placeholder';
import Manage_Website_Users_Create_Heading from '@salesforce/label/c.SBR_3_0_Manage_Website_Users_Create_Heading';
import Button_Invite_New_User from '@salesforce/label/c.SBR_3_0_Manage_Website_User_Button_Invite_New_User';
import Button_Next from '@salesforce/label/c.SBR_3_0_Manage_Website_User_Button_Next';
import Button_Previous from '@salesforce/label/c.SBR_3_0_Manage_Website_User_Button_Previous';
import Button_Confirm from '@salesforce/label/c.SBR_3_0_Manage_Website_User_Button_Confirm';
import Email_Empty_Error from '@salesforce/label/c.SBR_3_0_Manage_Website_User_Email_Empty_Error';
import SBR_3_0_Manage_Website_Users_ExistingUserError from '@salesforce/label/c.SBR_3_0_Manage_Website_Users_ExistingUserError';

import ManageWebsiteUsersColumns from '@salesforce/apex/SBR_3_0_ManageWebsiteUserController.getManageWebsiteUsersColumns';
import ManageWebsiteUsersRecords from '@salesforce/apex/SBR_3_0_ManageWebsiteUserController.getManageWebsiteUsersRecords';
import CreateWebsiteUsersRecords from '@salesforce/apex/SBR_3_0_ManageWebsiteUserController.CreateWebsiteUsersRecords';
import searchWebsiteUser from '@salesforce/apex/SBR_3_0_ManageWebsiteUserController.searchWebsiteUser';

export default class SBR_3_0_ManageWebsiteUsers extends LightningElement {
    isLoaded = false; /* This variable is used to control loader in the component */
    deviceTypeDesktp; /* This variable is used to determine the device that component is opened as Desktop */
    deviceTypeTablet; /* This variable is used to determine the device that component is opened as Tablet */
    deviceTypeMobile; /* This variable is used to determine the device that component is opened as Mobile */

    MWUColumns; /* This variable is used to store all the Headers that need to be displayed in the Data Table */
    MWURecords = []; /* This variable is used to store all Results  that need to be displayed in the Data Table */
    sortBy = 'name'; /* This variable is used to control the sorting field in the Data Table */
    defaultSortDirection = 'asc'; /* This variable is used to control the default sorting direction in the Data Table */
    sortDirection = 'asc'; /* This variable is used to control the sorting direction in the Data Table */

    ShowCreateUser = false; /* This variable is used to control visibility of the User Invite screen */
    ShowUserResults = false; /* This variable is used to control visibility of the User Results screen */
    ShowUserConfrimationScreen = false; /* This variable is used to control visibility of the User Confirmation screen */

    FirstName; /* This variable is used to store the First Name from the User Creation Screen */
    LastName; /* This variable is used to store the Last Name from the User Creation Screen */
    Email; /* This variable is used to store the Email from the User Creation Screen */
    Users; /* This variable is used to store Users from the response */
    AccountNumber; /* This variable is used to store Account number from the Account Record */
    UserType; /* This variable is used to determine the User Type from the response based on Email input from User Creation Screen */
    UserTypeCredit; /* This variable is used to determine the User Type as Credit from the response based on Email input from User Creation Screen */
    UserTypeCash; /* This variable is used to determine the User Type as Cash from the response based on Email input from User Creation Screen */
    CompanyCode; /* This variable is used to store Company Code from the Account Record */

    CreditComment; /* This variable is used to store Comment for Credit User Type that will be displayed on User Confirmation Screen */
    CashCommentHeading; /* This variable is used to store Comment for Cash User Type as Heading that will be displayed on User Confirmation Screen */
    CashCommentBody; /* This variable is used to store Comment for Cash User Type as body that will be displayed on User Confirmation Screen */

    items = []; /* This variable is used to store the list of User record that are fetched from the Account Number as copy */
    recordCount = 20; /* This variable is used to store the Records Count which will be used for loging more data in Data table*/
    totalRecountCount = 0; /* This variable is used to store the Total Records Count which will be used for loging more data in Data table*/
    targetDatatable; /* This variable is used to load the Data table*/
    LoadMore = true; /* This variable is used to control Infinite loading in the Data Table*/
    DisablePreviousButton = false; /* This variable is used to control Previous Buttoon Enable/Disabled*/
    isExistingUser = false; // 5411
    label = {
        Category_Account_Results,
        Manage_Website_Users_Title,
        Manage_Website_Users_Heading,
        Manage_Website_Users_Search,
        Manage_Website_Users_Placeholder,
        Manage_Website_Users_Create_Heading,
        Button_Invite_New_User,
        Button_Next,
        Button_Previous,
        Button_Confirm,
        SBR_3_0_Manage_Website_Users_ExistingUserError
    };
    _recordId;

    @api set recordId(value) {
        this._recordId = value;
        this.createColumns();
        this.createResults();
    }
    get recordId() {
        return this._recordId;
    }
    closeModal() {
        console.log('recordId close ' + this.recordId);
    }

    connectedCallback() {
        if (FORM_FACTOR === 'Large') {
            this.deviceTypeDesktp = true;
        } else if (FORM_FACTOR === 'Medium') {
            this.deviceTypeTablet = true;
        } else if (FORM_FACTOR === 'Small') {
            this.deviceTypeMobile = true;
        }
    }

    createColumns() {
        ManageWebsiteUsersColumns({ Category: Category_Account_Results })
            .then((data) => {
                var ColumnsMap = [];
                for (var key in data) {
                    var values = data[key];
                    var Label = values[0];
                    var APIName = values[1];
                    var DataType = values[2];
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
                this.MWUColumns = ColumnsMap;
            })
            .catch((error) => {
                this.isLoaded = true;
                const event = new ShowToastEvent({
                    message: error,
                    variant: 'error',
                    mode: 'dismissable'
                });
                this.dispatchEvent(event);
            });
    }

    createResults() {
        this.items = [];
        this.FirstName = '';
        this.LastName = '';
        this.Email = '';
        let randomNumber = Math.random();
        ManageWebsiteUsersRecords({ recordId: this.recordId, randomNumber: randomNumber })
            .then((data) => {
                this.AccountNumber = data.AccountNumber;
                this.CompanyCode = data.CompanyCode;
                this.Users = data.users;
                this.items = [...this.items, ...this.Users];
                if (this.deviceTypeMobile) {
                    this.MWURecords = this.items;
                } else {
                    if (this.items.length > 20) {
                        this.LoadMore = true;
                    } else {
                        this.LoadMore = false;
                    }
                    this.totalRecountCount = this.items.length;
                    this.MWURecords = this.items.slice(0, this.recordCount);
                }
                this.isLoaded = true;
                this.ShowUserResults = true;
            })
            .catch((error) => {
                this.isLoaded = true;
                this.ShowCreateUser = true;
                this.ShowUserResults = false;
                this.DisablePreviousButton = true;
                const event = new ShowToastEvent({
                    message: error,
                    variant: 'error',
                    mode: 'dismissable'
                });
                this.dispatchEvent(event);
            });
    }

    filterSearchResults(event) {
        // var SearchString = new RegExp(event.target.value.toLowerCase());
        // console.log('SearchString' + SearchString);
        // console.log('this.items' + JSON.stringify(this.items));
        // this.MWURecords = this.items.filter((row) => SearchString.test(row.name.toLowerCase()));
        // if (this.MWURecords.length == 0) {
        //     this.MWURecords = this.items.filter((row) => SearchString.test(row.email.toLowerCase()));
        // }
        // if (!this.deviceTypeMobile) {
        //     if (this.MWURecords.length > 20) {
        //         this.LoadMore = true;
        //     } else {
        //         this.LoadMore = false;
        //     }
        // }
        this.MWURecords = [];
        const searchString = event.detail.value;
        const filteredByName = this.items.filter((item) => item.name.toLowerCase().includes(searchString.toLowerCase()));
        this.MWURecords = JSON.parse(JSON.stringify(filteredByName.length === 0 ? this.items.filter((item) => item.email.toLowerCase().includes(searchString.toLowerCase())) : filteredByName));

        if (!this.deviceTypeMobile) {
            if (this.MWURecords.length > 20) {
                this.LoadMore = true;
            } else {
                this.LoadMore = false;
            }
        }
    }

    handleSortdata(event) {
        this.sortBy = event.detail.fieldName;
        this.sortDirection = event.detail.sortDirection;
        this.sortMWUData(event.detail.fieldName, event.detail.sortDirection);
    }

    sortMWUData(fieldname, direction) {
        let parseData = JSON.parse(JSON.stringify(this.MWURecords));
        let keyValue = (a) => {
            return a[fieldname];
        };
        let isReverse = direction === 'asc' ? 1 : -1;
        parseData.sort((x, y) => {
            x = keyValue(x) ? keyValue(x) : '';
            y = keyValue(y) ? keyValue(y) : '';

            return isReverse * ((x > y) - (y > x));
        });
        this.MWURecords = parseData;
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

    getRecords() {
        this.recordCount = this.recordCount > this.totalRecountCount ? this.totalRecountCount : this.recordCount;
        this.MWURecords = this.items.slice(0, this.recordCount);
        if (this.targetDatatable) {
            this.targetDatatable.isLoading = false;
        }
    }

    OpenUserCreationScreen(event) {
        this.DisablePreviousButton = false;
        this.ShowCreateUser = true;
        this.ShowUserResults = false;
    }
    NavigateToUserResultsScreen(event) {
        this.ShowCreateUser = false;
        this.ShowUserResults = true;
    }
    CheckUserType(event) {
        const isInputsCorrect = [...this.template.querySelectorAll('lightning-input')].reduce((validSoFar, inputField) => {
            inputField.reportValidity();
            return validSoFar && inputField.checkValidity();
        }, true);
        if (isInputsCorrect) {
            this.isLoaded = false;
            this.FirstName = this.template.querySelector('lightning-input[data-name="FirstName"]').value;
            this.LastName = this.template.querySelector('lightning-input[data-name="LastName"]').value;
            this.Email = this.template.querySelector('lightning-input[data-name="Email"]').value;

            if(this.Users && this.Email){
                this.isExistingUser = this.Users.some(val => (val.email).toLowerCase() == (this.Email).toLowerCase());
                    if(this.isExistingUser){ 
                        const existingUserErrorToast = new ShowToastEvent({
                            message: this.label.SBR_3_0_Manage_Website_Users_ExistingUserError,
                            variant: 'error',
                            mode: 'dismissable'
                        });
                        this.dispatchEvent(existingUserErrorToast); 
                        this.FirstName = '';
                        this.LastName = '';
                        this.Email = '';
                        this.isLoaded = true;
                        this.NavigateToUserResultsScreen(event);
                        return;
                         
                } 
            }

            searchWebsiteUser({ SearchEmail: this.Email })
                .then((RecordsData) => {
                    this.AccountResponse = RecordsData;
                    this.UserType = RecordsData.accountType;
                    if (this.UserType == 'credit') {
                        this.UserTypeCredit = true;
                        this.CreditComment = 'Are you sure you want to invite web user ' + this.FirstName + ' ' + this.LastName + ' (' + this.Email + ') ?';
                    } else if (this.UserType == 'cash') {
                        this.UserTypeCash = true;
                        this.CashCommentHeading = 'Web user ' + this.FirstName + ' ' + this.LastName + ' (' + this.Email + ') has a Non-Credit profile';
                        this.CashCommentBody = 'Are you sure you want to convert the customer’s profile to Credit and assign to Account ' + this.AccountNumber + ' ?  They will lose all rental history from their Non-Credit Account in Command Center.'
                    }
                    if (this.UserType == 'USER_NOT_FOUND') {
                        this.UserTypeCredit = true;
                        this.CreditComment = 'Are you sure you want to invite web user ' + this.FirstName + ' ' + this.LastName + ' (' + this.Email + ') ?';
                    }
                    this.ShowCreateUser = false;
                    this.ShowUserConfrimationScreen = true;
                    this.isLoaded = true;
                })
                .catch((error) => {
                    var Message = 'Error in sending Email Invite to ' + this.Email;
                    const event = new ShowToastEvent({
                        message: Message,
                        variant: 'error',
                        mode: 'dismissable'
                    });
                    this.dispatchEvent(event);
                });
        }
    }
    NavigateToUserUserCreationScreen(event) {
        this.ShowCreateUser = true;
        this.ShowUserConfrimationScreen = false;
    }
    InviteNewUser(event) {
        this.isLoaded = false;
        this.ShowCreateUser = false;
        this.ShowUserConfrimationScreen = false;
        CreateWebsiteUsersRecords({ recordId: this.recordId, FirstName: this.FirstName, LastName: this.LastName, Email: this.Email, AccountNumber: this.AccountNumber, CompanyCode: this.CompanyCode, UserType: this.UserType })
            .then((data) => {
                var Message = 'Email invite successfully sent to ' + this.Email;
                const event = new ShowToastEvent({
                    message: Message,
                    variant: 'success',
                    mode: 'dismissable'
                });
                this.dispatchEvent(event);
                this.createResults();
                this.dispatchEvent(new CloseActionScreenEvent());
            })
            .catch((error) => {
                this.isLoaded = true;
                this.dispatchEvent(new CloseActionScreenEvent());
                var Message = 'Error in sending Email Invite to ' + this.Email;
                const event = new ShowToastEvent({
                    message: Message,
                    variant: 'error',
                    mode: 'dismissable'
                });
                this.dispatchEvent(event);
                this.dispatchEvent(new CustomEvent('modalclose'));
            });
    }
}