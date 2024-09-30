import { LightningElement } from 'lwc';
import fetchUserSessionId from "@salesforce/apex/SBR_3_0_UserSessionDetails.fetchUserSessionId";

export async function checkTerminalInSession(){
    const sessionId = await fetchUserSessionId() || '';
    const isTerminalInSession = localStorage.getItem(sessionId);
    if(!isTerminalInSession) localStorage.clear();
    const terminalValue = isTerminalInSession || '--None--';
    return {sessionId, terminalValue}
}