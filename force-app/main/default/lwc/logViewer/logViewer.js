import { LightningElement,track } from 'lwc';
import {
    subscribe,
    unsubscribe,
    onError,
    setDebugFlag,
    isEmpEnabled,
} from 'lightning/empApi';

export default class LogViewer extends LightningElement {
    @track logEntryEvents = [];
    unfilteredEvents = [];
    key = 1;
    isExpanded = false;
    isStreamEnabled = true;

    //Filters
    loggedByFilter;
    recordIdFilter;

    _channel = '/event/LogEntryEvent__e';
    _subscription = {}

    get title() {
        let logEntryString = ' Log Entry Events';
        let startingTitle = this.logEntryEvents.length + logEntryString;
        if (this.unfilteredEvents.length !== this.logEntryEvents.length) {
            startingTitle = this.logEntryEvents.length + ' matching results out of ' + this.unfilteredEvents.length + logEntryString;
        }
        return startingTitle;
    }

    get streamButtonVariant() {
        return this.isStreamEnabled ? 'success' : 'brand';
    }

    async connectedCallback() {
        document.title = 'Log Entry Event Stream';
        if (isEmpEnabled()) {
            this.createSubscription();
        }
    }

    disconnectedCallback() {
        this.cancelSubscription();
    }

    async createSubscription() {
        this._subscription = await subscribe(this._channel, -1, event => {
            const logEntryEvent = event.data.payload;
            logEntryEvent.key = this.key++;
            let payload = JSON.parse(JSON.stringify(logEntryEvent));
            logEntryEvent.payload = JSON.stringify(payload,null,2);
            this.unfilteredEvents.unshift(logEntryEvent);
            this._filterEvents();
        });
    }

    handleFilterChange(event) {
        this[event.target.dataset.id] = event.target.value;
        this._filterEvents();
    }

    cancelSubscription() {
        unsubscribe(this._subscription);
    }

    onClear() {
        this.logEntryEvents = [];
        this.unfilteredEvents = [];
    }

    onToggleStream() {
        this.isStreamEnabled = !this.isStreamEnabled;
        // eslint-disable-next-line
        this.isStreamEnabled ? this.createSubscription() : this.cancelSubscription();
    }

    // Private functions
    _filterEvents() {

        this.logEntryEvents = this.unfilteredEvents.filter(
            logEntryEvent =>
                this._meetsLoggedByFilter(logEntryEvent) &&
                this._meetsRecordIdFilter(logEntryEvent)
        );
    }

    _meetsLoggedByFilter(logEntryEvent) {
        return this._matchesTextFilter(this.loggedByFilter, logEntryEvent.User__c);
    }

    _meetsRecordIdFilter(logEntryEvent) {
        return this._matchesTextFilter(this.recordIdFilter, logEntryEvent.RecordID__c);
    }

    _matchesTextFilter(filterCriteria = '', text = '') {
        let matches = false;
        if (!filterCriteria || text.includes(filterCriteria) || text.match(filterCriteria)) {
            matches = true;
        }
        return matches;
    }

}