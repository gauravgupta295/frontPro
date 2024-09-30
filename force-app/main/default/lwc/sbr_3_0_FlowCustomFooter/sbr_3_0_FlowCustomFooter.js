import { LightningElement, api, wire } from 'lwc';
import { FlowNavigationBackEvent, FlowNavigationNextEvent } from "lightning/flowSupport";
import { IsConsoleNavigation, getFocusedTabInfo, closeTab, openTab, setTabLabel, setTabIcon } from 'lightning/platformWorkspaceApi';
import { NavigationMixin } from 'lightning/navigation';
import lightningCancelModalLWC from 'c/sbr_3_0_sfsMobileGenericConfirmationModal';

export default class Sbr_3_0_FlowCustomFooter extends NavigationMixin(LightningElement) {

    @api showNextButton = false;
    @api lableNextButton;
    @api showPreviousButton = false;
    @api lablePreviousButton;
    @api showCancelButton = false;
    @api lableCancelButton;
    @api showSaveButton = false;
    @api lableSaveButton;
    @api recordId;
    @api object;
    @api isRedirectToURL = false;

    @wire(IsConsoleNavigation) isConsoleNavigation;

    connectedCallback(){
        if(this.isConsoleNavigation){
            getFocusedTabInfo().then((tabInfo) => {
                setTabLabel(tabInfo.tabId, "Review Work Order");
                setTabIcon(tabInfo.tabId, "utility:transport_light_truck");
            }).catch(function(error) {
                console.log(error);
            });
        }
    }

    // To handle previous click
    handlePrevious() {
        this.dispatchEvent(new FlowNavigationBackEvent());
    }

    // To handle next claick
    handleNext() {
        this.dispatchEvent(new FlowNavigationNextEvent());
    }

    // To handle cancel click
    async handleCancel() {
        await lightningCancelModalLWC.open({
            size        : 'small',
            description : 'Accessible description of modal purpose',
            content     : 'Are you sure ?',
            headerText  : 'Confirmation',
            onyesclick  : (e) => {
                
                this.closeTab();
            }
        });
    }

    // closes the flow screen
    closeTab(){
        if(this.isConsoleNavigation){
            getFocusedTabInfo().then((tabInfo) => {
                console.log('@@@@ tabInfo ==>> ', tabInfo);
                openTab({
                    recordId : this.recordId,
                    focus    : true
                }).then(response => {
                    if(tabInfo.tabId != response){
                        closeTab(tabInfo.tabId);
                    } else {
                        window.location.reload();
                    }
                });
            }).catch(function(error) {
                console.log(error);
            });
        } else {
            this.navigateToRecord();
        }
    }

    // navigate to the record page
    navigateToRecord(){
        console.log('@@@@ record ID ==>> ', this.recordId);
        if(this.isRedirectToURL)
        {
            //window.open('/'+this.recordId);
            window.location = '/'+this.recordId;
        }
        else
        {
            this[NavigationMixin.Navigate]({
                type : 'standard__recordPage',
                attributes : {
                    recordId : this.recordId,
                    objectApiName: this.object,
                    actionName: 'view',
                }
            });
        }
    }
}