import { LightningElement,wire,track } from 'lwc';
import CommentsModelBox from "c/sBR_3_0_AccountManagementCRProcessActions";
import SBR_3_0_Account_Management_CR_Title from '@salesforce/label/c.SBR_3_0_Account_Management_CR_Title';
import My_Pending_Requests_for_Strategic_Type from '@salesforce/label/c.SBR_3_0_My_Pending_Requests_for_Strategic_Type';
import My_Pending_Requests_for_Account_Relationships from '@salesforce/label/c.SBR_3_0_My_Pending_Requests_for_Account_Relationships';
import My_Pending_Requests_for_OSR_Fingerprint from '@salesforce/label/c.SBR_3_0_My_Pending_Requests_for_OSR_Fingerprint';
import Submitted_Account_Relationship_Change_Requests from '@salesforce/label/c.SBR_3_0_Account_Management_CR_Submitted_Account_Relationship_Change_Requests';
import Submitted_OSR_Relationship_Change_Requests from '@salesforce/label/c.SBR_3_0_Account_Management_CR_Submitted_OSR_Relationship_Change_Requests';
import Account_Management_CR_Strategic_Type_Change_Requests from '@salesforce/label/c.SBR_3_0_Account_Management_CR_Strategic_Type_Change_Requests';
import Account_Management_CR_Button_Recall from '@salesforce/label/c.SBR_3_0_Account_Management_CR_Button_Recall';
import Account_Management_CR_Button_Approve from '@salesforce/label/c.SBR_3_0_Account_Management_CR_Button_Approve';
import Account_Management_CR_Button_Reject from '@salesforce/label/c.SBR_3_0_Account_Management_CR_Button_Reject';
import Account_Management_CR_Success_Message from '@salesforce/label/c.SBR_3_0_Account_Management_CR_Success_Message';
import Account_Management_CR_Success_Message1 from '@salesforce/label/c.SBR_3_0_Account_Management_CR_Success_Message1';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import AccountManagmentCRRecords from '@salesforce/apex/SBR_3_0_AccountManagementCRController.getAccountManagmentCRRecords';
import AccountManagmentCRColumns from '@salesforce/apex/SBR_3_0_AccountManagementCRController.getAccountManagementCRColumns';

const filterOptions = [
    { value: My_Pending_Requests_for_Account_Relationships, label: My_Pending_Requests_for_Account_Relationships },
	{ value: My_Pending_Requests_for_Strategic_Type, label: My_Pending_Requests_for_Strategic_Type },
	{ value: My_Pending_Requests_for_OSR_Fingerprint, label: My_Pending_Requests_for_OSR_Fingerprint },
    { value: Submitted_Account_Relationship_Change_Requests, label: Submitted_Account_Relationship_Change_Requests },
    { value: Submitted_OSR_Relationship_Change_Requests, label: Submitted_OSR_Relationship_Change_Requests },
	{ value: Account_Management_CR_Strategic_Type_Change_Requests, label: Account_Management_CR_Strategic_Type_Change_Requests },
];

export default class ARListView extends LightningElement {
	ARRecords;
	ARRecordsSize;
	ARColumns;
	sortBy = 'nameUrl';
	sortByName = 'Request Name';
    defaultSortDirection = 'asc';
    sortDirection = 'asc';
	SelectedRowsToPass;
	currentFilter = My_Pending_Requests_for_Account_Relationships;
	filterOptions = filterOptions;
	error;
	label;
	isLoaded = false;
	isDisabled = true;
	isExpanded = false;
	ShowRecall = true;
	ShowApprove = false;
	ShowReject = false;
	Header;
	PluralRequest;
	SearchString;
	@wire(AccountManagmentCRColumns,{currentFilter:My_Pending_Requests_for_Account_Relationships}) wiredAccountManagmentCRColumns({ error, data }) {
		if (data) {
			this.createColumns(data);
		} else if (error) {
            console.log(error);
            this.error = error;
        }
    }  
	ClearFilters(evt){
		this.isLoaded = false;
		this.SearchString = "";
		AccountManagmentCRColumns({ currentFilter: this.currentFilter})
			.then((data) => {
				this.template.querySelector('lightning-datatable').selectedRows=[];
				this.createColumns(data);
			})
			.catch((error) => {
				this.error = error;
			});
	}
	FilterRecords(evt){
		const isEnterKey = evt.keyCode === 13;
		console.log("isEnterKey : "+isEnterKey);
        if (isEnterKey) {
			this.isDisabled = true;
			console.log('evt.target.value'+evt.target.value);
			let SearchString = evt.target.value;
			console.log("Filter Search Results based on : "+SearchString);
			if(SearchString.length == 1){
				const evt = new ShowToastEvent({
					title: 'search term must be longer than one character',
					variant: 'error',
				});
				this.dispatchEvent(evt);	
			}
			else{
				this.isLoaded = false;
				this.SearchString = SearchString;
				AccountManagmentCRColumns({ currentFilter: this.currentFilter})
				.then((data) => {
					this.template.querySelector('lightning-datatable').selectedRows=[];
					this.createColumns(data);
				})
				.catch((error) => {
					this.error = error;
				});
			}
		}
	}
	createColumns(data) {
        var ColumnsMap =[];
		for(var key in data){
			console.log("key"+key);
			var Label = data[key];
			console.log("Label"+Label[0]);
			var DataType = Label[1];
			console.log("DataType"+DataType);
			if(DataType == "DATE"){
				console.log("key Inside"+key);
				ColumnsMap.push({
					label: Label[0],
					fieldName: key,
					type: 'date',
					sortable: "true",
					value: Label[0],
					typeAttributes: {
						month: 'numeric',
						day: 'numeric',
						year: 'numeric',
						day: '2-digit',
						month: '2-digit',
						timeZone:'UTC'
					},
				});
			}
			else{
				if(key == 'Name'){
					ColumnsMap.push({
						label: Label[0],
						fieldName: 'nameUrl',
						type: 'url',
						sortable: "true",
						value: Label[0],
						typeAttributes: {label: { fieldName: key }, target: '_self'}
					});
				}
				else{	
					if(DataType == 'REFERENCE'){
						if(key == 'Account__r.Name'){
							ColumnsMap.push({
							label: Label[0],
							fieldName: 'AccountNameUrl',
							type: 'url',
							sortable: "true",
							value: Label[0],
							typeAttributes: {label: { fieldName: 'AccountName' }, target: '_self'}
							});
						}
						else if(key == 'CreatedBy.Name'){
							ColumnsMap.push({
								label: Label[0],
								fieldName: 'requesterName',
								type: 'text',
								sortable: "true",
								value: Label[0],
								typeAttributes: {label: { fieldName: key }}
							});
						}
						else if(key == 'RecordType.Name'){
							ColumnsMap.push({
								label: Label[0],
								fieldName: 'recordtypeName',
								type: 'text',
								sortable: "true",
								value: Label[0],
								typeAttributes: {label: { fieldName: key }}
							});
						}
						else if(key == 'Sales_Rep__r.Rep_Type__c'){
							ColumnsMap.push({
								label: Label[0],
								fieldName: 'newSalesRep',
								type: 'text',
								sortable: "true",
								value: Label[0],
								typeAttributes: {label: { fieldName: key }}
							});
						}
						else if(key == 'Current_Sales_Rep__r.Rep_Type__c'){
							ColumnsMap.push({
								label: Label[0],
								fieldName: 'currentSalesRep',
								type: 'text',
								sortable: "true",
								value: Label[0],
								typeAttributes: {label: { fieldName: key }}
							});
						}
						else{
							ColumnsMap.push({
								label: Label[0],
								fieldName: key,
								type: 'url',
								sortable: "true",
								value: Label[0],
								typeAttributes: {label: { fieldName: key }, target: '_self'}
							});
						}
					}
					else{
						ColumnsMap.push({
							label : Label[0],
							fieldName : key,
							type: 'text', 
							value: Label[0],
							sortable: "true"
						});
					}
				}
			}
		}
		this.ARColumns = ColumnsMap;
		AccountManagmentCRRecords({ currentFilter: this.currentFilter,SearchString:this.SearchString })
			.then((data) => {
				this.createRecords(data);
			})
			.catch((error) => {
				this.error = error;
			});
	}
	createRecords(data) {
        let nameUrl;
		let requesterName;
		let AccountName;
		let AccountNameUrl;
		let recordtypeName;
		let currentSalesRep;
		let newSalesRep;
		let EffectiveDate;
		console.log("this.currentFilter Inside"+this.currentFilter);
		this.ARRecords = data.map(row => { 
			nameUrl = `/${row.Id}`;
			console.log("nameUrl"+nameUrl);
			requesterName =`${row.CreatedBy.Name}`;
			console.log("requesterName"+requesterName);
			if(`${row.Account__c}` != 'undefined'){
				AccountNameUrl = `/${row.Account__c}`;
				console.log("AccountNameUrl"+AccountNameUrl);
				AccountName = `${row.Account__r.Name}`;
				console.log("AccountName"+AccountName);
			}
			if(`${row.Current_Sales_Rep__c}` != 'undefined'){
				currentSalesRep = `${row.Current_Sales_Rep__r.Rep_Type__c}`;
				console.log("currentSalesRep"+currentSalesRep);
			}
			if(`${row.Sales_Rep__c}` != 'undefined'){
				newSalesRep = `${row.Sales_Rep__r.Rep_Type__c}`;
				console.log("newSalesRep"+newSalesRep);
			}
			if(this.currentFilter == Account_Management_CR_Strategic_Type_Change_Requests || 
				this.currentFilter == Submitted_OSR_Relationship_Change_Requests ||
				this.currentFilter == My_Pending_Requests_for_Strategic_Type || 
				this.currentFilter == My_Pending_Requests_for_OSR_Fingerprint){
				recordtypeName = `${row.RecordType.Name}`;
			}
			return {...row , nameUrl,requesterName,AccountName,AccountNameUrl,currentSalesRep,newSalesRep,recordtypeName,EffectiveDate} 
		})
		this.ARRecordsSize = this.ARRecords.length;
		this.isLoaded = true;
	}
	handleSortdata(event) {       
        this.sortBy = event.detail.fieldName;       
        this.sortDirection = event.detail.sortDirection;   
		this.sortByName = event.detail.value;
		console.log('this.sortByName'+this.sortByName);
        this.sortAMCRData(event.detail.fieldName, event.detail.sortDirection);
    }
	sortAMCRData(fieldname, direction) {
        let parseData = JSON.parse(JSON.stringify(this.ARRecords));
       	let keyValue = (a) => {
            return a[fieldname];
        };
		let isReverse = direction === 'asc' ? 1: -1;
		parseData.sort((x, y) => {
            x = keyValue(x) ? keyValue(x) : ''; 
            y = keyValue(y) ? keyValue(y) : '';
           
            return isReverse * ((x > y) - (y > x));
        });
        this.ARRecords = parseData;
	}
	label = {
        SBR_3_0_Account_Management_CR_Title,
		Account_Management_CR_Button_Recall,
		Account_Management_CR_Button_Approve,
		Account_Management_CR_Button_Reject,
	};

	get dropdownTriggerClass() {
        if (this.isExpanded) {
            return 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click custom_list_view slds-is-open'
        } else {
            return 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click custom_list_view'
        }
    }

	handleClickExtend() {
        this.isExpanded = !this.isExpanded;
	}

	handleFilterChangeButton(event) {
		this.isDisabled = true;
		this.isLoaded = false;
        let filter = event.target.dataset.filter;
		console.log("filter"+filter);
	 	this.isExpanded = !this.isExpanded;
		this.currentFilter = filter;
        console.log("this.currentFilter Inside"+this.currentFilter);
		if(this.currentFilter == My_Pending_Requests_for_Strategic_Type ||
			this.currentFilter == My_Pending_Requests_for_OSR_Fingerprint ||
			this.currentFilter == My_Pending_Requests_for_Account_Relationships 
			){
			this.ShowRecall = true;	
		}
		else{
			this.ShowRecall = false;	
		}
		if(this.currentFilter == Submitted_Account_Relationship_Change_Requests || 
			this.currentFilter == Submitted_OSR_Relationship_Change_Requests || 
			this.currentFilter == Account_Management_CR_Strategic_Type_Change_Requests){
			this.ShowApprove = true;	
			this.ShowReject = true;
		}
		else{
			this.ShowApprove = false;	
			this.ShowReject = false;
		}
		console.log("ShowRecall"+this.ShowRecall);
		console.log("ShowApprove"+this.ShowApprove);
		console.log("ShowReject"+this.ShowReject);
		AccountManagmentCRColumns({ currentFilter: this.currentFilter})
			.then((data) => {
				this.template.querySelector('lightning-datatable').selectedRows=[];
				this.createColumns(data);
			})
			.catch((error) => {
				this.error = error;
			});
	}
	handleRowSelection(event){
		console.log("isDisabled"+this.isDisabled);
		const selectedRows = event.detail.selectedRows;
		if(selectedRows != ''){
			this.isDisabled = false;
		}
		else{
			this.isDisabled = true;
		}
		this.SelectedRowsToPass = selectedRows;
		console.log("isDisabled"+this.isDisabled);
	}
	handleActionSelection(event){
		this.isLoaded = false;
		let SelectedButtond = event.target.value;
		let SingularRequest;
		let isRecall = false;
		console.log("Selected Button "+SelectedButtond);
		console.log("this.currentFilter"+this.currentFilter);
		if(SelectedButtond == "Reject"){
            this.Header = "Reject Request";
			this.PluralRequest = "Rejection";
			SingularRequest = "Rejected";
        }
        else if(SelectedButtond == "Approve"){
            this.Header = "Approve Request";
			this.PluralRequest = "Approval";
			SingularRequest = "Approved";
        }
		else if(SelectedButtond == "Recall"){
            this.Header = "Recall Approval Request";
			this.PluralRequest = "Recall";
			SingularRequest = "Recalled";
			isRecall = true;
        }
        console.log('this.Header'+this.Header);
		console.log('this.PluralRequest'+this.PluralRequest);
		CommentsModelBox.open({
								label:"Enter Comment to Continue",
								SelectedRowsToPass:this.SelectedRowsToPass,
								SelectedButtond:SelectedButtond,
								currentFilter:this.currentFilter,
								Header:this.Header,
								PluralRequest:this.PluralRequest,
								isRecall:isRecall
							})
		.then((result) => {
			console.log(result);
			if(result == 'success'){
				console.log("length"+this.SelectedRowsToPass.length);
				var Message = "";
				if(this.SelectedRowsToPass.length == 1){
					var Message = Account_Management_CR_Success_Message1;
				}
				else{
					var Message = Account_Management_CR_Success_Message;
				}
				var Title = this.SelectedRowsToPass.length+' '+Message+' '+SingularRequest;
				console.log("Title"+Title);
				this.isLoaded = true;
				console.log("this.currentFilter in response"+this.currentFilter);
				AccountManagmentCRColumns({ currentFilter: this.currentFilter })
				.then((data) => {
					this.template.querySelector('lightning-datatable').selectedRows=[];
					this.createColumns(data);
				})
				.catch((error) => {
					this.error = error;
				});
				const evt = new ShowToastEvent({
					title: Title,
					variant: 'success',
				});
				this.dispatchEvent(evt);	    
			}
			else{
				this.isLoaded = true;	
			}
		})
		.catch((error) => {
				this.error = error;
		});
	}
}