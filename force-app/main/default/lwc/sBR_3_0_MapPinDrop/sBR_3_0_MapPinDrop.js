import { LightningElement, wire, api, track } from "lwc";

import FORM_FACTOR from "@salesforce/client/formFactor";
import { NavigationMixin } from "lightning/navigation";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

import getVisualforceDomain from "@salesforce/apex/SBR_3_0_GoogleMapCmpController.getVisualforceDomain";

import { getPicklistValues, getObjectInfo } from "lightning/uiObjectInfoApi";
import ACCOUNT_OBJECT from "@salesforce/schema/Account";
import ACCOUNT_COUNTRY_CODE from "@salesforce/schema/Account.BillingCountryCode";
import ACCOUNT_STATE_CODE from "@salesforce/schema/Account.BillingStateCode";
import EDITINFOMAPPINDROPTEMPLATE from "./editInfoMapPinDrop.html";
import DEFAULTTEMPLATE from "./sBR_3_0_MapPinDrop.html";

const { userAgent } = navigator;

export default class SBR_3_0_MapPinDrop extends NavigationMixin(
  LightningElement
) {
  loadGoogleMap = true;

  showFilters = false;
  filterWrapper;

  showRecordForm = false;
  showCreateForm = false;
  recordFormWrapper;

  recordFormObjectShow;
  recordFormIdShow;
  recordFormIconShow;
  recordFormTitleShow;
  recordFormWrapperShow;

  recordFormIdCreate;
  recordFormObjectCreate;
  recordFormIconCreate;
  recordFormWrapperCreate;
  recordFormTitleCreate;

  isNextDisabled = true;
  showSelectionScreen = true;
  isLatLngNotPopulated = true;

  @api pinDropLabel;
  @api pinDropLat;
  @api pinDropLng;
  @api pinDropStreet;
  @api pinDropCity;
  @api pinDropState;
  @api pinDropFullState;
  @api pinDropCounty;
  @api pinDropCountry;
  @api pinDropZip;
  @api pinDropIsUsed = false;
  @api pinCopyAddrFromLocation = false;
  @api locationStreet;
  @api countQuoteScreenVisit = 1;
  dropPin = false;

  pageNo = 1;
  recordsToDisplay;
  recordsPerPage = 50;
  totalPages = 0;
  pageIndexStart = 0;
  pageIndexEnd = 0;
  pageTotalRecords;
  disablePrev = true;
  disableNext = true;
  orderBy = "ASC";
  orderByDisplay = "utility:sort";

  mapData = [];
  mapOptionsCenter = { lat: 37.7749, lng: -122.4194 };
  vfOrigin;
  ltngOrigin;
  iFrameURL;
  showSpinner;
  error;
  message;
  zoomLevel;
  baseURL;
  rendered = false;
  statesLoaded = false;

  @track _countries = [];
  @track _countryToStates = {};

  @wire(getObjectInfo, { objectApiName: ACCOUNT_OBJECT })
  accountObjectInfo;

  @wire(getPicklistValues, {
    recordTypeId: "$accountObjectInfo.data.defaultRecordTypeId",
    fieldApiName: ACCOUNT_COUNTRY_CODE
  })
  countryPicklistValues({ error, data }) {
    this._countries = data?.values;
  }

  @wire(getPicklistValues, {
    recordTypeId: "$accountObjectInfo.data.defaultRecordTypeId",
    fieldApiName: ACCOUNT_STATE_CODE
  })
  statePicklistValues({ error, data }) {
    if (!data) {
      return;
    }

    const validForNumberToCountry = Object.fromEntries(
      Object.entries(data.controllerValues).map(([key, value]) => [value, key])
    );
    this._countryToStates = data.values.reduce((accumulatedStates, state) => {
      const countryIsoCode = validForNumberToCountry[state.validFor[0]];

      return {
        ...accumulatedStates,
        [countryIsoCode]: [
          ...(accumulatedStates?.[countryIsoCode] || []),
          { label: state.label, value: state.value }
        ]
      };
    }, {});
    this.statesLoaded = true;
  }

  get countries() {
    return this._countries;
  }

  get states() {
    return this._countryToStates[this.pinDropCountry] || [];
  }

  renderedCallback() {
    if (!this.rendered) {
      this.baseURL = window.location.origin;
      this.iFrameURL = "/apex/SBR_3_0_GoogleMapPinDrop?lcHost=" + this.baseURL;
      this.rendered = true;
      this.checkLatLongPopulated();
    }
  }

  handleAddressChange(event) {
    let address = this.template.querySelector("lightning-input-address");

    this.pinDropCity = address.city;
    this.pinDropState = address.province;
    this.pinDropStreet = address.street;
    this.pinDropZip = address.postalCode;
    this.pinDropCountry = address.country;
  }

  handleCoordinateChange(event) {
    var id = event.target.id;
    if (id.indexOf("lat") > -1) {
      this.pinDropLat = event.target.value;
    } else if (id.indexOf("lng") > -1) {
      this.pinDropLng = event.target.value;
    }
    this.checkLatLongPopulated();
  }

  checkLatLongPopulated() {
    if (
      this.pinDropLat !== null &&
      this.pinDropLng !== null &&
      typeof this.pinDropLat !== "undefined" &&
      typeof this.pinDropLng !== "undefined" &&
      this.pinDropLat !== "" &&
      this.pinDropLng !== ""
    ) {
      this.isLatLngNotPopulated = false;
    } else {
      this.isLatLngNotPopulated = true;
    }
  }

  // Wire getVisualforceDomain Apex method to a VF Domain
  @wire(getVisualforceDomain, { formFactor: FORM_FACTOR, userAgent: userAgent })
  wiredVFDomain({ error, data }) {
    console.log("Form factor -> " + FORM_FACTOR);
    if (data) {
      this.vfOrigin = "https://" + data;
      console.log("this vfOrigin -> ", this.vfOrigin);
    } else if (error) {
      this.error = error;
      this.vfOrigin = undefined;
    }
  }

  constructor() {
    super();
    this.zoomLevel = 12;
    //this.template.addEventListener('recordformaction', this.handleRecordFormAction);
    window.addEventListener(
      "message",
      (e) => {
        console.log("e.origin -> ", e.origin);
        console.log("this.vfOrigin.data -> ", this.vfOrigin);
        console.log("e.data.request -> ", e.data.request);
        console.log(JSON.stringify(e.data));
        if (e.data.request == "LOADED") {
          console.log("Loading Map...");
          if (this.pinDropLat && this.pinDropLng) {
            this.mapOptionsCenter.lat = this.pinDropLat;
            this.mapOptionsCenter.lng = this.pinDropLng;
            this.zoomLevel = 15;
            this.dropPin = true;
            var message = this.buildMapDataMessage();
            this.sendData(message);
            this.loadGoogleMap = false;
            this.dropPin = false;
          } else if (navigator.geolocation) {
            navigator.geolocation.getCurrentPosition(
              (position) => {
                console.log("getting geo in lwc");
                this.showSpinner = false;
                // Get the Latitude and Longitude from Geolocation API
                var userLatitude = position.coords.latitude;
                var userLongitude = position.coords.longitude;

                var myLocation = {
                  lat: parseFloat(userLatitude),
                  lng: parseFloat(userLongitude)
                };
                this.mapOptionsCenter.lat = myLocation.lat;
                this.mapOptionsCenter.lng = myLocation.lng;
                var message = this.buildMapDataMessage();
                this.sendData(message); // initial load of data - sends Data to VF page
                this.loadGoogleMap = false;
              },
              (error) => {
                console.log("Geo Location blocked...");
                var message = this.buildMapDataMessage();
                this.sendData(message); // initial load of data - sends Data to VF page
                this.loadGoogleMap = false;
              }
            );
          } else {
            var message = this.buildMapDataMessage();
            this.sendData(message); // initial load of data - sends Data to VF page
            this.loadGoogleMap = false;
          }
        } else if (e.data.request == "reloadMapData") {
          var message = this.buildMapDataMessage();
          this.sendData(message);
        } else if (e.data.request == "goToCurrentLocation") {
          console.log("go to current Location LWC");
          this.goToCurrentLocation();
        } else if (e.data.request == "panelAction") {
          console.log("panel action -> ", e.data.action);
          console.log(e.data);
          console.log("Stringify Proxy:");
          console.log(JSON.stringify(e.data));
          var action = e.data.action;

          if (action == "create") {
            console.log("panel action found street -> ", e.data.street);
            console.log(JSON.stringify(e.data));
            console.log(e.data.state);

            this.pinDropIsUsed = true;
            this.pinDropLabel = e.data.label;
            this.pinDropLat = e.data.lat;
            this.pinDropLng = e.data.lng;
            this.pinDropStreet = e.data.street;
            this.pinDropCity = e.data.city;
            this.pinDropState = e.data.state;
            this.pinDropFullState = e.data.fullState;
            this.pinDropCountry =
              e.data.country === "United States"
                ? "US"
                : e.data.country === "Canada"
                  ? "CA"
                  : "";
            this.pinDropZip = e.data.zip;
            let addressInput = this.template.querySelector(
              "lightning-input-address"
            );

            this.checkLatLongPopulated();
            if (addressInput != null) {
              addressInput.country = this.pinDropCountry;
              addressInput.province = this.pinDropState;
              addressInput.city = this.pinDropCity;
              addressInput.street = this.pinDropStreet;
              addressInput.postalCode = this.pinDropZip;
            }

            if (!this.formFactorIsLarge()) {
              this.dispatchEvent(
                new ShowToastEvent({
                  title: "Success",
                  message: "\nAddress captured.\nTap Next to proceed.",
                  variant: "success"
                })
              );
            }
          }
        }
      },
      false
    );
  }

  buildMapDataMessage() {
    var message = {
      loadGoogleMap: this.loadGoogleMap,
      mapOptions: '{"zoom": ' + this.zoomLevel + "}",
      mapOptionsCenter: this.mapOptionsCenter,
      dropPin: this.dropPin
    };
    return message;
  }

  sendData(message) {
    try {
      console.log("LWC sending data...");
      this.template
        .querySelector("iframe")
        .contentWindow.postMessage(JSON.stringify(message), this.vfOrigin);
      console.log("LWC data sent...");
    } catch (e) {
      console.log("ERROR Message -> ", e);
      console.log(JSON.stringify(e));
    }
  }

  goToCurrentLocation() {
    console.log("navigator ->", navigator);
    this.showSpinner = true;
    if (navigator.geolocation) {
      navigator.geolocation.getCurrentPosition((position) => {
        console.log("getting geo in lwc");
        this.showSpinner = false;
        // Get the Latitude and Longitude from Geolocation API
        var userLatitude = position.coords.latitude;
        var userLongitude = position.coords.longitude;

        var myLocation = {
          lat: parseFloat(userLatitude),
          lng: parseFloat(userLongitude)
        };
        console.log("user location ->", myLocation);

        var message = this.recenter(myLocation);
        this.sendData(message);
      });
    }
  }

  goToCoordinates() {
    console.log("navigator ->", navigator);
    // Get the Latitude and Longitude from Geolocation API

    var coordLocation = {
      lat: parseFloat(this.pinDropLat),
      lng: parseFloat(this.pinDropLng)
    };
    console.log("coord location ->", coordLocation);

    var message = this.recenter(coordLocation);
    this.sendData(message);
  }

  recenter(position) {
    var message = this.buildRecenterMessage(position);
    this.sendData(message);
  }

  buildRecenterMessage(latLng) {
    var message = {
      markerType: "recenter",
      position: latLng
    };
    return message;
  }

  formFactorIsLarge() {
    return FORM_FACTOR === "Large";
  }

  get showAddressFields() {
    return this.formFactorIsLarge();
  }

  //START: FRONT-20772 - to return the selected address to edit job site info component
  @api isEditInfoModal;
  @api
  getSelectedAddress() {
    let addressValues = {
      label: this.pinDropLabel,
      street: this.pinDropStreet,
      city: this.pinDropCity,
      state: this.pinDropState,
      fullState: this.pinDropFullState,
      country: this.pinDropCountry,
      postalZipCode: this.pinDropZip,
      latitude: this.pinDropLat,
      longitude: this.pinDropLng,
      locationStreet: this.locationStreet
    };
    return addressValues;
  }

  render() {
    if (this.isEditInfoModal) {
      return EDITINFOMAPPINDROPTEMPLATE;
    }
    return DEFAULTTEMPLATE;
  }
  //END: FRONT-20772
}