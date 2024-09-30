import { LightningElement, wire, api } from 'lwc';
import fetchPriceList from '@salesforce/apex/PPA_TableForAnalyticsController.fetchPriceList';
import hasPermission from '@salesforce/customPermission/PPA_Regional_Manager_RSD';
/*PPA Phase 2: DP-1025
Added custom label - PPA_Enable_Customer_Summary_tab*/
import enableCustomerSummaryTab from '@salesforce/label/c.PPA_Enable_Customer_Summary_tab';

const col1 = [
    { label: 'Price List Name', fieldName: 'Name', type: 'button', initialWidth: 500, wrapText: false, typeAttributes: { label: { fieldName: 'Name'}, name: 'view', value: 'view', variant: 'base'}, cellAttributes: { class: 'slds-p-vertical_none slds-m-vertical_none' }, hideDefaultActions: true, sortable: true },
    { label: 'Customer #', fieldName: 'PPA_Customer_No__c', type: 'text', hideDefaultActions:true, sortable: true },
    { label: 'TTM Rental', fieldName: 'PPA_Customer_TTM__c', type: 'currency', hideDefaultActions:true, cellAttributes: {alignment: 'left'}, sortable: true },
    { label: 'Next 30 Days', fieldName: 'PPA_Next_30_Days__c', type: 'currency', hideDefaultActions:true, cellAttributes: {alignment: 'left'}, sortable: true },
    { label: 'Next 90 Days', fieldName: 'PPA_Next_90_Days__c', type: 'currency', hideDefaultActions:true, cellAttributes: {alignment: 'left'}, sortable: true },
    /*PPA Phase 2: DP-1025
    Added PPA_Started__c */
    { label: 'Started', fieldName: 'PPA_Started__c', type: 'text', hideDefaultActions: true, sortable: true }
];

const col2 = [
    { label: 'End Date', fieldName: 'PPA_Dashboard_End_Date__c', type: 'date-local', hideDefaultActions:true, sortable: true,
        typeAttributes: {
            day: '2-digit',
            month: '2-digit',
            year: 'numeric'
        }
    },
    { label: 'Price List Name', fieldName: 'Name', type: 'button', initialWidth: 500, wrapText: false, typeAttributes: { label: { fieldName: 'Name'}, name: 'view', value: 'view', variant: 'base'}, cellAttributes: { class: 'slds-p-vertical_none slds-m-vertical_none' }, hideDefaultActions: true, sortable: true },
    { label: 'TTM Rental', fieldName: 'PPA_Customer_TTM__c', type: 'currency',cellAttributes: {alignment: 'left'}, hideDefaultActions:true, sortable: true },
    { label: 'Health', fieldName: 'PPA_Health__c', type: 'text', cellAttributes: { class: { fieldName: 'PPA_RowColorClass__c'}}, hideDefaultActions:true, sortable: true },
    { label: 'RA %', fieldName: 'PPA_Current_TTM_RA__c', type: 'text', hideDefaultActions:true, sortable: true },
    { label: 'Active Days', fieldName: 'PPA_Active_Days__c', type: 'text', hideDefaultActions:true, sortable: true },
    { label: 'Status', fieldName: 'PPA_Status__c', type: 'text', hideDefaultActions:true, sortable: true },
    { label: 'Next Approver Name', fieldName: 'PPA_Next_Approver_Name__c', type: 'text', hideDefaultActions:true, sortable: true },
    /*PPA Phase 2: DP-1025
    Added PPA_Started__c */
    { label: 'Started', fieldName: 'PPA_Started__c', type: 'text', hideDefaultActions: true, sortable: true }
];

const col3 = [
    { label: 'Rep Name', fieldName: 'PPA_Rep_Name__c', type: 'text', hideDefaultActions:true, sortable: true },
    /*PPA Phase 2: DP-1025
    Added PPA_Started__c */
    { label: 'Started', fieldName: 'PPA_Started__c', type: 'text', hideDefaultActions: true, sortable: true },
    { label: 'Price List Name', fieldName: 'Name', type: 'button', initialWidth: 500, wrapText: false, typeAttributes: { label: { fieldName: 'Name'}, name: 'view', value: 'view', variant: 'base'}, cellAttributes: { class: 'slds-p-vertical_none slds-m-vertical_none' }, hideDefaultActions: true, sortable: true },
    { label: 'Customer #', fieldName: 'PPA_Customer_No__c', type: 'text', hideDefaultActions:true, sortable: true },
    { label: 'TTM Rental', fieldName: 'PPA_Customer_TTM__c', type: 'currency', hideDefaultActions:true, cellAttributes: {alignment: 'left'}, sortable: true },
    { label: 'Next 30 Days', fieldName: 'PPA_Next_30_Days__c', type: 'currency', hideDefaultActions:true, cellAttributes: {alignment: 'left'}, sortable: true },
    { label: 'Next 90 Days', fieldName: 'PPA_Next_90_Days__c', type: 'currency', hideDefaultActions:true, cellAttributes: {alignment: 'left'}, sortable: true }
];

const col4 = [
    { label: 'Total',hideDefaultActions:true},
    { label: '', hideDefaultActions:true, initialWidth: 500},
    { label: '', hideDefaultActions:true},
    { label: '', hideDefaultActions:true},
    { label: '', hideDefaultActions:true},
    { label: '', hideDefaultActions:true}
];

const col5 = [
    { label: 'Total', hideDefaultActions:true, initialWidth: 500},
    { label: '', hideDefaultActions:true},
    { label: '', hideDefaultActions:true},
    { label: '', hideDefaultActions:true},
    { label: '', hideDefaultActions:true}
];

const col6 = [
    /*PPA Phase 2: DP-1025
    Added PPA_Rep_Name__c */
    { label: 'Rep', fieldName: 'PPA_Rep_Name__c', type: 'text', hideDefaultActions: true, sortable: true },
    {
        label: 'End Date', fieldName: 'PPA_Dashboard_End_Date__c', type: 'date-local', hideDefaultActions: true, sortable: true,
        typeAttributes: {
            day: '2-digit',
            month: '2-digit',
            year: 'numeric'
        }
    },
    { label: 'Price List Name', fieldName: 'Name', type: 'button', initialWidth: 500, wrapText: false, typeAttributes: { label: { fieldName: 'Name' }, name: 'view', value: 'view', variant: 'base' }, cellAttributes: { class: 'slds-p-vertical_none slds-m-vertical_none' }, hideDefaultActions: true, sortable: true },
    { label: 'TTM Rental', fieldName: 'PPA_Customer_TTM__c', type: 'currency', cellAttributes: { alignment: 'left' }, hideDefaultActions: true, sortable: true },
    { label: 'Health', fieldName: 'PPA_Health__c', type: 'text', cellAttributes: { class: { fieldName: 'PPA_RowColorClass__c' } }, hideDefaultActions: true, sortable: true },
    { label: 'RA %', fieldName: 'PPA_Current_TTM_RA__c', type: 'text', hideDefaultActions: true, sortable: true },
    { label: 'Active Days', fieldName: 'PPA_Active_Days__c', type: 'text', hideDefaultActions: true, sortable: true },
    { label: 'Status', fieldName: 'PPA_Status__c', type: 'text', hideDefaultActions: true, sortable: true },
    { label: 'Next Approver Name', fieldName: 'PPA_Next_Approver_Name__c', type: 'text', hideDefaultActions: true, sortable: true },
    /*PPA Phase 2: DP-1025
    Added PPA_Started__c */
    { label: 'Started', fieldName: 'PPA_Started__c', type: 'text', hideDefaultActions: true, sortable: true }
];

export default class PPA_PriceListAnalyticsLWC extends LightningElement {
    @api Status;
    @api Health;
    @api RepName;
    @api Enddate;
    allRecords = [] ;
    colDisplay;
    colDisplay2;
    colDisplay4 = [];
    colDisplay5 = [];
    col1 = col1;
    col3 = col3;
    col4 = col4;
    col5 = col5;
    totalSum1 = '';
    totalSum2 = '';
    totalSum3 = '';
    showTotalRSD = false;
    showTotalSCR = false;
    sortDirection;
    sortedBy;
    //PPA Phase 2: DP-1025
    isActive = false;
    @api IsStarted = 'all';
    /*PPA Phase 2: DP-1025
    Added enableCustSumTab to show/hide Customer Summary tab*/
    enableCustSumTab = (enableCustomerSummaryTab.toLowerCase() == 'true' || enableCustomerSummaryTab.toLowerCase() == 'yes') ? true : false;

    @wire(fetchPriceList, { Status: '$Status', Health: '$Health', RepName: '$RepName', Enddate: '$Enddate', IsStarted: '$IsStarted'})
    wiredCatclass({ error, data }) {
        if (data){
            //console.log(data);
            this.allRecords = data;
            this.handleSum(data);
            
                if (hasPermission) {
                    this.colDisplay = this.col3;
                    //PPA Phase 2: DP-1025
                    this.colDisplay2 = col6; 
                    this.showTotalRSD = true;
                }
                else {
                    this.colDisplay = this.col1;
                    //PPA Phase 2: DP-1025
                    this.colDisplay2 = col2;
                    this.showTotalSCR = true;
                }
        }
        else if (error) {
            console.log(error);
        }
    }
    //PPA Phase 2: DP-1025
    toggleStarted(event) {
        if(event.target.checked) {
            this.IsStarted = 'Yes';
        }
        else {
            this.IsStarted = 'No';
        }
    }

    handleRowAction(event) {
        const record = event.detail.row;
        const url = "/" + record.Id
        window.open(url);
    }

    handleSum(allRecords){
        let totalSum = 0;
        let totalSum30 = 0;
        let totalSum90 = 0;

        for(let i=0; i< allRecords.length; i++){
            const record = allRecords[i];

            const custTTM = record.PPA_Customer_TTM__c|| 0;
            totalSum += parseFloat(custTTM);
            
            const custTTM30 = record.PPA_Next_30_Days__c|| 0;
            totalSum30 += parseFloat(custTTM30);

            const custTTM90 = record.PPA_Next_90_Days__c|| 0;
            totalSum90 += parseFloat(custTTM90);
        }

        let formatting_options = { style: 'currency', currency: 'USD', minimumFractionDigits: 2};
        let dollarString = new Intl.NumberFormat("en-US", formatting_options); 
                
        this.totalSum1 = dollarString.format(totalSum);
        this.totalSum2 = dollarString.format(totalSum30);
        this.totalSum3 = dollarString.format(totalSum90);

        this.colDisplay4 = [];
        this.colDisplay4.push({label: 'Total',hideDefaultActions:true});
        this.colDisplay4.push({label: '',hideDefaultActions:true, initialWidth: 500});
        this.colDisplay4.push({label: '',hideDefaultActions:true});
        this.colDisplay4.push({label: this.totalSum1, hideDefaultActions:true});
        this.colDisplay4.push({label: this.totalSum2, hideDefaultActions:true});
        this.colDisplay4.push({label: this.totalSum3, hideDefaultActions:true});

        this.colDisplay5 = [];
        this.colDisplay5.push({label: 'Total',hideDefaultActions:true, initialWidth: 500});
        this.colDisplay5.push({label: '',hideDefaultActions:true});
        this.colDisplay5.push({label: this.totalSum1, hideDefaultActions:true});
        this.colDisplay5.push({label: this.totalSum2, hideDefaultActions:true});
        this.colDisplay5.push({label: this.totalSum3, hideDefaultActions:true});
    } 

    onHandleSort(event) {
        const fieldName = event.detail.fieldName;
        const sortDirection = event.detail.sortDirection;
        
        let sortedData = [...this.allRecords];

            if (sortDirection === 'asc'){
                sortedData = sortedData.slice().sort((a,b) => (a[fieldName] > b[fieldName]) ? 1 : -1);
            }
            else if (sortDirection === 'desc'){
                sortedData = sortedData.slice().sort((a,b) => (a[fieldName] < b[fieldName]) ? 1 : -1);
            }

        this.allRecords = sortedData;
        this.sortDirection = sortDirection;
        this.sortedBy = fieldName;
    }
}