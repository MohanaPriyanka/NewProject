/**
 * Created By: Peter Yao
 * Description:  Creates Transaction Applications from a Lease Dimensions daily or monthly payment 
 *               file saved as a CSV
 *               Assumes 16 columns, from Portfolio through Comments
 * Tested by: LeaseDimensionsImportControllerTest
 **/

public without sharing class LeaseDimensionsImportController {
    public Document document {
        get {
            if (document == null)
                document = new Document();
            return document;
        }
        set;
    }
    public List<Loan__c> loansFound;
    public Set<String> loanNumbers;
    public String loadResult {get;set;}
    
    public LeaseDimensionsImportController() {
    }

    public void loadCSV() {
        CSVReader csvReader = new CSVReader(document.body.toString());
        String[] line;
        ReportLine rl;
        loanNumbers = new Set<String>();
        List<ReportLine> reportLines = new List<ReportLine>();
        while ((line = csvReader.readLine()) != null) {
            try {
                rl = new ReportLine(line);
                reportLines.add(rl);
                loanNumbers.add(rl.loanNumber);
            } catch (LDImportException ldie) {
                // Exception is already added to the debug log
            }
        }
        
        loansFound = [SELECT Id, Loan_Number__c
                        FROM Loan__c
                        WHERE Loan_Number__c IN :loanNumbers];
        loadResult = loansFound.size() + ' of ' + loanNumbers.size() + ' found\n';
        if (loansFound.size() != loanNumbers.size()) {
            // LD has a transaction to a loan we couldn't find. Report which one
            Map<String, Loan__c> loanMap = new Map<String, Loan__c>();
            for (Loan__c loan : loansFound) {
                loanMap.put(loan.Loan_Number__c, loan);
            }
            for (String ln : loanNumbers) {
                if (loanMap.get(ln) == null) {
                    loadResult += ln + ' not found\n';
                }
            }
        }
        System.debug(LoggingLevel.ERROR, loadResult);
    }

    private class ReportLine {
        String portfolio;
        String company;
        String region;
        String office;
        String account;
        String loanNumber;
        String customerName;
        String processDate;
        String paymentEffectiveDate;
        String invoiceDueDate;
        String transactionDescription;
        String invoiceNumber;
        String checkNumber;
        String cashCode;
        String amount;
        String reversalReason;
        String comments;
        
        private ReportLine(String[] inputLine) {
            if (inputLine.size() != 16 ||
                // Excel saves non-printing characters when saving to csv, so use contains instead of equals
                inputLine[0].contains('Portfolio') ||
                inputLine[4].equals('')) {
                throw new LDImportException('Not processing this line: ' + inputLine);
            }
            portfolio = inputLine[0];
            company = inputLine[1];
            region = inputLine[2];
            office = inputLine[3];
            account = inputLine[4];
            if (account.startsWith('BW')) {
                loanNumber = account;
            } else {
                loanNumber = 'BW' + account.leftPad(7).replace(' ','0');
            }
            customerName = inputLine[5];
            processDate = inputLine[6];
            paymentEffectiveDate = inputLine[7];
            invoiceDueDate = inputLine[8];
            transactionDescription = inputLine[9];
            invoiceNumber = inputLine[10];
            checkNumber = inputLine[11];
            cashCode = inputLine[12];
            amount = inputLine[13];
            reversalReason = inputLine[14];
            comments = inputLine[15];
        }
    }
    
    public class LDImportException extends Exception{}

}