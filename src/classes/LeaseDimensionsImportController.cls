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
    public List<ReportLine> reportLines;
    public Map<String, Loan__c> loanMap;
    public static Map<String, String> descriptionMap =
        new Map<String, String>{'IBL PMT - INTEREST' => 'Interest',
                                'IBL PRN PAYDOWN' => 'Principal',
                                'WRITE DOWN ASST INVN' => 'Principal',
                                'PAYMENT OTHER CHARGE' => 'Interest',
                                'IBL INT CR' => 'Interest',
                                'IBL INT CR REV' => 'Interest',
                                'IBL PRN PAYDOWN REV' => 'Principal',
                                'IBL PMT REV - INT' => 'Interest',
                                'IBL PMT - PRINCIPAL' => 'Principal',
                                'IBL PRN WRITE-DOWN' => 'Principal',
                                'IBL PMT REV - PRN' => 'Principal',
                                'PMT REV OTHER CHARGE' => 'Interest',
                                'IBL PRN WRITE-DN REV' => 'Principal'};

    public LeaseDimensionsImportController() {
    }

    public void processCSV() {
        loadCSV();
        generateTAs();
    }

    private void loadCSV() {
        CSVReader csvReader = new CSVReader(document.body.toString());
        String[] line;
        ReportLine rl;
        loanNumbers = new Set<String>();
        reportLines = new List<ReportLine>();
        while ((line = csvReader.readLine()) != null) {
            try {
                rl = new ReportLine(line);
                reportLines.add(rl);
                loanNumbers.add(rl.loanNumber);
            } catch (LDImportException ldie) {
                // Exception is already added to the debug log
            }
        }
        
        loansFound = [SELECT Id, Loan_Number__c,
                      (SELECT Id, Period__c, Payment_Due_Date2__c
                       FROM Loan_Payments__r
                       WHERE Period__c <> null
                       ORDER BY Period__c)
                      FROM Loan__c
                      WHERE Loan_Number__c IN :loanNumbers];
        loanMap = new Map<String, Loan__c>();
        for (Loan__c loan : loansFound) {
            loanMap.put(loan.Loan_Number__c, loan);
        }

        loadResult = loansFound.size() + ' of ' + loanNumbers.size() + ' found\n';
        if (loansFound.size() != loanNumbers.size()) {
            // LD has a transaction to a loan we couldn't find. Report which one
            for (String ln : loanNumbers) {
                if (loanMap.get(ln) == null) {
                    loadResult += ln + ' not found\n';
                }
            }
        }
        System.debug(LoggingLevel.ERROR, loadResult);
    }

    private void generateTAs() {
        List<Transaction_Application__c> taList = new List<Transaction_Application__c>();
        Transaction_Application__c ta;
        Loan__c loan;
        for (ReportLine rl : reportLines) {
            try {
                loan = loanMap.get(rl.loanNumber);
                if (loan != null) {
                    taList.add(rl.getTA(loan));
                }
            } catch (LDImportException ldie) {
                // Exception prints debug, skip this one and go to next
            }
        }
        insert taList;
    }

    private class ReportLine {
        String portfolio;
        String company;
        String region;
        String office;
        String account;
        String loanNumber;
        String customerName;
        Date processDate;
        Date paymentEffectiveDate;
        Date invoiceDueDate;
        String transactionDescription;
        String invoiceNumber;
        String checkNumber;
        String cashCode;
        Decimal amount;
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
            processDate = Date.parse(inputLine[6].trim());
            paymentEffectiveDate = Date.parse(inputLine[7].trim());
            if (!String.isBlank(inputLine[8])) {
                invoiceDueDate = Date.parse(inputLine[8].trim());
            }
            transactionDescription = inputLine[9];
            invoiceNumber = inputLine[10];
            checkNumber = inputLine[11];
            cashCode = inputLine[12];
            amount = parse(inputLine[13]);
            reversalReason = inputLine[14];
            comments = inputLine[15];
        }

        private Decimal parse(String parsed) {
            if (parsed.contains('(') || parsed.contains(')')) {
                parsed = parsed.replaceAll('[(), ]', '');
                return Decimal.valueOf(parsed) * -1;
            } else {
                parsed = parsed.replaceAll('[, ]', '');
                return Decimal.valueOf(parsed);
            }
        }        

        public Transaction_Application__c getTA(Loan__c loan) {
            Transaction_Application__c ta =
                new Transaction_Application__c(Process_Date__c = processDate,
                                               Effective_Date__c = paymentEffectiveDate,
                                               Description__c = transactionDescription,
                                               Invoice_Number__c = invoiceNumber,
                                               Check_Number__c = checkNumber,
                                               Cash_Code__c = cashCode,
                                               Comments__c = (String.isBlank(reversalReason)?'':(reversalReason+'\n')) + comments);
            for (Loan_Payment__c lp : loan.Loan_Payments__r) {
                if  (LoanServicer.appliesTo(paymentEffectiveDate, lp)) {
                    ta.Loan_Payment__c = lp.Id;
                    break;
                }
            }
            if (ta.Loan_Payment__c == null) {
                throw new LDImportException('Could not find a loan payment to relate to. ' +
                                            'Loan: ' + account + ' Effective Date: ' + paymentEffectiveDate);
            }
            String principalOrInterest;
            if ((principalOrInterest = descriptionMap.get(transactionDescription)) == null) {
                throw new LDImportException('Unknown transaction description found: ' + transactionDescription);
            } else if (principalOrInterest.equals('Principal')) {
                ta.Principal_Applied__c = amount;
            } else {
                ta.Interest_Applied__c = amount;
            }
            if (transactionDescription.equals('IBL PRN WRITE-DN REV') ||
                transactionDescription.equals('IBL PRN WRITE-DOWN') ||
                transactionDescription.equals('WRITE DOWN ASST INVN')) {
                if (comments.toUpperCase().contains('CUSTOMER')) {
                    ta.Principal_Paydown_Reason__c = 'Customer';
                } else {
                    ta.Principal_Paydown_Reason__c = 'IBLS';
                }
            }
            return ta;
        }
    }
    
    public class LDImportException extends Exception{}

}
