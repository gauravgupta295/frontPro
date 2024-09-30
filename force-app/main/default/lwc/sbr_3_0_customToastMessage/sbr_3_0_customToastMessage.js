import { LightningElement, api,track } from 'lwc';

 
 export default class displayToastMessage extends LightningElement {
 
     @api errtitle;
     @api errmsg;
     @api errmsg2;
     @api email;
     @api successtitl;
     @api successmesg;
     @api showsuccess;
     @api record;
     @api displayFullWidth;
     @track displayErrorToast=false;
     @api displayWarningToast=false;
     @api isWarning=false;
     @track displaySuccessToast=false;
     
     @track warningMsgStyle = 'slds-theme_warning layouts';
     
     connectedCallback(){
       console.log('this.errtitle, this.successmesg',this.errtitle, this.successmesg);
       console.log('showsuccess::'+this.showsuccess);
       console.log("recordtype customtoast", this.record);
       if(this.errtitle!=='' && this.errmsg!=='' && this.errtitle!==undefined && this.errmsg!==undefined) {
        if(this.errmsg==='Select a record type.'){
            this.displayWarningToast=true;
        } else if(!this.isWarning) {
            this.displayErrorToast=true;
        }
       }
       
       console.log('displayFullWidth ',this.displayFullWidth)
        if(this.displayFullWidth) {
            this.warningMsgStyle = 'slds-theme_warning layouts fullwidth';
        }
       

        // if(this.showsuccess ){
        //     this.displaySuccessToast=true;
        //     setTimeout(() => {
        //         this.displaySuccessToast=false;
        //     }, time);
        //    }
    }

 
     closeToast(){
        const displayToastEvent = new CustomEvent('closetoast');
        this.dispatchEvent(displayToastEvent);
     }
 }