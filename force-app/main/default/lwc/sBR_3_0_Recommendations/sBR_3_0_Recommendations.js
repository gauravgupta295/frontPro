import { LightningElement,api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import updateRecommendations from '@salesforce/apex/SBR_3_0_CustomerMaturityModelController.updateRecommendations';
import FORM_FACTOR from "@salesforce/client/formFactor";

export default class SBR_3_0_Recommendations extends LightningElement {
    @api upSellResponse;
    @api crossSellResponse;
    @api isUpsellNULL;
    @api isCrosssellNULL;
    @api isServerDown;
    @api accountRec;
    @api errorMessage;
    @api isServerUpWithError;
    @api errorMessageRec;
    @api titleselectthumbsupthumbsdown;
    @api tabletitleupsell;
    @api tabletitlecrosssell;
    @api tablecolumncatclass;
    @api tablecolumndescription;
    @api tablecolumnfeedback;
    @api buttonsubmitfeedback;
    @api pleaseprovideanycomments;
    isRecommendationTab = true;
    Recommendations = new Map();
    likeState;
    dislikeState;
    disableSubmitAction = true;
    isModalOpen = false;
    additionalComments;
    isLoaded = true;
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
        this.isRecommendationTab = true;
    }
    closeModal() {
        this.isModalOpen = false;
    }
    handleRefresh(){
        const event = new CustomEvent('refreshmodel');
        this.dispatchEvent(event);
    }
    handleCloseModal(event){
        this.isModalOpen = false;
        this.isLoaded = true;
    }
    handleFeedbackSubmission(event) {
        this.additionalComments = event.detail.additionalComments;
        this.isModalOpen = false;
        this.isLoaded = false;
        var Values = new Array();
        for (let [key, value] of  this.Recommendations.entries()) {
            Values.push(value);
        }
        updateRecommendations   ({  
                                    Recommendations: Values,
                                    AdditionalComments : this.additionalComments,
                                    accountRec : this.accountRec
                                })
            .then((RecordsData) => {
                this.disableSubmitAction = true;
                const event = new ShowToastEvent({
                    message: 'Feedback has been shared. Thank you.',
                    variant: 'success',
                    mode: 'dismissable'
                });
                this.dispatchEvent(event);
                this.isLoaded = true;
            })
            .catch((error) => {
                const event = new ShowToastEvent({
                    message: error.body.message,
                    variant: 'error',
                    mode: 'dismissable'
                });
                this.dispatchEvent(event);
                this.isLoaded = true;
            });
    }
    submitFeedback(event){
       this.isModalOpen = true;
    }
    handleButtonClick(event) {
        console.log("Dataset ",JSON.stringify(event.target.dataset));
        var dataName = event.target.dataset.name;
        var dataId = event.target.dataset.id;
        var dataState = event.target.dataset.state;
        this.Recommendations.set(dataName,JSON.stringify(event.target.dataset));
        if(dataId == "Upsell"){
            let upselllikeTarget = this.template.querySelector(`[data-name="${dataName}"][data-id="Upsell"][data-state="like"]`);
            let upselldislikeTarget = this.template.querySelector(`[data-name="${dataName}"][data-id="Upsell"][data-state="dislike"]`);
            if(dataState == "like"){
                if(upselllikeTarget.selected){
                    upselllikeTarget.selected = false;
                }
                else if(!upselllikeTarget.selected){
                    upselllikeTarget.selected = true;
                    upselldislikeTarget.selected = false;
                }
                var Selected = upselllikeTarget.selected;
                if(!Selected){
                    if(this.Recommendations.has(dataName)){
                        this.Recommendations.delete(dataName);
                        if(this.Recommendations.size == 0){
                            this.disableSubmitAction = true;
                        }
                    }
                }
                else{
                    this.disableSubmitAction = false;
                }
            }
            else if(dataState == "dislike"){
                if(upselldislikeTarget.selected){
                    upselldislikeTarget.selected = false;
                }
                else if(!upselldislikeTarget.selected){
                    upselldislikeTarget.selected = true;
                    upselllikeTarget.selected = false;
                }
                var Selected = upselldislikeTarget.selected;
                if(!Selected){
                    if(this.Recommendations.has(dataName)){
                        this.Recommendations.delete(dataName);
                        if(this.Recommendations.size == 0){
                            this.disableSubmitAction = true;
                        }
                    }
                }
                else{
                    this.disableSubmitAction = false;
                }
            }
        }
        else if(dataId == "Crosssell"){
            let crossselllikeTarget = this.template.querySelector(`[data-name="${dataName}"][data-id="Crosssell"][data-state="like"]`);
            let crossselldislikeTarget = this.template.querySelector(`[data-name="${dataName}"][data-id="Crosssell"][data-state="dislike"]`);
            if(dataState == "like"){
                if(crossselllikeTarget.selected){
                    crossselllikeTarget.selected = false;
                }
                else{
                    crossselllikeTarget.selected = true;
                    crossselldislikeTarget.selected = false;
                }
                var Selected = crossselllikeTarget.selected;
                if(!Selected){
                    if(this.Recommendations.has(dataName)){
                        this.Recommendations.delete(dataName);
                        if(this.Recommendations.size == 0){
                            this.disableSubmitAction = true;
                        }
                    }
                }
                else{
                    this.disableSubmitAction = false;
                }
            }
            else if(dataState == "dislike"){
                if(crossselldislikeTarget.selected){
                    crossselldislikeTarget.selected = false;
                }
                else{
                    crossselldislikeTarget.selected = true;
                    crossselllikeTarget.selected = false;
                }
                var Selected = crossselldislikeTarget.selected;
                if(!Selected){
                    if(this.Recommendations.has(dataName)){
                        this.Recommendations.delete(dataName);
                        if(this.Recommendations.size == 0){
                            this.disableSubmitAction = true;
                        }
                    }
                }
                else{
                    this.disableSubmitAction = false;
                }
            }
        }
    }
}