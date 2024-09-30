import { LightningElement } from 'lwc';
import fetchUserSessionId from "@salesforce/apex/SBR_3_0_UserSessionDetails.fetchUserSessionId";
import TerminalDetails from "@salesforce/apex/SBR_3_0_MakeADepositController.getTerminal";

/**
  * Checks if terminal value is present in localstorage for active session.
  * Note: if sessionId is not present then clearing localstorage as data in localstorage not get erased automatically.
  * sessionId, terminalValue
  * @author : Kavita
  * @returns {object} object
*/
export async function checkTerminalInSession() {
    const sessionId = await fetchUserSessionId() || '';
    const isTerminalInSession = localStorage.getItem(sessionId);
    if (!isTerminalInSession) localStorage.clear();
    const terminalValue = isTerminalInSession || '--None--';
    return { sessionId, terminalValue }
}

/**
  * Returns the terminal options present for corrosponding department.
  * @author : Kavita
  * @returns {array} terminalOptions
*/
export async function getTerminalDetails(department) {
    try {
        const terminalResult = await TerminalDetails({ department });
        if (!terminalResult) return [];
        const terminalOptions = [{ value: '--None--', label: '--None--' }].concat(
            terminalResult.map(terminalOption => ({
                value: terminalOption,
                label: terminalOption
            }))
        );
        return terminalOptions;
    } catch (error) {
        console.error('error in fetching terminal values', error);
        return [];
    }
}