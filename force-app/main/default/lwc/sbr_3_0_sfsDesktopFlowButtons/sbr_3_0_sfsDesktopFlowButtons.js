import { LightningElement,api } from 'lwc';
import {FlowNavigationBackEvent,FlowAttributeChangeEvent,FlowNavigationNextEvent} from "lightning/flowSupport";
import lightningDeleteModalLWC from 'c/sbr_3_0_sfsMobileGenericConfirmationModal';
//import { deleteRecord } from 'lightning/uiRecordApi';
import getWoToBeDeleted from '@salesforce/apex/Sbr_3_0_sfsDesktopPartsCmpController.getWoToBeDeleted';

export default class Sbr_3_0_sfsDesktopFlowGenricButtons extends LightningElement {

    
     @api availableActions = [];
     @api showNextButton=false;
     @api showPreviousButton=false;
     @api disableNextButton=false;
     @api lableNextButton;
     @api lablePreviousButton;
     @api showCancelButton=false;
     @api lableCancelButton;
     @api showSaveButton=false;
     @api lableSaveButton="Save";
     @api callFrom="Flow";
     @api object;
     @api showSkipButton;
     @api lableSkipButton;
     @api showSummary;
     @api lableSummaryButton;
     @api type='List';
     @api recordId;
     @api recordToBeDeleted;
     @api displayNextScreenMessage=false;
     @api nextScreenMessage; 
     @api disableSaveButton=false;

     @api usedisable=false;
		@api hideCancelPopup = false;
		
     // To handle previous click
     handlePrevious(){ 
            if(this.callFrom=="Lwc"){
                console.log("back");
                this.dispatchEvent(new CustomEvent('previous',{bubbles: true}));
            }else{
                const navigateBackEvent = new FlowNavigationBackEvent();
                console.log("back");
                this.dispatchEvent(navigateBackEvent);
            } 
     } 
     // To handle next claick
     handleNext(){
        if(this.callFrom=="Lwc"){
                console.log("next");
                this.dispatchEvent(new CustomEvent('next',{bubbles: true}));
        }else{
          const navigateNextEvent = new FlowNavigationNextEvent();
          console.log("next");
          this.dispatchEvent(navigateNextEvent);

          
        }
     }
     // To handle skip to summary 
     handleSummary(){

      const attributeChangeEvent = new FlowAttributeChangeEvent('skiptoSummary', true)
      this.dispatchEvent(attributeChangeEvent);
      // setTimeout(() => {
      //    const navigateNextEvent = new FlowNavigationNextEvent();
      //    this.dispatchEvent(navigateNextEvent);
      //    }, 1);
      // const navigateNextEvent = new FlowNavigationNextEvent();
      //       this.dispatchEvent(navigateNextEvent);
      this.dispatchEvent(new CustomEvent('summary',{bubbles: true}));
       
     }
     // To handle next cancel click
     async handleCancel(){

       console.log("REcord to be Deleted: "+this.recordToBeDeleted);
      
        if(this.callFrom=="Lwc" && this.hideCancelPopup == false){

                
         await lightningDeleteModalLWC.open({
            size: 'small',
            description: 'Accessible description of modal purpose',
            content: 'Are you sure ?',
            headerText:'Confirmation',
            onyesclick:(e)=>{

                       if(this.recordToBeDeleted){
                        this.handleCancelDelete(this.recordToBeDeleted);
                       }else{
                        console.log("cancel");
                        this.dispatchEvent(new CustomEvent('cancel',{bubbles: true}));
                       }
            }
         }); 
                     

        }else if(this.hideCancelPopup == true){
						console.log('no');
						
						let link=this.handleType();
						console.log(link);
						//window.location.href=`${window.location.origin}/lightning/o/${this.object}/list`;
						window.location.href=link;
						console.log("cancel");
				}else{
                
         await lightningDeleteModalLWC.open({
            size: 'small',
            description: 'Accessible description of modal purpose',
            content: 'Are you sure ?',
            headerText:'Confirmation',
            onyesclick:(e)=>{
              // console.log(`${window.location.origin}/lightning/o/${this.object}/list`);
                        let link=this.handleType();
                        console.log(link);
                        //window.location.href=`${window.location.origin}/lightning/o/${this.object}/list`;
                        window.location.href=link;
                        console.log("cancel");
            }  
         });  
            
        }

     }
     // To handle save click
     handleSave(){
        if(this.callFrom=="Lwc"){
                console.log("save");
                this.dispatchEvent(new CustomEvent('save',{bubbles: true}));
        }else{
             const navigateNextEvent = new FlowNavigationNextEvent();
             console.log("save");
             this.dispatchEvent(navigateNextEvent);
        }
     }
     handleType()
     {
      let link;
      if(this.type=='List')
      {
        link= `${window.location.origin}/lightning/o/${this.object}/list`;
        if(this.recordId)
        {
         link+='?filterName='+this.recordId;
        }
        //https://sunbeltrentals--devpro5.sandbox.lightning.force.com/lightning/o/Account/list?filterName=00B8D0000046QPVUA2
      }
      else{
         link=`${window.location.origin}/lightning/r/${this.object}/${this.recordId}/view`;
        // https://sunbeltrentals--devpro5.sandbox.lightning.force.com/lightning/r/WorkOrder/0WO8D000000MAOsWAO/View
      }
      return link;
     }

     // To handle skip click
     handleSkip(){
        if(this.callFrom=="Lwc"){
                const navigateNextEvent = new FlowNavigationNextEvent();
                console.log("save");
                this.dispatchEvent(navigateNextEvent);
        }else{
             const navigateNextEvent = new FlowNavigationNextEvent();
             console.log("save");
             this.dispatchEvent(navigateNextEvent);
        }
     }
    
// Handle delete on cancel

handleCancelDelete(recId){
   console.log("Recc: "+recId);
  // deleteRecord(recId)
  getWoToBeDeleted({recordId : recId})
   .then((result) => {
      console.log("cancel Delete");
      console.log(JSON.stringify(result));
      this.dispatchEvent(new CustomEvent('cancel',{bubbles: true})); 
      console.log("Deletion Worked");
   }).catch(error=> {
         console.log(JSON.stringify(error));
         
   });

}
    
}