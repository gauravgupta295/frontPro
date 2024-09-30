import { LightningElement,api } from 'lwc';
import LightningModal from 'lightning/modal';

export default class Sbr_3_0_sfsMobileGenericConfirmationModal extends LightningModal{

    @api content;
    @api contentHide;
    @api headerText;
    @api totalPartsAmt;
    @api laborTotal;
    @api travelTotal;
    @api miscTotal;
    // @api outSideLaborTotal;// Commented as per SERV-19167
    @api totalAmt;
    @api totalTaxOnSales;
    @api  totalinvoiceAmount;
    @api  totalStatetaxAmount;
    @api totalCountyTaxAmount;
    @api  companyCode;
    @api disableSave;
    @api showEstimatorButton;
    @api workOrderTypeIsQuote;
    @api errorMessage
    companyCode01;

    connectedCallback() {
        //code
        // console.log('outSideLaborTotal'+this.outSideLaborTotal);
        
        console.log('contentHide'+this.contentHide);
        if(this.companyCode == '01'){
            this.companyCode01 = true;
        }else {
            this.companyCode01 = false; 
        }
    }
    handleYes() {
        // Created the event with the data.
        const selectedEvent = new CustomEvent("yesclick");
        // Dispatches the event.
        this.dispatchEvent(selectedEvent); 
        console.log('yes hit');
        this.close('okay');
    }

    /**
     * This function dispatches yesclick event.c/bikeCard
     * @purpose | Once the tax modal is closed, it will call Damage Estimator screen.
     */
    handleSaveDamageEstimator()
    {
        //Create Attribute to be sent through Event
        var data = { detail: true };
        // Created the event with the data.
        const selectedEvent = new CustomEvent("yesdeclick", data);
        // Dispatches the event.
        this.dispatchEvent(selectedEvent); 
        console.log('yes hit');
        this.close('okay');
    }

    handleNo(){
        this.close('okay');
    }

}