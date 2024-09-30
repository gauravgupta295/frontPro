import { LightningElement, api, track } from "lwc";
import FrontLineCSS from "@salesforce/resourceUrl/FrontLinesCSS";
import { loadStyle } from "lightning/platformResourceLoader";

export default class Sbr_3_0_customTooltipCmp extends LightningElement {
  @api iconVariant;
  @api iconName;
  @api content;
  @api iconSize = "x-small";
  showTooltip;
  hideToooltip = false;

  //START FRONT-1950
  connectedCallback() {
    this.loadStyleSheet();
    if(this.content===""){
      this.hideToooltip = true;
    } else {
      this.hideToooltip = false;
    }
  }

  renderedCallback(){ //FRONT-11845
    if(this.iconName === "utility:warning"){
      this.template.querySelector('[icon-name="utility:warning"]').className='warningClass';
    }
  }

  loadStyleSheet() {
    loadStyle(this, FrontLineCSS);
  }
  //END FRONT-1950

  toggleTooltip() {
    this.showTooltip = !this.showTooltip;
  }

  get tooltipClass() {
    //ADDED FOR FRONT-1950
    if(this.iconVariant==='topToolTip'){
      return 'slds-popover slds-popover_tooltip slds-nubbin_bottom-left tooltip-topToolTip info-mobile-tooltip';
    } else if(this.iconVariant==='rightToolTip'){
      return 'slds-popover slds-popover_tooltip slds-nubbin_left tooltip-rightToolTip info-mobile-tooltip';
    } 
    //ADDED FOR FRONT-11845
    else if(this.iconVariant==='topToolTipError'){
      return 'slds-popover slds-popover_tooltip slds-nubbin_bottom-left tooltip-topToolTipError info-mobile-tooltip';
    } else if(this.iconVariant==='rightToolTipError'){
      return 'slds-popover slds-popover_tooltip slds-nubbin_left tooltip-rightToolTipError info-mobile-tooltip';
    } else {
      return `slds-popover slds-popover_tooltip slds-nubbin_bottom-left tooltip-${this.iconVariant}`;
    }   
  }
}