import { LightningElement, api } from "lwc";
import { isMobile, ACCORDION_VIEW } from "c/sbr_3_0_dynamicRecordFormUtility";
import DEFAULT_DESKTOP_TEMPLATE from "./desktop/default.html";
import MOBILE_MULTI_SECTION_TEMPLATE from "./mobile/multiSection.html";
import MOBILE_SINGLE_SECTION_TEMPLATE from "./mobile/singleSection.html";
import MOBILE_MULTI_PAGE_TEMPLATE from "./mobile/multiPage.html";

export default class Sbr_3_0_dynamicRecordFormPage extends LightningElement {
  static renderMode = "light"; // the default is 'shadow'
  _page;
  activeSection = [];
  isMobile = isMobile;
  hasMultiplePanels = true;
  hasRendered = false;
  @api
  get page() {
    return this._page;
  }

  set page(value) {
    this._page = value;
    this.hasMultiplePanels = this.page.sections.length > 1;
    if (!isMobile) {
      this.activeSection = this._page.sections.map((section) => {
        if (!section.IsCollapsible) return section.externalId;
        return null;
      });
    }
  }

  @api
  recordId;
  @api
  objectApiName;
  mobileProps = {
    variant: "static"
  };

  @api
  viewMode = ACCORDION_VIEW;

  render() {
    let template;
    if (this.isMobile) {
      if (this.page.hasChildrenPages) {
        template = MOBILE_MULTI_PAGE_TEMPLATE;
      } else if (this.hasMultiplePanels && this.viewMode !== ACCORDION_VIEW) {
        template = MOBILE_MULTI_SECTION_TEMPLATE;
      } else {
        template = MOBILE_SINGLE_SECTION_TEMPLATE;
      }
    } else {
      template = DEFAULT_DESKTOP_TEMPLATE;
    }
    return template;
  }

  handleTogglePanelOnClick(event) {
    event.stopPropagation();
    let targetPanelId = event.target.dataset.targetPanelId;
    this.togglePanel(targetPanelId);
  }

  handleToggleOnLoad(targetPanelId) {
    this.togglePanel(targetPanelId);
  }

  togglePanel(targetPanelId) {
    if (targetPanelId) {
      let targetPanel = this.querySelector(
        `div[data-panel-id="${targetPanelId}"]`
      );
      let tabList = this.querySelector(".tab-list");
      let mobileScreen = this.querySelector(
        `c-sbr_3_0_mobile-screen[data-panel-id="${targetPanelId}"]`
      );
      if (targetPanel) {
        this.isPanelOpen = !this.isPanelOpen;
        targetPanel.classList.toggle("slds-hide");
        targetPanel.classList.toggle("slds-is-open");
        if (this.isPanelOpen) {
          targetPanel.removeAttribute("hidden");
        } else {
          targetPanel.setAttribute("hidden", "");
        }
        if (tabList) {
          tabList.classList.toggle("slds-hide");
        }
        if (mobileScreen) {
          mobileScreen.toggleScreen({
            hidePreviousTitle: true,
            hidePreviousFooter: false
          });
        }
      }
    }
  }
}