import { LightningElement,api,track,wire } from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { FlowNavigationNextEvent, FlowNavigationFinishEvent, FlowNavigationBackEvent } from 'lightning/flowSupport';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import Account_Management_Title_For_Update from '@salesforce/label/c.SBR_3_0_Account_Management_Title_For_Update';
export default class Sbr_ChangeRequestBulkScreen extends LightningElement {
    @api amcrList=[];
    @api fieldList;
    @api objectType ;
    @api isEditable;
    @api objectScreenLabel = Account_Management_Title_For_Update;
    @track tableHeight;
    @track columns=[];
    @track isModalOpen = false;
    @track recordsToRemove=[];

    @wire(getObjectInfo, { objectApiName: '$objectType' })
        amcrSchema({data,error}){
            if(data){
                console.log('data@@',data);
                console.log('amcrSchema@@ ', this.fieldList);
                let fieldNames = this.fieldList.split(',');
                let consData = Object.assign({},data);//JSON.parse(JSON.stringify(data));
                 fieldNames.forEach( each => {
                                    console.log('label ', each);
                                    let ele = consData.fields[each];
                                    this.columns.push({label: ele.label, fieldName: each, hideDefaultActions: true});
                                });
              
                console.log('columns@2',this.columns);
            }   
        };
    
    
    connectedCallback(){
        console.log('amcrSchema@@22 ', this.amcrList);
    if(this.amcrList && this.amcrList.length >0){
        let i=0;
        const copyVar = JSON.parse(JSON.stringify(this.amcrList));
        copyVar.forEach( each => {
            each['key'] = i;
            i++;
        })
        this.amcrList = [...copyVar];
    }
    
    }

    get isTableColumnSet(){
        console.log('this.amcrList.length@@', this.amcrList);
        return this.columns.length >0 && this.amcrList.length >0 ;
    }

    getSelectedRecord(event){    
        this.recordsToRemove = [];
        const selectedRows = event.detail.selectedRows;
        console.log('selectedRows@@', selectedRows.length);
        // Display that fieldName of the selected rows
        for (let i = 0; i < selectedRows.length; i++) {
            this.recordsToRemove.push(selectedRows[i]);
        }
        console.log('recordsToRemove@@', this.recordsToRemove);
    }

    get getSelectedRec(){
       return this.recordsToRemove.length <=0 ;
    }

    get hideCheckbox(){
        return !this.isEditable;
    }
   
    renderedCallback(){   
        if(this.amcrList.length ==0 ){
            this.tableHeight = 'height:3rem;';
        }else{  
          //  this.tableHeight = 'height: '+  (this.amcrList.length * 2.5)+ 3 + 'rem;';   
          this.tableHeight = 'height:20rem;';
          
        }   
        
    }
    removeRecords(){
       // const eleToRemove = new Set(this.recordsToRemove);
        const newArr = this.amcrList.filter((ele) => {
            // return those elements not in the eleToRemove
            return !this.recordsToRemove.map( each => each.key).includes(ele.key);
          });
          this.template.querySelector('lightning-datatable').selectedRows = [];
          this.amcrList = JSON.parse(JSON.stringify(newArr));
          this.recordsToRemove = [];
    }

    handleFlowPrevious() {
        const navigateBackEvent = new FlowNavigationBackEvent();
        this.dispatchEvent(navigateBackEvent);
    }

    handleFlowFinish() {
        console.log('this.amcrList@@@@@',this.amcrList );
        const navigateNextEvent = new FlowNavigationNextEvent();
        this.dispatchEvent(navigateNextEvent);
    }

    openModal() {
        // to open modal set isModalOpen tarck value as true
        this.isModalOpen = true;
    }
    closeModal() {
        // to close modal set isModalOpen tarck value as false
        this.isModalOpen = false;
    }
    submitDetails() {
        // to close modal set isModalOpen tarck value as false
        //Add your code to call apex method or do some processing
        this.isModalOpen = false;
    }
    showToast(type,message) {
        const event = new ShowToastEvent({
            title: type,
            variant: type,
            message: message
                
        });
        this.dispatchEvent(event);
    }

}