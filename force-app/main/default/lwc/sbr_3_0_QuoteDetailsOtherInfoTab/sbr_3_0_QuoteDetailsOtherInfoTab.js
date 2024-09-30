import { LightningElement, api, wire } from "lwc";
import { getRecord, getFieldValue, getFieldDisplayValue } from 'lightning/uiRecordApi';

import TAXABLE from "@salesforce/schema/SBQQ__Quote__c.Taxable__c";
import RENTAL_TAX_EXEMPT_CODE from "@salesforce/schema/SBQQ__Quote__c.Rental_Tax_Exempt_Code__c";
import TAX_DISTRICT from "@salesforce/schema/SBQQ__Quote__c.Tax_District__c";
import GST_TAX from "@salesforce/schema/SBQQ__Quote__c.GST_Tax__c";
import SALES_TAX_EXEMPT_CODE from "@salesforce/schema/SBQQ__Quote__c.Sales_Tax_Exempt_Code__c";
import TAX_RATE_USED from "@salesforce/schema/SBQQ__Quote__c.Tax_Rate_Used__c";
import PST_TAX from "@salesforce/schema/SBQQ__Quote__c.PST_Tax__c";


import FORM_FACTOR from "@salesforce/client/formFactor";

const SMALL_FORM_FACTOR = "Small"; 


export default class Sbr_3_0_QuoteDetailsOptionsTab extends LightningElement {
    @api recordId;
    @api objectApiName;

    isOpen = true;
    taxable;
    rentalTaxExemptCode;
    taxDistrict;
    gstTax;
    salesTaxExemptCode;
    taxRateUsed;
    pstTax;
    readOnly = true;
    options = [
        { label: 'Taxable', value: true },
        { label: 'Non-Taxable', value: false }
    ]

    @wire(getRecord, { recordId: '$recordId', fields: [TAXABLE, RENTAL_TAX_EXEMPT_CODE, TAX_DISTRICT, GST_TAX, SALES_TAX_EXEMPT_CODE, TAX_RATE_USED, PST_TAX] })
    wiredRecord({ error, data }) {
        if (data) {
            this.taxable = getFieldValue(data, TAXABLE)
            this.rentalTaxExemptCode = getFieldValue(data, RENTAL_TAX_EXEMPT_CODE);
            this.taxDistrict = getFieldValue(data, TAX_DISTRICT);
            this.gstTax = getFieldDisplayValue(data, GST_TAX);
            this.salesTaxExemptCode = getFieldValue(data, SALES_TAX_EXEMPT_CODE);
            this.taxRateUsed = getFieldValue(data, TAX_RATE_USED);
            this.pstTax = getFieldDisplayValue(data, PST_TAX);
            console.log("DATA", data);
        } else if (error) {
            console.error('Error loading record', error);
        } 
    }

    get isMobile() {
        return FORM_FACTOR === SMALL_FORM_FACTOR;
    }

    toggleSection() {
        this.isOpen = !this.isOpen;
    }
}