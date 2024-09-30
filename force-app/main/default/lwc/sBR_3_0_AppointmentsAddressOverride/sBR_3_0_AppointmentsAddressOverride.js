import { LightningElement, api, wire } from 'lwc';
import getAddressLatLong from '@salesforce/apex/SBR_3_0_EventOperations.getAddressLatLong';
import getEventById from '@salesforce/apex/SBR_3_0_EventOperations.getEventById';
import updateEvent from '@salesforce/apex/SBR_3_0_EventOperations.updateEvent';
import { FlowNavigationFinishEvent } from 'lightning/flowSupport';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import STATES from '@salesforce/schema/Location.State__c';
import LOCATION from '@salesforce/schema/Location';
export default class SBR_3_0_AppointmentsAddressOverride extends LightningElement {
    @api recordId;
    street;
    city;
    state;
    country;
    zipCode;
    updateAddress;
    badInputMessage = 'City and state are required or zip code';
    statesPicklistValues = [];
    spinnerShow;
    cityValidity;
    stateValidity;
    zipCodeValidity;

    get countryPicklistValues() {
        return [
            { label: 'United States', value: 'US' },
            { label: 'Canada', value: 'CA' }
        ];
    }

    @wire(getObjectInfo, { objectApiName: LOCATION })
    objectInfo;

    @wire(getPicklistValues, {
        recordTypeId: '$objectInfo.data.defaultRecordTypeId',
        fieldApiName: STATES
    })
    getPicklistValuesForField({ data }) {
        if (data) {
            this.statesPicklistValues = [...data.values];
        }
    }
    async connectedCallback() {
        const event = await getEventById({ eventId: this.recordId });
        this.street = event.Street__c;
        this.city = event.City__c;
        this.state = event.State__c;
        this.zipCode = event.ZIP_Code__c;
        this.country = event.Country__c;
        this.updateAddress = !event.Override_System_Address_Updates__c;
        if (event.Override_System_Address_Updates__c) {
            this.restoreOriginalAddress();
        }
    }

    handleChange(event) {
        switch (event.target.label) {
            case 'Street':
                this.street = event.detail.value;
                break;
            case 'City':
                this.city = event.detail.value;
                break;
            case 'State':
                this.state = event.detail.value;
                break;
            case 'ZIP Code':
                this.zipCode = event.detail.value;
                break;
            case 'Country':
                this.country = event.detail.value;
                break;
            default:
                break;
        }
        this.validateAddress();
    }

    async overrideAddress() {
        if (this.zipCode || (this.city && this.state)) {
            this.spinnerShow = true;
            const payload = {
                eventId: this.recordId,
                street: this.street,
                city: this.city,
                state: this.state,
                country: this.country,
                zipCode: this.zipCode
            };
            const result = await getAddressLatLong({ payload: payload });
            if (result) {
                this.spinnerShow = false;
                const navigateFinishEvent = new FlowNavigationFinishEvent();
                this.dispatchEvent(navigateFinishEvent);
            }
        } else if (!this.cityValidity) {
            this.template.querySelector(`[data-id="city"]`).setCustomValidity(this.badInputMessage);
        } else if (!this.stateValidity) {
            this.template.querySelector(`[data-id="state"]`).setCustomValidity(this.badInputMessage);
        } else if (!this.zipCodeValidity) {
            this.template.querySelector(`[data-id="zipCode"]`).setCustomValidity(this.badInputMessage);
        }
    }

    async restoreOriginalAddress() {
        this.spinnerShow = true;
        const payload = {
            eventId: this.recordId,
            OverrideSystemAddress: this.updateAddress
        };
        await updateEvent({ payload: payload });
        this.spinnerShow = false;
        const navigateFinishEvent = new FlowNavigationFinishEvent();
        this.dispatchEvent(navigateFinishEvent);
    }

    validateAddress() {
        const cityInput = this.template.querySelector('[data-id="city"]');
        const stateInput = this.template.querySelector('[data-id="state"]');
        const zipCodeInput = this.template.querySelector('[data-id="zipCode"]');

        if (!(this.zipCode || (this.city && this.state))) {
            cityInput.setCustomValidity(this.badInputMessage);
            zipCodeInput.setCustomValidity(this.badInputMessage);
        } else {
            cityInput.setCustomValidity('');
            zipCodeInput.setCustomValidity('');
        }

        this.cityValidity = cityInput.checkValidity();
        this.stateValidity = stateInput.checkValidity();
        this.zipCodeValidity = zipCodeInput.checkValidity();

        cityInput.reportValidity();
        stateInput.reportValidity();
        zipCodeInput.reportValidity();
    }
}