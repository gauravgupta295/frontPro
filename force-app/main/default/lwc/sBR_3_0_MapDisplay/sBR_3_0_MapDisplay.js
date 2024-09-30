import { LightningElement, api, wire, track } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import STREET_FIELD from '@salesforce/schema/AssociatedLocation.Street_Address__c';
import CITY_FIELD from '@salesforce/schema/AssociatedLocation.City__c';
import STATE_FIELD from '@salesforce/schema/AssociatedLocation.State__c';
import POSTAL_CODE_FIELD from '@salesforce/schema/AssociatedLocation.Zip_Code__c';
import COUNTRY_FIELD from '@salesforce/schema/AssociatedLocation.Country__c';

const LATITUDE_FIELD = 'AssociatedLocation.Latitude_Longitude__Latitude__s';
const LONGITUDE_FIELD = 'AssociatedLocation.Latitude_Longitude__Longitude__s';

export default class SBR_3_0_MapDisplay extends LightningElement {
    @api recordId;
    @track record;
    @track error;

    zoomLevel = 15;

    @track mapMarkers = [];
    mapOptions = {
        draggable: false,
        disableDefaultUI: true
    };
    
    @wire(getRecord, { recordId: '$recordId', fields: [LATITUDE_FIELD, LONGITUDE_FIELD, STREET_FIELD, CITY_FIELD, STATE_FIELD, POSTAL_CODE_FIELD, COUNTRY_FIELD] })
    jobSite({ error, data }) {
        if(data) {
            this.record = data;
            this.error = undefined;
            this.fillMapMarker();
        } 
        else if (error) {
            this.error = error;
            this.record = undefined;
        }
    };

    fillMapMarker() {
        let mark = {
            location: {
                City: this.record.fields.City__c.value,
                Country: this.record.fields.Country__c.value,
                PostalCode: this.record.fields.Zip_Code__c.value,
                State: this.record.fields.State__c.value,
                Street: this.record.fields.Street_Address__c.value,
                Latitude: this.record.fields.Latitude_Longitude__Latitude__s.value,
                Longitude: this.record.fields.Latitude_Longitude__Longitude__s.value
            },
            // title: 'Location',
            // icon: 'standard:AssociatedLocation'
        };

        let marker = [];
        marker.push(mark);
        this.mapMarkers = marker;
    }
}