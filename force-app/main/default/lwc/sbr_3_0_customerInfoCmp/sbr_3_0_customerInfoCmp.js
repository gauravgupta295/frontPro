import { api, wire, LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';


export default class Sbr_3_0_customerInfoCmp extends LightningElement {
    whereClause = "recordtype.name in ('Credit','Corp Link','Prospect','Non-Credit')";
    acctFields = "RM_Account_Number__c, ShippingCity, ShippingState, ShippingPostalCode, RM_Account_Number_Display__c, Status__c, Phone,Company_Code__c, E_mail_Address__c";//25958
    _customerInfo = null;

    isAddCustomerPanelVisible = false;
    closeIcon = 'slds-icon';
    closeIconSelected = 'slds-icon close-icon';
    isMobile = false;
    @api viewState;
    @api selectedProducts;
    
    @api
    get syncCustomer() {
        return this._customerInfo;
    }
    set syncCustomer(value) {
        this._customerInfo = value;
    }
    connectedCallback() {
        this.isMobile = window.matchMedia('(max-width: 480px)').matches;
    }
    updateCustomerPricing(event) {
        let selectedCustomer = event.detail;
        if (selectedCustomer.selectedRecord) {
            this._customerInfo = selectedCustomer.selectedRecord;
            console.log('@@vm33'+  JSON.stringify(this._customerInfo));
            try {
                const selectedCustomerEvent1 = new CustomEvent('customerselection', {
                    detail: {
                        selectedRecord: { ...this._customerInfo }
                    },
                    bubbles: true,
                    composed: true
                });
                console.log('selectedCustomerEvent1 customerinfo->'+JSON.stringify(event.detail));
                console.log('\n event - ' + JSON.stringify(selectedCustomerEvent1));
                this.dispatchEvent(selectedCustomerEvent1);
            }
            catch(error){
                console.log('\n dispatching customerselection event error ' + JSON.stringify(error));
            }
            switch(this.viewState){
                case 'base':
                    const toggleBasePanel = new CustomEvent('toggleprodinqmobilestate', {
                        bubbles: true,
                        composed: true,
                        'detail': {
                            viewState: 'base',
                            showTabsPanel: true,
                        }
                    });
                    this.dispatchEvent(toggleBasePanel);
                    const customerSelectedBase = new CustomEvent('sendcustomerselected', {
                        'detail': {
                            viewState: 'base',
                            isCustomerSelected: true
                        }
                    });
                    this.dispatchEvent(customerSelectedBase);
                    break;
                case 'item-spotlight':
                    let selectedProduct = this.selectedProducts;
                    const toggleprodinqmobilestate = new CustomEvent('toggleprodinqmobilestate', {
                        bubbles: true,
                        composed: true,
                        'detail': {
                            viewState: 'item-spotlight',
                            showTabsPanel: false,
                            product: selectedProduct
                        }
                    });
                    this.dispatchEvent(toggleprodinqmobilestate);
                    const customerSelectedSpotlight = new CustomEvent('sendcustomerselected', {
                        'detail': {
                            viewState: 'item-spotlight',
                            isCustomerSelected: true,
                            previousCustomer: true
                        }
                    });
                    this.dispatchEvent(customerSelectedSpotlight);
                    break;
                default:
                    break;
            }
            let accountName = this._customerInfo.Name;
            if (accountName === undefined || accountName === null) {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: `Account removed from Cart`,
                        variant: 'success',
                    }),
                );
            } else {
            this.dispatchEvent(
            new ShowToastEvent({
                title: 'Success',
                message: `Account ${accountName} added to Cart`,
                variant: 'success',
            }),
        );
        }
        } else {
            this.template.querySelector("c-sbr_3_0_modal-cmp").toggleModal();
            if(this._customerInfo){
                this._customerInfo = JSON.parse(JSON.stringify(this._customerInfo));
            }
            this.clearCustomer(event)
        }
        const customerSelectedSpotlight = new CustomEvent('sendcustomerselected', {
            'detail': {
                viewState: 'item-spotlight',
                isCustomerSelected: true,
                previousCustomer: true
            }
        });
        this.dispatchEvent(customerSelectedSpotlight);
        }
    
    clearCustomer = (event) => {
        event.stopPropagation();
        this.template.querySelector("c-sbr_3_0_modal-cmp").toggleModal();
        let accountName = this._customerInfo.Name;
        this._customerInfo = {};
        const selectedCustomerEvent = new CustomEvent('customerselection', { detail: {} });
        this.dispatchEvent(selectedCustomerEvent);
        switch(this.viewState){
            case 'base':
                const toggleBasePanel = new CustomEvent('toggleprodinqmobilestate', {
                    bubbles: true,
                    composed: true,
                    'detail': {
                        viewState: 'base',
                        showTabsPanel: true,
                    }
                });
                this.dispatchEvent(toggleBasePanel);
                const customerSelectedBase = new CustomEvent('sendcustomerselected', {
                    'detail': {
                        viewState: 'base',
                        isCustomerSelected: false
                    }
                });
                this.dispatchEvent(customerSelectedBase);
                break;
            case 'item-spotlight':
                let selectedProduct = this.selectedProducts;
                const toggleprodinqmobilestate = new CustomEvent('toggleprodinqmobilestate', {
                    bubbles: true,
                    composed: true,
                    'detail': {
                        viewState: 'item-spotlight',
                        showTabsPanel: false,
                        product: selectedProduct
                    }
                });
                this.dispatchEvent(toggleprodinqmobilestate);
                const customerSelectedSpotlight = new CustomEvent('sendcustomerselected', {
                    'detail': {
                        viewState: 'item-spotlight',
                        isCustomerSelected: false,
                        previousCustomer: false
                    }
                });
                this.dispatchEvent(customerSelectedSpotlight);
                break;
            default:
                break;
        }
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Success',
                message: `Account ${accountName} removed from Cart`,
                variant: 'success',
            }),
        );
        const customerSelectedSpotlight = new CustomEvent('sendcustomerselected', {
            'detail': {
                viewState: 'item-spotlight',
                isCustomerSelected: false,
                previousCustomer: false
            }
        });
        this.dispatchEvent(customerSelectedSpotlight);
    }
    togglePanel() {
        console.log('this.viewState === ' + this.viewState);
        //viewState should be item search or item spotlight

        switch(this.viewState){
            case 'base':
                const toggleBasePanel = new CustomEvent('toggleprodinqmobilestate', {
                    bubbles: true,
                    composed: true,
                    'detail': {
                        viewState: 'base',
                        showTabsPanel: true,
                    }
                });
                this.dispatchEvent(toggleBasePanel);
                break;
            case 'item-spotlight':
                let selectedProduct = this.selectedProducts;
                const toggleprodinqmobilestate = new CustomEvent('toggleprodinqmobilestate', {
                    bubbles: true,
                    composed: true,
                    'detail': {
                        viewState: 'item-spotlight',
                        showTabsPanel: false,
                        product: selectedProduct
                    }
                });
                this.dispatchEvent(toggleprodinqmobilestate);
                break;
            default:
                break;
        }
    }
}