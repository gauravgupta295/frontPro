import { LightningElement, wire } from 'lwc';

import FORM_FACTOR from '@salesforce/client/formFactor'

import getVisualforceDomain from '@salesforce/apex/SBR_3_0_GoogleMapCmpController.getVisualforceDomain';
import getLightningDomain from '@salesforce/apex/SBR_3_0_GoogleMapCmpController.getLightningDomain';
import getAccounts from '@salesforce/apex/SBR_3_0_GoogleMapCmpController.getAccounts';

export default class SBR_3_0_GoogleMapCmp extends LightningElement {

    accounts;
    mapOptionsCenter;
    mapData;
    vfOrigin;
    ltngOrigin;
    iFrameURL;
    showSpinner;
    error;
    message;
    zoomLevel;

    // Wire getVisualforceDomain Apex method to a VF Domain
    @wire(getVisualforceDomain, {formFactor: FORM_FACTOR})
    wiredVFDomain({ error, data }) {
        if (data) {
            this.vfOrigin = 'https://' + data;
            console.log('this vfOrigin -> ', this.vfOrigin);
        } else if (error) {
            this.error = error;
            this.vfOrigin = undefined;
        }
    }

    // Wire getLightningDomain Apex method to a Lightning Domain
    @wire(getLightningDomain)
    wiredLtngDomain({ error, data }) {
        if (data) {
            this.ltngOrigin = data + '/';
            this.iFrameURL = '/apex/SBR_3_0_GoogleMap?lcHost=' + this.ltngOrigin;
            console.log('this ltngOrigin -> ', this.ltngOrigin);
            console.log('this iFrameURL -> ', this.iFrameURL);
        } else if (error) {
            this.error = error;
            this.ltngOrigin = undefined;
        }
    }

    @wire(getAccounts)
    wiredAccounts({ error, data }) {
        if (data) {
            console.log('wire data returned ->', data);
            this.accounts = data;
            this.error = undefined;
            var acc = data;
            if(acc.length > 0){
                //var mapOptionsCenter = {'lat' : parseFloat(acc[0].Latitude__c), 
                //                        'lng' : parseFloat(acc[0].Longitude__c)};
                var mapOptionsCenter = {'lat' : 37.7749,
                                        'lng' : -122.4194};
                var mapData = Array();
                for(var i = 0; i < acc.length; i++){
                    mapData.push({
                                'myLoc' : 'false',
                                'id' : acc[i].Id,
                                'lat' : parseFloat(acc[i].Latitude__c), 
                                'lng' : parseFloat(acc[i].Longitude__c), 
                                'name' : acc[i].Name,
                                'street': acc[i].BillingStreet,
                                'city': acc[i].BillingCity,
                                'state': acc[i].BillingState,
                                'postal': acc[i].BillingPostalCode})
                }
            }
            console.log('mapData -> ', mapData);
            console.log('mapOptionsCenter -> ', mapOptionsCenter);
            this.mapOptionsCenter = mapOptionsCenter;
            this.mapData = mapData;

        } else if (error) {
            this.error = error;
            this.accounts = undefined;
        }
    }

    constructor(){
        console.log('constructor...');
        super();
        this.zoomLevel = 12;
        window.addEventListener('message', e => {
            console.log('e.origin -> ', e.origin);
            console.log('this.vfOrigin.data -> ', this.vfOrigin);
            /*if(e.origin != this.vfOrigin) {
                return;
            }*/
            this.sendData(e);
        }, false);
    }

    sendData(e){
        console.log('in send data...', e);
        
        var message = {
            'loadGoogleMap' : true,
            'mapData': this.mapData, 
            'mapOptions': '{"zoom": ' + this.zoomLevel + '}',  
            'mapOptionsCenter': this.mapOptionsCenter
        };

        this.template.querySelector('iframe').contentWindow.postMessage(message, this.vfOrigin);
        console.log('LWC sent data...');
    }

    handleClick(){
        console.log('navigator ->', navigator);
        this.showSpinner = true;
        if (navigator.geolocation) {
            navigator.geolocation.getCurrentPosition(position => {
                console.log('getting geo in lwc');
                this.showSpinner = false;
                // Get the Latitude and Longitude from Geolocation API
                var userLatitude = position.coords.latitude;
                var userLongitude = position.coords.longitude;
                
                var mapOptionsCenter = {'lat':parseFloat(userLatitude), 
                                        'lng':parseFloat(userLongitude)};
                var mapData = Array();
                for(var i = 0; i < this.mapData.length; i++){
                    var elem = this.mapData[i];
                    mapData.push(elem);
                }

                mapData.push({
                    'myLoc' : 'true',
                    'id': '0',
                    'lat': parseFloat(userLatitude), 
                    'lng': parseFloat(userLongitude), 
                    'name':'You are here'
                });

                this.mapData = mapData;
                this.mapOptionsCenter = mapOptionsCenter;
                this.zoomLevel = 6;

                this.sendData();
            });
        }
    }
}