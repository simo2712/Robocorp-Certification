*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library    RPA.Browser.Selenium
Library    RPA.HTTP
Library    RPA.Tables
Library    RPA.PDF
Library    RPA.Archive
Library    RPA.RobotLogListener
Library    RPA.Robocorp.Vault
Library    RPA.Dialogs


*** Variables ***
${CSV_FILE_URL}     https://robotsparebinindustries.com/orders.csv
${CSV_FILE_PATH}    ${OUTPUT DIR}/orders.csv
${PDF_FILE_PATH}    data/receipts/
${JPG_FILE_PATH}    data/screenshots/


*** Keywords ***
Input zip filename
    Add text input    zip_filename    placeholder=Give the filename of the ZIP archive
    ${response}=    Run dialog
    [Return]    ${OUTPUT DIR}/${response.zip_filename}.zip


*** Keywords ***
Open the robot order website
    ${url}=     Get Secret    url
    Open Available Browser     ${url}[RobotSpareBin]
    

*** Keywords ***
Get orders
    Download    ${CSV_FILE_URL}    overwrite=True    target_file=${CSV_FILE_PATH}
    ${orders}=    Read table from CSV     ${CSV_FILE_PATH}
    [Return]    ${orders}


*** Keywords ***
Close the annoying modal
    Click Element If Visible   css:#root > div > div.modal > div > div > div > div > div > button.btn.btn-dark


*** Keywords ***
Fill the form
    [Arguments]    ${order}
    Select From List By Value    id:head    ${order['Head']}
    Select Radio Button    body    ${order['Body']}
    Input Text    class:form-control    ${order['Legs']}
    Input Text    id:address    ${order['Address']}


*** Keywords ***
Preview the robot
    Click Button    id:preview


*** Keywords ***
Submit the order
    Click Button    id:order
    Is Element Visible    id:receipt    False


*** Keywords ***
Store the receipt as a PDF file
    [Arguments]    ${order number}
    ${receipt_html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${receipt_html}    ${PDF_FILE_PATH}/${order number}.pdf
    [Return]    ${PDF_FILE_PATH}/${order number}.pdf


*** Keywords ***
Take a screenshot of the robot
    [Arguments]    ${order number}
    Wait Until Element Is Visible    id:robot-preview-image
    Screenshot    id:robot-preview-image    ${JPG_FILE_PATH}/${order number}.jpg
    [Return]    ${JPG_FILE_PATH}/${order number}.jpg


*** Keywords ***
Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${robot_screenshot}    ${pdf_file_path}
    ${list_screenshot}=     Create List    ${robot_screenshot}
    Add Files To Pdf    ${list_screenshot}   ${pdf_file_path}    append=True


*** Keywords ***
Go to order another robot
    Click Element If Visible   id:order-another


*** Keywords ***
Create a ZIP file of the receipts
    [Arguments]    ${zip_file_path}
    Archive Folder With Zip    ${PDF_FILE_PATH}    ${zip_file_path}
    


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Mute Run On Failure    Submit the order
    ${ZIP_FILE_PATH}=    Input zip filename
    Open the robot order website
    ${orders}=    Get orders
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${row}
        Preview the robot
        Wait Until Keyword Succeeds    10x    1s    Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Go to order another robot
    END
    Create a ZIP file of the receipts    ${ZIP_FILE_PATH}
