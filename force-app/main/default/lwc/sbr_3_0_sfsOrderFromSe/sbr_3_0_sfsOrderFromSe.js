import { LightningElement,api,track,wire } from 'lwc';
import  generateXML from '@salesforce/apex/SBR_3_0_SfsOrderFromSeController.generateXml';
import FORM_FACTOR from "@salesforce/client/formFactor";
import { NavigationMixin } from 'lightning/navigation';
import errorMessageRentReady from '@salesforce/label/c.SF_PS_Error_for_Rent_Ready';
import orderFromSeNote from '@salesforce/label/c.SF_PS_Message_For_ReturnToWO';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';



export default class Sbr_3_0_sfsOrderFromSe extends NavigationMixin(LightningElement){
    @api recordId;
    request;
    response;
    message
    deviceType
    spinner=false;
    WODesc
    msgTitle='Message:';
    //errorMsg='Parts are not allowed on a Rent Ready Inspection.';
    errorMessageRentReady=errorMessageRentReady;
    orderFromSeNote=orderFromSeNote;


    @track inputData={}
    showDescError=false;
    get isMessage()
    {
        if(this.message)
        {
            return true;
        }
        return false;
    }

    connectedCallback(){
       
        if (FORM_FACTOR === "Large") {
            this.deviceType = "Desktop";
        }
        else{
            this.deviceType='Phone';
        }
        console.log('this is form factor '+ FORM_FACTOR);
 
       this.spinner=true;
       this.callGenerateXml();
       
    }

    callGenerateXml()
    {
        let url= window.location.href;
        generateXML({recordId:this.recordId,deviceType:this.deviceType,url:url}).then((result) => {
            //console.log('TEST');
            //console.log('this is data '+JSON.stringify(result));
            this.request= result.request;
            this.response=result.response;

            //console.log(result.request);
            //console.log(result.response);
            
            if(result.statusCode=='200' )
            {
                let url=result.url;
                this.message=this.orderFromSeNote;
               this.msgTitle='';
                this[NavigationMixin.Navigate]({

                    type: 'standard__webPage',
            
                    attributes: {
            
                        url:url
            
                    }
                
            
                });
                this.spinner=false;

            }
            else {
                //console.log('here '+result.isRentReady);
                this.spinner=false;
                this.showDescError=Boolean(result.isRentReady)?true:false;
                this.message=result.message;
                this.statusCode=result.statusCode;

            }
        })
        .catch((error) => {
            this.spinner=false;
            this.error = error;
            console.log('ERROR ' +JSON.stringify(error));
            let message = 'Unknown error';
            if (Array.isArray(error)) {
                message = error.body.map(e => e.message).join(', ');
            } else if (typeof error.body.message === 'string') {
                message = error.message;
            }
            this.message=message;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error loading data',
                    message,
                    variant: 'error',
                }),
            );
        
        }); 

    }
}