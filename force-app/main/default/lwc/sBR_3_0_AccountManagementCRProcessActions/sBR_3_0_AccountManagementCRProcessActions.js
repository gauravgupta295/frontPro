import LightningModal from 'lightning/modal';
import {LightningElement,api} from 'lwc';
import sendNoteficationsForAccountManagementCR from '@salesforce/apex/SBR_3_0_AccountManagementCRController.sendNoteficationsForAccountManagementCR';
export default class SBR_3_0_AccountManagementCRProcessActions extends LightningModal {
    Comments;
     
    @api SelectedRowsToPass;
    @api SelectedButtond;
    @api currentFilter;

    hideModalBox() {  
        this.close('canceled');
    }
    
    inputComments(event) {  
        this.close('success');
        this.Comments = [this.template.querySelector("lightning-textarea").value].toString();;
        console.log("Comments: "+this.Comments);
        console.log("SelectedRowsToPass: "+this.SelectedRowsToPass);
        console.log("SelectedButtond: "+this.SelectedButtond);
        sendNoteficationsForAccountManagementCR({selectedRows:this.SelectedRowsToPass,ClicledButton:this.SelectedButtond,Comments:this.Comments,currentFilter:this.currentFilter})
        .then((data) => {
			console.log("data"+data); 
        })
        .catch((error) => {
            console.log("error"+error); 
            this.error = error;
        });
    }
}