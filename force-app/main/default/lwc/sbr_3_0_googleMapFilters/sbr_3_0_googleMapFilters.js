import { LightningElement, api, wire } from "lwc";
import userId from "@salesforce/user/Id";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getUsersProjectDodgeTypes from "@salesforce/apex/SBR_3_0_ProjectDA.getUsersProjectDodgeTypes";
import getUsersProjectDodgePhases from "@salesforce/apex/SBR_3_0_ProjectDA.getUsersProjectDodgePhases";
import getMaxRank from "@salesforce/apex/SBR_3_0_AccountDA.getAccountRelationshipsForUsersLowestRank";
import getLineOfBusinesses from "@salesforce/apex/SBR_3_0_BranchDA.getBranchesLineOfBusinesses";
import getUsersProjectMinValuation from "@salesforce/apex/SBR_3_0_ProjectDA.getUsersProjectMinValuation";
import isPECUser from "@salesforce/apex/SBR_3_0_ProjectDA.canUserViewPECProject";

export default class sbr_3_0_googleMapFilters extends LightningElement {
    @api filterWrapper;

    isPEC = false;
    
    // General Filters
    showAll = false;
    showAppointments = true;
    showTasks = true;
    showAccounts = true;
    showLeads = true;
    showJobSites = true;
    showProjects = true;
    showOpportunities = true;
    showBranches = false;
    userTerritories = userId;
    userId = userId;
    globalSearch;

    // Appt Filters
    appointmentSearch;
    apptParentType = "";
    openAppointments = true;
    todaysAppointments = true;
    next7DaysAppointments = false;
    thisWeekAppointments = false;
    nextWeekAppointments = false;
    nextXDaysAppointments = false;
    nextXDaysAppointmentsValue;
    dateRangeAppointments = false;
    dateRangeAppointmentsStart;
    dateRangeAppointmentsEnd;

    // Task Filters
    taskSearch;
    taskParentType = "";
    openTasks = true;
    todaysTasks = true;
    next7DaysTasks = false;
    thisWeekTasks = false;
    nextWeekTasks = false;
    nextXDaysTasks = false;
    nextXDaysTasksValue;
    dateRangeTasks = false;
    dateRangeTasksStart;
    dateRangeTasksEnd;

    // Account Filters
    searchAccounts;
    accountSearch;
    top25Accounts = true;
    top50Accounts = false;
    topXAccounts = false;
    topXAccountsValue;
    watchlistAccounts = false;
    dormantAccounts = false;
    rankRangeAccounts = false;
    rankRangeAccountsStart = 1;
    rankRangeAccountsEnd = 10;
    accountRecordTypePrevious = ['All'];
    accountRecordType = ['All'];
    showOffices = false;
    assignedAccountsOnly = false;
    includeTracked = false;

    // Lead Filters
    openLeads = true;
    leadShareLeads = false;
    campaignLeads = false;
    campaignType = '';

    // Job Sites Filters
    jobSiteSearch;
    activeJobSites = true;
    todayJobSites = false;
    yesterdayJobSites = false;
    nextXDaysJobSites = false;
    nextXDaysJobSitesValue;

    // Project Filters
    projectSearch;
    toggledProject = false;
    toggledBranch = false;
    cityProject = false;
    cityProjectValue;
    plantIdProject = false;
    plantIdProjectValue;
    plantNameProject = false;
    plantNameProjectValue;
    valuationProject = false;
    valuationProjectValue;
    valuationRangeProjects = true;
    valuationRangeProjectsStart = 1000000;
    valuationRangeProjectsEnd;
    squareFootageRangeProjects = false;
    squareFootageRangeProjectsStart;
    squareFootageRangeProjectsEnd;
    projectStatus = "";
    projectPrimaryType = []; // "Default";
    projectPrimaryTypePrevious = [];
    projectStage = "";
    projectOrigin = ['All'];
    projectOriginPrevious = ['All'];
    projectActivity = "";
    projectTiming = "";
    projectDodgePhase = []; // = "Default";
    projectDodgePhasePrevious = [];
    projectCreatedDate = 'All Time';
    dateRangeCreatedDateProjectsStart;
    dateRangeCreatedDateProjectsEnd;
    // Project Bid Date Filters
    next30DaysBidDateProject = true;
    lastXDaysBidDateProject = false;
    lastXDaysBidDateProjectValue;
    nextXDaysBidDateProject = false;
    nextXDaysBidDateProjectValue;
    dateRangeBidDateProjects = false;
    dateRangeBidDateProjectsStart;
    dateRangeBidDateProjectsEnd;
    // Project Completion Date Filters
    next30DaysCompletionDateProject = false;
    lastXDaysCompletionDateProject = false;
    lastXDaysCompletionDateProjectValue;
    nextXDaysCompletionDateProject = false;
    nextXDaysCompletionDateProjectValue;
    dateRangeCompletionDateProjects = false;
    dateRangeCompletionDateProjectsStart;
    dateRangeCompletionDateProjectsEnd;
    // Project Kickoff Date Filters
    next30DaysKickoffDateProject = true;
    lastXDaysKickoffDateProject = false;
    lastXDaysKickoffDateProjectValue;
    nextXDaysKickoffDateProject = false;
    nextXDaysKickoffDateProjectValue;
    dateRangeKickoffDateProjects = false;
    dateRangeKickoffDateProjectsStart;
    dateRangeKickoffDateProjectsEnd;
    // Project AFE Date Filters
    next30DaysAFEDateProject = false;
    lastXDaysAFEDateProject = false;
    lastXDaysAFEDateProjectValue;
    nextXDaysAFEDateProject = false;
    nextXDaysAFEDateProjectValue;
    dateRangeAFEDateProjects = false;
    dateRangeAFEDateProjectsStart;
    dateRangeAFEDateProjectsEnd;
    // Project RQF Date Filters
    next30DaysRQFDateProject = false;
    lastXDaysRQFDateProject = false;
    lastXDaysRQFDateProjectValue;
    nextXDaysRQFDateProject = false;
    nextXDaysRQFDateProjectValue;
    dateRangeRQFDateProjects = false;
    dateRangeRQFDateProjectsStart;
    dateRangeRQFDateProjectsEnd;

    // Opportunity Filters
    opportunitySearch;
    opportunityStagePrevious = ['All'];
    opportunityStage = ['All'];
    openOpportunity;
    closeDateNext30DaysOpportunity = true;
    closeDateLastXDaysOpportunity = false;
    closeDateLastXDaysOpportunityValue;
    closeDateNextXDaysOpportunity = false;
    closeDateNextXDaysOpportunityValue;
    estDateNext30DaysOpportunity = true;
    estDateLastXDaysOpportunity = false;
    estDateLastXDaysOpportunityValue;
    estDateNextXDaysOpportunity = false;
    estDateNextXDaysOpportunityValue;

    // Branch Filters
    branchSearch;
    lineOfBusiness = ['All'];
    lineOfBusinessPrevious = ['All'];
    country = 'All';
    lineOfBusinessOptions;
    lineOfBusinessData;
    isPicklistDisabled = false;
    loadBranchData = false;
    allBranches = false;

    async connectedCallback() {
        console.log("in filter constructor...");
        console.log(JSON.stringify(this.filterWrapper));
        console.log('this.userId -> ', this.userId);
        this.projectDodgePhase = []; // clears Default set in Apex to pull defaults on load
        this.projectPrimaryType = []; // ^^

        if (this.filterWrapper) {
            this.processFilters();
        }

        if (this.filterWrapper == undefined) {
            this.filterWrapper = { userTerritories: this.userTerritories };
            getMaxRank({ filterWrapper: this.filterWrapper })
                .then((maxRank) => {
                    console.log("max Rank -> " + maxRank);
                    this.rankRangeAccountsEnd = maxRank;
                })
                .catch((error) => {
                    console.log(error);
                    console.log("error in get data");
                });
            getUsersProjectDodgeTypes({ userId: this.userId })
                .then((data) => {
                    if (data) {
                        console.log("getUsersProjectDodgeTypes -> ");
                        console.log(data);
                        if(data.length > 0){
                            this.projectPrimaryType = data;
                        }
                        else {
                            this.projectPrimaryType = ['All'];
                            this.projectPrimaryTypePrevious = ['All'];
                        }
                    }
                })
                .catch((error) => {
                    console.log("error in get default picklists types");
                    console.log(error);
                });

            getUsersProjectDodgePhases({ userId: this.userId })
                .then((data) => {
                    if (data) {
                        console.log("getUsersProjectDodgePhases -> ");
                        console.log(data);
                        if(data.length > 0){
                            this.projectDodgePhase = data;
                        }
                        else {
                            this.projectDodgePhase = ['All'];
                            this.projectDodgePhasePrevious = ['All'];
                        }
                    }
                })
                .catch((error) => {
                    console.log("error in get default picklists phases ");
                    console.log(error);
                });

            getUsersProjectMinValuation({ userId: this.userId })
            .then((data) => {
                if (data != undefined) {
                    console.log("getUsersProjectMinValuation -> ");
                    console.log(data);
                    this.valuationRangeProjectsStart  = data;
                    this.valuationRangeProjects = true;
                }
            })
            .catch((error) => {
                console.log("error in get default picklists phases ");
                console.log(error);
            });

            isPECUser({ userId: this.userId })
            .then((data) => {
                if (data != undefined) {
                    this.isPEC = data;
                    console.log('isPEC -> ' + this.isPEC);
                }
            })
            .catch((error) => {
                console.log("error in get default picklists phases ");
                console.log(error);
            });
        }
        this.lineOfBusinessData = await getLineOfBusinesses();
        this.lineOfBusinessOptions = [{ value: "All", label: "All" }].concat(this.getLOBOptions(
            this.country,
            this.lineOfBusinessData
        ));
    }

    getLOBOptions(country, data) {
        const linesOfBuiseness = JSON.parse(data);
        if (country != 'All') {
            const countryData = linesOfBuiseness.find(
                (item) => item.country === country
            );
            this.isPicklistDisabled = !countryData;
            return countryData
                ? countryData.lobs.map((lob) => ({ label: lob, value: lob }))
                : [];
        }
        // If no country selected, return all LOBs
        const allLOBs = [];
        this.isPicklistDisabled = false
        linesOfBuiseness.forEach((item) =>
            item.lobs.forEach((lob) => {
                if (!allLOBs.includes(lob)) {
                    allLOBs.push(lob);
                }
            })
        );
        return allLOBs.map((lob) => ({ label: lob, value: lob }));
    }

    applyFilters() {
        if (this.validateFilters()) {

            console.log("applying filters...");
            var message = this.buildFilterMessage();
            console.log('filters to send : ', JSON.stringify(message));
            const event = new CustomEvent("applyfilters", {
                detail: message
            });
            this.dispatchEvent(event);
            console.log("fired event...");
        }
    }

    validateFilters() {
        if (
            this.rankRangeAccounts &&
            (!this.rankRangeAccountsStart || !this.rankRangeAccountsEnd)
        ) {
            const toastEvent = new ShowToastEvent({
                title: "An error occured. Please try again.",
                message:
                    "Please populate both From and To fields in the Account Filter: Rank X",
                variant: "error"
            });
            this.dispatchEvent(toastEvent);
            return false;
        }
        if (
            this.rankRangeAccounts &&
            this.rankRangeAccountsStart > this.rankRangeAccountsEnd
        ) {
            const toastEvent = new ShowToastEvent({
                title: "An error occured. Please try again.",
                message:
                    "Please populate a valid range for From and To fields in the Account Filter: Rank X",
                variant: "error"
            });
            this.dispatchEvent(toastEvent);
            return false;
        }

        let validateInputs = true;
        let numberElements = this.template.querySelectorAll('lightning-input[data-type="number"]');
        numberElements.forEach((elem) => {
            
            if(elem.classList.contains('slds-has-error')) {
                const toastEvent = new ShowToastEvent({
                    title: "An error occured. Please try again.",
                    message:
                        "Please populate a valid integer.",
                    variant: "error"
                });
                this.dispatchEvent(toastEvent);
                validateInputs = false;
                return;
            }
        });
        return validateInputs;
    }

    handleUserFilter(event) {
        console.log("In handleUserFilter...");
        this.userTerritories = event.detail;
        //Creating a local object since filterWrapper can't be modified
        const filterWrapperObj = { userTerritories: this.userTerritories };
        getMaxRank({ filterWrapper: filterWrapperObj })
            .then((maxRank) => {
                console.log("max Rank -> " + maxRank);
                this.rankRangeAccountsEnd = maxRank;
            })
            .catch((error) => {
                console.log(error);
                console.log("error in get data");
            });
        /* Creates the event with the updated UserID data since 
        filterWrapper can't be updated here bcz its read-only */
        const userFilterUpdateEvent = new CustomEvent("userfilterupdate", { detail: this.userTerritories });
        this.dispatchEvent(userFilterUpdateEvent);
    }

    handlePicklistChange(event) {
        let target = event.currentTarget;
        let obj = target.dataset.obj;
        let scope = target.dataset.scope;

        if (obj == "Appointment") {
            this.apptParentType = event.detail.value;
        }
        if (obj == "Task") {
            this.taskParentType = event.detail.value;
        }
        if (obj == "Account") {
            this.accountRecordType = event.detail.value;
            let previousAll = this.accountRecordTypePrevious.filter(e => e == 'All');
            if(this.accountRecordType.includes('All') && previousAll.includes('All')) {
                this.accountRecordType = this.accountRecordType.filter(e => e !== 'All');
            }
            else if(this.accountRecordType.includes('All')) {
                this.accountRecordType = ['All'];
            } else if(this.accountRecordType == '') {
                this.accountRecordType = ['All'];
            }
            this.accountRecordTypePrevious = this.accountRecordType;
        }
        if (obj == "Lead") {
            this.campaignType = event.detail.value;
        }

        // Project Picklists
        if (obj == "Project" && scope == "status") {
            this.projectStatus = event.detail.value;
        }
        if (obj == "Project" && scope == "primaryType") {
            this.projectPrimaryType = event.detail.value;
            //if(!this.lineOfBusiness) {
                let previousAll = this.projectPrimaryTypePrevious.filter(e => e == 'All');
                if(this.projectPrimaryType.includes('All') && previousAll.includes('All')) {
                    this.projectPrimaryType = this.projectPrimaryType.filter(e => e !== 'All');
                }
                else if(this.projectPrimaryType.includes('All')) {
                    this.projectPrimaryType = ['All'];
                } else if(this.projectPrimaryType == '') {
                    this.projectPrimaryType = ['All'];
                }
                this.projectPrimaryTypePrevious = this.projectPrimaryType;
            //}
        }
        if (obj == "Project" && scope == "stage") {
            this.projectStage = event.detail.value;
        }
        if (obj == "Project" && scope == "origin") {
            this.projectOrigin = event.detail.value;
            let previousAll = this.projectOriginPrevious.filter(e => e == 'All');
            if(this.projectOrigin.includes('All') && previousAll.includes('All')) {
                this.projectOrigin = this.projectOrigin.filter(e => e !== 'All');
            }
            else if(this.projectOrigin.includes('All')) {
                this.projectOrigin = ['All'];
            } else if(this.projectOrigin == '') {
                this.projectOrigin = ['All'];
            }
            this.projectOriginPrevious = this.projectOrigin;
        }
        if (obj == "Project" && scope == "activity") {
            this.projectActivity = event.detail.value;
        }
        if (obj == "Project" && scope == "timing") {
            this.projectTiming = event.detail.value;
        }
        if (obj == "Project" && scope == "dodgePhase") {
            this.projectDodgePhase = event.detail.value;
            let previousAll = this.projectDodgePhasePrevious.filter(e => e == 'All');
            if(this.projectDodgePhase.includes('All') && previousAll.includes('All')) {
                this.projectDodgePhase = this.projectDodgePhase.filter(e => e !== 'All');
            }
            else if(this.projectDodgePhase.includes('All')) {
                this.projectDodgePhase = ['All'];
            } else if(this.projectDodgePhase == '') {
                this.projectDodgePhase = ['All'];
            }
            this.projectDodgePhasePrevious = this.projectDodgePhase;
        }

        if (obj == "Project" && scope == "created") {
            this.projectCreatedDate = event.detail.value;
        }

        // Opportunity Picklists
        if (obj == "Opportunity" && scope == "stage") {
            this.opportunityStage = event.detail.value;
            let previousAll = this.opportunityStagePrevious.filter(e => e == 'All');
            if(this.opportunityStage.includes('All') && previousAll.includes('All')) {
                this.opportunityStage = this.opportunityStage.filter(e => e !== 'All');
            }
            else if(this.opportunityStage.includes('All')) {
                this.opportunityStage = ['All'];
            } else if(this.opportunityStage == '') {
                this.opportunityStage = ['All'];
            }
            this.opportunityStagePrevious = this.opportunityStage;
        }

        if (obj == "Branch" && scope == "lob") {
            this.lineOfBusiness = event.detail.value;

            console.log(this.lineOfBusiness);
            console.log(JSON.stringify(this.lineOfBusinessPrevious));
            
            let previousAll = this.lineOfBusinessPrevious.filter(e => e == 'All');
            if(this.lineOfBusiness.includes('All') && previousAll.includes('All')) {
                this.lineOfBusiness = this.lineOfBusiness.filter(e => e !== 'All');
            }
            else if(this.lineOfBusiness.includes('All')) {
                this.lineOfBusiness = ['All'];
            } else if(this.lineOfBusiness == '') {
                this.lineOfBusiness = ['All'];
            }
            this.lineOfBusinessPrevious = this.lineOfBusiness;
        }
        if (obj == "Branch" && scope == "country") {
            this.country = event.detail.value;
            this.lineOfBusinessOptions = [{ value: "All", label: "All" }].concat(this.getLOBOptions(
                this.country,
                this.lineOfBusinessData
            ));
        }
    }
    handleSectionToggle(event) {     
        if (event.detail.openSections.includes("Branches")) {
            this.loadBranchData = true;
        }
    }

    stopProp(event) {
        event.stopPropagation();
    }

    increaseSizePanel(event) {
        if(event.currentTarget.dataset.id == 'projectId') {
            this.toggledProject = !this.toggledProject;
        }
        if(event.currentTarget.dataset.id == 'branchId') {
            this.toggledBranch = !this.toggledBranch;
        }
        this.increaseSizePanelLogic();
    }

    increaseSizePanelLogic() {
        if(!this.toggledBranch && !this.toggledProject) {
            const sizeEvent = new CustomEvent("sizechange", {
                detail: false
            });
            this.dispatchEvent(sizeEvent);
            
        } else {
            const sizeEvent = new CustomEvent("sizechange", {
                detail: true
            });
            this.dispatchEvent(sizeEvent);
        }
    }

    get showDodgeFilters() {
        if(this.projectOrigin.includes('Dodge') || this.projectOrigin.includes('All')) {
            return true;
        }
        else {
            return false;
        }
    }
    get showSearchAllAccounts(){
        if(this.accountSearch && this.accountSearch.length > 0) {
            return true;
        } else {
            this.searchAccounts = false;
            return false;
        }
    }
    get showProjectCreatedRange(){
        if(this.projectCreatedDate == 'Range') {
            return true;
        } else {
            return false;
        }
    }

    get relatedOptions() {
        return [
            { value: "", label: "All" },
            { value: "Account", label: "Account" },
            { value: "Project__c", label: "Project" },
            { value: "Opportunity", label: "Opportunity" },
            { value: "Other", label: "Other" }
        ];
    }
    get accountRecordTypeOptions() {
        return [
            { value: "All", label: "All" },
            { value: "ERP_Link", label: "Corp Link" },
            { value: "Credit", label: "Credit" },
            { value: "Global", label: "Global" },
            { value: "Office", label: "Office" },
            { value: "Prospect", label: "Prospect" }
        ];
    }
    get leadCampaignTypeOptions() {
        return [
            { value: "", label: "No Campaign" },
            { value: "Marketing", label: "Marketing" },
            { value: "Sales", label: "Sales" }
        ];
    }
    get projectStatusOptions() {
        return [
            { value: "", label: "All" },
            { value: "Pending", label: "Pending" },
            { value: "Working", label: "Working" },
            { value: "Complete", label: "Complete" }
        ];
    }
    get projectStageOptions() {
        return [
            { value: "", label: "All" },
            { value: "1-Site Survey", label: "1-Site Survey" },
            { value: "2-Excavation & Grading", label: "2-Excavation & Grading" },
            { value: "3-Utility Installation", label: "3-Utility Installation" },
            { value: "4-Foundation", label: "4-Foundation" },
            { value: "5-Skeleton & Roofing", label: "5-Skeleton & Roofing" },
            { value: "6-Power, Plumbing & HVAC", label: "6-Power, Plumbing & HVAC" },
            { value: "7-Exterior Buildout", label: "7-Exterior Buildout" },
            { value: "8-Interior Buildout", label: "8-Interior Buildout" },
            {
                value: "9-Landscaping & Erosion Control",
                label: "9-Landscaping & Erosion Control"
            },
            { value: "10-Curb & Gutter Paving", label: "10-Curb & Gutter Paving" },
            { value: "11-Signage", label: "11-Signage" },
            { value: "12-Move-In & Maintenance", label: "12-Move-In & Maintenance" },
            { value: "13-Office Call", label: "13-Office Call" },
            { value: "14-Completed", label: "14-Completed" }
        ];
    }
    get projectOriginOptions() {

        if(this.isPEC) {
            return [
                { value: "All", label: "All" },
                { value: "User Created", label: "User Created" },
                { value: "Dodge", label: "Dodge" },
                { value: "PEC", label: "PEC" }
            ];
        } else {
            return [
                { value: "All", label: "All" },
                { value: "User Created", label: "User Created" },
                { value: "Dodge", label: "Dodge" }
            ];
        }
    }
    get projectActivityOptions() {
        return [
            { value: "", label: "All" },
            { value: "P1 - Market Analysis", label: "P1 - Market Analysis" },
            { value: "P1 - Site Study", label: "P1 - Site Study" },
            { value: "P1 - Project Scope", label: "P1 - Project Scope" },
            { value: "P1 - Economic Evaluation", label: "P1 - Economic Evaluation" },
            { value: "P1 - Energy Analysis", label: "P1 - Energy Analysis" },
            { value: "P1 - Equipment Studies", label: "P1 - Equipment Studies" },
            { value: "P1 - Preliminary Design", label: "P1 - Preliminary Design" },
            { value: "P1 - Site Selection", label: "P1 - Site Selection" },
            { value: "P1 - Detailed Design", label: "P1 - Detailed Design" },
            {
                value: "P1 - Technology Comparison",
                label: "P1 - Technology Comparison"
            },
            { value: "P1 - Fuel Strategy", label: "P1 - Fuel Strategy" },
            { value: "P1 - Capital Estimating", label: "P1 - Capital Estimating" },
            {
                value: "P1 - Site Characterization",
                label: "P1 - Site Characterization"
            },
            { value: "P1 - Dismantling", label: "P1 - Dismantling" },
            { value: "P1 - Demolition", label: "P1 - Demolition" },
            {
                value: "P1 - Project Justification",
                label: "P1 - Project Justification"
            },
            { value: "P1 - AFE Submittal", label: "P1 - AFE Submittal" },
            { value: "P2 - Permitting", label: "P2 - Permitting" },
            {
                value: "P2 - Owner Review of Issue",
                label: "P2 - Owner Review of Issue"
            },
            { value: "E1- Capital Approval", label: "E1- Capital Approval" },
            { value: "E2 - Purchasing", label: "E2 - Purchasing" },
            {
                value: "E2 - Preliminary Engineering",
                label: "E2 - Preliminary Engineering"
            },
            {
                value: "E2 - Definitive Estimating",
                label: "E2 - Definitive Estimating"
            },
            { value: "E2 - Cost Analysis", label: "E2 - Cost Analysis" },
            {
                value: "E2 - Planning and Scheduling",
                label: "E2 - Planning and Scheduling"
            },
            { value: "E2 - Site Preparation", label: "E2 - Site Preparation" },
            { value: "E2 - Safety Studies", label: "E2 - Safety Studies" },
            { value: "E2 - Unit Stimulation", label: "E2 - Unit Stimulation" },
            { value: "E2 - Unit Strategies", label: "E2 - Unit Strategies" },
            { value: "E2 - Unit Control", label: "E2 - Unit Control" },
            {
                value: "E2 - Detailed Engineering",
                label: "E2 - Detailed Engineering"
            },
            { value: "E2 - Cost Control", label: "E2 - Cost Control" },
            { value: "E2 - Expediting", label: "E2 - Expediting" },
            { value: "C1 - Structural Erection", label: "C1 - Structural Erection" },
            {
                value: "C1 - Construction - Union",
                label: "C1 - Construction - Union"
            },
            {
                value: "C1 - Construction - Merit Shop",
                label: "C1 - Construction - Merit Shop"
            },
            { value: "C1 - Inspection", label: "C1 - Inspection" },
            {
                value: "C1 - Venture Capitalization Report",
                label: "C1 - Venture Capitalization Report"
            },
            {
                value: "C1 - Mechanical Completion",
                label: "C1 - Mechanical Completion"
            },
            { value: "C1 - Final Commissioning", label: "C1 - Final Commissioning" },
            { value: "C1 - Completion/Start-Up", label: "C1 - Completion/Start-Up" },
            {
                value: "C2 - Maintenance Programs",
                label: "C2 - Maintenance Programs"
            },
            {
                value: "C2 - Contract Maintenance",
                label: "C2 - Contract Maintenance"
            },
            {
                value: "C2 - Long-Term Maintenance",
                label: "C2 - Long-Term Maintenance"
            },
            {
                value: "C2 - Scheduled Maintenance",
                label: "C2 - Scheduled Maintenance"
            }
        ];
    }
    get projectTimingOptions() {
        return [
            { value: "", label: "All" },
            { value: "Capital - P1 - Planning", label: "Capital - P1 - Planning" },
            { value: "Capital - P2 - Planning", label: "Capital - P2 - Planning" },
            {
                value: "Capital - E1 - Engineering",
                label: "Capital - E1 - Engineering"
            },
            {
                value: "Capital - E2 - Engineering",
                label: "Capital - E2 - Engineering"
            },
            {
                value: "Capital - C1 - Maintenance",
                label: "Capital - C1 - Maintenance"
            },
            {
                value: "Maintenance - C2 - Maintenance",
                label: "Maintenance - C2 - Maintenance"
            }
        ];
    }

    get projectPrimaryTypeOptions() {
        return [
            { value: "All", label: "All" },
            { value: "Air Pollution Control", label: "Air Pollution Control" },
            { value: "Aircraft Sales/Service", label: "Aircraft Sales/Service" },
            { value: "Airline Terminal", label: "Airline Terminal" },
            { value: "Airport Lighting", label: "Airport Lighting" },
            {
                value: "Apartments/Condominiums 1-3 Stories",
                label: "Apartments/Condominiums 1-3 Stories"
            },
            {
                value: "Apartments/Condominiums 4+ Stories",
                label: "Apartments/Condominiums 4+ Stories"
            },
            { value: "Athletic Facility", label: "Athletic Facility" },
            { value: "Athletic Lighting", label: "Athletic Lighting" },
            { value: "Bank", label: "Bank" },
            { value: "Beach/Marina Facility", label: "Beach/Marina Facility" },
            { value: "Bowling Alley", label: "Bowling Alley" },
            { value: "Bridge", label: "Bridge" },
            {
                value: "Capitol/ Courthouse/City Hall",
                label: "Capitol/ Courthouse/City Hall"
            },
            { value: "Casino", label: "Casino" },
            { value: "Clinic/Medical Office", label: "Clinic/Medical Office" },
            { value: "Cogeneration Plant", label: "Cogeneration Plant" },
            { value: "College/University", label: "College/University" },
            { value: "Communication Building", label: "Communication Building" },
            { value: "Communication Lines", label: "Communication Lines" },
            {
                value: "Convention & Exhibit Center",
                label: "Convention & Exhibit Center"
            },
            { value: "Custom Homes", label: "Custom Homes" },
            { value: "Data Center", label: "Data Center" },
            { value: "Dock/Pier", label: "Dock/Pier" },
            { value: "Dormitory", label: "Dormitory" },
            { value: "Dredging", label: "Dredging" },
            {
                value: "Dry Waste Treatment Plant",
                label: "Dry Waste Treatment Plant"
            },
            { value: "Elderly/Assisted Living", label: "Elderly/Assisted Living" },
            { value: "Electric Substation", label: "Electric Substation" },
            { value: "Fire/Police Station", label: "Fire/Police Station" },
            { value: "Flood Control Dams", label: "Flood Control Dams" },
            { value: "Food/Beverage Service", label: "Food/Beverage Service" },
            { value: "Freight Terminal", label: "Freight Terminal" },
            { value: "Fuel/Chemical Line", label: "Fuel/Chemical Line" },
            { value: "Gas/Chemical Plant", label: "Gas/Chemical Plant" },
            {
                value: "Guidance Detection Tracking System",
                label: "Guidance Detection Tracking System"
            },
            { value: "Hazardous Waste Disposal", label: "Hazardous Waste Disposal" },
            { value: "Heating/Cooling Plant", label: "Heating/Cooling Plant" },
            { value: "Highway Signs/Guardrails", label: "Highway Signs/Guardrails" },
            { value: "Hospital", label: "Hospital" },
            { value: "Hotel/Motel", label: "Hotel/Motel" },
            { value: "Hydroelectric Dams", label: "Hydroelectric Dams" },
            { value: "Hydroelectric Plant", label: "Hydroelectric Plant" },
            { value: "Indoor Arena", label: "Indoor Arena" },
            {
                value: "Industrial Waste Disposal",
                label: "Industrial Waste Disposal"
            },
            { value: "Kindergarten", label: "Kindergarten" },
            { value: "Landscaping", label: "Landscaping" },
            { value: "Library", label: "Library" },
            { value: "Manufacturing Building", label: "Manufacturing Building" },
            {
                value: "Middle/Senior High School",
                label: "Middle/Senior High School"
            },
            { value: "Military Facility", label: "Military Facility" },
            {
                value: "Miscellaneous Education Building",
                label: "Miscellaneous Education Building"
            },
            {
                value: "Miscellaneous Recreational",
                label: "Miscellaneous Recreational"
            },
            { value: "Mobile Home Park", label: "Mobile Home Park" },
            { value: "Museum", label: "Museum" },
            { value: "Nuclear Power Plant", label: "Nuclear Power Plant" },
            {
                value: "Nursing/Convalescent Center",
                label: "Nursing/Convalescent Center"
            },
            { value: "Office", label: "Office" },
            { value: "Park/Playground", label: "Park/Playground" },
            { value: "Parking Garage", label: "Parking Garage" },
            { value: "Passenger Terminal", label: "Passenger Terminal" },
            { value: "Passenger Terminal (Other)", label: "Passenger Terminal (Other)" },
            { value: "Paving", label: "Paving" },
            { value: "Pedestrian Tunnel", label: "Pedestrian Tunnel" },
            { value: "Post Office", label: "Post Office" },
            { value: "Power Lines", label: "Power Lines" },
            { value: "Power Plant", label: "Power Plant" },
            { value: "Pre-School", label: "Pre-School" },
            { value: "Primary School", label: "Primary School" },
            { value: "Prison/Jail", label: "Prison/Jail" },
            { value: "Railroad", label: "Railroad" },
            { value: "Refinery", label: "Refinery" },
            { value: "Regional Shopping Mall", label: "Regional Shopping Mall" },
            { value: "Retail", label: "Retail" },
            { value: "Retail (Other)", label: "Retail (Other)" },
            { value: "Roadway Lighting", label: "Roadway Lighting" },
            { value: "Runway/Taxiway", label: "Runway/Taxiway" },
            { value: "Sale/Spec Homes", label: "Sale/Spec Homes" },
            { value: "Sanitary Sewer", label: "Sanitary Sewer" },
            { value: "Sewage Treatment Plant", label: "Sewage Treatment Plant" },
            {
                value: "Shopping Center/Strip Mall",
                label: "Shopping Center/Strip Mall"
            },
            { value: "Shoreline Maintenance", label: "Shoreline Maintenance" },
            { value: "Sidewalk/Parking Lot", label: "Sidewalk/Parking Lot" },
            { value: "Site Development", label: "Site Development" },
            { value: "Social Club", label: "Social Club" },
            { value: "Space Facility", label: "Space Facility" },
            { value: "Stadium", label: "Stadium" },
            { value: "Storage Tank", label: "Storage Tank" },
            { value: "Storage Tank (Other)", label: "Storage Tank (Other)" },
            { value: "Storm Sewer", label: "Storm Sewer" },
            {
                value: "Supermarket/Convenience Store",
                label: "Supermarket/Convenience Store"
            },
            { value: "Swimming Pool", label: "Swimming Pool" },
            {
                value: "Testing/Research/Development Lab",
                label: "Testing/Research/Development Lab"
            },
            { value: "Theater/Auditorium", label: "Theater/Auditorium" },
            { value: "Tower/Signal System", label: "Tower/Signal System" },
            { value: "Unclassified", label: "Unclassified" },
            { value: "Utility Tunnel", label: "Utility Tunnel" },
            { value: "Vehicle Sales/Service", label: "Vehicle Sales/Service" },
            { value: "Vehicle Tunnel", label: "Vehicle Tunnel" },
            { value: "Vocational School", label: "Vocational School" },
            { value: "Warehouse", label: "Warehouse" },
            { value: "Water Line", label: "Water Line" },
            { value: "Water Supply Dams", label: "Water Supply Dams" },
            { value: "Water Tank", label: "Water Tank" },
            { value: "Water Treatment Plant", label: "Water Treatment Plant" },
            { value: "Water Supply", label: "Water Supply" },
            {
                value: "Animal/Plant/Fish Facility",
                label: "Animal/Plant/Fish Facility"
            },
            {
                value: "Funeral/Interment Facility",
                label: "Funeral/Interment Facility"
            },
            { value: "Worship Facility", label: "Worship Facility" },
            { value: "Warehouse (Refrigerated)", label: "Warehouse (Refrigerated)"},
            { value: "Pharmaceutical & Biotech", label: "Pharmaceutical & Biotech" },
            { value: "Pulp, Paper & Wood", label: "Pulp, Paper & Wood" },
            { value: "Power", label: "Power" },
            { value: "Food & Beverage", label: "Food & Beverage" },
            { value: "Industrial Manufacturing", label: "Industrial Manufacturing" },
            { value: "Terminals", label: "Terminals" },
            { value: "Production (Oil & Gas)", label: "Production (Oil & Gas)" },
            { value: "Metals & Minerals", label: "Metals & Minerals" },
            {
                value: "Chemical Processing (CPI)",
                label: "Chemical Processing (CPI)"
            },
            { value: "Alternative Fuel", label: "Alternative Fuel" },
            { value: "Oil & Gas Pipelines", label: "Oil & Gas Pipelines" },
            { value: "Petroleum Refining (HPI)", label: "Petroleum Refining (HPI)" }
        ];
    }

    get projectDodgePhaseOptions() {
        return [
            { value: "All", label: "All" },
            { value: "Request for Proposals", label: "Request for Proposals" },
            {
                value: "Request for Qualifications",
                label: "Request for Qualifications"
            },
            { value: "Pre-design", label: "Pre-design" },
            { value: "Planning Schematics", label: "Planning Schematics" },
            { value: "Design Development", label: "Design Development" },
            { value: "Construction Documents", label: "Construction Documents" },
            { value: "Pre-qualification", label: "Pre-qualification" },
            { value: "Bidding", label: "Bidding" },
            { value: "Gc Bidding", label: "Gc Bidding" },
            { value: "Gc Bidding-invitation", label: "Gc Bidding-invitation" },
            { value: "Sub Bidding", label: "Sub Bidding" },
            { value: "Negotiating", label: "Negotiating" },
            { value: "Bid Results", label: "Bid Results" },
            { value: "Start", label: "Start" },
            { value: "Subcontract Award", label: "Subcontract Award" },
            { value: "Permit", label: "Permit" },
            { value: "Construction", label: "Construction" },
            { value: "Notice of Completion", label: "Notice of Completion" },
            { value: "Leasing", label: "Leasing" },
            { value: "Service Bidding", label: "Service Bidding" },
            { value: "Retrofit", label: "Retrofit" },
            { value: "Delayed", label: "Delayed" },
            { value: "Abandoned", label: "Abandoned" }
        ];
    }

    get projectCreatedDateOptions() {
        return [
            { value: "All Time", label: "All Time" },
            { value: "Today", label: "Today" },
            { value: "Last 7 Days", label: "Last 7 Days" },
            { value: "Range", label: "Range"}
        ];
    }

    get opportunityStageOptions() {
        return [
            { value: "All", label: "All" },
            { value: "Qualification", label: "Qualification" },
            { value: "Needs Analysis", label: "Needs Analysis" },
            { value: "ID Decision Makers", label: "ID Decision Makers" },
            { value: "Proposal/Price Quote", label: "Proposal/Price Quote" },
            { value: "Negotiation/Review", label: "Negotiation/Review" }
        ];
    }
    get countryOptions() {
        return [
            { value: "All", label: "All" },
            { value: "CA", label: "Canada" },
            { value: "US", label: "United States" }
        ];
    }
    //SF-7819
    get userWhereClause(){
        return 'RepID__c!=null AND IsActive=true';
    }

    toggleCheckbox(event) {
        let target = event.currentTarget;

        console.log("in toggleCheckbox");
        let obj = target.dataset.obj;
        let scope = target.dataset.scope;

        console.log("obj -> ", obj);
        console.log("scope -> ", scope);

        // Generic Checkbox
        if(obj == 'All' && scope == 'show') {
            this.showAll = !this.showAll;
            this.showAppointments = this.showTasks = this.showAccounts = this.showLeads = this.showJobSites =
                this.showProjects = this.showOpportunities = this.showBranches = this.showAll;
        }
        // Appointment Checkboxes
        if (obj == "Appointment" && scope == "show") {
            this.showAppointments = !this.showAppointments;
        }
        if (obj == "Appointment" && scope == "open") {
            this.openAppointments = !this.openAppointments;
        }
        if (obj == "Appointment" && scope == "today") {
            this.todaysAppointments = !this.todaysAppointments;
        }
        if (obj == "Appointment" && scope == "thisWeek") {
            this.thisWeekAppointments = !this.thisWeekAppointments;
        }
        if (obj == "Appointment" && scope == "nextWeek") {
            this.nextWeekAppointments = !this.nextWeekAppointments;
        }
        if (obj == "Appointment" && scope == "next7Days") {
            this.next7DaysAppointments = !this.next7DaysAppointments;
        }
        if (obj == "Appointment" && scope == "nextXDays") {
            this.nextXDaysAppointments = !this.nextXDaysAppointments;
        }
        if (obj == "Appointment" && scope == "dateRange") {
            this.dateRangeAppointments = !this.dateRangeAppointments;
            this.increaseSizePanelLogic('appointments', this.dateRangeAppointments);
        }

        // Task Checkboxes
        if (obj == "Task" && scope == "show") {
            this.showTasks = !this.showTasks;
        }
        if (obj == "Task" && scope == "open") {
            this.openTasks = !this.openTasks;
        }
        if (obj == "Task" && scope == "today") {
            this.todaysTasks = !this.todaysTasks;
        }
        if (obj == "Task" && scope == "thisWeek") {
            this.thisWeekTasks = !this.thisWeekTasks;
        }
        if (obj == "Task" && scope == "nextWeek") {
            this.nextWeekTasks = !this.nextWeekTasks;
        }
        if (obj == "Task" && scope == "next7Days") {
            this.next7DaysTasks = !this.next7DaysTasks;
        }
        if (obj == "Task" && scope == "nextXDays") {
            this.nextXDaysTasks = !this.nextXDaysTasks;
        }
        if (obj == "Task" && scope == "dateRange") {
            this.dateRangeTasks = !this.dateRangeTasks;
            this.increaseSizePanelLogic('tasks', this.dateRangeTasks);
        }

        // Account Checkboxes
        if (obj == "Account" && scope == "searchAccounts") {
            this.searchAccounts = !this.searchAccounts;
        }
        if (obj == "Account" && scope == "show") {
            this.showAccounts = !this.showAccounts;
        }
        if (obj == "Account" && scope == "top25") {
            this.top25Accounts = !this.top25Accounts;
        }
        if (obj == "Account" && scope == "top50") {
            this.top50Accounts = !this.top50Accounts;
        }
        if (obj == "Account" && scope == "topX") {
            this.topXAccounts = !this.topXAccounts;
        }
        if (obj == "Account" && scope == "watchlist") {
            this.watchlistAccounts = !this.watchlistAccounts;
        }
        if (obj == "Account" && scope == "dormant") {
            this.dormantAccounts = !this.dormantAccounts;
        }
        if (obj == "Account" && scope == "rankRange") {
            this.rankRangeAccounts = !this.rankRangeAccounts;
        }
        // if (obj == "Account" && scope == "showOffices") {
        //     this.showOffices = !this.showOffices;
        // }
        if (obj == "Account" && scope == "assignedAccountsOnly") {
            this.assignedAccountsOnly = !this.assignedAccountsOnly;
        }
        if (obj == "Account" && scope == "includeTracked") {
            this.includeTracked = !this.includeTracked;
        }

        // Lead Checkboxes
        if (obj == "Lead" && scope == "show") {
            this.showLeads = !this.showLeads;
        }
        if (obj == "Lead" && scope == "open") {
            this.openLeads = !this.openLeads;
        }
        if (obj == "Lead" && scope == "leadShare") {
            this.leadShareLeads = !this.leadShareLeads;
        }
        if (obj == "Lead" && scope == "campaignLeads") {
            this.campaignLeads = !this.campaignLeads;
        }

        // Job Site Checkboxes
        if (obj == "Job Site" && scope == "show") {
            this.showJobSites = !this.showJobSites;
        }
        if (obj == "Job Site" && scope == "active") {
            this.activeJobSites = !this.activeJobSites;
        }
        if (obj == "Job Site" && scope == "today") {
            this.todayJobSites = !this.todayJobSites;
        }
        if (obj == "Job Site" && scope == "yesterday") {
            this.yesterdayJobSites = !this.yesterdayJobSites;
        }
        if (obj == "Job Site" && scope == "nextXDays") {
            this.nextXDaysJobSites = !this.nextXDaysJobSites;
        }

        // Project Checkboxes
        if (obj == "Project" && scope == "show") {
            this.showProjects = !this.showProjects;
        }
        if (obj == "Project" && scope == "city") {
            this.cityProject = !this.cityProject;
        }
        if (obj == "Project" && scope == "plantId") {
            this.plantIdProject = !this.plantIdProject;
        }
        if (obj == "Project" && scope == "plantName") {
            this.plantNameProject = !this.plantNameProject;
        }
        if (obj == "Project" && scope == "valuation") {
            this.valuationProject = !this.valuationProject;
        }
        if (obj == "Project" && scope == "valuationRange") {
            this.valuationRangeProjects = !this.valuationRangeProjects;
        }
        if (obj == "Project" && scope == "squareFootageRange") {
            this.squareFootageRangeProjects = !this.squareFootageRangeProjects;
        }
        if (obj == "Project" && scope == "next30DaysBidDate") {
            this.next30DaysBidDateProject = !this.next30DaysBidDateProject;
        }
        if (obj == "Project" && scope == "lastXDaysBidDate") {
            this.lastXDaysBidDateProject = !this.lastXDaysBidDateProject;
        }
        if (obj == "Project" && scope == "nextXDaysBidDate") {
            this.nextXDaysBidDateProject = !this.nextXDaysBidDateProject;
        }
        if (obj == "Project" && scope == "dateRangeBidDate") {
            this.dateRangeBidDateProjects = !this.dateRangeBidDateProjects;
        }
        if (obj == "Project" && scope == "next30DaysCompletionDate") {
            this.next30DaysCompletionDateProject =
                !this.next30DaysCompletionDateProject;
        }
        if (obj == "Project" && scope == "lastXDaysCompletionDate") {
            this.lastXDaysCompletionDateProject =
                !this.lastXDaysCompletionDateProject;
        }
        if (obj == "Project" && scope == "nextXDaysCompletionDate") {
            this.nextXDaysCompletionDateProject =
                !this.nextXDaysCompletionDateProject;
        }
        if (obj == "Project" && scope == "dateRangeCompletionDate") {
            this.dateRangeCompletionDateProjects =
                !this.dateRangeCompletionDateProjects;
        }
        if (obj == "Project" && scope == "next30DaysKickoffDate") {
            this.next30DaysKickoffDateProject = !this.next30DaysKickoffDateProject;
        }
        if (obj == "Project" && scope == "lastXDaysKickoffDate") {
            this.lastXDaysKickoffDateProject = !this.lastXDaysKickoffDateProject;
        }
        if (obj == "Project" && scope == "nextXDaysKickoffDate") {
            this.nextXDaysKickoffDateProject = !this.nextXDaysKickoffDateProject;
        }
        if (obj == "Project" && scope == "dateRangeKickoffDate") {
            this.dateRangeKickoffDateProjects = !this.dateRangeKickoffDateProjects;
        }
        if (obj == "Project" && scope == "next30DaysAFEDate") {
            this.next30DaysAFEDateProject = !this.next30DaysAFEDateProject;
        }
        if (obj == "Project" && scope == "lastXDaysAFEDate") {
            this.lastXDaysAFEDateProject = !this.lastXDaysAFEDateProject;
        }
        if (obj == "Project" && scope == "nextXDaysAFEDate") {
            this.nextXDaysAFEDateProject = !this.nextXDaysAFEDateProject;
        }
        if (obj == "Project" && scope == "dateRangeAFEDate") {
            this.dateRangeAFEDateProjects = !this.dateRangeAFEDateProjects;
        }
        if (obj == "Project" && scope == "next30DaysRQFDate") {
            this.next30DaysRQFDateProject = !this.next30DaysRQFDateProject;
        }
        if (obj == "Project" && scope == "lastXDaysRQFDate") {
            this.lastXDaysRQFDateProject = !this.lastXDaysRQFDateProject;
        }
        if (obj == "Project" && scope == "nextXDaysRQFDate") {
            this.nextXDaysRQFDateProject = !this.nextXDaysRQFDateProject;
        }
        if (obj == "Project" && scope == "dateRangeRQFDate") {
            this.dateRangeRQFDateProjects = !this.dateRangeRQFDateProjects;
        }

        // Opportunity Checkboxes
        if (obj == "Opportunity" && scope == "show") {
            this.showOpportunities = !this.showOpportunities;
        }
        if (obj == "Opportunity" && scope == "open") {
            this.openOpportunity = !this.openOpportunity;
        }
        if (obj == "Opportunity" && scope == "closeDateNext30Days") {
            this.closeDateNext30DaysOpportunity =
                !this.closeDateNext30DaysOpportunity;
        }
        if (obj == "Opportunity" && scope == "closeDateLastXDays") {
            this.closeDateLastXDaysOpportunity = !this.closeDateLastXDaysOpportunity;
        }
        if (obj == "Opportunity" && scope == "closeDateNextXDays") {
            this.closeDateNextXDaysOpportunity = !this.closeDateNextXDaysOpportunity;
        }
        if (obj == "Opportunity" && scope == "estDateNext30Days") {
            this.estDateNext30DaysOpportunity = !this.estDateNext30DaysOpportunity;
        }
        if (obj == "Opportunity" && scope == "estDateLastXDays") {
            this.estDateLastXDaysOpportunity = !this.estDateLastXDaysOpportunity;
        }
        if (obj == "Opportunity" && scope == "estDateNextXDays") {
            this.estDateNextXDaysOpportunity = !this.estDateNextXDaysOpportunity;
        }

        // Branch Checkboxes
        if (obj == "Branch" && scope == "show") {
            this.showBranches = !this.showBranches;
        }

        if(this.showAppointments && this.showTasks && this.showAccounts && this.showLeads && this.showJobSites &&
            this.showProjects && this.showOpportunities && this.showBranches) {
                this.showAll = true;
        } else {
            this.showAll = false;
        }

    }

    handleValueChange(event) {
        let target = event.currentTarget;
        let obj = target.dataset.obj;
        let scope = target.dataset.scope;

        if (obj == "All" && scope == "search") {
            this.globalSearch = event.target.value;
            if (event.target.value === "") {
                this.appointmentSearch = "";
                this.taskSearch = "";
                this.accountSearch = "";
                this.jobSiteSearch = "";
                this.projectSearch = "";
                this.opportunitySearch = "";
                this.branchSearch = "";
            }
        }

        // Appointment Values
        if (obj == "Appointment" && scope == "search") {
            this.appointmentSearch = event.target.value;
        }
        if (obj == "Appointment" && scope == "nextXDays") {
            this.nextXDaysAppointmentsValue = Math.trunc(Number(event.target.value));
        }
        if (obj == "Appointment" && scope == "dateRangeStart") {
            this.dateRangeAppointmentsStart = event.target.value;
        }
        if (obj == "Appointment" && scope == "dateRangeEnd") {
            this.dateRangeAppointmentsEnd = event.target.value;
        }

        // Task Values
        if (obj == "Task" && scope == "search") {
            this.taskSearch = event.target.value;
        }
        if (obj == "Task" && scope == "nextXDays") {
            this.nextXDaysTasksValue = Math.trunc(Number(event.target.value));
        }
        if (obj == "Task" && scope == "dateRangeStart") {
            this.dateRangeTasksStart = event.target.value;
        }
        if (obj == "Task" && scope == "dateRangeEnd") {
            this.dateRangeTasksEnd = event.target.value;
        }

        // Account Values
        if (obj == "Account" && scope == "search") {
            this.accountSearch = event.target.value;
        }
        if (obj == "Account" && scope == "topX") {
            this.topXAccountsValue = Math.trunc(Number(event.target.value));
        }
        if (obj == "Account" && scope == "rankStart") {
            this.rankRangeAccountsStart = Math.trunc(Number(event.target.value));
        }
        if (obj == "Account" && scope == "rankEnd") {
            this.rankRangeAccountsEnd = Math.trunc(Number(event.target.value));
        }

        // Job Site Values
        if (obj == "Job Site" && scope == "search") {
            this.jobSiteSearch = event.target.value;
        }
        if (obj == "Job Site" && scope == "nextXDays") {
            this.nextXDaysJobSitesValue = Math.trunc(Number(event.target.value));
        }

        // Project Values
        if (obj == "Project" && scope == "search") {
            this.projectSearch = event.target.value;
        }
        if (obj == "Project" && scope == "cityValue") {
            this.cityProjectValue = event.target.value;
        }
        if (obj == "Project" && scope == "plantIdValue") {
            this.plantIdProjectValue = event.target.value;
        }
        if (obj == "Project" && scope == "plantNameValue") {
            this.plantNameProjectValue = event.target.value;
        }
        if (obj == "Project" && scope == "valuationValue") {
            this.valuationProjectValue = event.target.value;
        }
        if (obj == "Project" && scope == "valuationRangeStart") {
            this.valuationRangeProjectsStart = event.target.value;
        }
        if (obj == "Project" && scope == "valuationRangeEnd") {
            this.valuationRangeProjectsEnd = event.target.value;
        }
        if (obj == "Project" && scope == "squareFootageRangeStart") {
            this.squareFootageRangeProjectsStart = Math.trunc(Number(event.target.value));
        }
        if (obj == "Project" && scope == "squareFootageRangeEnd") {
            this.squareFootageRangeProjectsEnd = Math.trunc(Number(event.target.value));
        }
        if (obj == "Project" && scope == "lastXDaysBidDateValue") {
            this.lastXDaysBidDateProjectValue = Math.trunc(Number(event.target.value));
        }
        if (obj == "Project" && scope == "nextXDaysBidDateValue") {
            this.nextXDaysBidDateProjectValue = Math.trunc(Number(event.target.value));
        }
        if (obj == "Project" && scope == "dateRangeBidDateStart") {
            this.dateRangeBidDateProjectsStart = event.target.value;
        }
        if (obj == "Project" && scope == "dateRangeBidDateEnd") {
            this.dateRangeBidDateProjectsEnd = event.target.value;
        }
        if (obj == "Project" && scope == "lastXDaysCompletionDateValue") {
            this.lastXDaysCompletionDateProjectValue = Math.trunc(Number(event.target.value));
        }
        if (obj == "Project" && scope == "nextXDaysCompletionDateValue") {
            this.nextXDaysCompletionDateProjectValue = Math.trunc(Number(event.target.value));
        }
        if (obj == "Project" && scope == "dateRangeCompletionDateStart") {
            this.dateRangeCompletionDateProjectsStart = event.target.value;
        }
        if (obj == "Project" && scope == "dateRangeCompletionDateEnd") {
            this.dateRangeCompletionDateProjectsEnd = event.target.value;
        }
        if (obj == "Project" && scope == "lastXDaysKickoffDateValue") {
            this.lastXDaysKickoffDateProjectValue = Math.trunc(Number(event.target.value));
        }
        if (obj == "Project" && scope == "nextXDaysKickoffDateValue") {
            this.nextXDaysKickoffDateProjectValue = Math.trunc(Number(event.target.value));
        }
        if (obj == "Project" && scope == "dateRangeKickoffDateStart") {
            this.dateRangeKickoffDateProjectsStart = event.target.value;
        }
        if (obj == "Project" && scope == "dateRangeKickoffDateEnd") {
            this.dateRangeKickoffDateProjectsEnd = event.target.value;
        }
        if (obj == "Project" && scope == "lastXDaysAFEDateValue") {
            this.lastXDaysAFEDateProjectValue = Math.trunc(Number(event.target.value));
        }
        if (obj == "Project" && scope == "nextXDaysAFEDateValue") {
            this.nextXDaysAFEDateProjectValue = Math.trunc(Number(event.target.value));
        }
        if (obj == "Project" && scope == "dateRangeAFEDateStart") {
            this.dateRangeAFEDateProjectsStart = event.target.value;
        }
        if (obj == "Project" && scope == "dateRangeAFEDateEnd") {
            this.dateRangeAFEDateProjectsEnd = event.target.value;
        }
        if (obj == "Project" && scope == "lastXDaysRQFDateValue") {
            this.lastXDaysRQFDateProjectValue = Math.trunc(Number(event.target.value));
        }
        if (obj == "Project" && scope == "nextXDaysRQFDateValue") {
            this.nextXDaysRQFDateProjectValue = Math.trunc(Number(event.target.value));
        }
        if (obj == "Project" && scope == "dateRangeRQFDateStart") {
            this.dateRangeRQFDateProjectsStart = event.target.value;
        }
        if (obj == "Project" && scope == "dateRangeRQFDateEnd") {
            this.dateRangeRQFDateProjectsEnd = event.target.value;
        }
        if (obj == "Project" && scope == "dateRangeCreatedDateProjectsStart") {
            this.dateRangeCreatedDateProjectsStart = event.target.value;
        }
        if (obj == "Project" && scope == "dateRangeCreatedDateProjectsEnd") {
            this.dateRangeCreatedDateProjectsEnd = event.target.value;
        }

        // Opportunity Values
        if (obj == "Opportunity" && scope == "search") {
            this.opportunitySearch = event.target.value;
        }
        if (obj == "Opportunity" && scope == "closeDateLastXDays") {
            this.closeDateLastXDaysOpportunityValue = Math.trunc(Number(event.target.value));
        }
        if (obj == "Opportunity" && scope == "closeDateNextXDays") {
            this.closeDateNextXDaysOpportunityValue = Math.trunc(Number(event.target.value));
        }
        if (obj == "Opportunity" && scope == "estDateLastXDays") {
            this.estDateLastXDaysOpportunityValue = Math.trunc(Number(event.target.value));
        }
        if (obj == "Opportunity" && scope == "estDateNextXDays") {
            this.estDateNextXDaysOpportunityValue = Math.trunc(Number(event.target.value));
        }

        // Branch Values
        if (obj == "Branch" && scope == "search") {
            this.branchSearch = event.target.value;
        }
    }

    buildFilterMessage() {
        var message = {
            // general filters
            userTerritories: this.userTerritories,
            globalSearch: this.globalSearch,
            isPEC: this.isPEC,

            // show filters
            showAll: this.showAll,
            showAppointments: this.showAppointments,
            showTasks: this.showTasks,
            showAccounts: this.showAccounts,
            showLeads: this.showLeads,
            showJobSites: this.showJobSites,
            showProjects: this.showProjects,
            showOpportunities: this.showOpportunities,
            showBranches: this.showBranches,

            // appt filters
            appointmentSearch: this.appointmentSearch,
            apptParentType: this.apptParentType,
            openAppointments: this.openAppointments,
            todaysAppointments: this.todaysAppointments,
            next7DaysAppointments: this.next7DaysAppointments,
            thisWeekAppointments: this.thisWeekAppointments,
            nextWeekAppointments: this.nextWeekAppointments,
            nextXDaysAppointments: this.nextXDaysAppointments,
            nextXDaysAppointmentsValue: this.nextXDaysAppointmentsValue,
            dateRangeAppointments: this.dateRangeAppointments,
            dateRangeAppointmentsStart: this.dateRangeAppointmentsStart,
            dateRangeAppointmentsEnd: this.dateRangeAppointmentsEnd,

            // task filters
            taskSearch: this.taskSearch,
            taskParentType: this.taskParentType,
            todaysTasks: this.todaysTasks,
            openTasks: this.openTasks,
            next7DaysTasks: this.next7DaysTasks,
            thisWeekTasks: this.thisWeekTasks,
            nextWeekTasks: this.nextWeekTasks,
            nextXDaysTasks: this.nextXDaysTasks,
            nextXDaysTasksValue: this.nextXDaysTasksValue,
            dateRangeTasks: this.dateRangeTasks,
            dateRangeTasksStart: this.dateRangeTasksStart,
            dateRangeTasksEnd: this.dateRangeTasksEnd,

            // account filters
            searchAccounts: this.searchAccounts,
            accountSearch: this.accountSearch,
            top25Accounts: this.top25Accounts,
            top50Accounts: this.top50Accounts,
            topXAccounts: this.topXAccounts,
            topXAccountsValue: this.topXAccountsValue,
            watchlistAccounts: this.watchlistAccounts,
            dormantAccounts: this.dormantAccounts,
            rankRangeAccounts: this.rankRangeAccounts,
            rankRangeAccountsStart: this.rankRangeAccountsStart,
            rankRangeAccountsEnd: this.rankRangeAccountsEnd,
            accountRecordType: this.accountRecordType,
            showOffices: this.showOffices,
            assignedAccountsOnly: this.assignedAccountsOnly,
            includeTracked: this.includeTracked,

            // lead filters
            openLeads: this.openLeads,
            leadShareLeads: this.leadShareLeads,
            campaignLeads: this.campaignLeads,
            campaignType: this.campaignType,

            // job site filters
            jobSiteSearch: this.jobSiteSearch,
            activeJobSites: this.activeJobSites,
            todayJobSites: this.todayJobSites,
            yesterdayJobSites: this.yesterdayJobSites,
            nextXDaysJobSites: this.nextXDaysJobSites,
            nextXDaysJobSitesValue: this.nextXDaysJobSitesValue,

            // project filters
            projectSearch: this.projectSearch,
            cityProject: this.cityProject,
            cityProjectValue: this.cityProjectValue,
            plantIdProject: this.plantIdProject,
            plantIdProjectValue: this.plantIdProjectValue,
            plantNameProject: this.plantNameProject,
            plantNameProjectValue: this.plantNameProjectValue,
            valuationProject: this.valuationProject,
            valuationProjectValue: this.valuationProjectValue,
            valuationRangeProjects: this.valuationRangeProjects,
            valuationRangeProjectsStart: this.valuationRangeProjectsStart,
            valuationRangeProjectsEnd: this.valuationRangeProjectsEnd,
            squareFootageRangeProjects: this.squareFootageRangeProjects,
            squareFootageRangeProjectsStart: this.squareFootageRangeProjectsStart,
            squareFootageRangeProjectsEnd: this.squareFootageRangeProjectsEnd,
            projectStatus: this.projectStatus,
            projectPrimaryType: this.projectPrimaryType,
            projectStage: this.projectStage,
            projectOrigin: this.projectOrigin,
            projectActivity: this.projectActivity,
            projectTiming: this.projectTiming,
            projectDodgePhase: this.projectDodgePhase,
            projectCreatedDate: this.projectCreatedDate,
            dateRangeCreatedDateProjectsStart: this.dateRangeCreatedDateProjectsStart,
            dateRangeCreatedDateProjectsEnd: this.dateRangeCreatedDateProjectsEnd,

            // Project Bid Filters
            next30DaysBidDateProject: this.next30DaysBidDateProject,
            lastXDaysBidDateProject: this.lastXDaysBidDateProject,
            lastXDaysBidDateProjectValue: this.lastXDaysBidDateProjectValue,
            nextXDaysBidDateProject: this.nextXDaysBidDateProject,
            nextXDaysBidDateProjectValue: this.nextXDaysBidDateProjectValue,
            dateRangeBidDateProjects: this.dateRangeBidDateProjects,
            dateRangeBidDateProjectsStart: this.dateRangeBidDateProjectsStart,
            dateRangeBidDateProjectsEnd: this.dateRangeBidDateProjectsEnd,

            // Project Completion Filters
            next30DaysCompletionDateProject: this.next30DaysCompletionDateProject,
            lastXDaysCompletionDateProject: this.lastXDaysCompletionDateProject,
            lastXDaysCompletionDateProjectValue:
                this.lastXDaysCompletionDateProjectValue,
            nextXDaysCompletionDateProject: this.nextXDaysCompletionDateProject,
            nextXDaysCompletionDateProjectValue:
                this.nextXDaysCompletionDateProjectValue,
            dateRangeCompletionDateProjects: this.dateRangeCompletionDateProjects,
            dateRangeCompletionDateProjectsStart:
                this.dateRangeCompletionDateProjectsStart,
            dateRangeCompletionDateProjectsEnd:
                this.dateRangeCompletionDateProjectsEnd,

            // Project Kickoff Filters
            next30DaysKickoffDateProject: this.next30DaysKickoffDateProject,
            lastXDaysKickoffDateProject: this.lastXDaysKickoffDateProject,
            lastXDaysKickoffDateProjectValue: this.lastXDaysKickoffDateProjectValue,
            nextXDaysKickoffDateProject: this.nextXDaysKickoffDateProject,
            nextXDaysKickoffDateProjectValue: this.nextXDaysKickoffDateProjectValue,
            dateRangeKickoffDateProjects: this.dateRangeKickoffDateProjects,
            dateRangeKickoffDateProjectsStart: this.dateRangeKickoffDateProjectsStart,
            dateRangeKickoffDateProjectsEnd: this.dateRangeKickoffDateProjectsEnd,

            // Project AFE Filters
            next30DaysAFEDateProject: this.next30DaysAFEDateProject,
            lastXDaysAFEDateProject: this.lastXDaysAFEDateProject,
            lastXDaysAFEDateProjectValue: this.lastXDaysAFEDateProjectValue,
            nextXDaysAFEDateProject: this.nextXDaysAFEDateProject,
            nextXDaysAFEDateProjectValue: this.nextXDaysAFEDateProjectValue,
            dateRangeAFEDateProjects: this.dateRangeAFEDateProjects,
            dateRangeAFEDateProjectsStart: this.dateRangeAFEDateProjectsStart,
            dateRangeAFEDateProjectsEnd: this.dateRangeAFEDateProjectsEnd,

            // Project RQF Filters
            next30DaysRQFDateProject: this.next30DaysRQFDateProject,
            lastXDaysRQFDateProject: this.lastXDaysRQFDateProject,
            lastXDaysRQFDateProjectValue: this.lastXDaysRQFDateProjectValue,
            nextXDaysRQFDateProject: this.nextXDaysRQFDateProject,
            nextXDaysRQFDateProjectValue: this.nextXDaysRQFDateProjectValue,
            dateRangeRQFDateProjects: this.dateRangeRQFDateProjects,
            dateRangeRQFDateProjectsStart: this.dateRangeRQFDateProjectsStart,
            dateRangeRQFDateProjectsEnd: this.dateRangeRQFDateProjectsEnd,

            // Opportunity Filters
            opportunitySearch: this.opportunitySearch,
            opportunityStage: this.opportunityStage,
            openOpportunity: this.openOpportunity,
            closeDateNext30DaysOpportunity: this.closeDateNext30DaysOpportunity,
            closeDateLastXDaysOpportunity: this.closeDateLastXDaysOpportunity,
            closeDateLastXDaysOpportunityValue:
                this.closeDateLastXDaysOpportunityValue,
            closeDateNextXDaysOpportunity: this.closeDateNextXDaysOpportunity,
            closeDateNextXDaysOpportunityValue:
                this.closeDateNextXDaysOpportunityValue,
            estDateNext30DaysOpportunity: this.estDateNext30DaysOpportunity,
            estDateLastXDaysOpportunity: this.estDateLastXDaysOpportunity,
            estDateLastXDaysOpportunityValue: this.estDateLastXDaysOpportunityValue,
            estDateNextXDaysOpportunity: this.estDateNextXDaysOpportunity,
            estDateNextXDaysOpportunityValue: this.estDateNextXDaysOpportunityValue,

            // Branch Filters
            branchSearch: this.branchSearch,
            country: this.country,
            lineOfBusiness: this.lineOfBusiness,
            loadBranchData: this.loadBranchData
            //allBranches: this.allBranches
        };
        return message;
    }

    processFilters() {
        console.log("HERE==>", this.filterWrapper);
        this.userTerritories = this.filterWrapper.userTerritories;
        this.globalSearch = this.filterWrapper.globalSearch;
        this.isPEC = this.filterWrapper.isPEC,

        // show filters
        this.showAll = this.filterWrapper.showAll;
        this.showAppointments = this.filterWrapper.showAppointments;
        this.showTasks = this.filterWrapper.showTasks;
        this.showAccounts = this.filterWrapper.showAccounts;
        this.showLeads = this.filterWrapper.showLeads;
        this.showJobSites = this.filterWrapper.showJobSites;
        this.showProjects = this.filterWrapper.showProjects;
        this.showOpportunities = this.filterWrapper.showOpportunities;
        this.showBranches = this.filterWrapper.showBranches;

        // appt filters
        this.appointmentSearch = this.filterWrapper.appointmentSearch;
        this.apptParentType = this.filterWrapper.apptParentType;
        this.openAppointments = this.filterWrapper.openAppointments;
        this.todaysAppointments = this.filterWrapper.todaysAppointments;
        this.next7DaysAppointments = this.filterWrapper.next7DaysAppointments;
        this.thisWeekAppointments = this.filterWrapper.thisWeekAppointments;
        this.nextWeekAppointments = this.filterWrapper.nextWeekAppointments;
        this.nextXDaysAppointments = this.filterWrapper.nextXDaysAppointments;
        this.nextXDaysAppointmentsValue =
            this.filterWrapper.nextXDaysAppointmentsValue;
        this.dateRangeAppointments = this.filterWrapper.dateRangeAppointments;
        this.dateRangeAppointmentsStart =
            this.filterWrapper.dateRangeAppointmentsStart;
        this.dateRangeAppointmentsEnd = this.filterWrapper.dateRangeAppointmentsEnd;

        // task filters
        this.taskSearch = this.filterWrapper.taskSearch;
        this.taskParentType = this.filterWrapper.taskParentType;
        this.todaysTasks = this.filterWrapper.todaysTasks;
        this.openTasks = this.filterWrapper.openTasks;
        this.next7DaysTasks = this.filterWrapper.next7DaysTasks;
        this.thisWeekTasks = this.filterWrapper.thisWeekTasks;
        this.nextWeekTasks = this.filterWrapper.nextWeekTasks;
        this.nextXDaysTasks = this.filterWrapper.nextXDaysTasks;
        this.nextXDaysTasksValue = this.filterWrapper.nextXDaysTasksValue;
        this.dateRangeTasks = this.filterWrapper.dateRangeTasks;
        this.dateRangeTasksStart = this.filterWrapper.dateRangeTasksStart;
        this.dateRangeTasksEnd = this.filterWrapper.dateRangeTasksEnd;

        // account filters
        this.searchAccounts = this.filterWrapper.searchAccounts;
        this.accountSearch = this.filterWrapper.accountSearch;
        this.top25Accounts = this.filterWrapper.top25Accounts;
        this.top50Accounts = this.filterWrapper.top50Accounts;
        this.topXAccounts = this.filterWrapper.topXAccounts;
        this.topXAccountsValue = this.filterWrapper.topXAccountsValue;
        this.watchlistAccounts = this.filterWrapper.watchlistAccounts;
        this.dormantAccounts = this.filterWrapper.dormantAccounts;
        this.rankRangeAccounts = this.filterWrapper.rankRangeAccounts;
        this.rankRangeAccountsStart = this.filterWrapper.rankRangeAccountsStart;
        this.rankRangeAccountsEnd = this.filterWrapper.rankRangeAccountsEnd;
        this.accountRecordType = JSON.parse(this.filterWrapper.accountRecordType);
        this.accountRecordTypePrevious = JSON.parse(this.filterWrapper.accountRecordType);
        this.showOffices = this.filterWrapper.showOffices;
        this.assignedAccountsOnly = this.filterWrapper.assignedAccountsOnly;
        this.includeTracked = this.filterWrapper.includeTracked;

        // lead filters
        this.openLeads = this.filterWrapper.openLeads;
        this.leadShareLeads = this.filterWrapper.leadShareLeads;
        this.campaignLeads = this.filterWrapper.campaignLeads;
        this.campaignType = this.filterWrapper.campaignType;

        // job site filters
        this.jobSiteSearch = this.filterWrapper.jobSiteSearch;
        this.activeJobSites = this.filterWrapper.activeJobSites;
        this.todayJobSites = this.filterWrapper.todayJobSites;
        this.yesterdayJobSites = this.filterWrapper.yesterdayJobSites;
        this.nextXDaysJobSites = this.filterWrapper.nextXDaysJobSites;
        this.nextXDaysJobSitesValue = this.filterWrapper.nextXDaysJobSitesValue;

        // project filters
        this.projectSearch = this.filterWrapper.projectSearch;
        this.cityProject = this.filterWrapper.cityProject;
        this.cityProjectValue = this.filterWrapper.cityProjectValue;
        this.plantIdProject = this.filterWrapper.plantIdProject;
        this.plantIdProjectValue = this.filterWrapper.plantIdProjectValue;
        this.plantNameProject = this.filterWrapper.plantNameProject;
        this.plantNameProjectValue = this.filterWrapper.plantNameProjectValue;
        this.valuationProject = this.filterWrapper.valuationProject;
        this.valuationProjectValue = this.filterWrapper.valuationProjectValue;
        this.valuationRangeProjects = this.filterWrapper.valuationRangeProjects;
        this.valuationRangeProjectsStart =
            this.filterWrapper.valuationRangeProjectsStart;
        this.valuationRangeProjectsEnd =
            this.filterWrapper.valuationRangeProjectsEnd;
        this.squareFootageRangeProjects =
            this.filterWrapper.squareFootageRangeProjects;
        this.squareFootageRangeProjectsStart =
            this.filterWrapper.squareFootageRangeProjectsStart;
        this.squareFootageRangeProjectsEnd =
            this.filterWrapper.squareFootageRangeProjectsEnd;
        this.projectStatus = this.filterWrapper.projectStatus;
        this.projectPrimaryType = JSON.parse(this.filterWrapper.projectPrimaryType);
        this.projectPrimaryTypePrevious = JSON.parse(this.filterWrapper.projectPrimaryType);
        this.projectStage = this.filterWrapper.projectStage;
        this.projectOrigin = JSON.parse(this.filterWrapper.projectOrigin);
        this.projectOriginPrevious = JSON.parse(this.filterWrapper.projectOrigin);
        this.projectActivity = this.filterWrapper.projectActivity;
        this.projectTiming = this.filterWrapper.projectTiming;
        this.projectDodgePhase = JSON.parse(this.filterWrapper.projectDodgePhase);
        this.projectDodgePhasePrevious = JSON.parse(this.filterWrapper.projectDodgePhase);
        this.projectCreatedDate = this.filterWrapper.projectCreatedDate;
        this.dateRangeCreatedDateProjectsStart = this.filterWrapper.dateRangeCreatedDateProjectsStart;
        this.dateRangeCreatedDateProjectsEnd = this.filterWrapper.dateRangeCreatedDateProjectsEnd;

        // Project Bid Filters
        this.next30DaysBidDateProject = this.filterWrapper.next30DaysBidDateProject;
        this.lastXDaysBidDateProject = this.filterWrapper.lastXDaysBidDateProject;
        this.lastXDaysBidDateProjectValue =
            this.filterWrapper.lastXDaysBidDateProjectValue;
        this.nextXDaysBidDateProject = this.filterWrapper.nextXDaysBidDateProject;
        this.nextXDaysBidDateProjectValue =
            this.filterWrapper.nextXDaysBidDateProjectValue;
        this.dateRangeBidDateProjects = this.filterWrapper.dateRangeBidDateProjects;
        this.dateRangeBidDateProjectsStart =
            this.filterWrapper.dateRangeBidDateProjectsStart;
        this.dateRangeBidDateProjectsEnd =
            this.filterWrapper.dateRangeBidDateProjectsEnd;

        // Project Completion Filters
        this.next30DaysCompletionDateProject =
            this.filterWrapper.next30DaysCompletionDateProject;
        this.lastXDaysCompletionDateProject =
            this.filterWrapper.lastXDaysCompletionDateProject;
        this.lastXDaysCompletionDateProjectValue =
            this.filterWrapper.lastXDaysCompletionDateProjectValue;
        this.nextXDaysCompletionDateProject =
            this.filterWrapper.nextXDaysCompletionDateProject;
        this.nextXDaysCompletionDateProjectValue =
            this.filterWrapper.nextXDaysCompletionDateProjectValue;
        this.dateRangeCompletionDateProjects =
            this.filterWrapper.dateRangeCompletionDateProjects;
        this.dateRangeCompletionDateProjectsStart =
            this.filterWrapper.dateRangeCompletionDateProjectsStart;
        this.dateRangeCompletionDateProjectsEnd =
            this.filterWrapper.dateRangeCompletionDateProjectsEnd;

        // Project Kickoff Filters
        this.next30DaysKickoffDateProject =
            this.filterWrapper.next30DaysKickoffDateProject;
        this.lastXDaysKickoffDateProject =
            this.filterWrapper.lastXDaysKickoffDateProject;
        this.lastXDaysKickoffDateProjectValue =
            this.filterWrapper.lastXDaysKickoffDateProjectValue;
        this.nextXDaysKickoffDateProject =
            this.filterWrapper.nextXDaysKickoffDateProject;
        this.nextXDaysKickoffDateProjectValue =
            this.filterWrapper.nextXDaysKickoffDateProjectValue;
        this.dateRangeKickoffDateProjects =
            this.filterWrapper.dateRangeKickoffDateProjects;
        this.dateRangeKickoffDateProjectsStart =
            this.filterWrapper.dateRangeKickoffDateProjectsStart;
        this.dateRangeKickoffDateProjectsEnd =
            this.filterWrapper.dateRangeKickoffDateProjectsEnd;

        // Project AFE Filters
        this.next30DaysAFEDateProject = this.filterWrapper.next30DaysAFEDateProject;
        this.lastXDaysAFEDateProject = this.filterWrapper.lastXDaysAFEDateProject;
        this.lastXDaysAFEDateProjectValue =
            this.filterWrapper.lastXDaysAFEDateProjectValue;
        this.nextXDaysAFEDateProject = this.filterWrapper.nextXDaysAFEDateProject;
        this.nextXDaysAFEDateProjectValue =
            this.filterWrapper.nextXDaysAFEDateProjectValue;
        this.dateRangeAFEDateProjects = this.filterWrapper.dateRangeAFEDateProjects;
        this.dateRangeAFEDateProjectsStart =
            this.filterWrapper.dateRangeAFEDateProjectsStart;
        this.dateRangeAFEDateProjectsEnd =
            this.filterWrapper.dateRangeAFEDateProjectsEnd;

        // Project RQF Filters
        this.next30DaysRQFDateProject = this.filterWrapper.next30DaysRQFDateProject;
        this.lastXDaysRQFDateProject = this.filterWrapper.lastXDaysRQFDateProject;
        this.lastXDaysRQFDateProjectValue =
            this.filterWrapper.lastXDaysRQFDateProjectValue;
        this.nextXDaysRQFDateProject = this.filterWrapper.nextXDaysRQFDateProject;
        this.nextXDaysRQFDateProjectValue =
            this.filterWrapper.nextXDaysRQFDateProjectValue;
        this.dateRangeRQFDateProjects = this.filterWrapper.dateRangeRQFDateProjects;
        this.dateRangeRQFDateProjectsStart =
            this.filterWrapper.dateRangeRQFDateProjectsStart;
        this.dateRangeRQFDateProjectsEnd =
            this.filterWrapper.dateRangeRQFDateProjectsEnd;

        // Opportunity Filters
        this.opportunitySearch = this.filterWrapper.opportunitySearch;
        this.opportunityStage = JSON.parse(this.filterWrapper.opportunityStage);
        this.opportunityStagePrevious = JSON.parse(this.filterWrapper.opportunityStage);
        this.openOpportunity = this.filterWrapper.openOpportunity;
        this.closeDateNext30DaysOpportunity =
            this.filterWrapper.closeDateNext30DaysOpportunity;
        this.closeDateLastXDaysOpportunity =
            this.filterWrapper.closeDateLastXDaysOpportunity;
        this.closeDateLastXDaysOpportunityValue =
            this.filterWrapper.closeDateLastXDaysOpportunityValue;
        this.closeDateNextXDaysOpportunity =
            this.filterWrapper.closeDateNextXDaysOpportunity;
        this.closeDateNextXDaysOpportunityValue =
            this.filterWrapper.closeDateNextXDaysOpportunityValue;
        this.estDateNext30DaysOpportunity =
            this.filterWrapper.estDateNext30DaysOpportunity;
        this.estDateLastXDaysOpportunity =
            this.filterWrapper.estDateLastXDaysOpportunity;
        this.estDateLastXDaysOpportunityValue =
            this.filterWrapper.estDateLastXDaysOpportunityValue;
        this.estDateNextXDaysOpportunity =
            this.filterWrapper.estDateNextXDaysOpportunity;
        this.estDateNextXDaysOpportunityValue =
            this.filterWrapper.estDateNextXDaysOpportunityValue;

        // Branch Filters
        this.branchSearch = this.filterWrapper.branchSearch;
        this.country = this.filterWrapper.country;
        this.lineOfBusiness = JSON.parse(this.filterWrapper.lineOfBusiness);
        this.lineOfBusinessPrevious = JSON.parse(this.filterWrapper.lineOfBusiness);
        this.loadBranchData = this.filterWrapper.loadBranchData;
        //this.allBranches = this.filterWrapper.allBranches;
    }
}