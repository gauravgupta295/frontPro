import { LightningElement,api,wire } from 'lwc';
import FORM_FACTOR from "@salesforce/client/formFactor";


export default class SBR_3_0_Power_Of_Sunbelt_Summary extends LightningElement {
    @api currentLOBUsed;
    @api noOfProductsRented;
    @api currentTTMSpent;
    @api potentialLOBUsed; 
    @api currentLOB; 
    @api potentialLOB;   
    @api isCurrentLOBNULL;
    @api isPotentialLOBNULL;
    @api customLabelsMap;
    @api isServerDown;
    @api isError;
    @api errorMessage;
    @api errorMessageRec;
    @api isServerUpWithError;
    @api tilecurrentlob;
    @api tilettmspend;
    @api tilenoofproductsrented;
    @api tilepotentiallob;
    @api titlecurrentlineofbusiness;
    @api titlepotentiallineofbusiness;

    isRecommendationTab = false;
    connectedCallback() {
        if (FORM_FACTOR === "Large") {
            this.deviceTypeDesktp = true;
        } 
        else if (FORM_FACTOR === "Medium") {
            this.deviceTypeTablet = true;
        } 
        else if (FORM_FACTOR === "Small") {
            this.deviceTypeMobile = true;
        }
        const isiPad = /iPad/i.test(navigator.userAgent);
        const isPortrait = window.innerHeight > window.innerWidth;
        window.addEventListener('orientationchange', () => {
            if (window.orientation === 0) {
            } 
            else {
            }
        });
        this.isRecommendationTab = false;
    }
    handleRefresh(){
        const event = new CustomEvent('refreshmodel');
        this.dispatchEvent(event);
    }
}