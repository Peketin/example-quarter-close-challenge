*** Settings ***
Documentation     Completes the Quarter Close challenge.
Library           RPA.Browser.Playwright
Library           RPA.Robocorp.Vault
Library           Collections

*** Tasks ***
Complete the Quarter Close challenge
    ${transaction_page}=    Open the transaction review website
    Accept cookies
    ${transactions}=    Get transactions
    Open the bank web application
    Log in to the bank web application
    ${matched_transactions}=    Match transactions    ${transactions}
    Switch Page    ${transaction_page}[page_id]
    Save transaction statuses    ${matched_transactions}
    Take a screenshot of the result

*** Keywords ***
Open the transaction review website
    New Context    userAgent=Chrome/100.0.4896.75
    ${transaction_page}=
    ...    New Page
    ...    https://developer.automationanywhere.com/challenges/automationanywherelabs-quarterclose.html
    [Return]    ${transaction_page}

Accept cookies
    Click    id=onetrust-accept-btn-handler

Open the bank web application
    Click    css=a.btn-peters
    Switch Page    NEW

Log in to the bank web application
    ${secret}=    Get Secret    arcadiaBank
    Fill Secret    id=inputEmail    ${secret}[username]
    Fill Secret    id=inputPassword    ${secret}[password]
    Click    css=a >> text="Login"

Get transactions
    ${transaction_elements}=    Get Elements    css=div[id^="transaction"]
    ${transactions}=    Create List
    FOR    ${transaction_element}    IN    @{transaction_elements}
        ${id}=
        ...    Get Property
        ...    ${transaction_element}
        ...    id
        ${account}=
        ...    Get Property
        ...    ${transaction_element} >> input[id^="PaymentAccount"]
        ...    value
        ${amount}=
        ...    Get Property
        ...    ${transaction_element} >> input[id^="PaymentAmount"]
        ...    value
        ${transaction}=
        ...    Create Dictionary
        ...    id=${id}
        ...    account=${account}
        ...    amount=${amount}
        Append To List    ${transactions}    ${transaction}
    END
    [Return]    ${transactions}

Match transactions
    [Arguments]    ${transactions}
    FOR    ${transaction}    IN    @{transactions}
        Open the account page    ${transaction}
        ${status}=    Search transaction and return status    ${transaction}
        Set To Dictionary    ${transaction}    status=${status}
    END
    [Return]    ${transactions}

Open the account page
    [Arguments]    ${transaction}
    Click    css=a >> text="${transaction}[account]"

Search transaction and return status
    [Arguments]    ${transaction}
    Wait For Elements State    id=transactions
    Type Text
    ...    css=.dataTable-search input.dataTable-input
    ...    ${transaction}[amount]
    ${transaction_found}=
    ...    Run Keyword And Return Status
    ...    Wait For Elements State
    ...    text="Showing 1 to 1 of 1 entries"
    ...    timeout=1.5 seconds
    ${status}=    Set Variable    Unverified
    IF    ${transaction_found}
        ${status}=    Set Variable    Verified
    END
    [Return]    ${status}

Save transaction statuses
    [Arguments]    ${transactions}
    FOR    ${transaction}    IN    @{transactions}
        Select Options By
        ...    css=#${transaction}[id] select[id^="Status"]
        ...    value
        ...    ${transaction}[status]
    END
    Click    id=submitbutton    force=True

Take a screenshot of the result
    Sleep    1 second
    Take Screenshot    selector=css=#myModal .modal-content
